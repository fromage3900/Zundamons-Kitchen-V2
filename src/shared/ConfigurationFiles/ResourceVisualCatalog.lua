--!strict
-- Canonical, Git-backed defaults for resource visuals. Studio-authored node
-- attributes may override these values without changing gameplay scripts.

export type AssetType = "Mesh" | "Model" | "Prefab" | "Fallback"
export type Descriptor = {
	variant: string,
	assetId: string,
	assetType: AssetType,
	scale: Vector3,
	offset: CFrame,
	enabled: boolean,
	attribution: string?,
}

local Catalog = {}

local variants: { [string]: Descriptor } = {}

local function register(variant: string, assetId: string, assetType: AssetType?, enabled: boolean?): Descriptor
	local descriptor: Descriptor = table.freeze({
		variant = variant,
		assetId = assetId,
		assetType = assetType or "Mesh",
		scale = Vector3.new(1, 1, 1),
		offset = CFrame.identity,
		enabled = enabled == true,
	})
	variants[variant] = descriptor
	return descriptor
end

-- IDs were previously registered as wrapper-Model asset IDs, which failed
-- ContentProvider:PreloadAsync as SpecialMesh targets (AssetFetchStatus.Failure).
-- Verified live 2026-08-12 in Studio: LoadAsset unwraps each wrapper to a real
-- MeshPart whose MeshId *does* resolve; entries below now point at those
-- verified inner mesh IDs. Seed/SeedLeaf/Leaf/Mature/ZundaLeaf_Default passed
-- directly and are unchanged.
register("Variant1", "rbxassetid://125552534191638", "Mesh", true)
register("Variant2", "rbxassetid://110321726780139", "Mesh", true)
register("Rock_Common", "rbxassetid://81332711510127", "Mesh", true)
register("Rock_Rare", "rbxassetid://81332711510127", "Mesh", true)
register("GoldOre_Default", "rbxassetid://81332711510127", "Mesh", true)
register("Wheat_01", "rbxassetid://72200439315451", "Mesh", true)
register("Wheat_02", "rbxassetid://72200439315451", "Mesh", true)
register("Wheat_03", "rbxassetid://72200439315451", "Mesh", true)
register("ZundaFlower_Default", "rbxassetid://72200439315451", "Mesh", true)
register("ZundaFlower_Rare", "rbxassetid://72200439315451", "Mesh", true)
register("ZundaPea_01", "rbxassetid://75167715290828", "Mesh", true)
register("ZundaPea_02", "rbxassetid://75167715290828", "Mesh", true)
register("ZundaPea_03", "rbxassetid://75167715290828", "Mesh", true)
register("Mushroom_01", "rbxassetid://95390217986219", "Mesh", true)
register("Mushroom_02", "rbxassetid://95390217986219", "Mesh", true)
register("BerryBush_01", "rbxassetid://139306345319488", "Mesh", true)
register("BerryBush_02", "rbxassetid://139306345319488", "Mesh", true)
register("BerryBush_03", "rbxassetid://139306345319488", "Mesh", true)
register("Root_01", "rbxassetid://73466898093060", "Mesh", true)
register("Root_02", "rbxassetid://73466898093060", "Mesh", true)
register("Seed", "rbxassetid://132798405534424", "Mesh", true)
register("SeedLeaf", "rbxassetid://110157288415078", "Mesh", true)
register("Leaf", "rbxassetid://118786859560292", "Mesh", true)
register("Mature", "rbxassetid://85258154641863", "Mesh", true)
register("EdamamePod_Default", "rbxassetid://75167715290828", "Mesh", true)
register("ZundaLeaf_Default", "rbxassetid://118786859560292", "Mesh", true)
register("SweetPea_Default", "rbxassetid://75167715290828", "Mesh", true)
register("PeaFlower_Default", "rbxassetid://72200439315451", "Mesh", true)
register("SaltedPeaBouquet_Default", "rbxassetid://72200439315451", "Mesh", true)

local defaultsByArchetype: { [string]: string } = {
	AppleTree = "Variant1",
	PineTree = "Variant2",
	Rock = "Rock_Common",
	MarbleRock = "Rock_Rare",
	GoldRock = "GoldOre_Default",
	Wheat = "Wheat_01",
	ZundaFlower = "ZundaFlower_Default",
	ZundaPea = "ZundaPea_01",
	ZundaMushroom = "Mushroom_01",
	["Zunda Mushroom"] = "Mushroom_01",
	ZundaBerry = "BerryBush_01",
	["Zunda Berry"] = "BerryBush_01",
	ZundaRoot = "Root_01",
	["Zunda Root"] = "Root_01",
	CarrotPlot = "Mature",
	EdamamePod = "EdamamePod_Default",
	ZundaLeaf = "ZundaLeaf_Default",
	SweetPea = "SweetPea_Default",
	PeaFlower = "PeaFlower_Default",
	SaltedPeaBouquet = "SaltedPeaBouquet_Default",
}

function Catalog.normalizeAssetId(value: any): string
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(math.floor(value))
	end
	if type(value) ~= "string" then
		return ""
	end
	local numeric = string.match(value, "%d+")
	return if numeric then "rbxassetid://" .. numeric else ""
end

function Catalog.get(variantId: string?): Descriptor?
	return if variantId then variants[variantId] else nil
end

function Catalog.getDefaultVariant(archetypeId: string): string?
	return defaultsByArchetype[archetypeId]
end

function Catalog.getForArchetype(archetypeId: string, variantId: string?): Descriptor?
	return Catalog.get(variantId or defaultsByArchetype[archetypeId])
end

function Catalog.getVariantIds(): { string }
	local result = {}
	for variant in variants do
		table.insert(result, variant)
	end
	table.sort(result)
	return result
end

function Catalog.getAll(): { [string]: Descriptor }
	return table.clone(variants)
end

return table.freeze(Catalog)
