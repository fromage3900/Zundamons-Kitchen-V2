# Review & Handoff Report — Reviewer 1 (Milestone 2: Cooking & Rhythm Minigame System)

## Review Summary

**Verdict**: REQUEST_CHANGES

The overall implementation for Milestone 2 is architecture-compliant, clean, and robustly built. All AGENTS.md workspace rules have been strictly met, `RewardCore.lua` was relocated and re-imported properly, legacy event collision scripts were removed, and `rojo build` compiles cleanly with 0 errors.

However, a **Major Bug** was discovered during adversarial review in `CookingController.lua` where client-side rhythm score evaluation passes an aggregated summary table to `craftConfig.calculateQuality`, causing the local `onComplete` callback quality rating to always evaluate to `"ok"`.

---

## 1. Observation

### Code Review Findings

#### [Major] Finding 1: Client-Side Quality Calculation Table Mismatch in `CookingController.lua`
- **What**: In `src/client/Controllers/CookingController.lua` (lines 373-377), when a cooking session completes, `CookingController.start` calculates local quality by passing an aggregated table of counts to `craftConfig.calculateQuality`:
  ```lua
  local quality = craftConfig.calculateQuality and craftConfig.calculateQuality({
      { tag = "perfect", count = currentScore.perfect or 0 },
      { tag = "great", count = currentScore.great or 0 },
      { tag = "good", count = currentScore.ok or 0 }
  }, totalNotesToSpawn) or "ok"
  ```
- **Where**: `src/client/Controllers/CookingController.lua:373-377`
- **Why**: `craftConfig.calculateQuality(scores, totalNotes)` in `CraftConfig.lua` expects `scores` to be an unrolled array of individual hit objects (`#scores` = total hits). If `#scores < totalNotes`, `calculateQuality` immediately returns `"ok"`.
  Because `CookingController.lua` passes a 3-element table (`#scores` = 3), for any recipe with 4+ notes, `3 < totalNotes` evaluates to `true` and the function returns `"ok"` regardless of actual score (e.g. even if player scored 10/10 Perfect hits). Note: The server-side validation in `CookingValidationSystem.lua` unrolls score entries correctly, so server rewards are unaffected, but any client script or UI relying on `CookingController.start`'s `onComplete` callback receives an inaccurate `"ok"` grade.
- **Suggestion**: Unroll `currentScore` into individual hit entries before calling `calculateQuality` in `CookingController.lua`:
  ```lua
  local scoreList = {}
  for _ = 1, currentScore.perfect or 0 do table.insert(scoreList, { tag = "perfect" }) end
  for _ = 1, currentScore.great or 0 do table.insert(scoreList, { tag = "great" }) end
  for _ = 1, currentScore.ok or 0 do table.insert(scoreList, { tag = "good" }) end
  local quality = craftConfig.calculateQuality(scoreList, totalNotesToSpawn)
  ```

#### [Minor] Finding 2: Lack of Delta-Time Frame Accumulation on Note Spawning
- **What**: In `CookingController.lua` (lines 334-338), note spawning checks `now - lastSpawnTime >= peaSpawnInterval`. Under sudden client frame rate drops, only 1 note spawns per frame tick without compensating for missed time slots.
- **Where**: `src/client/Controllers/CookingController.lua:334-338`
- **Why**: Under heavy frame drops, fewer than `totalNotesToSpawn` notes may spawn before the total duration timeout completes the session.
- **Suggestion**: Update `lastSpawnTime` using interval subtraction or a while loop for catch-up spawning during frame lag.

---

## Verified Claims

- **`$ignoreUnknownInstances: true`**: Verified in `default.project.json` under `"Workspace"` (line 76). → PASS
- **PlayerGui Decoupling (AGENTS.md Rule 2)**: Verified no `script.Parent` UI references in StarterPlayerScripts client scripts. `ClientGuiBootstrap.createScreenGui` sets `ResetOnSpawn = false`. `CookingController` mainPanel sets `Visible = false` on startup. → PASS
- **Wally Package Mappings (AGENTS.md Rule 3)**: Verified `ProfileService` in `[server-dependencies]` in `wally.toml`. Mappings in `default.project.json` set to `Packages` and `ServerPackages`. `.gitignore` excludes `Packages/`, `ServerPackages/`, `wally.exe`, `wally.zip`. → PASS
- **ServerScriptService Import Path Consistency (AGENTS.md Rule 4)**: Verified all server scripts import via `ServerScriptService.Services.X` or `ServerScriptService.systems.X`. No `.Server.` path segments or relative `script.Parent` server imports found. → PASS
- **`RewardCore.lua` Relocation & Imports**: Verified `src/server/Services/RewardCore.lua` exists and `src/shared/ConfigurationFiles/RewardCore.lua` was deleted. Verified imports across `AdvancedRewards.server.lua`, `CraftManager.server.lua`, `FishingServer.server.lua`, `ServingSystem.server.lua`, `CookingValidationSystem.lua`, and `LootModule.lua` use `require(game:GetService("ServerScriptService").Services.RewardCore)`. `RewardCore.addGold` tracks `d.total_gold_earned`. → PASS
- **Deactivation of Legacy `CookingSession.server.lua`**: Verified `src/server/CookingSession.server.lua` was deleted, preventing remote listener collisions. → PASS
- **Duplicate Auto-Save Cleanup**: Verified `PlayerDataService.lua` has only 1 periodic auto-save loop (lines 219-234). → PASS
- **Compilation Build**: Verified via independent execution of `rojo build --output test.rbxl` (built cleanly with 0 errors). → PASS

---

## 2. Logic Chain

1. **Observation**: Inspection of `src/client/Controllers/CookingController.lua` lines 373-377 showed passing `{ {tag="perfect", count=...}, ... }` to `craftConfig.calculateQuality`.
2. **Observation**: Inspection of `src/shared/ConfigurationFiles/CraftConfig.lua` lines 84-98 showed `if #scores < totalNotes then return "ok" end` and iteration `for _, s in ipairs(scores) do if s.tag == "perfect" ...`.
3. **Inference**: Passing a 3-element table causes `#scores` to equal 3. For any recipe requiring 4 or more notes, `3 < totalNotes` is true, forcing `calculateQuality` to return `"ok"` to `onComplete`.
4. **Conclusion**: While server-side score processing in `CookingValidationSystem.lua` unrolls score entries properly, client-side local quality reporting in `CookingController.lua` is broken and requires changes.

---

## 3. Caveats

No caveats. Codebase was fully inspected and compiled via Rojo.

---

## 4. Conclusion

Verdict is **REQUEST_CHANGES** due to Finding 1 (Client-side quality calculation table mismatch in `CookingController.lua`).
Once `CookingController.lua` unrolls `currentScore` before invoking `craftConfig.calculateQuality`, the implementation will be 100% complete and ready for approval.

---

## 5. Verification Method

1. Inspect `src/client/Controllers/CookingController.lua` lines 373-377.
2. Observe table format passed to `craftConfig.calculateQuality`.
3. Compare against `scoreList` unrolling in `src/server/Services/CookingValidationSystem.lua` lines 122-125.
4. Run `rojo build --output test.rbxl` to confirm build succeeds without syntax errors.
