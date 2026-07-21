--!strict
-- [[ModuleScript] ArchitecturePipeline]]
-- Asset manifest for a Roblox procedural architecture addon.
-- Each entry defines a building or environment prop to generate via a procedural pipeline,
-- its target Roblox config slot, variant info, and export path for FBX/OBJ generation.

local ArchitecturePipeline = {
	buildings = {
		MarketHall = {
			variants = {
				{
					id = "MarketHall_01",
					description = "Large market hall with a glass roof and warm exterior lights",
					params = { width = 10.0, depth = 8.0, height = 5.0, roof_style = "gabled", wall_color = "#F5F0C0" },
				},
				{
					id = "MarketHall_02",
					description = "Smaller market pavilion with open-air stalls and green trim",
					params = { width = 8.0, depth = 6.0, height = 4.5, roof_style = "hipped", wall_color = "#E8F8E5" },
				},
			},
			target_slot = "ArchitectureVariants.MarketHall.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Buildings/MarketHall/",
		},
		BakeryStall = {
			variants = {
				{
					id = "BakeryStall_01",
					description = "Small bakery stall with a pastry display window and warm brick facade",
					params = { width = 6.0, depth = 4.0, height = 3.5, roof_style = "flat", trim_color = "#A97449" },
				},
			},
			target_slot = "ArchitectureVariants.BakeryStall.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Buildings/BakeryStall/",
		},
	},

	street_props = {
		StreetLamp = {
			variants = {
				{
					id = "StreetLamp_01",
					description = "Tall street lamp with a curved arm and warm lantern glow",
					params = { height = 4.5, arm_length = 1.2, light_color = "#FFF4A8" },
				},
			},
			target_slot = "ArchitectureVariants.StreetLamp.meshes",
			fbx_export_path = "Assets/Generated/Architecture/StreetProps/StreetLamp/",
		},
		Bench = {
			variants = {
				{
					id = "Bench_01",
					description = "Stone bench with carved details and weathered finish",
					params = { length = 2.0, material = "stone", cushion_color = "#C2B280" },
				},
			},
			target_slot = "ArchitectureVariants.Bench.meshes",
			fbx_export_path = "Assets/Generated/Architecture/StreetProps/Bench/",
		},
	},

	interiors = {
		CounterIsland = {
			variants = {
				{
					id = "CounterIsland_01",
					description = "Multi-station kitchen counter island with built-in seating",
					params = { width = 4.0, depth = 1.2, height = 1.0, counter_color = "#8B6514" },
				},
			},
			target_slot = "ArchitectureVariants.CounterIsland.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Interiors/CounterIsland/",
		},
	},

	decor = {
		Balcony = {
			variants = {
				{
					id = "Balcony_01",
					description = "Small balcony with wooden railing and hanging plants",
					params = { width = 3.0, depth = 1.0, railing_style = "wood", planter_count = 2 },
				},
			},
			target_slot = "ArchitectureVariants.Balcony.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Decor/Balcony/",
		},
	},

	foliage = {
		ZundaFlower = {
			variants = {
				{
					id = "ZundaFlower_Default",
					description = "A gentle flower that glows with morning dew",
					params = { height = 1.2, color = "#E1B9FF" },
				},
				{
					id = "ZundaFlower_Rare",
					description = "A rare glowing variant of the Zunda Flower",
					params = { height = 1.5, color = "#FFD700" },
				},
			},
			target_slot = "ArchitectureVariants.ZundaFlower.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Foliage/ZundaFlower/",
		},
		BerryBush = {
			variants = {
				{
					id = "BerryBush_01",
					description = "Small berry bush with ripe fruits",
					params = { height = 1.0, berry_color = "#FF69B4" },
				},
				{
					id = "BerryBush_02",
					description = "Tall berry bush with abundant clusters",
					params = { height = 1.8, berry_color = "#FF4500" },
				},
				{
					id = "BerryBush_03",
					description = "Wild berry thicket with hidden fruits",
					params = { height = 2.0, berry_color = "#8B008B" },
				},
			},
			target_slot = "ArchitectureVariants.BerryBush.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Foliage/BerryBush/",
		},
		ZundaMushroom = {
			variants = {
				{
					id = "Mushroom_01",
					description = "Tiny bioluminescent mushroom cluster",
					params = { height = 0.6, cap_color = "#E1B9FF" },
				},
				{
					id = "Mushroom_02",
					description = "Large capped forest mushroom",
					params = { height = 1.2, cap_color = "#FF6347" },
				},
			},
			target_slot = "ArchitectureVariants.ZundaMushroom.meshes",
			fbx_export_path = "Assets/Generated/Architecture/Foliage/ZundaMushroom/",
		},
	},
}

return ArchitecturePipeline
