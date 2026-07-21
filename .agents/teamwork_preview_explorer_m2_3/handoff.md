# Handoff Report — Explorer 3 (Milestone 2: Cooking & Rhythm Minigame System Audit)

## Executive Summary
Audit of `RewardCore`, `CookingValidationSystem`, `PlayerDataService`, `CraftManager`, `LootModule`, and `ChefLevelConfig` revealed **9 critical bugs, architectural rule violations, and formula mismatches**:
1. `RewardCore.lua` is mislocated in `src/shared/ConfigurationFiles/` (ReplicatedStorage) while requiring `ServerScriptService` modules, violating AGENTS.md Rule 4 and client-server boundaries.
2. Triple quality formula conflict between `CookingValidationSystem.lua`, `CraftConfig.lua`, and legacy `CookingSession.server.lua`.
3. Conflicting, duplicate server cooking systems (`CookingSession.server.lua` vs Matter ECS `CookingValidationSystem.lua`).
4. Dish inventory delivery flaw (cooked dishes spawn as physical world loot drops instead of being delivered directly to player data inventory; physical drop loss causes permanent ingredient waste).
5. Data schema mismatch (`d.inventory` table initialized by `RewardCore` vs top-level item keys used by `PlayerDataService` & `ServingSystem`).
6. Timestamp inconsistency mixing `os.clock()` (server uptime) for combo timers with `os.time()` (Unix epoch) for powerups.
7. Duplicate 60-second auto-save background loops in `PlayerDataService.lua`.
8. Inconsistent `total_gold_earned` tracking (updated in serving, but ignored in cooking quality bonus and item selling).
9. Uncapped compound multiplier stacking for gold rewards.

---

## 1. Observations

### 1.1 File Location & Import Violations (AGENTS.md Rule 4)
- **Observed File**: `src/shared/ConfigurationFiles/RewardCore.lua`
- **Prompt Specification**: `src/server/Services/RewardCore.lua`
- **Code Quote** (`src/shared/ConfigurationFiles/RewardCore.lua`, line 14):
  ```lua
  local PlayerDataService = require(game.ServerScriptService.Services.PlayerDataService)
  ```
- **Code Quote** (`default.project.json`, lines 7-9):
  ```json
  "ConfigurationFiles": {
    "$path": "src/shared/ConfigurationFiles"
  }
  ```
- **Impact**: `src/shared/ConfigurationFiles` maps to `ReplicatedStorage.ConfigurationFiles`. Placing a server service in `ReplicatedStorage` that requires `ServerScriptService` causes client crash if required on client, and exposes server data mutation methods on the client API surface.

### 1.2 Quality Calculation Formula Mismatch
Three separate files calculate rhythm minigame quality using incompatible algorithms:
1. `src/server/systems/cooking/CookingValidationSystem.lua` (lines 85-90):
   ```lua
   local weighted = (score.perfectHits * 3 + score.greatHits * 2 + score.okHits * 1) / (total * 3)
   if weighted >= 0.9 then quality = "perfect"
   elseif weighted >= 0.7 then quality = "great"
   ```
2. `src/shared/ConfigurationFiles/CraftConfig.lua` (lines 84-98):
   ```lua
   if perfects == totalNotes or perfects >= math.ceil(totalNotes * 0.6) then return "perfect"
   elseif hits >= math.ceil(totalNotes * 0.5) then return "great"
   else return "ok" end
   ```
3. `src/server/CookingSession.server.lua` (lines 81-87):
   ```lua
   if hitCount >= maxHits then return "perfect"
   elseif hitCount >= math.ceil(maxHits * 0.8) then return "great"
   else return "ok" end
   ```
- **Impact**: Client UI predicting quality via `CraftConfig.calculateQuality` disagrees with `CookingValidationSystem` server grading.

### 1.3 Duplicate / Competing Cooking Server Systems
- **Observed Files**: `src/server/CookingSession.server.lua` AND `src/server/systems/cooking/CookingValidationSystem.lua`.
- Both scripts connect to RemoteEvent `CookingHit`:
  - `CookingSession.server.lua` (lines 62-67):
    ```lua
    cookingHit.OnServerEvent:Connect(function(player)
        local session = sessions[player.UserId]
        if not session then return end
        session.hitCount = session.hitCount + 1
    end)
    ```
  - `CookingValidationSystem.lua` (lines 52-53):
    ```lua
    for _, ev in world:query(Matter.useEvent(hitEvent, "OnServerEvent")) do
        local player, clientTick, quality = ev[1], ev[2], ev[3]
    ```
