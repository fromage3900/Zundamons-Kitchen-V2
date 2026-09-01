-- [[ModuleScript] CraftConfig (ref: RBXA87A5A8ED1144C28AF3B367DE07C83A3)]]
local craft = {}

craft.recipes = {
	-- Tier 1: Starter recipes
	["Apple Pie"] = { ["Apple"] = 3, ["Wheat"] = 5 },
	["Bread"] = { ["Wheat"] = 10 },

	-- Tier 2: Intermediate recipes (unlock after 5 guests)
	["Zunda Bread"] = { ["Wheat"] = 15, ["Apple"] = 2 },
	["Royal Stew"] = { ["Wheat"] = 8, ["Apple"] = 5, ["Gold"] = 1 },
	["Zunda Mochi"] = { ["Zunda Pea"] = 5, ["Wheat"] = 8 },
	["Edamame Snack"] = { ["Edamame Pod"] = 3, ["Zunda Leaf"] = 2 },

	-- Tier 3: Advanced recipes (unlock after 20 guests)
	["Fancy Pie"] = { ["Apple"] = 7, ["Wheat"] = 12, ["Gold"] = 2 },
	["Zundamon's Banquet"] = { ["Wheat"] = 20, ["Apple"] = 10, ["Gold"] = 3 },
	["Sweet Pea Cake"] = { ["Sweet Pea"] = 4, ["Wheat"] = 10, ["Zunda Pea"] = 3 },
	["Pea Flower Tea"] = { ["Pea Flower"] = 5, ["Zunda Leaf"] = 3 },

	-- Tier 4: Expert recipe (unlock after 50 guests)
	["Ultimate Feast"] = { ["Wheat"] = 30, ["Apple"] = 20, ["Gold"] = 5 },
	["Zunda Paradise"] = { ["Zunda Pea"] = 15, ["Edamame Pod"] = 10, ["Sweet Pea"] = 5, ["Pea Flower"] = 3 },

	-- ════════════════════════════════════════════════════════
	-- NEW RECIPES v2 — Seasonal, companion-themed, mastery dishes
	-- ════════════════════════════════════════════════════════

	-- Tier 2
	["Antimon's Speed Soup"] = { ["Zunda Mushroom"] = 4, ["Zunda Leaf"] = 3 },
	["Cardamon's Calm Cup"] = { ["Pea Flower"] = 3, ["Zunda Leaf"] = 2, ["Sweet Pea"] = 1 },

	-- Tier 3
	["Seasonal Salad"] = { ["Zunda Berry"] = 3, ["Zunda Leaf"] = 2 },
	["Sakuradamon's Blossom Bites"] = { ["Pea Flower"] = 4, ["Zunda Berry"] = 3 },

	-- Tier 4
	["Warm Winter Stew"] = { ["Zunda Root"] = 3, ["Zunda Mushroom"] = 2, ["Gold"] = 1 },
	["Ankomon's Protein Punch"] = { ["Edamame Pod"] = 5, ["Zunda Pea"] = 3, ["Gold"] = 1 },
	["Golden Harvest Platter"] = { ["Apple"] = 5, ["Wheat"] = 8, ["Gold"] = 2, ["Sweet Pea"] = 3 },

	-- ════════════════════════════════════════════════════════
	-- 12 NOVEL -DAMON COMPANION SIGNATURE RECIPES
	-- ════════════════════════════════════════════════════════
	["Sumimon's Ink-Wash Soba"] = { ["Wheat"] = 8, ["Zunda Mushroom"] = 4, ["Zunda Leaf"] = 3 },
	["Kagamon's Glazed Mirror Mochi"] = { ["Zunda Pea"] = 6, ["Wheat"] = 8, ["Sweet Pea"] = 3 },
	["Suzurimon's Bell Chime Dango"] = { ["Zunda Pea"] = 5, ["Wheat"] = 6, ["Gold"] = 1 },
	["Wasabimon's Pungent Zunda Soba"] = { ["Wheat"] = 10, ["Zunda Leaf"] = 4, ["Zunda Root"] = 3 },
	["Yurimon's Imperial Lily Glaze"] = { ["Sweet Pea"] = 5, ["Pea Flower"] = 4, ["Gold"] = 2 },
	["Kinakomon's Golden Dust Dango"] = { ["Wheat"] = 12, ["Zunda Pea"] = 4, ["Apple"] = 2 },
	["Kuroyurimon's Eclipse Velvet Tart"] = { ["Zunda Berry"] = 5, ["Wheat"] = 8, ["Zunda Mushroom"] = 3 },
	["Matchamon's Ceremonial Froth Bowl"] = { ["Pea Flower"] = 6, ["Zunda Leaf"] = 5, ["Sweet Pea"] = 2 },
	["Shisomon's Pickled Perilla Wrap"] = { ["Zunda Leaf"] = 6, ["Zunda Root"] = 3, ["Zunda Berry"] = 3 },
	["Karintomon's Crisp Molasses Crunch"] = { ["Wheat"] = 10, ["Apple"] = 4, ["Gold"] = 2 },
	["Tsukimidamon's Lunar Dumpling Plate"] = { ["Wheat"] = 8, ["Zunda Pea"] = 6, ["Sweet Pea"] = 4 },
	["Hoshidamon's Sun-Cured Persimmon Paste"] = { ["Apple"] = 6, ["Zunda Berry"] = 4, ["Zunda Root"] = 3 },
}

