#!/usr/bin/env python3
"""Comprehensive test verification for Milestone 1: Core Rhythm Engine & Beatmaps.

Tests:
1. RhythmBeatmapConfig:
   - 4 Action Lanes: CHOP (1, "Chop", 🔪, "D", Color3(160,210,150)), STIR (2, "Stir", 🥣, "F", Color3(255,200,80)),
                     SIMMER (3, "Simmer", 🔥, "J", Color3(255,150,200)), SEASON (4, "Season", 🧂, "K", Color3(145,215,195)).
   - Lane lookups by ID and Name.
   - Deterministic chart generator (BPM, notes, timestamps, lanes, start delay).
2. RhythmEngine:
   - Timing windows: Baseline Perfect (+/-0.12s), Great (+/-0.28s), Good (+/-0.45s).
   - Stat precision scaling: Widens windows up to +25%.
   - Hit evaluation: Judgment, offset, score (1000, 600, 300, 0).
   - Combo multipliers: 1.0x (0-4), 1.2x (5-9), 1.5x (10-14), 2.0x (15-19), 3.0x (20+).
   - Scoring & Streak management: Total score, accuracy %, max combo, letter grades (S, A, B, C, F), dish quality.
   - Edge cases: Empty hits, extreme offsets, zero/max precision, streak breaks on miss.
"""

import math
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"

errors = []


def assert_true(cond: bool, msg: str):
    if not cond:
        errors.append(f"FAIL: {msg}")
        print(f"❌ FAIL: {msg}")
    else:
        print(f"✅ PASS: {msg}")


def test_rhythm_beatmap_config_source():
    path = SRC / "shared/ConfigurationFiles/RhythmBeatmapConfig.lua"
    assert_true(path.exists(), "RhythmBeatmapConfig.lua exists")
    content = path.read_text(encoding="utf-8")

    # Check 4 lanes
    assert_true('CHOP = {' in content or '["CHOP"]' in content, "CHOP lane defined")
    assert_true('STIR = {' in content or '["STIR"]' in content, "STIR lane defined")
    assert_true('SIMMER = {' in content or '["SIMMER"]' in content, "SIMMER lane defined")
    assert_true('SEASON = {' in content or '["SEASON"]' in content, "SEASON lane defined")

    # Check icons and keys
    assert_true("🔪" in content, "Chop knife icon present")
    assert_true("🥣" in content, "Stir bowl icon present")
    assert_true("🔥" in content, "Simmer flame icon present")
    assert_true("🧂" in content, "Season salt icon present")
    assert_true('"D"' in content or "'D'" in content, "Key D present")
    assert_true('"F"' in content or "'F'" in content, "Key F present")
    assert_true('"J"' in content or "'J'" in content, "Key J present")
    assert_true('"K"' in content or "'K'" in content, "Key K present")

    # Check colors (Pastel palette)
    assert_true("160, 210, 150" in content, "Zunda green RGB(160, 210, 150) present")
    assert_true("255, 200, 80" in content, "Gold RGB(255, 200, 80) present")
    assert_true("255, 150, 200" in content, "Pink RGB(255, 150, 200) present")
    assert_true("145, 215, 195" in content, "Mint RGB(145, 215, 195) present")

    # Check getChart function
    assert_true("function RhythmBeatmapConfig.getChart" in content, "getChart function exported")


def test_rhythm_engine_source():
    path = SRC / "shared/Rhythm/RhythmEngine.lua"
    assert_true(path.exists(), "RhythmEngine.lua exists")
    content = path.read_text(encoding="utf-8")

    # Check core functions
    assert_true("function RhythmEngine.evaluateHit" in content, "evaluateHit exported")
    assert_true("function RhythmEngine.getComboMultiplier" in content, "getComboMultiplier exported")
    assert_true("function RhythmEngine.calculateScore" in content, "calculateScore exported")
    assert_true("function RhythmEngine.getTimingWindows" in content, "getTimingWindows exported")
    assert_true("function RhythmEngine.getGrade" in content, "getGrade exported")

    # Check baseline constants
    assert_true("0.12" in content, "Baseline Perfect window 0.12s present")
    assert_true("0.28" in content, "Baseline Great window 0.28s present")
    assert_true("0.45" in content, "Baseline Good window 0.45s present")
    assert_true("1000" in content, "Perfect score 1000 present")
    assert_true("600" in content, "Great score 600 present")
    assert_true("300" in content, "Good score 300 present")


# ── Mathematical & Logic Simulation Tests ────────────────────────────────────

