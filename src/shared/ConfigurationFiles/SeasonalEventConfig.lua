--!strict
-- [[ModuleScript] SeasonalEventConfig]]
-- 4 Seasonal Events for Zundamon's Kitchen V2.
--
-- Each event runs during its real-world season window. Events provide:
--   - Exclusive recipes (only craftable during the event)
--   - One Mythic damon encounter (only obtainable that season, ever)
--   - A seasonal currency earned from daily quests
--   - A 7-day quest chain (quest IDs reference QuestConfig entries)
--   - Additional gacha banner pool injections
--   - Seasonal shop: cosmetics, evolution items, exclusive recipes
--
-- Season detection uses the server's UTC month to determine which event
-- is active. Multiple events do not overlap.
-- Spring: March–May (months 3–5)
-- Summer: June–August (months 6–8)
-- Autumn: September–November (months 9–11)
-- Winter: December–February (months 12, 1, 2)

local SeasonalEventConfig = {}

-- ── Active Season Lookup ──────────────────────────────────────────────────────

-- Returns the season key for a given UTC month (1–12).
function SeasonalEventConfig.getSeasonForMonth(month: number): string
	if month >= 3 and month <= 5 then
		return "spring"
	elseif month >= 6 and month <= 8 then
		return "summer"
	elseif month >= 9 and month <= 11 then
		return "autumn"
	else
		return "winter"
	end
end

-- ── Event Definitions ─────────────────────────────────────────────────────────

