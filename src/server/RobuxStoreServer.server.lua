-- [[Script] RobuxStoreServer]]
-- Wires MarketplaceService as the sole ProcessReceipt owner.
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local SSS = game:GetService("ServerScriptService")
local MarketplaceConfig = require(RS.ConfigurationFiles.MarketplaceConfig)

-- ── PRODUCT CATALOGUE ────────────────────────────────────────────────────────
-- Format: [productId] = { type, key, displayName }
-- type: "companion" | "recipe" | "accessory"
-- key:  stored as _G.data[playerName]["companion_owned_KEY"] = true
-- Notify client of purchase result
local RE = RS:WaitForChild("RemoteEvents")
local purchaseEv = RE:FindFirstChild("PurchaseResult")
if not purchaseEv then
	purchaseEv = Instance.new("RemoteEvent")
	purchaseEv.Name = "PurchaseResult"
	purchaseEv.Parent = RE
end

-- ProcessReceipt delegated to MarketplaceService.lua (unified handler)

-- Client requests a purchase prompt
local RF = RS:WaitForChild("RemoteFunctions")
local promptRF = RF:FindFirstChild("PromptRobuxPurchase")
if not promptRF then
	promptRF = Instance.new("RemoteFunction")
	promptRF.Name = "PromptRobuxPurchase"
	promptRF.Parent = RF
end

-- Wire prompt: client asks to purchase → server opens Roblox purchase dialog
promptRF.OnServerInvoke = function(player, productId)
	if
		not MarketplaceConfig.enabled
		or type(productId) ~= "number"
		or not MarketplaceConfig.isValidProductId(productId)
	then
		return false
	end
	MPS:PromptProductPurchase(player, productId)
	return true
end

print("[RobuxStoreServer] Ready")
