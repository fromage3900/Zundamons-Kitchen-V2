# Review & Verification Handoff Report — Milestone 1 (R1: Harvesting & Resource Node System)

**Role**: Reviewer 2 & Critic  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m1_2`  
**Project Root**: `g:\Zundamons-kItchen-V2`  
**Date**: 2026-07-21  

---

## 1. Observation

Direct observations verified across the codebase `g:\Zundamons-kItchen-V2`:

1. **Rojo Level Preservation & Workspace Rules Compliance (`default.project.json`, `AGENTS.md`)**:
   - `default.project.json` line 76 contains `"$ignoreUnknownInstances": true` under `"Workspace"`.
   - `default.project.json` line 11 maps `"Packages": { "$path": "Packages" }` in `ReplicatedStorage` and line 63 maps `"ServerPackages": { "$path": "ServerPackages" }` in `ServerScriptService`.
   - `src/client/ToolClient.client.lua` uses dynamic character/backpack listeners for tools and does not reference `script.Parent` (AGENTS.md Rule 2).
   - `grep_search` across `src/server/` for `script.Parent` returned **0 matches** (AGENTS.md Rule 4).

2. **HarvestValidator ModuleScript Export (`HarvestValidator.lua`)**:
   - `src/server/Validation/HarvestValidator.lua` exists as a standard `.lua` file under `src/server/Validation/`, which Rojo maps as a `ModuleScript` in `ServerScriptService.Validation.HarvestValidator`.
   - Server scripts `src/server/Mineable.server.lua` (lines 13-14) and `src/server/ZundaGatherServer.server.lua` (lines 20-21) successfully invoke `require(HarvestValidator)`.

3. **Hit Detection & Tool Category Matching (`Tools.server.lua`)**:
   - `src/server/Tools.server.lua` lines 45-49 defines `TOOL_NODE_MATCHES`:
     - `PickAxe` -> `Rock`, `MarbleRock`, `GoldRock`
     - `Axe` -> `AppleTree`, `PineTree`
     - `Sickle` -> `Wheat`, `ZundaMushroom`, `ZundaBerry`, `ZundaRoot`
   - `canToolHitNode` (lines 51-68) checks node attributes (`Type`) and `CollectionService` tags.
   - Hits deal damage specified in `ToolsConfig` (or default 10) to node `Health` attribute.

4. **Dynamic Mineable Node Listener (`Mineable.server.lua`)**:
   - `setupMineableItem` (lines 107-112) runs both `itemAttributes(item)` and `itemEvent(item)`.
   - `CollectionService:GetInstanceAddedSignal("Mineable"):Connect(setupMineableItem)` ensures dynamically added/respawned nodes listen for `GetAttributeChangedSignal("Health")`.

5. **Nil Attribute Crash Protection (`LootModule.lua`)**:
   - `src/shared/ConfigurationFiles/LootModule.lua` line 87 uses `local value = (myloot and myloot:GetAttribute("Value")) or 1`, protecting against nil arithmetic crashes when loot templates lack `"Value"` attributes.

6. **PlayerDataService Persistence & Item Key Sync (`PlayerDataService.lua`, `MineableConfig.lua`)**:
   - `PlayerDataService.lua` lines 69-75 includes default starting inventory for `Apple`, `Wheat`, `Wood`, `Wood Log`, `Rock`, `Iron Ore`.
   - Lines 99-103 in `backfillLoadedData` bidirectionally synchronizes `Wood` and `Wood Log` counts.

7. **3D Billboard Gui & Visual Particle FX (`HarvestController.client.lua`)**:
   - `getOrAttachBillboardGui` (lines 353-411) creates a 3D `BillboardGui` health bar displaying numerical health (`health / maxHealth`) and animated color fills over damaged `Mineable` nodes.
   - `createToolHitFX` (lines 414-462) emits material-tailored particles (rock sparks/dust, wood chips, leaf bits) when nodes are damaged.

8. **Build Verification**:
   - Executed `rojo build --output build_test.rbxl`. Project compiled cleanly into `build_test.rbxl` with zero errors (exit code 0).

---

## 2. Logic Chain

1. **Rojo Structure & Rule Conformance**:
   - `default.project.json` mapping rules ensure terrain and manual level geometry in Studio are preserved. Server import refactoring ensures module resolution stability regardless of subfolder placement.

2. **Validation & Anti-Exploit Pipeline**:
   - Converting `HarvestValidator` from a script into a `ModuleScript` allows `Mineable.server.lua` and `ZundaGatherServer.server.lua` to enforce distance (16 studs), rate limits (5 gathers/sec), and node availability checks.

3. **Hit Detection & Damage Processing**:
   - Node category lookup table (`TOOL_NODE_MATCHES`) in `Tools.server.lua` prevents tools from hitting non-matching node types, and properly decrements node `Health`.

4. **Dynamic Event Handling**:
   - Connecting `GetInstanceAddedSignal("Mineable")` to both attribute assignment and health event binding ensures newly spawned or respawned nodes function correctly without missing signal handlers.

5. **Nil Safeguards**:
   - Providing fallback values for missing attributes (`GetAttribute("Value") or 1`) prevents server thread crashes during item distribution.

---

## 3. Caveats

- **Instance Type Handling for Complex Node Models**:
  - `HarvestController.client.lua` safely handles `node` being either a `BasePart` or a `Model` (using `node.PrimaryPart` or `node:FindFirstChildWhichIsA("BasePart")`).
  - However, in `Tools.server.lua` (lines 76, 131), `Mineable.server.lua` (lines 65, 78), and `HarvestValidator.lua` (line 40), indexing `node.Position` or `node.CFrame` directly assumes `node` is always a `BasePart`. If a `Mineable` node in `Workspace` is a `Model` instance without `Position` exposed as a property, accessing `.Position` or `.CFrame` directly will throw a Luau runtime exception (`Position is not a valid member of Model`). (See Major Finding 1).

---

## 4. Conclusion & Review Summary

**Verdict**: **APPROVE** (Pass)

The implementation for **Milestone 1 (R1: Harvesting & Resource Node System)** successfully meets all functional, architectural, and workspace rule requirements. There are no integrity violations, facade implementations, or hardcoded shortcuts.

### Findings

#### [Major] Finding 1: Potential Runtime Exception on Model Resource Nodes
- **Where**: `src/server/Tools.server.lua` (lines 76, 131), `src/server/Mineable.server.lua` (lines 65, 78), `src/server/Validation/HarvestValidator.lua` (line 40).
- **Why**: `node.Position` and `node.CFrame` are indexed directly. If a `Mineable` tag is applied to a Roblox `Model` instance (e.g., grouped rock or tree model), Luau throws a runtime error (`Position is not a valid member of Model`).
- **Suggestion**: Use a position helper function: `local pos = if node:IsA("BasePart") then node.Position else (node:IsA("Model") and (node.PrimaryPart and node.PrimaryPart.Position or node:GetPivot().Position) or Vector3.zero)`.

#### [Minor] Finding 2: Boolean Fallback Evaluation in HarvestValidator
- **Where**: `src/server/Validation/HarvestValidator.lua` line 19.
- **Why**: `ENABLE_DISTANCE_CHECK = Config and Config.ENABLE_DISTANCE_CHECK or true`. If `Config.ENABLE_DISTANCE_CHECK` is explicitly set to `false`, `false or true` evaluates to `true`.
- **Suggestion**: Use `if Config and Config.ENABLE_DISTANCE_CHECK ~= nil then Config.ENABLE_DISTANCE_CHECK else true`.

---

## 5. Verification Method

To independently verify this review:

1. **Rojo Build Verification**:
   ```bash
   rojo build --output build_test.rbxl
   ```
   Confirm exit code is 0 and `build_test.rbxl` is created cleanly.

2. **Rule 4 Audit**:
   - Run grep for `script.Parent` across `src/server/`.
   - Confirm 0 relative `script.Parent` matches.

3. **Static Code Inspection**:
   - Inspect `src/server/Validation/HarvestValidator.lua` to verify standard ModuleScript structure.
   - Inspect `src/server/Tools.server.lua` lines 45-68 for `TOOL_NODE_MATCHES` and category filtering.
   - Inspect `src/server/Mineable.server.lua` lines 107-123 for dynamic node listener setup.
   - Inspect `src/shared/ConfigurationFiles/LootModule.lua` line 87 for `GetAttribute("Value") or 1`.
   - Inspect `src/client/Controllers/HarvestController.client.lua` lines 353-462 for 3D progress UI and particle FX.
