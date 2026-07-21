local Matter = require(game.ReplicatedStorage.Packages.Matter)

local CookingSession = Matter.component("CookingSession")

--[[
	Data Structure:
	{
		playerId = number,
		recipeId = string,
		startTime = number,
		duration = number,
	}
]]

return CookingSession
