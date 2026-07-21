# Handoff Report: PlayerDataService, Inventory, Remotes & Server Security (Milestone 1 - R1)

**Agent**: Explorer 3
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m1_3`
**Date**: 2026-07-21

---

## 1. Observation

### A. Data Persistence & DataStore Architecture
1. **Raw `DataStoreService` Usage vs. `ProfileService` Wiping**:
   - File: `g:\Zundamons-kItchen-V2\wally.toml` (line 24) declares `ProfileService = "alreadypro/profileservice@1.0.4"` under `[server-dependencies]`.
   - File: `g:\Zundamons-kItchen-V2\src\server\Services\PlayerDataService.lua` (lines 9, 114-116, 135-146) uses raw `DataStoreService:GetDataStore("KitchenProgression")` with standard `GetAsync` / `SetAsync` instead of `ProfileService`.
   - Lines 145 (`store[tostring(player.UserId)] = nil`) deletes the player's in-memory session data at player departure regardless of whether `SetAsync` succeeded or failed, risking data loss on network or DataStore outage.

2. **Duplicate Auto-Save Loops**:
   - File: `g:\Zundamons-kItchen-V2\src\server\Services\PlayerDataService.lua` contains TWO identical 60-second auto-save loops:
     - Loop 1 (lines 208-220): `task.spawn(function() while true do task.wait(60) ... end end)`
     - Loop 2 (lines 237-252): `task.spawn(function() while true do task.wait(60) ... end end)`
   - Result: Redundant DataStore requests firing twice every minute per player.

### B. Data Schema & Inventory Data Structure Mismatches
1. **Schema Disconnect (`DataSchema.lua` vs `PlayerDataService.lua`)**:
   - File: `g:\Zundamons-kItchen-V2\src\shared\DataSchema.lua` (lines 6-14) defines inventory nested under `Inventory`:
     ```lua
     Inventory = {
         ["Basic Pan"] = 1,
         ["Apple"] = 5,
     },
     UnlockedRecipes = { ["Zunda Apple Pie"] = true }
     ```
   - File: `g:\Zundamons-kItchen-V2\src\server\Services\PlayerDataService.lua` (lines 69-74) initializes items flat at the top level of the player data table:
     ```lua
     Apple = 5, Wheat = 5, Wood = 5, Rock = 5, ["Iron Ore"] = 3
     ```
   - File: `g:\Zundamons-kItchen-V2\src\shared\ConfigurationFiles\LootModule.lua` (lines 89-93) assigns loot at the top level: `data[lootname] = (data[lootname] or 0) + value`.
   - Result: Code that checks `data.Inventory[itemName]` gets `nil`, while code checking `data[itemName]` gets numbers.

2. **Item Identifier Mismatch (`Wood` vs `Wood Log`, snake_case vs Title Case)**:
   - File: `g:\Zundamons-kItchen-V2\src\shared\ConfigurationFiles\MineableConfig.lua` (line 39) specifies tree drops as `"Wood Log"`.
   - File: `g:\Zundamons-kItchen-V2\src\server\Services\PlayerDataService.lua` (line 71) initializes `"Wood"`.
   - File: `g:\Zundamons-kItchen-V2\src\shared\ConfigurationFiles\ItemConfig.lua` (lines 8-52) uses snake_case IDs (`zunda_flower`, `zunda_pea`), whereas `GatherConfig`, `MineableConfig`, `LootModule`, and `PlayerDataService` use Title Case (`"Zunda Flower"`, `"Zunda Pea"`).

### C. Physical Loot Drop & Inventory Addition Flow
1. **Dependency on Client-Side `.Touched` Physics**:
   - File: `g:\Zundamons-kItchen-V2\src\server\ZundaGatherServer.server.lua` (lines 61-66): `grantItems` calls `lootMod.generateLoot(player, items, position)` and records `d.gathered_items[item] = true` for discovery, but does NOT increment item quantities.
   - File: `g:\Zundamons-kItchen-V2\src\shared\ConfigurationFiles\LootModule.lua` (lines 111-123): `GiveLoot` RemoteFunction is only invoked when client script `CreateLoot.client.lua` detects physical part `.Touched`.
   - Result: If the drop part falls out of workspace bounds or fails to register touch on client, the player receives zero items in inventory.

### D. Tool Action Remotes, Hotbar Sync & Security Validation
1. **Tool Equipping Corrupts Hotbar State**:
   - File: `g:\Zundamons-kItchen-V2\src\server\ToolManager.server.lua` (lines 44-48): `handleEquipTool` destroys character tools directly via `child:Destroy()`.
   - File: `g:\Zundamons-kItchen-V2\src\server\InventoryServer.server.lua` (lines 97-169): Listens to `char.ChildAdded` / `ChildRemoved` and manages `plr.Hotbar` slots. Destroying tools directly without going through `InventoryServer` creates null references in hotbar slots.
   - File: `g:\Zundamons-kItchen-V2\src\server\ToolManager.server.lua` (lines 55-60): Looks for tool models exclusively in `game.StarterPack`. If tool models live in `ReplicatedStorage`, equipping fails.

2. **Tool Data Hidden from Client**:
   - File: `g:\Zundamons-kItchen-V2\src\server\RequestDataHandler.server.lua` (line 20): `HIDDEN` table lists `tools = true`, hiding tool ownership and tier information from UIs calling `RequestData`.

3. **Remote Events / Functions Inventory Audit**:
   - RemoteFunction `ToolRemotes.ConnectFunction`: Triggered on tool swing, validated in `Tools.server.lua` (checking proximity <= 8 studs).
   - RemoteFunction `RemoteFunctions.EquipTool`: Invoked to equip tools, handled in `ToolManager.server.lua`.
   - RemoteFunction `RemoteFunctions.GiveLoot`: Invoked on item touch, validated in `LootModule.lua` (using single-use security codes).
   - RemoteEvent `RemoteEvents.HarvestNode`: Invoked on click gather, validated in `ZundaGatherServer.server.lua` via `HarvestValidator`.
   - **Missing Remote**: No RemoteEvent exists to notify the client in real-time when inventory quantities change (`InventoryUpdated` / `DataUpdated`), requiring UIs to poll `RequestData`.

### E. AGENTS.md Workspace Rules Audit
1. **Rule 1 (`$ignoreUnknownInstances`)**:
   - File: `g:\Zundamons-kItchen-V2\default.project.json` (line 76) contains `"$ignoreUnknownInstances": true` under `"Workspace"`.
   - Result: **PASS**.

2. **Rule 2 (Client UI Decoupling)**:
   - File: `g:\Zundamons-kItchen-V2\src\client\ToolClient.client.lua` (lines 2, 6): Uses `script.Parent` on a script mapped to `StarterPlayerScripts`, throwing runtime error: `Activated is not a valid member of StarterPlayerScripts`.
   - Result: **FAIL (VIOLATION)**.

3. **Rule 3 (Wally Package Structure & Dependencies)**:
   - File: `g:\Zundamons-kItchen-V2\wally.toml` includes `ProfileService` under `[server-dependencies]`.
   - File: `g:\Zundamons-kItchen-V2\default.project.json` maps `Packages` to `ReplicatedStorage` and `ServerPackages` to `ServerScriptService`.
   - File: `g:\Zundamons-kItchen-V2\.gitignore` contains `Packages/`, `ServerPackages/`, `wally.exe`, `wally.zip`.
   - Result: **PASS** (configuration), but server code currently bypasses `ProfileService`.

4. **Rule 4 (ServerScriptService Path Consistency)**:
   - Relative `script.Parent.Services.PlayerDataService` imports found in:
     - `src/server/ToolManager.server.lua` (line 11)
     - `src/server/ZundaGatherServer.server.lua` (line 48)
     - `src/server/AdvancedRewards.server.lua` (line 15)
     - `src/server/CompanionBuffServer.server.lua` (line 4)
   - Result: **FAIL (VIOLATION)**. Imports must use `game.ServerScriptService.Services.PlayerDataService` or `ServerScriptService.Services.PlayerDataService`.

---

## 2. Logic Chain

1. **Premise 1: Wally & DataStore Best Practices**:
   - `wally.toml` declares `ProfileService`, which provides session locking, auto-saving, and crash protection.
   - `PlayerDataService.lua` uses raw `DataStoreService:SetAsync` and deletes data on `PlayerRemoving` without waiting for success.
   - **Deduction**: If a server crashes or network drops during save, player data is wiped from memory and unsaved progress is lost. Refactoring `PlayerDataService` to utilize `ProfileService` (or robust `UpdateAsync` with session protection) and removing duplicate auto-save loops is critical.

2. **Premise 2: Schema Consistency**:
   - `DataSchema.lua` dictates a nested `data.Inventory` table, whereas `PlayerDataService.lua` and `LootModule.lua` place item counts at the root level (`data["Apple"] = 5`).
   - **Deduction**: Any feature expecting `data.Inventory` fails or receives `nil`. Standardizing inventory structure across `DataSchema.lua`, `PlayerDataService.lua`, and `LootModule.lua` is required.

3. **Premise 3: Physical Drop Reliability**:
   - Loot addition requires physical 3D part instantiation and client `.Touched` firing.
   - **Deduction**: Physics glitches, latency, or out-of-bounds drop spawns cause permanent item loss. Server should implement either direct inventory crediting with client visual particle spawns or a server proximity auto-pickup fallback.

4. **Premise 4: Tool & Hotbar Architecture**:
   - `ToolManager.server.lua` destroys tool parts directly, bypassing `InventoryServer.server.lua`.
   - **Deduction**: Destroying tools without updating `InventoryServer` corrupts `Hotbar` and `Equipped` slots, causing desync between server inventory and client hotbar UI.

5. **Premise 5: Rule 2 and Rule 4 Compliance**:
   - `ToolClient.client.lua` uses `script.Parent` in `StarterPlayerScripts`.
   - Server scripts use relative `script.Parent.Services` imports.
   - **Deduction**: `ToolClient.client.lua` must be cleaned up/removed, and all server imports updated to explicit `ServerScriptService.Services...` paths.

---

## 3. Caveats

- **ProfileService Dependency**: `ProfileService` package must be installed into `ServerPackages/` via Wally before switching `PlayerDataService` to use it.
- **Physical Loot Visuals**: Removing physical loot parts entirely would simplify persistence, but keeping client-side visual drops (with immediate server crediting) retains game feel while guaranteeing zero item loss.

---

## 4. Conclusion

`PlayerDataService`, inventory persistence, tool remotes, and server security require **5 core fixes**:

1. **Integrate ProfileService / Upgrade DataStore Engine**:
   - Refactor `PlayerDataService.lua` to use `ProfileService` (or `UpdateAsync` with session protection). Remove duplicate `task.spawn` auto-save loops.
2. **Unify Inventory Schema & Item Names**:
   - Align `DataSchema.lua`, `PlayerDataService.lua`, `LootModule.lua`, and `MineableConfig.lua`. Standardize item keys (e.g. `"Wood"` vs `"Wood Log"`) and ensure `data.Inventory` dictionary is used consistently.
3. **Guarantee Item Drop Addition**:
   - Add immediate server-side inventory crediting in `LootModule.lua` / `ZundaGatherServer` / `Mineable`, or add server auto-pickup timeout so physical drop failures do not cause item loss.
4. **Fix Tool Equipping & Hotbar Synchronization**:
   - Synchronize `ToolManager.server.lua` with `InventoryServer.server.lua`. Ensure tool models are loaded from `ReplicatedStorage.Models` or `ReplicatedStorage.Tools` rather than relying strictly on `StarterPack`. Unhide `tools` in `RequestDataHandler.server.lua` or add a `GetTools` remote.
5. **Fix Workspace Rule Violations (Rule 2 & Rule 4)**:
   - Remove or fix `src/client/ToolClient.client.lua` (`script.Parent` violation).
   - Update all relative `script.Parent.Services` imports in server scripts to explicit `game.ServerScriptService.Services.PlayerDataService`.

---

## 5. Verification Method

1. **Persistence & Data Schema Verification**:
   - Inspect `PlayerDataService.lua` to confirm single auto-save loop and proper data structure.
   - Check `DataSchema.lua` vs `LootModule.assignLoot` to ensure items are added to `data.Inventory` or standardized schema.
2. **Item Drop Addition Verification**:
   - Trigger node harvest (`ZundaGatherServer` or `Mineable`). Check server logs and `PlayerDataService.get(player)` to confirm inventory item count increments reliably.
3. **Rule Audit Verification**:
   - Verify `src/client/ToolClient.client.lua` has no `script.Parent` references under `StarterPlayerScripts`.
   - Grep `script.Parent.Services` across `src/server` to confirm 0 relative path violations remain.
