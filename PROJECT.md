# Project: Dynamic Rhythm Cooking Minigame for Zundamon's Kitchen V2

## Architecture

The Dynamic Rhythm Cooking Minigame provides an interactive, deterministic, multi-lane rhythm gameplay experience during cooking sessions in Zundamon's Kitchen V2.

```
+---------------------------------------------------------------------------------------------------+
|                                          CLIENT                                                   |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | CookingController / RhythmView                                                              |  |
|  | - 4 Culinary Lanes: Chopping 🔪, Stirring 🥣, Simmering 🔥, Seasoning 🧂                     |  |
|  | - Responsive Controls: Desktop (DFJK / Arrow Keys / Space) + Mobile Dual-Thumb Touch Pads    |  |
|  | - Frame-independent Note Interpolation & Pastel VFX (Zunda Green, Gold, Pink, Mint)       |  |
|  | - Immediate Local Prediction & Visual Judgment Popups ("PERFECT!! ✨", "GREAT! 🍡", etc.)  |  |
|  +------------------------------+------------------------------------+--------------------------+  |
|                                 |                                    |                            |
|                                 v                                    v                            |
|             +----------------------------------+    +----------------------------------+          |
|             | ZundaSoundController & VO        |    | RhythmEngine (Shared Evaluation) |          |
|             | - Hit SFX (Perfect, Great, Miss) |    | - Timing window evaluator        |          |
|             | - VOICEVOX Zundamon Cheerleading |    | - Combo multiplier calculator    |          |
|             |   (Barge-in + Cooldowns)         |    | - S/A/B/C/F Grade generator      |          |
|             +----------------------------------+    +----------------+-----------------+          |
+----------------------------------------------------------------------|----------------------------+
                                                                       |
                                                CookingHit RemoteEvent | (sessionId, noteIndex, lane)
                                                                       v
+---------------------------------------------------------------------------------------------------+
|                                          SERVER                                                   |
|                                                                                                   |
|  +---------------------------------------------------------------------------------------------+  |
|  | CookingService                                                                              |  |
|  | - Validates station proximity & reserves ingredients via PlayerDataService.mutate           |  |
|  | - Spawns authoritative ECS CookingSession (firstTargetAt, noteInterval, windows)            |  |
|  | - Authoritatively validates hit offsets against server timestamps                          |  |
|  | - Resolves final score, grade, and dish quality (perfect/great/ok)                          |  |
|  +----------------------------------------------+----------------------------------------------+  |
|                                                 |                                                 |
|                                                 v CookingService.CookCompleted Bindable           |
|  +---------------------------------------------------------------------------------------------+  |
|  | EndlessLoopWiring & Progression Cascades                                                    |  |
|  | - RewardCore.settle: persists dish, awards bonus gold & XP                                  |  |
|  | - syncPlayerWardrobe: grants Style Points & Chef Stats (Precision, Speed)                   |  |
|  | - ChallengeModeService: increments combo streaks and wave progression                       |  |
|  | - DailyChallengeService: updates daily cook & quality quest targets                         |  |
|  +---------------------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## Feature Inventory

| # | Feature | Description | Milestone | Source |
|---|---|---|---|---|
| F1 | Multi-Lane Rhythm Data Model & Chart Generator | 4 culinary lanes (Chopping, Stirring, Simmering, Seasoning) with recipe-seeded deterministic beatmaps and BPM tempos | M1 | ORIGINAL_REQUEST §R1 |
| F2 | Discrete Timing & Accuracy Evaluation Engine | Timing window evaluation (Perfect $\pm 0.12\text{s}$, Great $\pm 0.28\text{s}$, Good $\pm 0.45\text{s}$, Miss), hit offset computation | M1 | ORIGINAL_REQUEST §R1 |
| F3 | Dynamic Combo & Multiplier Tracker | Combo streak tracking, multiplier scaling ($1.0\times \rightarrow 3.0\times$), and streak breaks on misses | M1 | ORIGINAL_REQUEST §R1 |
| F4 | Infinity Nikki Pastel UI Presentation | Glassmorphic 4-track panel, note visual interpolation, pastel colors (`#A0D296`, `#FFC850`, `#FF96C8`, `#91D7C3`), `UIScale` viewport responsiveness | M2 | ORIGINAL_REQUEST §R2 |
| F5 | Animated Hit Feedback & Visual Bursts | Animated judgment banners ("PERFECT!! ✨", "GREAT! 🍡", "GOOD! 🌸", "MISS... 💧"), particle sparkles, combo fire auras | M2 | ORIGINAL_REQUEST §R2 |
| F6 | Dynamic SFX & Zundamon VOICEVOX Cheerleading | Hit SFX triggers, Zundamon voice cues on start, high combos ($10\times, 20\times$), misses, and final rank with single-channel barge-in and cooldowns | M2 | ORIGINAL_REQUEST §R2 |
| F7 | Letter Grading & Score Evaluator | Total score, accuracy percentage, max combo, and discrete letter grades ($S \ge 95\%$, $A \ge 85\%$, $B \ge 70\%$, $C \ge 50\%$, $F < 50\%$) | M3 | ORIGINAL_REQUEST §R3 |
| F8 | Server-Authoritative Reward & Quality Settlement | Authoritative timestamp validation in `CookingService`, mapping grades to dish qualities (`perfect`, `great`, `ok`), and atomic `PlayerDataService.mutate` settlement | M3 | ORIGINAL_REQUEST §R3 |
| F9 | Progression Cascades (Stats, Style, Quests) | Style Points gains, Chef Stat increments (Precision/Speed), Daily Challenge updates, and Challenge Mode progression | M3 | ORIGINAL_REQUEST §R3 |
| F10 | Desktop & Mobile Cross-Platform Controls | DFJK keys, Arrow keys, Spacebar input, and dedicated mobile touch screen hit pads with decoupled `ClientGuiBootstrap` (`ResetOnSpawn = false`) | M4 | ORIGINAL_REQUEST §R4 |
| F11 | End-to-End Test Suite & Verification | 4-tier requirement-driven test suite (Tiers 1-4) + Tier 5 adversarial stress hardening and CI gate verification | M5 | ORIGINAL_REQUEST §Verification |

