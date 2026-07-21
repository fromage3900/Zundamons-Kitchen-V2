-- [[Script] AdvancedRewards (ref: RBX8A0BF27E24424EAEB517610C64B69B30)]]
-- AdvancedRewards: subscribes to RewardCore.notify and runs
-- recipe mastery, guest reputation, daily quests, achievements, login bonus, power-ups.
local Players = game:GetService("Players")
local RS = game.ReplicatedStorage
local SSS = game.ServerScriptService

local RewardCore = require(RS.ConfigurationFiles.RewardCore)
local ChefLevelConfig = require(RS.ConfigurationFiles.ChefLevelConfig)
local AchievementConfig = require(RS.ConfigurationFiles.AchievementConfig)
local DailyQuestConfig = require(RS.ConfigurationFiles.DailyQuestConfig)
local PowerupConfig = require(RS.ConfigurationFiles.PowerupConfig)
local ToolManager = require(SSS:WaitForChild("ToolManager", 10) or SSS.ToolManager)
local ToolsConfig = require(RS.ConfigurationFiles.ToolsConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local rewardEvents = RS:WaitForChild("RewardEvents")
local NotifyAction = rewardEvents:WaitForChild("NotifyAction")
local PopupEvent = rewardEvents:WaitForChild("PopupEvent")
local AchievementUnlocked = rewardEvents:WaitForChild("AchievementUnlocked")

-- Additional remotes for daily / powerups / upgrades
local function ensureRemote(name, class)
    local r = rewardEvents:FindFirstChild(name)
    if not r then r = Instance.new(class); r.Name = name; r.Parent = rewardEvents end
    return r
end
local DailyUpdate = ensureRemote("DailyUpdate", "RemoteEvent")
local LoginBonusEvent = ensureRemote("LoginBonusEvent", "RemoteEvent")
local PowerupUpdate = ensureRemote("PowerupUpdate", "RemoteEvent")
local UsePowerup = ensureRemote("UsePowerup", "RemoteFunction")
local UpgradeTool = ensureRemote("UpgradeTool", "RemoteFunction")
local GetCompendium = ensureRemote("GetCompendium", "RemoteFunction")

-- Debounce table for rate limiting
local remoteDebounce = {}
local function isSpamming(player, action, interval)
    local now = os.clock()
    local key = player.UserId .. "_" .. action
    if remoteDebounce[key] and (now - remoteDebounce[key]) < (interval or 1) then
        return true
    end
    remoteDebounce[key] = now
    return false
end

------------------------------------------------------------------
-- Daily login
------------------------------------------------------------------
local function dayNumber()
    return math.floor(os.time() / 86400)
end

local function handleLogin(player)
    local d = PlayerDataService.get(player)
    if not d then return end
    local today = dayNumber()
    if d.daily.lastClaimDay == today then return end
    local cfg = DailyQuestConfig.loginBonus
    if d.daily.lastClaimDay == today - 1 then
        d.daily.streak = math.min(d.daily.streak + 1, cfg.capDays)
    else
        d.daily.streak = 1
    end
    d.daily.lastClaimDay = today
    -- pick today's quest
    local q = DailyQuestConfig.pool[math.random(1, #DailyQuestConfig.pool)]
    d.daily.todayQuestId = q.id
    d.daily.todayProgress = 0
    d.daily.todayClaimed = false
    -- award login bonus
    local bonus = cfg.baseGold + cfg.streakBonus * (d.daily.streak - 1)
    RewardCore.addGold(player, bonus, "login")
    RewardCore.addXP(player, ChefLevelConfig.xpRewards.dailyLogin, "login")
    LoginBonusEvent:FireClient(player, d.daily.streak, bonus, q)
    DailyUpdate:FireClient(player, q, d.daily.todayProgress, false)
end

------------------------------------------------------------------
-- Subsystem trackers (all hooked from NotifyAction)
------------------------------------------------------------------
local function unlockAchievement(player, ach)
    local d = PlayerDataService.get(player)
    if d.achievements[ach.id] then return end
    d.achievements[ach.id] = true
    AchievementUnlocked:FireClient(player, ach.name, ach.desc, ach.icon)
    RewardCore.addGold(player, 25, "achievement")
    RewardCore.addXP(player, 50, "achievement")
end

local function checkAchievements(player, metrics)
    local d = PlayerDataService.get(player)
    for _, ach in ipairs(AchievementConfig) do
        if not d.achievements[ach.id] then
            local val = metrics[ach.metric]
            if val and val >= ach.goal then
                unlockAchievement(player, ach)
            end
        end
    end
end

local function gatherMetrics(d)
    local maxRep = 0
    for _, v in pairs(d.guestRep) do if v > maxRep then maxRep = v end end
    local maxMastery, masteredCount = 0, 0
    for _, m in pairs(d.mastery) do
        if m.level and m.level > maxMastery then maxMastery = m.level end
        if m.level and m.level >= 5 then masteredCount = masteredCount + 1 end
    end
    local maxToolTier = 1
    for _, v in pairs(d.toolTiers) do if v > maxToolTier then maxToolTier = v end end
    return {
        guestsServed     = d.stats and d.stats.guestsServed or 0,
        perfectCooks     = d.stats and d.stats.perfectCooks or 0,
        maxCombo         = d.stats and d.stats.maxCombo or 0,
        totalGather      = d.stats and d.stats.totalGather or 0,
        totalGold        = d.stats and d.stats.totalGold or 0,
        chefLevel        = d.chef.level,
        maxRep           = maxRep,
        maxMastery       = maxMastery,
        masteredCount    = masteredCount,
        maxToolTier      = maxToolTier,
        loginStreak      = d.daily.streak,
        powerupsUsed     = d.stats and d.stats.powerupsUsed or 0,
        dailyQuestsDone  = d.stats and d.stats.dailyQuestsDone or 0,
    }
end

local function bumpStat(d, name, delta)
    d.stats = d.stats or {}
    d.stats[name] = (d.stats[name] or 0) + (delta or 1)
end

local function setMaxStat(d, name, value)
    d.stats = d.stats or {}
    if (d.stats[name] or 0) < value then d.stats[name] = value end
end

------------------------------------------------------------------
-- Daily quest progress
------------------------------------------------------------------
local function progressDaily(player, metric, amount)
    local d = PlayerDataService.get(player)
    if not d.daily.todayQuestId or d.daily.todayClaimed then return end
    local q
    for _, p in ipairs(DailyQuestConfig.pool) do
        if p.id == d.daily.todayQuestId then q = p break end
    end
    if not q or q.metric ~= metric then return end
    d.daily.todayProgress = d.daily.todayProgress + (amount or 1)
    if d.daily.todayProgress >= q.goal then
        d.daily.todayClaimed = true
        d.daily.todayProgress = q.goal
        RewardCore.addGold(player, q.reward.gold, "daily")
        RewardCore.addXP(player, q.reward.xp, "daily")
        bumpStat(d, "dailyQuestsDone", 1)
        DailyUpdate:FireClient(player, q, d.daily.todayProgress, true)
        PopupEvent:FireClient(player, "bonus", "📋 Daily complete!", Color3.fromRGB(255, 200, 120))
    else
        DailyUpdate:FireClient(player, q, d.daily.todayProgress, false)
    end
end

------------------------------------------------------------------
-- Subscribe to NotifyAction
------------------------------------------------------------------
NotifyAction.Event:Connect(function(player, action, payload)
    local d = PlayerDataService.get(player)
    if not d then return end
    payload = payload or {}

    if action == "serve" then
        bumpStat(d, "guestsServed", 1)
        bumpStat(d, "totalGold", payload.gold or 0)
        -- guest reputation
        if payload.guestName then
            d.guestRep[payload.guestName] = (d.guestRep[payload.guestName] or 0) + 1
            local rep = d.guestRep[payload.guestName]
            if rep == 3 or rep == 10 or rep == 25 then
                PopupEvent:FireClient(player, "bonus", "❤ " .. payload.guestName .. " rep " .. rep, Color3.fromRGB(255, 150, 200))
                -- tip bonus
                local tip = math.floor(rep * 2.5)
                RewardCore.addGold(player, tip, "rep")
            end
        end
        -- recipe mastery on serve
        if payload.recipe then
            d.mastery[payload.recipe] = d.mastery[payload.recipe] or { level = 1, xp = 0 }
            local m = d.mastery[payload.recipe]
            m.xp = m.xp + 1
            if m.xp >= m.level * 5 and m.level < 10 then
                m.xp = 0
                m.level = m.level + 1
                PopupEvent:FireClient(player, "bonus", "📖 " .. payload.recipe .. " mastery " .. m.level, Color3.fromRGB(180, 220, 255))
                RewardCore.addXP(player, 30, "mastery")
                RewardCore.addGold(player, m.level * 5, "mastery")
                if m.level == 5 then
                    PopupEvent:FireClient(player, "bonus", "🌟 Perk: bonus dish +10% for " .. payload.recipe, Color3.fromRGB(255, 220, 100))
                elseif m.level == 10 then
                    PopupEvent:FireClient(player, "bonus", "🏆 Perk: gold +15% for " .. payload.recipe, Color3.fromRGB(255, 200, 50))
                end
            end
        end
        progressDaily(player, "serve", 1)

    elseif action == "craft" then
        if payload.quality == "perfect" then
            bumpStat(d, "perfectCooks", 1)
            progressDaily(player, "perfect", 1)
        end
        progressDaily(player, "craft", 1)

    elseif action == "gather" then
        bumpStat(d, "totalGather", payload.count or 1)
        -- IronWrist bonus chance
        if d.powerups.IronWrist and d.powerups.IronWrist > os.time() then
            if math.random() < 0.25 then
                d[payload.item] = (d[payload.item] or 0) + 1
                PopupEvent:FireClient(player, "item", "+1 " .. payload.item .. " (Iron Wrist!)", Color3.fromRGB(255, 220, 120))
            end
        end
        progressDaily(player, "gather", 1)

    elseif action == "sell" then
        bumpStat(d, "totalGold", payload.gold or 0)
    end

    -- Combo high-water mark
    setMaxStat(d, "maxCombo", d.combo.count)
    if d.combo.count >= 5 or d.combo.count >= 10 or d.combo.count >= 15 then
        progressDaily(player, "combo", d.combo.count)
    end

    checkAchievements(player, gatherMetrics(d))
end)

------------------------------------------------------------------
-- Power-up usage
------------------------------------------------------------------
UsePowerup.OnServerInvoke = function(player, key)
    if typeof(key) ~= "string" then return false, "invalid key type" end
    if isSpamming(player, "UsePowerup", 0.5) then return false, "rate limit" end

    local d = PlayerDataService.get(player); if not d then return false, "no data" end
    local cfg = PowerupConfig[key]; if not cfg then return false, "unknown powerup" end
    
    local cost = cfg.cost and cfg.cost.gold or 0
    if (d.gold or 0) < cost then return false, "not enough gold" end
    
    d.gold = d.gold - cost
    d.powerups[key] = os.time() + cfg.duration
    bumpStat(d, "powerupsUsed", 1)
    
    PowerupUpdate:FireClient(player, key, d.powerups[key])
    PopupEvent:FireClient(player, "bonus", cfg.icon .. " " .. cfg.name .. "!", Color3.fromRGB(180, 240, 200))
    checkAchievements(player, gatherMetrics(d))
    
    return true, d.gold
end

------------------------------------------------------------------
-- Tool upgrade
------------------------------------------------------------------
UpgradeTool.OnServerInvoke = function(player, toolType)
    if typeof(toolType) ~= "string" then return false, "invalid toolType" end
    if isSpamming(player, "UpgradeTool", 1.0) then return false, "rate limit" end

    -- Whitelist validation
    if not ToolsConfig.tools[toolType] then
        return false, "invalid tool type"
    end

    local d = PlayerDataService.get(player); if not d then return false, "no data" end
    local cur = d.toolTiers[toolType] or 1
    if cur >= 3 then return false, "already max" end
    
    local cost = (cur == 1) and 300 or 900
    if (d.gold or 0) < cost then return false, "not enough gold (need " .. cost .. ")" end
    
    d.gold = d.gold - cost
    d.toolTiers[toolType] = cur + 1
    
    -- Apply to live tool in character
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("Type") == toolType then
                item:SetAttribute("Tier", "Tier" .. (cur + 1))
            end
        end
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("Type") == toolType then
                item:SetAttribute("Tier", "Tier" .. (cur + 1))
            end
        end
    end
    
    PopupEvent:FireClient(player, "bonus", "🔨 " .. toolType .. " → Tier " .. (cur + 1), Color3.fromRGB(255, 220, 150))
    checkAchievements(player, gatherMetrics(d))
    return true, d.gold
end

------------------------------------------------------------------
-- Compendium sync
------------------------------------------------------------------
GetCompendium.OnServerInvoke = function(player)
    local d = PlayerDataService.get(player) or {}
    return {
        achievements = AchievementConfig,
        unlocked = d.achievements or {},
        mastery = d.mastery or {},
        toolTiers = d.toolTiers or {},
        guestRep = d.guestRep or {},
        daily = d.daily or {},
        powerups = d.powerups or {},
        powerupConfig = PowerupConfig,
        dailyConfig = DailyQuestConfig,
        stats = d.stats or {},
    }
end

------------------------------------------------------------------
-- Hook player login
------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1.5)
		local d = PlayerDataService.getOrCreate(player)
        d.daily = d.daily or { lastClaimDay = 0, streak = 0, todayQuestId = nil, todayProgress = 0, todayClaimed = false }
        d.achievements = d.achievements or {}
        d.mastery = d.mastery or {}
        d.toolTiers = d.toolTiers or { Axe = 1, PickAxe = 1, Sickle = 1 }
        d.guestRep = d.guestRep or {}
        d.powerups = d.powerups or {}
        d.stats = d.stats or {}
        d.gold = d.gold or 0
        d.combo = d.combo or { count = 0, multiplier = 1.0, lastActionAt = 0 }
        d.chef = d.chef or { level = 1, xp = 0 }
        handleLogin(player)
    end)
end)

print("[AdvancedRewards] online")
