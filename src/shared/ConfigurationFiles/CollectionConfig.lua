--!strict
-- [[ModuleScript] CollectionConfig]
-- Central collection totals for the Collection Tracker panel.
-- All totals are derived from canonical config catalogs so the tracker never
-- drifts out of sync when new companions, recipes, achievements, or zones are
-- added.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CompanionConfig = require(ReplicatedStorage.ConfigurationFiles.CompanionConfig)
local AchievementConfig = require(ReplicatedStorage.ConfigurationFiles.AchievementConfig)
local CraftConfig = require(ReplicatedStorage.ConfigurationFiles.CraftConfig)
local TeleporterConfig = require(ReplicatedStorage.ConfigurationFiles.TeleporterConfig)

local CollectionConfig = {}

CollectionConfig.categories = {
	{
		id = "companions",
		label = "Companions",
		icon = "🌱",
		color = Color3.fromRGB(160, 210, 150),
	},
	{
		id = "achievements",
		label = "Achievements",
		icon = "🏆",
		color = Color3.fromRGB(255, 200, 80),
	},
	{
		id = "recipes",
		label = "Recipes",
		icon = "🍳",
		color = Color3.fromRGB(255, 150, 200),
	},
	{
		id = "biomes",
		label = "Biomes",
		icon = "🗺️",
		color = Color3.fromRGB(145, 215, 195),
	},
}

function CollectionConfig.getTotal(categoryId: string): number
	if categoryId == "companions" then
		local count = 0
		for _ in pairs(CompanionConfig.companions) do
			count += 1
		end
		return count
	elseif categoryId == "achievements" then
		return #AchievementConfig
	elseif categoryId == "recipes" then
		local count = 0
		for _ in pairs(CraftConfig.recipes) do
			count += 1
		end
		return count
	elseif categoryId == "biomes" then
		local count = 0
		for _ in pairs(TeleporterConfig.zones) do
			count += 1
		end
		return count
	end
	return 0
end

function CollectionConfig.getTotals(): { [string]: number }
	local totals = {}
	for _, category in ipairs(CollectionConfig.categories) do
		totals[category.id] = CollectionConfig.getTotal(category.id)
	end
	return totals
end

return CollectionConfig
