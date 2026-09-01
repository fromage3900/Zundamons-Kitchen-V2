--!strict
-- [[ModuleScript] DamonEvolutionConfig]]
-- Pokemon-inspired evolution system for Zundamon's Kitchen V2.
--
-- Evolution Trigger Requirements (all three must be met simultaneously):
--   bond_required  : companion bond tier (1/2/3) — always 3 for evolution
--   recipe_required: the player must have cooked this dish at least once at "perfect" quality
--   item_cost      : { item = itemName, count = N } — consumed on evolution
--
-- Evolved forms gain:
--   - Buff magnitude boosted by buff_boost factor (multiplicative)
--   - New glow color (distinct from base)
--   - New sparkle palette
--   - A `evolution_awakening` VN scene key fires automatically
--   - displayName suffix appended (e.g. "·Shin" = "true/genuine" in Japanese)
--
-- NOTE: Evolved companion keys must be added to CompanionConfig.companions
-- by the implementing agent — the keys here serve as the canonical source of
-- truth for what evolved forms SHOULD exist.

local DamonEvolutionConfig = {}

-- ── Evolution Pairs ──────────────────────────────────────────────────────────

DamonEvolutionConfig.evolutions = {

	-- 1. Zundamon → Zundamon·Shin (真もん)
	--    The original spirit finally remembers the Zunda Arrow
	{
		base = "zundamon",
		evolved = "zundamon_shin",
		displayName = "Zundamon·Shin",
		nameJP = "真ずんだもん",
		bond_required = 3,
		recipe_required = "Zunda Paradise",
		item_cost = { item = "Pea Flower", count = 10 },
		buff_boost = 1.40, -- +40% on top of base
		evolved_glow = Color3.fromRGB(100, 220, 160),
		evolved_sparkles = {
			Color3.fromRGB(140, 255, 200),
			Color3.fromRGB(80, 200, 140),
			Color3.fromRGB(220, 255, 240),
		},
		evolution_flavor = "The Zunda Arrow's memory floods back in a cascade of green light. Zundamon·Shin is not just a companion — she is the source.",
		awakening_narrator = "A blinding emerald pulse. The kitchen smells of fresh edamame and something older — something that pre-dates the village itself.",
		awakening_damon = "I REMEMBER NOW, NANODA!!! THE ARROW... THE ARROW WAS ME ALL ALONG!! 🫛✨💚",
	},

	-- 2. Sakuradamon → Hanafubuki·mon (花吹雪もん)
	--    Full bloom: petals now fall upward
	{
		base = "sakuradamon",
		evolved = "hanafubukimon",
		displayName = "Hanafubuki·mon",
		nameJP = "花吹雪もん",
		bond_required = 3,
		recipe_required = "Sakuradamon's Blossom Bites",
		item_cost = { item = "Pea Flower", count = 8 },
		buff_boost = 1.45,
		evolved_glow = Color3.fromRGB(255, 140, 190),
		evolved_sparkles = {
			Color3.fromRGB(255, 170, 210),
			Color3.fromRGB(235, 100, 160),
			Color3.fromRGB(255, 230, 245),
		},
		evolution_flavor = "Petals that once drifted down now spiral upward. The blossom storm never ends — it just changes direction.",
		awakening_narrator = "A thousand petals detach from a single unseen tree and begin to rise, impossibly, into a darkening sky.",
		awakening_damon = "I finally found the season that never ends! LET US COOK SOMETHING WORTHY OF THIS WIND!!! 🌸🌸🌸",
	},

	-- 3. Sumimon → Sumimon·Shin (墨もん·真)
	--    The ink spirit finally paints herself into existence
	{
		base = "sumimon",
		evolved = "sumimon_shin",
		displayName = "Sumimon·Shin",
		nameJP = "墨もん·真",
		bond_required = 3,
		recipe_required = "Sumimon's Ink-Wash Soba",
		item_cost = { item = "Zunda Leaf", count = 12 },
		buff_boost = 1.50,
		evolved_glow = Color3.fromRGB(60, 70, 100),
		evolved_sparkles = {
			Color3.fromRGB(30, 40, 70),
			Color3.fromRGB(100, 120, 160),
			Color3.fromRGB(200, 220, 255),
		},
		evolution_flavor = "She was always the brushstroke, never the painter. Now she is both.",
		awakening_narrator = "The ink drips upward from the page. A silhouette assembles itself, unhurried, from a thousand unfinished lines.",
		awakening_damon = "... I finally signed the painting. It was... always me, wasn't it. Thank you for sitting with me until the ink dried.",
	},

	-- 4. Ankomon → Ankomon·Kinsei (金星あんこもん)
	--    Red bean alchemist transcends into golden prosperity
	{
		base = "ankomon",
		evolved = "ankomon_kinsei",
		displayName = "Ankomon·Kinsei",
		nameJP = "金星あんこもん",
		bond_required = 3,
		recipe_required = "Ankomon's Protein Punch",
		item_cost = { item = "Gold", count = 5 },
		buff_boost = 1.35,
		evolved_glow = Color3.fromRGB(255, 200, 50),
		evolved_sparkles = {
			Color3.fromRGB(255, 230, 120),
			Color3.fromRGB(220, 160, 30),
			Color3.fromRGB(255, 250, 200),
		},
		evolution_flavor = "Every guest who leaves now feels richer than when they arrived — even if they can't explain why.",
		awakening_narrator = "A smell of roasted red beans and something metallic — like warm gold coins. Then: laughter, distant and generous.",
		awakening_damon = "HEY HEY HEY!!! ALL THAT SWEETNESS COMPOUNDED INTO SOMETHING LEGENDARY!!! YOUR WALLET IS SAFE WITH ME!!! 💰🥜✨",
	},

	-- 5. Tantanmon → Gōkaemon (豪快もん)
	--    The spicy spirit ignites into a full culinary wildfire
	{
		base = "tantanmon",
		evolved = "gokaemon",
		displayName = "Gōkaemon",
		nameJP = "豪快もん",
		bond_required = 3,
		recipe_required = "Royal Stew",
		item_cost = { item = "Zunda Berry", count = 6 },
		buff_boost = 1.45,
		evolved_glow = Color3.fromRGB(255, 70, 20),
		evolved_sparkles = {
			Color3.fromRGB(255, 120, 50),
			Color3.fromRGB(200, 40, 10),
			Color3.fromRGB(255, 200, 80),
		},
		evolution_flavor = "The spark became a wildfire. There is no such thing as too fast now.",
		awakening_narrator = "An explosion of heat and citrus-pepper. The kitchen timer melts. The oven door swings open on its own.",
		awakening_damon = "COOK FASTER. FASTER. THE GUESTS CAN'T EVEN SEE ME MOVE ANYMORE!!! THIS IS WHAT SPEED FEELS LIKE!!! 🔥🔥🔥",
	},

	-- 6. Suzurimon → Ōgane·mon (大鐘もん)
	--    The cracked shrine bell becomes the great cathedral bell
	{
		base = "suzurimon",
		evolved = "oganemon",
		displayName = "Ōgane·mon",
		nameJP = "大鐘もん",
		bond_required = 3,
		recipe_required = "Suzurimon's Bell Chime Dango",
		item_cost = { item = "Zunda Root", count = 8 },
		buff_boost = 1.60,
		evolved_glow = Color3.fromRGB(200, 160, 60),
		evolved_sparkles = {
			Color3.fromRGB(230, 190, 90),
			Color3.fromRGB(160, 120, 30),
			Color3.fromRGB(255, 235, 160),
		},
		evolution_flavor = "The crack sealed. The silence it broke was the silence of a hundred years.",
		awakening_narrator = "A single low tone resonates through the floorboards, the walls, the sky. Nothing burns in this kitchen. Not anymore.",
		awakening_damon = "... The fracture is gone. I can ring clearly now. I will keep your tempo, always. Do not falter.",
	},

	-- 7. Matchamon → Kōcha·mon (紅茶もん)
	--    The green tea ceremony master masters red tea: the opposite side of the leaf
	{
		base = "matchamon",
		evolved = "kochamon",
		displayName = "Kōcha·mon",
		nameJP = "紅茶もん",
		bond_required = 3,
		recipe_required = "Matchamon's Ceremonial Froth Bowl",
		item_cost = { item = "Zunda Flower", count = 10 },
		buff_boost = 1.40,
		evolved_glow = Color3.fromRGB(180, 90, 60),
		evolved_sparkles = {
			Color3.fromRGB(210, 120, 80),
			Color3.fromRGB(150, 60, 30),
			Color3.fromRGB(255, 200, 170),
		},
		evolution_flavor = "She spent centuries mastering the stillness of green. It took one perfect cook to discover warmth.",
		awakening_narrator = "The tea bowl turns amber. The ceremony continues, but the ceremony has changed. Something warm and imperfect has entered.",
		awakening_damon = "I thought ceremony meant stillness. But you showed me that warmth is also a kind of ritual. Let us begin.",
	},

	-- 8. Tsukimidamon → Mangetsu·mon (満月もん)
	--    New moon to full moon — the night shift apex
	{
		base = "tsukimidamon",
		evolved = "mangetsumon",
		displayName = "Mangetsu·mon",
		nameJP = "満月もん",
		bond_required = 3,
		recipe_required = "Tsukimidamon's Lunar Dumpling Plate",
		item_cost = { item = "Sweet Pea", count = 10 },
		buff_boost = 1.50,
		evolved_glow = Color3.fromRGB(240, 245, 255),
		evolved_sparkles = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(200, 215, 255),
			Color3.fromRGB(255, 245, 200),
		},
		evolution_flavor = "The crescent became the full moon. The whole kitchen glows silver at midnight now.",
		awakening_narrator = "Total lunar fullness. The shadows retreat to the edges of the map. Every surface shines like polished lacquer.",
		awakening_damon = "The moon is full, {player}. I am full. The kitchen is full of light. Tonight, we cook like there is no morning after... 🌕✨",
	},
}

