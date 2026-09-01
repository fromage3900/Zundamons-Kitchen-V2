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

	-- ── Depth progression (2026-08-25) ─────────────────────────────────
	-- Long-term loop: depth = min(zundarooms_escapes, maxDepth). Each level
	-- adds corridor segments and entity speed, and scales escape rewards.
	-- Depth 0 is exactly the pre-depth encounter (backward compatible).
	maxDepth = 8,
	depthSegmentsPerLevel = 1,
	depthEntitySpeedPerLevel = 0.8,
	-- Extra time granted per extra segment (the corridor got longer).
	depthTimeoutPerSegment = 14,
	depthGoldPerLevel = 35,
	depthXPPerLevel = 12,

	-- ── Memory fragments ───────────────────────────────────────────────
	-- Lore collectibles spawned mid-corridor. Touching one speeds the entity
	-- up for the REST OF THE RUN ("it notices you") -- and fragments only
	-- persist if the player escapes with them. Caught/timeout = lost.
	fragmentsPerRun = 2,
	fragmentEntitySpeedBonus = 0.75,
	fragmentGold = 25,
	fragmentXP = 10,
	-- Full collectible set. Server prefers memories the player has not
	-- recovered yet; duplicates still pay gold/XP but add no new lore.
	memories = {
		{ id = "hum", text = "The humming is a recipe being repeated so it is not forgotten." },
		{ id = "menu", text = "A menu written in your handwriting. You have never seen these dishes." },
		{ id = "chair", text = "One chair at every table faces the wall instead." },
		{ id = "soup", text = "A bowl of soup, still warm. The order ticket is dated tomorrow." },
		{ id = "bell", text = "The kitchen bell rings twice. Nobody has ever rung it twice." },
		{ id = "apron", text = "An apron folded neatly on the floor. The name tag is scratched out." },
		{ id = "window", text = "A serving window that opens onto another serving window." },
		{ id = "recipe", text = "Step 7 just says: do not let it taste the dish before the guest does." },
		{ id = "guest", text = "A guest satisfaction survey, all tens. The signature is a long wet smear." },
		{ id = "edamame", text = "A single edamame pod, polished like a keepsake. It is warmer than your hand." },
		{ id = "clock", text = "The wall clock runs backward during service hours only." },
		{ id = "door", text = "A note pinned to the pale door: 'closing time is when it says it is.'" },
	},
}

return table.freeze(ZundaroomsConfig)
