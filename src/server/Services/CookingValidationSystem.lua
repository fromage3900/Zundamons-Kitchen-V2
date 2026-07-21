--!strict
-- CookingValidationSystem: Server cooking validation and rhythm minigame score system.
-- Validates recipe requirements, deducts raw ingredients, tracks note hit accuracy,
-- awards XP/Gold/Level progression via RewardCore, and delivers dishes directly to PlayerDataService inventory.

local Matter = require(game.ReplicatedStorage.Packages.Matter)
local CookingSession = require(game.ReplicatedStorage.components.cooking.CookingSession)
local CookingScore = require(game.ReplicatedStorage.components.cooking.CookingScore)

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local craftConfig = require(RS.ConfigurationFiles.CraftConfig)
local RewardCore = require(SSS.Services.RewardCore)
local ChefLevelConfig = require(RS.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(SSS.Services.PlayerDataService)

local QUALITY_BONUS = {
	perfect = { gold = 25, extraChance = 0.35 },
	great   = { gold = 10, extraChance = 0.0  },
	ok      = { gold = 0,  extraChance = 0.0  },
}

local CookingValidationSystemModule = {}

function CookingValidationSystemModule.validateIngredients(player: Player, recipeName: string): boolean
	local recipeDef = craftConfig.recipes[recipeName]
	if not recipeDef then return false end

	local ingredients = recipeDef.ingredients or recipeDef
	local data = PlayerDataService.get(player) or PlayerDataService.getOrCreate(player)
	for ingredient, requiredQty in pairs(ingredients) do
		if type(ingredient) == "string" and type(requiredQty) == "number" then
			local owned = data[ingredient]
			if not owned or owned < requiredQty then
				return false
			end
		end
	end
	return true
end

function CookingValidationSystemModule.deductIngredients(player: Player, recipeName: string): boolean
	if not CookingValidationSystemModule.validateIngredients(player, recipeName) then
		return false
	end

	local recipeDef = craftConfig.recipes[recipeName]
	local ingredients = recipeDef.ingredients or recipeDef
	local data = PlayerDataService.getOrCreate(player)
	for ingredient, requiredQty in pairs(ingredients) do
		if type(ingredient) == "string" and type(requiredQty) == "number" then
			data[ingredient] = (data[ingredient] or 0) - requiredQty
			if data[ingredient] <= 0 then
				data[ingredient] = nil
			end
		end
	end
	return true
end

local function CookingValidationSystem(world)
	-- Listen for CookingStartEvent from CraftManager / server scripts
	local startEvent = RS.RemoteEvents:FindFirstChild("CookingStartEvent")
	if startEvent then
		for _, player, item, position in Matter.useEvent(startEvent, "Event") do

			local recipeDef = craftConfig.recipes and craftConfig.recipes[item]
			local noteCount = (craftConfig.difficulty and craftConfig.difficulty[item] and craftConfig.difficulty[item].notes)
				or (recipeDef and recipeDef.notes) or 10
			local duration = math.max(craftConfig.cookingTimes and craftConfig.cookingTimes[item] or 15, (noteCount * 1.0) + 2.0 + 3.0)

			world:spawn(
				CookingSession({
					playerId = player.UserId,
					recipeId = item,
					position = position or Vector3.new(0, 0, 0),
					startTime = os.clock(),
					duration = duration,
				}),
				CookingScore({
					notesHit = {},
					perfectHits = 0,
					greatHits = 0,
					okHits = 0,
					misses = 0,
					totalNotes = noteCount,
				})
			)
			print(string.format("[CookingValidationSystem] Started session for %s: %s (%d notes)", player.Name, item, noteCount))
		end
	end

	-- Listen for CookingHit RemoteEvents from clients
	local hitEvent = RS.RemoteEvents:FindFirstChild("CookingHit")
	if hitEvent then
		for _, player, clientTick, quality in Matter.useEvent(hitEvent, "OnServerEvent") do

			for id, session, score in world:query(CookingSession, CookingScore) do
				if session.playerId == player.UserId then
					local hitCount = score.perfectHits + score.greatHits + score.okHits + score.misses
					if hitCount < score.totalNotes then
						if quality == "perfect" then
							score.perfectHits += 1
						elseif quality == "great" then
							score.greatHits += 1
						elseif quality == "ok" then
							score.okHits += 1
						else
							score.misses += 1
						end
						world:insert(id, score)
					end
					break
				end
			end
		end
	end

	-- Process completed sessions
	for id, session, score in world:query(CookingSession, CookingScore) do
		local timeElapsed = os.clock() - session.startTime
		if timeElapsed >= session.duration + 0.5 then
			local player = game.Players:GetPlayerByUserId(session.playerId)

			if player then
				local totalNotes = score.totalNotes
				local scoreList = {}
				for _ = 1, score.perfectHits do table.insert(scoreList, { tag = "perfect" }) end
				for _ = 1, score.greatHits do table.insert(scoreList, { tag = "great" }) end
				for _ = 1, score.okHits do table.insert(scoreList, { tag = "good" }) end

				local quality = craftConfig.calculateQuality(scoreList, totalNotes)
				local item = session.recipeId

				-- 1. Award Gold & Combo
				local bonus = QUALITY_BONUS[quality] or QUALITY_BONUS["ok"]
				if bonus.gold > 0 then
					RewardCore.bumpCombo(player)
					RewardCore.addGold(player, bonus.gold, quality == "perfect" and "perfect" or "craft")
				elseif quality == "ok" then
					RewardCore.breakCombo(player)
				end

				-- 2. Award Chef XP & Level Sync
				local craftXP = (quality == "perfect") and ChefLevelConfig.xpRewards.craftPerfect or ChefLevelConfig.xpRewards.craftSuccess
				RewardCore.addXP(player, craftXP, "craft")
				RewardCore.syncLevel(player)
				RewardCore.notify(player, "craft", { recipe = item, quality = quality })

				-- 3. Deliver cooked dish directly to player data inventory in PlayerDataService
				local dishAmount = 1
				if quality == "perfect" and bonus.extraChance > 0 and math.random() < bonus.extraChance then
					dishAmount = dishAmount + 1
				end

				PlayerDataService.update(player, function(d)
					d[item] = (d[item] or 0) + dishAmount
					if quality == "perfect" then
						d.perfect_cooks = (d.perfect_cooks or 0) + 1
						d.cooking_streak = (d.cooking_streak or 0) + 1
						d.max_cooking_streak = math.max(d.max_cooking_streak or 0, d.cooking_streak)
					elseif quality == "great" then
						d.great_cooks = (d.great_cooks or 0) + 1
						d.cooking_streak = (d.cooking_streak or 0) + 1
					else
						d.cooking_streak = 0
					end
					d.recipes_served_count = d.recipes_served_count or {}
					d.recipes_served_count[item] = (d.recipes_served_count[item] or 0) + 1
				end)

				-- 4. Notify client of cooking result
				pcall(function()
					local cookResultEvent = RS.RemoteEvents:FindFirstChild("CookingResult")
					if cookResultEvent then
						cookResultEvent:FireClient(player, {
							recipe = item,
							quality = quality,
							bonusGold = bonus.gold,
							dishCount = dishAmount,
						})
					end
				end)

				print(string.format("[CookingValidationSystem] Finished session for %s: %s (Quality: %s, Dishes: %d, Perfects: %d, Greats: %d, Ok: %d, Misses: %d)",
					player.Name, item, quality, dishAmount, score.perfectHits, score.greatHits, score.okHits, score.misses))
			end

			world:remove(id, CookingSession)
			world:remove(id, CookingScore)
		end
	end
end

setmetatable(CookingValidationSystemModule, {
	__call = function(_, world)
		return CookingValidationSystem(world)
	end
})

return CookingValidationSystemModule
