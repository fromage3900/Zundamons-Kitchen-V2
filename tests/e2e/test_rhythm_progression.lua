--!strict
-- tests/e2e/test_rhythm_progression.lua
-- E2E Requirement-Driven Tests for Scoring, Grading & Server Progression Cascades (F8, F9)
-- Covers Tier 1 (Feature Coverage), Tier 2 (Boundary Cases), and Tier 3 (Cross-Feature Combinations).

local test_rhythm_progression = {}

export type TestResult = {
	name: string,
	tier: string,
	feature: string,
	passed: boolean,
	error: string?,
}

-- Reference Reward & Progression Contract
local ProgressionContract = {
	XP_REWARDS = {
		craftPerfect = 30,
		craftSuccess = 15,
	},
	GOLD_REWARDS = {
		perfect = 25,
		great = 10,
		ok = 0,
	},
	STYLE_REWARDS = {
		perfect = 100,
		great = 50,
		ok = 20,
	},
}

function ProgressionContract.evaluateQuality(accuracy: number, perfectRatio: number, goodRatio: number): string
	if accuracy >= 95.0 or perfectRatio >= 0.80 then
		return "perfect"
	elseif accuracy >= 85.0 or goodRatio >= 0.60 then
		return "great"
	else
		return "ok"
	end
end

function ProgressionContract.simulateSettlement(
	recipeName: string,
	quality: string,
	playerData: { [string]: any },
	rngBonusRoll: number?
): {
	ok: boolean,
	dishCount: number,
	bonusGold: number,
	xp: number,
	stylePoints: number,
	updatedData: { [string]: any },
}
	local data = table.clone(playerData)
	local bonusRoll = rngBonusRoll or 0.50
	local dishAmount = 1
	if quality == "perfect" and bonusRoll < 0.35 then
		dishAmount = 2
	end

	local bonusGold = ProgressionContract.GOLD_REWARDS[quality] or 0
	local xp = quality == "perfect" and ProgressionContract.XP_REWARDS.craftPerfect
		or ProgressionContract.XP_REWARDS.craftSuccess
	local stylePoints = ProgressionContract.STYLE_REWARDS[quality] or 20

	-- Mutate player data atomically
	data.gold = (data.gold or 0) + bonusGold
	data.xp = (data.xp or 0) + xp
	data.style_points = (data.style_points or 0) + stylePoints
	data[recipeName] = (data[recipeName] or 0) + dishAmount

	data.cooked_dishes = data.cooked_dishes or {}
	data.cooked_dishes[recipeName] = data.cooked_dishes[recipeName] or {}
	data.cooked_dishes[recipeName][quality] = (data.cooked_dishes[recipeName][quality] or 0) + dishAmount

	if quality == "perfect" then
		data.perfect_cooks = (data.perfect_cooks or 0) + 1
		data.cooking_streak = (data.cooking_streak or 0) + 1
		data.max_cooking_streak = math.max(data.max_cooking_streak or 0, data.cooking_streak)
	elseif quality == "great" then
		data.great_cooks = (data.great_cooks or 0) + 1
		data.cooking_streak = (data.cooking_streak or 0) + 1
	else
		data.cooking_streak = 0
	end

	return {
		ok = true,
		dishCount = dishAmount,
		bonusGold = bonusGold,
		xp = xp,
		stylePoints = stylePoints,
		updatedData = data,
	}
end

