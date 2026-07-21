-- [[Script] RobuxStoreServer]]
-- Wires MarketplaceService as the sole ProcessReceipt owner.
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")
local MarketplaceService = require(script.Parent.Services.MarketplaceService)

-- ── PRODUCT CATALOGUE ────────────────────────────────────────────────────────
-- Format: [productId] = { type, key, displayName }
-- type: "companion" | "recipe" | "accessory"
-- key:  stored as _G.data[playerName]["companion_owned_KEY"] = true
local PRODUCTS = {
    -- COMPANIONS  (replace IDs!)
    [1111111101] = { type="companion",  key="zundacat",     name="ZundaCat Companion"  },
    [1111111102] = { type="companion",  key="zundabunny",   name="ZundaBunny Companion"},
    [1111111103] = { type="companion",  key="tantanmon",    name="TantanMon Companion" },
    -- PREMIUM RECIPES
    [1111111104] = { type="recipe",     key="Premium Ramen",name="Premium Ramen Recipe"},
    [1111111105] = { type="recipe",     key="Party Cake",   name="Party Cake Recipe"   },
    [1111111106] = { type="recipe",     key="Truffle Soup", name="Truffle Soup Recipe" },
    -- ACCESSORIES (cosmetic flags)
    [1111111107] = { type="accessory",  key="crown",        name="Gold Crown"          },
    [1111111108] = { type="accessory",  key="bow",          name="Pink Bow"            },
    [1111111109] = { type="accessory",  key="chefhat",      name="Chef Hat"            },
}

-- Notify client of purchase result
local RE      = RS:WaitForChild("RemoteEvents")
local purchaseEv = RE:FindFirstChild("PurchaseResult")
if not purchaseEv then
    purchaseEv = Instance.new("RemoteEvent"); purchaseEv.Name="PurchaseResult"; purchaseEv.Parent=RE
end

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

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
	if not PRODUCTS[productId] then return false end
	MPS:PromptProductPurchase(player, productId)
	return true
end

print("[RobuxStoreServer] Ready — "..#(function() local t={} for k in pairs(PRODUCTS) do t[#t+1]=k end return t end()).." products")
