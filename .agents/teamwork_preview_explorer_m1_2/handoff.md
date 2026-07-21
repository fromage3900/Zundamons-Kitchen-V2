# Handoff Report: Harvesting & Resource Node System (Milestone 1 - R1)

## 1. Observation

Direct observations from codebase inspection across `src/`:

### A. Missing Target Files Referenced in Plan / Prompt
- **`src/shared/Shared/Config/ResourceNodes.lua`**: Does NOT exist in workspace. Config is split across:
  - `src/shared/ConfigurationFiles/GatherConfig.lua`: lines 16-77 (Click resources: `ZundaFlower`, `ZundaPea`, `Zunda Mushroom`, `Zunda Berry`, `Zunda Root`, `SaltedPeaBouquet`, `CarrotPlot`)
  - `src/shared/ConfigurationFiles/MineableConfig.lua`: lines 6-68 (Tool nodes: `Rock`, `MarbleRock`, `GoldRock`, `Wheat`, `AppleTree`, `PineTree`, `ZundaMushroom`, `ZundaBerry`, `ZundaRoot`)
  - `src/shared/ConfigurationFiles/HarvestConfig.lua`: lines 6-55 (Interactions, cooldowns, UI colors, particle settings)
  - `src/shared/Shared/Config/HarvestNodeVariants.lua`: lines 6-93 (Mesh IDs, scale ranges, sway ranges)
- **`src/server/services/HarvestService.lua`**: Does NOT exist in workspace. Server harvesting logic is split across:
  - `src/server/ZundaGatherServer.server.lua`: lines 137-263 (`HarvestNode` remote listener for click-to-gather)
  - `src/server/Mineable.server.lua`: lines 39-103 (Health listener and loot distribution for mineable tool nodes)
  - `src/server/Tools.server.lua`: lines 61-120 (`Activated` RemoteFunction handler for tool swinging damage)
  - `src/server/Validation/HarvestValidator.server.lua`: lines 96-130 (`validateHarvest` function)

### B. Critical Runtime Errors & Broken Connections
1. **Fatal Require Error on `HarvestValidator.server.lua`**:
   - `src/server/Validation/HarvestValidator.server.lua` is a `.server.lua` script.
   - `src/server/ZundaGatherServer.server.lua` line 20-21:
     `local HarvestValidator = SSS:FindFirstChild("Validation") and SSS.Validation:FindFirstChild("HarvestValidator")`
     `local validateHarvest = HarvestValidator and require(HarvestValidator).validateHarvest`
   - `src/server/Mineable.server.lua` line 13-14:
     `local HarvestValidator = SSS:FindFirstChild("Validation") and SSS.Validation:FindFirstChild("HarvestValidator")`
     `local validateHarvest = HarvestValidator and require(HarvestValidator).validateHarvest`
   - **Observation**: Calling `require()` on a Script (`.server.lua`) in Luau fails with runtime error: `Attempt to require a script that is not a ModuleScript`.

2. **Broken Tool Hit Detection in `Tools.server.lua`**:
   - `src/server/Tools.server.lua` lines 49-56:
     ```lua
     for _, node in pairs(CollectionService:GetTagged("Mineable")) do
         if node.Parent and CollectionService:HasTag(node, toolType) then
             local dist = (node.Position - origin).Magnitude
             if dist <= HIT_RADIUS then table.insert(targets, { node = node, dist = dist }) end
         end
     end
     ```
   - **Observation**: `toolType` evaluates to `"Axe"`, `"PickAxe"`, or `"Sickle"`. Nodes in workspace only have tags `"Mineable"` and node category (e.g. `"Rock"`). No system adds `"PickAxe"` to `"Rock"` nodes, so `CollectionService:HasTag(node, "PickAxe")` returns `false`, causing all tool swings to hit 0 targets and deal 0 damage.

3. **Potential Nil Arithmetic Crash in `LootModule.lua`**:
   - `src/shared/ConfigurationFiles/LootModule.lua` lines 86-93:
     ```lua
     function assignLoot(player, lootname, myloot)
         local value = myloot:GetAttribute("Value")
         local data = PlayerDataService.getOrCreate(player)
         if not data[lootname] then
             data[lootname] = value
         else
             data[lootname] = data[lootname] + value
         end
     ```
   - **Observation**: `myloot:GetAttribute("Value")` returns `nil` if the template item in `ReplicatedStorage.Loot` lacks a `"Value"` attribute. Line 92 then attempts `data[lootname] + nil`, causing a fatal runtime error.

