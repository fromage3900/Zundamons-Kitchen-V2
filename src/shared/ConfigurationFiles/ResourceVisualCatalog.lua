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

-- These legacy IDs are retained for identification and migration, but are
-- disabled because live ContentProvider checks returned AssetFetchStatus.Failure.
-- The authoring plugin enables verified, experience-owned replacements through
-- per-node attributes or the Studio catalog.
register("Variant1", "rbxassetid://82622166538467", "Mesh", false)
register("Variant2", "rbxassetid://80371673720142", "Mesh", false)
register("Rock_Common", "rbxassetid://74975285002856", "Mesh", false)
register("Rock_Rare", "rbxassetid://138139954211772", "Mesh", false)
register("GoldOre_Default", "rbxassetid://105153259339546", "Mesh", false)
register("Wheat_01", "rbxassetid://120483243502197", "Mesh", false)
register("Wheat_02", "rbxassetid://124905165003062", "Mesh", false)
register("Wheat_03", "rbxassetid://127847933091778", "Mesh", false)
register("ZundaFlower_Default", "rbxassetid://130899236683010", "Mesh", false)
register("ZundaFlower_Rare", "rbxassetid://86582218951352", "Mesh", false)
register("ZundaPea_01", "rbxassetid://106482523402868", "Mesh", false)
register("ZundaPea_02", "rbxassetid://119452475051045", "Mesh", false)
register("ZundaPea_03", "rbxassetid://107116519758062", "Mesh", false)
register("Mushroom_01", "rbxassetid://96331224587968", "Mesh", false)
register("Mushroom_02", "rbxassetid://85124051974569", "Mesh", false)
register("BerryBush_01", "rbxassetid://91224321091798", "Mesh", false)
register("BerryBush_02", "rbxassetid://74222048987638", "Mesh", false)
register("BerryBush_03", "rbxassetid://76322051780722", "Mesh", false)
register("Root_01", "rbxassetid://106581238862764", "Mesh", false)
register("Root_02", "rbxassetid://122644985457254", "Mesh", false)
register("Seed", "rbxassetid://132798405534424", "Mesh", false)
register("SeedLeaf", "rbxassetid://110157288415078", "Mesh", false)
register("Leaf", "rbxassetid://118786859560292", "Mesh", false)
register("Mature", "rbxassetid://85258154641863", "Mesh", false)
register("EdamamePod_Default", "rbxassetid://106482523402868", "Mesh", false)
register("ZundaLeaf_Default", "rbxassetid://118786859560292", "Mesh", false)
register("SweetPea_Default", "rbxassetid://107116519758062", "Mesh", false)
register("PeaFlower_Default", "rbxassetid://130899236683010", "Mesh", false)
register("SaltedPeaBouquet_Default", "rbxassetid://86582218951352", "Mesh", false)

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