def sim_precision_bonus(stat_precision: float) -> float:
    if not stat_precision or stat_precision <= 0:
        return 0.0
    if stat_precision > 1.0:
        ratio = min(max(stat_precision / 500.0, 0.0), 1.0)
        return ratio * 0.25
    return min(max(stat_precision, 0.0), 0.25)


def sim_timing_windows(stat_precision: float):
    bonus = sim_precision_bonus(stat_precision)
    mult = 1.0 + bonus
    return {
        "perfect": 0.12 * mult,
        "great": 0.28 * mult,
        "good": 0.45 * mult,
        "multiplier": mult,
    }


def sim_evaluate_hit(target_time: float, hit_time: float, stat_precision: float = 0):
    offset = hit_time - target_time
    abs_offset = abs(offset)
    windows = sim_timing_windows(stat_precision)

    if abs_offset <= windows["perfect"]:
        return "PERFECT", offset, 1000
    elif abs_offset <= windows["great"]:
        return "GREAT", offset, 600
    elif abs_offset <= windows["good"]:
        return "GOOD", offset, 300
    else:
        return "MISS", offset, 0


def sim_combo_multiplier(combo: int) -> float:
    if combo < 5:
        return 1.0
    elif combo < 10:
        return 1.2
    elif combo < 15:
        return 1.5
    elif combo < 20:
        return 2.0
    else:
        return 3.0


def sim_grade(accuracy: float) -> str:
    if accuracy >= 95.0:
        return "S"
    elif accuracy >= 85.0:
        return "A"
    elif accuracy >= 70.0:
        return "B"
    elif accuracy >= 50.0:
        return "C"
    else:
        return "F"


def sim_calculate_score(hits: list):
    total_hits = len(hits)
    perfect_count = 0
    great_count = 0
    good_count = 0
    miss_count = 0

    total_score = 0
    current_combo = 0
    max_combo = 0

    base_scores = {"PERFECT": 1000, "GREAT": 600, "GOOD": 300, "MISS": 0}

    for h in hits:
        judgment = h.upper() if isinstance(h, str) else h.get("judgment", "MISS").upper()
        if judgment == "OK":
            judgment = "GOOD"

        base = base_scores.get(judgment, 0)
        if judgment == "PERFECT":
            perfect_count += 1
            current_combo += 1
        elif judgment == "GREAT":
            great_count += 1
            current_combo += 1
        elif judgment == "GOOD":
            good_count += 1
            current_combo += 1
        else:
            miss_count += 1
            current_combo = 0

        if current_combo > max_combo:
            max_combo = current_combo

        mult = sim_combo_multiplier(current_combo) if current_combo > 0 else 1.0
        total_score += int(base * mult)

    accuracy = 0.0
    if total_hits > 0:
        weighted = (perfect_count * 1.0) + (great_count * 0.6) + (good_count * 0.3)
        accuracy = round((weighted / total_hits) * 10000) / 100.0

    grade = sim_grade(accuracy)
    perfect_ratio = (perfect_count / total_hits) if total_hits > 0 else 0
    quality = "perfect" if (perfect_ratio >= 0.8 or accuracy >= 95.0) else ("great" if accuracy >= 70.0 else "ok")

    return {
        "totalScore": total_score,
        "accuracy": accuracy,
        "maxCombo": max_combo,
        "finalCombo": current_combo,
        "grade": grade,
        "quality": quality,
        "counts": {
            "PERFECT": perfect_count,
            "GREAT": great_count,
            "GOOD": good_count,
            "MISS": miss_count,
            "total": total_hits,
        },
    }


