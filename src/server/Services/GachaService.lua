--!strict
-- [[ModuleScript] GachaService]]
-- Authoritative server-side gacha pull & pity service.
-- Handles Whim Gacha pulls, pity counters, and inventory rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigurationFiles = Shared:WaitForChild("ConfigurationFiles")
local GachaConfig = require(ConfigurationFiles:WaitForChild("GachaConfig"))

local GachaService = {}
local playerPityData: { [number]: { pulls: number, legendaryPity: number } } = {}

local function getPlayerData(player: Player)
	if not playerPityData[player.UserId] then
		playerPityData[player.UserId] = { pulls = 0, legendaryPity = 0 }
	end
	return playerPityData[player.UserId]
end

function GachaService.performPull(player: Player, bannerId: string): { success: boolean, item: any?, isPity: boolean }
	local data = getPlayerData(player)
	data.pulls += 1
	data.legendaryPity += 1

	local banner = GachaConfig.banners[1]
	for _, b in ipairs(GachaConfig.banners) do
		if b.id == bannerId then
			banner = b
			break
		end
	end

	local poolType = "rare"
	local isPity = false

	-- Check Pity
	if data.legendaryPity >= GachaConfig.pity.legendaryPityCount then
		poolType = "legendary"
		data.legendaryPity = 0
		isPity = true
	elseif data.pulls % GachaConfig.pity.epicPityCount == 0 then
		poolType = "epic"
		isPity = true
	else
		-- RNG Roll
		local roll = math.random(1, 100)
		if roll <= 5 then
			poolType = "legendary"
			data.legendaryPity = 0
		elseif roll <= 25 then
			poolType = "epic"
		else
			poolType = "rare"
		end
	end

	local items = banner.pool[poolType]
	local selectedItem = items[math.random(1, #items)]

	return {
		success = true,
		item = selectedItem,
		isPity = isPity,
	}
end

-- Cleanup on Player Leaving
Players.PlayerRemoving:Connect(function(player)
	playerPityData[player.UserId] = nil
end)

return GachaService
