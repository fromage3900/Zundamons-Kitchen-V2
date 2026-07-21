local Matter = require(game.ReplicatedStorage.Packages.Matter)

local ItemDrop = Matter.component("ItemDrop")

--[[
	Data Structure:
	{
		targetPlayerId = number,
		itemName = string,
		quantity = number,
	}
]]

return ItemDrop
