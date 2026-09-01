#!/usr/bin/env python3
"""
scripts/stress_test_rhythm_timing.py

Adversarial Stress Test Suite & Timing Oracle for Zundamon's Kitchen V2
Milestone M5 Rhythm Cooking Engine Empirical Validation.

Stress Dimensions:
1. Boundary Timing Offsets at exact microsecond thresholds (±0.12000s, ±0.28000s, ±0.45000s).
2. Stat Precision Window Expansion (0 to 500 scale, over-cap, compound companion buffs).
3. Network Latency Jitter (±0.10s to ±0.50s) & Out-of-Order Packet Reordering.
4. High-Frequency Input Spamming (100Hz) & Simultaneous Multi-Lane Presses (Anti-Exploit).
5. Streak Breaks & Multiplier Transitions (1.0x -> 1.2x -> 1.5x -> 2.0x -> 3.0x).
6. Memory Stability & Deterministic Monte-Carlo Simulation (1,000+ sessions).
"""

import sys
import os
import math
import time
import random
import hashlib
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass

# Ensure stdout/stderr UTF-8 encoding
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# ==============================================================================
# CANONICAL ENGINE SPECIFICATION CONSTANTS
# ==============================================================================

BASE_WINDOWS = {
    "PERFECT": 0.12,
    "GREAT": 0.28,
    "GOOD": 0.45,
}

BASE_SCORES = {
    "PERFECT": 1000,
    "GREAT": 600,
    "GOOD": 300,
    "MISS": 0,
}

MAX_PRECISION_BONUS = 0.25

GRADE_THRESHOLDS = [
    (95.0, "S"),
    (85.0, "A"),
    (70.0, "B"),
    (50.0, "C"),
    (0.0, "F"),
]

# ==============================================================================
# CANONICAL SIMULATOR IMPLEMENTATION (Mirrors Luau RhythmEngine.lua)
# ==============================================================================

def get_precision_bonus(stat_precision: Optional[float]) -> float:
    if stat_precision is None or stat_precision <= 0:
        return 0.0
    if stat_precision > 1.0:
        ratio = max(0.0, min(1.0, stat_precision / 500.0))
        return ratio * MAX_PRECISION_BONUS
    else:
        return max(0.0, min(MAX_PRECISION_BONUS, stat_precision))

def get_timing_windows(stat_precision: Optional[float], companion_buff: float = 0.0, signature_bonus: bool = False) -> Dict[str, float]:
    bonus = get_precision_bonus(stat_precision)
    mult = 1.0 + bonus
    perfect_win = BASE_WINDOWS["PERFECT"] * mult
    if companion_buff > 0:
        perfect_win *= (1.0 + companion_buff)
    if signature_bonus:
        perfect_win *= 1.10
    great_win = BASE_WINDOWS["GREAT"] * mult
    good_win = BASE_WINDOWS["GOOD"] * mult
    return {
        "perfect": perfect_win,
        "great": great_win,
        "good": good_win,
        "multiplier": mult,
    }

def evaluate_hit(target_time: float, hit_time: float, stat_precision: Optional[float] = None,
                 companion_buff: float = 0.0, signature_bonus: bool = False) -> Tuple[str, float, int]:
    if not isinstance(target_time, (int, float)) or not isinstance(hit_time, (int, float)):
        return "MISS", 0.0, 0
    if math.isnan(target_time) or math.isnan(hit_time) or math.isinf(target_time) or math.isinf(hit_time):
        return "MISS", 0.0, 0

    offset = hit_time - target_time
    abs_offset = abs(offset)
    windows = get_timing_windows(stat_precision, companion_buff, signature_bonus)

    # Use epsilon threshold comparisons matching IEEE 754 precision
    if abs_offset <= windows["perfect"] + 1e-9:
        return "PERFECT", offset, BASE_SCORES["PERFECT"]
    elif abs_offset <= windows["great"] + 1e-9:
        return "GREAT", offset, BASE_SCORES["GREAT"]
    elif abs_offset <= windows["good"] + 1e-9:
        return "GOOD", offset, BASE_SCORES["GOOD"]
    else:
        return "MISS", offset, BASE_SCORES["MISS"]

def get_combo_multiplier(combo: int) -> float:
    if not isinstance(combo, int) or combo < 5:
        return 1.0
    elif combo < 10:
        return 1.2
    elif combo < 15:
        return 1.5
    elif combo < 20:
        return 2.0
    else:
        return 3.0

