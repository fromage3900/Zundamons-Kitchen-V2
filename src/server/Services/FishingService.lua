--!strict
-- Server-authoritative fishing domain. The client sends reel intent only; fish
-- selection, simulation, settlement, and lifecycle remain on the server.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishConfig = require(ReplicatedStorage.ConfigurationFiles.FishConfig)
local FishingSession = require(ReplicatedStorage.components.fishing.FishingSession)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)

local toolRemotes = ReplicatedStorage:WaitForChild("ToolRemotes")
local fishingState = toolRemotes:WaitForChild("FishingState") :: RemoteEvent
local fishingResult = toolRemotes:WaitForChild("FishingResult") :: RemoteEvent

local BEGIN_COOLDOWN = 2.5
local INPUT_COOLDOWN = 0.04
local STATE_INTERVAL = 0.1
local MAX_ZONE_DISTANCE = 45
local MAX_STEP = 0.1

local FishingService = {}
local activeWorld: any = nil
local activeByPlayer: { [number]: { entityId: any, sessionId: string, lastInputAt: number } } = {}
local lastBeginAt: { [number]: number } = {}

local function equippedRod(player: Player): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("Type") == "FishingRod" then
			return child
		end
	end
	return nil
end

local function positionOf(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	end
	if instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function inFishingZone(player: Player): boolean
	local zones = CollectionService:GetTagged("FishingZone")
	if #zones == 0 then
		-- Existing places predate zone tags. Once a designer adds any FishingZone,
		-- proximity becomes mandatory without requiring another code change.
		return true
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	for _, zone in ipairs(zones) do
		local position = positionOf(zone)
		if position and (root.Position - position).Magnitude <= MAX_ZONE_DISTANCE then
			return true
		end
	end
	return false
end

local function emitResult(player: Player?, sessionId: string, outcome: string, payload: any?)
	if player and player.Parent == Players then
		fishingResult:FireClient(player, {
			sessionId = sessionId,
			outcome = outcome,
			payload = payload,
		})
	end
end

local function settle(world: any, entityId: any, session: any, outcome: string)
	if session.settled then
		return
	end
	local settledSession = table.clone(session)
	settledSession.settled = true
	world:insert(entityId, FishingSession(settledSession))
	activeByPlayer[session.playerId] = nil

	local player = Players:GetPlayerByUserId(session.playerId)
	local payload = nil
	if outcome == "caught" and player then
		local itemName = "Fish: " .. session.fishName
		local reward = RewardCore.settle(player, {
			xp = session.fishXp,
			reason = "fish",
			combo = true,
			popupItem = itemName,
			popupColor = session.fishColor,
		}, function(data)
			data[itemName] = (data[itemName] or 0) + 1
			data.total_fish_caught = (data.total_fish_caught or 0) + 1
			data.fish_caught_count = data.fish_caught_count or {}
			data.fish_caught_count[session.fishName] = (data.fish_caught_count[session.fishName] or 0) + 1
			return true, { item = itemName, count = data[itemName] }
		end)
		if reward.ok then
			payload = {
				name = session.fishName,
				rarity = session.fishRarity,
				color = session.fishColor,
				xp = reward.xp,
				item = itemName,
			}
		else
			outcome = "settlement_failed"
		end
	elseif player and (outcome == "lost" or outcome == "timeout") then
		RewardCore.breakCombo(player)
	end

	emitResult(player, session.sessionId, outcome, payload)
	world:despawn(entityId)
end

function FishingService.attachWorld(world: any)
	if activeWorld and activeWorld ~= world then
		error("FishingService cannot attach to multiple Matter worlds")
	end
	activeWorld = world
end

function FishingService.begin(player: Player): { [string]: any }
	if not activeWorld then
		return { ok = false, reason = "fishing_not_ready" }
	end
	if not PlayerDataService.get(player) then
		return { ok = false, reason = "data_not_loaded" }
	end
	if activeByPlayer[player.UserId] then
		return { ok = false, reason = "session_active" }
	end
	local now = os.clock()
	if now - (lastBeginAt[player.UserId] or 0) < BEGIN_COOLDOWN then
		return { ok = false, reason = "rate_limited" }
	end
	lastBeginAt[player.UserId] = now
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return { ok = false, reason = "character_unavailable" }
	end
	if not equippedRod(player) then
		return { ok = false, reason = "rod_not_equipped" }
	end
	if not inFishingZone(player) then
		return { ok = false, reason = "not_in_fishing_zone" }
	end

	local fish = FishConfig.rollFish()
	local difficulty = FishConfig.difficulty[fish.rarity]
	if not difficulty then
		return { ok = false, reason = "invalid_fish_config" }
	end
	local sessionId = HttpService:GenerateGUID(false)
	local entityId = activeWorld:spawn(FishingSession({
		sessionId = sessionId,
		playerId = player.UserId,
		fishName = fish.name,
		fishRarity = fish.rarity,
		fishValue = fish.value,
		fishXp = fish.xp,
		fishColor = fish.color,
		difficulty = table.clone(difficulty),
		startTime = now,
		lastStepTime = now,
		nextTugAt = now + math.random(40, 100) / 100,
		lastStateSentAt = 0,
		tension = 0.2,
		progress = 0,
		reeling = false,
		settled = false,
	}))
	activeByPlayer[player.UserId] = { entityId = entityId, sessionId = sessionId, lastInputAt = 0 }
	return {
		ok = true,
		sessionId = sessionId,
		presentation = { name = fish.name, rarity = fish.rarity, color = fish.color },
	}
end

function FishingService.input(player: Player, payload: any): { [string]: any }
	if type(payload) ~= "table" or type(payload.sessionId) ~= "string" or type(payload.reeling) ~= "boolean" then
		return { ok = false, reason = "invalid_payload" }
	end
	local active = activeByPlayer[player.UserId]
	if not active or active.sessionId ~= payload.sessionId then
		return { ok = false, reason = "invalid_session" }
	end
	local now = os.clock()
	if now - active.lastInputAt < INPUT_COOLDOWN then
		return { ok = false, reason = "rate_limited" }
	end
	active.lastInputAt = now
	for entityId, session in activeWorld:query(FishingSession) do
		if entityId == active.entityId and session.sessionId == active.sessionId and not session.settled then
			local nextSession = table.clone(session)
			nextSession.reeling = payload.reeling
			activeWorld:insert(entityId, FishingSession(nextSession))
			return { ok = true }
		end
	end
	activeByPlayer[player.UserId] = nil
	return { ok = false, reason = "session_missing" }
end

function FishingService.cancel(player: Player, payload: any): { [string]: any }
	if type(payload) ~= "table" or type(payload.sessionId) ~= "string" then
		return { ok = false, reason = "invalid_payload" }
	end
	local active = activeByPlayer[player.UserId]
	if not active or active.sessionId ~= payload.sessionId then
		return { ok = false, reason = "invalid_session" }
	end
	for entityId, session in activeWorld:query(FishingSession) do
		if entityId == active.entityId then
			settle(activeWorld, entityId, session, "cancelled")
			return { ok = true }
		end
	end
	activeByPlayer[player.UserId] = nil
	return { ok = true }
end

function FishingService.step(world: any)
	FishingService.attachWorld(world)
	local now = os.clock()
	for entityId, session in world:query(FishingSession) do
		if session.settled then
			continue
		end
		local player = Players:GetPlayerByUserId(session.playerId)
		if not player or not equippedRod(player) then
			settle(world, entityId, session, "cancelled")
			continue
		end
		local nextSession = table.clone(session)
		local dt = math.clamp(now - nextSession.lastStepTime, 0, MAX_STEP)
		nextSession.lastStepTime = now
		if now >= nextSession.nextTugAt then
			if math.random() < nextSession.difficulty.dodgeChance then
				nextSession.tension =
					math.min(1, nextSession.tension + nextSession.difficulty.tugMag * (math.random(50, 100) / 100))
			end
			nextSession.nextTugAt = now + math.random(40, 100) / 100
		end
		if nextSession.reeling then
			nextSession.progress = math.min(1, nextSession.progress + dt / nextSession.difficulty.duration * 1.6)
			nextSession.tension = math.min(1, nextSession.tension + dt * 0.25)
		else
			nextSession.tension = math.max(0.05, nextSession.tension - dt * 0.6)
			nextSession.progress = math.max(0, nextSession.progress - dt * 0.02)
		end

		if nextSession.tension >= 1 then
			settle(world, entityId, nextSession, "lost")
		elseif nextSession.progress >= 1 then
			settle(world, entityId, nextSession, "caught")
		elseif now - nextSession.startTime > math.max(20, nextSession.difficulty.duration * 3) then
			settle(world, entityId, nextSession, "timeout")
		else
			if now - nextSession.lastStateSentAt >= STATE_INTERVAL then
				nextSession.lastStateSentAt = now
				fishingState:FireClient(player, {
					sessionId = nextSession.sessionId,
					tension = nextSession.tension,
					progress = nextSession.progress,
				})
			end
			world:insert(entityId, FishingSession(nextSession))
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	lastBeginAt[player.UserId] = nil
	local active = activeByPlayer[player.UserId]
	if not active or not activeWorld then
		return
	end
	for entityId, session in activeWorld:query(FishingSession) do
		if entityId == active.entityId then
			settle(activeWorld, entityId, session, "disconnected")
			break
		end
	end
	activeByPlayer[player.UserId] = nil
end)

return FishingService