- **Impact**: `CookingSession.server.lua` intercepts `CookingHit` events sent by `TimedCookingScript.client.lua` (`cookingHitEvent:FireServer(tick(), quality)`), counting all events (including `"miss"`) as hits in its legacy session state.

### 1.4 Dish Inventory Delivery & Storage Key Mismatch
- **Observed File**: `src/server/systems/cooking/CookingValidationSystem.lua` (lines 96-101):
  ```lua
  loot_module.generateLoot(player, {item}, position, quality)
  ```
- **Observed File**: `src/shared/ConfigurationFiles/LootModule.lua` (lines 88-93):
  ```lua
  local data = PlayerDataService.getOrCreate(player)
  if not data[lootname] then
      data[lootname] = value
  else
      data[lootname] = data[lootname] + value
  end
  ```
- **Observed File**: `src/shared/ConfigurationFiles/RewardCore.lua` (lines 17-18):
  ```lua
  local d = PlayerDataService.getOrCreate(player)
  d.inventory = d.inventory or {}
  ```
- **Impact**:
  1. Cooked dishes spawn in the 3D world as physical drops (`MakeLootEvent`). If uncollected, ingredients are consumed but dish is lost.
  2. Collected dishes are saved to `data["Zunda Mochi"]` (top-level keys), leaving `d.inventory` in `RewardCore` empty and unused.

### 1.5 Timestamp Uptime vs Wall-Clock Inconsistency
- **Observed File**: `src/shared/ConfigurationFiles/RewardCore.lua`:
  - Combo timer (line 129 & 171): `d.combo.lastActionAt = os.clock()` (server process CPU uptime in seconds).
  - Powerup timer (line 72): `d.powerups.LuckyCharm > os.time()` (Unix epoch wall-clock timestamp).
- **Impact**: `os.clock()` resets to 0 whenever a server restarts or player teleports to a new server instance. Storing `os.clock()` in player session state saved to DataStore causes combo timers to be invalid across server sessions.

### 1.6 Duplicate Auto-Save Loops in `PlayerDataService.lua`
- **Observed File**: `src/server/Services/PlayerDataService.lua`:
  - Loop 1 (lines 213-226): `task.spawn` running `while true do task.wait(60) ... progressionStore:SetAsync(...) end`.
  - Loop 2 (lines 243-258): Identical `task.spawn` running `while true do task.wait(60) ... progressionStore:SetAsync(...) end`.
- **Impact**: Triggers double DataStore write requests every 60 seconds per player, increasing risk of hitting DataStore rate limits (60 + 10 * players / min).

### 1.7 Inconsistent `total_gold_earned` Progression Tracking
- **Observed Files**: `ServingSystem.server.lua` vs `CookingValidationSystem.lua` / `LootModule.lua`.
  - `ServingSystem.server.lua` (line 145): `playerData.total_gold_earned = (playerData.total_gold_earned or 0) + payAmount`.
  - `CookingValidationSystem.lua` (line 105): `RewardCore.addGold(player, bonus.gold, ...)` — updates `d.gold` but does NOT update `d.total_gold_earned`.
  - `LootModule.lua` (line 61): `total = RewardCore.addGold(player, total, "sell")` — updates `d.gold` but does NOT update `d.total_gold_earned`.
- **Impact**: Player lifetime gold statistics and tier/achievement requirements relying on `total_gold_earned` fail to track gold earned from cooking quality bonuses or selling items.

### 1.8 Uncapped Multiplier Compound Stacking
- **Observed File**: `src/shared/ConfigurationFiles/RewardCore.lua` (lines 67-83):
  `finalAmount = math.floor(amount * comboMult * luckyCharmMult * companionGoldBuff * decorGoldBuff)`
- **Impact**: 15x combo (5.0x) * LuckyCharm (1.5x) * Companion (1.2x) * Decor (1.2x) = 10.8x total multiplier. With base gold of 25 for perfect cook, payout reaches 270 gold per single cook, leading to rapid economy inflation.

---

## 2. Logic Chain