4. **Missing UI & Particle Feedback for Tool Mining**:
   - `src/client/Controllers/HarvestController.client.lua` lines 48-94 & 97-129: Renders a 2D ScreenGui progress bar and particle effects ONLY for `ClickDetector` gathering nodes.
   - `src/client/LocalTools.client.lua` / `src/server/Tools.server.lua`: Tool swinging at `Mineable` nodes (Rocks/Trees) has NO 3D BillboardGui health bar, NO particle effects on hit (sparks, rock fragments, wood chips), and NO visual progress indicator.

5. **Item ID & Naming Mismatches**:
   - `src/shared/ConfigurationFiles/ItemConfig.lua` lines 8-52 uses snake_case IDs (`zunda_flower`, `zunda_pea`, `zunda_mushroom`, `zunda_berry`, `zunda_root`).
   - `GatherConfig.lua`, `MineableConfig.lua`, `LootModule.lua`, and `PlayerDataService.lua` use Title Case names (`"Zunda Flower"`, `"Zunda Pea"`, `"Rock"`, `"Gold Ore"`).

### C. AGENTS.md Workspace Rules Audit
1. **Rule 1 (`$ignoreUnknownInstances`)**:
   - `default.project.json` line 76: `"Workspace": { "$className": "Workspace", "$path": "src/Workspace", "$ignoreUnknownInstances": true }`.
   - **Status**: PASSED.
2. **Rule 2 (Client UI Decoupling & Visibility)**:
   - `HarvestController.client.lua` line 51: `screenGui.ResetOnSpawn = false`, line 61: `progressContainer.Visible = false`.
   - **Status**: PASSED (though creating GUI via `ClientGuiBootstrap.createScreenGui` is recommended).
3. **Rule 3 (Wally Packages)**:
   - `wally.toml` lines 23-24: `[server-dependencies] ProfileService = "alreadypro/profileservice@1.0.4"`.
   - `default.project.json` lines 10-12 & 63-65 map `Packages` to `ReplicatedStorage` and `ServerPackages` to `ServerScriptService`.
   - `.gitignore` lines 1-2 include `Packages/` and `ServerPackages/`.
   - **Status**: PASSED.
4. **Rule 4 (ServerScriptService Import Path Consistency)**:
   - `src/server/ZundaGatherServer.server.lua` line 48: `require(script.Parent.Services.PlayerDataService)`
   - `src/server/ToolManager.server.lua` line 11: `require(script.Parent.Services.PlayerDataService)`
   - **Status**: FAILED (relative `script.Parent` path imports break when scripts are organized under subfolders like `ServerScriptService.Garden`). Rule requires using `ServerScriptService.Services.PlayerDataService`.

---

## 2. Logic Chain

1. **Premise 1**: In Roblox Luau runtime, `require()` can only execute on a `ModuleScript`.
   - **Step**: `HarvestValidator.server.lua` has extension `.server.lua`, which Rojo builds as a `Script`.
   - **Deduction**: When `ZundaGatherServer` or `Mineable` invokes `require(HarvestValidator)`, Luau raises a fatal error, disabling server-side harvest validation.

2. **Premise 2**: Tool hit detection in `Tools.server.lua` checks `CollectionService:HasTag(node, toolType)`.
   - **Step**: `toolType` for Axe is `"Axe"`, Pickaxe is `"PickAxe"`, Sickle is `"Sickle"`.
   - **Step**: Mineable nodes in `MineableConfig.lua` (`Rock`, `MarbleRock`, `GoldRock`, `AppleTree`, `PineTree`) only have category tags (e.g., `"Rock"`).
   - **Deduction**: Because no script maps node category tags (`"Rock"`) to required tool tags (`"PickAxe"`), `findHitTargets` returns an empty array. Tool swinging fails to deal damage to resource nodes.

3. **Premise 3**: Item drops assign loot using `LootModule.assignLoot`.
   - **Step**: `assignLoot` executes `local value = myloot:GetAttribute("Value")`.
   - **Step**: Models in `ReplicatedStorage.Loot` are missing the `"Value"` attribute by default.
   - **Deduction**: `value` is `nil`, causing `data[lootname] + value` to throw an arithmetic error on line 92, preventing loot collection into inventory.

