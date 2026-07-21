# Handoff Report — Challenger 1: Milestone 1 R1 Empirical Verification

## Observation

Empirical testing was conducted using custom test harness `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m1_1\test_harness_m1.py` and Rojo build verification `rojo build default.project.json -o build/Zundamons-kItchen.rbxl`. 

Out of 16 empirical test cases evaluated across the 6 specified R1 subsystems, **10 PASSED** and **6 FAILED**:

### 1. Tool Hit Detection & Position Safety
- **PASS**: `Tools.server.lua` lines 45-68 (`TOOL_NODE_MATCHES`) correctly maps PickAxe -> Rock/MarbleRock/GoldRock, Axe -> AppleTree/PineTree, Sickle -> Wheat/ZundaMushroom/ZundaBerry/ZundaRoot.
- **PASS**: `Tools.server.lua` line 16 configures `HIT_RADIUS = 8` studs.
- **FAIL**: `Tools.server.lua` line 76: `local dist = (node.Position - origin).Magnitude`.
  - *Direct Observation*: `findHitTargets` directly accesses `node.Position` on instances tagged with `Mineable`. If a `Mineable` instance is a `Model` (or parented under a Model tagged as `Mineable`), `node.Position` throws a Luau runtime crash (`Position is not a valid member of Model`). In contrast, `HarvestController.client.lua` line 465 checks `if node:IsA("BasePart") then node.Position else (node.PrimaryPart and node.PrimaryPart.Position or Vector3.zero)`.

### 2. Node Health Reduction & Multiplayer Cooldown
- **PASS**: `Tools.server.lua` line 127 (`node:SetAttribute("Health", math.max(health - damage, 0))`) correctly reduces health down to a lower bound of 0.
- **FAIL**: `Mineable.server.lua` lines 46-101.
  - *Direct Observation*: `Tools.server.lua` line 124 calls `CollectionService:AddTag(node, player.Name .. "|" .. tier)` on swing. `Mineable.server.lua` NEVER removes these wildcard tags upon health reaching 0 or upon node respawn (`obj.Parent = parent`). Stale tags linger across respawns indefinitely.
- **FAIL**: `Mineable.server.lua` line 51 & `HarvestValidator.lua` line 118.
  - *Direct Observation*: In `Mineable.server.lua`, when node health reaches 0, it iterates `for _, player in pairs(Players:GetPlayers()) do` and calls `validateHarvest(player, item)`. The first tagged player evaluated passes `validateHarvest`, which executes `node:SetAttribute("LastHarvested", tick())`. When the loop moves to the next tagged player (e.g. the player who actually dealt the final hit), `validateCooldown` evaluates `tick() - LastHarvested`, sees `< HARVEST_COOLDOWN` (1.0s), and rejects the second player with `"Node is on cooldown"`. The legitimate player is denied loot.

### 3. Particle Spawning & Feedback
- **PASS**: `HarvestController.client.lua` lines 97-129 (`createHarvestParticles`) creates particle emitters on harvest completion.
- **PASS**: `HarvestController.client.lua` lines 413-462 (`createToolHitFX`) differentiates particle colors/textures between rocks (sparks/dust), trees (wood chips), and crops (leaf bits).
- **PASS**: Particle parts are automatically cleaned up after lifetime via `task.delay(1.0, function() part:Destroy() end)`.

### 4. Loot Drops & Security
- **FAIL**: `LootModule.lua` line 116 (`local myloot = loot:FindFirstChild(lootname)`).
  - *Direct Observation*: `ZundaGatherServer.server.lua` grants items `"Salted Pea Bouquet"` (line 230) and `"Carrot"` (line 246). `MineableConfig.lua` drops `"Marble Rock"`. None of these items exist in `ReplicatedStorage.Loot` (`src/shared/Loot`). Calling `loot:FindFirstChild(lootname)` evaluates to `nil`, causing `GiveLoot` to return `false`. Items cannot be picked up or added to player inventory.
- **FAIL**: `LootModule.lua` lines 111-123 & `searchforCode` line 70.
  - *Direct Observation*: `GiveLoot` calls `searchforCode(player, genCode, lootname, false)`. `searchforCode` with `isRemoving = false` does NOT remove the generated code from `codes[player.Name]`. `GiveLoot` does not consume the code; consumption relies on client firing `removeCode:FireServer(...)`. A client can invoke `GiveLoot` multiple times concurrently before `removeCode` arrives, multiplying item rewards arbitrarily.

### 5. Inventory Save
- **PASS**: `PlayerDataService.lua` lines 41-91 (`createDefaultData`) establishes canonical player state including `gold = 50`, `gathered_items = {}`, and initial inventory quantities.
- **PASS**: `PlayerDataService.lua` lines 135-152 (`savePlayer`) and lines 213-226 (periodic 60s auto-save) persist data via `DataStoreService:GetDataStore("KitchenProgression")`.