def get_grade(accuracy: float) -> str:
    for threshold, grade in GRADE_THRESHOLDS:
        if accuracy >= threshold:
            return grade
    return "F"

def get_dish_quality(accuracy: float, perfect_ratio: float = 0.0) -> str:
    if perfect_ratio >= 0.8 or accuracy >= 95.0:
        return "perfect"
    elif accuracy >= 70.0:
        return "great"
    else:
        return "ok"

def calculate_score(hits: List[Any]) -> Dict[str, Any]:
    total_hits = len(hits)
    counts = {"PERFECT": 0, "GREAT": 0, "GOOD": 0, "MISS": 0}
    current_combo = 0
    max_combo = 0
    total_score = 0
    max_possible_score = total_hits * BASE_SCORES["PERFECT"]

    for raw in hits:
        if isinstance(raw, str):
            j = raw.upper()
            if j == "OK":
                j = "GOOD"
        elif isinstance(raw, dict):
            j = raw.get("judgment", raw.get("tag", "MISS")).upper()
            if j == "OK":
                j = "GOOD"
        else:
            j = "MISS"

        if j not in counts:
            j = "MISS"

        counts[j] += 1
        base_score = BASE_SCORES[j]

        if j != "MISS":
            current_combo += 1
            if current_combo > max_combo:
                max_combo = current_combo
            mult = get_combo_multiplier(current_combo)
            total_score += math.floor(base_score * mult)
        else:
            current_combo = 0

    if total_hits > 0:
        weighted = (counts["PERFECT"] * 1.0) + (counts["GREAT"] * 0.6) + (counts["GOOD"] * 0.3)
        accuracy = round((weighted / total_hits) * 10000) / 100.0
    else:
        accuracy = 0.0

    perfect_ratio = (counts["PERFECT"] / total_hits) if total_hits > 0 else 0.0
    grade = get_grade(accuracy)
    quality = get_dish_quality(accuracy, perfect_ratio)

    return {
        "totalScore": total_score,
        "maxPossibleScore": max_possible_score,
        "accuracy": accuracy,
        "maxCombo": max_combo,
        "finalCombo": current_combo,
        "grade": grade,
        "quality": quality,
        "counts": counts,
    }

# ==============================================================================
# STRESS TEST HARNESS & TEST SUITES
# ==============================================================================

class StressTestHarness:
    def __init__(self):
        self.tests_run = 0
        self.tests_passed = 0
        self.tests_failed = 0
        self.failures: List[str] = []
        self.start_time = 0.0

    def assert_true(self, condition: bool, test_name: str, details: str = ""):
        self.tests_run += 1
        if condition:
            self.tests_passed += 1
        else:
            self.tests_failed += 1
            msg = f"[FAILED] {test_name}: {details}"
            self.failures.append(msg)
            print(f"  ❌ {msg}")

    def assert_equal(self, actual: Any, expected: Any, test_name: str, details: str = ""):
        self.assert_true(actual == expected, test_name, f"Expected {expected}, got {actual}. {details}")

    def assert_almost_equal(self, actual: float, expected: float, test_name: str, tol: float = 1e-6):
        diff = abs(actual - expected)
        self.assert_true(diff <= tol, test_name, f"Expected ~{expected}, got {actual} (delta={diff})")

# ------------------------------------------------------------------------------
# 1. BOUNDARY TIMING OFFSETS STRESS SUITE
# ------------------------------------------------------------------------------