4. **Premise 4**: Milestone 1 R1 requirements state players equip tools, deal damage to nodes, see progress bars and particle effects, receive item drops, and save inventory.
   - **Step**: Current client architecture isolates UI progress bars to `ClickDetector` plant gathering inside `HarvestController.client.lua`. Tool-based mining/woodcutting has no health/progress UI or hit particles.
   - **Deduction**: Tool mining lacks visual feedback for node damage, health state, and particle rendering.

5. **Premise 5**: Architectural plan requires clean Rojo module organization and strict AGENTS.md path consistency.
   - **Step**: Configuration is split between `GatherConfig`, `MineableConfig`, `HarvestConfig`, `HarvestNodeVariants`, and `ItemConfig`.
   - **Step**: Relative imports `script.Parent.Services` violate Rule 4.
   - **Deduction**: A unified `ResourceNodes.lua` config module and `HarvestService.lua` server service should be constructed, and all imports updated to explicit `ServerScriptService.Services...` paths.

---

## 3. Caveats

- **Workspace Level Instances**: Raw `.rbxl` binary level geometry in Roblox Studio was not directly inspected as binary files (`*.rbxl`) are gitignored; findings are based on Rojo project JSON and Luau codebase structure.
- **Rojo Sync Target Locations**: If `HarvestValidator.server.lua` was intended to be a ModuleScript, renaming its file extension to `HarvestValidator.lua` resolves the require issue cleanly.
- **No caveats beyond listed assumptions.**

---

## 4. Conclusion

Milestone 1 (R1: Harvesting & Resource Node System) requires architectural consolidation and bug fixes before implementation:

1. **Consolidate Resource Definitions**: Create `src/shared/Shared/Config/ResourceNodes.lua` (or `src/shared/ConfigurationFiles/ResourceNodes.lua`) combining `GatherConfig`, `MineableConfig`, `HarvestConfig`, and `HarvestNodeVariants`. Include explicit tool requirements per node (`Axe` for Trees, `PickAxe` for Rocks, `Sickle` for Crops).
2. **Consolidate Server Harvesting**: Create `src/server/Services/HarvestService.lua` unifying `ZundaGatherServer`, `Mineable`, `Tools`, and `HarvestValidator`.
3. **Fix `HarvestValidator` Module Type**: Rename `HarvestValidator.server.lua` to `HarvestValidator.lua` (ModuleScript) so it can be required by server services without throwing Luau errors.
4. **Fix Tool Hit Detection**: Update `Tools.server.lua` hit detection to resolve tool requirements from node type attributes/configs (e.g. `Rock` requires `PickAxe`) rather than requiring raw `PickAxe` tags on node parts.
5. **Fix `LootModule.lua` Nil Attribute Handling**: Change `local value = myloot:GetAttribute("Value")` to `local value = (myloot and myloot:GetAttribute("Value")) or 1`.
6. **Implement Health/Progress UI & Particle Effects for Tool Mining**: Extend visual controller (`HarvestController` or `FXController`) to render BillboardGui health bars over damaged nodes and spawn hit particles (sparks, stone dust, wood chips) during tool swings.
7. **Fix ServerScriptService Imports (Rule 4)**: Replace `script.Parent.Services.PlayerDataService` with `game.ServerScriptService.Services.PlayerDataService`.

---

## 5. Verification Method

### Recommended Verification Steps
1. **Luau Static Audit**:
   - Inspect `HarvestValidator.lua` is a ModuleScript.
   - Verify `ServerScriptService` imports do not use relative `script.Parent.Services` paths.
2. **Tool Swinging Verification**:
   - Equip Pickaxe, swing at Rock node. Confirm `Tools.server.lua` successfully finds hit target, reduces node `Health` from 100 to 0 over multiple swings, and triggers loot drop.
   - Equip Axe, swing at Tree node. Confirm wood logs drop on node destruction.
3. **UI & Particle Verification**:
   - Confirm BillboardGui or ScreenGui progress bar displays remaining health/progress for both click-gather nodes and mineable tool nodes.
   - Confirm hit particles trigger at hit location on each swing.
4. **Loot Collection Verification**:
   - Touch dropped loot item. Verify `LootModule.assignLoot` executes without nil errors and updates `PlayerDataService` inventory.