---

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|---|---|---|---|
| M1 | Core Rhythm Engine & Beatmaps | Implement `src/shared/Rhythm/RhythmEngine.lua` and `src/shared/ConfigurationFiles/RhythmBeatmapConfig.lua` | none | DONE |
| M2 | Visual Presentation & Audio/VO | Build 4-lane UI in `src/client/Controllers/CookingController.lua`, particle animations, and hook `ZundaSoundController` / `VoiceConfig` cheerleading cues | M1 | DONE |
| M3 | Scoring, Grading & Server Progression | Implement `src/shared/Rhythm/RhythmScoreEvaluator.lua`, update `src/server/Services/CookingService.lua`, and enrich `EndlessLoopWiring.server.lua` | M1 | DONE |
| M4 | Cross-Platform Controls & Integration | Add DFJK/Arrow/Space keybindings + mobile touch pads, hook `CraftingScript.client.lua` and kitchen station prompt flows | M2, M3 | DONE |
| M5 | E2E Testing, Adversarial Hardening & CI Gates | Complete E2E test suite (Tiers 1-5), review gates, adversarial stress tests, and forensic integrity audit | M1, M2, M3, M4 | DONE |

---

## Interface Contracts

### 1. `RhythmBeatmapConfig.lua`
- `RhythmBeatmapConfig.Lanes`:
  ```lua
  {
      CHOP = { id = 1, name = "Chop", icon = "🔪", key = "D", color = Color3.fromRGB(160, 210, 150) },
      STIR = { id = 2, name = "Stir", icon = "🥣", key = "F", color = Color3.fromRGB(255, 200, 80) },
      SIMMER = { id = 3, name = "Simmer", icon = "🔥", key = "J", color = Color3.fromRGB(255, 150, 200) },
      SEASON = { id = 4, name = "Season", icon = "🧂", key = "K", color = Color3.fromRGB(145, 215, 195) },
  }
  ```
- `RhythmBeatmapConfig.getChart(recipeName: string, durationSeconds: number, difficulty: string?): Chart`
  - Returns: `{ bpm = number, totalNotes = number, notes = { { index = number, targetTime = number, laneId = number, duration = number? } } }`

### 2. `RhythmEngine.lua`
- `RhythmEngine.evaluateHit(targetTime: number, hitTime: number, statPrecision: number?): (Judgment, number)`
  - Judgment: `"PERFECT"` ($\le 0.12\text{s}$), `"GREAT"` ($\le 0.28\text{s}$), `"GOOD"` ($\le 0.45\text{s}$), `"MISS"` ($> 0.45\text{s}$)
  - Offset: signed time delta in seconds (`hitTime - targetTime`).
- `RhythmEngine.getComboMultiplier(combo: number): number`
  - Returns multiplier from $1.0\times$ (0-4 combo) to $3.0\times$ (20+ combo).
- `RhythmEngine.calculateScore(hits: { Judgment }): { totalScore: number, accuracy: number, maxCombo: number, grade: string, counts: table }`
  - Grades: `S` ($\ge 95\%$), `A` ($\ge 85\%$), `B` ($\ge 70\%$), `C` ($\ge 50\%$), `F` ($< 50\%$).

### 3. Server Remotes & Bindables
- `CraftFunction.OnServerInvoke(player: Player, recipeName: string, stationPos: Vector3): SessionPayload`
  - Returns `{ ok = boolean, sessionId = string, chart = Chart, firstTargetAt = number, windows = Windows }`
- `CookingHit.OnServerEvent(player: Player, sessionId: string, noteIndex: number, laneId: number)`
  - Server evaluates hit against `firstTargetAt + note.targetTime`, records judgment, and updates session streak.
- `CookingResult:FireClient(player: Player, resultPayload)`
  - Sends `{ ok = boolean, recipe = string, quality = string, grade = string, score = number, accuracy = number, maxCombo = number, rewards = table }`
- `CookingService.CookCompleted:Fire(player: Player, recipeId: string, quality: string, minigameMetrics: table)`
  - Transmits full metrics to `EndlessLoopWiring.server.lua` for progression distribution.

---

## Code Layout & Ownership

- `src/shared/Rhythm/RhythmEngine.lua` — Core deterministic timing, hit judgment, combo multipliers, scoring (M1, Worker M1)
- `src/shared/ConfigurationFiles/RhythmBeatmapConfig.lua` — 4-lane chart definitions and procedural recipe chart generator (M1, Worker M1)
- `src/shared/Rhythm/RhythmScoreEvaluator.lua` — Grade classification and reward scaling formulas (M3, Worker M3)
- `src/client/Controllers/CookingController.lua` — Client UI view, note renderer, visual/audio feedback, and cross-platform controls (M2 & M4, Worker M2/M4)
- `src/server/Services/CookingService.lua` — Authoritative session management, timestamp validation, Matter ECS session step (M3, Worker M3)
- `src/server/systems/EndlessLoopWiring.server.lua` — Event wiring for Style Points, Chef Stats, and Quests (M3, Worker M3)
- `tests/e2e/rhythm/` — E2E test runner and test cases (E2E Test Writer)
