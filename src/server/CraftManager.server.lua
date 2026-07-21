-- [[Script] CraftManager (ref: RBX1C358C3F233C41328CB4C3F0B82DD2B3)]]
-- CraftManager: Server-side handler for CraftFunction.
-- Supports a timed-cooking quality parameter ("perfect", "great", "ok")
-- which grants bonus gold + (on perfect) a small chance at a bonus dish.
local RS  = game.ReplicatedStorage
local SSS = game:GetService("ServerScriptService")
local RF  = RS:WaitForChild("RemoteFunctions")
local RE  = RS:WaitForChild("RemoteEvents")
local craftfunction = RF:WaitForChild("CraftFunction")
local configFiles = RS:WaitForChild("ConfigurationFiles")
local craftConfig = require(configFiles:WaitForChild("CraftConfig"))
local craftData = craftConfig.recipes
local loot_module = require(configFiles:WaitForChild("LootModule"))
local RewardCore = require(SSS.Services.RewardCore)
local ChefLevelConfig = require(configFiles:WaitForChild("ChefLevelConfig"))

-- Optional: notify clients of cooking results so VN/HUD can react
local cookResultEvent = RE:FindFirstChild("CookingResult")
if not cookResultEvent then
    cookResultEvent = Instance.new("RemoteEvent")
    cookResultEvent.Name = "CookingResult"
    cookResultEvent.Parent = RE
end

-- Quality → bonus gold and extra-dish chance
local QUALITY_BONUS = {
    perfect = { gold = 25, extraChance = 0.35 },
    great   = { gold = 10, extraChance = 0.0  },
    ok      = { gold = 0,  extraChance = 0.0  },
}

local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)

local function ensureDataBucket(player)
	return PlayerDataService.getOrCreate(player)
end

-- Rate limiter: 1 craft per second per player
local lastCraft = {}
local function checkRate(player)
	local now = os.clock()
	local last = lastCraft[player]
	if last and now - last < 1 then return false end
	lastCraft[player] = now
	return true
end

local SSS = game:GetService("ServerScriptService")
local cookingStartEvent = SSS:FindFirstChild("CookingStartEvent")
if not cookingStartEvent then
	cookingStartEvent = Instance.new("BindableEvent")
	cookingStartEvent.Name = "CookingStartEvent"
	cookingStartEvent.Parent = SSS
end

local CookingValidationSystem = require(SSS.Services.CookingValidationSystem)

local function craftItem(player, item, position)
    if not checkRate(player) then return "Fail" end

    local values = craftData[item]
    if not values then return "Fail" end

    if not CookingValidationSystem.validateIngredients(player, item) then
        return "Fail"
    end

    if not CookingValidationSystem.deductIngredients(player, item) then
        return "Fail"
    end

	-- Trigger ECS Cooking Session
	cookingStartEvent:Fire(player, item, position)
    return "Cooking"
end

craftfunction.OnServerInvoke = craftItem

-- Memory cleanup
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(p) lastCraft[p] = nil end)
