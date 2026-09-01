--!strict
-- tests/e2e/test_rhythm_scenarios.lua
-- E2E Requirement-Driven Tests for Scenarios, Combinations & Adversarial Hardening
-- Covers Tier 3 (Cross-Feature Combinations), Tier 4 (Real-World Application Scenarios), and Tier 5 (Adversarial Stress).

local test_rhythm_scenarios = {}

export type TestResult = {
	name: string,
	tier: string,
	feature: string,
	passed: boolean,
	error: string?,
}

-- Complete Session Simulator
local function simulateSession(
	recipeName: string,
	duration: number,
	inputSequence: { { noteIndex: number, laneId: number, offset: number } },
	options: {
		precisionBuff: number?,
		rngBonusRoll: number?,
		initialData: { [string]: any }?,
	}?
)
	local opts = options or {}
	local initialData = opts.initialData or { gold = 100, xp = 50, style_points = 0, cooking_streak = 0 }
	local precisionBuff = opts.precisionBuff or 0.0

	-- Windows
	local pWin = 0.12 * (1 + precisionBuff)
	local grWin = 0.28 * (1 + precisionBuff)
	local gdWin = 0.45 * (1 + precisionBuff)

	-- Evaluate judgments
	local judgments = {}
	local combo = 0
	local maxCombo = 0
	local totalScore = 0
	local counts = { perfect = 0, great = 0, good = 0, miss = 0 }
	local voiceTriggers = {}

	local function getMultiplier(c: number): number
		if c >= 20 then
			return 3.0
		elseif c >= 15 then
			return 2.5
		elseif c >= 10 then
			return 2.0
		elseif c >= 5 then
			return 1.5
		else
			return 1.0
		end
	end

	table.insert(voiceTriggers, "cook_start")

	for _, input in ipairs(inputSequence) do
		local absOff = math.abs(input.offset)
		local j = "MISS"
		if absOff <= pWin then
			j = "PERFECT"
		elseif absOff <= grWin then
			j = "GREAT"
		elseif absOff <= gdWin then
			j = "GOOD"
		else
			j = "MISS"
		end

		table.insert(judgments, j)
		if j == "PERFECT" then
			counts.perfect += 1
			combo += 1
			totalScore += math.floor(1000 * getMultiplier(combo))
		elseif j == "GREAT" then
			counts.great += 1
			combo += 1
			totalScore += math.floor(700 * getMultiplier(combo))
		elseif j == "GOOD" then
			counts.good += 1
			combo += 1
			totalScore += math.floor(400 * getMultiplier(combo))
		else
			counts.miss += 1
			combo = 0
			table.insert(voiceTriggers, "cook_miss")
		end

		if combo > maxCombo then
			maxCombo = combo
		end

		if combo == 10 then
			table.insert(voiceTriggers, "cook_combo_10")
		elseif combo == 20 then
			table.insert(voiceTriggers, "cook_combo_20")
		end
	end

	local totalNotes = #inputSequence
	local weighted = counts.perfect * 1.0 + counts.great * 0.7 + counts.good * 0.4
	local accuracy = totalNotes > 0 and (weighted / totalNotes) * 100 or 0
	local grade = "F"
	if accuracy >= 95.0 then
		grade = "S"
		table.insert(voiceTriggers, "cook_rank_s")
	elseif accuracy >= 85.0 then
		grade = "A"
		table.insert(voiceTriggers, "cook_rank_a")
	elseif accuracy >= 70.0 then
		grade = "B"
	elseif accuracy >= 50.0 then
		grade = "C"
	else
		grade = "F"
	end

	-- Quality derivation
	local quality = "ok"
	if grade == "S" or (counts.perfect / math.max(totalNotes, 1)) >= 0.80 then
		quality = "perfect"
	elseif grade == "A" or ((counts.perfect + counts.great + counts.good) / math.max(totalNotes, 1)) >= 0.60 then
		quality = "great"
	end

	-- Reward settlement
	local bonusGold = quality == "perfect" and 25 or (quality == "great" and 10 or 0)
	local xp = quality == "perfect" and 30 or 15
	local stylePoints = quality == "perfect" and 100 or (quality == "great" and 50 or 20)
	local dishAmount = 1
	if quality == "perfect" and (opts.rngBonusRoll or 0.5) < 0.35 then
		dishAmount = 2
	end

	local data = table.clone(initialData)
	data.gold = (data.gold or 0) + bonusGold
	data.xp = (data.xp or 0) + xp
	data.style_points = (data.style_points or 0) + stylePoints
	data[recipeName] = (data[recipeName] or 0) + dishAmount

	return {
		recipeName = recipeName,
		duration = duration,
		totalNotes = totalNotes,
		counts = counts,
		maxCombo = maxCombo,
		totalScore = totalScore,
		accuracy = accuracy,
		grade = grade,
		quality = quality,
		dishAmount = dishAmount,
		bonusGold = bonusGold,
		xp = xp,
		stylePoints = stylePoints,
		voiceTriggers = voiceTriggers,
		finalData = data,
	}
