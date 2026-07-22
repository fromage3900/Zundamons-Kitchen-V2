--!strict
-- [[ModuleScript] ChefStatsConfig]]
-- Chef stat system inspired by Infinity Nikki's style stats.
-- Stats grow through cooking/serving and provide compounding bonuses.
-- Each stat has diminishing returns (like Uma Musume training).

local ChefStatsConfig = {}

-- ── Stat Definitions ────────────────────────────────────────────────────────
-- Each stat has:
--   name: Display name
--   emoji: Icon
--   description: What it does
--   baseValue: Starting value
--   maxValue: Cap
--   growthPerLevel: How much each point adds
--   diminishingReturns: Factor for diminishing returns (0.0 = no returns, 1.0 = linear)

ChefStatsConfig.stats = {
	speed = {
		name = "Speed",
		emoji = "⚡",
		description = "Faster cooking times and quicker guest service",
		baseValue = 100,
		maxValue = 500,
		growthPerLevel = 2.0,
		diminishingReturns = 0.85,
		color = Color3.fromRGB(255, 200, 80),
	},
	precision = {
		name = "Precision",
		emoji = "🎯",
		description = "Wider perfect cooking window and better quality control",
		baseValue = 100,
		maxValue = 500,
		growthPerLevel = 1.5,
		diminishingReturns = 0.80,
		color = Color3.fromRGB(160, 210, 150),
	},
	charisma = {
		name = "Charisma",
		emoji = "💖",
		description = "Higher guest pay and better tips from serving",
		baseValue = 100,
		maxValue = 500,
		growthPerLevel = 1.8,
		diminishingReturns = 0.82,
		color = Color3.fromRGB(255, 150, 200),
	},
	stamina = {
		name = "Stamina",
		emoji = "💪",
		description = "Longer combo windows and sustained cooking performance",
		baseValue = 100,
		maxValue = 500,
		growthPerLevel = 2.2,
		diminishingReturns = 0.88,
		color = Color3.fromRGB(145, 215, 195),
	},
}

-- ── Style Points System (Infinity Nikki aesthetic) ──────────────────────────
-- Style points are earned from stylish cooking, perfect timing, and companion
-- coordination. They unlock fashion items and outfit variants.

ChefStatsConfig.stylePoints = {
	-- Sources of style points
	sources = {
		perfect_cook = 10,
		great_cook = 5,
		combo_5 = 15,
		combo_10 = 30,
		companion_synergy = 20,
		recipe_master = 25,
		serving_flawless = 8,
		daily_challenge = 50,
	},

	-- Style tiers (like Infinity Nikki's style ranks)
	tiers = {
		{ name = "Fresh",       minPoints = 0,     color = Color3.fromRGB(200, 200, 200),  badge = "🌱" },
		{ name = "Stylish",     minPoints = 500,   color = Color3.fromRGB(160, 210, 150),  badge = "🍃" },
		{ name = "Chic",        minPoints = 2000,  color = Color3.fromRGB(255, 200, 80),   badge = "⭐" },
		{ name = "Gorgeous",    minPoints = 8000,  color = Color3.fromRGB(255, 150, 200),  badge = "💖" },
		{ name = "Legendary",   minPoints = 30000, color = Color3.fromRGB(230, 185, 130),  badge = "👑" },
	},

	-- Outfit unlocks per style tier
	outfitUnlocks = {
		{ tier = "Stylish",     outfits = { "Zundapal_PastelDress", "Zundacat_RibbonTail" } },
		{ tier = "Chic",        outfits = { "Zundamon_ShinyCoat", "Zundabunny_BlossomEars" } },
		{ tier = "Gorgeous",    outfits = { "Ankomon_GoldTrim", "Cardamon_CrownOfCalm" } },
		{ tier = "Legendary",   outfits = { "Zundamon_MagicalGirlForm", "AllCompanions_CosmicAura" } },
	},
}

-- ── Stat Calculation ─────────────────────────────────────────────────────────

function ChefStatsConfig.calculateStatValue(baseValue: number, points: number, growthPerLevel: number, diminishingFactor: number): number
	-- Diminishing returns: each point gives less than the last
	-- Formula: baseValue + points * growthPerLevel * diminishingFactor^(points/100)
	local effectiveGrowth = growthPerLevel * (diminishingFactor ^ (points / 100))
	return baseValue + points * effectiveGrowth
end

function ChefStatsConfig.getStatBonus(statKey: string, points: number): number
	local stat = ChefStatsConfig.stats[statKey]
	if not stat then
		return 0
	end
	local value = ChefStatsConfig.calculateStatValue(
		stat.baseValue, points, stat.growthPerLevel, stat.diminishingReturns
	)
	-- Return as a multiplier (1.0 = no bonus, 1.5 = 50% bonus)
	return value / stat.baseValue
end

function ChefStatsConfig.getCookingTimeMultiplier(speedPoints: number): number
	-- Speed reduces cooking time. 1.0 = normal, 0.5 = half time
	local bonus = ChefStatsConfig.getStatBonus("speed", speedPoints)
	return math.clamp(1.0 / bonus, 0.4, 1.5)
end

function ChefStatsConfig.getPerfectWindowMultiplier(precisionPoints: number): number
	-- Precision widens the perfect window. 1.0 = normal, 2.0 = double window
	local bonus = ChefStatsConfig.getStatBonus("precision", precisionPoints)
	return math.clamp(bonus, 1.0, 2.5)
end

function ChefStatsConfig.getGoldMultiplier(charismaPoints: number): number
	-- Charisma increases gold from serving. 1.0 = normal, 2.0 = double gold
	local bonus = ChefStatsConfig.getStatBonus("charisma", charismaPoints)
	return math.clamp(bonus, 1.0, 3.0)
end

function ChefStatsConfig.getComboWindowMultiplier(staminaPoints: number): number
	-- Stamina extends combo window. 1.0 = normal, 2.0 = double window
	local bonus = ChefStatsConfig.getStatBonus("stamina", staminaPoints)
	return math.clamp(bonus, 1.0, 2.0)
end

function ChefStatsConfig.getStyleTier(points: number): { name: string, color: Color3, badge: string }
	for i = #ChefStatsConfig.stylePoints.tiers, 1, -1 do
		local tier = ChefStatsConfig.stylePoints.tiers[i]
		if points >= tier.minPoints then
			return tier
		end
	end
	return ChefStatsConfig.stylePoints.tiers[1]
end

function ChefStatsConfig.getDefaultStats(): { [string]: number }
	return {
		speed = 0,
		precision = 0,
		charisma = 0,
		stamina = 0,
		style_points = 0,
	}
end

function ChefStatsConfig.getTrainingCost(statKey: string, currentPoints: number): { gold: number, items: { [string]: number } }
	-- Cost increases with points invested (diminishing returns on training)
	local baseCost = 50
	local tier = math.floor(currentPoints / 100) + 1
	local cost = math.floor(baseCost * (1.5 ^ tier))
	return {
		gold = cost,
		items = { ["Wheat"] = tier, ["Zunda Pea"] = math.max(1, math.floor(tier / 2)) },
	}
end

return ChefStatsConfig