SeasonalEventConfig.events = {

	spring = {
		id = "spring_blossom_fest",
		displayName = "Spring Blossom Fest",
		emoji = "🌸",
		tagline = "The petals have arrived. The kitchen is alive.",
		color = Color3.fromRGB(255, 200, 220),
		months = { 3, 4, 5 },

		-- Seasonal currency
		currency = {
			id = "blossom_tokens",
			displayName = "Blossom Tokens",
			emoji = "🌸",
			description = "Earned from spring daily quests. Spend at the Blossom Shop.",
		},

		-- Exclusive recipes (only craftable during this event)
		exclusive_recipes = {
			["Sakura Zunda Parfait"] = { ["Pea Flower"] = 4, ["Zunda Pea"] = 3, ["Sweet Pea"] = 2 },
			["Hanami Mochi Platter"] = { ["Zunda Pea"] = 5, ["Wheat"] = 8, ["Pea Flower"] = 3 },
			["Cherry Blossom Dango"] = { ["Sweet Pea"] = 4, ["Zunda Berry"] = 3, ["Pea Flower"] = 2 },
		},
		exclusive_recipe_times = {
			["Sakura Zunda Parfait"] = 7,
			["Hanami Mochi Platter"] = 9,
			["Cherry Blossom Dango"] = 6,
		},

		-- Mythic damon — only obtainable during this event, ever
		mythic_damon = {
			key = "harumon",
			displayName = "Harumon",
			nameJP = "春もん",
			emoji = "🌺",
			rarity = "Mythic",
			flavor = "The first blossom of the year. She arrives without warning and leaves the same way.",
			unlock_quest = "quest_harumon_spring_final",
		},

		-- 7-day quest chain (IDs defined in QuestConfig)
		quest_chain = {
			day1 = "quest_spring_day1_bloom",
			day2 = "quest_spring_day2_gather",
			day3 = "quest_spring_day3_cook",
			day4 = "quest_spring_day4_serve",
			day5 = "quest_spring_day5_bond",
			day6 = "quest_spring_day6_perfect",
			day7 = "quest_spring_day7_final",
		},

		-- Seasonal shop
		shop = {
			{
				id = "spring_apron_cosmetic",
				cost = 80,
				currency = "blossom_tokens",
				type = "cosmetic",
				name = "Cherry Blossom Apron",
			},
			{
				id = "spring_evo_item",
				cost = 150,
				currency = "blossom_tokens",
				type = "evo_item",
				name = "Petal Evolution Stone",
				item = "Pea Flower",
				count = 5,
			},
			{
				id = "spring_gacha_ticket",
				cost = 40,
				currency = "blossom_tokens",
				type = "currency",
				name = "Whim Ticket ×5",
			},
			{
				id = "spring_recipe_sakura",
				cost = 60,
				currency = "blossom_tokens",
				type = "recipe",
				name = "Sakura Zunda Parfait (permanent unlock)",
			},
		},

		-- Gacha banner injections (added to active GachaConfig banner)
		gacha_pool_additions = {
			legendary = {
				{
					id = "harumon_damon_token",
					type = "damon_encounter",
					name = "Harumon Encounter Token",
					icon = "🌺",
				},
			},
			epic = {
				{ id = "spring_apron_legendary", type = "outfit", name = "Legendary Blossom Dress", icon = "👗" },
			},
		},
	},

	summer = {
		id = "summer_harvest_rush",
		displayName = "Summer Harvest Rush",
		emoji = "☀️",
		tagline = "The sun is at its peak. The kitchen has never been busier.",
		color = Color3.fromRGB(255, 210, 100),
		months = { 6, 7, 8 },

		currency = {
			id = "sunstone_shards",
			displayName = "Sunstone Shards",
			emoji = "🌟",
			description = "Earned from summer daily quests. Spend at the Summer Stall.",
		},

		exclusive_recipes = {
			["Hoshidamon's Midsummer Sun Jelly"] = { ["Zunda Berry"] = 5, ["Sweet Pea"] = 3, ["Apple"] = 4 },
			["Karintomon's Festival Fire Crunch"] = { ["Zunda Pea"] = 4, ["Wheat"] = 6, ["Gold"] = 1 },
			["Edamame Shaved Ice"] = { ["Edamame Pod"] = 5, ["Zunda Pea"] = 3, ["Zunda Leaf"] = 2 },
		},
		exclusive_recipe_times = {
			["Hoshidamon's Midsummer Sun Jelly"] = 8,
			["Karintomon's Festival Fire Crunch"] = 5,
			["Edamame Shaved Ice"] = 4,
		},

		mythic_damon = {
			key = "natsudamon",
			displayName = "Natsudamon",
			nameJP = "夏もん",
			emoji = "🌻",
			rarity = "Mythic",
			flavor = "A sunflower spirit who arrived at noon and hasn't moved since. She is, by her own accounting, exactly where she is supposed to be.",
			unlock_quest = "quest_natsudamon_summer_final",
		},

		quest_chain = {
			day1 = "quest_summer_day1_harvest",
			day2 = "quest_summer_day2_fire",
			day3 = "quest_summer_day3_rush",
			day4 = "quest_summer_day4_guest",
			day5 = "quest_summer_day5_festival",
			day6 = "quest_summer_day6_chain",
			day7 = "quest_summer_day7_final",
		},

		shop = {
			{
				id = "summer_hat_cosmetic",
				cost = 80,
				currency = "sunstone_shards",
				type = "cosmetic",
				name = "Straw Festival Hat",
			},
			{
				id = "summer_evo_item",
				cost = 150,
				currency = "sunstone_shards",
				type = "evo_item",
				name = "Sunstone Shard ×10",
				item = "Zunda Berry",
				count = 8,
			},
			{
				id = "summer_gacha_ticket",
				cost = 40,
				currency = "sunstone_shards",
				type = "currency",
				name = "Whim Ticket ×5",
			},
			{
				id = "summer_recipe_jelly",
				cost = 60,
				currency = "sunstone_shards",
				type = "recipe",
				name = "Hoshidamon's Sun Jelly (permanent unlock)",
			},
		},

		gacha_pool_additions = {
			legendary = {
				{
					id = "natsudamon_damon_token",
					type = "damon_encounter",
					name = "Natsudamon Encounter Token",
					icon = "🌻",
				},
			},
			epic = { { id = "summer_festival_crown", type = "accessory", name = "Festival Crown", icon = "👑" } },
		},
	},

	autumn = {
		id = "autumn_moon_gathering",
		displayName = "Autumn Moon Gathering",
		emoji = "🍂",
		tagline = "The harvest is in. The moon is full. Someone is waiting at the kitchen door.",
		color = Color3.fromRGB(220, 150, 80),
		months = { 9, 10, 11 },

		currency = {
			id = "moonleaf_coins",
			displayName = "Moonleaf Coins",
			emoji = "🍂",
			description = "Earned from autumn daily quests. Spend at the Moon Market.",
		},

		exclusive_recipes = {
			["Tsukimidamon's Harvest Moon Soup"] = { ["Zunda Root"] = 4, ["Zunda Mushroom"] = 3, ["Zunda Berry"] = 2 },
			["Hoshidamon's Persimmon Slow-Cure"] = { ["Apple"] = 5, ["Zunda Root"] = 3, ["Gold"] = 1 },
			["Autumn Leaf Zunda Crepe"] = { ["Wheat"] = 8, ["Zunda Berry"] = 4, ["Sweet Pea"] = 2 },
		},
		exclusive_recipe_times = {
			["Tsukimidamon's Harvest Moon Soup"] = 9,
			["Hoshidamon's Persimmon Slow-Cure"] = 11,
			["Autumn Leaf Zunda Crepe"] = 7,
		},

		mythic_damon = {
			key = "akimon",
			displayName = "Akimon",
			nameJP = "秋もん",
			emoji = "🍁",
			rarity = "Mythic",
			flavor = "An autumn spirit who appears only at the precise moment a leaf decides to let go. Guests who encounter her always order comfort food.",
			unlock_quest = "quest_akimon_autumn_final",
		},

		quest_chain = {
			day1 = "quest_autumn_day1_harvest",
			day2 = "quest_autumn_day2_moon",
			day3 = "quest_autumn_day3_gather",
			day4 = "quest_autumn_day4_bond",
			day5 = "quest_autumn_day5_cook",
			day6 = "quest_autumn_day6_slow",
			day7 = "quest_autumn_day7_final",
		},

		shop = {
			{
				id = "autumn_cloak_cosmetic",
				cost = 80,
				currency = "moonleaf_coins",
				type = "cosmetic",
				name = "Harvest Cloak",
			},
			{
				id = "autumn_evo_item",
				cost = 150,
				currency = "moonleaf_coins",
				type = "evo_item",
				name = "Moon Dew Drop",
				item = "Zunda Root",
				count = 6,
			},
			{
				id = "autumn_gacha_ticket",
				cost = 40,
				currency = "moonleaf_coins",
				type = "currency",
				name = "Whim Ticket ×5",
			},
			{
				id = "autumn_recipe_soup",
				cost = 60,
				currency = "moonleaf_coins",
				type = "recipe",
				name = "Harvest Moon Soup (permanent unlock)",
			},
		},

		gacha_pool_additions = {
			legendary = {
				{ id = "akimon_damon_token", type = "damon_encounter", name = "Akimon Encounter Token", icon = "🍁" },
			},
			epic = {
				{ id = "autumn_lantern_back", type = "accessory", name = "Paper Lantern Backpiece", icon = "🏮" },
			},
		},
	},

	winter = {
		id = "winter_zunda_vigil",
		displayName = "Winter Zunda Vigil",
		emoji = "❄️",
		tagline = "The snow has come. The warmest kitchen is the one with the most companions.",
		color = Color3.fromRGB(200, 220, 255),
		months = { 12, 1, 2 },

		currency = {
			id = "frost_pearls",
			displayName = "Frost Pearls",
			emoji = "❄️",
			description = "Earned from winter daily quests. Spend at the Winter Hearth Shop.",
		},

		exclusive_recipes = {
			["Suzurimon's Midnight Bell Oshiruko"] = { ["Zunda Pea"] = 5, ["Sweet Pea"] = 3, ["Wheat"] = 6 },
			["Kinakomon's Hearth Kinako Porridge"] = { ["Wheat"] = 10, ["Zunda Root"] = 3, ["Edamame Pod"] = 4 },
			["Winter Zunda Nabe"] = {
				["Zunda Mushroom"] = 4,
				["Zunda Root"] = 3,
				["Edamame Pod"] = 3,
				["Zunda Leaf"] = 2,
			},
		},
		exclusive_recipe_times = {
			["Suzurimon's Midnight Bell Oshiruko"] = 8,
			["Kinakomon's Hearth Kinako Porridge"] = 7,
			["Winter Zunda Nabe"] = 12,
		},

		mythic_damon = {
			key = "fuyumon",
			displayName = "Fuyumon",
			nameJP = "冬もん",
			emoji = "☃️",
			rarity = "Mythic",
			flavor = "A winter spirit made of the silence between snowflakes. She has been coming to this kitchen every winter for as long as anyone can remember, and she has never once explained why.",
			unlock_quest = "quest_fuyumon_winter_final",
		},

		quest_chain = {
			day1 = "quest_winter_day1_warmth",
			day2 = "quest_winter_day2_nabe",
			day3 = "quest_winter_day3_vigil",
			day4 = "quest_winter_day4_bond",
			day5 = "quest_winter_day5_bell",
			day6 = "quest_winter_day6_feast",
			day7 = "quest_winter_day7_final",
		},

		shop = {
			{
				id = "winter_shawl_cosmetic",
				cost = 80,
				currency = "frost_pearls",
				type = "cosmetic",
				name = "Snowfall Shawl",
			},
			{
				id = "winter_evo_item",
				cost = 150,
				currency = "frost_pearls",
				type = "evo_item",
				name = "Frost Pearl ×5",
				item = "Sweet Pea",
				count = 8,
			},
			{
				id = "winter_gacha_ticket",
				cost = 40,
				currency = "frost_pearls",
				type = "currency",
				name = "Whim Ticket ×5",
			},
			{
				id = "winter_recipe_nabe",
				cost = 60,
				currency = "frost_pearls",
				type = "recipe",
				name = "Winter Zunda Nabe (permanent unlock)",
			},
		},

		gacha_pool_additions = {
			legendary = {
				{
					id = "fuyumon_damon_token",
					type = "damon_encounter",
					name = "Fuyumon Encounter Token",
					icon = "☃️",
				},
			},
			epic = { { id = "winter_ice_crown", type = "accessory", name = "Frost Crown", icon = "❄️" } },
		},
	},
}

-- ── Helper Functions ──────────────────────────────────────────────────────────

-- Returns the active event for the current UTC month, or nil if none.
function SeasonalEventConfig.getActiveEvent(): { [string]: any }?
	local month = tonumber(os.date("!%m")) or 1
	local seasonKey = SeasonalEventConfig.getSeasonForMonth(month)
	return SeasonalEventConfig.events[seasonKey]
end

return SeasonalEventConfig
