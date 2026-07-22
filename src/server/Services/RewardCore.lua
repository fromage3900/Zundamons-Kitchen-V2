-- [[ModuleScript] RewardCore (Server Service)]
local RewardCore = {}

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local rewardEvents = RS:WaitForChild("RewardEvents")
local PopupEvent = rewardEvents:WaitForChild("PopupEvent")
local ChefLevelUpdate = rewardEvents:WaitForChild("ChefLevelUpdate")
local ComboUpdate = rewardEvents:WaitForChild("ComboUpdate")
local LevelUpEvent = rewardEvents:WaitForChild("LevelUpEvent")
local RequestRewardSync = rewardEvents:WaitForChild("RequestRewardSync")
local NotifyAction = rewardEvents:WaitForChild("NotifyAction")

local ChefLevelConfig = require(RS.ConfigurationFiles.ChefLevelConfig)
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)
local PlayerDataService = require(SSS.Services.PlayerDataService)

local function ensureProfile(player)
	local d = PlayerDataService.getOrCreate(player)
	d.gold = d.gold or 0
	d.total_gold_earned = d.total_gold_earned or 0
	d.chef = d.chef or { level = 1, xp = 0 }
	d.combo = d.combo or { count = 0, multiplier = 1.0, lastActionAt = 0 }
	d.mastery = d.mastery or {}
	d.toolTiers = d.toolTiers or { Axe = 1, PickAxe = 1, Sickle = 1 }
	d.guestRep = d.guestRep or {}
	d.achievements = d.achievements or {}
	d.daily = d.daily or { lastClaimDay = 0, streak = 0, todayQuestId = nil, todayProgress = 0, todayClaimed = false }
	d.powerups = d.powerups or {} -- { name = expiresAt }
	return d
end

local COMBO_WINDOW = 8 -- seconds

local function comboMultiplier(count)
	if count < 2 then
		return 1.0
	end
	if count < 4 then
		return 1.25
	end
	if count < 7 then
		return 1.5
	end
	if count < 10 then
		return 2.0
	end
	if count < 15 then
		return 3.0
	end
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
	if not active then
		return 0
	end
	local def = CompanionConfig.companions[active]
	if not def or not def.buff then
		return 0
	end
	if def.buff.stat == stat then
		return def.buff.magnitude
	end
	return 0
end
RewardCore.companionBuff = companionBuff

function RewardCore.addGold(player, amount, reason)
	if amount <= 0 then
		return 0
	end
	ensureProfile(player)
	local finalAmount = 0
	local multiplier = 1
	local ok = PlayerDataService.mutate(player, "reward_gold", function(d)
		-- Apply combo multiplier on gold from "active" actions
		if reason == "serve" or reason == "craft" or reason == "perfect" then
			multiplier = d.combo.multiplier
		end
		-- Apply Lucky Charm powerup
		if d.powerups.LuckyCharm and d.powerups.LuckyCharm > os.time() then
			multiplier = multiplier * 1.5
		end
		-- Companion gold buff (Ankomon)
		if reason == "serve" then
			multiplier = multiplier * (1 + companionBuff(player, "gold"))
		end
		-- Decoration gold buff
		if d.active_decor_buffs and d.active_decor_buffs.gold > 0 then
			multiplier = multiplier * (1 + d.active_decor_buffs.gold)
		end
		finalAmount = math.floor(amount * multiplier)
		d.gold = (d.gold or 0) + finalAmount
		d.total_gold_earned = (d.total_gold_earned or 0) + finalAmount
		return true
	end)
	if not ok then
		return 0
	end
	popup(player, "gold", "+" .. finalAmount .. "g", Color3.fromRGB(255, 220, 90))
	if multiplier > 1 then
		popup(player, "bonus", "x" .. string.format("%.1f", multiplier) .. " combo!", Color3.fromRGB(255, 150, 200))
	end
	return finalAmount
end

function RewardCore.addXP(player, amount, reason)
	if amount <= 0 then
		return 0
	end
	ensureProfile(player)
	local finalAmount = amount
	local levelUps = {}
	local ok = PlayerDataService.mutate(player, "reward_xp", function(d)
		-- Companion XP buff (Sakuradamon)
		local xpBuff = companionBuff(player, "xp")
		if xpBuff > 0 then
			finalAmount = math.floor(finalAmount * (1 + xpBuff))
		end
		-- Decoration XP buff
		if d.active_decor_buffs and d.active_decor_buffs.xp > 0 then
			finalAmount = math.floor(finalAmount * (1 + d.active_decor_buffs.xp))
		end
		d.chef.xp = d.chef.xp + finalAmount

		while d.chef.xp >= ChefLevelConfig.xpForLevel(d.chef.level) do
			d.chef.xp = d.chef.xp - ChefLevelConfig.xpForLevel(d.chef.level)
			d.chef.level = d.chef.level + 1
			table.insert(levelUps, d.chef.level)
		end
		return true
	end)
	if not ok then
		return 0
	end
	popup(player, "xp", "+" .. finalAmount .. " XP", Color3.fromRGB(180, 130, 255))
	for _, level in ipairs(levelUps) do
		local tier = ChefLevelConfig.tierForLevel(level)
		LevelUpEvent:FireClient(player, level, tier.name, tier.color, tier.badge)
	end
	RewardCore.syncLevel(player)
	return finalAmount
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
	ensureProfile(player)
	local ok = PlayerDataService.mutate(player, "reward_combo_bump", function(d)
		local now = os.clock()
		if now - d.combo.lastActionAt > COMBO_WINDOW then
			d.combo.count = 1
		else
			d.combo.count = d.combo.count + 1
		end
		d.combo.lastActionAt = now
		d.combo.multiplier = comboMultiplier(d.combo.count)
		return true
	end)
	if ok then
		RewardCore.syncCombo(player)
	end
	return ok
