--!strict
-- [[ModuleScript] DamonTypeConfig]]
-- Pokémon-inspired Damon Type System for Zundamon's Kitchen V2.
--
-- Every companion belongs to one or more types. Types drive:
--   1. Party synergy bonuses (3-companion party combos → cooking buffs)
--   2. DamonDex display and filtering
--   3. Seasonal event affinities
--   4. Evolution thematic groupings
--
-- Type affinities (synergy pairs → bonus stat + magnitude):
--   Pea   + Blossom   → style_points      +0.15  (15% more style from cooking)
--   Spice + Fermented → gold_surge        +0.20  (20% gold on consecutive serves)
--   Shadow + Ink      → gather_dark       +0.20  (20% gather yield at night)
--   Celestial + Ancient → xp_surge        +0.25  (25% XP from all actions)
--   Pea   + Ancient   → combo_extend      +0.15  (15% wider perfect window)
--   Spice + Celestial → chain_bonus       +0.12  (12% chain multiplier bonus)
--   Blossom + Fermented → tip_surge       +0.18  (18% bonus tips from guests)
--   Shadow + Ancient  → overcook_resist   +0.30  (30% overcook protection)
--   Ink   + Blossom   → style_crit        +0.10  (10% chance of 2× style points)
--   All-Pea party     → pea_mastery       +0.10  (10% all stats when all 3 are Pea)

local DamonTypeConfig = {}

-- ── Type Definitions ────────────────────────────────────────────────────────

DamonTypeConfig.types = {
	Pea = {
		displayName = "Pea",
		emoji = "🫛",
		description = "Spirits rooted in the edamame/zunda lineage. Warm, grounding, cooperative.",
		color = Color3.fromRGB(160, 210, 150), -- Zunda green
		loreHint = "The Pea type descends from the original Zunda blessing — Zundamon's own life force.",
	},
	Spice = {
		displayName = "Spice",
		emoji = "🌶️",
		description = "Fiery, volatile spirits born from heat and urgency. Amplify speed and gold.",
		color = Color3.fromRGB(255, 120, 60),
		loreHint = "Spice spirits are fragments of kitchen flame — they burn bright and brief.",
	},
	Blossom = {
		displayName = "Blossom",
		emoji = "🌸",
		description = "Gentle petal spirits tied to seasons and beauty. Boost style and tips.",
		color = Color3.fromRGB(255, 180, 210),
		loreHint = "Every Blossom spirit blooms once per season, then sleeps until the next.",
	},
	Shadow = {
		displayName = "Shadow",
		emoji = "🌑",
		description = "Twilight spirits of dusk, memory, and hidden things. Thrive after dark.",
		color = Color3.fromRGB(110, 80, 150),
		loreHint = "Shadow spirits are said to be echoes of kitchens lost to time.",
	},
	Celestial = {
		displayName = "Celestial",
		emoji = "⭐",
		description = "Moon and star spirits. Patient, luminous, amplify XP and wisdom.",
		color = Color3.fromRGB(200, 215, 255),
		loreHint = "Celestial damons were placed in the sky by the first Zundamon — they watch over every cook.",
	},
	Fermented = {
		displayName = "Fermented",
		emoji = "🍶",
		description = "Slow, patient spirits of time and transformation. Reward deliberate play.",
		color = Color3.fromRGB(200, 170, 120),
		loreHint = "Fermented spirits only speak to those who wait. They have no patience for hurry.",
	},
	Ancient = {
		displayName = "Ancient",
		emoji = "🏮",
		description = "Spirits older than the village itself — oracles, bells, arrows.",
		color = Color3.fromRGB(220, 195, 145),
		loreHint = "Ancient spirits remember the Zunda Arrow. They do not share those memories lightly.",
	},
	Ink = {
		displayName = "Ink",
		emoji = "🖌️",
		description = "Artistic spirits of brush, canvas, and impermanence. Style amplifiers.",
		color = Color3.fromRGB(100, 110, 130),
		loreHint = "Ink spirits believe cooking is a form of calligraphy — one brushstroke, never repeated.",
	},
}

-- ── Companion Type Assignments ───────────────────────────────────────────────
-- Each companion key maps to a list of types (primary first).

DamonTypeConfig.assignments = {
	-- Original companions
	zundamon = { "Pea", "Celestial" },
	ankomon = { "Pea", "Fermented" },
	cardamon = { "Spice", "Blossom" },
	antimon = { "Pea", "Fermented" },
	sakuradamon = { "Blossom", "Celestial" },
	tantanmon = { "Spice" },
	dog = { "Pea" },
	cat = { "Blossom", "Shadow" },
	parrot = { "Blossom", "Celestial" },

	-- Wave 2 companions (teamwork batch)
	sumimon = { "Ink", "Shadow" },
	kagamon = { "Blossom", "Shadow" }, -- unreliable narrator: hides shadow behind blossom
	suzurimon = { "Ancient", "Fermented" }, -- cracked bell, drowned shrine
	wasabimon = { "Spice", "Ancient" },
	yurimon = { "Blossom", "Celestial" },
	kinakomon = { "Pea", "Fermented" },
	kuroyurimon = { "Shadow", "Blossom" }, -- gothic dark lily, unreliable narrator
	matchamon = { "Fermented", "Ancient" }, -- tea ceremony, ichigo ichie
	shisomon = { "Pea", "Fermented" },
	karintomon = { "Spice", "Celestial" }, -- chaotic festival energy
	tsukimidamon = { "Celestial", "Shadow" },
	hoshidamon = { "Fermented", "Celestial" },

	-- Canon-linked companions (R6 Lore Cohort)
	kiritandamon = { "Ancient", "Spice" }, -- Tohoku Kiritan: precision + analytical urgency
	itakodamon = { "Ancient", "Shadow" }, -- Tohoku Itako: oldest oracle, speaks from darkness
	zunkodamon = { "Spice", "Celestial" }, -- Tohoku Zunko: warrior heat + legendary status
	zunabunny = { "Pea", "Celestial" }, -- Zundamon mascot form: pure Pea lineage, wild luck
	nanonadamon = { "Ancient", "Pea" }, -- Zunda Arrow fragment: oldest Pea spirit of all
}

