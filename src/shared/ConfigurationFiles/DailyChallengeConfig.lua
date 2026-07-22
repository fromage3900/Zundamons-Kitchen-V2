-- [[ModuleScript] DailyChallengeConfig]]
-- Daily challenge system inspired by Uma Musume's daily races.
-- 3 rotating daily challenges + weekly boss challenge.
-- Applies Infinity Nikki aesthetic: dreamy, magical girl, fashion-forward.

local DailyChallengeConfig = {}

-- ── Daily Challenge Pool ────────────────────────────────────────────────────
-- Each day, 3 challenges are selected from this pool.
-- Like Uma Musume's daily races, they rotate and provide varied objectives.

DailyChallengeConfig.dailyPool = {
	-- Cooking challenges
	{
		id = "dc_perfect_3",
		title = "Perfect Timing",
		description = "Cook 3 dishes with PERFECT timing",
		icon = "🎯",
		metric = "perfect",
		goal = 3,
		reward = { gold = 120, xp = 100, style = 15 },
		difficulty = 2,
	},
	{
		id = "dc_cook_5",
		title = "Cooking Spree",
		description = "Cook 5 dishes",
		icon = "🍳",
		metric = "cook",
		goal = 5,
		reward = { gold = 80, xp = 60, style = 10 },
		difficulty = 1,
	},
	{
		id = "dc_perfect_5",
		title = "Flawless Chef",
		description = "Cook 5 PERFECT dishes",
		icon = "✨",
		metric = "perfect",
		goal = 5,
		reward = { gold = 200, xp = 150, style = 25 },
		difficulty = 3,
	},

	-- Serving challenges
	{
		id = "dc_serve_5",
		title = "Hospitality Hero",
		description = "Serve 5 guests",
		icon = "🍽️",
		metric = "serve",
		goal = 5,
		reward = { gold = 100, xp = 80, style = 12 },
		difficulty = 1,
	},
	{
		id = "dc_serve_10",
		title = "Service Pro",
		description = "Serve 10 guests",
		icon = "⭐",
		metric = "serve",
		goal = 10,
		reward = { gold = 180, xp = 120, style = 20 },
		difficulty = 2,
	},
	{
		id = "dc_combo_5",
		title = "Combo Master",
		description = "Hit a 5x combo",
		icon = "🔥",
		metric = "combo",
		goal = 5,
		reward = { gold = 150, xp = 100, style = 20 },
		difficulty = 2,
	},
	{
		id = "dc_combo_8",
		title = "Combo Legend",
		description = "Hit an 8x combo",
		icon = "💫",
		metric = "combo",
		goal = 8,
		reward = { gold = 250, xp = 180, style = 30 },
		difficulty = 3,
	},

	-- Gathering challenges
	{
		id = "dc_gather_10",
		title = "Gatherer",
		description = "Gather 10 ingredients",
		icon = "🫛",
		metric = "gather",
		goal = 10,
		reward = { gold = 60, xp = 50, style = 8 },
		difficulty = 1,
	},
	{
		id = "dc_gather_20",
		title = "Resource Pro",
		description = "Gather 20 ingredients",
		icon = "🌿",
		metric = "gather",
		goal = 20,
		reward = { gold = 120, xp = 100, style = 15 },
		difficulty = 2,
	},

	-- Gold challenges
	{
		id = "dc_gold_250",
		title = "Coin Collector",
		description = "Earn 250 gold",
		icon = "🪙",
		metric = "earn_gold",
		goal = 250,
		reward = { gold = 50, xp = 40, style = 10 },
		difficulty = 1,
	},
	{
		id = "dc_gold_500",
		title = "Gold Rush",
		description = "Earn 500 gold",
		icon = "💰",
		metric = "earn_gold",
		goal = 500,
		reward = { gold = 100, xp = 80, style = 20 },
		difficulty = 2,
	},

	-- Challenge mode
	{
		id = "dc_challenge_wave_3",
		title = "Wave Rider",
		description = "Complete 3 Challenge Mode waves",
		icon = "🌊",
		metric = "challenge_wave",
		goal = 3,
		reward = { gold = 300, xp = 200, style = 40 },
		difficulty = 3,
	},
	{
		id = "dc_challenge_score_500",
		title = "Score Chaser",
		description = "Score 500 points in Challenge Mode",
		icon = "📊",
		metric = "challenge_score",
		goal = 500,
		reward = { gold = 250, xp = 150, style = 30 },
		difficulty = 2,
	},

	-- Infinity Nikki themed challenges
	{
		id = "dc_style_50",
		title = "Stylish Cook",
		description = "Earn 50 style points",
		icon = "💖",
		metric = "style_points",
		goal = 50,
		reward = { gold = 100, xp = 80, style = 25 },
		difficulty = 2,
	},
	{
		id = "dc_outfit_1",
		title = "Fashion Forward",
		description = "Unlock 1 companion outfit",
		icon = "👗",
		metric = "outfit_collect",
		goal = 1,
		reward = { gold = 150, xp = 100, style = 30 },
		difficulty = 2,
	},
}

-- ── Weekly Boss Challenge ────────────────────────────────────────────────────
-- Like Uma Musume's championship races — a harder challenge that resets weekly.

