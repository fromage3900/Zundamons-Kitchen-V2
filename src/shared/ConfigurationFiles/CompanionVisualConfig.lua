--!strict
-- Git-backed companion visual defaults. Studio-owned entries under
-- ServerStorage.CompanionVisualCatalog override these without script edits.

local CompanionVisualConfig = {}

CompanionVisualConfig.defaultAssetId = "rbxassetid://84382956251208"
CompanionVisualConfig.defaultPrefab = "zundapalupdate4"

CompanionVisualConfig.visuals = {
	zundamon    = { modelAssetId = "rbxassetid://121481310719137", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil, orientCorrection = CFrame.Angles(0, math.rad(180), 0) },
	zundapal    = { modelAssetId = "rbxassetid://121481310719137", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil, orientCorrection = CFrame.Angles(0, math.rad(180), 0) }, -- Backward compat alias
	dog         = { modelAssetId = "rbxassetid://123070508686616", basePrefab = "dog", idleAnimationId = nil, walkAnimationId = nil },
	parrot      = { modelAssetId = "rbxassetid://84382956251208",  basePrefab = "parrot", idleAnimationId = nil, walkAnimationId = nil },
	cat         = { modelAssetId = "rbxassetid://131662379743903", basePrefab = "cat", idleAnimationId = nil, walkAnimationId = nil },
	zundacat    = { modelAssetId = "rbxassetid://101663144452966", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	zundabunny  = { modelAssetId = "rbxassetid://76425192775041",  basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	tantanmon   = { modelAssetId = "rbxassetid://107150527246774", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	ankomon     = { modelAssetId = "rbxassetid://110290651922538", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	cardamon    = { modelAssetId = "rbxassetid://91041813069462",  basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	antimon     = { modelAssetId = "rbxassetid://94125444857929",  basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
	sakuradamon = { modelAssetId = "rbxassetid://128478553136178", basePrefab = "zundapalupdate4", idleAnimationId = nil, walkAnimationId = nil },
}

function CompanionVisualConfig.get(companionKey: string): any
	return CompanionVisualConfig.visuals[companionKey]
		or { modelAssetId = CompanionVisualConfig.defaultAssetId, basePrefab = CompanionVisualConfig.defaultPrefab }
end

return table.freeze(CompanionVisualConfig)