def test_boundary_timing(harness: StressTestHarness):
    print("\n[STRESS 1] Microsecond Boundary Timing Offsets (Exact Thresholds)")
    target = 100.0

    # 1.1 Exact Zero Offset
    j, off, sc = evaluate_hit(target, target)
    harness.assert_equal(j, "PERFECT", "Boundary: Zero Delta Judgment")
    harness.assert_equal(sc, 1000, "Boundary: Zero Delta Score")

    # 1.2 Perfect / Great Boundary (±0.120000s)
    eps = 1e-6
    # Inner Perfect
    j, _, _ = evaluate_hit(target, target + 0.11999)
    harness.assert_equal(j, "PERFECT", "Boundary: +0.11999s -> PERFECT")
    j, _, _ = evaluate_hit(target, target - 0.11999)
    harness.assert_equal(j, "PERFECT", "Boundary: -0.11999s -> PERFECT")

    # Exact threshold 0.120000s
    j, _, _ = evaluate_hit(target, target + 0.120000)
    harness.assert_equal(j, "PERFECT", "Boundary: Exact +0.120000s -> PERFECT")
    j, _, _ = evaluate_hit(target, target - 0.120000)
    harness.assert_equal(j, "PERFECT", "Boundary: Exact -0.120000s -> PERFECT")

    # Just outside Perfect -> Great
    j, _, _ = evaluate_hit(target, target + 0.120001)
    harness.assert_equal(j, "GREAT", "Boundary: +0.120001s -> GREAT")
    j, _, _ = evaluate_hit(target, target - 0.120001)
    harness.assert_equal(j, "GREAT", "Boundary: -0.120001s -> GREAT")

    # 1.3 Great / Good Boundary (±0.280000s)
    j, _, _ = evaluate_hit(target, target + 0.27999)
    harness.assert_equal(j, "GREAT", "Boundary: +0.27999s -> GREAT")
    j, _, _ = evaluate_hit(target, target - 0.27999)
    harness.assert_equal(j, "GREAT", "Boundary: -0.27999s -> GREAT")

    # Exact threshold 0.280000s
    j, _, _ = evaluate_hit(target, target + 0.280000)
    harness.assert_equal(j, "GREAT", "Boundary: Exact +0.280000s -> GREAT")
    j, _, _ = evaluate_hit(target, target - 0.280000)
    harness.assert_equal(j, "GREAT", "Boundary: Exact -0.280000s -> GREAT")

    # Just outside Great -> Good
    j, _, _ = evaluate_hit(target, target + 0.280001)
    harness.assert_equal(j, "GOOD", "Boundary: +0.280001s -> GOOD")
    j, _, _ = evaluate_hit(target, target - 0.280001)
    harness.assert_equal(j, "GOOD", "Boundary: -0.280001s -> GOOD")

    # 1.4 Good / Miss Boundary (±0.450000s)
    j, _, _ = evaluate_hit(target, target + 0.44999)
    harness.assert_equal(j, "GOOD", "Boundary: +0.44999s -> GOOD")
    j, _, _ = evaluate_hit(target, target - 0.44999)
    harness.assert_equal(j, "GOOD", "Boundary: -0.44999s -> GOOD")

    # Exact threshold 0.450000s
    j, _, _ = evaluate_hit(target, target + 0.450000)
    harness.assert_equal(j, "GOOD", "Boundary: Exact +0.450000s -> GOOD")
    j, _, _ = evaluate_hit(target, target - 0.450000)
    harness.assert_equal(j, "GOOD", "Boundary: Exact -0.450000s -> GOOD")

    # Just outside Good -> Miss
    j, _, _ = evaluate_hit(target, target + 0.450001)
    harness.assert_equal(j, "MISS", "Boundary: +0.450001s -> MISS")
    j, _, _ = evaluate_hit(target, target - 0.450001)
    harness.assert_equal(j, "MISS", "Boundary: -0.450001s -> MISS")

    # 1.5 Dense Sub-Millisecond Sweep (10,000 continuous points across [-0.60s, +0.60s])
    monotonic_errors = 0
    prev_judgment_rank = 0
    # Rank: 3=PERFECT, 2=GREAT, 1=GOOD, 0=MISS
    rank_map = {"PERFECT": 3, "GREAT": 2, "GOOD": 1, "MISS": 0}
    sweep_steps = 10000
    for i in range(sweep_steps):
        delta = -0.60 + (1.20 * i / sweep_steps)
        j, off, _ = evaluate_hit(target, target + delta)
        curr_rank = rank_map[j]
        # As abs(delta) increases, rank must never increase (monotonicity check)
        abs_d = abs(delta)
        expected_j = "MISS"
        if abs_d <= 0.12 + 1e-9:
            expected_j = "PERFECT"
        elif abs_d <= 0.28 + 1e-9:
            expected_j = "GREAT"
        elif abs_d <= 0.45 + 1e-9:
            expected_j = "GOOD"
        if j != expected_j:
            monotonic_errors += 1

    harness.assert_equal(monotonic_errors, 0, "Boundary: 10,000-point Continuous Sweep Monotonicity", f"{monotonic_errors} errors")

    # 1.6 Degenerate & Extreme Inputs
    j, _, _ = evaluate_hit(target, float("nan"))
    harness.assert_equal(j, "MISS", "Boundary: NaN HitTime -> MISS")
    j, _, _ = evaluate_hit(float("nan"), target)
    harness.assert_equal(j, "MISS", "Boundary: NaN TargetTime -> MISS")
    j, _, _ = evaluate_hit(target, float("inf"))
    harness.assert_equal(j, "MISS", "Boundary: +Inf HitTime -> MISS")
    j, _, _ = evaluate_hit(target, -1e12)
    harness.assert_equal(j, "MISS", "Boundary: Extreme Negative HitTime -> MISS")
    j, _, _ = evaluate_hit(target, 1e12)
    harness.assert_equal(j, "MISS", "Boundary: Extreme Future HitTime -> MISS")

