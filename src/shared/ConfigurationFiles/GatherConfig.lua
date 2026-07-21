--!strict
-- GatherConfig: canonical click-gather definitions (ResourceType nodes).
-- Tool-based mining (rocks, trees) lives in MineableConfig + Tools.server.

export type ClickResource = {
	itemName: string,
	defaultYield: number,
	respawnSeconds: number,
	notifyEmoji: string,
}

local GatherConfig = {}

-- ResourceType attribute on BasePart + ClickDetector → instant click harvest (ZundaGatherServer).
-- Do NOT duplicate these as Mineable tool nodes — use one path per resource.
GatherConfig.clickResources = {
	ZundaFlower = {
		itemName = "Zunda Flower",
		defaultYield = 3,
		respawnSeconds = 25,
		notifyEmoji = "🌼",
	},
	ZundaPea = {
		itemName = "Zunda Pea",
		defaultYield = 2,
		respawnSeconds = 35,
		notifyEmoji = "🫛",
	},
	-- Zunda Mushroom, Zunda Berry, Zunda Root moved to MineableConfig (Sickle tool)
	EdamamePod = {
		itemName = "Edamame Pod",
		defaultYield = 2,
		respawnSeconds = 30,
		notifyEmoji = "🫛",
	},
	ZundaLeaf = {
		itemName = "Zunda Leaf",
		defaultYield = 3,
		respawnSeconds = 22,
		notifyEmoji = "🍃",
	},
	SweetPea = {
		itemName = "Sweet Pea",
		defaultYield = 2,
		respawnSeconds = 28,
		notifyEmoji = "🫛",
	},
	PeaFlower = {
		itemName = "Pea Flower",
		defaultYield = 2,
		respawnSeconds = 30,
		notifyEmoji = "🌸",
	},
	SaltedPeaBouquet = {
		itemName = "Salted Pea Bouquet",
		defaultYield = 1,
		respawnSeconds = 45,
		notifyEmoji = "💐",
	},
}

GatherConfig.mysteryLoot = {
	"Zunda Flower",
	"Zunda Flower",
	"Zunda Pea",
	"Zunda Pea",
	"Gold Ore",
	"Marble Rock",
	"Apple",
	"Wheat",
}

GatherConfig.mysteryResourceType = "MysteryLoot"
GatherConfig.mysteryRespawnSeconds = 90

function GatherConfig.getClickResource(resourceType: string): ClickResource?
	return GatherConfig.clickResources[resourceType]
end

function GatherConfig.isClickOnlyFlora(resourceType: string): boolean
	return GatherConfig.clickResources[resourceType] ~= nil
end

return GatherConfig
