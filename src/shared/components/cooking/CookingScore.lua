local Matter = require(game.ReplicatedStorage.Packages.Matter)

local CookingScore = Matter.component("CookingScore")

--[[
	Data Structure:
	{
		notesHit = { [number] = string }, -- map of note index to quality
		perfectHits = number,
		greatHits = number,
		okHits = number,
		misses = number,
		totalNotes = number
	}
]]

return CookingScore
