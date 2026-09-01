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
		goodHits = number,
		okHits = number,
		misses = number,
		currentCombo = number,
		maxCombo = number,
		totalScore = number,
		chart = table?,
		windows = { perfect: number, great: number, good: number }?,
		hitRecords = { table }?,
		settled = boolean,
		perfectWindow = number?, -- custom per-player (companion buff)
		greatWindow = number?,
		okWindow = number?,
	}
]]

return CookingSession
