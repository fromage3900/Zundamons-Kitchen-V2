--!strict
local ZundaroomsConfig = {
	unlockGuestsServed = 1,
	-- Keep runtime rooms above Workspace.FallenPartsDestroyHeight (commonly -500).
	roomY = 1000,
	roomWidth = 26,
	roomLength = 110,
	entitySpeed = 10,
	-- Prefer a Studio-authored Model named ZundaroomsEntity in ServerStorage or
	-- ReplicatedStorage.Models. Set this only after uploading under the game owner.
	entityModelAssetId = "",
	entityVisualScale = 1,
	entityVisualOffset = CFrame.identity,
	catchDistance = 4,
	sessionTimeout = 45,
	escapeGold = 100,
	escapeXP = 40,
}

return table.freeze(ZundaroomsConfig)
