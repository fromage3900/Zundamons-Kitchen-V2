# E2E Test Infra: Dynamic Rhythm Cooking Minigame

## Test Philosophy
- **Opaque-box & Requirement-driven**: Derived strictly from `ORIGINAL_REQUEST.md` (R1-R4) and user-facing specifications. Tests evaluate observable behaviors, timing math, accuracy calculations, grading outputs, cross-platform inputs, and server reward outcomes without relying on private implementation internals.
- **Methodology**: Systematic 4-Tier Test Design (Category-Partition, Boundary Value Analysis, Pairwise Combinatorial Testing, Real-World Workload Testing) + Tier 5 Adversarial Stress Hardening.

---

## Feature Inventory & Test Coverage Matrix

| # | Feature | Requirement Source | Tier 1 (Coverage) | Tier 2 (Boundary) | Tier 3 (Pairwise) | Tier 4 (Scenarios) |
|---|---|---|:---:|:---:|:---:|:---:|
| F1 | Multi-Lane Rhythm Data Model & Chart Generator | ORIGINAL_REQUEST §R1 | ≥5 | ≥5 | ✓ | ✓ |
| F2 | Discrete Timing & Accuracy Evaluation Engine | ORIGINAL_REQUEST §R1 | ≥5 | ≥5 | ✓ | ✓ |
| F3 | Dynamic Combo & Multiplier Tracker | ORIGINAL_REQUEST §R1 | ≥5 | ≥5 | ✓ | ✓ |
| F4 | Infinity Nikki Pastel UI Presentation | ORIGINAL_REQUEST §R2 | ≥5 | ≥5 | ✓ | ✓ |
| F5 | Animated Hit Feedback & Visual Bursts | ORIGINAL_REQUEST §R2 | ≥5 | ≥5 | ✓ | ✓ |
| F6 | Dynamic SFX & Zundamon VO Cheerleading | ORIGINAL_REQUEST §R2 | ≥5 | ≥5 | ✓ | ✓ |
| F7 | Letter Grading & Score Evaluator | ORIGINAL_REQUEST §R3 | ≥5 | ≥5 | ✓ | ✓ |
| F8 | Server-Authoritative Reward & Quality Settlement | ORIGINAL_REQUEST §R3 | ≥5 | ≥5 | ✓ | ✓ |
| F9 | Progression Cascades (Stats, Style, Quests) | ORIGINAL_REQUEST §R3 | ≥5 | ≥5 | ✓ | ✓ |
| F10 | Desktop & Mobile Cross-Platform Controls | ORIGINAL_REQUEST §R4 | ≥5 | ≥5 | ✓ | ✓ |

---

## Test Architecture

- **Test Runner Location**: `tests/rhythm_test_runner.lua` (executable via Luau or test driver script `scripts/run_rhythm_tests.py` / `tests/test_rhythm_engine.py`).
- **Test Categories**:
  - `tests/e2e/test_rhythm_engine.lua` (Tier 1 & Tier 2: Chart generation, timing offsets, combo math, grading, score bounds).
  - `tests/e2e/test_rhythm_progression.lua` (Tier 1, Tier 2, Tier 3: Quality mapping, style point awards, chef stats integration, quest triggers).
  - `tests/e2e/test_rhythm_scenarios.lua` (Tier 3 & Tier 4: Full cooking workflows, cross-platform input simulation, dropped inputs, network latency jitter, combo milestone cheerleading).
- **Execution & Pass/Fail Semantics**:
  - All test files return exit code `0` on 100% pass.
  - Zero tolerance for test assertions failures.

---

## Coverage Thresholds
- **Tier 1 (Feature Coverage)**: ≥5 test cases per feature (50 total)
- **Tier 2 (Boundary & Corner Cases)**: ≥5 test cases per feature (50 total)
- **Tier 3 (Cross-Feature Combinations)**: ≥10 multi-feature interaction tests
- **Tier 4 (Real-World Application Scenarios)**: ≥5 full-gameplay integration scenarios
- **Total Minimum Target**: ≥115 deterministic test cases across Tiers 1-4.
