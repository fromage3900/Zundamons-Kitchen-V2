-- [[Script] CraftManager (ref: RBX1C358C3F233C41328CB4C3F0B82DD2B3)]]
-- CraftManager: Server-side handler for CraftFunction.
-- Supports a timed-cooking quality parameter ("perfect", "great", "ok")
-- which grants bonus gold + (on perfect) a small chance at a bonus dish.
local RS  = game.ReplicatedStorage
local RF  = RS:WaitForChild("RemoteFunctions")
local RE  = RS:WaitForChild("RemoteEvents")
local craftfunction = RF:WaitForChild("CraftFunction")
local configFiles = RS:WaitForChild("ConfigurationFiles")
local craftConfig = require(configFiles:WaitForChild("CraftConfig"))
local craftData = craftConfig.recipes
local loot_module = require(configFiles:WaitForChild("LootModule"))
local RewardCore = require(configFiles:WaitForChild("RewardCore"))
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

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

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

-- Shared quality calc from CraftConfig (replaces trust from client)
local function craftItem(player, item, position, scores)
    if not checkRate(player) then return "Fail" end
    local quality = "ok"
    if scores and type(scores) == "table" and #scores > 0 then
        local diff = craftConfig.difficulty[item] or craftConfig.defaultDifficulty
        if #scores <= diff.notes then
            quality = craftConfig.calculateQuality(scores, diff.notes)
        end
    end
    if not QUALITY_BONUS[quality] then quality = "ok" end

    local values = craftData[item]
    if not values then return "Fail" end

    local bucket = ensureDataBucket(player)

    -- Check that the player has every ingredient in the right amount
    for key, value in pairs(values) do
        local owned = bucket[key]
        if not owned or owned < value then
            return "Fail"
        end
    end

    -- Deduct ingredients
    for key, value in pairs(values) do
        bucket[key] -= value
        if bucket[key] <= 0 then
            bucket[key] = nil
        end
    end

    -- Award the crafted dish as a world drop (with quality attribute)
    loot_module.generateLoot(player, {item}, position, quality)

    -- Perfect bonus: small chance at an extra dish
    local bonus = QUALITY_BONUS[quality]
    if bonus.extraChance > 0 and math.random() < bonus.extraChance then
        loot_module.generateLoot(player, {item}, position + Vector3.new(0, 1, 0), quality)
    end

    -- Bonus gold for great/perfect timing (combo-multiplied)
    if bonus.gold > 0 then
        RewardCore.bumpCombo(player)
        RewardCore.addGold(player, bonus.gold, quality == "perfect" and "perfect" or "craft")
    elseif quality == "ok" then
        RewardCore.breakCombo(player)
    end

    -- XP for crafting
    local craftXP = (quality == "perfect") and ChefLevelConfig.xpRewards.craftPerfect or ChefLevelConfig.xpRewards.craftSuccess
    RewardCore.addXP(player, craftXP, "craft")
    RewardCore.notify(player, "craft", { recipe = item, quality = quality })

    -- Notify client (for VN flair, particles, etc.)
    pcall(function()
        cookResultEvent:FireClient(player, {
            recipe = item,
            quality = quality,
            bonusGold = bonus.gold,
        })
    end)

    -- Check if first time crafting this recipe (for side dialogue trigger)
    local RE_re = RS:WaitForChild("RemoteEvents")
    local sideDlgRE = RE_re:FindFirstChild("TriggerSideDialogue")
    local bucket_before = PlayerDataService.get(player)
    if not bucket_before then return "ok" end
    local was_first_craft = not bucket_before.recipes_served_count or not bucket_before.recipes_served_count[item]

    -- Track cooking quality for quest system
    PlayerDataService.update(player, function(d)
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
        if not d.recipes_served_count then d.recipes_served_count = {} end
        d.recipes_served_count[item] = (d.recipes_served_count[item] or 0) + 1
        -- Track speed cooks (cooking time ≤ threshold)
        if quality == "perfect" or quality == "great" then
            local cookTime = craftConfig.cookingTimes[item] or 5
            if cookTime <= 4 then
                d.speed_cooks = (d.speed_cooks or 0) + 1
            end
        end
    end)

    -- Trigger side dialogue on first-time craft
    if was_first_craft and sideDlgRE then
        local dlgKey = ({
            ["Antimon's Speed Soup"] = "antimon_speed_soup",
            ["Cardamon's Calm Cup"] = "cardamon_calm_cup",
            ["Seasonal Salad"] = "seasonal_salad",
            ["Sakuradamon's Blossom Bites"] = "sakuradamon_blossom_bites",
            ["Warm Winter Stew"] = "warm_winter_stew",
            ["Ankomon's Protein Punch"] = "ankomon_protein_punch",
            ["Golden Harvest Platter"] = "golden_harvest_platter",
            ["Zunda Mochi"] = "zunda_mochi",
            ["Royal Stew"] = "royal_stew",
        })[item]
        if dlgKey then
            pcall(function() sideDlgRE:FireClient(player, dlgKey) end)
        end
    end

    return "Success"
end

craftfunction.OnServerInvoke = craftItem

-- Memory cleanup
local Players = game:GetService("Players")
Players.PlayerRemoving:Connect(function(p) lastCraft[p] = nil end)