-- ── Helper Functions ─────────────────────────────────────────────────────────

-- Returns the evolution entry for a base companion key, or nil if none.
function DamonEvolutionConfig.getEvolution(baseKey: string): {
	base: string,
	evolved: string,
	displayName: string,
	bond_required: number,
	recipe_required: string,
	item_cost: { item: string, count: number },
	buff_boost: number,
	[string]: any,
}?
	for _, evo in ipairs(DamonEvolutionConfig.evolutions) do
		if evo.base == baseKey then
			return evo
		end
	end
	return nil
end

-- Returns true if the player satisfies all conditions to evolve a companion.
-- playerData: { bondTiers: {[key]: number}, cookedPerfect: {[recipe]: bool}, inventory: {[item]: number} }
function DamonEvolutionConfig.canEvolve(baseKey: string, playerData: { [string]: any }): (boolean, string)
	local evo = DamonEvolutionConfig.getEvolution(baseKey)
	if not evo then
		return false, "No evolution exists for this companion."
	end

	local bondTiers = playerData.bondTiers or {}
	if (bondTiers[baseKey] or 0) < evo.bond_required then
		return false, ("Bond tier %d required (current: %d)."):format(evo.bond_required, bondTiers[baseKey] or 0)
	end

	local cookedPerfect = playerData.cookedPerfect or {}
	if not cookedPerfect[evo.recipe_required] then
		return false, ("Must cook '%s' at Perfect quality first."):format(evo.recipe_required)
	end

	local inventory = playerData.inventory or {}
	local needed = evo.item_cost
	if (inventory[needed.item] or 0) < needed.count then
		return false, ("Need %d× %s (have %d)."):format(needed.count, needed.item, inventory[needed.item] or 0)
	end

	return true, "Ready to evolve!"
end

return DamonEvolutionConfig
