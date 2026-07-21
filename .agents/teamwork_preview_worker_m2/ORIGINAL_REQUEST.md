## 2026-07-21T18:00:46Z
<USER_REQUEST>
You are Worker 3 for Milestone 2 (R2: Cooking & Rhythm Minigame System).
Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2
Project root: g:\Zundamons-kItchen-V2
Plan file: g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md
Workspace rules: g:\Zundamons-kItchen-V2\AGENTS.md
Explorer Reports:
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_1\handoff.md
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_3\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks for Milestone 2 Implementation:
1. **Relocate & Fix RewardCore.lua**: Move `RewardCore.lua` from `src/shared/ConfigurationFiles/RewardCore.lua` to `src/server/Services/RewardCore.lua`. Ensure import uses `game:GetService("ServerScriptService").Services.PlayerDataService` (AGENTS.md Rule 4).
2. **Deactivate Legacy CookingSession**: Remove or disable legacy `CookingSession.server.lua` so it doesn't intercept `CookingHit` RemoteEvents or interfere with `CookingValidationSystem.lua`.
3. **Unified Client Cooking Controller (`CookingController.lua`)**: Create `src/client/Controllers/CookingController.lua` implementing the rhythm minigame client UI:
   - Spawns 10 notes matching server expectations.
   - Precise timing hit windows (Perfect, Great, Ok, Miss).
   - Multi-input support (Spacebar, Mobile Touch, Gamepad).
   - Visual feedback: floating rating text ("PERFECT!", "GREAT!", "OK!", "MISS!") and live combo meter updates.
   - Fires hit and miss remotes to the server.
   - Strictly adheres to AGENTS.md Rule 2 (`ClientGuiBootstrap` / `PlayerGui`, `ResetOnSpawn = false`, `panel.Visible = false` at startup).
4. **Server Cooking Validation System (`CookingValidationSystem.lua`)**: Update `src/server/Services/CookingValidationSystem.lua` to:
   - Validate recipe crafting requirements against player inventory in `PlayerDataService`.
   - Deduct required raw ingredients.
   - Validate client note hit timing and calculate final accuracy score.
   - Call `RewardCore` to award Gold, Chef XP, Level progression, and place the cooked dish directly into player inventory (`PlayerDataService`).
5. **Fix Duplicate Auto-Save Loop**: Remove redundant 60s auto-save `task.spawn` loop in `src/server/Services/PlayerDataService.lua`.
6. **Build & Test Verification**: Verify project compilation with `rojo build`. Document all changes in `handoff.md`.
</USER_REQUEST>
