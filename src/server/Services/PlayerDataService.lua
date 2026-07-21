--!strict
-- PlayerDataService: canonical store for per-player progression/inventory data.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = require(ReplicatedStorage.ConfigurationFiles.ProgressionConfig)
local playerStateChanged = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlayerStateChanged")

local progressionStore = DataStoreService:GetDataStore("KitchenProgression")

local store: { [string]: { [string]: any } } = {}
local mutationLocks: { [string]: boolean } = {}

local PlayerDataService = {}

local createDefaultData: () -> { [string]: any }

local NON_INVENTORY_NUMBER_KEYS = {
	gold = true,
	total_gold_earned = true,
	guests_served = true,
	perfect_cooks = true,
	great_cooks = true,
	companion_affection = true,
	companion_chats = true,
	cooking_streak = true,
	max_cooking_streak = true,
	tier = true,
	recipes_unlocked_count = true,
	speed_cooks = true,
	total_fish_caught = true,
	data_revision = true,
}

local function cloneDictionary(value: any): any
	if type(value) == "table" then
		return table.clone(value)
	end
	return value
end

local function deepClone(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end
	local copies = seen or {}
	if copies[value] then
		return copies[value]
	end
	local copy = {}
	copies[value] = copy
	for key, child in pairs(value) do
		copy[deepClone(key, copies)] = deepClone(child, copies)
	end
	return copy
end

local function restoreSnapshot(data: { [string]: any }, snapshot: { [string]: any })
	for key in pairs(data) do
		data[key] = nil
	end
	for key, value in pairs(snapshot) do
		data[key] = value
	end
end

local function normalizeAliases(data: { [string]: any })
	if data["Wood"] or data["Wood Log"] then
		local syncVal = (data["Wood Log"] and data["Wood"] and math.max(data["Wood"], data["Wood Log"]))
			or data["Wood Log"]
			or data["Wood"]
			or 0
		data["Wood"] = syncVal
		data["Wood Log"] = syncVal
	end
end

local function buildProjection(data: { [string]: any }): { [string]: any }
	local inventory = {}
	for key, value in pairs(data) do
		if type(key) == "string" and type(value) == "number" and value > 0 and not NON_INVENTORY_NUMBER_KEYS[key] then
			inventory[key] = value
		end
	end

	return {
		revision = data.data_revision or 0,
		inventory = inventory,
		gold = data.gold or 0,
		totalGoldEarned = data.total_gold_earned or 0,
		guestsServed = data.guests_served or 0,
		tier = data.tier or 1,
		chef = cloneDictionary(data.chef) or { level = 1, xp = 0 },
		combo = cloneDictionary(data.combo) or { count = 0, multiplier = 1 },
		recipesUnlocked = cloneDictionary(data.recipes_unlocked) or {},
		recipesCookedCount = cloneDictionary(data.recipes_cooked_count) or {},
		recipesServedCount = cloneDictionary(data.recipes_served_count) or {},
		cookedDishes = deepClone(data.cooked_dishes) or {},
		totalFishCaught = data.total_fish_caught or 0,
		fishCaughtCount = cloneDictionary(data.fish_caught_count) or {},
	}
end

local function emitProjection(player: Player, data: { [string]: any })
	if player.Parent == Players then
		playerStateChanged:FireClient(player, buildProjection(data))
	end
end

function PlayerDataService.get(player: Player): { [string]: any }?
	local key = tostring(player.UserId)
	return store[key]
end

function PlayerDataService.getOrCreate(player: Player): { [string]: any }
	local key = tostring(player.UserId)
	if not store[key] then
		store[key] = createDefaultData()
	end
	return store[key]
end

function PlayerDataService.set(player: Player, data: { [string]: any })
	store[tostring(player.UserId)] = data
end

function PlayerDataService.clear(player: Player)
	local key = tostring(player.UserId)
	store[key] = nil
	mutationLocks[key] = nil
end

-- Mutators must not yield. Returning false rejects the transaction without
-- advancing the revision or emitting a projection.
function PlayerDataService.mutate(
	player: Player,
	reason: string,
	mutator: ({ [string]: any }) -> (boolean?, any?)
): (boolean, any?)
	local key = tostring(player.UserId)
	local data = store[key]
	if not data then
		return false, "data_not_loaded"
	end
	if mutationLocks[key] then
		return false, "mutation_in_progress"
	end

	mutationLocks[key] = true
	local snapshot = deepClone(data)
	local callOk, accepted, result = pcall(mutator, data)
	if not callOk then
		restoreSnapshot(data, snapshot)
		mutationLocks[key] = nil
		warn(string.format("[PlayerDataService] Mutation '%s' failed for %s", reason, player.Name))
		return false, "mutation_failed"
	end
	if accepted == false then
		restoreSnapshot(data, snapshot)
		mutationLocks[key] = nil
		return false, result or "rejected"
	end

	normalizeAliases(data)
	data.data_revision = (data.data_revision or 0) + 1
	mutationLocks[key] = nil
	emitProjection(player, data)
	return true, result
end

function PlayerDataService.update(player: Player, mutator: ({ [string]: any }) -> ()): boolean
	local ok = PlayerDataService.mutate(player, "legacy_update", function(data)
		mutator(data)
		return true
	end)
	return ok
end

function PlayerDataService.getProjection(player: Player): { [string]: any }?
	local data = PlayerDataService.get(player)
	if not data then
		return nil
	end
	return buildProjection(data)
end

function PlayerDataService.pushProjection(player: Player): boolean
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end
	emitProjection(player, data)
	return true
end

function PlayerDataService.getItemCount(player: Player, itemName: string): number
	local data = PlayerDataService.get(player)
	if not data or type(itemName) ~= "string" or itemName == "" then
		return 0
	end
	local value = data[itemName]
	return type(value) == "number" and math.max(0, value) or 0
end

function PlayerDataService.grantItem(player: Player, itemName: string, amount: number): (boolean, any?)
	if type(itemName) ~= "string" or itemName == "" or type(amount) ~= "number" or amount <= 0 then
		return false, "invalid_item_grant"
	end
	return PlayerDataService.mutate(player, "grant_item", function(data)
		data[itemName] = (data[itemName] or 0) + amount
		return true, { item = itemName, count = data[itemName] }
	end)
end

function PlayerDataService.consumeItem(player: Player, itemName: string, amount: number): (boolean, any?)
	if type(itemName) ~= "string" or itemName == "" or type(amount) ~= "number" or amount <= 0 then
		return false, "invalid_item_consume"
	end
	return PlayerDataService.mutate(player, "consume_item", function(data)
		local owned = data[itemName]
		if type(owned) ~= "number" or owned < amount then
			return false, "insufficient_items"
		end
		local remaining = owned - amount
		data[itemName] = remaining > 0 and remaining or nil
		return true, { item = itemName, count = remaining }
	end)
end

createDefaultData = function(): { [string]: any }
	local data = {
		gold = 50,
		total_gold_earned = 0,
		guests_served = 0,
		perfect_cooks = 0,
		great_cooks = 0,
		quests_completed = {},
		companion_affection = 0,
		companion_chats = 0,
		cooking_streak = 0,
		max_cooking_streak = 0,
		tier = 1,
		recipes_unlocked = {},
		cosmetics_unlocked = {},
		furniture_unlocked = {},
		locations_unlocked = {},
		owned_clothing = {},
		owned_decorations = {},
		owned_plot = nil,
		placed_furniture = {},
		recipes_unlocked_count = 0,
		recipes_cooked_count = {},
		recipes_served_count = {},
		speed_cooks = 0,
		total_fish_caught = 0,
		fish_caught_count = {},
		cooked_dishes = {},
		cooking_reservation = nil,
		gathered_items = {},
		companions_set = {},
		npc_chats = {},
		zones_visited = {},
		Apple = 5,
		Wheat = 5,
		Wood = 5,
		["Wood Log"] = 5,
		Rock = 5,
		["Iron Ore"] = 3,
		data_revision = 0,
	}

	for _, recipe in ipairs(CONFIG.milestones[1].unlocks.recipes) do
		table.insert(data.recipes_unlocked, recipe)
	end
	for _, cosmetic in ipairs(CONFIG.milestones[1].unlocks.cosmetics) do
		table.insert(data.cosmetics_unlocked, cosmetic)
	end
	for _, furniture in ipairs(CONFIG.milestones[1].unlocks.furniture) do
		table.insert(data.furniture_unlocked, furniture)
	end
	for _, location in ipairs(CONFIG.milestones[1].unlocks.locations) do
		table.insert(data.locations_unlocked, location)
	end

	return data
end

local function backfillLoadedData(loaded: { [string]: any })
	if loaded.gold == nil then
		loaded.gold = loaded.current_gold or loaded.Gold or 0
	end
	loaded.current_gold = nil
	loaded.Gold = nil
	normalizeAliases(loaded)
	loaded.data_revision = loaded.data_revision or 0
	loaded.recipes_cooked_count = loaded.recipes_cooked_count or {}
	loaded.recipes_served_count = loaded.recipes_served_count or {}
	loaded.total_fish_caught = loaded.total_fish_caught or 0
	loaded.fish_caught_count = loaded.fish_caught_count or {}
	loaded.cooked_dishes = loaded.cooked_dishes or {}
	-- A persisted reservation means the prior server ended before settlement.
	-- Restore its ingredients once during load, then clear the journal.
	if type(loaded.cooking_reservation) == "table" then
		local ingredients = loaded.cooking_reservation.ingredients
		if type(ingredients) == "table" then
			for ingredient, amount in pairs(ingredients) do
				if type(ingredient) == "string" and type(amount) == "number" and amount > 0 then
					loaded[ingredient] = (loaded[ingredient] or 0) + amount
				end
			end
		end
		loaded.cooking_reservation = nil
	end
	if loaded.owned_clothing == nil then
		loaded.owned_clothing = {}
	end
	if loaded.owned_decorations == nil then
		loaded.owned_decorations = {}
	end
	if loaded.owned_plot == nil then
		loaded.owned_plot = nil
	end
	if loaded.placed_furniture == nil then
		loaded.placed_furniture = {}
	end
end

function PlayerDataService.loadPlayer(player: Player)
	local userId = player.UserId
	local success, playerData = pcall(function()
		return progressionStore:GetAsync("player_" .. userId)
	end)

	if success and playerData then
		local loaded = playerData
		backfillLoadedData(loaded)
		store[tostring(player.UserId)] = loaded
		print("[PlayerDataService] Loaded progression for " .. player.Name)
	else
		store[tostring(player.UserId)] = createDefaultData()
		print("[PlayerDataService] Created new progression for " .. player.Name)
	end
end

function PlayerDataService.savePlayer(player: Player)
	local data = store[tostring(player.UserId)]
	if not data then
		return
	end

	local ok, err = pcall(function()
		progressionStore:SetAsync("player_" .. player.UserId, data)
	end)

	if ok then
		print("[PlayerDataService] Saved progression for " .. player.Name)
	else
		print("[PlayerDataService] Failed to save " .. player.Name .. ": " .. tostring(err))
	end

	store[tostring(player.UserId)] = nil
	mutationLocks[tostring(player.UserId)] = nil
end

function PlayerDataService.checkAndUnlockTiers(player: Player)
	local data = store[tostring(player.UserId)]
	if not data then
		return
	end

	local currentTier = data.tier
	for milestoneId = currentTier + 1, #CONFIG.milestones do
		local milestone = CONFIG.milestones[milestoneId]
		if data.guests_served >= milestone.guests_served then
			data.tier = milestoneId
			local newRecipes = {}
			for _, recipe in ipairs(milestone.unlocks.recipes) do
				if not table.find(data.recipes_unlocked, recipe) then
					table.insert(data.recipes_unlocked, recipe)
					table.insert(newRecipes, recipe)
				end
			end
			for _, cosmetic in ipairs(milestone.unlocks.cosmetics) do
				if not table.find(data.cosmetics_unlocked, cosmetic) then
					table.insert(data.cosmetics_unlocked, cosmetic)
				end
			end
			for _, furniture in ipairs(milestone.unlocks.furniture) do
				if not table.find(data.furniture_unlocked, furniture) then
					table.insert(data.furniture_unlocked, furniture)
				end
			end
			for _, location in ipairs(milestone.unlocks.locations) do
				if not table.find(data.locations_unlocked, location) then
					table.insert(data.locations_unlocked, location)
				end
			end
			if #newRecipes > 0 then
				local reFolder = game.ReplicatedStorage:WaitForChild("RemoteEvents")
				local unlockEv = reFolder:FindFirstChild("RecipeUnlocked")
				if not unlockEv then
					unlockEv = Instance.new("RemoteEvent")
					unlockEv.Name = "RecipeUnlocked"
					unlockEv.Parent = reFolder
				end
				unlockEv:FireClient(player, { tier = milestoneId, tierName = milestone.name, recipes = newRecipes })
			end
			print("[PlayerDataService] " .. player.Name .. " unlocked tier " .. milestoneId .. ": " .. milestone.name)
		end
	end
end

local RF = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions")
local markTut = RF:FindFirstChild("MarkTutorialDone")
if not markTut then
	markTut = Instance.new("RemoteFunction")
	markTut.Name = "MarkTutorialDone"
	markTut.Parent = RF
end
markTut.OnServerInvoke = function(player)
	local d = PlayerDataService.getOrCreate(player)
	d.tutorial_done = true
	return true
end

-- Periodic auto-save every 60s to prevent data loss on server crash
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = store[tostring(player.UserId)]
			if data then
				local ok, err = pcall(function()
					progressionStore:SetAsync("player_" .. player.UserId, data)
				end)
				if not ok then
					print("[PlayerDataService] Auto-save failed for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.loadPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.savePlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not store[tostring(player.UserId)] then
		PlayerDataService.loadPlayer(player)
	end
end

return PlayerDataService
