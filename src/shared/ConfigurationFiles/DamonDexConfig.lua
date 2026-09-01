--!strict
-- [[ModuleScript] DamonDexConfig]]
-- The Zundamonédex: canonical collectible registry for all companions.
-- Pokémon-inspired Dex with rarity tiers, W-stats, discovery methods, and lore.
--
-- Rarity Tiers:
--   Common    — available from early questlines, always accessible
--   Rare      — requires mid-game bonding or specific quests
--   Epic      — gacha or hard challenge rewards
--   Legendary — grand questline or endgame unlocks
--   Mythic    — seasonal exclusives, one-per-player, never re-earnable
--
-- W-Stats (Warmth / Wit / Wildness / Wisdom):
--   Warmth   : how nurturing/supportive the companion is (affects guest patience aura)
--   Wit      : cleverness, strategy, chain bonus potential
--   Wildness : unpredictability, RNG influence, critical event chance
--   Wisdom   : lore depth, stat growth rate boost, XP multiplier
--   All stats 1–10 scale.

local DamonDexConfig = {}

DamonDexConfig.entries = {

	-- ── Original Companions ──────────────────────────────────────────────────

	zundamon = {
		displayName = "Zundamon",
		dexNumber = 1,
		rarity = "Legendary",
		types = { "Pea", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "She finds you. Always.",
		lore = "The first companion. The original Zunda fairy. A fragment of the Zunda Arrow made sentient by centuries of warmth. She ends every sentence with ~のだ and has never once admitted to being tired.",
		wStats = { Warmth = 10, Wit = 6, Wildness = 7, Wisdom = 8 },
	},
	ankomon = {
		displayName = "Ankomon",
		dexNumber = 2,
		rarity = "Rare",
		types = { "Pea", "Fermented" },
		discoveryMethod = "questline",
		discoveryHint = "Follow the smell of roasted red beans at dusk.",
		lore = "A red bean spirit who sweetens every payday. Ankomon was born from the fermentation vat of a legendary sweet shop that closed three hundred years ago. She insists she is not nostalgic. The shop's sign still hangs in her glow.",
		wStats = { Warmth = 7, Wit = 5, Wildness = 3, Wisdom = 6 },
	},
	cardamon = {
		displayName = "Cardamon",
		dexNumber = 3,
		rarity = "Rare",
		types = { "Spice", "Blossom" },
		discoveryMethod = "questline",
		discoveryHint = "Find her near the spice rack. She has been waiting.",
		lore = "A cardamom seedling spirit who steadies hands and widens focus. She was once a kitchen weed — misidentified, nearly pulled out. Someone tasted her by accident and discovered that accident was actually perfection.",
		wStats = { Warmth = 6, Wit = 8, Wildness = 2, Wisdom = 7 },
	},
	antimon = {
		displayName = "Antimon",
		dexNumber = 4,
		rarity = "Rare",
		types = { "Pea", "Fermented" },
		discoveryMethod = "questline",
		discoveryHint = "Follow the mint trail north of the garden.",
		lore = "A minty wisp who whispers where to dig. Antimon is a root spirit — she lives primarily underground and surfaces only to point at things. She finds above-ground existence chaotic and bracing. She is learning to enjoy it.",
		wStats = { Warmth = 5, Wit = 7, Wildness = 5, Wisdom = 6 },
	},
	sakuradamon = {
		displayName = "Sakuradamon",
		dexNumber = 5,
		rarity = "Rare",
		types = { "Blossom", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "She appears when cherry petals fall in the kitchen.",
		lore = "A blossom spirit who carries good lessons on the breeze. Sakuradamon blooms once and lasts forever — her petals have never been recorded actually touching the ground. She considers falling to be someone else's habit.",
		wStats = { Warmth = 8, Wit = 6, Wildness = 3, Wisdom = 9 },
	},
	tantanmon = {
		displayName = "Tantanmon",
		dexNumber = 6,
		rarity = "Rare",
		types = { "Spice" },
		discoveryMethod = "questline",
		discoveryHint = "Somewhere very fast. Look quickly.",
		lore = "A spicy little firework born from the collision of a chili harvest and a midsummer lightning bolt. She has never been stationary long enough for anyone to measure her exact height. Estimates vary by three inches.",
		wStats = { Warmth = 4, Wit = 5, Wildness = 10, Wisdom = 3 },
	},
	dog = {
		displayName = "Dog Companion",
		dexNumber = 7,
		rarity = "Common",
		types = { "Pea" },
		discoveryMethod = "default",
		discoveryHint = "She was always here.",
		lore = "A faithful furry friend who arrived on the kitchen doorstep on the first day and has never left. She has no known spirit origin. She is simply Dog. This seems to satisfy everyone involved.",
		wStats = { Warmth = 9, Wit = 3, Wildness = 6, Wisdom = 4 },
	},
	cat = {
		displayName = "Cat Companion",
		dexNumber = 8,
		rarity = "Common",
		types = { "Blossom", "Shadow" },
		discoveryMethod = "default",
		discoveryHint = "She found you. Not the other way around.",
		lore = "A purring little menace of disputed origin. Cat has been observed in the kitchen, the garden, the forest glade, and several places that do not yet appear on the map. She declines to comment on any of these locations.",
		wStats = { Warmth = 5, Wit = 7, Wildness = 7, Wisdom = 5 },
	},
	parrot = {
		displayName = "Parrot Companion",
		dexNumber = 9,
		rarity = "Common",
		types = { "Blossom", "Celestial" },
		discoveryMethod = "default",
		discoveryHint = "Listen for the colourful vocabulary near the berry grove.",
		lore = "A colourful chatterbox of unknown provenance who arrived speaking seventeen languages and decided six was enough. Parrot does not explain where she learned the other eleven. She considers this a feature, not a mystery.",
		wStats = { Warmth = 6, Wit = 8, Wildness = 5, Wisdom = 6 },
	},

	-- ── Wave 2 Companions ────────────────────────────────────────────────────

	sumimon = {
		displayName = "Sumimon",
		dexNumber = 10,
		rarity = "Epic",
		types = { "Ink", "Shadow" },
		discoveryMethod = "questline",
		discoveryHint = "Complete the Ink-Wash questline. She does not appear before you are ready.",
		lore = "An ink-wash spirit who views cooking as living calligraphy. She was once a painter of some renown; the paintings still exist but are unsigned. She says she was not yet finished. By any observable measure, she never will be.",
		wStats = { Warmth = 6, Wit = 9, Wildness = 2, Wisdom = 10 },
	},
	kagamon = {
		displayName = "Kagamon",
		dexNumber = 11,
		rarity = "Epic",
		types = { "Blossom", "Shadow" },
		discoveryMethod = "questline",
		discoveryHint = "She will find you first. She always does. That is not a coincidence.",
		lore = "A shimmering mirror spirit who maintains an unwavering smile. The cracks in her glass, if you look at the right angle in the right light, trace the shape of an ancient fire. Kagamon has never looked at herself at that angle. She says mirrors are for looking outward.",
		wStats = { Warmth = 8, Wit = 7, Wildness = 4, Wisdom = 6 },
	},
	suzurimon = {
		displayName = "Suzurimon",
		dexNumber = 12,
		rarity = "Epic",
		types = { "Ancient", "Fermented" },
		discoveryMethod = "questline",
		discoveryHint = "Hear the bell ringing where there is no bell.",
		lore = "A solemn sacred bell spirit who endured the drowning of an ancient shrine. She tolled for three days as the water rose. The crack below her eastern face is a record, not a wound. She keeps your rhythm because she cannot keep anything else.",
		wStats = { Warmth = 7, Wit = 6, Wildness = 1, Wisdom = 10 },
	},
	wasabimon = {
		displayName = "Wasabimon",
		dexNumber = 13,
		rarity = "Rare",
		types = { "Spice", "Ancient" },
		discoveryMethod = "questline",
		discoveryHint = "Climb to the highest gather node. She will be there, waiting, having arrived before you.",
		lore = "An austere ascetic monk from the alpine rapids who grates away all weakness. Wasabimon trained for four hundred years before she considered herself adequately prepared to comment on someone else's knife skills. She is still not satisfied with her own.",
		wStats = { Warmth = 3, Wit = 8, Wildness = 5, Wisdom = 9 },
	},
	yurimon = {
		displayName = "Yurimon",
		dexNumber = 14,
		rarity = "Rare",
		types = { "Blossom", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "Serve a perfect Royal Stew to a fashionista guest.",
		lore = "A refined former imperial banquet master who left high palace kitchens for the honest warmth of village cooking. She will not say what drove her out of the palace. She will say, unprompted and repeatedly, that the palace's knife sharpening was inconsistent.",
		wStats = { Warmth = 7, Wit = 8, Wildness = 2, Wisdom = 8 },
	},
	kinakomon = {
		displayName = "Kinakomon",
		dexNumber = 15,
		rarity = "Rare",
		types = { "Pea", "Fermented" },
		discoveryMethod = "questline",
		discoveryHint = "Find her in the warmest corner of the kitchen at dawn.",
		lore = "A warm grandmotherly mill spirit who showers the kitchen in roasted soybean warmth. Kinakomon was a grindstone before she was a spirit — centuries of grain slowly passed through her gave her opinions about wheat, strong ones, and an enduring affection for anyone who eats well.",
		wStats = { Warmth = 10, Wit = 5, Wildness = 2, Wisdom = 7 },
	},
	kuroyurimon = {
		displayName = "Kuroyurimon",
		dexNumber = 16,
		rarity = "Epic",
		types = { "Shadow", "Blossom" },
		discoveryMethod = "questline",
		discoveryHint = "She will appear dramatically at a moment of your weakness. Do not be fooled by the theatrics.",
		lore = "An overly theatrical gothic dark lily spirit who presents as a lord of darkness and is secretly an easily flustered bookworm. The darkness she claims to command is mostly borrowed from library overdue fees. Her overcook protection is completely genuine.",
		wStats = { Warmth = 5, Wit = 8, Wildness = 6, Wisdom = 7 },
	},
	matchamon = {
		displayName = "Matchamon",
		dexNumber = 17,
		rarity = "Rare",
		types = { "Fermented", "Ancient" },
		discoveryMethod = "questline",
		discoveryHint = "She is already there. You simply haven't noticed her yet.",
		lore = "A contemplative tea master who views cooking as Ichigo Ichie — one time, one meeting, never repeated. She has performed the same tea ceremony approximately 12,000 times and found something new each time. She does not see this as a contradiction.",
		wStats = { Warmth = 7, Wit = 9, Wildness = 1, Wisdom = 10 },
	},
	shisomon = {
		displayName = "Shisomon",
		dexNumber = 18,
		rarity = "Rare",
		types = { "Pea", "Fermented" },
		discoveryMethod = "questline",
		discoveryHint = "She will smell you before you find her. This is not a metaphor.",
		lore = "An eccentric botanist and pickler obsessed with fermentation microbes and wild forest herbs. Shisomon carries seventeen different fermentation crocks on her at all times. She considers this minimalist. She is wrong.",
		wStats = { Warmth = 5, Wit = 8, Wildness = 7, Wisdom = 8 },
	},
	karintomon = {
		displayName = "Karintomon",
		dexNumber = 19,
		rarity = "Rare",
		types = { "Spice", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "Win the biggest cooking chain of your life. She will be watching.",
		lore = "A high-octane festival snack master who treats the kitchen like a boisterous carnival midway. Karintomon was born from the intersection of a fireworks display and a hot sugar vat. She has been trying to recreate that moment ever since. Every perfect cook is another attempt.",
		wStats = { Warmth = 6, Wit = 5, Wildness = 10, Wisdom = 4 },
	},
	tsukimidamon = {
		displayName = "Tsukimidamon",
		dexNumber = 20,
		rarity = "Rare",
		types = { "Celestial", "Shadow" },
		discoveryMethod = "questline",
		discoveryHint = "Cook at midnight. She will be there.",
		lore = "A dreamy moon-viewing spirit who awakens under silver starry skies. Tsukimidamon has watched every full moon since the village was first built. She knows things about the night that the day cannot explain. She shares them slowly, never all at once.",
		wStats = { Warmth = 7, Wit = 7, Wildness = 4, Wisdom = 9 },
	},
	hoshidamon = {
		displayName = "Hoshidamon",
		dexNumber = 21,
		rarity = "Epic",
		types = { "Fermented", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "She was here before anyone else. She will be here after. Slow-cook something for her.",
		lore = "A sun-cured hermit who knows that greatest sweetness is unlocked through patient time. Hoshidamon has been in the village longer than the village itself — she was sun-drying things on this hillside when it was just a hill. She is not in a hurry. She never has been.",
		wStats = { Warmth = 8, Wit = 7, Wildness = 1, Wisdom = 10 },
	},

	-- ── Canon-Linked Companions ───────────────────────────────────────────────

	kiritandamon = {
		displayName = "Kiritandamon",
		dexNumber = 22,
		rarity = "Legendary",
		types = { "Ancient", "Spice" },
		discoveryMethod = "questline",
		discoveryHint = "Complete Kiritan's three-stage questline. She does not appear until you are precise enough to deserve it.",
		lore = "Tohoku Kiritan's analytical echo — she arrived in the kitchen with a clipboard and has not put it down. She has measured every cooking timer, ranked every recipe by difficulty-per-ingredient, and produced a 40-page report on knife angle optimization that nobody has read. She is very proud of it.",
		wStats = { Warmth = 5, Wit = 10, Wildness = 2, Wisdom = 9 },
	},

	itakodamon = {
		displayName = "Itakodamon",
		dexNumber = 23,
		rarity = "Legendary",
		types = { "Ancient", "Shadow" },
		discoveryMethod = "questline",
		discoveryHint = "She will find you when you have served 100 guests. She has been watching since guest number one.",
		lore = "Tohoku Itako's ancient oracle echo — she was present at the forging of the Zunda Arrow. She has not spoken about that day. She will not. She speaks mostly in chant, occasionally in prophecy, and once, memorably, in a recipe.",
		wStats = { Warmth = 4, Wit = 9, Wildness = 5, Wisdom = 10 },
	},

	zunkodamon = {
		displayName = "Zunkodamon",
		dexNumber = 24,
		rarity = "Legendary",
		types = { "Spice", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "Serve the highest-value guest of your career. She will arrive as the next guest immediately after.",
		lore = "Tohoku Zunko's warrior-chef echo — she won every battle and found it left her hungry. She applies the same focused ferocity to cooking that she once applied to combat. She once mentioned, in passing, that she used to wield Zundamon as an arrow. She has not mentioned it since.",
		wStats = { Warmth = 7, Wit = 7, Wildness = 8, Wisdom = 7 },
	},

	zunabunny = {
		displayName = "Zunabunny",
		dexNumber = 25,
		rarity = "Epic",
		types = { "Pea", "Celestial" },
		discoveryMethod = "questline",
		discoveryHint = "Fail a recipe spectacularly. She will appear to explain that she also does this constantly and it is fine.",
		lore = "Zundamon's mascot form, somehow granted autonomous existence. She is smaller, fluffier, and significantly more chaotic than her source. She does not understand consequences. She does not feel she needs to. Her edamame-pod ears are slightly larger than Zundamon's, which she considers an upgrade.",
		wStats = { Warmth = 9, Wit = 3, Wildness = 10, Wisdom = 2 },
	},

	nanonadamon = {
		displayName = "Nanonadamon",
		dexNumber = 26,
		rarity = "Mythic",
		types = { "Ancient", "Pea" },
		discoveryMethod = "questline",
		discoveryHint = "Complete 'The Zunda Origin' grand questline. She was waiting at the end of it before you started.",
		lore = "A fragment of the original Zunda Arrow — specifically the tip, broken off in the only true battle the Arrow was ever fired. She has been in the kitchen since before the kitchen existed. She ends every sentence with ~のだ. She is not good or evil. She is purpose in a quieter form.",
		wStats = { Warmth = 6, Wit = 8, Wildness = 3, Wisdom = 10 },
	},
}

-- ── Helper Functions ─────────────────────────────────────────────────────────

-- Returns dex entry for a companion key, or nil.
function DamonDexConfig.getEntry(key: string): { [string]: any }?
	return DamonDexConfig.entries[key]
end

-- Returns all entries at or above a rarity tier.
-- Order: Common < Rare < Epic < Legendary < Mythic
local RARITY_RANK = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
function DamonDexConfig.getByMinRarity(minRarity: string): { { [string]: any } }
	local minRank = RARITY_RANK[minRarity] or 1
	local result = {}
	for _, entry in pairs(DamonDexConfig.entries) do
		if (RARITY_RANK[entry.rarity] or 0) >= minRank then
			table.insert(result, entry)
		end
	end
	return result
end

-- Returns total dex size (for completion percentage calculations).
function DamonDexConfig.totalCount(): number
	local n = 0
	for _ in pairs(DamonDexConfig.entries) do
		n += 1
	end
	return n
end

return DamonDexConfig
