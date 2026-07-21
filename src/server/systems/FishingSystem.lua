--!strict
-- FishingSystem: Matter ECS system for server-authoritative fishing sessions.
-- Replaces ad-hoc activeBites table in FishingServer.server.lua with ECS-managed entities.
-- Validates casting, tracks tug physics server-side, awards rewards via RewardCore.

local Matter = require(game.ReplicatedStorage.Packages.Matter)
local FishingSession = require(game.ReplicatedStorage.components.fishing.FishingSession)

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local FishConfig = require(RS.ConfigurationFiles.FishConfig)
local RewardCore = require(SSS.Services.RewardCore)
local PlayerDataService = require(SSS.Services.PlayerDataService)

local FISHING_TIMEOUT = 45 -- seconds before an inactive session is auto-cleaned

-- Track which players already have an active session (faster than querying every time)
local activePlayerIds: { [number]: boolean } = {}

local function FishingSystem(world)
	-- Listen for FishingCast "begin" via RemoteFunction (invoked from FishingServer)
	local fishingCast = RS.ToolRemotes:FindFirstChild("FishingCast")
	if fishingCast then
		-- The FishingCast.OnServerInvoke still handles the immediate sync return.
		-- We intercept to spawn an ECS entity for state tracking.
		-- This runs via a Matter event wrapper for the RemoteFunction.
		for _, ev in world:query(Matter.useEvent(fishingCast, "OnServerInvoke")) do
			local player, action, payload = ev[1], ev[2], ev[3]
			if action == "begin" then
				-- Clean up any stale session for this player
				for id, session in world:query(FishingSession) do
					if session.playerId == player.UserId then
						world:despawn(id)
						activePlayerIds[player.UserId] = nil
					end
				end

				-- Validate rod equipped
				local char = player.Character
				if not char then
					continue
				end
				local rod
				for _, t in pairs(char:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("Type") == "FishingRod" then
						rod = t
						break
					end
				end
				if not rod then
					continue
				end

				-- Roll fish
				local fish = FishConfig.rollFish()
				if not fish then
					continue
				end
				local diff = FishConfig.difficulty and FishConfig.difficulty[fish.rarity]
					or {
						tugMag = 0.15,
						dodgeChance = 0.10,
						duration = 6,
						hookWindow = 0.55,
					}

				-- Spawn ECS entity
				world:spawn(FishingSession({
					playerId = player.UserId,
					fishName = fish.name,
					fishRarity = fish.rarity,
					fishValue = fish.value,
					fishXp = fish.xp,
					fishColor = fish.color,
					difficulty = diff,
					startTime = os.clock(),
					lastTugTime = os.clock(),
					tension = 0.2,
					progress = 0,
					reeling = false,
					finished = false,
				}))
				activePlayerIds[player.UserId] = true

				print(
					string.format(
						"[FishingSystem] Session started for %s (%s, rarity %d)",
						player.Name,
						fish.name,
						fish.rarity
					)
				)
			elseif action == "result" then
				-- Find the player's session
				for id, session in world:query(FishingSession) do
					if session.playerId == player.UserId then
						local timeElapsed = os.clock() - session.startTime

						if payload and payload.success then
							-- Anti-exploit: minimum catch time
							if timeElapsed < 2.0 then
								RewardCore.breakCombo(player)
								world:despawn(id)
								activePlayerIds[player.UserId] = nil
								print(
									string.format("[FishingSystem] %s caught too fast (exploit blocked)", player.Name)
								)
								continue
							end

							-- Award rewards
							RewardCore.bumpCombo(player)
							local goldAwarded = RewardCore.addGold(player, session.fishValue, "serve")
							RewardCore.addXP(player, session.fishXp, "craft")

							-- Add to inventory
							local data = PlayerDataService.getOrCreate(player)
							if data then
								local key = "Fish_" .. session.fishName
								data[key] = (data[key] or 0) + 1
							end

							-- Fire popup
							local popupEvent = RS:FindFirstChild("RewardEvents")
								and RS.RewardEvents:FindFirstChild("PopupEvent")
							if popupEvent then
								popupEvent:FireClient(player, "item", "🎣 " .. session.fishName, session.fishColor)
							end

							RewardCore.notify(player, "fish", {
								name = session.fishName,
								rarity = session.fishRarity,
								gold = goldAwarded,
							})

							print(
								string.format(
									"[FishingSystem] %s caught %s (+%dg, +%dxp)",
									player.Name,
									session.fishName,
									goldAwarded,
									session.fishXp
								)
							)
						else
							RewardCore.breakCombo(player)
							print(string.format("[FishingSystem] %s lost fish (%s)", player.Name, session.fishName))
						end

						session.finished = true
						world:insert(id, session)
						-- Despawn next tick
						task.defer(function()
							world:despawn(id)
							activePlayerIds[player.UserId] = nil
						end)
						break
					end
				end
			end
		end
	end

	-- Clean up stale sessions (player disconnected or timed out)
	for id, session in world:query(FishingSession) do
		if session.finished then
			world:despawn(id)
			activePlayerIds[session.playerId] = nil
		elseif os.clock() - session.startTime > FISHING_TIMEOUT then
			local player = game.Players:GetPlayerByUserId(session.playerId)
			if player then
				print(string.format("[FishingSystem] Session timed out for %s (%s)", player.Name, session.fishName))
			end
			world:despawn(id)
			activePlayerIds[session.playerId] = nil
		end
	end
end

-- Public API for checking if a player has an active session
function FishingSystem.hasActiveSession(playerId: number): boolean
	return activePlayerIds[playerId] == true
end

return FishingSystem
