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
ProgressionConfig.guest_settings = {
	max_guests_at_once = 3,
	spawn_interval_min = 30,
	spawn_interval_max = 60,
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

return ProgressionConfig