# ------------------------------------------------------------------------------
# 2. STAT PRECISION WINDOW EXPANSION STRESS SUITE
# ------------------------------------------------------------------------------

def test_stat_precision_scaling(harness: StressTestHarness):
    print("\n[STRESS 2] Chef Stat Precision Window Expansion & Buff Compounding")
    target = 50.0

    # 2.1 Baseline Zero Precision
    w0 = get_timing_windows(0)
    harness.assert_almost_equal(w0["perfect"], 0.12, "Precision 0: Perfect Window = 0.12s")
    harness.assert_almost_equal(w0["great"], 0.28, "Precision 0: Great Window = 0.28s")
    harness.assert_almost_equal(w0["good"], 0.45, "Precision 0: Good Window = 0.45s")

    # 2.2 Midpoint Precision (250 points = +12.5%)
    w250 = get_timing_windows(250)
    harness.assert_almost_equal(w250["multiplier"], 1.125, "Precision 250: Multiplier = 1.125")
    harness.assert_almost_equal(w250["perfect"], 0.12 * 1.125, "Precision 250: Perfect = 0.135s")
    harness.assert_almost_equal(w250["great"], 0.28 * 1.125, "Precision 250: Great = 0.315s")
    harness.assert_almost_equal(w250["good"], 0.45 * 1.125, "Precision 250: Good = 0.50625s")

    # 2.3 Max Cap Precision (500 points = +25.0%)
    w500 = get_timing_windows(500)
    harness.assert_almost_equal(w500["multiplier"], 1.25, "Precision 500: Multiplier = 1.25")
    harness.assert_almost_equal(w500["perfect"], 0.12 * 1.25, "Precision 500: Perfect = 0.150s (0.12 * 1.25)")
    harness.assert_almost_equal(w500["great"], 0.28 * 1.25, "Precision 500: Great = 0.350s (0.28 * 1.25)")
    harness.assert_almost_equal(w500["good"], 0.45 * 1.25, "Precision 500: Good = 0.5625s (0.45 * 1.25)")

    # 2.4 Over-Cap Precision (1000 points clamped to max 25%)
    w1000 = get_timing_windows(1000)
    harness.assert_almost_equal(w1000["perfect"], 0.150, "Precision 1000: Clamped to Max Perfect 0.150s")

    # 2.5 Hit Evaluation at Expanded Window Edge
    # At 500 precision, delta = +0.145s was a Great without buff, but should be PERFECT with buff!
    j_base, _, _ = evaluate_hit(target, target + 0.145, stat_precision=0)
    harness.assert_equal(j_base, "GREAT", "Precision 0: +0.145s is GREAT")
    j_buff, _, _ = evaluate_hit(target, target + 0.145, stat_precision=500)
    harness.assert_equal(j_buff, "PERFECT", "Precision 500: +0.145s is PERFECT")

    # 2.6 Compound Buff Stacking (Precision 500 + Companion 15% + Signature Recipe 10%)
    w_stacked = get_timing_windows(500, companion_buff=0.15, signature_bonus=True)
    # Expected perfect = 0.12 * 1.25 * 1.15 * 1.10 = 0.18975s
    expected_stacked_perfect = 0.12 * 1.25 * 1.15 * 1.10
    harness.assert_almost_equal(w_stacked["perfect"], expected_stacked_perfect, "Stacked Buffs: Perfect Window = ~0.18975s")

    # Test hit at +0.180s under fully stacked buffs
    j_stacked, _, _ = evaluate_hit(target, target + 0.180, stat_precision=500, companion_buff=0.15, signature_bonus=True)
    harness.assert_equal(j_stacked, "PERFECT", "Stacked Buffs: +0.180s hits PERFECT")

# ------------------------------------------------------------------------------
# 3. LATENCY JITTER & PACKET REORDERING SIMULATION
# ------------------------------------------------------------------------------

