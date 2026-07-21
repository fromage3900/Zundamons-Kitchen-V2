--!strict
-- MarketplaceConfig: single DevProduct catalog (replace placeholder IDs before public launch).
-- Used by RobuxStoreServer, CompanionShopServer, and StoreScript.client.

local MarketplaceConfig = {}

-- Server receipt catalog: [productId] = { type, key, name }
MarketplaceConfig.products = {
	[1111111101] = { type = "companion", key = "zundacat", name = "ZundaCat Companion" },
	[1111111102] = { type = "companion", key = "zundabunny", name = "ZundaBunny Companion" },
	[1111111103] = { type = "companion", key = "tantanmon", name = "TantanMon Companion" },
	[1111111104] = { type = "recipe", key = "Premium Ramen", name = "Premium Ramen Recipe" },
	[1111111105] = { type = "recipe", key = "Party Cake", name = "Party Cake Recipe" },
	[1111111106] = { type = "recipe", key = "Truffle Soup", name = "Truffle Soup Recipe" },
	[1111111107] = { type = "accessory", key = "crown", name = "Gold Crown" },
	[1111111108] = { type = "accessory", key = "bow", name = "Pink Bow" },
	[1111111109] = { type = "accessory", key = "chefhat", name = "Chef Hat" },
}

-- Premium companions in CompanionShop (0 = not configured yet)
MarketplaceConfig.companionDevProductIds = {
	ankomon = 0,
	cardamon = 0,
	antimon = 0,
	sakuradamon = 0,
	zundacat = 1111111101,
	zundabunny = 1111111102,
	tantanmon = 1111111103,
}

-- Client StoreScript display (derived from products; edit copy here)
MarketplaceConfig.storeDisplay = {
	companions = {
		{ id = 1111111101, name = "ZundaCat", emoji = "🐱", desc = "A playful feline companion", robux = 80, key = "zundacat" },
		{ id = 1111111102, name = "ZundaBunny", emoji = "🐰", desc = "Fluffy bunny bestie", robux = 80, key = "zundabunny" },
		{ id = 1111111103, name = "TantanMon", emoji = "🌶️", desc = "Spicy & spirited companion", robux = 100, key = "tantanmon" },
	},
	recipes = {
		{ id = 1111111104, name = "Premium Ramen", emoji = "🍜", desc = "Exclusive ramen recipe", robux = 60 },
		{ id = 1111111105, name = "Party Cake", emoji = "🎂", desc = "Fancy celebration cake", robux = 60 },
		{ id = 1111111106, name = "Truffle Soup", emoji = "🍲", desc = "Ultra-rare truffle recipe", robux = 80 },
	},
	accessories = {
		{ id = 1111111107, name = "Gold Crown", emoji = "👑", desc = "Wear royalty on your head", robux = 40 },
		{ id = 1111111108, name = "Pink Bow", emoji = "🎀", desc = "Cute bow accessory", robux = 40 },
		{ id = 1111111109, name = "Chef Hat", emoji = "🍽️", desc = "Professional chef headwear", robux = 50 },
	},
}

function MarketplaceConfig.isValidProductId(productId: number): boolean
	return MarketplaceConfig.products[productId] ~= nil
end

function MarketplaceConfig.getProduct(productId: number)
	return MarketplaceConfig.products[productId]
end

return MarketplaceConfig
