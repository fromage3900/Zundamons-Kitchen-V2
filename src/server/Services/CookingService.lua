--!strict
-- Server-authoritative cooking sessions with dynamic multi-lane rhythm evaluation.
-- Ingredients are journaled as a reservation; clients submit note-hit intent.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CookingSession = require(ReplicatedStorage.components.cooking.CookingSession)
local CraftConfig = require(ReplicatedStorage.ConfigurationFiles.CraftConfig)
local ChefLevelConfig = require(ReplicatedStorage.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local CompanionConfig = require(ReplicatedStorage.ConfigurationFiles.CompanionConfig)
local RhythmEngine = require(ReplicatedStorage.Rhythm.RhythmEngine)
local RhythmScoreEvaluator = require(ReplicatedStorage.Rhythm.RhythmScoreEvaluator)
local RhythmBeatmapConfig = require(ReplicatedStorage.ConfigurationFiles.RhythmBeatmapConfig)

local cookingResult = ReplicatedStorage.RemoteEvents:WaitForChild("CookingResult") :: RemoteEvent

local START_DELAY = 2.0
local NOTE_INTERVAL = 1.0
local BASE_PERFECT_WINDOW = 0.12
local GREAT_WINDOW = 0.28
local OK_WINDOW = 0.45
local BEGIN_COOLDOWN = 1.0
local MAX_STATION_DISTANCE = 24

local CookingService = {}
CookingService.CookCompleted = Instance.new("BindableEvent")
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

	-- Evaluate performance metrics via RhythmScoreEvaluator
	local evalResult = RhythmScoreEvaluator.evaluate({
		perfectHits = session.perfectHits,
		greatHits = session.greatHits,
		goodHits = session.goodHits or session.okHits,
		misses = session.misses,
		totalNotes = session.totalNotes,
		maxCombo = session.maxCombo,
		totalScore = session.totalScore,
		hitRecords = session.hitRecords,
	})

	local quality = evalResult.quality
	local grade = evalResult.grade

	local dishAmount = 1
	if quality == "perfect" and math.random() < 0.35 then
		dishAmount += 1
	end

	local baseBonusGold = quality == "perfect" and 25 or quality == "great" and 10 or 0
	local goldMultiplier = evalResult.goldBonusMultiplier or 1.0
	local finalBonusGold = math.floor(baseBonusGold * goldMultiplier)

	local xp = quality == "perfect" and ChefLevelConfig.xpRewards.craftPerfect or ChefLevelConfig.xpRewards.craftSuccess
	local reward = RewardCore.settle(player, {
		gold = finalBonusGold,
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

	local metrics = {
		grade = grade,
		quality = reward.ok and quality or "failed",
		accuracy = evalResult.accuracy,
		score = evalResult.totalScore,
		maxCombo = evalResult.maxCombo,
		stylePoints = evalResult.stylePoints,
		statXP = evalResult.statXP,
		counts = evalResult.counts,
		dishCount = reward.ok and dishAmount or 0,
		bonusGold = reward.ok and reward.gold or 0,
	}

	cookingResult:FireClient(player, {
		sessionId = session.sessionId,
		recipe = session.recipeId,
		quality = reward.ok and quality or "failed",
		grade = grade,
		score = evalResult.totalScore,
		accuracy = evalResult.accuracy,
		maxCombo = evalResult.maxCombo,
		bonusGold = reward.ok and reward.gold or 0,
		dishCount = reward.ok and dishAmount or 0,
		stylePoints = evalResult.stylePoints,
		statXP = evalResult.statXP,
		counts = evalResult.counts,
	})

	if reward.ok then
		CookingService.CookCompleted:Fire(player, session.recipeId, quality, metrics)
	end
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

	-- Precision stat & companion buffs calculation
	local data = PlayerDataService.get(player)
	local precisionPoints = (data and data.chef_stats and data.chef_stats.precision) or 0
	local baseWindows = RhythmEngine.getTimingWindows(precisionPoints)

	local activeComp = data and data.active_companion
	local def = activeComp and CompanionConfig.companions[activeComp]
	local buff = def and def.buff
	local perfectWindow = baseWindows.perfect
	if buff and buff.stat == "perfect_window" and buff.magnitude > 0 then
		perfectWindow = perfectWindow * (1 + buff.magnitude)
	end
	if def and def.signature_recipes and def.signature_recipes[recipeName] == true then
		perfectWindow = perfectWindow * 1.10
	end
	local greatWindow = baseWindows.great
	local goodWindow = baseWindows.good

	local cookingDuration = CraftConfig.cookingTimes[recipeName]
		or (CraftConfig.difficulty[recipeName] and (CraftConfig.difficulty[recipeName].notes * NOTE_INTERVAL))
		or 8.0
	local chart = RhythmBeatmapConfig.getChart(recipeName, cookingDuration, "normal")

	local serverTimeNow = workspace:GetServerTimeNow()
	local startDelay = chart.startDelay or START_DELAY
	local firstTargetAt = serverTimeNow + startDelay
	local totalNotes = chart.totalNotes or #chart.notes
	local noteInterval = 60 / chart.bpm

	local entityId = activeWorld:spawn(CookingSession({
		sessionId = sessionId,
		playerId = player.UserId,
		recipeId = recipeName,
		startTime = serverTimeNow,
		firstTargetAt = firstTargetAt,
		startDelay = startDelay,
		noteInterval = noteInterval,
		totalNotes = totalNotes,
		nextExpected = 1,
		perfectHits = 0,
		greatHits = 0,
		goodHits = 0,
		okHits = 0,
		misses = 0,
		currentCombo = 0,
		maxCombo = 0,
		totalScore = 0,
		chart = chart,
		hitRecords = {},
		windows = {
			perfect = perfectWindow,
			great = greatWindow,
			good = goodWindow,
		},
		perfectWindow = perfectWindow,
		greatWindow = greatWindow,
		okWindow = goodWindow,
		settled = false,
	}))
	activeByPlayer[player.UserId] = { entityId = entityId, sessionId = sessionId }
	return {
		ok = true,
		sessionId = sessionId,
		recipe = recipeName,
		chart = chart,
		totalNotes = totalNotes,
		firstTargetAt = firstTargetAt,
		startTime = serverTimeNow,
		startDelay = startDelay,
		noteInterval = noteInterval,
		perfectWindow = perfectWindow,
		greatWindow = greatWindow,
		okWindow = goodWindow,
		goodWindow = goodWindow,
		windows = {
			perfect = perfectWindow,
			great = greatWindow,
			good = goodWindow,
		},
	}
end

function CookingService.hit(player: Player, sessionId: any, noteIndex: any, laneId: any?)
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
		nextSession.hitRecords = session.hitRecords and table.clone(session.hitRecords) or {}
		local now = workspace:GetServerTimeNow()

		local okWindow = nextSession.okWindow or (nextSession.windows and nextSession.windows.good) or OK_WINDOW
		local greatWindow = nextSession.greatWindow
			or (nextSession.windows and nextSession.windows.great)
			or GREAT_WINDOW
		local perfectWindow = nextSession.perfectWindow
			or (nextSession.windows and nextSession.windows.perfect)
			or BASE_PERFECT_WINDOW

		local function getNoteTargetTime(idx: number): number
			if nextSession.chart and nextSession.chart.notes and nextSession.chart.notes[idx] then
				return nextSession.startTime + nextSession.chart.notes[idx].targetTime
			else
				return nextSession.firstTargetAt + (idx - 1) * nextSession.noteInterval
			end
		end

		-- Advance expired unhit notes before noteIndex
		while nextSession.nextExpected <= nextSession.totalNotes do
			local target = getNoteTargetTime(nextSession.nextExpected)
			if now <= target + okWindow then
				break
			end
			nextSession.misses += 1
			nextSession.currentCombo = 0
			table.insert(nextSession.hitRecords, {
				noteIndex = nextSession.nextExpected,
				judgment = "MISS",
				offset = now - target,
				score = 0,
			})
			nextSession.nextExpected += 1
		end

		if noteIndex ~= nextSession.nextExpected or noteIndex > nextSession.totalNotes then
			return
		end

		local targetTime = getNoteTargetTime(noteIndex)
		local difference = now - targetTime
		local absDiff = math.abs(difference)

		if absDiff > okWindow then
			if now > targetTime + okWindow then
				nextSession.misses += 1
				nextSession.currentCombo = 0
				table.insert(nextSession.hitRecords, {
					noteIndex = noteIndex,
					judgment = "MISS",
					offset = difference,
					score = 0,
				})
				nextSession.nextExpected += 1
				activeWorld:insert(entityId, CookingSession(nextSession))
			end
			return
		end

		local judgment: string
		local baseScore: number
		if absDiff <= perfectWindow then
			judgment = "PERFECT"
			baseScore = RhythmEngine.BASE_SCORES.PERFECT
			nextSession.perfectHits += 1
			nextSession.currentCombo += 1
		elseif absDiff <= greatWindow then
			judgment = "GREAT"
			baseScore = RhythmEngine.BASE_SCORES.GREAT
			nextSession.greatHits += 1
			nextSession.currentCombo += 1
		else
			judgment = "GOOD"
			baseScore = RhythmEngine.BASE_SCORES.GOOD
			nextSession.goodHits = (nextSession.goodHits or 0) + 1
			nextSession.okHits += 1
			nextSession.currentCombo += 1
		end

		nextSession.maxCombo = math.max(nextSession.maxCombo, nextSession.currentCombo)
		local mult = RhythmEngine.getComboMultiplier(nextSession.currentCombo)
		local hitScore = math.floor(baseScore * mult)
		nextSession.totalScore = (nextSession.totalScore or 0) + hitScore

		table.insert(nextSession.hitRecords, {
			noteIndex = noteIndex,
			laneId = laneId,
			judgment = judgment,
			offset = difference,
			score = hitScore,
		})

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

		local function getNoteTargetTime(idx: number): number
			if session.chart and session.chart.notes and session.chart.notes[idx] then
				return session.startTime + session.chart.notes[idx].targetTime
			else
				return session.firstTargetAt + (idx - 1) * session.noteInterval
			end
		end

		local okWindow = session.okWindow or (session.windows and session.windows.good) or OK_WINDOW
		local lastTargetAt = getNoteTargetTime(session.totalNotes)
		local finishAt = lastTargetAt + okWindow + 0.5

		if now >= finishAt then
			local complete = table.clone(session)
			complete.hitRecords = session.hitRecords and table.clone(session.hitRecords) or {}
			while complete.nextExpected <= complete.totalNotes do
				complete.misses += 1
				table.insert(complete.hitRecords, {
					noteIndex = complete.nextExpected,
					judgment = "MISS",
					offset = 0,
					score = 0,
				})
				complete.nextExpected += 1
			end
			complete.currentCombo = 0
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