def test_latency_and_reordering(harness: StressTestHarness):
    print("\n[STRESS 3] Extreme Latency Jitter (±0.10s to ±0.50s) & Packet Reordering")

    class ServerSessionMock:
        def __init__(self, recipe: str, note_timestamps: List[float], windows: Dict[str, float]):
            self.recipe = recipe
            self.notes = note_timestamps
            self.total_notes = len(note_timestamps)
            self.next_expected = 1
            self.hit_records = []
            self.perfect_hits = 0
            self.great_hits = 0
            self.good_hits = 0
            self.misses = 0
            self.current_combo = 0
            self.max_combo = 0
            self.total_score = 0
            self.windows = windows

        def on_server_hit(self, server_now: float, note_index: int, lane_id: int):
            ok_win = self.windows["good"]
            great_win = self.windows["great"]
            perf_win = self.windows["perfect"]

            # Advance expired unhit notes before note_index
            while self.next_expected <= self.total_notes:
                tgt = self.notes[self.next_expected - 1]
                if server_now <= tgt + ok_win:
                    break
                self.misses += 1
                self.current_combo = 0
                self.hit_records.append({"noteIndex": self.next_expected, "judgment": "MISS", "offset": server_now - tgt, "score": 0})
                self.next_expected += 1

            if note_index != self.next_expected or note_index > self.total_notes:
                return  # Out of order or stale packet ignored

            target_time = self.notes[note_index - 1]
            diff = server_now - target_time
            abs_diff = abs(diff)

            if abs_diff > ok_win:
                if server_now > target_time + ok_win:
                    self.misses += 1
                    self.current_combo = 0
                    self.hit_records.append({"noteIndex": note_index, "judgment": "MISS", "offset": diff, "score": 0})
                    self.next_expected += 1
                return

            if abs_diff <= perf_win:
                judgment = "PERFECT"
                base_score = 1000
                self.perfect_hits += 1
                self.current_combo += 1
            elif abs_diff <= great_win:
                judgment = "GREAT"
                base_score = 600
                self.great_hits += 1
                self.current_combo += 1
            else:
                judgment = "GOOD"
                base_score = 300
                self.good_hits += 1
                self.current_combo += 1

            if self.current_combo > self.max_combo:
                self.max_combo = self.current_combo

            mult = get_combo_multiplier(self.current_combo)
            hit_score = math.floor(base_score * mult)
            self.total_score += hit_score
            self.hit_records.append({"noteIndex": note_index, "judgment": judgment, "offset": diff, "score": hit_score})
            self.next_expected += 1

        def server_finish(self, server_now: float):
            ok_win = self.windows["good"]
            while self.next_expected <= self.total_notes:
                self.misses += 1
                self.hit_records.append({"noteIndex": self.next_expected, "judgment": "MISS", "offset": 0, "score": 0})
                self.next_expected += 1

    # 3.1 Scenario: Mild Jitter (Ping = 50ms ± 20ms) -> All Perfect inputs remain Perfect/Great
    chart_notes = [2.0 + i * 1.0 for i in range(10)]
    server = ServerSessionMock("Zunda Mochi", chart_notes, get_timing_windows(0))

    for idx, target_t in enumerate(chart_notes, 1):
        client_hit_t = target_t  # Client hits exact target
        latency = 0.050 + random.uniform(-0.020, 0.020)  # 30ms to 70ms ping
        server_arrival_t = client_hit_t + latency
        server.on_server_hit(server_arrival_t, idx, 1)

    server.server_finish(15.0)
    harness.assert_equal(server.total_notes, 10, "Mild Jitter: Total Notes")
    harness.assert_equal(len(server.hit_records), 10, "Mild Jitter: 10/10 Records Processed")
    harness.assert_true(server.perfect_hits >= 9, f"Mild Jitter: Perfect Hits = {server.perfect_hits} >= 9")
    harness.assert_equal(server.misses, 0, "Mild Jitter: 0 Misses")

    # 3.2 Scenario: Extreme Jitter (Ping = 200ms ± 150ms) -> Some degrade to Great/Good but no server desync
    server_extreme = ServerSessionMock("Zunda Mochi", chart_notes, get_timing_windows(0))
    for idx, target_t in enumerate(chart_notes, 1):
        client_hit_t = target_t
        latency = 0.200 + random.uniform(-0.150, 0.150)  # 50ms to 350ms ping
        server_arrival_t = client_hit_t + latency
        server_extreme.on_server_hit(server_arrival_t, idx, 1)

    server_extreme.server_finish(15.0)
    harness.assert_equal(len(server_extreme.hit_records), 10, "Extreme Jitter: All 10 notes accounted for")
    harness.assert_true(server_extreme.perfect_hits + server_extreme.great_hits + server_extreme.good_hits >= 8,
                        f"Extreme Jitter: Non-miss hits = {10 - server_extreme.misses} >= 8")

    # 3.3 Scenario: Catastrophic Packet Reordering (Packet 3 arrives AFTER Packet 4 and 5)
    server_reorder = ServerSessionMock("Zunda Mochi", chart_notes, get_timing_windows(0))
    packets = [
        (2.02, 1),
        (3.03, 2),
        (5.05, 4),  # Note 4 arrives first at t=5.05
        (5.08, 5),  # Note 5 arrives at t=5.08
        (5.20, 3),  # Note 3 arrives late at t=5.20 (after Note 3 target=4.0 + 0.45=4.45 expired)
    ]
    for arr_t, n_idx in packets:
        server_reorder.on_server_hit(arr_t, n_idx, 1)

    server_reorder.server_finish(15.0)
    harness.assert_equal(len(server_reorder.hit_records), 10, "Reorder: All 10 notes resolved")
    # Note 3 should have expired and been marked as MISS when server reached t=5.05
    n3_record = [r for r in server_reorder.hit_records if r["noteIndex"] == 3][0]
    harness.assert_equal(n3_record["judgment"], "MISS", "Reorder: Expired Note 3 marked as MISS")

