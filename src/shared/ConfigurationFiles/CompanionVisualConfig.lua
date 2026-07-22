--!strict
-- Git-backed companion visual defaults. Studio-owned entries under
-- ServerStorage.CompanionVisualCatalog override these without script edits.

local CompanionVisualConfig = {}

CompanionVisualConfig.defaultAssetId = "rbxassetid://103182526409237"

CompanionVisualConfig.visuals = {
	zundapal = { modelAssetId = "rbxassetid://71161704530283", basePrefab = "zundapal" },
	dog = { modelAssetId = "rbxassetid://123070508686616", basePrefab = "dog" },
	parrot = { modelAssetId = "rbxassetid://100814736457956", basePrefab = "parrot" },
	cat = { modelAssetId = "rbxassetid://131662379743903", basePrefab = "cat" },
	zundamon = { modelAssetId = "rbxassetid://121481310719137", basePrefab = "zundapal" },
	zundacat = { modelAssetId = "rbxassetid://101663144452966", basePrefab = "zundapal" },
	zundabunny = { modelAssetId = "rbxassetid://76425192775041", basePrefab = "zundapal" },
	tantanmon = { modelAssetId = "rbxassetid://107150527246774", basePrefab = "zundapal" },
	ankomon = { modelAssetId = "rbxassetid://110290651922538", basePrefab = "zundapal" },
	cardamon = { modelAssetId = "rbxassetid://91041813069462", basePrefab = "zundapal" },
	antimon = { modelAssetId = "rbxassetid://94125444857929", basePrefab = "zundapal" },
	sakuradamon = { modelAssetId = "rbxassetid://128478553136178", basePrefab = "zundapal" },
}

function CompanionVisualConfig.get(companionKey: string): any
	return CompanionVisualConfig.visuals[companionKey]
		or { modelAssetId = CompanionVisualConfig.defaultAssetId, basePrefab = "zundapal" }
end

return table.freeze(CompanionVisualConfig)