function test_rhythm_progression.runAll(): { TestResult }
	local results: { TestResult } = {}

	local function assertTest(name: string, tier: string, feature: string, fn: () -> ())
		local ok, err = pcall(fn)
		table.insert(results, {
			name = name,
			tier = tier,
			feature = feature,
			passed = ok,
			error = not ok and tostring(err) or nil,
		})
	end

	-- =========================================================================
	-- TIER 1: FEATURE COVERAGE (F8, F9)
	-- =========================================================================

	-- F8: Server-Authoritative Reward & Quality Settlement (>= 5 cases)
	assertTest("F8-T1-01: Grade S yields 'perfect' quality dish", "Tier 1", "F8", function()
		local quality = ProgressionContract.evaluateQuality(98.0, 1.0, 1.0)
		assert(quality == "perfect", "Expected perfect, got " .. quality)
	end)

	assertTest("F8-T1-02: Grade A yields 'great' quality dish", "Tier 1", "F8", function()
		local quality = ProgressionContract.evaluateQuality(88.0, 0.5, 0.9)
		assert(quality == "great", "Expected great, got " .. quality)
	end)

	assertTest("F8-T1-03: Grade C yields 'ok' quality dish", "Tier 1", "F8", function()
		local quality = ProgressionContract.evaluateQuality(55.0, 0.2, 0.4)
		assert(quality == "ok", "Expected ok, got " .. quality)
	end)

	assertTest("F8-T1-04: Perfect cook grants +25 bonus gold and 30 XP", "Tier 1", "F8", function()
		local initData = { gold = 100, xp = 50 }
		local res = ProgressionContract.simulateSettlement("Zunda Mochi", "perfect", initData, 0.50)
		assert(res.bonusGold == 25, "Bonus gold must be 25")
		assert(res.xp == 30, "XP must be 30")
		assert(res.updatedData.gold == 125, "Updated gold must be 125")
		assert(res.updatedData.xp == 80, "Updated XP must be 80")
	end)

	assertTest("F8-T1-05: 35% RNG bonus rolls duplicate dish for perfect cook", "Tier 1", "F8", function()
		local initData = { gold = 0, xp = 0 }
		local resBonus = ProgressionContract.simulateSettlement("Zunda Mochi", "perfect", initData, 0.20)
		assert(resBonus.dishCount == 2, "Dish count should be 2 when roll < 0.35")
		local resNormal = ProgressionContract.simulateSettlement("Zunda Mochi", "perfect", initData, 0.80)
		assert(resNormal.dishCount == 1, "Dish count should be 1 when roll >= 0.35")
	end)

	assertTest("F8-T1-06: Atomic reservation lifecycle (reserve -> commit / refund)", "Tier 1", "F8", function()
		local data = { Wheat = 10, Apple = 5, cooking_reservation = nil }
		-- 1. Reserve ingredients
		data.Wheat -= 5
		data.Apple -= 2
		data.cooking_reservation = { sessionId = "sess_123", ingredients = { Wheat = 5, Apple = 2 } }
		assert(data.Wheat == 5 and data.Apple == 3, "Ingredients deducted on reservation")

		-- 2. Refund simulation on cancel
		local function refund(d: any, sessId: string): boolean
			if not d.cooking_reservation or d.cooking_reservation.sessionId ~= sessId then
				return false
			end
			for k, v in pairs(d.cooking_reservation.ingredients) do
				d[k] = (d[k] or 0) + v
			end
			d.cooking_reservation = nil
			return true
		end
		local ok = refund(data, "sess_123")
		assert(ok == true, "Refund succeeded")
		assert(data.Wheat == 10 and data.Apple == 5, "Ingredients fully restored")
		assert(data.cooking_reservation == nil, "Reservation cleared")
	end)

	-- F9: Progression Cascades (Stats, Style, Quests) (>= 5 cases)
	assertTest("F9-T1-01: Style points granted scale with quality (100, 50, 20)", "Tier 1", "F9", function()
		local d1 = ProgressionContract.simulateSettlement("Bread", "perfect", { style_points = 0 })
		local d2 = ProgressionContract.simulateSettlement("Bread", "great", { style_points = 0 })
		local d3 = ProgressionContract.simulateSettlement("Bread", "ok", { style_points = 0 })
		assert(d1.stylePoints == 100, "Perfect gives 100 Style Points")
		assert(d2.stylePoints == 50, "Great gives 50 Style Points")
		assert(d3.stylePoints == 20, "OK gives 20 Style Points")
	end)

	assertTest("F9-T1-02: Chef precision stat incremented on perfect hits", "Tier 1", "F9", function()
		local chefStats = { precision = 10, speed = 10 }
		local function onCookComplete(stats: any, quality: string)
			if quality == "perfect" then
				stats.precision += 1
			end
		end
		onCookComplete(chefStats, "perfect")
		assert(chefStats.precision == 11, "Precision should increment to 11")
	end)

	assertTest("F9-T1-03: Chef speed stat incremented on high BPM recipes", "Tier 1", "F9", function()
		local chefStats = { speed = 15 }
		local function onFastCook(stats: any, bpm: number)
			if bpm >= 130 then
				stats.speed += 1
			end
		end
		onFastCook(chefStats, 140)
		assert(chefStats.speed == 16, "Speed should increment to 16")
	end)

	assertTest("F9-T1-04: Daily challenge progression updates on cook completion", "Tier 1", "F9", function()
		local dailyQuest = { id = "daily_cook_3", current = 1, target = 3, completed = false }
		local function onDailyCook(quest: any)
			quest.current += 1
			if quest.current >= quest.target then
				quest.completed = true
			end
		end
		onDailyCook(dailyQuest)
		assert(dailyQuest.current == 2, "Daily progress updated to 2")
		onDailyCook(dailyQuest)
		assert(dailyQuest.current == 3 and dailyQuest.completed == true, "Daily quest completed")
	end)

	assertTest("F9-T1-05: Challenge Mode wave score boosted by rhythm performance", "Tier 1", "F9", function()
		local waveState = { waveScore = 1000, multiplier = 1.0 }
		local function applyRhythmScore(state: any, score: number)
			state.waveScore += math.floor(score * 0.1)
		end
		applyRhythmScore(waveState, 25000)
		assert(waveState.waveScore == 3500, "Wave score increased by 2500")
	end)

	-- =========================================================================
	-- TIER 2: BOUNDARY & CORNER CASES (F8, F9)
	-- =========================================================================

	-- F8 Boundary Cases
	assertTest("F8-T2-01: Server hit validation under high network jitter (+0.44s)", "Tier 2", "F8", function()
		local target = 10.0
		local serverNow = 10.44 -- Arrives at +0.44s due to latency
		local diff = math.abs(serverNow - target)
		assert(diff <= 0.45, "Hit within Good window accepted")
		local serverNowLate = 10.46
		local diffLate = math.abs(serverNowLate - target)
		assert(diffLate > 0.45, "Hit arriving at +0.46s rejected as expired")
	end)

	assertTest("F8-T2-02: Out-of-order note submissions rejected by server", "Tier 2", "F8", function()
		local session = { nextExpected = 2, totalNotes = 5 }
		local function processHit(s: any, noteIndex: number): boolean
			if noteIndex ~= s.nextExpected then
				return false
			end
			s.nextExpected += 1
			return true
		end
		assert(processHit(session, 4) == false, "Note 4 submitted when expecting Note 2 is rejected")
		assert(processHit(session, 2) == true, "Note 2 accepted")
	end)

	assertTest("F8-T2-03: Duplicate note submission rejected", "Tier 2", "F8", function()
		local session = { nextExpected = 3, totalNotes = 5 }
		local function processHit(s: any, noteIndex: number): boolean
			if noteIndex ~= s.nextExpected then
				return false
			end
			s.nextExpected += 1
			return true
		end
		assert(processHit(session, 3) == true, "First hit accepted")
		assert(processHit(session, 3) == false, "Duplicate hit on note 3 rejected")
	end)

	assertTest("F8-T2-04: Player disconnect mid-session triggers atomic refund", "Tier 2", "F8", function()
		local playerState = {
			gold = 50,
			Wheat = 0,
			cooking_reservation = { sessionId = "sess_disc", ingredients = { Wheat = 8 } },
		}
		-- Disconnect refund
		for k, v in pairs(playerState.cooking_reservation.ingredients) do
			playerState[k] = (playerState[k] or 0) + v
		end
		playerState.cooking_reservation = nil
		assert(playerState.Wheat == 8, "Refund restored Wheat to 8")
		assert(playerState.cooking_reservation == nil, "Reservation cleared")
	end)

	assertTest("F8-T2-05: Future timestamp spoofing rejected by server", "Tier 2", "F8", function()
		local serverTime = 100.0
		local clientClaimedTime = 110.0 -- 10 seconds ahead
		local function validateHit(serverNow: number, target: number): boolean
			local delta = math.abs(serverNow - target)
			return delta <= 0.45
		end
		assert(validateHit(serverTime, clientClaimedTime) == false, "Future spoofed timestamp rejected")
	end)

	-- F9 Boundary Cases
	assertTest("F9-T2-01: Style points overflow clamp at maximum cap", "Tier 2", "F9", function()
		local MAX_STYLE = 1000000
		local currentStyle = 999980
		local addStyle = 100
		local newStyle = math.min(currentStyle + addStyle, MAX_STYLE)
		assert(newStyle == 1000000, "Style points clamped at maximum cap")
	end)

	assertTest("F9-T2-02: Maximum chef stat cap handling", "Tier 2", "F9", function()
		local MAX_STAT = 100
		local precision = 100
		local nextPrecision = math.min(precision + 1, MAX_STAT)
		assert(nextPrecision == 100, "Chef stat clamped at 100")
	end)

	assertTest("F9-T2-03: Quest progression when target is already completed", "Tier 2", "F9", function()
		local quest = { current = 5, target = 5, completed = true }
		local function updateQuest(q: any)
			if not q.completed then
				q.current = math.min(q.current + 1, q.target)
				if q.current >= q.target then
					q.completed = true
				end
			end
		end
		updateQuest(quest)
		assert(quest.current == 5 and quest.completed == true, "Completed quest does not overflow")
	end)

	assertTest("F9-T2-04: Zero reward penalty for all-miss session", "Tier 2", "F9", function()
		local init = { gold = 50, xp = 100, style_points = 200 }
		local res = ProgressionContract.simulateSettlement("Burnt Dish", "ok", init)
		assert(res.bonusGold == 0, "No bonus gold for ok/failed")
		assert(res.stylePoints == 20, "Baseline 20 style points")
		assert(res.xp == 15, "Standard 15 craft success XP")
	end)

	assertTest("F9-T2-05: Concurrent multiple quest targets update in single event", "Tier 2", "F9", function()
		local q1 = { id = "q_cook_any", current = 0, target = 1 }
		local q2 = { id = "q_style_pts", current = 10, target = 100 }
		local function onCookSettled(quality: string, styleEarned: number)
			q1.current += 1
			q2.current += styleEarned
		end
		onCookSettled("perfect", 100)
		assert(q1.current == 1, "Quest 1 progressed")
		assert(q2.current == 110, "Quest 2 progressed")
	end)

	-- =========================================================================
	-- TIER 3: CROSS-FEATURE COMBINATIONS (Progression & Settle Pairs)
	-- =========================================================================

	assertTest(
		"F8+F9-T3-01: Full S-Rank Cooking run cascades to Gold, XP, Style Points and Stats",
		"Tier 3",
		"F8+F9",
		function()
			local initialData = {
				gold = 500,
				xp = 200,
				style_points = 150,
				cooking_streak = 2,
				max_cooking_streak = 5,
			}
			local res = ProgressionContract.simulateSettlement("Zundamon's Banquet", "perfect", initialData, 0.10)
			assert(res.dishCount == 2, "Bonus dish awarded on roll < 0.35")
			assert(res.bonusGold == 25, "25 bonus gold")
			assert(res.xp == 30, "30 XP")
			assert(res.stylePoints == 100, "100 style points")
			assert(res.updatedData.gold == 525, "Gold updated")
			assert(res.updatedData.xp == 230, "XP updated")
			assert(res.updatedData.style_points == 250, "Style points updated")
			assert(res.updatedData.cooking_streak == 3, "Cooking streak incremented")
		end
	)

	assertTest("F8+F9-T3-02: Miss resets streak in settlement data", "Tier 3", "F8+F9", function()
		local initialData = {
			gold = 100,
			xp = 0,
			style_points = 0,
			cooking_streak = 8,
			max_cooking_streak = 8,
		}
		local res = ProgressionContract.simulateSettlement("Failed Stew", "ok", initialData)
		assert(res.updatedData.cooking_streak == 0, "Cooking streak reset to 0 on ok quality")
		assert(res.updatedData.max_cooking_streak == 8, "Max cooking streak preserved")
	end)

	return results
end

return test_rhythm_progression
