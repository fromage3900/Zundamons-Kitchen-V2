# Project Plan: Zundamon's Kitchen V2 — UI System Overhaul

## Overview
Overhaul and optimize the UI system for Zundamon's Kitchen V2 across client controllers, keybind dispatchers, startup UI boot scripts, and Rojo place build verification.

## Architecture & Requirements Summary
1. **R1. Centered Pea Wheel Radial Menu & Visibility**:
   - Fix `src/client/Controllers/PeaWheelController.lua` and radial UI instances.
   - Center overlay in middle of screen (`Position = UDim2.fromScale(0.5, 0.5)`, `AnchorPoint = Vector2.new(0.5, 0.5)`) when opened via Tab key, Q key, or hub button.
   - Ensure all 8 radial slices (inventory, cook, quests, compendium, materials, map, shop, settings) are 100% visible without clipping off-edge.
   - Maintain client UI decoupling rules (`ResetOnSpawn = false`, `Visible = false` on startup).

2. **R2. Single Source of Truth Keybind Dispatching**:
   - Fix keybind dispatching across `src/client/UIActionRegistry.lua` and individual client UI scripts (`PouchScript.client.lua`, `CraftingScript.client.lua`, `StoreScript.client.lua`, etc.).
   - Deduplicate `UserInputService.InputBegan` listeners so `UIActionRegistry.lua` acts as single source of truth.
   - Remove redundant `InputBegan` listeners in client UI scripts to prevent double-toggle open/close bugs.

3. **R3. Fast UI Boot & Traversal Performance**:
   - Optimize `src/client/Systems/000_LegacyOverlayCleanup.client.lua` and UI startup scripts.
   - Consolidate multiple `GetDescendants()` tree loops into a single single-pass tree traversal on PlayerGui load.
   - Eliminate blocking `WaitForChild` delays on UI panel initialization.

4. **R4. Rojo Build Compilation & Verification**:
   - Compile all changes into `build/Zundamons-kItchen.rbxl` using `rojo build default.project.json -o build/Zundamons-kItchen.rbxl`.
   - Verify `python scripts/preflight_audit.py` passes with 0 errors.

## Milestones

### Milestone 1: Centered Pea Wheel Radial Menu & Visibility Overhaul
- **Objective**: Fix `PeaWheelController.lua` centering (`Position = UDim2.fromScale(0.5, 0.5)`, `AnchorPoint = Vector2.new(0.5, 0.5)`). Ensure all 8 radial slices are fully visible without screen edge clipping. Verify startup modal visibility (`Visible = false`) and `ResetOnSpawn = false`.
- **Target Files**: `src/client/Controllers/PeaWheelController.lua`
- **Dependencies**: None
- **Status**: PLANNED

### Milestone 2: Single Source of Truth Keybind Dispatching
- **Objective**: Deduplicate keybind handling in `UIActionRegistry.lua` and remove duplicate `UserInputService.InputBegan` listeners in `PouchScript.client.lua`, `CraftingScript.client.lua`, `StoreScript.client.lua`, etc. Ensure clean single-keypress toggle for keys I, K, J, C, M, P, B, F1, Tab, Q.
- **Target Files**: `src/client/UIActionRegistry.lua`, `src/client/PouchScript.client.lua`, `src/client/CraftingScript.client.lua`, `src/client/StoreScript.client.lua` (and other UI client scripts)
- **Dependencies**: Milestone 1
- **Status**: PLANNED

### Milestone 3: Fast UI Boot & Traversal Performance
- **Objective**: Consolidate multiple `GetDescendants()` tree traversals in `000_LegacyOverlayCleanup.client.lua` and startup UI scripts into a single single-pass tree traversal on `PlayerGui` load. Replace blocking `WaitForChild` delays with non-blocking async references.
- **Target Files**: `src/client/Systems/000_LegacyOverlayCleanup.client.lua`, UI startup scripts
- **Dependencies**: Milestone 2
- **Status**: PLANNED

### Milestone 4: Rojo Build Compilation & Preflight Audit Verification
- **Objective**: Compile place file via `rojo build default.project.json -o build/Zundamons-kItchen.rbxl` cleanly. Verify `python scripts/preflight_audit.py` returns 0 errors. Conduct full gate review (Reviewers, Challengers, Forensic Auditor).
- **Target Files**: `default.project.json`, `build/Zundamons-kItchen.rbxl`, `scripts/preflight_audit.py`
- **Dependencies**: Milestones 1, 2, 3
- **Status**: PLANNED

## Verification & Audit Strategy
For each milestone:
1. **Exploration**: 3 Explorers analyze target scripts, configuration structures, and contract rules, returning detailed analysis reports.
2. **Implementation**: 1 Worker implements fixes, runs builds/tests/preflight check, and reports code diffs & verification output.
3. **Review**: 2 Reviewers independently assess Luau code quality, decoupled UI rules, keybind safety, and performance traversal.
4. **Adversarial Verification**: 2 Challengers stress-test edge cases, keybind spam, screen resize clipping, and traversal load times.
5. **Integrity Audit**: 1 Forensic Auditor performs static analysis and integrity validation (HARD VETO on hardcoded test hacks or fake logic).
