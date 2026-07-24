--!strict
local ZundaroomsConfig = {
	unlockGuestsServed = 1,
	-- Keep runtime rooms above Workspace.FallenPartsDestroyHeight (commonly -500).
	roomY = 1000,
	roomWidth = 26,
	-- Length of ONE corridor segment. The full run is segmentCount * roomLength.
	roomLength = 110,
	-- Liminal-space expansion (2026-07-24): the encounter used to be a single
	-- short room. Chained segments make it a proper corridor -- the repetition
	-- itself is the point (classic "Backrooms" liminal-space read), rather than
	-- hand-authoring a long unique layout.
	segmentCount = 6,
	-- If present, ServerStorage.AssetLibrary.Zundarooms.RoomSegment (a Model)
	-- is cloned per segment instead of the procedural box -- same prefab-first
	-- convention as AssetLibrary.Companions / AssetLibrary.ResourceNodes.
	-- Falls back to the procedural segment when absent (never blocks play).
	entitySpeed = 10,
	-- Prefer a Studio-authored Model named ZundaroomsEntity in ServerStorage or
	-- ReplicatedStorage.Models. Set this only after uploading under the game owner.
	entityModelAssetId = "",
	entityVisualScale = 1,
	entityVisualOffset = CFrame.identity,
	catchDistance = 4,
	-- Longer corridor needs more time to traverse than the old single-room 45s.
	sessionTimeout = 90,
	escapeGold = 100,
	escapeXP = 40,
	-- Liminal lighting: sparse flickering fixtures instead of even room light.
	fixtureSpacing = 22,
	fixtureFlickerMin = 0.35,
	fixtureFlickerMax = 1.0,
}

return table.freeze(ZundaroomsConfig)
