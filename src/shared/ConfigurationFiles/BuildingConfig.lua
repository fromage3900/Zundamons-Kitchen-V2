-- [[ModuleScript] BuildingConfig (ref: RBXF956EB362B02471EBFD59EE11F8B3C31)]]
-- BuildingConfig: Defines all buildings, their doors, and interior connections

local BuildingConfig = {
	-- GrandCafe: Main restaurant hub
	["GrandCafe"] = {
		name = "Grand Cafe",
		emoji = "🍽",
		description = "A cozy cafe to rest and eat",
		doors = {
			{
				name = "GrandCafe_Door_Main",
				displayName = "🚪 Grand Cafe",
				position = Vector3.new(0, 7, -30),
				interiorSpawnPos = Vector3.new(0, 3, 0),
				exteriorReturnPos = Vector3.new(0, 7, -20),
			},
		},
		interiorFolder = "GrandCafe_Interior",
	},

	-- KitchenWorkshop: Cooking area
	["KitchenWorkshop"] = {
		name = "Kitchen Workshop",
		emoji = "🍳",
		description = "Where recipes come to life",
		doors = {
			{
				name = "KitchenWorkshop_Door_Main",
				displayName = "🚪 Kitchen Workshop",
				position = Vector3.new(30, 7, -30),
				interiorSpawnPos = Vector3.new(0, 3, 0),
				exteriorReturnPos = Vector3.new(30, 7, -20),
			},
		},
		interiorFolder = "KitchenWorkshop_Interior",
	},

	-- BakeryStall: Baking shop
	["BakeryStall"] = {
		name = "Bakery Stall",
		emoji = "🥐",
		description = "Freshly baked goods",
		doors = {
			{
				name = "BakeryStall_Door_Main",
				displayName = "🚪 Bakery Stall",
				position = Vector3.new(-30, 7, -30),
				interiorSpawnPos = Vector3.new(0, 3, 0),
				exteriorReturnPos = Vector3.new(-30, 7, -20),
			},
		},
		interiorFolder = "BakeryStall_Interior",
	},
}

return BuildingConfig
