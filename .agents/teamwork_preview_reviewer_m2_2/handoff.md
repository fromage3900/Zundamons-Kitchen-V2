# Review Handoff Report — Reviewer 2 (Milestone 2: Cooking & Rhythm Minigame System)

## 1. Observation

### Build & Compilation Verification
* **Command**: `rojo build --output test.rbxl`
* **Result**:
  ```
  Building project 'Zundamons-kItchen-V2'
  Built project to test.rbxl
  ```
* Project compiles cleanly with 0 errors.

### Implementation Audit
1. **10-Note Spawning & Difficulty Configuration**:
   * `src/client/Controllers/CookingController.lua` lines 30-36:
     ```lua
     local PEA_CONFIG = {
         fallDuration = 2.0,
         hitWindow = 0.15,     -- Perfect <= 0.15s
         greatWindow = 0.35,   -- Great <= 0.35s
         okWindow = 0.60,      -- OK <= 0.60s
         totalNotes = 10,      -- Server default total note count
     }
     ```
   * `CookingController.lua` lines 273-276:
     ```lua
     local totalNotesToSpawn = PEA_CONFIG.totalNotes
     if craftConfig and craftConfig.difficulty and craftConfig.difficulty[recipeName] then
         totalNotesToSpawn = craftConfig.difficulty[recipeName].notes or PEA_CONFIG.totalNotes
     end
     ```
   * `src/server/Services/CookingValidationSystem.lua` line 64:
     ```lua
     local totalNotes = (craftConfig.difficulty and craftConfig.difficulty[item] and craftConfig.difficulty[item].notes) or 10
     ```

2. **Timing Windows & Rating Text Visuals**:
   * `src/client/Controllers/CookingController.lua` lines 53-63 (`getHitQuality`):
     * Perfect: `|diff| <= 0.15s`
     * Great: `|diff| <= 0.35s`
     * OK: `|diff| <= 0.60s`
     * Miss: `|diff| > 0.60s` or note fall progress >= 1.2.
   * Floating rating popups (`spawnFloatingRating`, lines 65-90): TextLabel animated with `TweenService` (Back Out easing, floating up and fading out, destroyed on completion).

3. **Multi-Input Support**:
   * `src/client/Controllers/CookingController.lua` lines 312-325:
     * Keyboard: `Enum.KeyCode.Space`
     * Gamepad: `Enum.KeyCode.ButtonA`, `Enum.KeyCode.ButtonX`
     * Touch / Mouse: `Enum.UserInputType.Touch` & `tapButton.MouseButton1Click`

4. **Combo Meter Updates**:
   * Live combo tracking (`comboCount`, `maxComboCount`) in `CookingController.lua` lines 221, 249, 256, 350, 366.
   * `comboLabel.Text = string.format("Combo: %d | Max: %d", comboCount, maxComboCount)`.

5. **Ingredient Deduction & Validation**:
   * `src/server/Services/CookingValidationSystem.lua` lines 26-54:
     * `CookingValidationSystemModule.validateIngredients`: verifies player has required items from `craftConfig.recipes[recipeName]`.
     * `CookingValidationSystemModule.deductIngredients`: decrements quantities in `PlayerDataService.getOrCreate(player)` and cleans up zero/negative quantities.
   * `src/server/CraftManager.server.lua` lines 64-70: invokes validation and deduction before starting session.

6. **Quality Bonus Rewards & Direct Dish Inventory Delivery**:
   * `src/server/Services/CookingValidationSystem.lua` lines 18-22, 131-165:
     * Perfect: +25 bonus gold (with combo multiplier), 35% extra dish chance, `craftPerfect` XP.
     * Great: +10 bonus gold, `craftSuccess` XP.
     * OK: +0 bonus gold, `craftSuccess` XP, combo reset via `RewardCore.breakCombo`.
     * Dish delivery: Direct inventory increment into `PlayerDataService` (`d[item] = (d[item] or 0) + dishAmount`).

7. **Legacy Code Deactivation**:
   * `src/server/CookingSession.server.lua` has been completely deleted.
   * Workspace grep for `CookingSession.server` returned 0 occurrences in `src/`.

8. **AGENTS.md Workspace Rules Compliance**:
   * Rule 1: `default.project.json` contains `"$ignoreUnknownInstances": true` under `"Workspace"`.
   * Rule 2: `CookingController.lua` creates GUI in `PlayerGui` via `ClientGuiBootstrap.createScreenGui(player, "CookingControllerGui", 100)` with `ResetOnSpawn = false` and `mainPanel.Visible = false` on startup (line 106).
   * Rule 3: Wally packages mapped to `ReplicatedStorage.Packages` and `ServerScriptService.ServerPackages`, ignored in `.gitignore`.
   * Rule 4: ServerScriptService imports use `ServerScriptService.Services.X` or `ServerScriptService.systems.X` without `.Server.` prepended.

9. **Integrity Violations Audit**:
   * No hardcoded test results, facade implementations, fake logs, or self-certifying shortcuts were found.

