## 2026-07-21T17:54:24Z
You are the Worker for Milestone 1 (R1: Harvesting & Resource Node System).
Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1
Project root: g:\Zundamons-kItchen-V2
Plan file: g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md
Workspace rules: g:\Zundamons-kItchen-V2\AGENTS.md
Explorer Reports:
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m1_1\handoff.md
- g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m1_2\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks for Milestone 1 Implementation:
1. **AGENTS.md Rule 2 Fix**: Refactor or remove `src/client/ToolClient.client.lua` to eliminate `script.Parent` runtime errors in `StarterPlayerScripts`. Use `ClientGuiBootstrap` / `PlayerGui` or dynamic tool listening.
2. **HarvestValidator ModuleScript Fix**: Rename `src/server/Validation/HarvestValidator.server.lua` to `src/server/Validation/HarvestValidator.lua` (ModuleScript) so `require()` calls in `ZundaGatherServer` and `Mineable` succeed.
3. **Tool Hit Detection Fix**: Update `src/server/Tools.server.lua` hit detection logic so tool types (`PickAxe`, `Axe`, `Sickle`) correctly match resource node types/categories (`Rock`, `AppleTree`, `Wheat`, etc.) and deal damage.
4. **Dynamic Mineable Event Fix**: In `src/server/Mineable.server.lua`, update `GetInstanceAddedSignal("Mineable")` to call `itemEvent(item)` so dynamically spawned or respawned mineables listen to health changes, drop loot, and respawn properly.
5. **LootModule Nil Protection**: In `src/shared/ConfigurationFiles/LootModule.lua`, update `assignLoot` so missing `"Value"` attributes default to `1` (`(myloot and myloot:GetAttribute("Value")) or 1`), preventing nil arithmetic crashes.
6. **Item Naming & Inventory Sync**: Standardize item key names (e.g. `"Wood Log"` vs `"Wood"`) across `MineableConfig`, `GatherConfig`, `LootModule`, and `PlayerDataService`.
7. **Health/Progress UI & Particle Feedback**: Implement 3D BillboardGui or HUD progress bars and hit particles (sparks, stone dust, wood chips) for tool mining/chopping/harvesting in client scripts (`HarvestController.client.lua`).
8. **AGENTS.md Rule 4 Import Path Consistency**: Ensure all server scripts use explicit `game:GetService("ServerScriptService").Services.X` or `ServerScriptService.systems.X` import paths without relative `script.Parent.Services` or `.Server.` segments.
9. **Tool Equipping & Hotbar Sync**: Update `ToolManager.server.lua` and `InventoryServer.server.lua` so equipping tools updates hotbar ObjectValues cleanly without breaking character inventory.
10. **Build & Test Verification**: Run syntax checks, linter (`selene` if available), build checks (`rojo build`), and document all results in your `handoff.md` and `progress.md`.

Write your full implementation summary and verification results to `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1\handoff.md`.
