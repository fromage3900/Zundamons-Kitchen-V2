# BRIEFING — 2026-07-21T18:02:30Z

## Mission
Implement Milestone 2: Relocate RewardCore.lua, deactivate legacy CookingSession.server.lua, create unified CookingController.lua client UI controller, update CookingValidationSystem.lua, fix duplicate auto-save loop in PlayerDataService.lua, verify with `rojo build`.

## 🔒 My Identity
- Archetype: implementer / qa / specialist
- Roles: implementer, qa, specialist
- Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2
- Original parent: 85d1c382-dde2-40bc-9e91-9cae049af0ef
- Milestone: Milestone 2 (R2: Cooking & Rhythm Minigame System)

## 🔒 Key Constraints
- AGENTS.md Rule 1: `$ignoreUnknownInstances: true` under Workspace in default.project.json
- AGENTS.md Rule 2: Client UI decoupling & visibility (ClientGuiBootstrap/PlayerGui, ResetOnSpawn = false, panel.Visible = false on startup)
- AGENTS.md Rule 3: Wally package structure & dependencies
- AGENTS.md Rule 4: ServerScriptService path consistency (`ServerScriptService.Services.X` or `ServerScriptService.systems.X`, no extra `.Server.`)
- Integrity Mandate: DO NOT CHEAT. Real logic only. No hardcoding or dummy implementations.

## Current Parent
- Conversation ID: 85d1c382-dde2-40bc-9e91-9cae049af0ef
- Updated: 2026-07-21T18:02:30Z

## Task Summary
- **What to build**:
  1. Relocate RewardCore.lua to `src/server/Services/RewardCore.lua` and fix imports.
  2. Deactivate legacy CookingSession.server.lua.
  3. Create unified `src/client/Controllers/CookingController.lua`.
  4. Update `src/server/Services/CookingValidationSystem.lua`.
  5. Fix duplicate 60s auto-save loop in `src/server/Services/PlayerDataService.lua`.
  6. Verify build with `rojo build`.
- **Success criteria**: All 6 tasks completed, code compiles with `rojo build`, zero lint/runtime errors, tests pass.
- **Interface contracts**: PROJECT.md / AGENTS.md
- **Code layout**: src/client/Controllers, src/server/Services, etc.

## Key Decisions Made
- Relocated RewardCore to `src/server/Services/RewardCore.lua` and updated `d.total_gold_earned` on gold addition.
- Removed legacy `CookingSession.server.lua` to avoid `CookingHit` event collisions.
- Created `CookingController.lua` strictly adhering to AGENTS.md Rule 2 (`ClientGuiBootstrap`, `ResetOnSpawn = false`, `panel.Visible = false` on startup).
- Updated `CookingValidationSystem.lua` to validate recipe crafting requirements, deduct raw ingredients, calculate quality with `craftConfig.calculateQuality`, call `RewardCore` for gold/XP/level sync, and add cooked dish directly to `PlayerDataService`.
- Removed duplicate 60s auto-save loop from `PlayerDataService.lua`.

## Artifact Index
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2\ORIGINAL_REQUEST.md — Original User Request
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2\progress.md — Progress log & heartbeat
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2\handoff.md — Final handoff report

## Change Tracker
- **Files modified**:
  - `src/server/Services/RewardCore.lua` (Created)
  - `src/shared/ConfigurationFiles/RewardCore.lua` (Deleted)
  - `src/server/CookingSession.server.lua` (Deleted)
  - `src/client/Controllers/CookingController.lua` (Created)
  - `src/client/TimedCookingScript.client.lua` (Updated)
  - `src/client/ui/cooking/components/CookingHUD.lua` (Updated)
  - `src/client/ClientMain.client.lua` (Updated)
  - `src/server/Services/CookingValidationSystem.lua` (Created)
  - `src/server/systems/cooking/CookingValidationSystem.lua` (Updated)
  - `src/server/Services/PlayerDataService.lua` (Updated)
  - `src/server/CraftManager.server.lua` (Updated)
  - `src/server/AdvancedRewards.server.lua` (Updated)
  - `src/server/FishingServer.server.lua` (Updated)
  - `src/server/ServingSystem.server.lua` (Updated)
  - `src/shared/ConfigurationFiles/LootModule.lua` (Updated)
- **Build status**: `rojo build` PASSED (0 errors)
- **Pending issues**: None

## Quality Status
- **Build/test result**: Pass
- **Lint status**: Clean
- **Tests added/modified**: Rojo build verified

## Loaded Skills
- None