DailyChallengeConfig.weeklyBoss = {
	{
		id = "wc_zunda_rush",
		title = "Zunda Paradise Rush",
		description = "Serve 5 Zunda Paradise dishes in Challenge Mode",
		icon = "🫛",
		metric = "challenge_recipe",
		goal = 5,
		recipe = "Zunda Paradise",
		reward = { gold = 1000, xp = 500, style = 100, items = { "Zundamon's Banquet" } },
		difficulty = 5,
	},
	{
		id = "wc_perfect_50",
		title = "Perfectionist",
		description = "Cook 50 PERFECT dishes this week",
		icon = "👑",
		metric = "perfect",
		goal = 50,
		reward = { gold = 800, xp = 400, style = 80, items = { "Golden Harvest Platter" } },
		difficulty = 5,
	},
	{
		id = "wc_wave_20",
		title = "Endless Wave",
		description = "Reach wave 20 in Challenge Mode",
		icon = "🌊",
		metric = "challenge_wave",
		goal = 20,
		reward = { gold = 1200, xp = 600, style = 120, items = { "Ultimate Feast" } },
		difficulty = 5,
	},
}

-- ── Streak Rewards ──────────────────────────────────────────────────────────
-- Completing all 3 daily challenges gives a streak bonus.

DailyChallengeConfig.streakRewards = {
	{ streak = 1,  reward = { gold = 50,  xp = 40,  style = 10 } },
	{ streak = 3,  reward = { gold = 150, xp = 100, style = 30, items = { "Zunda Berry" } } },
	{ streak = 5,  reward = { gold = 300, xp = 200, style = 60, items = { "Sweet Pea" } } },
	{ streak = 7,  reward = { gold = 500, xp = 300, style = 100, items = { "Zunda Mochi" } } },
	{ streak = 14, reward = { gold = 1000, xp = 500, style = 200, items = { "Pea Flower" } } },
	{ streak = 30, reward = { gold = 2500, xp = 1000, style = 500, items = { "Zunda Paradise" } } },
}

-- ── Daily Login Bonus ───────────────────────────────────────────────────────

DailyChallengeConfig.loginBonus = {
	baseGold = 50,
	streakBonus = 25,
	capDays = 7,
}

-- ── Daily Visitor (Nikki the Drifter — Infinity Nikki reference) ───────────

DailyChallengeConfig.dailyVisitor = {
	npcId = "rbxassetid://128478553136178",
	npcName = "Nikki the Drifter",
	spawnPoint = Vector3.new(192, -518, -408),
	reward = { gold = 100, xp = 80, item = "Zunda Flower" },
	dialogueMorning = {
		"The morning breeze carries whispers of adventure... 🌄",
		"I've traveled far to taste your cooking today!",
		"A new day, a new recipe to discover~ ✨",
		"The stars align for a perfect cook today, chef~ 💫",
	},
	dialogueEvening = {
		"The stars are out... time for a warm meal! 🌙",
		"Evening is the best time for comfort food.",
		"The day's journey ends with a full belly~ 🌟",
		"Your kitchen glows like a magical girl's transformation! ✨",
	},
}

-- ── Daily Resources ─────────────────────────────────────────────────────────

DailyChallengeConfig.dailyResources = {
	{ resourceType = "Zunda Flower", count = 3, meshHint = "ZundaFlower_Rare" },
	{ resourceType = "Zunda Pea",    count = 5, meshHint = "ZundaPea_02" },
	{ resourceType = "Sweet Pea",    count = 3, meshHint = "SweetPea_01" },
	{ resourceType = "Pea Flower",   count = 2, meshHint = "PeaFlower_01" },
}

-- ── Helper Functions ────────────────────────────────────────────────────────

function DailyChallengeConfig.selectDailyChallenges(): any
	-- Select 3 random challenges from the pool
	local selected = {}
	local poolCopy = {}
	for _, challenge in ipairs(DailyChallengeConfig.dailyPool) do
		table.insert(poolCopy, challenge)
	end

	-- Shuffle and pick 3
	for i = #poolCopy, 2, -1 do
		local j = math.random(1, i)
		poolCopy[i], poolCopy[j] = poolCopy[j], poolCopy[i]
	end

	for i = 1, math.min(3, #poolCopy) do
		table.insert(selected, poolCopy[i])
	end

	return selected
end

function DailyChallengeConfig.getWeeklyBoss(): table
	-- Rotate weekly boss based on day of year
	local dayOfYear = tonumber(os.date("%j")) or 1
	local index = ((dayOfYear - 1) % #DailyChallengeConfig.weeklyBoss) + 1
	return DailyChallengeConfig.weeklyBoss[index]
end

function DailyChallengeConfig.getStreakReward(streak: number): { gold: number, xp: number, style: number, items: { string }? }
	for i = #DailyChallengeConfig.streakRewards, 1, -1 do
		local reward = DailyChallengeConfig.streakRewards[i]
		if streak >= reward.streak then
			return reward.reward
		end
	end
	return { gold = 0, xp = 0, style = 0 }
end

return DailyChallengeConfig
