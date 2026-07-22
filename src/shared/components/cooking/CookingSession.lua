local Matter = require(game.ReplicatedStorage.Packages.Matter)

local CookingSession = Matter.component("CookingSession")

--[[
	Data Structure:
	{
		sessionId = string,
		playerId = number,
		recipeId = string,
		startTime = number,
		firstTargetAt = number,
		noteInterval = number,
		totalNotes = number,
		nextExpected = number,
		perfectHits = number,
		greatHits = number,
		okHits = number,
		misses = number,
		settled = boolean,
		perfectWindow = number, -- custom per-player (companion buff), defaults to BASE_PERFECT_WINDOW
	}
]]

return CookingSession
