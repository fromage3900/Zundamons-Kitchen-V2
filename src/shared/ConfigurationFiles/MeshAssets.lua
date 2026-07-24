--!strict
-- Compatibility adapter. New resource visual code must use
-- ResourceVisualCatalog descriptors rather than raw mesh IDs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.ConfigurationFiles.ResourceVisualCatalog)

local MeshAssets = {}

local variantsByVisualKey: { [string]: { string } } = {
	Tree = { "Variant1", "Variant2" },
	Rock = { "Rock_Common", "Rock_Rare" },
	["Gold Ore"] = { "GoldOre_Default" },
	Wheat = { "Wheat_01", "Wheat_02", "Wheat_03" },
	ZundaFlower = { "ZundaFlower_Default", "ZundaFlower_Rare" },
	ZundaPea = { "ZundaPea_01", "ZundaPea_02", "ZundaPea_03" },
	["Zunda Mushroom"] = { "Mushroom_01", "Mushroom_02" },
	["Zunda Berry"] = { "BerryBush_01", "BerryBush_02", "BerryBush_03" },
	["Zunda Root"] = { "Root_01", "Root_02" },
	CarrotPlot = { "Seed", "SeedLeaf", "Leaf", "Mature" },
	EdamamePod = { "EdamamePod_Default" },
	ZundaLeaf = { "ZundaLeaf_Default" },
	SweetPea = { "SweetPea_Default" },
	PeaFlower = { "PeaFlower_Default" },
	SaltedPeaBouquet = { "SaltedPeaBouquet_Default" },
}

MeshAssets.meshes = {}
for visualKey, variants in variantsByVisualKey do
	local values = {}
	for _, variantId in variants do
		local descriptor = Catalog.get(variantId)
		values[variantId] = if descriptor and descriptor.enabled then descriptor.assetId else ""
	end
	MeshAssets.meshes[visualKey] = values
end

function MeshAssets.getMeshId(visualKey: string, variantId: string?): string
	if variantId then
		local descriptor = Catalog.get(variantId)
		return if descriptor and descriptor.enabled then descriptor.assetId else ""
	end
	for _, candidate in variantsByVisualKey[visualKey] or {} do
		local descriptor = Catalog.get(candidate)
		if descriptor and descriptor.enabled then
			return descriptor.assetId
		end
	end
	return ""
end

MeshAssets.getMesh = MeshAssets.getMeshId

function MeshAssets.getVariantIds(visualKey: string): { string }
	return table.clone(variantsByVisualKey[visualKey] or {})
end

return table.freeze(MeshAssets)
