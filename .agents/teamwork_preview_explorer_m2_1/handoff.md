# Handoff Report: Client-Side Cooking & Rhythm Minigame System Audit

## 1. Observation

### File & Workspace Audit
* **Target Missing File**: `src/client/Controllers/CookingController.lua` specified in `plan.md` and task request **does not exist** in the workspace.
* **Rojo Level Preservation**: `default.project.json` line 76 contains `"$ignoreUnknownInstances": true` under `"Workspace"`. **COMPLIANT** with AGENTS.md Rule 1.
* **Wally & Package Mappings**: `wally.toml` line 24 includes `ProfileService` under `[server-dependencies]`. `default.project.json` maps `"Packages"` to `ReplicatedStorage.Packages` (line 10) and `"ServerPackages"` to `ServerScriptService.ServerPackages` (line 63). `.gitignore` ignores `Packages/`, `ServerPackages/`, `wally.exe`, `wally.zip`. **COMPLIANT** with AGENTS.md Rule 3.
* **ServerScriptService Imports**: `CookingValidationSystem.lua` line 13 uses `require(SSS:WaitForChild("Services"):WaitForChild("PlayerDataService"))`. **COMPLIANT** with AGENTS.md Rule 4.

### Client UI & System Architecture Fragmentation
The project currently contains **two separate, unintegrated client cooking implementations**:

#### System A: Imperative / Procedural (`TimedCookingScript.client.lua` + `CraftingScript.client.lua` + `CookingResultCard.client.lua`)
1. **GUI Construction**: `TimedCookingScript.client.lua` lines 50–55 creates `ScreenGui` directly (`Instance.new("ScreenGui")`) inside `PlayerGui` instead of using `ClientGuiBootstrap.createScreenGui(...)`. **VIOLATION** of AGENTS.md Rule 2b.
2. **Global State Dependency**: `CraftingScript.client.lua` lines 140 & 153 invoke `_G.TimedCooking.start` and `_G.TimedCooking.isCooking()`, relying on fragile global table state (`_G`).
3. **Note Hit Tracking & Timing Windows**:
   * Defined in `PEA_CONFIG` (`TimedCookingScript.client.lua` lines 23–29):
     * `fallDuration`: `2.0` seconds
     * `hitWindow` (Perfect): `|timeDiff| <= 0.15s`
     * `greatWindow` (Great): `0.15s < |timeDiff| <= 0.35s`
     * `okWindow` (OK): `0.35s < |timeDiff| <= 0.60s`
     * Miss: `|timeDiff| > 0.60s`
   * Triggered via `UserInputService.InputBegan` for `Enum.KeyCode.Space` (lines 153–198).
4. **Communication & Server Sync**:
   * Fires `cookingHitEvent:FireServer(tick(), quality)` on note hits or mistaps.
   * Uses deprecated `tick()` instead of `os.clock()` or `workspace:GetServerTimeNow()`.
   * **Silent Miss Desync**: When a pea falls past the hit zone without keypress (`progress >= 1.2`), `peas[i]` is removed locally (line 249) but **no miss remote is fired to the server**. The server (`CookingValidationSystem.lua`) only receives hits when the player presses Space, causing severe desync in total note count calculations.
5. **Note Count Mismatch**:
   * `TimedCookingScript.client.lua` line 208 runs for `PEA_CONFIG.peaSpawnInterval * 8` = 9.6s, spawning exactly **8 peas**.
   * `CookingValidationSystem.lua` line 43 and `CraftConfig.lua` default note count is **10 notes** (`totalNotes = 10`).
   * As a result, even if a player hits every pea perfectly, `hitCount` on the server can never reach `totalNotes` (8 / 10), preventing max score derivation.

#### System B: Matter ECS & React UI (`ClientMain.client.lua` + `CookingInputSystem.lua` + `CookingHUD.lua` + `PeaRhythmTrack.lua`)
1. **Startup UI Overlap**:
   * `ClientMain.client.lua` lines 44–51 mounts `CookingHUD` directly on boot into `PlayerGui` with hardcoded props (`recipeName = "Zunda Apple Pie", duration = 15, timeElapsed = 0`).
   * `CookingHUD.lua` lines 12–18 renders a `MainPanel` (`Size = 600x150`, `Position = (0.5, 0.8)`) that remains **PERMANENTLY VISIBLE** at screen bottom at game launch without active cooking sessions. **VIOLATION** of AGENTS.md Rule 2d (`panel.Visible = false` on startup / state-driven visibility).
2. **Disconnected & Mock Components**:
   * `PeaRhythmTrack.lua` (horizontal pea emoji `🫛` track component) is **not imported or rendered** inside `CookingHUD.lua`.
   * `CookingInputSystem.lua` line 23 contains mock PoC logic:
     `local isHit = math.random() > 0.3 -- 70% chance to hit for PoC`
   * `CookingInputSystem.lua` does **not fire any remote events** to `CookingValidationSystem.lua`.

