--!strict
local ZundaroomsConfig = {
	unlockGuestsServed = 1,
	-- Keep runtime rooms above Workspace.FallenPartsDestroyHeight (commonly -500).
	roomY = 1000,
	roomWidth = 26,
	roomLength = 110,
	entitySpeed = 10,
	catchDistance = 4,
	sessionTimeout = 45,
	escapeGold = 100,
	escapeXP = 40,
}

return table.freeze(ZundaroomsConfig)
