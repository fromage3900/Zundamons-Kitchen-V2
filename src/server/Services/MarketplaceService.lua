-- [[ModuleScript] MarketplaceService (ref: RBX-CONSOLIDATED-MARKETPLACE)]]
-- Single ProcessReceipt owner. All product purchases route through here.
-- CompanionShopServer and RobuxStoreServer delegate to this service.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.PlayerDataService)
local MarketplaceConfig = require(RS.ConfigurationFiles.MarketplaceConfig)
local RE = RS:WaitForChild("RemoteEvents")

local purchaseEv = RE:FindFirstChild("PurchaseResult")
if not purchaseEv then
	purchaseEv = Instance.new("RemoteEvent"); purchaseEv.Name = "PurchaseResult"; purchaseEv.Parent = RE
end

local CompanionOwnedSync = RE:FindFirstChild("CompanionOwnedSync")

local MarketplaceSvc = {}

function MarketplaceSvc.processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local prod = MarketplaceConfig.products[productId]
	if not prod then
		warn("[MarketplaceService] Unknown product: " .. productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local d = PlayerDataService.getOrCreate(player)

	if prod.type == "companion" then
		d["companion_owned_" .. prod.key] = true
		if CompanionOwnedSync then
			CompanionOwnedSync:FireClient(player, prod.key, true)
		end
	elseif prod.type == "recipe" then
		if not d.recipes_unlocked then d.recipes_unlocked = {} end
		d.recipes_unlocked[prod.key] = true
	elseif prod.type == "accessory" then
		d["accessory_" .. prod.key] = true
	end

	purchaseEv:FireClient(player, prod.name, prod.type)
	print("[MarketplaceService] " .. player.Name .. " purchased " .. prod.name)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MarketplaceSvc.init()
	MarketplaceService.ProcessReceipt = MarketplaceSvc.processReceipt
	print("[MarketplaceService] ProcessReceipt initialized")
end

MarketplaceSvc.init()

return MarketplaceSvc