### 6. UI Progress Bar Responsiveness
- **PASS**: `HarvestController.client.lua` lines 48-94 (`createProgressBar`) initializes `HarvestProgressGui` and container.
- **PASS**: Cancellation triggers operate on movement threshold (line 213), range threshold (line 223), movement keys W/A/S/D/Space/Shift (line 558), and character respawn (line 547).
- **FAIL**: `HarvestController.client.lua` lines 270-331 (`startHarvest`).
  - *Direct Observation*: If `startHarvest` is invoked while harvesting, it calls `cancelHarvest("New harvest started")` which sets `isHarvesting = false`. Then `startHarvest` immediately sets `isHarvesting = true` and binds a new `Heartbeat` connection. On the next frame, the OLD `Heartbeat` callback runs, evaluates `if not isHarvesting then`, finds `isHarvesting == true`, remains connected, and runs concurrently with the new heartbeat—causing premature harvest completion.

---

## Logic Chain

1. **Observation**: `Tools.server.lua:76` reads `node.Position` without type checking.
   -> **Inference**: If a developer tags a `Model` instance as `Mineable`, calling `node.Position` throws a runtime exception in Luau (`Position is not a valid member of Model`).
   -> **Conclusion**: Hit detection is vulnerable to crashes when `Mineable` instances are Models.

2. **Observation**: `Tools.server.lua:124` adds wildcard tags `player.Name .. "|" .. tier`, but `Mineable.server.lua` never calls `CollectionService:RemoveTag`.
   -> **Inference**: Wildcard tags accumulate permanently on node instances across respawns.
   -> **Conclusion**: Stale player tags persist indefinitely, allowing players who previously hit a node to continue receiving loot drops on future respawns.

3. **Observation**: `Mineable.server.lua:51` iterates `Players:GetPlayers()` calling `validateHarvest`, and `HarvestValidator.lua:118` sets `node:SetAttribute("LastHarvested", tick())`.
   -> **Inference**: The first tagged player in `Players:GetPlayers()` triggers `LastHarvested = tick()`. When the loop reaches subsequent tagged players, `validateCooldown` sees `tick() - LastHarvested < 1.0` and returns `false, "Node is on cooldown"`.
   -> **Conclusion**: Multiple players damaging the same node results in the second player being denied loot due to server-side cooldown timestamp collision.

4. **Observation**: `LootModule.lua:116` checks `loot:FindFirstChild(lootname)`, but `"Carrot"`, `"Salted Pea Bouquet"`, and `"Marble Rock"` do not exist in `src/shared/Loot`.
   -> **Inference**: `loot:FindFirstChild(lootname)` returns `nil` for these items. `GiveLoot` returns `false`.
   -> **Conclusion**: Items harvested from Carrot plots, Salted Pea Bouquets, and Marble Rocks can never be picked up or saved to inventory.

5. **Observation**: `LootModule.lua:117` uses `searchforCode(..., false)` which does not mutate `codes[player.Name]`.
   -> **Inference**: Until `RemoveCode` is received from the client, `searchforCode` continues returning `true`.
   -> **Conclusion**: Concurrent or repeated `GiveLoot` RemoteFunction invocations exploit this to duplicate loot.

6. **Observation**: `HarvestController.client.lua:270` calls `cancelHarvest()` then immediately sets `isHarvesting = true` before creating a new `Heartbeat` connection.
   -> **Inference**: The old `Heartbeat` callback sees `isHarvesting == true` on its next frame and does not disconnect.
   -> **Conclusion**: Multiple heartbeat loops run in parallel, completing progress bar fills prematurely.

---

## Caveats

- Tests were executed via static analysis harness `test_harness_m1.py` and Rojo project build compilation (`rojo build`). Live Roblox server physics simulation was not executed.
- Network latency/jitter exceeding 500ms was not simulated.

---

## Conclusion

Milestone 1 R1 (Harvesting & Resource Node System) contains solid base structures (clean progress bar UI creation, sound/particle customization, DataStore persistence, tool tier damage mapping). However, **it is NOT ready for production release** due to **6 critical empirical bugs**:

1. **Model position crash** in `Tools.server.lua`.
2. **Permanent wildcard tag accumulation** in `Mineable.server.lua`.
3. **Multiplayer cooldown loot denial** in `Mineable.server.lua` + `HarvestValidator.lua`.
4. **Missing loot models** (`Carrot`, `Salted Pea Bouquet`, `Marble Rock`) in `ReplicatedStorage.Loot`.
5. **Server-side duplicate item exploit** in `LootModule.lua`.
6. **Heartbeat connection leak** in `HarvestController.client.lua`.

---

## Verification Method

To verify these results independently:

1. **Run Test Harness**:
   ```powershell
   python g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m1_1\test_harness_m1.py
   ```
   *Expected Output*: 16 tests run, 10 PASS, 6 FAIL.

2. **Verify Rojo Build**:
   ```powershell
   rojo build default.project.json -o build/Zundamons-kItchen.rbxl
   ```
   *Expected Output*: Project builds successfully to `build/Zundamons-kItchen.rbxl`.
