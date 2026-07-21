--!strict
-- [[ModuleScript] GrowthStageConfig]]
-- Defines growth stages for harvest nodes using localized meshes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeshProvider = require(ReplicatedStorage.Shared.Modules.MeshProvider)

local GrowthStageConfig = {}

-- Growth stages for CarrotPlot-style nodes
-- Each stage has a mesh reference, scale, and respawn time
GrowthStageConfig.CarrotPlot = {
	{
		name = "Seed",
		meshCategory = "HarvestNodes",
		meshName = "CarrotPlot", -- Will look for "Seed" child in CarrotPlot folder
		scale = 0.3,
		respawnTime = 10,
	},
	{
		name = "SeedLeaf",
		meshCategory = "HarvestNodes",
		meshName = "CarrotPlot",
		scale = 0.5,
		respawnTime = 15,
	},
	{
		name = "Leaf",
		meshCategory = "HarvestNodes",
		meshName = "CarrotPlot",
		scale = 0.8,
		respawnTime = 20,
	},
	{
		name = "Mature",
		meshCategory = "HarvestNodes",
		meshName = "CarrotPlot",
		scale = 1.0,
		respawnTime = 25,
		harvestable = true,
	},
}

-- Get mesh ID for a growth stage
function GrowthStageConfig.getMeshId(stageConfig: table): string
	local category = stageConfig.meshCategory
	local folderName = stageConfig.meshName
	local stageName = stageConfig.name
	
	-- Try to get from MeshProvider (localized meshes)
	local meshId = MeshProvider.get(category .. "/" .. folderName, stageName)
	if meshId ~= "" then
		return meshId
	end
	
	-- Fallback to MeshAssets config (asset IDs)
	local MeshAssets = require(ReplicatedStorage.ConfigurationFiles.MeshAssets)
	if MeshAssets.meshes[folderName] and MeshAssets.meshes[folderName][stageName] then
		return MeshAssets.meshes[folderName][stageName]
	end
	
	warn(`[GrowthStageConfig] No mesh found for {folderName}/{stageName}`)
	return ""
end

-- Get all stages for a node type
function GrowthStageConfig.getStages(nodeType: string): {table}
	return GrowthStageConfig[nodeType] or {}
end

-- Get harvestable stage
function GrowthStageConfig.getHarvestableStage(nodeType: string): table?
	local stages = GrowthStageConfig[nodeType]
	if not stages then return nil end
	
	for _, stage in ipairs(stages) do
		if stage.harvestable then
			return stage
		end
	end
	
	return nil
end

return GrowthStageConfig
