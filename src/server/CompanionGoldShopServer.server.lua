-- [[Script] CompanionGoldShopServer]]
-- Server endpoint for purchasing gold shop companions
local RS = game:GetService("ReplicatedStorage")
local RF = RS:WaitForChild("RemoteFunctions")
local RE = RS:WaitForChild("RemoteEvents")

local NPCConfig = require(RS.Shared.Config.NPCConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

-- RemoteFunction for gold shop purchases
local purchaseGoldCompanion = RF:FindFirstChild("PurchaseGoldCompanion")
if not purchaseGoldCompanion then
	purchaseGoldCompanion = Instance.new("RemoteFunction")
	purchaseGoldCompanion.Name = "PurchaseGoldCompanion"
	purchaseGoldCompanion.Parent = RF
end

-- Notify client of purchase result
local companionBoughtEvent = RE:FindFirstChild("CompanionBought")
if not companionBoughtEvent then
	companionBoughtEvent = Instance.new("RemoteEvent")
	companionBoughtEvent.Name = "CompanionBought"
	companionBoughtEvent.Parent = RE
end

purchaseGoldCompanion.OnServerInvoke = function(player, companionName)
	if typeof(companionName) ~= "string" then
		return false, "Invalid companion name"
	end

	local companion = NPCConfig.getGoldCompanion(companionName)
	if not companion then
		return false, "Companion not found"
	end

	local data = PlayerDataService.getOrCreate(player)

	-- Check level requirement
	if companion.levelRequired and (data.chef and data.chef.level or 1) < companion.levelRequired then
		return false, "Level " .. companion.levelRequired .. " required"
	end

	-- Check gold balance
	if (data.gold or 0) < companion.price then
		return false, "Not enough gold"
	end

	-- Check if already owned
	if data["companion_owned_" .. companionName] then
		return false, "Already owned"
	end

	-- Purchase the companion
	data.gold = data.gold - companion.price
	data["companion_owned_" .. companionName] = true
	data.active_companion = companionName

	companionBoughtEvent:FireClient(player, companionName, true)
	print("[CompanionGoldShop] " .. player.Name .. " purchased " .. companionName)

	return true, "Purchased!"
end

print("[CompanionGoldShopServer] Ready")