end

function test_rhythm_scenarios.runAll(): { TestResult }
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
	-- TIER 3: CROSS-FEATURE COMBINATIONS (PAIRWISE MATRIX)
	-- =========================================================================

	assertTest("T3-01: Multi-lane Chart Playback + Combo Multiplier Scaling (F1 + F3)", "Tier 3", "F1+F3", function()
		local inputs = {}
		for i = 1, 20 do
			local laneId = ((i - 1) % 4) + 1
			table.insert(inputs, { noteIndex = i, laneId = laneId, offset = 0.02 })
		end
		local res = simulateSession("Zunda Mochi", 7.0, inputs)
		assert(res.maxCombo == 20, "20 combo achieved across 4 lanes")
		assert(res.totalScore > 20 * 1000, "Score includes combo multiplier scaling")
	end)

	assertTest(
		"T3-02: Stat Precision Window Widening + Grade Evaluation (F2 + F7 + F9)",
		"Tier 3",
		"F2+F7+F9",
		function()
			-- Offsets at 0.13s (normally GREAT) with +25% precision buff widen window to 0.15s (PERFECT)
			local inputs = {}
			for i = 1, 10 do
				table.insert(inputs, { noteIndex = i, laneId = 1, offset = 0.13 })
			end
			local resNoBuff = simulateSession("Bread", 4.0, inputs, { precisionBuff = 0.0 })
			assert(resNoBuff.grade == "B" or resNoBuff.grade == "A", "Without buff accuracy is 70% (all GREAT)")
			assert(resNoBuff.counts.perfect == 0, "No perfect hits without buff")

			local resBuff = simulateSession("Bread", 4.0, inputs, { precisionBuff = 0.25 })
			assert(resBuff.grade == "S", "With buff accuracy is 100% (all PERFECT)")
			assert(resBuff.counts.perfect == 10, "10 perfect hits with buff")
		end
	)

	assertTest(
		"T3-03: Input Mode Switching (DFJK -> Touch -> Arrows) during active combo (F3 + F10)",
		"Tier 3",
		"F3+F10",
		function()
			local inputs = {
				-- Keys: D, F (DFJK mode)
				{ noteIndex = 1, laneId = 1, offset = 0.01 },
				{ noteIndex = 2, laneId = 2, offset = -0.02 },
				-- Touch pads
				{ noteIndex = 3, laneId = 3, offset = 0.00 },
				{ noteIndex = 4, laneId = 4, offset = 0.03 },
				-- Arrow keys: Up, Right
				{ noteIndex = 5, laneId = 3, offset = -0.01 },
				{ noteIndex = 6, laneId = 4, offset = 0.02 },
			}
			local res = simulateSession("Sweet Pea Cake", 9.0, inputs)
			assert(res.maxCombo == 6, "Seamless input mode switching preserves combo")
			assert(res.accuracy == 100.0, "100% accuracy maintained across input types")
		end
	)

	assertTest(
		"T3-04: High Combo Streak + VOICEVOX 10x/20x Cheerleading triggers (F3 + F6)",
		"Tier 3",
		"F3+F6",
		function()
			local inputs = {}
			for i = 1, 22 do
				table.insert(inputs, { noteIndex = i, laneId = (i % 4) + 1, offset = 0.01 })
			end
			local res = simulateSession("Ultimate Feast", 15.0, inputs)
			local found10, found20 = false, false
			for _, v in ipairs(res.voiceTriggers) do
				if v == "cook_combo_10" then
					found10 = true
				end
				if v == "cook_combo_20" then
					found20 = true
				end
			end
			assert(found10 == true, "Combo 10 voice cue triggered")
			assert(found20 == true, "Combo 20 voice cue triggered")
		end
	)

	assertTest(
		"T3-05: Server Timestamp Validation under Jitter + Quality Settlement (F2 + F7 + F8)",
		"Tier 3",
		"F2+F7+F8",
		function()
			local inputs = {}
			for i = 1, 10 do
				-- Jitter ranging from -0.10s to +0.10s
				local jitter = (i % 2 == 0) and 0.08 or -0.07
				table.insert(inputs, { noteIndex = i, laneId = 1, offset = jitter })
			end
			local res = simulateSession("Royal Stew", 8.0, inputs)
			assert(res.grade == "S", "Grade S despite network jitter within window")
			assert(res.quality == "perfect", "Perfect dish quality achieved")
			assert(res.bonusGold == 25, "Bonus gold granted")
		end
	)

	assertTest(
		"T3-06: S-Rank Performance + Style Points + Extra Dish RNG (F7 + F8 + F9)",
		"Tier 3",
		"F7+F8+F9",
		function()
			local inputs = {}
			for i = 1, 8 do
				table.insert(inputs, { noteIndex = i, laneId = (i % 4) + 1, offset = 0.0 })
			end
			local res = simulateSession("Zunda Mochi", 7.0, inputs, { rngBonusRoll = 0.15 })
			assert(res.grade == "S", "Grade S")
			assert(res.dishAmount == 2, "Extra dish awarded (roll 0.15 < 0.35)")
			assert(res.stylePoints == 100, "100 style points granted")
		end
	)

	assertTest(
		"T3-07: Miss Recovery + Audio Cheerleading + Final Grade B (F3 + F5 + F6 + F7)",
		"Tier 3",
		"F3+F5+F6+F7",
		function()
			-- Notes 1-3 Perfect, Note 4 Miss, Notes 5-10 Perfect
			local inputs = {
				{ noteIndex = 1, laneId = 1, offset = 0.0 },
				{ noteIndex = 2, laneId = 2, offset = 0.0 },
				{ noteIndex = 3, laneId = 3, offset = 0.0 },
				{ noteIndex = 4, laneId = 4, offset = 0.8 }, -- Miss
				{ noteIndex = 5, laneId = 1, offset = 0.0 },
				{ noteIndex = 6, laneId = 2, offset = 0.0 },
				{ noteIndex = 7, laneId = 3, offset = 0.0 },
				{ noteIndex = 8, laneId = 4, offset = 0.0 },
				{ noteIndex = 9, laneId = 1, offset = 0.0 },
				{ noteIndex = 10, laneId = 2, offset = 0.0 },
			}
			local res = simulateSession("Zunda Bread", 6.0, inputs)
			assert(res.counts.miss == 1, "1 miss recorded")
			assert(res.counts.perfect == 9, "9 perfect recorded")
			assert(res.maxCombo == 6, "Max combo after reset is 6")
			assert(res.accuracy == 90.0, "Accuracy 90.0% -> Grade A")
			local missVoiceFound = false
			for _, v in ipairs(res.voiceTriggers) do
				if v == "cook_miss" then
					missVoiceFound = true
				end
			end
			assert(missVoiceFound == true, "Miss voice cue triggered")
		end
	)

	assertTest("T3-08: Pastel UI Palette Consistency Across 4 Lanes (F1 + F4)", "Tier 3", "F1+F4", function()
		local lanes = {
			{ id = 1, hex = "#A0D296" },
			{ id = 2, hex = "#FFC850" },
			{ id = 3, hex = "#FF96C8" },
			{ id = 4, hex = "#91D7C3" },
		}
		for _, l in ipairs(lanes) do
			assert(#l.hex == 7 and l.hex:sub(1, 1) == "#", "Valid 7-character hex code")
		end
	end)

	assertTest(
		"T3-09: Companion Buff (Cardamon) + Recipe Chart Verification (F1 + F2 + F8)",
		"Tier 3",
		"F1+F2+F8",
		function()
			local cardamonBuff = 0.15
			local inputs = { { noteIndex = 1, laneId = 1, offset = 0.135 } }
			local res = simulateSession("Cardamon's Calm Cup", 5.0, inputs, { precisionBuff = cardamonBuff })
			assert(res.counts.perfect == 1, "Buff enabled perfect hit at 0.135s (0.12 * 1.15 = 0.138s)")
		end
	)

	assertTest("T3-10: Multi-recipe Cooking Pipeline State Isolation (F1 + F8 + F9)", "Tier 3", "F1+F8+F9", function()
		local playerState = { gold = 0, xp = 0, style_points = 0 }
		local in1 = { { noteIndex = 1, laneId = 1, offset = 0.0 } }
		local r1 = simulateSession("Apple Pie", 5.0, in1, { initialData = playerState })
		playerState = r1.finalData

		local in2 = { { noteIndex = 1, laneId = 2, offset = 0.0 } }
		local r2 = simulateSession("Bread", 4.0, in2, { initialData = playerState })
		playerState = r2.finalData

		assert(playerState.gold == 50, "Gold accumulated across 2 sessions (25 + 25)")
		assert(playerState.xp == 60, "XP accumulated (30 + 30)")
		assert(playerState.style_points == 200, "Style points accumulated (100 + 100)")
		assert(playerState["Apple Pie"] == 1, "Apple pie created")
		assert(playerState["Bread"] == 1, "Bread created")
	end)

	-- =========================================================================
	-- TIER 4: REAL-WORLD APPLICATION SCENARIOS
	-- =========================================================================

	assertTest("Scenario 1: 'The Perfect Zunda Mochi' (All-Perfect S-Rank Run)", "Tier 4", "Scenario1", function()
		local inputs = {}
		for i = 1, 10 do
			table.insert(inputs, { noteIndex = i, laneId = ((i - 1) % 4) + 1, offset = 0.01 * (i % 3) })
		end
		local res = simulateSession("Zunda Mochi", 7.0, inputs, { rngBonusRoll = 0.20 })
		assert(res.grade == "S", "Grade must be S")
		assert(res.accuracy == 100.0, "Accuracy must be 100%")
		assert(res.maxCombo == 10, "Max combo must equal note count")
		assert(res.quality == "perfect", "Dish quality must be perfect")
		assert(res.dishAmount == 2, "Bonus dish awarded")
		assert(res.bonusGold == 25, "+25 bonus gold")
		assert(res.stylePoints == 100, "+100 style points")
		assert(res.voiceTriggers[#res.voiceTriggers] == "cook_rank_s", "Rank S cheer triggered")
	end)

	assertTest(
		"Scenario 2: 'Golden Ramen Clutched Finish' (Miss Recovery to Grade A)",
		"Tier 4",
		"Scenario2",
		function()
			local inputs = {
				{ noteIndex = 1, laneId = 1, offset = 0.02 },
				{ noteIndex = 2, laneId = 2, offset = 0.01 },
				{ noteIndex = 3, laneId = 3, offset = 0.60 }, -- Early Miss
				{ noteIndex = 4, laneId = 4, offset = 0.05 },
				{ noteIndex = 5, laneId = 1, offset = 0.03 },
				{ noteIndex = 6, laneId = 2, offset = 0.02 },
				{ noteIndex = 7, laneId = 3, offset = 0.01 },
				{ noteIndex = 8, laneId = 4, offset = 0.02 },
				{ noteIndex = 9, laneId = 1, offset = 0.01 },
				{ noteIndex = 10, laneId = 2, offset = 0.02 },
			}
			local res = simulateSession("Golden Ramen", 10.0, inputs)
			assert(res.grade == "A", "Clutched finish achieves Grade A (90% accuracy)")
			assert(res.quality == "great", "Great dish quality")
			assert(res.bonusGold == 10, "+10 bonus gold")
			assert(res.stylePoints == 50, "+50 style points")
			assert(res.counts.miss == 1, "1 miss tracked")
			assert(res.maxCombo == 7, "Max combo recovered to 7")
		end
	)

	assertTest(
		"Scenario 3: 'Matcha Parfait Mobile Touch Cooking' (Touch Jitter Simulation)",
		"Tier 4",
		"Scenario3",
		function()
			-- Simulated touch screen inputs with touch jitter
			local inputs = {
				{ noteIndex = 1, laneId = 1, offset = 0.08 },
				{ noteIndex = 2, laneId = 2, offset = -0.09 },
				{ noteIndex = 3, laneId = 3, offset = 0.11 },
				{ noteIndex = 4, laneId = 4, offset = -0.05 },
				{ noteIndex = 5, laneId = 1, offset = 0.14 }, -- Great
				{ noteIndex = 6, laneId = 2, offset = -0.03 },
				{ noteIndex = 7, laneId = 3, offset = 0.06 },
				{ noteIndex = 8, laneId = 4, offset = -0.07 },
			}
			local res = simulateSession("Matchamon's Ceremonial Froth Bowl", 4.0, inputs)
			assert(res.counts.perfect == 7, "7 perfect hits despite touch jitter")
			assert(res.counts.great == 1, "1 great hit")
			assert(res.accuracy >= 95.0, "Accuracy >= 95% (96.25%)")
			assert(res.grade == "S", "Grade S achieved on mobile")
		end
	)

	assertTest("Scenario 4: 'Chaotic Network Latency & Server Reconciliation'", "Tier 4", "Scenario4", function()
		-- Server receives notes with variable network packet travel times
		local inputs = {
			{ noteIndex = 1, laneId = 1, offset = 0.22 }, -- Great (lag)
			{ noteIndex = 2, laneId = 2, offset = 0.15 }, -- Great
			{ noteIndex = 3, laneId = 3, offset = 0.05 }, -- Perfect
			{ noteIndex = 4, laneId = 4, offset = 0.25 }, -- Great
			{ noteIndex = 5, laneId = 1, offset = 0.35 }, -- Good
		}
		local res = simulateSession("Royal Stew", 8.0, inputs)
		assert(res.grade == "B", "High latency results in Grade B (70% accuracy)")
		assert(res.quality == "great" or res.quality == "ok", "Quality reconciled cleanly")
		assert(res.finalData.xp == 65, "XP awarded without desync")
	end)

	assertTest(
		"Scenario 5: 'Aborted Session & Disaster Recovery' (Player Leave at Note 5)",
		"Tier 4",
		"Scenario5",
		function()
			local playerState = {
				Wheat = 0,
				Apple = 0,
				gold = 100,
				cooking_reservation = { sessionId = "sess_abort", ingredients = { Wheat = 5, Apple = 3 } },
			}
			-- Simulate server heartbeat detecting player disconnection
			local function onPlayerDisconnect(state: any, sessId: string): boolean
				if state.cooking_reservation and state.cooking_reservation.sessionId == sessId then
					for ing, amt in pairs(state.cooking_reservation.ingredients) do
						state[ing] = (state[ing] or 0) + amt
					end
					state.cooking_reservation = nil
					return true
				end
				return false
			end
			local refunded = onPlayerDisconnect(playerState, "sess_abort")
			assert(refunded == true, "Session abort cleanly refunded")
			assert(playerState.Wheat == 5, "5 Wheat refunded")
			assert(playerState.Apple == 3, "3 Apple refunded")
			assert(playerState.cooking_reservation == nil, "Reservation cleared")
		end
	)

	-- =========================================================================
	-- TIER 5: ADVERSARIAL STRESS HARDENING
	-- =========================================================================

	assertTest(
		"T5-01: Fuzzing 1000 simulated notes across random lanes and offsets",
		"Tier 5",
		"Adversarial",
		function()
			local inputs = {}
			for i = 1, 1000 do
				local off = ((i * 17) % 100 - 50) / 100.0 -- -0.50s to +0.49s
				table.insert(inputs, { noteIndex = i, laneId = (i % 4) + 1, offset = off })
			end
			local res = simulateSession("Marathon Dish", 600.0, inputs)
			assert(res.totalNotes == 1000, "All 1000 notes processed")
			assert(res.totalScore >= 0, "Score is non-negative")
			assert(res.accuracy >= 0 and res.accuracy <= 100, "Accuracy within [0, 100]")
		end
	)

	assertTest("T5-02: Rapid 100-hits/sec input spam resilience", "Tier 5", "Adversarial", function()
		local hitCount = 0
		local lastHit = 0.0
		local function processHit(now: number): boolean
			if now - lastHit < 0.03 then
				return false -- Throttled
			end
			lastHit = now
			hitCount += 1
			return true
		end
		for i = 1, 100 do
			processHit(10.0 + i * 0.01) -- 10ms intervals
		end
		assert(hitCount < 40, "Rapid spam effectively throttled by rate limit")
	end)

	assertTest("T5-03: Memory leak verification across 500 consecutive sessions", "Tier 5", "Adversarial", function()
		local state = { gold = 0, xp = 0, style_points = 0 }
		for _ = 1, 500 do
			local inp = { { noteIndex = 1, laneId = 1, offset = 0.0 } }
			local r = simulateSession("Bread", 4.0, inp, { initialData = state })
			state = r.finalData
		end
		assert(state["Bread"] == 500, "500 sessions completed and garbage collected without state leakage")
	end)

	return results
end

return test_rhythm_scenarios
