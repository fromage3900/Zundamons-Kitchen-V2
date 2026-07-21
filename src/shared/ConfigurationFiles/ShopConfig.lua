-- [[ModuleScript] ShopConfig (ref: RBXA852983FFBD54415A2B7E1307FF7CBD7)]]
-- ShopConfig: All purchasable items across every shop in Zundymon's Kitchen
-- To add a new item: add an entry to the correct category table.
-- Fields: id, name, price (Gold), description, assetId (shirt/pants/accessory ID or model name)

local ShopConfig = {}

-- ============================================================
-- CLOTHING STORE items
-- assetId = Roblox shirt/pants asset ID string, or 0 for placeholder
-- type = "Shirt" | "Pants" | "Accessory"
-- ============================================================
ShopConfig.clothing = {
    {
        id          = "chef_apron",
        name        = "Chef's Apron",
        description = "A classic white apron for the dedicated cook!",
        type        = "Shirt",
        assetId     = 0,  -- replace with real Roblox asset ID
        price       = 50,
        tier        = 1,  -- unlocked from start
        icon        = "🧑‍🍳",
    },
    {
        id          = "chef_hat",
        name        = "Tall Chef Hat",
        description = "Stand tall in the kitchen!",
        type        = "Accessory",
        assetId     = 0,
        price       = 30,
        tier        = 1,
        icon        = "👨‍🍳",
    },
    {
        id          = "royal_outfit",
        name        = "Royal Chef Outfit",
        description = "Unlocked at Royal Chef tier. Gold trim, très chic!",
        type        = "Shirt",
        assetId     = 0,
        price       = 150,
        tier        = 2,  -- requires Royal Chef (5 guests)
        icon        = "👑",
    },
    {
        id          = "zundamon_dress",
        name        = "Zundamon Dress",
        description = "A green and white dress inspired by Zundamon herself!",
        type        = "Shirt",
        assetId     = 0,
        price       = 200,
        tier        = 2,
        icon        = "🌿",
    },
    {
        id          = "master_robe",
        name        = "Master Chef Robe",
        description = "Wear the mark of a Master Chef.",
        type        = "Shirt",
        assetId     = 0,
        price       = 400,
        tier        = 3,  -- requires Master Chef (20 guests)
        icon        = "⭐",
    },
    {
        id          = "legend_crown",
        name        = "Legend's Crown",
        description = "Only Legends wear this. Serve 50 guests to unlock!",
        type        = "Accessory",
        assetId     = 0,
        price       = 1000,
        tier        = 4,  -- requires Legend (50 guests)
        icon        = "🏆",
    },
}

-- ============================================================
-- KITCHEN EQUIPMENT items (decorations for the kitchen/serving area)
-- modelName = name of model in ServerStorage.ShopModels.Kitchen
-- ============================================================
ShopConfig.kitchen_equipment = {
    {
        id          = "fancy_oven",
        name        = "Fancy Oven",
        description = "A beautiful pink oven for the kitchen!",
        modelName   = "FancyOven",
        price       = 100,
        tier        = 1,
        icon        = "🔥",
    },
    {
        id          = "flower_vase",
        name        = "Flower Vase",
        description = "A pink vase for the counter.",
        modelName   = "FlowerVase",
        price       = 25,
        tier        = 1,
        icon        = "💐",
    },
    {
        id          = "chalkboard_menu",
        name        = "Chalkboard Menu",
        description = "Show off your recipes on a chalkboard!",
        modelName   = "ChalkboardMenu",
        price       = 60,
        tier        = 2,
        icon        = "📋",
    },
}

return ShopConfig
