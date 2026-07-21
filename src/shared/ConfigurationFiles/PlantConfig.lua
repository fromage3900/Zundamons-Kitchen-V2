-- [[ModuleScript] PlantConfig (ref: RBX5E18C669766B475697CF47E2B5B882CD)]]
local RunService = game:GetService("RunService")
local plantModels = nil
if RunService:IsServer() then
	plantModels = game:GetService("ServerStorage"):WaitForChild("Plants")
end

local plants = {}

-- Safely construct the table, letting Sprout be nil on the client
plants.items={["WheatSeed"]={["Grow_Time"]=5,
	                         ["Sprout"]=plantModels and plantModels:WaitForChild("Wheat Plant(Young)")},

	["Wheat Plant(Young)"]={["Grow_Time"]=5,
		                     ["Sprout"]=plantModels and plantModels:WaitForChild("Wheat Plant")}
}

return plants
