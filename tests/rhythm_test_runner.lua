--!strict
-- tests/rhythm_test_runner.lua
-- Master Test Runner for Dynamic Rhythm Cooking Minigame E2E Test Suite (Tiers 1 - 5)

local test_rhythm_engine = require(script.Parent.e2e.test_rhythm_engine)
local test_rhythm_progression = require(script.Parent.e2e.test_rhythm_progression)
local test_rhythm_scenarios = require(script.Parent.e2e.test_rhythm_scenarios)

local runner = {}

function runner.run()
	print("================================================================================")
	print("  DYNAMIC RHYTHM COOKING MINIGAME — E2E TEST SUITE (TIERS 1 - 5)")
	print("================================================================================")

	local allResults = {}

	local engineResults = test_rhythm_engine.runAll()
	for _, r in ipairs(engineResults) do
		table.insert(allResults, r)
	end

	local progressionResults = test_rhythm_progression.runAll()
	for _, r in ipairs(progressionResults) do
		table.insert(allResults, r)
	end

	local scenarioResults = test_rhythm_scenarios.runAll()
	for _, r in ipairs(scenarioResults) do
		table.insert(allResults, r)
	end

	local tierStats = {
		["Tier 1"] = { total = 0, passed = 0, failed = 0 },
		["Tier 2"] = { total = 0, passed = 0, failed = 0 },
		["Tier 3"] = { total = 0, passed = 0, failed = 0 },
		["Tier 4"] = { total = 0, passed = 0, failed = 0 },
		["Tier 5"] = { total = 0, passed = 0, failed = 0 },
	}

	local totalPassed = 0
	local totalFailed = 0

	for _, result in ipairs(allResults) do
		local stats = tierStats[result.tier]
		if stats then
			stats.total += 1
			if result.passed then
				stats.passed += 1
				totalPassed += 1
			else
				stats.failed += 1
				totalFailed += 1
				print(
					string.format(
						"  ❌ [%s][%s] %s: %s",
						result.tier,
						result.feature,
						result.name,
						tostring(result.error)
					)
				)
			end
		end
	end

	print("\n--------------------------------------------------------------------------------")
	print("  TIER BREAKDOWN SUMMARY")
	print("--------------------------------------------------------------------------------")
	local tiers = { "Tier 1", "Tier 2", "Tier 3", "Tier 4", "Tier 5" }
	for _, t in ipairs(tiers) do
		local s = tierStats[t]
		if s then
			local statusEmoji = (s.failed == 0 and s.total > 0) and "✅ PASS" or "❌ FAIL"
			print(
				string.format(
					"  %-10s | Total: %3d | Passed: %3d | Failed: %3d | %s",
					t,
					s.total,
					s.passed,
					s.failed,
					statusEmoji
				)
			)
		end
	end

	print("================================================================================")
	print(string.format("  TOTAL TESTS: %d | PASSED: %d | FAILED: %d", #allResults, totalPassed, totalFailed))
	print("================================================================================")

	if totalFailed == 0 then
		print("  🎉 ALL RHYTHM COOKING TESTS PASSED PERFECTLY!")
		return true
	else
		print(string.format("  ⚠️ %d TEST(S) FAILED!", totalFailed))
		return false
	end
end

-- Auto-run if executed as script
if script and script.Parent and not script.Parent:IsA("ModuleScript") then
	runner.run()
end

return runner
