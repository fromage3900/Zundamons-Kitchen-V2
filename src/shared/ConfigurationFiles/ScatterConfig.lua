--!strict
-- [[ModuleScript] ScatterConfig]]
-- Biome and placement configuration for procedural node scattering.
-- Seasonal biomes + cozy animation flags

local ScatterConfig = {}

ScatterConfig.biomes = {
	zunda_forest = {
		display = "Zunda Forest",
		node_types = {
			ZundaFlower = {
				resourceType = "ZundaFlower",
				density = 0.35,
				spacing = 10,
				variants = { "ZundaFlower_Default", "ZundaFlower_Rare" },
				variantWeights = { 0.7, 0.3 },
				scaleRange = { 0.8, 1.2 },
				yOffset = 0,
				yRotationRandom = true,
				spinSpeed = 0.5,
			},
			ZundaPea = {
				resourceType = "ZundaPea",
				density = 0.30,
				spacing = 12,
				variants = { "ZundaPea_01", "ZundaPea_02", "ZundaPea_03" },
				variantWeights = { 0.5, 0.3, 0.2 },
				scaleRange = { 0.95, 1.05 },
				yOffset = -0.1,
				yRotationRandom = true,
				swayAnimation = true,
			},
			["Zunda Mushroom"] = {
				resourceType = "Zunda Mushroom",
				density = 0.15,
				spacing = 18,
				variants = { "Mushroom_01", "Mushroom_02" },
				variantWeights = { 0.6, 0.4 },
				scaleRange = { 0.7, 1.3 },
				yOffset = 0,
				bobAnimation = true,
			},
			["Zunda Berry"] = {
				resourceType = "Zunda Berry",
				density = 0.30,
				spacing = 8,
				variants = { "BerryBush_01", "BerryBush_02", "BerryBush_03" },
				variantWeights = { 0.5, 0.3, 0.2 },
				scaleRange = { 0.85, 1.15 },
				yOffset = 0,
				glowWhenNear = true,
			},
			["Zunda Root"] = {
				resourceType = "Zunda Root",
				density = 0.12,
				spacing = 20,
				variants = { "Root_01", "Root_02" },
				variantWeights = { 0.65, 0.35 },
				scaleRange = { 0.9, 1.1 },
				yOffset = -0.5,
			},
		},
		exclusion_tags = { "Path", "Building", "Water", "Plot" },
		voxel_size = 12,
		max_slope = 45,
		seed = 4242,
	},

	mineable_foothills = {
		display = "Mineable Foothills",
		node_types = {
			Rock = {
				resourceType = "Rock",
				density = 0.20,
				spacing = 16,
				variants = { "Rock_Common", "Rock_Rare" },
				variantWeights = { 0.8, 0.2 },
				scaleRange = { 0.8, 1.4 },
				yOffset = -0.3,
				crackStages = 3,
			},
			["Gold Ore"] = {
				resourceType = "Gold Ore",
				density = 0.05,
				spacing = 30,
				variants = { "GoldOre_Default" },
				variantWeights = { 1.0 },
				scaleRange = { 0.9, 1.1 },
				yOffset = -0.3,
				glowColor = Color3.fromRGB(255, 215, 0),
			},
		},
		exclusion_tags = { "Path", "Building", "Water", "Plot" },
		voxel_size = 18,
		max_slope = 60,
		seed = 5150,
	},

	kitchen_garden = {
		display = "Kitchen Garden",
		node_types = {
			Wheat = {
				resourceType = "Wheat",
				density = 0.40,
				spacing = 6,
				variants = { "Wheat_01", "Wheat_02", "Wheat_03" },
				variantWeights = { 0.33, 0.33, 0.34 },
				scaleRange = { 0.9, 1.1 },
				yOffset = 0,
				swayRange = { min = 0.8, max = 1.2 },
			},
		},
		exclusion_tags = { "Building", "Path" },
		voxel_size = 8,
		max_slope = 15,
		seed = 4243,
	},

	summer_clearing = {
		display = "Summer Clearing",
		node_types = {
			Wheat = {
				resourceType = "Wheat",
				density = 0.50,
				spacing = 5,
				variants = { "Wheat_01", "Wheat_02", "Wheat_03" },
				variantWeights = { 0.33, 0.33, 0.34 },
				scaleRange = { 0.9, 1.1 },
				yOffset = 0,
				swayRange = { min = 0.8, max = 1.2 },
			},
			["Zunda Berry"] = {
				resourceType = "Zunda Berry",
				density = 0.40,
				spacing = 6,
				variants = { "BerryBush_01", "BerryBush_02", "BerryBush_03" },
				variantWeights = { 0.5, 0.3, 0.2 },
				scaleRange = { 0.85, 1.15 },
				yOffset = 0,
				glowWhenNear = true,
			},
		},
		exclusion_tags = { "Building", "Path" },
		voxel_size = 6,
		max_slope = 20,
		seed = 6127,
	},

	winter_grove = {
		display = "Winter Grove",
		node_types = {
			Rock = {
				resourceType = "Rock",
				density = 0.25,
				spacing = 15,
				variants = { "Rock_Common", "Rock_Rare" },
				variantWeights = { 0.8, 0.2 },
				scaleRange = { 0.8, 1.4 },
				yOffset = -0.3,
				crackStages = 3,
			},
			["Gold Ore"] = {
				resourceType = "Gold Ore",
				density = 0.10,
				spacing = 25,
				variants = { "GoldOre_Default" },
				variantWeights = { 1.0 },
				scaleRange = { 0.9, 1.1 },
				yOffset = -0.3,
				glowColor = Color3.fromRGB(255, 215, 0),
			},
		},
		exclusion_tags = { "Building", "Path", "Water" },
		voxel_size = 15,
		max_slope = 40,
		seed = 8223,
	},
}

ScatterConfig.defaults = {
	exclusion_tag = "ScatterExclude",
	max_placement_attempts = 50,
	spawn_height_offset = 2.5,
	spawn_radius = 1.5,
}

ScatterConfig.discoveryHints = {
	ZundaFlower = "A gentle flower that glows with morning dew~ 🌼",
	ZundaPea = "Plump green peas that sparkle pink! 🫛",
	["Zunda Mushroom"] = "Tiny mushrooms that dance in the shade 🍄",
	["Zunda Berry"] = "Sweet berries that blush when you approach 🍓",
	["Zunda Root"] = "Mystery roots that hum softly when dug 🌱",
	Rock = "Ordinary rock with ordinary sparkles ⛰",
	["Gold Ore"] = "Shiny ore that gleams like treasure! ✨",
	Wheat = "Golden wheat swaying in the breeze 🌾",
}

ScatterConfig.seasonalEffects = {
	summer = {
		ambientParticles = "rbxassetid://72344118179281",
		skyTint = Color3.fromRGB(180, 220, 255),
		postEffect = "rbxassetid://119265360193579",
	},
	winter = {
		ambientParticles = "rbxassetid://138168954342394",
		skyTint = Color3.fromRGB(220, 230, 255),
		postEffect = "rbxassetid://114503978860772",
	},
	spring = {
		ambientParticles = "rbxassetid://116106071236569",
		skyTint = Color3.fromRGB(200, 240, 200),
		postEffect = "rbxassetid://102598103777829",
	},
	fall = {
		ambientParticles = "rbxassetid://97345770028831",
		skyTint = Color3.fromRGB(255, 200, 150),
		postEffect = "rbxassetid://74694163979163",
	},
}

return ScatterConfig
