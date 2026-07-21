-- [[ModuleScript] PlantConfig (ref: RBX5E18C669766B475697CF47E2B5B882CD)]]
local SS = game.ServerStorage
local plantModels = SS:WaitForChild("Plants")
local plants = {}

plants.items={["WheatSeed"]={["Grow_Time"]=5, 
	                         ["Sprout"]=plantModels:WaitForChild("Wheat Plant(Young)")},

	["Wheat Plant(Young)"]={["Grow_Time"]=5, 
		                     ["Sprout"]=plantModels:WaitForChild("Wheat Plant")}
}

return plants
