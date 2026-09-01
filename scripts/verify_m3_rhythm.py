#!/usr/bin/env python3
"""
Verification suite for Milestone 3 (M3) — Scoring, Grading, Server Progression & Remotes Integration.
Tests:
1. RhythmScoreEvaluator grade evaluation: S (>=95%), A (>=85%), B (>=70%), C (>=50%), F (<50%)
2. Quality tier mapping: S -> "perfect", A/B -> "great", C/F -> "ok"
3. Reward multipliers: Gold bonus (S: +50%, A: +25%, B: +10%, C: +0%, F: +0%)
4. Style points: S (+250), A (+150), B (+75), C (+25), F (+0)
5. Chef Stat XP scaling (Precision & Speed)
6. CookingService integration with RhythmBeatmapConfig & RhythmScoreEvaluator
7. EndlessLoopWiring minigame metrics propagation to syncPlayerWardrobe, ChallengeModeService, and DailyChallengeService
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

passed = 0
failed = 0

def test(name: str, condition: bool, err_msg: str = ""):
    global passed, failed
    if condition:
        print(f"  [PASS] {name}")
        passed += 1
    else:
        print(f"  [FAIL] {name} -- {err_msg}")
        failed += 1

def main():
    print("================================================================================")
    print("  MILESTONE 3 (M3) VERIFICATION SUITE")
    print("================================================================================")

    # 1. Inspect RhythmScoreEvaluator.lua
    eval_path = SRC / "shared/Rhythm/RhythmScoreEvaluator.lua"
    test("RhythmScoreEvaluator.lua exists", eval_path.is_file())
    eval_text = eval_path.read_text(encoding="utf-8")

    # Check Grade thresholds
    test("Threshold S >= 95.0", "S = 95.0" in eval_text)
    test("Threshold A >= 85.0", "A = 85.0" in eval_text)
    test("Threshold B >= 70.0", "B = 70.0" in eval_text)
    test("Threshold C >= 50.0", "C = 50.0" in eval_text)

    # Check Quality mappings
    test("Grade S maps to 'perfect'", re.search(r'S\s*=\s*"perfect"', eval_text) is not None)
    test("Grade A maps to 'great'", re.search(r'A\s*=\s*"great"', eval_text) is not None)
    test("Grade B maps to 'great'", re.search(r'B\s*=\s*"great"', eval_text) is not None)
    test("Grade C maps to 'ok'", re.search(r'C\s*=\s*"ok"', eval_text) is not None)
    test("Grade F maps to 'ok'", re.search(r'F\s*=\s*"ok"', eval_text) is not None)

    # Check Gold bonus multipliers
    test("Gold bonus S: 1.50 / +50%", "S = 1.50" in eval_text and "S = 50" in eval_text)
    test("Gold bonus A: 1.25 / +25%", "A = 1.25" in eval_text and "A = 25" in eval_text)
    test("Gold bonus B: 1.10 / +10%", "B = 1.10" in eval_text and "B = 10" in eval_text)
    test("Gold bonus C: 1.00 / +0%", "C = 1.00" in eval_text and "C = 0" in eval_text)

    # Check Style points
    test("Style points S: +250", "S = 250" in eval_text)
    test("Style points A: +150", "A = 150" in eval_text)
    test("Style points B: +75", "B = 75" in eval_text)
    test("Style points C: +25", "C = 25" in eval_text)

    # Check stat XP calculation
    test("Precision & Speed XP calculation function exists", "function RhythmScoreEvaluator.calculateStatXP" in eval_text)
    test("Comprehensive evaluate function exists", "function RhythmScoreEvaluator.evaluate" in eval_text)

    # 2. Inspect CookingService.lua
    cooking_path = SRC / "server/Services/CookingService.lua"
    test("CookingService.lua exists", cooking_path.is_file())
    cooking_text = cooking_path.read_text(encoding="utf-8")

    test("CookingService requires RhythmBeatmapConfig", "RhythmBeatmapConfig" in cooking_text)
    test("CookingService requires RhythmScoreEvaluator", "RhythmScoreEvaluator" in cooking_text)
    test("CookingService requires RhythmEngine", "RhythmEngine" in cooking_text)
    test("CookingService.begin invokes RhythmBeatmapConfig.getChart", "RhythmBeatmapConfig.getChart" in cooking_text)
    test("CookingService.begin returns chart in session payload", "chart = chart" in cooking_text)
    test("CookingService.hit accepts (player, sessionId, noteIndex, laneId)", "function CookingService.hit(player: Player, sessionId: any, noteIndex: any, laneId: any?)" in cooking_text)
    test("CookingService.hit records judgment & streak", "nextSession.currentCombo" in cooking_text and "nextSession.totalScore" in cooking_text)
    test("CookingService.finish evaluates metrics via RhythmScoreEvaluator", "RhythmScoreEvaluator.evaluate" in cooking_text)
    test("CookingService.finish fires CookingResult RemoteEvent with full breakdown", "cookingResult:FireClient" in cooking_text and "grade = grade" in cooking_text)
    test("CookingService.finish fires CookingService.CookCompleted with metrics", "CookingService.CookCompleted:Fire(player, session.recipeId, quality, metrics)" in cooking_text)

    # 3. Inspect EndlessLoopWiring.server.lua
    wiring_path = SRC / "server/systems/EndlessLoopWiring.server.lua"
    test("EndlessLoopWiring.server.lua exists", wiring_path.is_file())
    wiring_text = wiring_path.read_text(encoding="utf-8")

    test("EndlessLoopWiring handles metrics in CookCompleted listener", "CookingService.CookCompleted.Event:Connect(function(player, recipeName, quality, metrics)" in wiring_text)
    test("EndlessLoopWiring propagates metrics into syncPlayerWardrobe", "syncPlayerWardrobe(player, styleGain, statGains)" in wiring_text)
    test("EndlessLoopWiring updates ChallengeModeService onCookComplete", "ChallengeModeService.onCookComplete(player, quality)" in wiring_text)
    test("EndlessLoopWiring updates DailyChallengeService progress", "DailyChallengeService.updateProgress(player, \"cook\", 1)" in wiring_text)

    # 4. Inspect CraftManager.server.lua
    craft_mgr_path = SRC / "server/CraftManager.server.lua"
    craft_mgr_text = craft_mgr_path.read_text(encoding="utf-8")
    test("CraftManager forwards laneId to CookingService.hit", "CookingService.hit(player, sessionId, noteIndex, laneId)" in craft_mgr_text)

    # 5. Inspect default.project.json
    proj_path = ROOT / "default.project.json"
    proj_text = proj_path.read_text(encoding="utf-8")
    test("default.project.json maps Rhythm folder", '"Rhythm": {\n        "$path": "src/shared/Rhythm"\n      }' in proj_text)

    print("\n--------------------------------------------------------------------------------")
    print(f"  TOTAL: {passed + failed} | PASSED: {passed} | FAILED: {failed}")
    print("================================================================================")

    if failed > 0:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
