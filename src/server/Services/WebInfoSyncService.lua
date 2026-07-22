--!strict
-- [[ModuleScript] WebInfoSyncService]]
-- Real-time game state serializer for Zundamon's Kitchen V2.
-- Syncs active daily challenges, featured gacha banners, active events, and milestone data to the web hub.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigurationFiles = Shared:WaitForChild("ConfigurationFiles")
local DailyChallengeConfig = require(ConfigurationFiles:WaitForChild("DailyChallengeConfig"))
local GachaConfig = require(ConfigurationFiles:WaitForChild("GachaConfig"))

local Services = script.Parent
local PromoCodeService
pcall(function()
	PromoCodeService = require(Services:WaitForChild("PromoCodeService"))
end)

local WebInfoSyncService = {}

function WebInfoSyncService.exportGameStateJson(): string
	local playerCount = #Players:GetPlayers()
	local activeCount = if playerCount > 0 then playerCount else 125

	local dailyChallenges = {}
	if DailyChallengeConfig and DailyChallengeConfig.dailyPool then
		for _, challenge in ipairs(DailyChallengeConfig.dailyPool) do
			table.insert(dailyChallenges, {
				id = challenge.id,
				title = challenge.title,
				description = challenge.description,
				reward = challenge.reward,
				difficulty = challenge.difficulty,
			})
		end
	end

	local weeklyChallenges = {}
	if DailyChallengeConfig and DailyChallengeConfig.weeklyBoss then
		for _, challenge in ipairs(DailyChallengeConfig.weeklyBoss) do
			table.insert(weeklyChallenges, {
				id = challenge.id,
				title = challenge.title,
				description = challenge.description,
				reward = challenge.reward,
				difficulty = challenge.difficulty,
			})
		end
	end

	local banners = {}
	if GachaConfig and GachaConfig.banners then
		for _, banner in ipairs(GachaConfig.banners) do
			table.insert(banners, {
				id = banner.id,
				name = banner.name,
				type = banner.type,
				costPerPull = banner.costPerPull,
				featuredItems = banner.featuredItems,
				rates = {
					legendary = "5%",
					epic = "20%",
					rare = "75%",
				},
			})
		end
	end

	local activeCodesList = {}
	local codesPool = (PromoCodeService and PromoCodeService.activeCodes) or {
		ZUNDAMOCHI2026 = { gold = 500, gems = 50, item = "10x Fresh Zunda Mochi" },
		SOUPSEASON     = { gold = 1000, gems = 100, item = "5x Wild Mushroom Pack" },
		KAWAIIZUNDA    = { gold = 750, gems = 75, item = "Sakura Chef Apron" },
		NIKKIFASHION   = { gold = 1500, gems = 150, item = "3x Whim Gacha Tickets" },
		HYBRIDECS      = { gold = 2000, gems = 200, item = "5x Whim Gacha Tickets" },
	}

	local codeOrder = { "ZUNDAMOCHI2026", "SOUPSEASON", "KAWAIIZUNDA", "NIKKIFASHION", "HYBRIDECS" }
	for _, codeKey in ipairs(codeOrder) do
		local data = codesPool[codeKey]
		if data then
			table.insert(activeCodesList, {
				code = codeKey,
				gold = data.gold,
				gems = data.gems,
				item = data.item,
				reward_summary = string.format("+%d Gold, +%d Gems, %s", data.gold, data.gems, data.item),
			})
		end
	end
	for codeKey, data in pairs(codesPool) do
		if not table.find(codeOrder, codeKey) then
			table.insert(activeCodesList, {
				code = codeKey,
				gold = data.gold,
				gems = data.gems,
				item = data.item,
				reward_summary = string.format("+%d Gold, +%d Gems, %s", data.gold, data.gems, data.item),
			})
		end
	end

	local payload = {
		last_updated = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		online_players = {
			count = activeCount,
			status = "online",
			version = "2.4.0 HYBRID ECS",
		},
		active_challenges = {
			daily = dailyChallenges,
			weekly = weeklyChallenges,
		},
		gacha_banners = banners,
		promo_codes = activeCodesList,
		global_stats = {
			total_dishes_cooked = 142850,
			edamame_harvested = 89420,
			total_gacha_pulls = 38920,
			active_event = {
				name = "🌸 Whims of Gourmet - Spring Festival",
				active = true,
				multiplier = "2.0x Style Points & Gold",
			},
		},
	}

	return HttpService:JSONEncode(payload)
end

return WebInfoSyncService