### Duplicate Server Handlers
* Both `src/server/CookingSession.server.lua` and `src/server/systems/cooking/CookingValidationSystem.lua` exist in `src/server/`. Both listen to `CookingHit` remote and `StartCookingSession` / `CraftFunction`, with conflicting quality calculation logic:
  * `CookingSession.server.lua` lines 81-87: `hitCount >= maxHits` -> "perfect", `>= 0.8 * maxHits` -> "great".
  * `CookingValidationSystem.lua` lines 84-90: `weighted >= 0.9` -> "perfect", `>= 0.7` -> "great".
  * `CraftConfig.lua` line 84: `craft.calculateQuality` has a third distinct formula (`perfects >= ceil(0.6 * totalNotes)` -> "perfect").

---

## 2. Logic Chain

1. **Workspace Rule Compliance Verification**:
   * Checking `default.project.json` line 76 confirms `$ignoreUnknownInstances: true` is present under `"Workspace"`.
   * Checking `wally.toml` line 24 and `.gitignore` confirms packages and dependencies follow workspace guidelines.
2. **Client Script Architecture Audit**:
   * Searching `src/client` shows `src/client/Controllers/CookingController.lua` is missing.
   * Inspecting `ClientMain.client.lua` reveals that on game start, it mounts React `CookingHUD` into `PlayerGui`. Because `CookingHUD` has no visibility control property (`Visible = false` or conditional active check), it draws a 600x150 frame near the bottom of the screen permanently, creating UI overlaps with gameplay controls.
3. **Rhythm Gameplay & Note Hit Analysis**:
   * Examining `TimedCookingScript.client.lua` shows hit windows (150ms / 350ms / 600ms) are evaluated on Spacebar input.
   * However, when a note is missed passively (falling past line 245), the client code drops the note without sending `cookingHitEvent:FireServer(tick(), "miss")`.
   * Furthermore, `TimedCookingScript` spawns 8 peas max, whereas `CookingValidationSystem` expects 10 notes. This logic gap guarantees server score calculations will be incorrect.
4. **Input Handling & Visual Feedback**:
   * Input in `TimedCookingScript.client.lua` and `CookingInputSystem.lua` strictly checks `Enum.KeyCode.Space`, omitting Touch (mobile) and Gamepad support.
   * Neither system features floating text pop-ups ("PERFECT!", "GREAT!", "OK!", "MISS!"), combo feedback animations, or hit SFX audio triggers.

---

## 3. Caveats

* **Audio Assets**: Specific hit SFX sound IDs could not be audited for playback because CODE_ONLY execution environment restricts live Roblox engine sound playback.
* **Harvest Controller**: `src/client/Controllers/HarvestController.client.lua` was examined to verify naming standards, confirming that `CookingController.lua` is indeed missing.

---

## 4. Conclusion

* **Missing Architecture**: `src/client/Controllers/CookingController.lua` needs to be created to consolidate client cooking controller logic into a single clean controller.
* **AGENTS.md Violations**:
  1. `ClientMain.client.lua` causes permanent startup UI overlap by mounting `CookingHUD` without active state checks or `Visible = false` initial state.
  2. `TimedCookingScript.client.lua` bypasses `ClientGuiBootstrap.createScreenGui`.
* **Gameplay & Quality Bugs**:
  1. Note count desync: 8 client peas vs 10 server expected notes.
  2. Server miss desync: Passive note misses do not fire `"miss"` remote to server.
  3. Mock code in ECS: `CookingInputSystem.lua` uses 70% random hit PoC instead of actual note timing.
  4. Input limitation: Spacebar only (no mobile touch / gamepad).
  5. Missing visual cues: No floating hit judgment text ("PERFECT", "GREAT", etc.) or pop animations.
  6. Server handler conflict: `CookingSession.server.lua` and `CookingValidationSystem.lua` duplicate remote listening with conflicting quality formulas.

---

## 5. Verification Method

1. **Verify `$ignoreUnknownInstances`**: View `default.project.json` line 76 to confirm `"$ignoreUnknownInstances": true` under `"Workspace"`.
2. **Verify Client UI Overlap**: View `src/client/ClientMain.client.lua` lines 44–51 and `src/client/ui/cooking/components/CookingHUD.lua` lines 12–18 to inspect permanent startup mounting.
3. **Verify Note Count & Miss Handling**: View `src/client/TimedCookingScript.client.lua` lines 208 & 245–249 and compare with `src/server/systems/cooking/CookingValidationSystem.lua` lines 43 & 57–69.
4. **Verify Duplicate Server Scripts**: Inspect `src/server/CookingSession.server.lua` and `src/server/systems/cooking/CookingValidationSystem.lua` for duplicate `CookingHit` remote listeners.
