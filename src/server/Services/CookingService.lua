--!strict
-- Server-authoritative cooking sessions. Ingredients are journaled as a
-- reservation; clients submit only session and note-index intent.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CookingSession = require(ReplicatedStorage.components.cooking.CookingSession)
local CraftConfig = require(ReplicatedStorage.ConfigurationFiles.CraftConfig)
local ChefLevelConfig = require(ReplicatedStorage.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)

local cookingResult = ReplicatedStorage.RemoteEvents:WaitForChild("CookingResult") :: RemoteEvent

local START_DELAY = 2.0
local NOTE_INTERVAL = 1.0
local PERFECT_WINDOW = 0.2
local GREAT_WINDOW = 0.42
local OK_WINDOW = 0.72
local BEGIN_COOLDOWN = 1.0
local MAX_STATION_DISTANCE = 24

local CookingService = {}
local activeWorld: any = nil
local activeByPlayer: { [number]: { entityId: any, sessionId: string } } = {}
local lastBeginAt: { [number]: number } = {}

local function recipeIngredients(recipeName: string): { [string]: number }?
	local recipe = CraftConfig.recipes[recipeName]
	if type(recipe) ~= "table" then
		return nil
	end
	local ingredients = {}
	for ingredient, amount in pairs(recipe.ingredients or recipe) do
		if type(ingredient) == "string" and type(amount) == "number" and amount > 0 then
			ingredients[ingredient] = amount
		end
	end
	return next(ingredients) and ingredients or nil
end

local function recipeUnlocked(data: any, recipeName: string): boolean
	return type(data.recipes_unlocked) == "table" and table.find(data.recipes_unlocked, recipeName) ~= nil
end

local function validCharacter(player: Player, requestedPosition: any): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	if
		typeof(requestedPosition) == "Vector3"
		and (root.Position - requestedPosition).Magnitude > MAX_STATION_DISTANCE
	then
		return false
	end
	return true
end

local function refund(player: Player, sessionId: string): boolean
	local ok = PlayerDataService.mutate(player, "cooking_refund", function(data)
		local reservation = data.cooking_reservation
		if type(reservation) ~= "table" or reservation.sessionId ~= sessionId then
			return false, "reservation_missing"
		end
		for ingredient, amount in pairs(reservation.ingredients) do
			data[ingredient] = (data[ingredient] or 0) + amount
		end
		data.cooking_reservation = nil
		return true
	end)
	return ok
end

local function qualityFor(session: any): string
	if session.perfectHits == session.totalNotes or session.perfectHits >= math.ceil(session.totalNotes * 0.6) then
		return "perfect"
	end
	if session.perfectHits + session.greatHits + session.okHits >= math.ceil(session.totalNotes * 0.5) then
		return "great"
	end
	return "ok"
end

local function finish(world: any, entityId: any, session: any)
	if session.settled then
		return
	end
	local settled = table.clone(session)
	settled.settled = true
	world:insert(entityId, CookingSession(settled))
	activeByPlayer[session.playerId] = nil
	local player = Players:GetPlayerByUserId(session.playerId)
	if not player then
		world:despawn(entityId)
		return
	end

	local quality = qualityFor(session)
	local dishAmount = 1
	if quality == "perfect" and math.random() < 0.35 then
		dishAmount += 1
	end
	local bonusGold = quality == "perfect" and 25 or quality == "great" and 10 or 0
	local xp = quality == "perfect" and ChefLevelConfig.xpRewards.craftPerfect or ChefLevelConfig.xpRewards.craftSuccess
	local reward = RewardCore.settle(player, {
		gold = bonusGold,
		xp = xp,
		reason = quality == "perfect" and "perfect" or "craft",
		combo = quality ~= "ok",
		breakCombo = quality == "ok",
		popupItem = string.format("%dx %s", dishAmount, session.recipeId),
	}, function(data)
		local reservation = data.cooking_reservation
		if type(reservation) ~= "table" or reservation.sessionId ~= session.sessionId then
			return false, "reservation_missing"
		end
		data.cooking_reservation = nil
		data[session.recipeId] = (data[session.recipeId] or 0) + dishAmount
		data.cooked_dishes = data.cooked_dishes or {}
		data.cooked_dishes[session.recipeId] = data.cooked_dishes[session.recipeId] or {}
		data.cooked_dishes[session.recipeId][quality] = (data.cooked_dishes[session.recipeId][quality] or 0)
			+ dishAmount
		data.recipes_cooked_count = data.recipes_cooked_count or {}
		data.recipes_cooked_count[session.recipeId] = (data.recipes_cooked_count[session.recipeId] or 0) + dishAmount
		if quality == "perfect" then
			data.perfect_cooks = (data.perfect_cooks or 0) + 1
			data.cooking_streak = (data.cooking_streak or 0) + 1
			data.max_cooking_streak = math.max(data.max_cooking_streak or 0, data.cooking_streak)
		elseif quality == "great" then
			data.great_cooks = (data.great_cooks or 0) + 1
			data.cooking_streak = (data.cooking_streak or 0) + 1
		else
			data.cooking_streak = 0
		end
		return true
	end)

	cookingResult:FireClient(player, {
		sessionId = session.sessionId,
		recipe = session.recipeId,
		quality = reward.ok and quality or "failed",
		bonusGold = reward.ok and reward.gold or 0,
		dishCount = reward.ok and dishAmount or 0,
	})
	world:despawn(entityId)
end

function CookingService.attachWorld(world: any)
	if activeWorld and activeWorld ~= world then
		error("CookingService cannot attach to multiple Matter worlds")
	end
	activeWorld = world
