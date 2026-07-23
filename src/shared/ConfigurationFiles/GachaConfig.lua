--!strict
-- [[ModuleScript] GachaConfig]]
-- Infinity Nikki style Whim/Fashion Gacha system for Zundamon's Kitchen V2.
-- Contains banners, rarity weights, pity system, and drop tables.

local GachaConfig = {}

-- Gacha Currencies
GachaConfig.currencies = {
	gems = { name = "Zunda Gems", emoji = "💎", robuxValue = 1 },
	tokens = { name = "Whim Tickets", emoji = "🎟️", earnedInGame = true },
}

-- Pity Rules
GachaConfig.pity = {
	epicPityCount = 10,     -- Guaranteed 4★ (Epic) or higher every 10 pulls
	legendaryPityCount = 50, -- Guaranteed 5★ (Legendary) every 50 pulls
}

-- Banners
GachaConfig.banners = {
	{
		id = "gourmet_spring_2026",
		name = "🌸 Whims of Spring Gourmet",
		type = "fashion",
		bannerImage = "rbxassetid://241685484",
		costPerPull = 100, -- Gems or Tickets
		featuredItems = { "Zundamon_MagicalGirlForm", "Royal_Gourmet_Crown", "Ankomon_GoldTrim" },
		pool = {
			legendary = {
				{ id = "Zundamon_MagicalGirlForm", type = "outfit", name = "Zunda Magical Girl Dress", icon = "👗✨" },
				{ id = "Royal_Gourmet_Crown", type = "accessory", name = "Royal Gourmet Crown", icon = "👑" },
				{ id = "AllCompanions_CosmicAura", type = "effect", name = "Cosmic Gourmet Aura", icon = "🌸" },
			},
			epic = {
				{ id = "Zundamon_ShinyCoat", type = "outfit", name = "Shiny Zunda Coat", icon = "🧥" },
				{ id = "Zundabunny_BlossomEars", type = "accessory", name = "Blossom Bunny Ears", icon = "🐰" },
				{ id = "Recipe_TruffleRamen", type = "recipe", name = "Golden Truffle Ramen", icon = "🍜" },
			},
			rare = {
				{ id = "Zundapal_PastelDress", type = "outfit", name = "Pastel Mint Apron", icon = "👗" },
				{ id = "Zundacat_RibbonTail", type = "accessory", name = "Ribbon Tail Brooch", icon = "🎀" },
				{ id = "ZundaGems_200", type = "currency", name = "200 Zunda Gems", icon = "💎" },
			},
		},
	},
}

return GachaConfig
