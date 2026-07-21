--!strict
-- [[ModuleScript] BlenderPipeline (ref: NEW)]]
-- Asset manifest for Blender → Roblox FBX pipeline.
-- Each entry defines a model to generate via Blender MCP,
-- its target Roblox asset slot, variant info, and parameters.
--
-- Usage: pass entries to Blender MCP for procedural generation,
-- then import FBX into Roblox Studio via the built-in MCP.

local BlenderPipeline = {
	-- Harvest node meshes (for HarvestNodeVariants.lua)
	harvest_nodes = {
		ZundaFlower = {
			variants = {
				{
					id = "ZundaFlower_Default",
					description = "Standard Zunda flower with curled petals, pea-green center",
					params = { petal_count = 5, stem_height = 1.2, color_hex = "#78C882", glow = false },
				},
				{
					id = "ZundaFlower_Rare",
					description = "Rare variant with lavender glow, double petals",
					params = { petal_count = 8, stem_height = 1.0, color_hex = "#E1B9FF", glow = true },
				},
			},
			target_slot = "HarvestNodeVariants.ZundaFlower.meshes",
			fbx_export_path = "Assets/HarvestNodes/ZundaFlower/",
		},
		ZundaPea = {
			variants = {
				{
					id = "ZundaPea_01",
					description = "Small pea pod, closed, bright green",
					params = { pod_size = 0.8, opened = false, color_hex = "#96E6A0" },
				},
				{
					id = "ZundaPea_02",
					description = "Medium pea pod, slightly open, peas visible",
					params = { pod_size = 1.0, opened = true, color_hex = "#82D68C" },
				},
				{
					id = "ZundaPea_03",
					description = "Large pea pod, fully opened, golden peas",
					params = { pod_size = 1.3, opened = true, color_hex = "#FFD700" },
				},
			},
			target_slot = "HarvestNodeVariants.ZundaPea.meshes",
			fbx_export_path = "Assets/HarvestNodes/ZundaPea/",
		},
		["Zunda Mushroom"] = {
			variants = {
				{
					id = "Mushroom_01",
					description = "Small round mushroom, lavender cap with spots",
					params = { cap_radius = 0.6, stem_height = 0.8, spot_count = 3, color_hex = "#E1B9FF" },
				},
				{
					id = "Mushroom_02",
					description = "Tall slender mushroom, pink gradient cap",
					params = { cap_radius = 0.5, stem_height = 1.4, spot_count = 5, color_hex = "#FFB5D4" },
				},
			},
			target_slot = "HarvestNodeVariants.['Zunda Mushroom'].meshes",
			fbx_export_path = "Assets/HarvestNodes/ZundaMushroom/",
		},
		["Zunda Berry"] = {
			variants = {
				{
					id = "BerryBush_01",
					description = "Small bush with blue berries, round canopy",
					params = { bush_radius = 1.0, berry_color_hex = "#4A90D9", berry_count = 5 },
				},
				{
					id = "BerryBush_02",
					description = "Medium bush with pink berries, spreading",
					params = { bush_radius = 1.3, berry_color_hex = "#FF69B4", berry_count = 8 },
				},
				{
					id = "BerryBush_03",
					description = "Large bush with gold berries, tall",
					params = { bush_radius = 1.5, berry_color_hex = "#FFD700", berry_count = 12 },
				},
			},
			target_slot = "HarvestNodeVariants.['Zunda Berry'].meshes",
			fbx_export_path = "Assets/HarvestNodes/ZundaBerry/",
		},
		["Zunda Root"] = {
			variants = {
				{
					id = "Root_01",
					description = "Short gnarled root, brown",
					params = { length = 0.8, twist = 0.3, color_hex = "#8B6514" },
				},
				{
					id = "Root_02",
					description = "Long twisted root with glowing tip",
					params = { length = 1.4, twist = 0.7, color_hex = "#A0782C" },
				},
			},
			target_slot = "HarvestNodeVariants.['Zunda Root'].meshes",
			fbx_export_path = "Assets/HarvestNodes/ZundaRoot/",
		},
		Rock = {
			variants = {
				{
					id = "Rock_Common",
					description = "Grey rounded rock, medium",
					params = { roughness = 0.7, color_hex = "#808080", size = 1.0 },
				},
				{
					id = "Rock_Rare",
					description = "Dark rock with crystal veins",
					params = { roughness = 0.4, color_hex = "#4A4A4A", crystal = true, size = 1.2 },
				},
			},
			target_slot = "HarvestNodeVariants.Rock.meshes",
			fbx_export_path = "Assets/HarvestNodes/Rock/",
		},
		["Gold Ore"] = {
			variants = {
				{
					id = "GoldOre_Default",
					description = "Rock with gold veins, warm glow",
					params = { roughness = 0.5, color_hex = "#8B4513", vein_color = "#FFD700", glow = true },
				},
			},
			target_slot = "HarvestNodeVariants.['Gold Ore'].meshes",
			fbx_export_path = "Assets/HarvestNodes/GoldOre/",
		},
		Wheat = {
			variants = {
				{
					id = "Wheat_01",
					description = "Short wheat stalk, green",
					params = { height = 1.0, head_size = 0.4, color_hex = "#90EE50" },
				},
				{
					id = "Wheat_02",
					description = "Medium wheat stalk, golden",
					params = { height = 1.4, head_size = 0.5, color_hex = "#DAA520" },
				},
				{
					id = "Wheat_03",
					description = "Tall wheat stalk, ripe gold",
					params = { height = 1.8, head_size = 0.6, color_hex = "#FFD700" },
				},
			},
			target_slot = "HarvestNodeVariants.Wheat.meshes",
			fbx_export_path = "Assets/HarvestNodes/Wheat/",
		},
	},

	-- Environment props
	environment_props = {
		Forest = {
			{
				id = "ZundaTree_01",
				description = "Round canopy tree with pea-green leaves",
				params = { trunk_height = 4.0, canopy_radius = 3.0, color_hex = "#78C882" },
				fbx_export_path = "Assets/Environment/Forest/Trees/",
			},
			{
				id = "ZundaTree_02",
				description = "Tall slender tree with lavender flowers",
				params = { trunk_height = 6.0, canopy_radius = 2.5, color_hex = "#E1B9FF" },
				fbx_export_path = "Assets/Environment/Forest/Trees/",
			},
			{
				id = "ForestFloor_Flowers",
				description = "Small ground cover flowers, mix of green and pink",
				params = { patch_radius = 2.0, density = 0.6, colors = { "#78C882", "#E1B9FF" } },
				fbx_export_path = "Assets/Environment/Forest/GroundCover/",
			},
		},
		Kitchen = {
			{
				id = "KitchenCounter_01",
				description = "Wooden kitchen counter with Zunda-green trim",
				params = { length = 4.0, depth = 2.5, height = 1.0, trim_color = "#78C882" },
				fbx_export_path = "Assets/Environment/Kitchen/Counters/",
			},
			{
				id = "KitchenShelf_01",
				description = "Wall shelf with ingredient jars",
				params = { length = 3.0, shelves = 2, jar_count = 4 },
				fbx_export_path = "Assets/Environment/Kitchen/Shelves/",
			},
			{
				id = "CookingPot_01",
				description = "Large cooking pot with Zunda stew",
				params = { diameter = 2.0, color_hex = "#4A4A4A", contents_color = "#96E6A0" },
				fbx_export_path = "Assets/Environment/Kitchen/Utensils/",
			},
		},
		House = {
			{
				id = "ZundaHouse_01",
				description = "Round cottage with pea-green roof, warm walls",
				params = { width = 8.0, depth = 6.0, height = 4.0, roof_color = "#78C882", wall_color = "#FFF8DC" },
				fbx_export_path = "Assets/Environment/Houses/Zunda/",
			},
			{
				id = "GardenFence_01",
				description = "Low wooden fence with Zunda-gate",
				params = { segment_count = 5, segment_length = 2.0, color_hex = "#8B6514" },
				fbx_export_path = "Assets/Environment/Houses/Fences/",
			},
		},
	},

	-- UI icons (for UIAssets.lua)
	ui_icons = {
		{ id = "icon_wheat", description = "Wheat icon for inventory", params = { subject = "wheat", style = "kawaii" }, target_slot = "UIAssets.icons.Wheat" },
		{ id = "icon_zunda_flower", description = "Zunda Flower icon", params = { subject = "flower", color_hex = "#E1B9FF" }, target_slot = "UIAssets.icons['Zunda Flower']" },
		{ id = "icon_zunda_pea", description = "Zunda Pea icon", params = { subject = "pea", color_hex = "#96E6A0" }, target_slot = "UIAssets.icons['Zunda Pea']" },
		{ id = "icon_zunda_berry", description = "Zunda Berry icon", params = { subject = "berry", color_hex = "#FF69B4" }, target_slot = "UIAssets.icons['Zunda Berry']" },
		{ id = "icon_zunda_mushroom", description = "Zunda Mushroom icon", params = { subject = "mushroom", color_hex = "#E1B9FF" }, target_slot = "UIAssets.icons['Zunda Mushroom']" },
		{ id = "icon_zunda_root", description = "Zunda Root icon", params = { subject = "root", color_hex = "#8B6514" }, target_slot = "UIAssets.icons['Zunda Root']" },
		{ id = "icon_bread", description = "Bread icon", params = { subject = "bread", color_hex = "#DAA520" }, target_slot = "UIAssets.icons.Bread" },
		{ id = "icon_apple_pie", description = "Apple Pie icon", params = { subject = "pie", color_hex = "#D2691E" }, target_slot = "UIAssets.icons['Apple Pie']" },
		{ id = "icon_zunda_mochi", description = "Zunda Mochi icon", params = { subject = "mochi", color_hex = "#96E6A0" }, target_slot = "UIAssets.icons['Zunda Mochi']" },
	},

	-- Particle textures
	particles = {
		{ id = "sparkle_green", description = "Zunda-green sparkle for harvest FX", params = { color_hex = "#78C882", shape = "star" }, target_slot = "UIAssets.particles.harvest_sparkle" },
		{ id = "sparkle_lavender", description = "Lavender sparkle for magic FX", params = { color_hex = "#E1B9FF", shape = "circle" }, target_slot = "UIAssets.particles.craft_magic" },
		{ id = "sparkle_gold", description = "Gold sparkle for rewards/levelup", params = { color_hex = "#FFD700", shape = "star" }, target_slot = "UIAssets.particles.serve_stars" },
	},
}

return BlenderPipeline
