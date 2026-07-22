# Project Plan: Zundamon's Kitchen V2 — Codebase Audit, Telemetry & Web Integration

## Overview
Decompose, execute, and verify the deep codebase audit, bug fixes, real-time game telemetry integration, and preflight verification for Zundamon's Kitchen V2 across Roblox server/client/shared scripts and the Zunda-OS 95 web portal (`docs/` and `site/`).

## Architecture & Requirements Summary
1. **R1. Deep Codebase Audit & Loose-Ends Fixes**:
   - Verify all RemoteEvent/RemoteFunction definitions in `ReplicatedStorage`.
   - Ensure zero `script.Parent` UI references in `StarterPlayerScripts`.
   - Ensure all modal/dialogue panels have `Visible = false` on startup in `ClientGuiBootstrap`.
   - Ensure top-level ScreenGuis have `ResetOnSpawn = false`.
   - Check `ServerScriptService` imports: use `ServerScriptService.Services.X` or `ServerScriptService.systems.X` (never `.Server.`).
   - Ensure `default.project.json` includes `"$ignoreUnknownInstances": true` under `"Workspace"`.
2. **R2. Real-Time Game Telemetry & Web Integration**:
   - Verify `WebInfoSyncService` in server scripts and `docs/api/game_info.json`.
   - Structure `game_info.json` with challenges, live banners, promo codes, player counts, and global stats.
   - Update `docs/index.html`, `docs/presskit.html`, `site/index.html` (and JS modules) to fetch `docs/api/game_info.json` dynamically with live ticker and event banners.
   - Synchronize `site/` and `docs/` using `sync_site.js`.
3. **R3. Preflight & Acceptance Verification**:
   - `python scripts/preflight_audit.py` returns 0 errors.
   - Reviewer, Challenger, and Forensic Auditor verification.

## Directory & Module Structure
- Roblox Source: `src/server/`, `src/client/`, `src/shared/`
- Workspace Config: `default.project.json`, `wally.toml`
- Scripts & Tools: `scripts/preflight_audit.py`, `scripts/sync_site.js`
- Web Hub: `docs/index.html`, `docs/presskit.html`, `docs/api/game_info.json`, `site/`

## Milestones

### Milestone 1: Deep Codebase Audit & Luau Bug Fixes
- **Objective**: Audit and fix all Luau scripts across `src/server`, `src/client`, `src/shared`. Ensure all RemoteEvents/RemoteFunctions exist, UI scripts follow `ClientGuiBootstrap` with modal `Visible = false` and `ResetOnSpawn = false`, import paths are consistent, and `default.project.json` has `"$ignoreUnknownInstances": true`.
- **Target Files**: `src/client/**/*`, `src/server/**/*`, `src/shared/**/*`, `default.project.json`
- **Dependencies**: None
- **Status**: DONE

### Milestone 2: Real-Time Game Telemetry & Web Hub Integration
- **Objective**: Enhance/verify `WebInfoSyncService` backend to sync game state to `docs/api/game_info.json`. Connect `docs/index.html`, `docs/presskit.html`, and `site/` web hubs to render real-time telemetry tickers, active daily challenges, live gacha banners, and community milestone progress without console errors. Run `sync_site.js`.
- **Target Files**: `src/server/Services/WebInfoSyncService.lua`, `docs/api/game_info.json`, `docs/index.html`, `docs/presskit.html`, `site/*`
- **Dependencies**: Milestone 1
- **Status**: IN_PROGRESS

### Milestone 3: Preflight Audit & End-to-End Acceptance Verification
- **Objective**: Execute `python scripts/preflight_audit.py` (must pass with 0 errors). Conduct independent review, adversarial testing, and Forensic Integrity Audit across all rules and requirements.
- **Target Files**: `scripts/preflight_audit.py`, all codebase & site files
- **Dependencies**: Milestones 1 & 2
- **Status**: PLANNED

## Verification & Audit Strategy
For each milestone:
1. **Exploration**: 3 Explorers analyze codebase, check contract rules, and report defect maps / integration plans.
2. **Implementation**: 1 Worker implements fixes, executes preflight check / node tests, and reports diffs & results.
3. **Review**: 2 Reviewers independently assess Luau correctness, decoupled UI rules, and telemetry integrity.
4. **Adversarial Verification**: 2 Challengers stress-test edge cases, missing remote calls, and web JSON parsing.
5. **Integrity Audit**: 1 Forensic Auditor performs static and execution analysis (HARD VETO on hardcoded cheating or fake logic).
