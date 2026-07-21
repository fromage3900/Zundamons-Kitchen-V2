local Matter = require(game.ReplicatedStorage.Packages.Matter)

local BuffProvider = Matter.component("BuffProvider")
--[[
	Data Structure:
	{
		buffType = string, -- e.g., "CookingSpeed", "GoldMultiplier"
		value = number,    -- e.g., 0.10 for +10%
	}
]]
return BuffProvider
