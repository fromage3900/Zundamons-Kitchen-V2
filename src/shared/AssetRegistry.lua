--!strict
-- Project-wide asset registry. Resource visuals are delegated to the canonical
-- ResourceVisualCatalog so harvest systems cannot drift between ID tables.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResourceVisualCatalog = require(ReplicatedStorage.ConfigurationFiles.ResourceVisualCatalog)

local AssetRegistry = {
	Name = "Zundamon's Kitchen V2 Asset Registry",
	Version = "2.0.0",
	ResourceVisuals = ResourceVisualCatalog.getAll(),
	Textures = {},
	Audio = {},
	Particles = {},
	Animations = {},
}

local function descend(root: any, path: { string }): any
	local value = root
	for _, key in path do
		if type(value) ~= "table" then
			return nil
		end
		value = value[key]
	end
	return value
end

function AssetRegistry.Get(category: string, subcategory: string?, assetName: string?): any
	local path = { category }
	if subcategory and subcategory ~= "" then
		table.insert(path, subcategory)
	end
	if assetName and assetName ~= "" then
		table.insert(path, assetName)
	end
	return descend(AssetRegistry, path)
end

function AssetRegistry.Validate(): { string }
	local invalid = {}
	for variantId, descriptor in ResourceVisualCatalog.getAll() do
		local normalized = ResourceVisualCatalog.normalizeAssetId(descriptor.assetId)
		if descriptor.enabled and normalized == "" then
			table.insert(invalid, "ResourceVisuals." .. variantId .. ".assetId")
		end
	end
	table.sort(invalid)
	return invalid
end

function AssetRegistry.GetMissingIDs(): { string }
	local missing = {}
	for variantId, descriptor in ResourceVisualCatalog.getAll() do
		if descriptor.enabled and ResourceVisualCatalog.normalizeAssetId(descriptor.assetId) == "" then
			table.insert(missing, "ResourceVisuals." .. variantId)
		end
	end
	table.sort(missing)
	return missing
end

return table.freeze(AssetRegistry)
