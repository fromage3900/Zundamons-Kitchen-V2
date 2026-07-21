# Project Plan: Zundamon's Kitchen V2

## Overview
Refactor, complete, and integrate the core gameplay loop (Harvest → Cook → Serve → Reward → Repeat) for Zundamon's Kitchen V2, adhering strictly to AGENTS.md rules and clean Rojo architectural principles.

## Workspace & Rojo Rules Compliance Checklist
- [ ] `$ignoreUnknownInstances: true` verified in `default.project.json` under `"Workspace"`.
- [ ] No `script.Parent` UI references in `StarterPlayerScripts`; use `ClientGuiBootstrap` / `PlayerGui`.
- [ ] `gui.ResetOnSpawn = false` set on top-level ScreenGuis.
- [ ] Modal/dialogue panels `panel.Visible = false` at startup.
- [ ] Wally dependencies correctly declared (`ProfileService` in `[server-dependencies]`), mappings in `default.project.json` match `ReplicatedStorage.Packages` and `ServerScriptService.ServerPackages`, `.gitignore` configured.
- [ ] Path imports in server scripts use `ServerScriptService.Services.X` or `ServerScriptService.systems.X` without `.Server.` prepended.

## Milestones

### Milestone 1: Requirement R1 - Harvesting & Resource Node System
- **Objective**: Players equip tools (Axe, Pickaxe, Sickle), swing to deal damage to resource nodes, see visual progress bars and particle effects, receive item drops, and save inventory changes in `PlayerDataService`.
- **Target Files/Modules**: `src/client/ToolClient.client.lua`, `src/server/Validation/HarvestValidator.lua`, `src/server/Tools.server.lua`, `src/server/Mineable.server.lua`, `src/shared/ConfigurationFiles/LootModule.lua`, `src/client/Controllers/HarvestController.client.lua`.
- **Dependencies**: None.
- **Status**: DONE

### Milestone 2: Requirement R2 - Cooking & Rhythm Minigame System
- **Objective**: Initiate crafting recipes leading to a server-validated rhythm minigame (`CookingValidationSystem`). Calculate accuracy grades (perfect, great, ok) for quality bonuses, gold rewards, chef XP, and dish delivery into inventory.
- **Target Files/Modules**: `src/client/Controllers/CookingController.lua`, `src/server/Services/CookingValidationSystem.lua`, `src/shared/ConfigurationFiles/Recipes.lua`, `src/server/Services/RewardCore.lua`.
- **Dependencies**: Milestone 1 (PlayerDataService / Inventory integration).
- **Status**: DONE

### Milestone 3: Requirement R3 - Guest Serving & Economy Loop
- **Objective**: Customer NPCs spawn in `workspace.Guests`, display requested recipes and gold rewards, accept dishes from player inventory, despawn smoothly, and trigger gold/chef XP rewards via `RewardCore`.
- **Target Files/Modules**: `src/server/Services/GuestService.lua`, `src/client/Controllers/GuestUIController.lua`, `src/server/Services/RewardCore.lua`.
- **Dependencies**: Milestone 2 (Dishes and inventory).
- **Status**: IN_PROGRESS

### Milestone 4: Requirement R4 - Real-time HUD Synchronization
- **Objective**: Dynamically update HUD UI elements (`ZundaHUD`, `ChefPill`, `XPBar`, `ComboMeter`, inventory notifications) in real-time on stat/inventory changes without manual GUI refreshes.
- **Target Files/Modules**: `src/client/controllers/HUDController.lua`, `src/client/bootstrap/ClientGuiBootstrap.lua`, `src/shared/RemoteEvents`.
- **Dependencies**: Milestones 1-3.
- **Status**: PLANNED

## Verification & Audit Strategy
For each milestone:
1. **Exploration**: 3 Explorers analyze code, detect bugs/rule violations, propose fix strategy.
2. **Implementation**: 1 Worker implements fix and runs luau analysis/tests/checks.
3. **Review**: 2 Reviewers independently review code correctness and workspace compliance.
4. **Adversarial Verification**: 2 Challengers stress-test logic.
5. **Integrity Audit**: 1 Forensic Auditor performs integrity verification (HARD VETO).
