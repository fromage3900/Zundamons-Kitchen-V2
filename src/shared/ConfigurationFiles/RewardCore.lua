-- [[ModuleScript] RewardCore (ref: RBXB6E1B235BC6A4A298C35D467B9D31D3E)]]
local RewardCore = {}

local RS = game.ReplicatedStorage
local rewardEvents = RS:WaitForChild("RewardEvents")
local PopupEvent       = rewardEvents:WaitForChild("PopupEvent")
local ChefLevelUpdate  = rewardEvents:WaitForChild("ChefLevelUpdate")
local ComboUpdate      = rewardEvents:WaitForChild("ComboUpdate")
local LevelUpEvent     = rewardEvents:WaitForChild("LevelUpEvent")
local RequestRewardSync= rewardEvents:WaitForChild("RequestRewardSync")
local NotifyAction     = rewardEvents:WaitForChild("NotifyAction")

local ChefLevelConfig = require(RS.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(game.ServerScriptService.Services.PlayerDataService)

local function ensureProfile(player)
	local d = PlayerDataService.getOrCreate(player)
    d.inventory = d.inventory or {}
    d.gold = d.gold or 0
    d.chef = d.chef or { level = 1, xp = 0 }
    d.combo = d.combo or { count = 0, multiplier = 1.0, lastActionAt = 0 }
    d.mastery = d.mastery or {}
    d.toolTiers = d.toolTiers or { Axe = 1, PickAxe = 1, Sickle = 1 }
    d.guestRep = d.guestRep or {}
    d.achievements = d.achievements or {}
    d.daily = d.daily or { lastClaimDay = 0, streak = 0, todayQuestId = nil, todayProgress = 0, todayClaimed = false }
    d.powerups = d.powerups or {}  -- { name = expiresAt }
    return d
end

local COMBO_WINDOW = 8  -- seconds

local function comboMultiplier(count)
    if count < 2 then return 1.0 end
    if count < 4 then return 1.25 end
    if count < 7 then return 1.5 end
    if count < 10 then return 2.0 end
    if count < 15 then return 3.0 end
    return 5.0
end

local function popup(player, kind, text, color)
    PopupEvent:FireClient(player, kind, text, color)
end

-- Companion buff lookup: reads active companion from player data
local function companionBuff(player, stat)
	local d = PlayerDataService.get(player)
	if not d then
		return 0
	end
    local active = d.active_companion
    if not active then return 0 end
    local cat = shared.ZundaCompanionCatalog
    if not cat then return 0 end
    local def = cat[active]
    if not def or not def.buff then return 0 end
    if def.buff.stat == stat then return def.buff.magnitude end
    return 0
end
RewardCore.companionBuff = companionBuff

function RewardCore.addGold(player, amount, reason)
    if amount <= 0 then return 0 end
    local d = ensureProfile(player)
    -- Apply combo multiplier on gold from "active" actions
    local mult = 1
    if reason == "serve" or reason == "craft" or reason == "perfect" then
        mult = d.combo.multiplier
    end
	-- Apply Lucky Charm powerup
	if d.powerups.LuckyCharm and d.powerups.LuckyCharm > os.time() then
		mult = mult * 1.5
	end
	-- Companion gold buff (Ankomon)
	if reason == "serve" then
		mult = mult * (1 + companionBuff(player, "gold"))
	end
	-- Decoration gold buff
	if d.active_decor_buffs and d.active_decor_buffs.gold > 0 then
		mult = mult * (1 + d.active_decor_buffs.gold)
	end
	local finalAmount = math.floor(amount * mult)
    d.gold = d.gold + finalAmount
    popup(player, "gold", "+" .. finalAmount .. "g", Color3.fromRGB(255, 220, 90))
    if mult > 1 then
        popup(player, "bonus", "x" .. string.format("%.1f", mult) .. " combo!", Color3.fromRGB(255, 150, 200))
    end
    return finalAmount
end

function RewardCore.addXP(player, amount, reason)
    if amount <= 0 then return end
    local d = ensureProfile(player)
	-- Companion XP buff (Sakuradamon)
	local xpBuff = companionBuff(player, "xp")
	if xpBuff > 0 then amount = math.floor(amount * (1 + xpBuff)) end
	-- Decoration XP buff
	if d.active_decor_buffs and d.active_decor_buffs.xp > 0 then
		amount = math.floor(amount * (1 + d.active_decor_buffs.xp))
	end
	d.chef.xp = d.chef.xp + amount
    popup(player, "xp", "+" .. amount .. " XP", Color3.fromRGB(180, 130, 255))

    -- Level up check
    while d.chef.xp >= ChefLevelConfig.xpForLevel(d.chef.level) do
        d.chef.xp = d.chef.xp - ChefLevelConfig.xpForLevel(d.chef.level)
        d.chef.level = d.chef.level + 1
        local tier = ChefLevelConfig.tierForLevel(d.chef.level)
        LevelUpEvent:FireClient(player, d.chef.level, tier.name, tier.color, tier.badge)
    end
    RewardCore.syncLevel(player)
end

function RewardCore.syncLevel(player)
    local d = ensureProfile(player)
    local tier = ChefLevelConfig.tierForLevel(d.chef.level)
    local xpNeeded = ChefLevelConfig.xpForLevel(d.chef.level)
    ChefLevelUpdate:FireClient(player, d.chef.level, d.chef.xp, xpNeeded, tier.name, tier.color, tier.badge)
end

function RewardCore.syncCombo(player)
    local d = ensureProfile(player)
    ComboUpdate:FireClient(player, d.combo.count, d.combo.multiplier)
end

function RewardCore.bumpCombo(player)
    local d = ensureProfile(player)
    local now = os.clock()
    if now - d.combo.lastActionAt > COMBO_WINDOW then
        d.combo.count = 1
    else
        d.combo.count = d.combo.count + 1
    end
    d.combo.lastActionAt = now
    d.combo.multiplier = comboMultiplier(d.combo.count)
    RewardCore.syncCombo(player)
end

function RewardCore.breakCombo(player)
    local d = ensureProfile(player)
    d.combo.count = 0
    d.combo.multiplier = 1.0
    RewardCore.syncCombo(player)
end

-- Notification hub for sub-systems
function RewardCore.notify(player, actionType, payload)
    NotifyAction:Fire(player, actionType, payload)
end

-- Convenience composite
function RewardCore.reward(player, opts)
    -- opts: { gold = number, xp = number, reason = string, popupItem = string }
    if opts.combo then RewardCore.bumpCombo(player) end
    local gained = 0
    if opts.gold then gained = RewardCore.addGold(player, opts.gold, opts.reason) end
    if opts.xp then RewardCore.addXP(player, opts.xp, opts.reason) end
    if opts.popupItem then popup(player, "item", "+" .. opts.popupItem, Color3.fromRGB(160, 240, 170)) end
    RewardCore.notify(player, opts.reason or "generic", { gold = gained, xp = opts.xp })
    return gained
end

-- Decay loop for combo
task.spawn(function()
    while true do
        task.wait(1)
		for _, player in ipairs(game.Players:GetPlayers()) do
			local d = PlayerDataService.get(player)
            if d and d.combo and d.combo.count > 0 then
                if os.clock() - d.combo.lastActionAt > COMBO_WINDOW then
                    RewardCore.breakCombo(player)
                end
            end
        end
    end
end)

-- Sync on join
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        ensureProfile(player)
        RewardCore.syncLevel(player)
        RewardCore.syncCombo(player)
    end)
end)

RequestRewardSync.OnServerInvoke = function(player)
    local d = ensureProfile(player)
    local tier = ChefLevelConfig.tierForLevel(d.chef.level)
    return {
        level = d.chef.level,
        xp = d.chef.xp,
        xpNeeded = ChefLevelConfig.xpForLevel(d.chef.level),
        tierName = tier.name,
        tierColor = tier.color,
        tierBadge = tier.badge,
        gold = d.gold,
        combo = d.combo,
        toolTiers = d.toolTiers,
        achievements = d.achievements,
        mastery = d.mastery,
        guestRep = d.guestRep,
        powerups = d.powerups,
    }
end

_G.RewardCore = RewardCore
return RewardCore