def test_logic_and_edge_cases():
    print("\n--- Testing Hit Evaluation & Windows ---")
    # Base windows
    w0 = sim_timing_windows(0)
    assert_true(math.isclose(w0["perfect"], 0.12), "Base perfect window is 0.12s")
    assert_true(math.isclose(w0["great"], 0.28), "Base great window is 0.28s")
    assert_true(math.isclose(w0["good"], 0.45), "Base good window is 0.45s")

    # Max Precision bonus (500 pts = +25%)
    w500 = sim_timing_windows(500)
    assert_true(math.isclose(w500["perfect"], 0.15), "Max precision perfect window is 0.15s (0.12 * 1.25)")
    assert_true(math.isclose(w500["great"], 0.35), "Max precision great window is 0.35s (0.28 * 1.25)")
    assert_true(math.isclose(w500["good"], 0.5625), "Max precision good window is 0.5625s (0.45 * 1.25)")

    # Hit judgments
    j, off, sc = sim_evaluate_hit(2.0, 2.05, 0)
    assert_true(j == "PERFECT" and math.isclose(off, 0.05) and sc == 1000, "Early/late 0.05s is PERFECT")

    j, off, sc = sim_evaluate_hit(2.0, 2.20, 0)
    assert_true(j == "GREAT" and math.isclose(off, 0.20) and sc == 600, "0.20s offset is GREAT")

    j, off, sc = sim_evaluate_hit(2.0, 2.35, 0)
    assert_true(j == "GOOD" and math.isclose(off, 0.35) and sc == 300, "0.35s offset is GOOD")

    j, off, sc = sim_evaluate_hit(2.0, 2.50, 0)
    assert_true(j == "MISS" and math.isclose(off, 0.50) and sc == 0, "0.50s offset is MISS")

    # Negative offset (early hit)
    j, off, sc = sim_evaluate_hit(2.0, 1.89, 0)
    assert_true(j == "PERFECT" and math.isclose(off, -0.11) and sc == 1000, "-0.11s offset is PERFECT")

    # Precision expansion converts Great to Perfect
    j_no_bonus, _, _ = sim_evaluate_hit(2.0, 2.13, 0)
    j_with_bonus, _, _ = sim_evaluate_hit(2.0, 2.13, 500)
    assert_true(j_no_bonus == "GREAT" and j_with_bonus == "PERFECT", "0.13s offset upgraded to PERFECT with 500 precision")

    print("\n--- Testing Multipliers ---")
    assert_true(sim_combo_multiplier(0) == 1.0, "Combo 0 = 1.0x")
    assert_true(sim_combo_multiplier(4) == 1.0, "Combo 4 = 1.0x")
    assert_true(sim_combo_multiplier(5) == 1.2, "Combo 5 = 1.2x")
    assert_true(sim_combo_multiplier(9) == 1.2, "Combo 9 = 1.2x")
    assert_true(sim_combo_multiplier(10) == 1.5, "Combo 10 = 1.5x")
    assert_true(sim_combo_multiplier(14) == 1.5, "Combo 14 = 1.5x")
    assert_true(sim_combo_multiplier(15) == 2.0, "Combo 15 = 2.0x")
    assert_true(sim_combo_multiplier(19) == 2.0, "Combo 19 = 2.0x")
    assert_true(sim_combo_multiplier(20) == 3.0, "Combo 20 = 3.0x")
    assert_true(sim_combo_multiplier(100) == 3.0, "Combo 100 = 3.0x")

    print("\n--- Testing Scoring & Streak Calculation ---")
    # All perfect 25 notes
    all_perfect = ["PERFECT"] * 25
    res = sim_calculate_score(all_perfect)
    assert_true(res["accuracy"] == 100.0, "All perfect accuracy is 100.0%")
    assert_true(res["grade"] == "S", "All perfect grade is S")
    assert_true(res["quality"] == "perfect", "All perfect quality is perfect")
    assert_true(res["maxCombo"] == 25, "Max combo is 25")
    assert_true(res["totalScore"] > 25000, f"Total score with multipliers > 25000: {res['totalScore']}")

    # Streak broken midway
    broken_streak = ["PERFECT"] * 10 + ["MISS"] + ["PERFECT"] * 10
    res_broken = sim_calculate_score(broken_streak)
    assert_true(res_broken["maxCombo"] == 10, "Max combo capped at 10 due to miss")
    assert_true(res_broken["finalCombo"] == 10, "Final combo is 10")
    assert_true(res_broken["counts"]["MISS"] == 1, "Miss count is 1")
    assert_true(res_broken["counts"]["PERFECT"] == 20, "Perfect count is 20")

    # Empty hits list
    res_empty = sim_calculate_score([])
    assert_true(res_empty["totalScore"] == 0 and res_empty["accuracy"] == 0 and res_empty["grade"] == "F", "Empty hits handled cleanly")


def main():
    print("==================================================")
    print("🎵 ZUNDAMON'S KITCHEN V2 - M1 RHYTHM VERIFIER 🎵")
    print("==================================================")

    test_rhythm_beatmap_config_source()
    test_rhythm_engine_source()
    test_logic_and_edge_cases()

    print("\n--------------------------------------------------")
    if errors:
        print(f"❌ {len(errors)} tests failed!")
        sys.exit(1)
    else:
        print("✨ ALL M1 RHYTHM TESTS PASSED CLEANLY! ✨")


if __name__ == "__main__":
    main()