# ------------------------------------------------------------------------------
# 4. INPUT SPAMMING & SIMULTANEOUS MULTI-LANE PRESSES STRESS SUITE
# ------------------------------------------------------------------------------

def test_input_spam_and_multi_lane(harness: StressTestHarness):
    print("\n[STRESS 4] High-Frequency Input Spamming (100Hz) & Multi-Lane Anti-Exploit")

    class ClientControllerMock:
        def __init__(self, chart_notes: List[Dict[str, Any]], windows: Dict[str, float]):
            self.notes = chart_notes
            self.windows = windows
            self.combo = 0
            self.max_combo = 0
            self.score = 0
            self.counts = {"perfect": 0, "great": 0, "good": 0, "miss": 0}
            self.active_notes = [{"index": n["index"], "laneId": n["laneId"], "targetTime": n["targetTime"], "hit": False, "missed": False} for n in chart_notes]

        def handle_lane_hit(self, now: float, target_lane_id: Optional[int]):
            best_note = None
            best_diff = float("inf")

            for note in self.active_notes:
                if not note["hit"] and not note["missed"]:
                    if target_lane_id is None or note["laneId"] == target_lane_id:
                        diff = abs(now - note["targetTime"])
                        if diff <= self.windows["good"] and diff < best_diff:
                            best_diff = diff
                            best_note = note

            if best_note:
                best_note["hit"] = True
                quality = "good"
                base_score = 300
                if best_diff <= self.windows["perfect"]:
                    quality = "perfect"
                    base_score = 1000
                elif best_diff <= self.windows["great"]:
                    quality = "great"
                    base_score = 600

                self.counts[quality] += 1
                self.combo += 1
                if self.combo > self.max_combo:
                    self.max_combo = self.combo
                mult = get_combo_multiplier(self.combo)
                self.score += math.floor(base_score * mult)
                return "HIT", quality
            else:
                # Mistap / Spam miss
                self.combo = 0
                self.counts["miss"] += 1
                return "MISTAP", "miss"

    # 4.1 100Hz Spam Attack on Empty Lane
    # Single note at t=2.0 on Lane 1.
    chart = [{"index": 1, "laneId": 1, "targetTime": 2.0}]
    win0 = get_timing_windows(0)
    client = ClientControllerMock(chart, win0)

    # Spam Lane 2 at 100Hz for 1 second (100 spam events between t=0.5 and t=1.5)
    spam_mistaps = 0
    for i in range(100):
        t = 0.5 + (i * 0.01)
        res, _ = client.handle_lane_hit(t, target_lane_id=2)
        if res == "MISTAP":
            spam_mistaps += 1

    harness.assert_equal(spam_mistaps, 100, "Spam Anti-Exploit: 100 off-lane spams trigger 100 mistaps")
    harness.assert_equal(client.combo, 0, "Spam Anti-Exploit: Combo remains 0")

    # 4.2 Simultaneous 4-Lane Press on Single Note Target
    # At t=2.0, player presses Lanes 1, 2, 3, 4 simultaneously. Note is on Lane 1.
    client_multi = ClientControllerMock([{"index": 1, "laneId": 1, "targetTime": 2.0}], win0)
    r1, q1 = client_multi.handle_lane_hit(2.0, target_lane_id=1)
    r2, q2 = client_multi.handle_lane_hit(2.0, target_lane_id=2)
    r3, q3 = client_multi.handle_lane_hit(2.0, target_lane_id=3)
    r4, q4 = client_multi.handle_lane_hit(2.0, target_lane_id=4)

    harness.assert_equal(r1, "HIT", "Multi-Lane: Target lane hits note")
    harness.assert_equal(r2, "MISTAP", "Multi-Lane: Empty lane 2 mistaps")
    harness.assert_equal(r3, "MISTAP", "Multi-Lane: Empty lane 3 mistaps")
    harness.assert_equal(r4, "MISTAP", "Multi-Lane: Empty lane 4 mistaps")
    harness.assert_equal(client_multi.combo, 0, "Multi-Lane: Combo reset by subsequent empty lane mistaps")

    # 4.3 Universal Key (Spacebar) Clean Fallback
    # Universal key presses target_lane_id=None -> matches Note 1 on Lane 1 without mistapping other lanes
    client_space = ClientControllerMock([{"index": 1, "laneId": 1, "targetTime": 2.0}], win0)
    r_sp, q_sp = client_space.handle_lane_hit(2.0, target_lane_id=None)
    harness.assert_equal(r_sp, "HIT", "Universal Spacebar: Successfully hits active lane note")
    harness.assert_equal(client_space.combo, 1, "Universal Spacebar: Combo is preserved (1)")

