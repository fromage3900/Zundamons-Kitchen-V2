-- [[Script] PlayerLeaving (ref: RBX5EFF58E6EFFA4AABB05BF684AB3E4CD2)]]
local Players = game.Players
local RS = game.ReplicatedStorage
local loot_module = require(RS.ConfigurationFiles.LootModule)

Players.PlayerRemoving:Connect(function(player)
	loot_module.eraseData(player)
end)