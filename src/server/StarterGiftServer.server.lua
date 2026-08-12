local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local STARTER_KIT = {
	gold_bonus = 50,
	items = {
		Apple = 10,
		Wheat = 10,
	},
}

local function giveStarterKit(player)
	local ok = PlayerDataService.mutate(player, "starter_gift", function(data)
		if data.starter_kit_claimed then
			return false
		end
		data.starter_kit_claimed = true
		data.gold = (data.gold or 0) + STARTER_KIT.gold_bonus
		for item, amount in pairs(STARTER_KIT.items) do
			data[item] = (data[item] or 0) + amount
		end
		return true
	end)
	if ok then
		print(string.format("[StarterGiftServer] Starter kit granted to %s", player.Name))
	end
end

local function onPlayerJoined(player)
	local data = PlayerDataService.get(player)
	if not data then
		local loaded = PlayerDataService.getOrCreate(player)
		task.wait(2)
		giveStarterKit(player)
	else
		giveStarterKit(player)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerJoined(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerJoined)
