-- Harvest Node Variants Configuration
-- FBX substitutes available in Downloads:\kenney_survival-kit\Models\FBX format\
-- Rock/Grass can substitute for plants; see docs/asset-mapping.md for full list
-- Deprecated: Use MeshAssets.lua (ConfigurationFiles) instead.
-- Kept for reference / fallback.
local Variants = {
	Wheat = {
		meshes = {
			["Wheat_01"] = "rbxassetid://120483243502197",
			["Wheat_02"] = "rbxassetid://124905165003062",
			["Wheat_03"] = "rbxassetid://127847933091778",
		},
		resourceType = "Wheat",
		swayRange = { min = 0.8, max = 1.2 },
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.9, 1.1 },
	},

	ZundaFlower = {
		meshes = {
			["ZundaFlower_Default"] = "rbxassetid://130899236683010",
			["ZundaFlower_Rare"] = "rbxassetid://86582218951352",
		},
		resourceType = "ZundaFlower",
		spinSpeed = 0.5,
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.8, 1.2 },
	},

	ZundaPea = {
		meshes = {
			["ZundaPea_01"] = "rbxassetid://106482523402868",
			["ZundaPea_02"] = "rbxassetid://119452475051045",
			["ZundaPea_03"] = "rbxassetid://107116519758062",
		},
		resourceType = "ZundaPea",
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.9, 1.1 },
	},

	["Zunda Mushroom"] = {
		meshes = {
			["Mushroom_01"] = "rbxassetid://96331224587968",
			["Mushroom_02"] = "rbxassetid://85124051974569",
		},
		resourceType = "Zunda Mushroom",
		bobHeight = 0.3,
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.7, 1.3 },
	},

	["Zunda Berry"] = {
		meshes = {
			["BerryBush_01"] = "rbxassetid://91224321091798",
			["BerryBush_02"] = "rbxassetid://74222048987638",
			["BerryBush_03"] = "rbxassetid://76322051780722",
		},
		resourceType = "Zunda Berry",
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.85, 1.15 },
	},

	["Zunda Root"] = {
		meshes = {
			["Root_01"] = "rbxassetid://106581238862764",
			["Root_02"] = "rbxassetid://122644985457254",
		},
		resourceType = "Zunda Root",
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.9, 1.1 },
	},

	Rock = {
		meshes = {
			["Rock_Common"] = "rbxassetid://74975285002856",
			["Rock_Rare"] = "rbxassetid://138139954211772",
		},
		resourceType = "Rock",
		crackStages = 3,
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.8, 1.4 },
	},

	["Gold Ore"] = {
		meshes = {
			["GoldOre_Default"] = "rbxassetid://105153259339546",
		},
		resourceType = "Gold Ore",
		glowColor = Color3.fromRGB(255, 215, 0),
		harvestEffect = "rbxassetid://241685484",
		scaleRange = { 0.9, 1.1 },
	},
}

function Variants.getMesh(nodeType: string, variantId: string?): string
	local config = Variants[nodeType]
	if not config then
		return ""
	end
	if variantId and config.meshes[variantId] then
		return config.meshes[variantId]
	end
	for _, meshId in pairs(config.meshes) do
		return meshId
	end
	return ""
end

function Variants.getVariantIds(nodeType: string): { string }
	local config = Variants[nodeType]
	if not config then
		return {}
	end
	local ids: { string } = {}
	for id, _ in pairs(config.meshes) do
		table.insert(ids, id)
	end
	return ids
end

function Variants.getScaleRange(nodeType: string): { number }
	local config = Variants[nodeType]
	if not config then
		return { 1, 1 }
	end
	return config.scaleRange
end

return Variants