end

function RewardCore.breakCombo(player)
	ensureProfile(player)
	local ok = PlayerDataService.mutate(player, "reward_combo_break", function(d)
		d.combo.count = 0
		d.combo.multiplier = 1.0
		return true
	end)
	if ok then
		RewardCore.syncCombo(player)
	end
	return ok
end

-- Notification hub for sub-systems
function RewardCore.notify(player, actionType, payload)
	NotifyAction:Fire(player, actionType, payload)
end

-- Applies domain inventory/state changes and rewards in one PlayerDataService
-- transaction. Domain services provide a synchronous mutator; RewardCore remains
-- the sole owner of combo, gold, XP, and reward presentation policy.
function RewardCore.settle(player, opts, domainMutator)
	ensureProfile(player)
	local goldGained = 0
	local xpGained = 0
	local multiplier = 1
	local levelUps = {}
	local domainResult = nil
	local comboChanged = false

	local ok, failure = PlayerDataService.mutate(player, "reward_settlement", function(d)
		if domainMutator then
			local accepted, result = domainMutator(d)
			if accepted == false then
				return false, result or "domain_rejected"
			end
			domainResult = result
		end

		if opts.combo then
			local now = os.clock()
			if now - d.combo.lastActionAt > COMBO_WINDOW then
				d.combo.count = 1
			else
				d.combo.count = d.combo.count + 1
			end
			d.combo.lastActionAt = now
			d.combo.multiplier = comboMultiplier(d.combo.count)
			comboChanged = true
		elseif opts.breakCombo then
			d.combo.count = 0
			d.combo.multiplier = 1.0
			comboChanged = true
		end

		local requestedGold = opts.gold or 0
		if requestedGold > 0 then
			if opts.reason == "serve" or opts.reason == "craft" or opts.reason == "perfect" then
				multiplier = d.combo.multiplier
			end
			if d.powerups.LuckyCharm and d.powerups.LuckyCharm > os.time() then
				multiplier = multiplier * 1.5
			end
			if opts.reason == "serve" then
				multiplier = multiplier * (1 + companionBuff(player, "gold"))
			end
			local decorGold = d.active_decor_buffs and d.active_decor_buffs.gold or 0
			if decorGold > 0 then
				multiplier = multiplier * (1 + decorGold)
			end
			goldGained = math.floor(requestedGold * multiplier)
			d.gold = d.gold + goldGained
			d.total_gold_earned = d.total_gold_earned + goldGained
		end

		local requestedXP = opts.xp or 0
		if requestedXP > 0 then
			xpGained = requestedXP
			local xpBuff = companionBuff(player, "xp")
			if xpBuff > 0 then
				xpGained = math.floor(xpGained * (1 + xpBuff))
			end
			local decorXP = d.active_decor_buffs and d.active_decor_buffs.xp or 0
			if decorXP > 0 then
				xpGained = math.floor(xpGained * (1 + decorXP))
			end
			d.chef.xp = d.chef.xp + xpGained
			while d.chef.xp >= ChefLevelConfig.xpForLevel(d.chef.level) do
				d.chef.xp = d.chef.xp - ChefLevelConfig.xpForLevel(d.chef.level)
				d.chef.level = d.chef.level + 1
				table.insert(levelUps, d.chef.level)
			end
		end

		return true
	end)

	if not ok then
		return { ok = false, reason = failure }
	end
	if comboChanged then
		RewardCore.syncCombo(player)
	end
	if goldGained > 0 then
		popup(player, "gold", "+" .. goldGained .. "g", Color3.fromRGB(255, 220, 90))
		if multiplier > 1 then
			popup(player, "bonus", "x" .. string.format("%.1f", multiplier) .. " combo!", Color3.fromRGB(255, 150, 200))
		end
	end
	if xpGained > 0 then
		popup(player, "xp", "+" .. xpGained .. " XP", Color3.fromRGB(180, 130, 255))
		for _, level in ipairs(levelUps) do
			local tier = ChefLevelConfig.tierForLevel(level)
			LevelUpEvent:FireClient(player, level, tier.name, tier.color, tier.badge)
		end
		RewardCore.syncLevel(player)
	end
	if opts.popupItem then
		popup(player, "item", "+" .. opts.popupItem, opts.popupColor or Color3.fromRGB(160, 240, 170))
	end
	local notification = { gold = goldGained, xp = xpGained, domain = domainResult }
	RewardCore.notify(player, opts.reason or "generic", notification)
	return { ok = true, gold = goldGained, xp = xpGained, domain = domainResult }
end

-- Convenience composite
function RewardCore.reward(player, opts)
	local result = RewardCore.settle(player, opts)
	if not result.ok then
		return 0, 0
	end
	return result.gold, result.xp
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
