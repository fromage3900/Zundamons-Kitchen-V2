--!strict
-- MarketplaceConfig: single DevProduct catalog (replace placeholder IDs before public launch).
-- Used by RobuxStoreServer, CompanionShopServer, and StoreScript.client.

local MarketplaceConfig = {}

-- Fail closed until placeholders are replaced and receipts are verified in a
-- private published experience.
MarketplaceConfig.enabled = false

-- Server receipt catalog: [productId] = { type, key, name }
MarketplaceConfig.products = {
	[1111111101] = { type = "companion", key = "cardamon", name = "Cardamon Companion" },
	[1111111102] = { type = "companion", key = "antimon", name = "Antimon Companion" },
	[1111111103] = { type = "companion", key = "sakuradamon", name = "Sakuradamon Companion" },
	[1111111104] = { type = "companion", key = "tantanmon", name = "Tantanmon Companion" },
	[1111111105] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" },
	[1111111106] = { type = "recipe", key = "Party Cake", name = "Party Cake Recipe" },
	[1111111107] = { type = "recipe", key = "Truffle Soup", name = "Truffle Soup Recipe" },
	[1111111108] = { type = "accessory", key = "crown", name = "Gold Crown" },
	[1111111109] = { type = "accessory", key = "bow", name = "Pink Bow" },
	[1111111110] = { type = "accessory", key = "chefhat", name = "Chef Hat" },
}

-- Premium companions in CompanionShop (0 = not configured yet)
MarketplaceConfig.companionDevProductIds = {
	cardamon = 1111111101,
	antimon = 1111111102,
	sakuradamon = 1111111103,
	tantanmon = 1111111104,
}

-- Client StoreScript display (derived from products; edit copy here)
MarketplaceConfig.storeDisplay = {
	companions = {
		{ id = 1111111101, name = "Cardamon", emoji = "🍋", desc = "+30% wider perfect cooking window", robux = 1000, key = "cardamon" },
		{ id = 1111111102, name = "Antimon", emoji = "🌿", desc = "+20% extra gather drop chance", robux = 1000, key = "antimon" },
		{ id = 1111111103, name = "Sakuradamon", emoji = "🌸", desc = "+25% XP bonus from cooking & serving", robux = 1000, key = "sakuradamon" },
		{ id = 1111111104, name = "Tantanmon", emoji = "🌶️", desc = "+20% speed & spicy burst", robux = 1000, key = "tantanmon" },
	},
	recipes = {
		{ id = 1111111105, name = "Premium Ramen", emoji = "🍜", desc = "Exclusive ramen recipe", robux = 60 },
		{ id = 1111111106, name = "Party Cake", emoji = "🎂", desc = "Fancy celebration cake", robux = 60 },
		{ id = 1111111107, name = "Truffle Soup", emoji = "🍲", desc = "Ultra-rare truffle recipe", robux = 80 },
	},
	accessories = {
		{ id = 1111111108, name = "Gold Crown", emoji = "👑", desc = "Wear royalty on your head", robux = 40 },
		{ id = 1111111109, name = "Pink Bow", emoji = "🎀", desc = "Cute bow accessory", robux = 40 },
		{ id = 1111111110, name = "Chef Hat", emoji = "🍽️", desc = "Professional chef headwear", robux = 50 },
	},
}

function MarketplaceConfig.isValidProductId(productId: number): boolean
	return MarketplaceConfig.products[productId] ~= nil
end

function MarketplaceConfig.getProduct(productId: number)
	return MarketplaceConfig.products[productId]
end

return MarketplaceConfig