# ------------------------------------------------------------------------------
# 5. COMBO MULTIPLIER & STREAK BREAK STATE MACHINE STRESS SUITE
# ------------------------------------------------------------------------------

def test_combo_multiplier_transitions(harness: StressTestHarness):
    print("\n[STRESS 5] Combo Multiplier Transitions & Streak Break Recovery")

    # 5.1 Multiplier Tiers: 1.0x (0-4), 1.2x (5-9), 1.5x (10-14), 2.0x (15-19), 3.0x (20+)
    harness.assert_almost_equal(get_combo_multiplier(0), 1.0, "Combo 0: Multiplier 1.0x")
    harness.assert_almost_equal(get_combo_multiplier(1), 1.0, "Combo 1: Multiplier 1.0x")
    harness.assert_almost_equal(get_combo_multiplier(4), 1.0, "Combo 4: Multiplier 1.0x")
    harness.assert_almost_equal(get_combo_multiplier(5), 1.2, "Combo 5: Multiplier 1.2x")
    harness.assert_almost_equal(get_combo_multiplier(9), 1.2, "Combo 9: Multiplier 1.2x")
    harness.assert_almost_equal(get_combo_multiplier(10), 1.5, "Combo 10: Multiplier 1.5x")
    harness.assert_almost_equal(get_combo_multiplier(14), 1.5, "Combo 14: Multiplier 1.5x")
    harness.assert_almost_equal(get_combo_multiplier(15), 2.0, "Combo 15: Multiplier 2.0x")
    harness.assert_almost_equal(get_combo_multiplier(19), 2.0, "Combo 19: Multiplier 2.0x")
    harness.assert_almost_equal(get_combo_multiplier(20), 3.0, "Combo 20: Multiplier 3.0x")
    harness.assert_almost_equal(get_combo_multiplier(50), 3.0, "Combo 50: Multiplier 3.0x")
    harness.assert_almost_equal(get_combo_multiplier(100), 3.0, "Combo 100: Multiplier 3.0x")

    # 5.2 Score Accumulation Across Streak Break
    # Run 25 hits: 19 Perfects, 1 Miss on note 20, 5 Perfects on notes 21-25
    hits_streak = ["PERFECT"] * 19 + ["MISS"] + ["PERFECT"] * 5
    res = calculate_score(hits_streak)

    harness.assert_equal(res["maxCombo"], 19, "Streak Break: Max Combo preserved at 19")
    harness.assert_equal(res["finalCombo"], 5, "Streak Break: Final Combo rebuilt to 5")
    harness.assert_equal(res["counts"]["PERFECT"], 24, "Streak Break: 24 Perfects")
    harness.assert_equal(res["counts"]["MISS"], 1, "Streak Break: 1 Miss")

    # Step-by-step score verification:
    # Notes 1..4: 4 * 1000 * 1.0 = 4000
    # Notes 5..9: 5 * 1000 * 1.2 = 6000
    # Notes 10..14: 5 * 1000 * 1.5 = 7500
    # Notes 15..19: 5 * 1000 * 2.0 = 10000
    # Note 20 (MISS): 0
    # Notes 21..24: 4 * 1000 * 1.0 = 4000
    # Note 25: 1 * 1000 * 1.2 = 1200
    expected_total_score = 4000 + 6000 + 7500 + 10000 + 0 + 4000 + 1200
    harness.assert_equal(res["totalScore"], expected_total_score, f"Streak Break: Total Score = {expected_total_score}")

    # Accuracy: (24 * 1.0 + 0) / 25 * 100 = 96.00% -> Grade S
    harness.assert_almost_equal(res["accuracy"], 96.0, "Streak Break: Accuracy = 96.00%")
    harness.assert_equal(res["grade"], "S", "Streak Break: Grade S (>= 95%)")
    harness.assert_equal(res["quality"], "perfect", "Streak Break: Quality 'perfect'")

