--!strict
-- [[ModuleScript] ZundaLoreConfig]]
-- Zundapedia: encyclopedic lore entries for Zundamon's Kitchen V2.
--
-- Entries unlock as players progress and are displayed in the Zundapedia UI panel.
-- All body text is grounded in real Zundamon canon (SSS LLC / VOICEVOX / Tohoku Zunko Project).
--
-- Fields per entry:
--   id          : unique string key
--   title       : display title
--   icon        : emoji
--   body        : 3–5 sentences of in-universe flavour, rooted in real lore
--   unlocked_by : { type = "quest"|"bond"|"companion"|"milestone", key = "...", tier = N? }
--   category    : "history" | "spirits" | "cuisine" | "world" | "canon"

local ZundaLoreConfig = {}

ZundaLoreConfig.entries = {

	-- ── Canon: Zundamon's True Origin ────────────────────────────────────────

	{
		id = "lore_zunda_arrow",
		title = "The Zunda Arrow",
		icon = "🏹",
		category = "canon",
		body = "Before she was a companion, Zundamon was a weapon — the Zunda Arrow, a magical bow forged from concentrated edamame spirit and wielded by the great warrior Tohoku Zunko. The Arrow carried Zundamon's soul: her laughter, her stubbornness, her irreducible warmth. When Zunko retired from battle, the Arrow was laid to rest, and Zundamon — no longer needed as a weapon — wandered into the world as a free spirit for the first time. She found the village kitchen and decided it suited her perfectly. She has not left since.",
		unlocked_by = { type = "quest", key = "quest_zundamon_bond_1" },
	},
	{
		id = "lore_nanoda_speech",
		title = "The ~nanoda Speech Pattern",
		icon = "💬",
		category = "canon",
		body = "Zundamon's sentences almost always end with '~のだ' (nanoda) or '~なのだ' (na-nanoda). Linguists of the spirit world believe this is a remnant of her life as an Arrow — declarations and commands, always. But Zundamon insists it simply feels right, like the pop of a fresh edamame pod. The pattern is so distinctive that companion spirits who spend enough time around her eventually adopt traces of it in their own speech.",
		unlocked_by = { type = "bond", key = "zundamon", tier = 1 },
	},
	{
		id = "lore_two_forms",
		title = "Zundamon's Two Forms",
		icon = "🌱",
		category = "canon",
		body = "Zundamon exists in two forms that she slips between without warning. Her Mascot Form is a small, fluffy white creature with large green ears that unmistakably resemble edamame pods — compact, soft, and slightly clumsy. Her Bishoujo Form is taller, androgynous, with light green hair and an expression that oscillates between determined and catastrophically unlucky. She rarely acknowledges that she has two forms; to her, they are both simply 'Zundamon.'",
		unlocked_by = { type = "milestone", key = "Garden Tending" },
	},
	{
		id = "lore_unlucky_nature",
		title = "The Unlucky Spirit",
		icon = "🍀",
		category = "canon",
		body = "Despite her enthusiasm, Zundamon has a well-documented history of being catastrophically unlucky. Pots boil over precisely when she watches them. Ingredient nodes run dry minutes after she points them out. Guest orders change the moment she memorises them. Spirits who study such things believe this is a cosmic counterbalance — her warmth and generosity are so powerful that the universe must offset them somewhere. Zundamon's response to this theory is: 'THEN I WILL BE WARM ENOUGH TO OVERFLOW THE OFFSET!!!'",
		unlocked_by = { type = "bond", key = "zundamon", tier = 2 },
	},

	-- ── Canon: Tohoku Spirit Family ──────────────────────────────────────────

	{
		id = "lore_tohoku_zunko",
		title = "Tohoku Zunko: The Warrior Chef",
		icon = "⚔️",
		category = "canon",
		body = "Tohoku Zunko is the spirit of Miyagi Prefecture and Zundamon's original partner. She is a warrior who channelled her battle energy into cooking when the wars ended, eventually becoming a celebrated feast-maker in the eastern provinces. She and Zundamon share a bond that predates memory — Arrow and archer. When Zunko visits the kitchen, the pots never boil over. Something about her presence makes the fire behave.",
		unlocked_by = { type = "quest", key = "quest_zunkodamon_meet" },
	},
	{
		id = "lore_tohoku_kiritan",
		title = "Tohoku Kiritan: The Analyst",
		icon = "📐",
		category = "canon",
		body = "Tohoku Kiritan is the most analytical of the Tohoku spirits — she approaches cooking like an engineering problem: optimal temperatures, precise gram measurements, no wasted motion. She is drawn to kitchen systems and has been known to critique inefficient chopping technique mid-conversation. Despite her reserved exterior, she has a soft spot for Zundamon's chaotic enthusiasm; she secretly keeps a logbook of Zundamon's 'anomalous successes' that defy all her models.",
		unlocked_by = { type = "quest", key = "quest_kiritandamon_meet" },
	},
	{
		id = "lore_tohoku_itako",
		title = "Tohoku Itako: The Ancient Oracle",
		icon = "🔮",
		category = "canon",
		body = "Tohoku Itako is the oldest of the recognized Tohoku spirits, and arguably the most unsettling. She communicates mostly through ritual chant, obscure metaphor, and occasional prophecy delivered at exactly the wrong moment. She knew Zundamon when the Zunda Arrow was first forged — she was present at the ceremony, though she refuses to describe what happened. 'Some knots', she says, 'are not meant to be untied.'",
		unlocked_by = { type = "quest", key = "quest_itakodamon_meet" },
	},
	{
		id = "lore_zun_zun_project",
		title = "The ZunZun Project",
		icon = "🌿",
		category = "canon",
		body = "The Tohoku spirits were not born from myth alone — they were called into being by human hope. After the great disaster that struck Japan's Tohoku region in 2011, a group of artists and voice performers created the Tohoku Zunko Project to pour love and memory into the region through art. Zundamon emerged from this same wellspring: she is a spirit of reconstruction, warmth, and resilience dressed as a clumsy fairy who speaks in ~nanoda. She carries the weight of that origin lightly, but she carries it.",
		unlocked_by = { type = "companion", key = "zundamon", tier = 3 },
	},

	-- ── Cuisine History ───────────────────────────────────────────────────────

	{
		id = "lore_zunda_mochi_origin",
		title = "The Origin of Zunda Mochi",
		icon = "🍡",
		category = "cuisine",
		body = "Zunda Mochi is the signature dish of Miyagi Prefecture — a soft rice cake blanketed in sweet, vivid green paste made from crushed edamame. The dish dates back centuries, and several competing origin stories exist: one claims the name derives from 'Zunda,' an old word for crushing beans; another that it was named after the legendary Sengoku general Date Masamune, who crushed beans with his sword hilt on the battlefield. Zundamon's version of this story changes every time she tells it.",
		unlocked_by = { type = "milestone", key = "Village Loop" },
	},
	{
		id = "lore_edamame_spirit_law",
		title = "The Edamame Spirit Laws",
		icon = "🫛",
		category = "history",
		body = "According to the oldest kitchen scrolls in the village, there are three laws that all edamame spirits must follow: Never let a pod go unharvested. Never waste the water you boiled them in — it carries iron and strength. Never refuse a hungry guest. Zundamon follows all three, though she interprets the third law so broadly that she once fed a stray cat an entire Zunda Paradise by herself.",
		unlocked_by = { type = "bond", key = "zundamon", tier = 1 },
	},
	{
		id = "lore_voicevox_mystery",
		title = "The Voice That Carries",
		icon = "🎵",
		category = "world",
		body = "Some spirits speak; Zundamon sings. The voice that resonates from her — bright, slightly nasal, full of barely-contained energy — is not like ordinary speech. It carries across the kitchen regardless of noise or distance, and it has been known to cause stuck pot lids to pop open on their own. Scholars of the spirit world attribute this to her origins as an Arrow: her words were always meant to travel.",
		unlocked_by = { type = "bond", key = "zundamon", tier = 2 },
	},

	-- ── World / Kitchen Lore ─────────────────────────────────────────────────

	{
		id = "lore_damon_suffix",
		title = "What Does '-damon' Mean?",
		icon = "✨",
		category = "world",
		body = "The '-mon' suffix in spirit names is a casual, affectionate diminutive — it roughly translates as 'little one,' 'thing,' or 'person of.' Zundamon is the Zunda-person: the spirit who IS the zunda. When other spirits adopt the '-damon' or '-mon' suffix, they are announcing themselves as part of the same lineage of warmth and kitchen magic. It is less a title and more an inheritance — freely given by Zundamon herself.",
		unlocked_by = { type = "milestone", key = "Village Loop" },
	},
	{
		id = "lore_kitchen_heartbeat",
		title = "The Kitchen as a Living Thing",
		icon = "🔥",
		category = "world",
		body = "The village kitchen is not merely a building. It breathes. The oven inhales during ingredient gathering and exhales during cooking; the serving counter has been known to inch slightly closer to hungry guests; the pots hum in a pitch that changes with the rhythm accuracy of the current cook. Zundamon has always known this. She refers to the kitchen as a 'they' — a habit the other companions have slowly begun to adopt.",
		unlocked_by = { type = "milestone", key = "Garden Tending" },
	},
	{
		id = "lore_zunda_pea_cycle",
		title = "The Zunda Pea Growth Cycle",
		icon = "🌱",
		category = "cuisine",
		body = "Zunda Peas grow differently in the village than anywhere else in the world. They take 22 seconds to respawn after harvest — exactly the length of Zundamon's favourite verse of her personal theme song. The plants seem to grow toward her voice. Larger harvests occur when she sings while gathering. The village agriculturalists have made their peace with this.",
		unlocked_by = { type = "milestone", key = "Berry Sweet" },
	},
	{
		id = "lore_types_of_spirits",
		title = "The Eight Spirit Types",
		icon = "🏮",
		category = "history",
		body = "Spirit scholars classify companion entities into eight elemental affinities: Pea, Spice, Blossom, Shadow, Celestial, Fermented, Ancient, and Ink. These are not merely categories but flavours of existence — a Spice spirit genuinely burns hotter; a Fermented spirit ages in real time. The classification was first proposed by Suzurimon, who had centuries to observe companions from the bottom of her drowned shrine. She never published her notes; they had to be recovered by divers.",
		unlocked_by = { type = "companion", key = "suzurimon", tier = 2 },
	},
	{
		id = "lore_evolution_myth",
		title = "On Transformation: The Shell Theory",
		icon = "🦋",
		category = "history",
		body = "When a companion evolves, they do not become something new — they shed a shell they have always been carrying. The original Zundamon text on transformation (dictated by Hoshidamon, who claims to have watched it happen three times) says: 'Every spirit contains its full self from the beginning. Bond, recipe, and sacrifice are not ingredients for change; they are keys for unlocking what was always there.' Hoshidamon has never confirmed or denied whether this applies to herself.",
		unlocked_by = { type = "milestone", key = "Forest Foraging" },
	},
	{
		id = "lore_challenge_mode_origin",
		title = "The Origin of the Challenge Waves",
		icon = "⚔️",
		category = "world",
		body = "The challenge waves did not begin as a test — they began as a memory. Every wave of increasingly demanding guests is a re-enactment of the night the village kitchen served 200 travellers in a single evening with only two pots and a broken ladle. Zundamon was there. She does not speak about it directly, but on the hardest waves she sometimes goes very quiet, and then very loud.",
		unlocked_by = { type = "milestone", key = "Peak Season" },
	},
	{
		id = "lore_ink_and_impermanence",
		title = "Sumimon and the Philosophy of Impermanence",
		icon = "🖌️",
		category = "spirits",
		body = "Sumimon believes that the highest form of cooking is an act of calligraphy: one brushstroke, never repeated, complete in the moment of its making. She does not mourn dishes that are eaten and gone — she considers that the point. She was the first companion to tell Zundamon that being a weapon was not a tragedy. 'You were wielded beautifully,' she said, 'and then you were set down. That is a complete stroke.' Zundamon cried for exactly four minutes and then announced she was going to cook something.",
		unlocked_by = { type = "companion", key = "sumimon", tier = 3 },
	},
	{
		id = "lore_mirror_fractures",
		title = "Kagamon and the Temple Fire",
		icon = "🪞",
		category = "spirits",
		body = "Kagamon will tell you she is a dazzling mirror spirit who has always been this radiant. She is not lying — she genuinely believes it. What the temple archives record is different: a mirror in the inner sanctum of a small Tohoku shrine that survived a fire by absorbing the building's entire light. The cracks in her reflection, if you look carefully at the right angle in the right light, trace the shape of the original fire. Kagamon has never looked at herself at that angle.",
		unlocked_by = { type = "companion", key = "kagamon", tier = 3 },
	},
	{
		id = "lore_bell_drowning",
		title = "The Drowned Shrine",
		icon = "🔔",
		category = "spirits",
		body = "Suzurimon was the bell of a shrine that was lost to a flood in a past age. She tolled continuously for three days as the water rose around her. By the time rescuers reached the site, the bell was cracked but still ringing — no one could explain how. She carries the crack still; it is visible just below her eastern face. She says it is not a wound. She says it is a record. She does not elaborate.",
		unlocked_by = { type = "companion", key = "suzurimon", tier = 3 },
	},
	{
		id = "lore_nanonadamon_arrow",
		title = "The Oldest Fragment",
		icon = "🏹",
		category = "spirits",
		body = "Nanonadamon does not claim to be ancient. Nanonadamon simply IS ancient, in the same way that rivers do not claim to be wet. She is a fragment of the original Zunda Arrow — specifically, the portion of the arrowhead that broke off during the first and last true battle the Arrow was ever fired in. She landed in the village kitchen centuries before anyone else arrived. She has been there ever since, watching, in the way that fragments of things that have known purpose continue to radiate it long after the purpose has passed.",
		unlocked_by = { type = "companion", key = "nanonadamon", tier = 1 },
	},
}

-- ── Helper Functions ─────────────────────────────────────────────────────────

-- Returns all entries in a given category.
function ZundaLoreConfig.getByCategory(category: string): { { [string]: any } }
	local result = {}
	for _, entry in ipairs(ZundaLoreConfig.entries) do
		if entry.category == category then
			table.insert(result, entry)
		end
	end
	return result
end

-- Returns an entry by id, or nil.
function ZundaLoreConfig.getById(id: string): { [string]: any }?
	for _, entry in ipairs(ZundaLoreConfig.entries) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

return ZundaLoreConfig
