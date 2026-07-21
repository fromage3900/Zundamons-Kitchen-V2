local Matter = require(game.ReplicatedStorage.Packages.Matter)

local FishingSession = Matter.component("FishingSession")

--[[
	Data Structure:
	{
		playerId = number,
		fishName = string,
		fishRarity = number,
		fishValue = number,
		fishXp = number,
		fishColor = Color3,
		difficulty = {
			tugMag = number,
			dodgeChance = number,
			duration = number,
			hookWindow = number,
		},
		startTime = number,
		lastTugTime = number,
		tension = number,
		progress = number,
		reeling = boolean,
		finished = boolean,
	}
]]

return FishingSession