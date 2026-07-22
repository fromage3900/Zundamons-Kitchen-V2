--!strict
-- [[ModuleScript] GrowthStageConfig]]
-- Defines growth stages for harvest nodes using localized meshes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResourceVisualCatalog = require(ReplicatedStorage.ConfigurationFiles.ResourceVisualCatalog)

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

function GrowthStageConfig.getDescriptor(stageConfig: table): any
	return ResourceVisualCatalog.get(stageConfig.name)
end

-- Compatibility for callers not yet migrated to visual descriptors.
function GrowthStageConfig.getMeshId(stageConfig: table): string
	local descriptor = GrowthStageConfig.getDescriptor(stageConfig)
	return if descriptor and descriptor.enabled then descriptor.assetId else ""
end

-- Get all stages for a node type
function GrowthStageConfig.getStages(nodeType: string): { table }
	return GrowthStageConfig[nodeType] or {}
end

-- Get harvestable stage
function GrowthStageConfig.getHarvestableStage(nodeType: string): table?
	local stages = GrowthStageConfig[nodeType]
	if not stages then
		return nil
	end

	for _, stage in ipairs(stages) do
		if stage.harvestable then
			return stage
		end
	end

	return nil
end

return GrowthStageConfig
