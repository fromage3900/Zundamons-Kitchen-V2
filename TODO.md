# Phase 3 Completion — Task List

## ✅ Step 1: Fix Companion System (Remove Fallback Chain)
- [x] Simplified `CompanionManager.server.lua` to use zundapalupdate4 mesh directly
- [x] Removed fragile InsertService/workspace fallback paths (7-level chain → 2-level)
- [x] Ensured `data.active_companion` defaults to "zundapal" in `onPlayerAdded`

## ✅ Step 2: Fix Cooking Client-Side Quality Calculation
- [x] Removed `craftConfig` dependency from `CookingController.lua`
- [x] Replaced `craftConfig.calculateQuality` call with simple local display-quality ratio
- [x] Client sends only intent (sessionId + noteIndex) — no forged quality path

## ✅ Step 3: Fix VN Welcome Dialogue Timing
- [x] Replaced raw `task.delay(2.5)` with robust wait loop checking `_G.ZundaVN` readiness
- [x] Added 10s timeout fallback so dialogue doesn't silently fail

## ✅ Step 4: Verify HUD Sync
- [x] Read `HudBootstrap.client.lua` and `HudScript.client.lua`
- [x] HUD sync is already properly wired through `RewardEvents` (`ChefLevelUpdate`, `ComboUpdate`, `LevelUpEvent`)
- [x] Initial sync via `RequestRewardSync:InvokeServer()` on startup
- [x] No changes needed - HUD already subscribes to PlayerDataService projections

## ✅ Step 5: PeaWheel Diagnostic & Fix
- [x] Verified `PeaWheelController.lua` already clean — no redundant bottom section, hub handler properly inside `buildWheelGui()`

## ✅ Step 6: Harvest System Bug Fixes
- [x] **Fix #1**: `HarvestValidator.lua` — `validateNode()` now checks `Seeded` attribute only if it exists (wild flower/mushroom nodes no longer incorrectly rejected)
- [x] **Fix #2**: `HarvestController.client.lua` — `HarvestNode` remote uses `WaitForChild` instead of `FindFirstChild`, with warning logged if not found
- [x] **Fix #3**: `HarvestController.client.lua` — heartbeat loop also checks `Seeded` attribute client-side, matching server validation

## ✅ Build Verification
- [x] **Rojo Build**: PASS — `rojo build default.project.json` → `build-test.rbxl` generated
- [x] **Selene Lint**: PASS — 0 errors, 0 parse errors across all modified files

## ✅ UI Panel Fixes Applied
- [x] **MaterialsScript.client.lua** — Added `actionId = "materials"` to `CozyModalShell.wrap()` call, added `UIRouter.register("materials")` for modal exclusivity and Escape handling
- [x] **PouchScript.client.lua** — Already had proper UIRouter/ActionRegistry wiring
- [x] **QuestScript.client.lua** — Already had proper UIRouter/ActionRegistry wiring
- [x] **CompendiumScript.client.lua** — Already had proper UIRouter/ActionRegistry wiring
- [x] **SettingsScreen.client.lua** — Already had proper UIRouter/ActionRegistry wiring

## ✅ Documentation Updated
- [x] `PHASE3_ACCEPTANCE_STATUS.md` updated with all code-level findings
- [x] All Phase 3 domains documented with current status

## Remaining — Requires Studio Testing (deferred)
- [ ] Fresh launch: Harvest → Cook → Serve → Reward → HUD
- [ ] Verify flower/mushroom picking works (was blocked by Seeded check) — code fix applied
- [ ] Verify companion appears with zundapalupdate4 mesh on character spawn — code fix applied
- [ ] Verify VN welcome dialogue fires on respawn after timing fix — code fix applied
- [ ] Multi-player concurrent session tests
- [ ] Rejoin restore verification