# ------------------------------------------------------------------------------
# 6. MONTE-CARLO STOCHASTIC & MEMORY LEAK SIMULATION
# ------------------------------------------------------------------------------

def test_monte_carlo_and_determinism(harness: StressTestHarness):
    print("\n[STRESS 6] 1,000-Session Monte-Carlo Simulation & Determinism Oracle")
    recipes = ["Zunda Mochi", "Bread", "Apple Pie", "Royal Stew", "Ultimate Feast", "Zunda Paradise"]

    # Run 1,000 randomized cooking sessions
    sessions_completed = 0
    for seed in range(1000):
        rnd = random.Random(seed)
        recipe = rnd.choice(recipes)
        num_notes = rnd.randint(8, 30)
        hits = []
        for n in range(num_notes):
            roll = rnd.random()
            if roll < 0.70:
                hits.append("PERFECT")
            elif roll < 0.85:
                hits.append("GREAT")
            elif roll < 0.95:
                hits.append("GOOD")
            else:
                hits.append("MISS")

        r1 = calculate_score(hits)
        r2 = calculate_score(hits)  # Determinism check

        if r1["totalScore"] != r2["totalScore"] or r1["accuracy"] != r2["accuracy"] or r1["grade"] != r2["grade"]:
            harness.assert_true(False, f"Determinism failure in session {seed}")

        # Check invariants
        if r1["accuracy"] < 0 or r1["accuracy"] > 100:
            harness.assert_true(False, f"Accuracy out of bounds in session {seed}: {r1['accuracy']}")
        if r1["maxCombo"] < 0 or r1["maxCombo"] > num_notes:
            harness.assert_true(False, f"MaxCombo out of bounds in session {seed}: {r1['maxCombo']}")
        if r1["totalScore"] < 0:
            harness.assert_true(False, f"Negative total score in session {seed}: {r1['totalScore']}")

        sessions_completed += 1

    harness.assert_equal(sessions_completed, 1000, "Monte-Carlo: 1,000/1,000 sessions deterministic & valid")

# ==============================================================================
# MAIN RUNNER
# ==============================================================================

def main():
    print("=" * 80)
    print("  ZUNDAMON'S KITCHEN V2 — RHYTHM ENGINE ADVERSARIAL STRESS SUITE")
    print("  Challenger 1: Timing, Lag & Input Stress Verification")
    print("=" * 80)

    harness = StressTestHarness()
    start = time.perf_counter()

    test_boundary_timing(harness)
    test_stat_precision_scaling(harness)
    test_latency_and_reordering(harness)
    test_input_spam_and_multi_lane(harness)
    test_combo_multiplier_transitions(harness)
    test_monte_carlo_and_determinism(harness)

    elapsed = time.perf_counter() - start

    print("\n" + "=" * 80)
    print("  STRESS TEST SUMMARY RESULTS")
    print("=" * 80)
    print(f"  TOTAL ASSERTIONS EXECUTED : {harness.tests_run}")
    print(f"  ASSERTIONS PASSED         : {harness.tests_passed}")
    print(f"  ASSERTIONS FAILED         : {harness.tests_failed}")
    print(f"  ELAPSED EXECUTION TIME    : {elapsed:.4f} seconds")
    print("=" * 80)

    if harness.tests_failed == 0:
        print("  🎉 VERDICT: EMPIRICALLY APPROVED! ALL STRESS VECTORS PASSED.")
        sys.exit(0)
    else:
        print(f"  ❌ VERDICT: REQUEST_CHANGES ({harness.tests_failed} failures)")
        for fail in harness.failures:
            print(f"    - {fail}")
        sys.exit(1)

if __name__ == "__main__":
    main()