-- ── Party Synergy Table ──────────────────────────────────────────────────────
-- Pairs and triples that trigger bonuses in a party of 3.
-- Evaluated server-side by CompanionBuffServer when party is set.
-- Format: { types = { "TypeA", "TypeB" }, stat, magnitude, description }

DamonTypeConfig.synergies = {
	{
		types = { "Pea", "Blossom" },
		stat = "style_points",
		magnitude = 0.15,
		description = "Pea & Blossom: +15% style points from cooking and serving",
	},
	{
		types = { "Spice", "Fermented" },
		stat = "gold_surge",
		magnitude = 0.20,
		description = "Spice & Fermented: +20% gold on consecutive serves (chain 3+)",
	},
	{
		types = { "Shadow", "Ink" },
		stat = "gather_dark",
		magnitude = 0.20,
		description = "Shadow & Ink: +20% gather yield during evening and night",
	},
	{
		types = { "Celestial", "Ancient" },
		stat = "xp_surge",
		magnitude = 0.25,
		description = "Celestial & Ancient: +25% XP from all actions",
	},
	{
		types = { "Pea", "Ancient" },
		stat = "combo_extend",
		magnitude = 0.15,
		description = "Pea & Ancient: +15% wider perfect cooking window",
	},
	{
		types = { "Spice", "Celestial" },
		stat = "chain_bonus",
		magnitude = 0.12,
		description = "Spice & Celestial: +12% chain multiplier bonus on rhythm hits",
	},
	{
		types = { "Blossom", "Fermented" },
		stat = "tip_surge",
		magnitude = 0.18,
		description = "Blossom & Fermented: +18% bonus tips from satisfied guests",
	},
	{
		types = { "Shadow", "Ancient" },
		stat = "overcook_resist",
		magnitude = 0.30,
		description = "Shadow & Ancient: +30% reduced overcook damage per rush",
	},
	{
		types = { "Ink", "Blossom" },
		stat = "style_crit",
		magnitude = 0.10,
		description = "Ink & Blossom: +10% chance of 2× style point crits on perfect cooks",
	},
	-- Triple type bonus (all three party members share the same type)
	{
		types = { "Pea", "Pea", "Pea" },
		stat = "pea_mastery",
		magnitude = 0.10,
		description = "Full Pea Party: +10% to ALL stats — the Zunda blessing manifests!",
		requiresTriple = true,
	},
	{
		types = { "Celestial", "Celestial", "Celestial" },
		stat = "star_alignment",
		magnitude = 0.15,
		description = "Star Alignment: +15% XP from all actions — the sky watches over you",
		requiresTriple = true,
	},
	{
		types = { "Spice", "Spice", "Spice" },
		stat = "blaze_rush",
		magnitude = 0.25,
		description = "Blaze Rush: +25% cook speed — a wall of heat fills the kitchen!",
		requiresTriple = true,
	},
}

-- ── Helper Functions ─────────────────────────────────────────────────────────

-- Returns the list of types for a companion key, or {} if unknown.
function DamonTypeConfig.getTypes(companionKey: string): { string }
	return DamonTypeConfig.assignments[companionKey] or {}
end

-- Returns the primary type (first in list) for a companion key.
function DamonTypeConfig.getPrimaryType(companionKey: string): string
	local types = DamonTypeConfig.assignments[companionKey]
	return (types and types[1]) or "Pea"
end

-- Returns all active synergy bonuses for a party of 3 companion keys.
-- A synergy activates if the party contains companions whose type sets
-- collectively cover all types listed in synergy.types.
function DamonTypeConfig.getPartySynergies(
	partyKeys: { string }
): { { stat: string, magnitude: number, description: string } }
	-- Collect all types present in the party (with repetition for triple-check)
	local typeCount: { [string]: number } = {}
	for _, key in ipairs(partyKeys) do
		for _, t in ipairs(DamonTypeConfig.getTypes(key)) do
			typeCount[t] = (typeCount[t] or 0) + 1
		end
	end

	local active = {}
	for _, synergy in ipairs(DamonTypeConfig.synergies) do
		local matched = true
		if synergy.requiresTriple then
			-- All three types must be the same
			local t = synergy.types[1]
			if (typeCount[t] or 0) < 3 then
				matched = false
			end
		else
			for _, needed in ipairs(synergy.types) do
				if not typeCount[needed] or typeCount[needed] == 0 then
					matched = false
					break
				end
			end
		end
		if matched then
			table.insert(active, {
				stat = synergy.stat,
				magnitude = synergy.magnitude,
				description = synergy.description,
			})
		end
	end
	return active
end

return DamonTypeConfig
