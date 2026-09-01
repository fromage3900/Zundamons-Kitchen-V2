--!strict
-- [[ModuleScript] ProgressionConfig]]
-- Shared progression values for server systems

local ProgressionConfig = {}

-- XP rewards per action
ProgressionConfig.xp = {
	serve = 15,
	craft = 10,
	craftPerfect = 25,
	gather = 5,
	login = 20,
}

-- Guest pay amounts by recipe (base)
ProgressionConfig.pay = {
	Bread = 10,
	["Apple Pie"] = 25,
	["Zunda Bread"] = 30,
	Cupcake = 35,
	["Zunda Mochi"] = 40,
	["Royal Stew"] = 100,
	["Salted Pea Bouquet"] = 50,
}

-- Guest personality templates for spawn variety
ProgressionConfig.guest_preferences = {
	{
		name = "Hopeful Visitor",
		pay_range = { 15, 25 },
		preferred_recipes = { "Bread", "Apple Pie" },
	},
	{
		name = "Food Critic",
		pay_range = { 40, 60 },
		preferred_recipes = { "Zunda Mochi", "Royal Stew", "Zunda Bread" },
	},
	{
		name = "Regular Customer",
		pay_range = { 20, 35 },
		preferred_recipes = { "Bread", "Zunda Bread" },
	},
	{
		name = "Picnic Guest",
		pay_range = { 30, 45 },
		preferred_recipes = { "Cupcake", "Apple Pie" },
	},
	{
		name = "⭐ Timed Challenge!",
		pay_range = { 80, 120 },
		preferred_recipes = { "Royal Stew", "Zunda Mochi", "Cupcake" },
		challenge = { patience = 30, bonus_gold = 60 },
	},
}

-- Guest spawning settings
-- Guests are the heart of the core loop, so they should show up quickly and
-- often. 15-30s keeps the kitchen busy without overwhelming the player.
ProgressionConfig.guest_settings = {
	max_guests_at_once = 3,
	spawn_interval_min = 15,
	spawn_interval_max = 30,
	first_guest_delay = 8,
	new_player_spawn_interval_min = 10,
	new_player_spawn_interval_max = 20,
	new_player_threshold = 5,
	guest_patience = 240,
	patience_warning = 60,
	patience_critical = 20,
}

-- Guest patience UI colors
ProgressionConfig.patience_colors = {
	normal = Color3.fromRGB(120, 200, 120),
	warning = Color3.fromRGB(220, 180, 80),
	critical = Color3.fromRGB(220, 80, 80),
}

-- Progression milestones (tier unlocks) — incremental cozy progression
-- Each tier grants: recipes, cosmetics, furniture, locations, and optional companion unlocks
ProgressionConfig.milestones = {
	{
		name = "Village Loop",
		guests_served = 0,
		unlocks = {
			recipes = { "Bread", "Apple Pie" },
			cosmetics = { "Chef Apron" },
			furniture = { "wooden_table", "pink_tulips" },
			locations = { "Kitchen" },
		},
	},
	{
		name = "Garden Tending",
		guests_served = 5,
		unlocks = {
			recipes = { "Zunda Bread", "Edamame Snack" },
			cosmetics = { "Gardener Hat" },
			furniture = { "stone_lantern", "garden_bench", "herb_shelf", "display_case" },
			locations = { "Garden" },
		},
	},
	{
		name = "Berry Sweet",
		guests_served = 12,
		unlocks = {
			recipes = { "Cupcake", "Pea Flower Tea" },
			cosmetics = { "Berry Headband" },
			furniture = { "window_box", "bookshelf" },
			locations = { "Berry Grove" },
		},
	},
	{
		name = "Forest Foraging",
		guests_served = 25,
		unlocks = {
			recipes = { "Zunda Mochi", "Sweet Pea Cake", "Seasonal Salad" },
			cosmetics = { "Forager Cloak" },
			furniture = { "fountain", "cherry_tree", "mushroom_stools", "hanging_lanterns" },
			locations = { "Forest Glade", "Hidden Alcove" },
		},
	},
	{
		name = "Peak Season",
		guests_served = 50,
		unlocks = {
			recipes = { "Royal Stew", "Ultimate Feast", "Cardamon's Calm Cup" },
			cosmetics = { "Chef's Crown", "Golden Apron" },
			furniture = { "fireplace", "fancy_bed", "trophy_shelf", "moon_gazer", "grand_stove", "spice_rack" },
			locations = { "Peak Vista", "Waterfall Cave" },
		},
	},
}

-- ── Prestige System ───────────────────────────────────────────────────────────
-- After completing all 5 milestone tiers (Peak Season reached), players may
-- Prestige: milestone progress resets but companions, recipes, and cosmetics
-- are kept. Each Prestige tier adds a permanent +10% gold multiplier (stacks,
-- up to 5×). A cosmetic badge is awarded at each tier.
--
-- Prestige requirements (each tier):
--   Must have reached "Peak Season" milestone in current prestige cycle.
--   Must have served the specified total lifetime guests.

ProgressionConfig.prestige = {
	enabled = true,
	max_tier = 5, -- Maximum prestige tier (5× gold multiplier)
	gold_per_tier = 0.10, -- +10% per tier (additive; tier 5 = +50% total)

	tiers = {
		{
			tier = 1,
			displayName = "Zunda Star ★",
			emoji = "⭐",
			gold_mult = 1.10,
			badge = "prestige_star_1",
			guests_required = 200,
		},
		{
			tier = 2,
			displayName = "Zunda Star ★★",
			emoji = "🌟",
			gold_mult = 1.20,
			badge = "prestige_star_2",
			guests_required = 500,
		},
		{
			tier = 3,
			displayName = "Zunda Star ★★★",
			emoji = "💫",
			gold_mult = 1.30,
			badge = "prestige_star_3",
			guests_required = 1000,
		},
		{
			tier = 4,
			displayName = "Zunda Radiance",
			emoji = "✨",
			gold_mult = 1.40,
			badge = "prestige_radiance",
			guests_required = 2000,
		},
		{
			tier = 5,
			displayName = "Zunda Legend",
			emoji = "🏆",
			gold_mult = 1.50,
			badge = "prestige_legend",
			guests_required = 5000,
		},
	},

	-- What is KEPT on prestige (not reset)
	kept_on_prestige = {
		"companions", -- all unlocked companions
		"recipes", -- all unlocked recipes
		"cosmetics", -- all earned cosmetics + badges
		"chef_stats", -- Speed, Precision, Charisma, Stamina
		"gacha_currency", -- Zunda Gems and Whim Tickets
		"bond_tiers", -- all companion bond levels
	},

	-- What RESETS on prestige
	reset_on_prestige = {
		"milestone_tier", -- back to Village Loop
		"guests_served", -- session counter
		"xp", -- player XP level
	},
}

return ProgressionConfig