1. **Premise**: `RewardCore` is designed as a server-authoritative service for managing player progression, XP, gold, level-ups, and combo states.
2. **Observation**: `RewardCore.lua` requires `game.ServerScriptService.Services.PlayerDataService` at file level (line 14) and is located in `src/shared/ConfigurationFiles/RewardCore.lua`.
3. **Deduction**: Because `src/shared/ConfigurationFiles` maps to `ReplicatedStorage`, `RewardCore.lua` is placed in shared client-reachable memory. But `ServerScriptService` is restricted on clients. If client code requires `RewardCore`, it throws a runtime crash. Moving `RewardCore.lua` to `src/server/Services/RewardCore.lua` aligns with the prompt, AGENTS.md Rule 4, and proper server architecture.
4. **Observation**: `CookingSession.server.lua` and `CookingValidationSystem.lua` both listen to `CookingHit`.
5. **Deduction**: Two independent server implementations exist for cooking validation. `CookingSession.server.lua` is a legacy non-ECS script that improperly counts `"miss"` as hits and overrides hit processing. `CookingSession.server.lua` should be deprecated/removed in favor of `CookingValidationSystem.lua`.
6. **Observation**: `CookingValidationSystem.lua` uses weighted formula `(3*P + 2*G + 1*O)/(3*N) >= 0.9` for perfect, while `CraftConfig.lua` uses `perfects >= 0.6 * N`.
7. **Deduction**: Client HUD predictions using `CraftConfig` will display "Perfect" rating when server yields "Great", leading to player confusion. Standardizing on `CraftConfig.calculateQuality` across both client and server resolves the mismatch.
8. **Observation**: Items collected via `LootModule.assignLoot` write to `data[item]` top-level keys. `RewardCore` initializes `d.inventory = {}`.
9. **Deduction**: `d.inventory` is orphaned. Normalizing data schema so items are consistently accessed via `data[item]` (or nested `data.inventory[item]`) prevents missing item bugs during guest serving (`ServingSystem` checks `playerData[foodItemName]`).
10. **Observation**: `PlayerDataService.lua` contains two identical `task.spawn` auto-save blocks (lines 213-226 & 243-258).
11. **Deduction**: Removing the redundant loop reduces DataStore quota usage by 50%.

---

## 3. Caveats
- **Uninvestigated Areas**: Client visual animation details in `CookingHUD.lua` (UI components) were not evaluated as part of server reward auditing.
- **Assumptions Made**: Assumed `CookingValidationSystem.lua` (Matter ECS) is the intended target system for Milestone 2, and `CookingSession.server.lua` is legacy code.

---

## 4. Conclusion & Actionable Recommendations

### Actionable Remediation Plan:
1. **Move `RewardCore.lua`**: Move `src/shared/ConfigurationFiles/RewardCore.lua` to `src/server/Services/RewardCore.lua` and update imports across server scripts (`require(ServerScriptService.Services.RewardCore)`).
2. **Deprecate Legacy `CookingSession.server.lua`**: Remove or disable `src/server/CookingSession.server.lua` to eliminate remote event listener collisions.
3. **Unify Quality Calculation**: Update `CookingValidationSystem.lua` to import and call `craftConfig.calculateQuality(scores, totalNotes)` for consistency with `CraftConfig.lua`.
4. **Direct Inventory Delivery for Cooking**: Update `CookingValidationSystem.lua` to add cooked dishes directly into player inventory via `PlayerDataService` upon cooking completion, using `loot_module.generateLoot` only for physical world item drops when explicitly needed.
5. **Clean Up `PlayerDataService.lua`**:
   - Remove duplicate `task.spawn` auto-save loop (lines 243-258).
   - Ensure `total_gold_earned` is updated whenever `RewardCore.addGold` is called.
6. **Standardize Timestamps**: Use `os.time()` or `workspace:GetServerTimeNow()` consistently for combo and powerup durations instead of mixing `os.clock()`.

---

## 5. Verification Method

1. **Linter / Luau Check**:
   - Run Luau static analysis on modified files to verify no unresolved imports or type errors.
2. **File Structure Inspection**:
   - Verify `src/server/Services/RewardCore.lua` exists and `default.project.json` maps `ServerScriptService` to `src/server`.
   - Verify `src/shared/ConfigurationFiles/RewardCore.lua` is removed.
3. **DataStore Auto-Save Audit**:
   - Inspect `PlayerDataService.lua` to verify single `task.spawn` loop exists for auto-saving.
4. **Quality Grade Verification Test**:
   - Simulate 10-note rhythm game with 7 Perfect hits, 2 Great hits, 1 Miss:
     - `CraftConfig.calculateQuality` returns `"perfect"` (7 >= 6).
     - Unified `CookingValidationSystem` returns `"perfect"`.
