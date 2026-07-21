--!strict
-- [[ModuleScript] MeshAssets]
-- Integrated harvest node meshes from HarvestNodeVariants.lua
-- See CREDITS.md for full attribution

local MeshAssets = {}

MeshAssets.meshes = {
	-- Harvest Nodes - Zunda Forest & Kitchen Garden
	-- Using asset 74045703734999 (carrot plot with growth stages)
	CarrotPlot = {
		["Seed"] = "rbxassetid://132798405534424",
		["SeedLeaf1"] = "rbxassetid://110157288415078",
		["SeedLeaf2"] = "rbxassetid://110157288415078",
		["SeedPack"] = "rbxassetid://94366688581103",
		["Leaf"] = "rbxassetid://118786859560292",
		["Mature"] = "rbxassetid://85258154641863",
		["Processed"] = "rbxassetid://86749155295155",
	},
	ZundaFlower = {
		["ZundaFlower_Default"] = "rbxassetid://130899236683010",
		["ZundaFlower_Rare"] = "rbxassetid://86582218951352",
	},
	ZundaPea = {
		["ZundaPea_01"] = "rbxassetid://106482523402868",
		["ZundaPea_02"] = "rbxassetid://119452475051045",
		["ZundaPea_03"] = "rbxassetid://107116519758062",
	},
	["Zunda Mushroom"] = {
		["Mushroom_01"] = "rbxassetid://96331224587968",
		["Mushroom_02"] = "rbxassetid://85124051974569",
	},
	["Zunda Berry"] = {
		["BerryBush_01"] = "rbxassetid://91224321091798",
		["BerryBush_02"] = "rbxassetid://74222048987638",
		["BerryBush_03"] = "rbxassetid://76322051780722",
	},
	["Zunda Root"] = {
		["Root_01"] = "rbxassetid://106581238862764",
		["Root_02"] = "rbxassetid://122644985457254",
	},
	Wheat = {
		["Wheat_01"] = "rbxassetid://120483243502197",
		["Wheat_02"] = "rbxassetid://124905165003062",
		["Wheat_03"] = "rbxassetid://127847933091778",
	},
	Rock = {
		["Rock_Common"] = "rbxassetid://74975285002856",
		["Rock_Rare"] = "rbxassetid://138139954211772",
	},
	["Gold Ore"] = {
		["GoldOre_Default"] = "rbxassetid://105153259339546",
	},

	-- Environment Props
	["Bush"] = {
		["bush"] = "rbxassetid://71267543570887",
	},
	["Lantern"] = {
		["Lantern"] = "rbxassetid://9854046603",
	},
	["Neon"] = {
		["neon heart"] = "rbxassetid://601198887",
	},
	-- User-provided assets
	["Mushroom"] = {
		["Default"] = "rbxassetid://96844649112031",
	},
	["Tree"] = {
		["Variant1"] = "rbxassetid://82622166538467",
		["Variant2"] = "rbxassetid://80371673720142",
	},
	["Bee"] = {
		["Default"] = "rbxassetid://91701180154526",
	},
}

-- Helper: get mesh ID with fallback
function MeshAssets.getMeshId(nodeType: string, variantId: string?): string
	local config = MeshAssets.meshes[nodeType]
	if not config then
		return ""
	end
	if variantId and config[variantId] then
		return config[variantId]
	end
	-- Return first available mesh
	for _, id in pairs(config) do
		return id
	end
	return ""
end

-- Keep backward compatibility with HarvestNodeVariants access patterns
MeshAssets.getMesh = MeshAssets.getMeshId
MeshAssets.getVariantIds = function(nodeType: string): { string }
	local config = MeshAssets.meshes[nodeType]
	if not config then return {} end
	local ids: { string } = {}
	for id, _ in pairs(config) do
		table.insert(ids, id)
	end
	return ids
end

return MeshAssets