end

function CookingService.begin(player: Player, recipeName: any, requestedPosition: any): { [string]: any }
	if not activeWorld then
		return { ok = false, reason = "cooking_not_ready" }
	end
	if type(recipeName) ~= "string" then
		return { ok = false, reason = "invalid_recipe" }
	end
	local ingredients = recipeIngredients(recipeName)
	if not ingredients then
		return { ok = false, reason = "invalid_recipe" }
	end
	if not validCharacter(player, requestedPosition) then
		return { ok = false, reason = "invalid_station" }
	end
	if activeByPlayer[player.UserId] then
		return { ok = false, reason = "session_active" }
	end
	local now = os.clock()
	if now - (lastBeginAt[player.UserId] or 0) < BEGIN_COOLDOWN then
		return { ok = false, reason = "rate_limited" }
	end
	lastBeginAt[player.UserId] = now
	local sessionId = HttpService:GenerateGUID(false)
	local reserved = PlayerDataService.mutate(player, "cooking_reserve", function(data)
		if not recipeUnlocked(data, recipeName) then
			return false, "recipe_locked"
		end
		if data.cooking_reservation ~= nil then
			return false, "reservation_active"
		end
		for ingredient, amount in pairs(ingredients) do
			if type(data[ingredient]) ~= "number" or data[ingredient] < amount then
				return false, "insufficient_ingredients"
			end
		end
		for ingredient, amount in pairs(ingredients) do
			data[ingredient] -= amount
			if data[ingredient] <= 0 then
				data[ingredient] = nil
			end
		end
		data.cooking_reservation =
			{ sessionId = sessionId, recipe = recipeName, ingredients = table.clone(ingredients) }
		return true
	end)
	if not reserved then
		return { ok = false, reason = "ingredients_unavailable" }
	end

	local totalNotes = CraftConfig.difficulty[recipeName] and CraftConfig.difficulty[recipeName].notes
		or CraftConfig.defaultDifficulty.notes
	local firstTargetAt = workspace:GetServerTimeNow() + START_DELAY
	local entityId = activeWorld:spawn(CookingSession({
		sessionId = sessionId,
		playerId = player.UserId,
		recipeId = recipeName,
		startTime = workspace:GetServerTimeNow(),
		firstTargetAt = firstTargetAt,
		noteInterval = NOTE_INTERVAL,
		totalNotes = totalNotes,
		nextExpected = 1,
		perfectHits = 0,
		greatHits = 0,
		okHits = 0,
		misses = 0,
		settled = false,
	}))
	activeByPlayer[player.UserId] = { entityId = entityId, sessionId = sessionId }
	return {
		ok = true,
		sessionId = sessionId,
		recipe = recipeName,
		totalNotes = totalNotes,
		firstTargetAt = firstTargetAt,
		noteInterval = NOTE_INTERVAL,
	}
end

function CookingService.hit(player: Player, sessionId: any, noteIndex: any)
	if type(sessionId) ~= "string" or type(noteIndex) ~= "number" or noteIndex % 1 ~= 0 then
		return
	end
	local active = activeByPlayer[player.UserId]
	if not active or active.sessionId ~= sessionId or not activeWorld then
		return
	end
	for entityId, session in activeWorld:query(CookingSession) do
		if entityId ~= active.entityId then
			continue
		end
		local nextSession = table.clone(session)
		local now = workspace:GetServerTimeNow()
		while nextSession.nextExpected <= nextSession.totalNotes do
			local target = nextSession.firstTargetAt + (nextSession.nextExpected - 1) * nextSession.noteInterval
			if now <= target + OK_WINDOW then
				break
			end
			nextSession.misses += 1
			nextSession.nextExpected += 1
		end
		if noteIndex ~= nextSession.nextExpected or noteIndex > nextSession.totalNotes then
			return
		end
		local target = nextSession.firstTargetAt + (noteIndex - 1) * nextSession.noteInterval
		local difference = math.abs(now - target)
		if difference > OK_WINDOW then
			return
		end
		if difference <= PERFECT_WINDOW then
			nextSession.perfectHits += 1
		elseif difference <= GREAT_WINDOW then
			nextSession.greatHits += 1
		else
			nextSession.okHits += 1
		end
		nextSession.nextExpected += 1
		activeWorld:insert(entityId, CookingSession(nextSession))
		return
	end
end

function CookingService.step(world: any)
	CookingService.attachWorld(world)
	local now = workspace:GetServerTimeNow()
	for entityId, session in world:query(CookingSession) do
		if session.settled then
			continue
		end
		local player = Players:GetPlayerByUserId(session.playerId)
		if not player then
			world:despawn(entityId)
			activeByPlayer[session.playerId] = nil
			continue
		end
		if not validCharacter(player, nil) then
			refund(player, session.sessionId)
			world:despawn(entityId)
			activeByPlayer[session.playerId] = nil
			continue
		end
		local finishAt = session.firstTargetAt + (session.totalNotes - 1) * session.noteInterval + OK_WINDOW
		if now >= finishAt then
			local complete = table.clone(session)
			complete.misses += complete.totalNotes - complete.nextExpected + 1
			complete.nextExpected = complete.totalNotes + 1
			finish(world, entityId, complete)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	lastBeginAt[player.UserId] = nil
	local active = activeByPlayer[player.UserId]
	if not active then
		return
	end
	refund(player, active.sessionId)
	if activeWorld then
		activeWorld:despawn(active.entityId)
	end
	activeByPlayer[player.UserId] = nil
end)

return CookingService