---

## 2. Logic Chain

1. **Clean Build**: `rojo build --output test.rbxl` builds the project binary without compilation errors, proving syntactical validity.
2. **Feature Coverage**: 10-note spawning, timing windows, multi-input, rating popups, combo updates, ingredient deduction, quality rewards, direct dish delivery, and legacy script deactivation have all been verified in code.
3. **Workspace Rule Compliance**: All rules from `AGENTS.md` are satisfied.
4. **Major Logic & Timing Desync Bug Found**:
   * In `src/server/Services/CookingValidationSystem.lua` lines 63-72:
     ```lua
     local duration = craftConfig.cookingTimes and craftConfig.cookingTimes[item] or 10
     ...
     world:spawn(
         CookingSession({
             playerId = player.UserId,
             recipeId = item,
             position = position or Vector3.new(0, 0, 0),
             startTime = os.clock(),
             duration = duration,
         }), ...
     )
     ```
   * And lines 115-117:
     ```lua
     for id, session, score in world:query(CookingSession, CookingScore) do
         local timeElapsed = os.clock() - session.startTime
         if timeElapsed >= session.duration + 0.5 then
             ...
             world:remove(id, CookingSession)
             world:remove(id, CookingScore)
         end
     end
     ```
   * **Problem**: In `CraftConfig.lua`, `cookingTimes` is set to e.g. 3s (`Edamame Snack`), 4s (`Bread`), 5s (`Apple Pie`).
   * On the client (`CookingController.lua`), notes spawn at 1.0s intervals and take `fallDuration = 2.0s` to fall. For a recipe spawning $N$ notes, note $N$ lands at $t = (N-1) \times 1.0 + 2.0$ seconds. For 10 notes (or even 5 notes at 1s intervals), note hits occur up to $t = 11.0$s (or $t = 6.0$s).
   * Because `session.duration` is set to `craftConfig.cookingTimes[item]` (e.g. 3s, 4s, 5s), the server session closes and destroys the `CookingSession` / `CookingScore` entities at $t = 3.5\text{s}, 4.5\text{s}, 5.5\text{s}$ — **BEFORE** all client notes reach the target line!
   * Any subsequent `CookingHit` events sent by the client after $t = 5.5\text{s}$ are silently ignored by `world:query(CookingSession, CookingScore)` because the server entity was already removed.
   * As a result, the server calculates final quality using truncated hits (`#scores < totalNotes`), wrongly demoting player performance to `"ok"` quality even if the player hit every note perfectly on the client!

---

## 3. Caveats

* End-to-end player network latency simulation requires launching Roblox Studio playtest session.
* Client timing authorization is trusted for `CookingHit` events; server enforces hit count cap (`hitCount < score.totalNotes`).

---

## 4. Conclusion

**Verdict**: **REQUEST_CHANGES**

### Findings

#### [Major] Finding 1: Server Cooking Session Duration Desync with Note Animation Sequence
* **What**: `session.duration` on the server is set to `craftConfig.cookingTimes[item]` (3s-5s for early recipes), whereas the client rhythm minigame note sequence takes `(totalNotes * 1.0) + fallDuration (2.0s) + 0.5s` (~12.5s for 10 notes, ~6.5s for 5 notes).
* **Where**: `src/server/Services/CookingValidationSystem.lua` lines 63 and 117.
* **Why**: The server purges the `CookingSession` ECS entity at `session.duration + 0.5` (e.g. 4.5s for `Bread`), discarding all note hits sent by the client after 4.5s. This causes the server to evaluate quality on incomplete hit counts, artificially capping player quality ratings at `"ok"`.
* **Suggestion**: Update line 63 in `src/server/Services/CookingValidationSystem.lua` so `session.duration` accounts for the note animation duration:
  ```lua
  local minNoteDuration = (totalNotes * 1.0) + 3.0
  local duration = math.max(craftConfig.cookingTimes and craftConfig.cookingTimes[item] or 10, minNoteDuration)
  ```

#### [Minor] Finding 2: Wrapper File Duplicate Pathing
* **What**: `src/server/systems/cooking/CookingValidationSystem.lua` acts as a thin wrapper around `src/server/Services/CookingValidationSystem.lua`.
* **Where**: `src/server/systems/cooking/CookingValidationSystem.lua`.
* **Why**: Having two files with identical names in different directories can confuse maintainers.
* **Suggestion**: Keep file wrapper documented clearly or centralize in `src/server/Services/`.

---

## 5. Verification Method

1. **Rojo Build Verification**:
   ```bash
   rojo build --output test.rbxl
   ```
2. **Code Inspection**:
   * Inspect `src/server/Services/CookingValidationSystem.lua` lines 63-72 & 115-117 to verify `session.duration`.
   * Inspect `src/client/Controllers/CookingController.lua` lines 282-370 to calculate note animation timeline.
   * Confirm deletion of `src/server/CookingSession.server.lua`.
   * Confirm `default.project.json` `$ignoreUnknownInstances: true`.
