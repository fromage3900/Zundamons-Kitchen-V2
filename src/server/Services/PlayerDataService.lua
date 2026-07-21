--!strict
-- PlayerDataService: canonical store for per-player progression/inventory data.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CONFIG = require(game.ReplicatedStorage.ConfigurationFiles.ProgressionConfig)

local progressionStore = DataStoreService:GetDataStore("KitchenProgression")

local store: { [string]: { [string]: any } } = {}

local PlayerDataService = {}

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
	store[tostring(player.UserId)] = nil
end

function PlayerDataService.update(player: Player, mutator: ({ [string]: any }) -> ())
	local data = PlayerDataService.getOrCreate(player)
	mutator(data)
end

local function createDefaultData(): { [string]: any }
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
		recipes_served_count = {},
		speed_cooks = 0,
		gathered_items = {},
		companions_set = {},
		npc_chats = {},
		zones_visited = {},
		Apple = 5,
		Wheat = 5,
		Wood = 5,
		Rock = 5,
		["Iron Ore"] = 3,
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
	markTut = Instance.new("RemoteFunction"); markTut.Name = "MarkTutorialDone"; markTut.Parent = RF
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
				pcall(function()
					progressionStore:SetAsync("player_" .. player.UserId, data)
				end)
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

-- Auto-save every 60 seconds to prevent data loss
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

return PlayerDataService
