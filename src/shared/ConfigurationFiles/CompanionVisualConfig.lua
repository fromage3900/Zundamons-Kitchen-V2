--!strict
-- Git-backed companion visual defaults. Studio-owned entries under
-- ServerStorage.CompanionVisualCatalog override these without script edits.

local CompanionVisualConfig = {}

CompanionVisualConfig.defaultAssetId = "rbxassetid://84382956251208"
CompanionVisualConfig.defaultPrefab = "zundapalupdate4"

CompanionVisualConfig.visuals = {
	zundapal    = { modelAssetId = "rbxassetid://84382956251208",  basePrefab = "zundapalupdate4" },
	dog         = { modelAssetId = "rbxassetid://123070508686616", basePrefab = "dog" },
	parrot      = { modelAssetId = "rbxassetid://84382956251208",  basePrefab = "parrot" },
	cat         = { modelAssetId = "rbxassetid://131662379743903", basePrefab = "cat" },
	zundamon    = { modelAssetId = "rbxassetid://121481310719137", basePrefab = "zundapalupdate4" },
	zundacat    = { modelAssetId = "rbxassetid://101663144452966", basePrefab = "zundapalupdate4" },
	zundabunny  = { modelAssetId = "rbxassetid://76425192775041",  basePrefab = "zundapalupdate4" },
	tantanmon   = { modelAssetId = "rbxassetid://107150527246774", basePrefab = "zundapalupdate4" },
	ankomon     = { modelAssetId = "rbxassetid://110290651922538", basePrefab = "zundapalupdate4" },
	cardamon    = { modelAssetId = "rbxassetid://91041813069462",  basePrefab = "zundapalupdate4" },
	antimon     = { modelAssetId = "rbxassetid://94125444857929",  basePrefab = "zundapalupdate4" },
	sakuradamon = { modelAssetId = "rbxassetid://128478553136178", basePrefab = "zundapalupdate4" },
}

function CompanionVisualConfig.get(companionKey: string): any
	return CompanionVisualConfig.visuals[companionKey]
		or { modelAssetId = CompanionVisualConfig.defaultAssetId, basePrefab = CompanionVisualConfig.defaultPrefab }
end

return table.freeze(CompanionVisualConfig)
