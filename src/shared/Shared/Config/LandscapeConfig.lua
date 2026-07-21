--!strict
-- Shared biome and asset placement definitions for procedural landscape generation.

local LandscapeConfig = {}

LandscapeConfig.biomes = {
	GardenVillage = {
		name = "GardenVillage",
		description = "A cozy village courtyard with paths, market lots, and garden clusters.",
		seed = 42,
		zones = {
			{ name = "Plaza", type = "central", size = 18, weight = 1.0, maxBuildings = 2, spawnProfile = "plaza" },
			{ name = "GardenEdge", type = "garden", size = 24, weight = 0.9, maxBuildings = 1, spawnProfile = "garden" },
			{ name = "MarketRow", type = "street", size = 16, weight = 0.8, maxBuildings = 3, spawnProfile = "market" },
			{ name = "PathLoop", type = "path", size = 12, weight = 0.6, maxBuildings = 0, spawnProfile = "path" },
		},
		assetProfiles = {
			plaza = {
				{ asset = "MarketHall", category = "buildings", weight = 0.55, required = true },
				{ asset = "StreetLamp", category = "street_props", weight = 0.8 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
			garden = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.9 },
				{ asset = "BerryBush", category = "foliage", weight = 0.7 },
				{ asset = "ZundaMushroom", category = "foliage", weight = 0.4 },
			},
			market = {
				{ asset = "BakeryStall", category = "buildings", weight = 0.8 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.9 },
			},
			path = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.6 },
				{ asset = "Bench", category = "street_props", weight = 0.5 },
			},
		},
		constraints = {
			pathSpacing = 6,
			minBuildingGap = 8,
			maxClusterSize = 5,
		},
	},
	ZundaMarket = {
		name = "ZundaMarket",
		description = "A busy market square with stalls, lanterns, and food vendors.",
		seed = 77,
		zones = {
			{ name = "MarketSquare", type = "central", size = 20, weight = 1.0, maxBuildings = 3, spawnProfile = "market_square" },
			{ name = "VendorRow", type = "street", size = 18, weight = 0.95, maxBuildings = 4, spawnProfile = "vendor_row" },
			{ name = "MarketGarden", type = "garden", size = 16, weight = 0.75, maxBuildings = 1, spawnProfile = "market_garden" },
		},
		assetProfiles = {
			market_square = {
				{ asset = "MarketHall", category = "buildings", weight = 0.8, required = true },
				{ asset = "BakeryStall", category = "buildings", weight = 0.75 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.85 },
				{ asset = "Bench", category = "street_props", weight = 0.65 },
			},
			vendor_row = {
				{ asset = "BakeryStall", category = "buildings", weight = 0.9 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.8 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
			market_garden = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.95 },
				{ asset = "BerryBush", category = "foliage", weight = 0.75 },
			},
		},
		constraints = {
			pathSpacing = 5,
			minBuildingGap = 7,
			maxClusterSize = 6,
		},
	},
	Promenade = {
		name = "Promenade",
		description = "A long scenic promenade lined with lights, benches, and decorative shrubs.",
		seed = 91,
		zones = {
			{ name = "MainWalk", type = "street", size = 24, weight = 1.0, maxBuildings = 2, spawnProfile = "walk" },
			{ name = "GardenNook", type = "garden", size = 16, weight = 0.8, maxBuildings = 1, spawnProfile = "nook" },
			{ name = "ViewingPoint", type = "central", size = 14, weight = 0.7, maxBuildings = 1, spawnProfile = "view" },
		},
		assetProfiles = {
			walk = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.95, required = true },
				{ asset = "Bench", category = "street_props", weight = 0.9 },
			},
			nook = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.9 },
				{ asset = "BerryBush", category = "foliage", weight = 0.8 },
			},
			view = {
				{ asset = "Bench", category = "street_props", weight = 0.8 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.75 },
			},
		},
		constraints = {
			pathSpacing = 4,
			minBuildingGap = 6,
			maxClusterSize = 4,
		},
	},
	Forest = {
		name = "Forest",
		description = "A dense forest edge with winding paths, mushrooms, and hidden clearings.",
		seed = 112,
		zones = {
			{ name = "CanopyEdge", type = "garden", size = 22, weight = 1.0, maxBuildings = 1, spawnProfile = "canopy" },
			{ name = "MushroomRing", type = "path", size = 18, weight = 0.85, maxBuildings = 0, spawnProfile = "mushroom" },
			{ name = "HiddenClearing", type = "central", size = 16, weight = 0.75, maxBuildings = 1, spawnProfile = "clearing" },
		},
		assetProfiles = {
			canopy = {
				{ asset = "ZundaMushroom", category = "foliage", weight = 0.95 },
				{ asset = "BerryBush", category = "foliage", weight = 0.7 },
			},
			mushroom = {
				{ asset = "ZundaMushroom", category = "foliage", weight = 0.9 },
				{ asset = "ZundaFlower", category = "foliage", weight = 0.6 },
			},
			clearing = {
				{ asset = "Bench", category = "street_props", weight = 0.7 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.55 },
			},
		},
		constraints = {
			pathSpacing = 4,
			minBuildingGap = 6,
			maxClusterSize = 7,
		},
	},
	BerryOrchard = {
		name = "BerryOrchard",
		description = "A bright berry orchard with winding rows, fruit clusters, and picnic nooks.",
		seed = 123,
		zones = {
			{ name = "FruitRows", type = "garden", size = 20, weight = 1.0, maxBuildings = 1, spawnProfile = "rows" },
			{ name = "PicnicNook", type = "central", size = 14, weight = 0.8, maxBuildings = 1, spawnProfile = "picnic" },
			{ name = "PathEdge", type = "path", size = 16, weight = 0.75, maxBuildings = 0, spawnProfile = "edge" },
		},
		assetProfiles = {
			rows = {
				{ asset = "BerryBush", category = "foliage", weight = 0.95 },
				{ asset = "ZundaFlower", category = "foliage", weight = 0.8 },
			},
			picnic = {
				{ asset = "Bench", category = "street_props", weight = 0.9 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.6 },
			},
			edge = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.75 },
				{ asset = "BerryBush", category = "foliage", weight = 0.7 },
			},
		},
		constraints = {
			pathSpacing = 5,
			minBuildingGap = 6,
			maxClusterSize = 5,
		},
	},
	MeadowPlaza = {
		name = "MeadowPlaza",
		description = "A bright meadow plaza with open lawns, flower beds, and social gathering space.",
		seed = 134,
		zones = {
			{ name = "CenterStage", type = "central", size = 18, weight = 1.0, maxBuildings = 2, spawnProfile = "center" },
			{ name = "FlowerBeds", type = "garden", size = 20, weight = 0.9, maxBuildings = 1, spawnProfile = "flowers" },
			{ name = "LanternWalk", type = "street", size = 16, weight = 0.8, maxBuildings = 2, spawnProfile = "lanterns" },
		},
		assetProfiles = {
			center = {
				{ asset = "Bench", category = "street_props", weight = 0.9, required = true },
				{ asset = "StreetLamp", category = "street_props", weight = 0.8 },
			},
			flowers = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.95 },
				{ asset = "BerryBush", category = "foliage", weight = 0.65 },
			},
			lanterns = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.95 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
		},
		constraints = {
			pathSpacing = 5,
			minBuildingGap = 7,
			maxClusterSize = 6,
		},
	},
	SunsetGrove = {
		name = "SunsetGrove",
		description = "A warm sunset grove with soft lighting, benches, and layered shrubs.",
		seed = 145,
		zones = {
			{ name = "GroveCenter", type = "central", size = 16, weight = 1.0, maxBuildings = 1, spawnProfile = "grove" },
			{ name = "ShrubRing", type = "garden", size = 20, weight = 0.85, maxBuildings = 1, spawnProfile = "shrubs" },
			{ name = "GlowPath", type = "street", size = 18, weight = 0.8, maxBuildings = 2, spawnProfile = "glow" },
		},
		assetProfiles = {
			grove = {
				{ asset = "Bench", category = "street_props", weight = 0.8 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.8 },
			},
			shrubs = {
				{ asset = "BerryBush", category = "foliage", weight = 0.9 },
				{ asset = "ZundaFlower", category = "foliage", weight = 0.75 },
			},
			glow = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.95 },
				{ asset = "Bench", category = "street_props", weight = 0.75 },
			},
		},
		constraints = {
			pathSpacing = 4,
			minBuildingGap = 6,
			maxClusterSize = 5,
		},
	},
	WheatField = {
		name = "WheatField",
		description = "A golden wheat field with tall grass, scarecrows, and hidden paths through the grain.",
		seed = 167,
		zones = {
			{ name = "GrainCenter", type = "central", size = 22, weight = 1.0, maxBuildings = 2, spawnProfile = "grain" },
			{ name = "TallGrassRing", type = "garden", size = 26, weight = 0.9, maxBuildings = 0, spawnProfile = "tallgrass" },
			{ name = "ScarecrowRow", type = "street", size = 18, weight = 0.8, maxBuildings = 2, spawnProfile = "scarecrow" },
		},
		assetProfiles = {
			grain = {
				{ asset = "Bench", category = "street_props", weight = 0.75 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.7 },
			},
			tallgrass = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.85 },
				{ asset = "BerryBush", category = "foliage", weight = 0.8 },
			},
			scarecrow = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.9 },
				{ asset = "Bench", category = "street_props", weight = 0.65 },
			},
		},
		constraints = {
			pathSpacing = 6,
			minBuildingGap = 8,
			maxClusterSize = 7,
		},
	},
	WheatCrystalGarden = {
		name = "CrystalGarden",
		description = "A shimmering garden with crystalline flora, glowing mushrooms, and luminescent pathways.",
		seed = 178,
		zones = {
			{ name = "CrystalHeart", type = "central", size = 18, weight = 1.0, maxBuildings = 1, spawnProfile = "crystal" },
			{ name = "GlowShroomRing", type = "garden", size = 22, weight = 0.9, maxBuildings = 0, spawnProfile = "glowshroom" },
			{ name = "CrystalPath", type = "street", size = 16, weight = 0.8, maxBuildings = 2, spawnProfile = "crystalpath" },
		},
		assetProfiles = {
			crystal = {
				{ asset = "ZundaMushroom", category = "foliage", weight = 0.95 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
			glowshroom = {
				{ asset = "ZundaMushroom", category = "foliage", weight = 0.9 },
				{ asset = "ZundaFlower", category = "foliage", weight = 0.75 },
			},
			crystalpath = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.95 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
		},
		constraints = {
			pathSpacing = 4,
			minBuildingGap = 6,
			maxClusterSize = 6,
		},
	},
	MoonlitGarden = {
		name = "MoonlitGarden",
		description = "A serene moonlit garden with soft flora, lantern paths, and reflective clearings.",
		seed = 156,
		zones = {
			{ name = "MoonClearing", type = "central", size = 16, weight = 1.0, maxBuildings = 1, spawnProfile = "moon" },
			{ name = "LanternPath", type = "street", size = 18, weight = 0.9, maxBuildings = 2, spawnProfile = "lanternpath" },
			{ name = "BloomRing", type = "garden", size = 20, weight = 0.85, maxBuildings = 0, spawnProfile = "bloom" },
		},
		assetProfiles = {
			moon = {
				{ asset = "Bench", category = "street_props", weight = 0.8 },
				{ asset = "StreetLamp", category = "street_props", weight = 0.9 },
			},
			lanternpath = {
				{ asset = "StreetLamp", category = "street_props", weight = 0.95 },
				{ asset = "Bench", category = "street_props", weight = 0.7 },
			},
			bloom = {
				{ asset = "ZundaFlower", category = "foliage", weight = 0.95 },
				{ asset = "BerryBush", category = "foliage", weight = 0.75 },
			},
		},
		constraints = {
			pathSpacing = 4,
			minBuildingGap = 6,
			maxClusterSize = 6,
		},
	},
}

function LandscapeConfig.getBiome(name)
	if not name then
		return LandscapeConfig.biomes.GardenVillage
	end

	return LandscapeConfig.biomes[name] or LandscapeConfig.biomes.GardenVillage
end

return LandscapeConfig
