-- [[ModuleScript] DecorationConfig (ref: RBX6F0E1238DEC14B5A8344D250D5F07D12)]]
-- DecorationConfig: Items players can place in their Garden or Cottage Plot
-- To add a new decoration: add an entry to garden_items or cottage_items.
-- Fields: id, name, price, description, modelName, zone ("garden"|"cottage"|"both")

local DecorationConfig = {}

-- ============================================================
-- GARDEN DECORATIONS
-- ============================================================
DecorationConfig.garden_items = {
	{
		id          = "pink_tulips",
		name        = "Pink Tulips",
		description = "A bunch of cheerful pink tulips!",
		modelName   = "PinkTulips",
		meshId      = "rbxassetid://130899236683010",
		price       = 15,
		tier        = 1,
		zone        = "garden",
		icon        = "🌷",
		buff        = { stat = "patience", magnitude = 0.05 },
	},
	{
		id          = "stone_lantern",
		name        = "Stone Lantern",
		description = "Light up the garden at night.",
		modelName   = "StoneLantern",
		meshId      = "rbxassetid://138139954211772",
		price       = 40,
		tier        = 1,
		zone        = "garden",
		icon        = "🏮",
		buff        = { stat = "xp", magnitude = 0.05 },
	},
	{
		id          = "garden_bench",
		name        = "Garden Bench",
		description = "A cozy wooden bench for relaxing.",
		modelName   = "GardenBench",
		meshId      = "rbxassetid://136635427702568",
		price       = 60,
		tier        = 1,
		zone        = "garden",
		icon        = "🪑",
		buff        = { stat = "gold", magnitude = 0.05 },
	},
	{
		id          = "fountain",
		name        = "Mini Fountain",
		description = "A decorative stone fountain with running water.",
		modelName   = "MiniFountain",
		meshId      = "",
		price       = 120,
		tier        = 2,
		zone        = "garden",
		icon        = "⛲",
		buff        = { stat = "gold", magnitude = 0.10 },
	},
	{
		id          = "cherry_tree",
		name        = "Cherry Blossom Tree",
		description = "A beautiful pink blossom tree!",
		modelName   = "CherryTree",
		meshId      = "rbxassetid://139609561607226",
		price       = 200,
		tier        = 2,
		zone        = "garden",
		icon        = "🌸",
		buff        = { stat = "patience", magnitude = 0.10 },
	},
}

-- ============================================================
-- COTTAGE / PLOT DECORATIONS
-- ============================================================
DecorationConfig.cottage_items = {
	{
		id          = "wooden_table",
		name        = "Wooden Table",
		description = "A simple wooden table for your cottage.",
		modelName   = "WoodenTable",
		meshId      = "rbxassetid://104840247636112",
		price       = 30,
		tier        = 1,
		zone        = "cottage",
		icon        = "🪑",
		buff        = { stat = "patience", magnitude = 0.05 },
	},
	{
		id          = "bookshelf",
		name        = "Bookshelf",
		description = "Fill it with your favourite recipes!",
		modelName   = "Bookshelf",
		meshId      = "",
		price       = 50,
		tier        = 1,
		zone        = "cottage",
		icon        = "📚",
		buff        = { stat = "xp", magnitude = 0.10 },
	},
	{
		id          = "window_box",
		name        = "Window Flower Box",
		description = "Attach pink flowers to your cottage windows.",
		modelName   = "WindowBox",
		meshId      = "",
		price       = 35,
		tier        = 1,
		zone        = "cottage",
		icon        = "🌺",
		buff        = { stat = "gold", magnitude = 0.05 },
	},
	{
		id          = "fireplace",
		name        = "Stone Fireplace",
		description = "Warm up your cottage with a crackling fire.",
		modelName   = "Fireplace",
		meshId      = "",
		price       = 150,
		tier        = 2,
		zone        = "cottage",
		icon        = "🔥",
		buff        = { stat = "gold", magnitude = 0.10 },
	},
	{
		id          = "fancy_bed",
		name        = "Fancy Bed",
		description = "Sleep in style after a long day serving guests!",
		modelName   = "FancyBed",
		meshId      = "",
		price       = 180,
		tier        = 2,
		zone        = "cottage",
		icon        = "🛏️",
		buff        = { stat = "xp", magnitude = 0.15 },
	},
	{
		id          = "trophy_shelf",
		name        = "Trophy Shelf",
		description = "Display your tier badges and achievements.",
		modelName   = "TrophyShelf",
		meshId      = "",
		price       = 250,
		tier        = 3,
		zone        = "cottage",
		icon        = "🏆",
		buff        = { stat = "patience", magnitude = 0.20 },
	},
}

return DecorationConfig