-- Cooking time multipliers (for timed cooking mechanic)
craft.cookingTimes = {
	["Apple Pie"] = 5,
	["Bread"] = 4,
	["Zunda Bread"] = 6,
	["Royal Stew"] = 8,
	["Zunda Mochi"] = 7,
	["Edamame Snack"] = 3,
	["Fancy Pie"] = 10,
	["Zundamon's Banquet"] = 12,
	["Sweet Pea Cake"] = 9,
	["Pea Flower Tea"] = 4,
	["Ultimate Feast"] = 15,
	["Zunda Paradise"] = 20,
	["Antimon's Speed Soup"] = 3,
	["Cardamon's Calm Cup"] = 5,
	["Seasonal Salad"] = 4,
	["Sakuradamon's Blossom Bites"] = 7,
	["Warm Winter Stew"] = 9,
	["Ankomon's Protein Punch"] = 10,
	["Golden Harvest Platter"] = 13,

	-- 12 Companion Signature Dish Timers
	["Sumimon's Ink-Wash Soba"] = 6,
	["Kagamon's Glazed Mirror Mochi"] = 8,
	["Suzurimon's Bell Chime Dango"] = 5,
	["Wasabimon's Pungent Zunda Soba"] = 5,
	["Yurimon's Imperial Lily Glaze"] = 9,
	["Kinakomon's Golden Dust Dango"] = 6,
	["Kuroyurimon's Eclipse Velvet Tart"] = 7,
	["Matchamon's Ceremonial Froth Bowl"] = 4,
	["Shisomon's Pickled Perilla Wrap"] = 4,
	["Karintomon's Crisp Molasses Crunch"] = 7,
	["Tsukimidamon's Lunar Dumpling Plate"] = 6,
	["Hoshidamon's Sun-Cured Persimmon Paste"] = 9,
}

-- Per-recipe minigame difficulty (shared: client spawns notes, server validates)
craft.difficulty = {
	["Bread"] = { notes = 3, speed = 2.0 },
	["Apple Pie"] = { notes = 4, speed = 1.9 },
	["Zunda Bread"] = { notes = 5, speed = 1.9 },
	["Royal Stew"] = { notes = 5, speed = 1.8 },
	["Zunda Mochi"] = { notes = 5, speed = 1.7 },
	["Edamame Snack"] = { notes = 3, speed = 2.2 },
	["Fancy Pie"] = { notes = 6, speed = 1.6 },
	["Zundamon's Banquet"] = { notes = 7, speed = 1.5 },
	["Sweet Pea Cake"] = { notes = 5, speed = 1.7 },
	["Pea Flower Tea"] = { notes = 4, speed = 1.9 },
	["Ultimate Feast"] = { notes = 8, speed = 1.4 },
	["Zunda Paradise"] = { notes = 9, speed = 1.3 },
}
craft.defaultDifficulty = { notes = 4, speed = 1.8 }

-- ── Canon Companion Signature Recipes ────────────────────────────────────────

craft.recipes["Kiritandamon's Precision Cut Tempura"] = {
	["Zunda Leaf"] = 3,
	["Edamame Pod"] = 4,
	["Zunda Root"] = 2,
}
craft.recipes["Itakodamon's Oracle Root Broth"] = {
	["Zunda Root"] = 5,
	["Zunda Mushroom"] = 3,
	["Zunda Leaf"] = 2,
}
craft.recipes["Zunkodamon's Victory Feast"] = {
	["Edamame Pod"] = 5,
	["Zunda Mushroom"] = 4,
	["Zunda Berry"] = 3,
	["Wheat"] = 6,
}
craft.recipes["Zunabunny's Accidental Masterpiece"] = {
	["Zunda Pea"] = 3,
	["Sweet Pea"] = 2,
	["Pea Flower"] = 1,
}
craft.recipes["Nanonadamon's First Recipe"] = {
	["Zunda Pea"] = 10,
	["Pea Flower"] = 5,
	["Zunda Leaf"] = 5,
}

craft.cookingTimes["Kiritandamon's Precision Cut Tempura"] = 6
craft.cookingTimes["Itakodamon's Oracle Root Broth"] = 9
craft.cookingTimes["Zunkodamon's Victory Feast"] = 8
craft.cookingTimes["Zunabunny's Accidental Masterpiece"] = 3
craft.cookingTimes["Nanonadamon's First Recipe"] = 15

craft.difficulty["Kiritandamon's Precision Cut Tempura"] = { notes = 7, speed = 1.5 }
craft.difficulty["Itakodamon's Oracle Root Broth"] = { notes = 6, speed = 1.6 }
craft.difficulty["Zunkodamon's Victory Feast"] = { notes = 8, speed = 1.4 }
craft.difficulty["Zunabunny's Accidental Masterpiece"] = { notes = 2, speed = 2.5 }
craft.difficulty["Nanonadamon's First Recipe"] = { notes = 10, speed = 1.2 }

-- Shared quality calculation from per-note scores (used by client + server)
function craft.calculateQuality(scores, totalNotes)
	if #scores < totalNotes then
		return "ok"
	end
	local perfects, greats, hits = 0, 0, 0
	for _, s in ipairs(scores) do
		if s.tag == "perfect" then
			perfects = perfects + 1
			hits = hits + 1
		elseif s.tag == "great" then
			greats = greats + 1
			hits = hits + 1
		elseif s.tag == "good" then
			hits = hits + 1
		end
	end
	if perfects == totalNotes or perfects >= math.ceil(totalNotes * 0.6) then
		return "perfect"
	elseif hits >= math.ceil(totalNotes * 0.5) then
		return "great"
	else
		return "ok"
	end
end

return craft
