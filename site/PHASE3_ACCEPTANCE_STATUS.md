# Phase 3 Acceptance Status

Updated: 2026-07-21
Branch: `codex/phase1-recovery`

This document separates implemented source, static/build evidence, live Studio evidence, and acceptance still requiring an external reconnect.

## Domain status

| Domain | Implementation evidence | Live evidence | Status |
| --- | --- | --- | --- |
| Data and rewards | `668e88d`; serialized rollback-safe mutations, projections, inventory helpers, atomic `RewardCore.settle` | Rejected/thrown mutation rollback, grants/consumption, gold lifetime accounting, and client projection tested in Studio | Verified |
| Fishing | `3a304c5`; sole adapter, opaque session, canonical rod-type validation, server simulation, bounded input, cleanup, atomic catch settlement | Duplicate/forged/legacy/replay rejection verified. The real `Driftwood Rod` caught one Carp; item, species counter, and total survived a ProfileService mock release/reload exactly once | Verified for single-player and mock rejoin; concurrent two-player gate remains |
| Cooking | `48fa918`; reservation journal, opaque session, server note schedule/quality, atomic quality-owned dish settlement | Real perfect Apple Pie consumed 3 Apples/5 Wheat and settled once; death restored ingredients and created no dish | Verified for completion and death refund; crash/rejoin remains integrated-gate work |
| Serving | `7f62ba8`; owner/state/proximity validation, server-selected dish quality, locked atomic dish/reward settlement; fail-safe guest cleanup | Real client cooking produced Bread through timed server hits; real `ServeGuest` consumed one perfect Bread, settled once, removed the guest, rejected replay, and projected gold/guest changes to the HUD | Verified for the single-player adapter loop; multi-player/rejoin remains integrated-gate work |
| Harvest pickup | `74af38e`; expiring player/item/position token, distance and replay validation, prompt plus touch, atomic inventory/XP; Rojo-backed loot templates | Real harvest issued a Zunda Flower token; forged item and distant claims failed, valid nearby claim added one item/one revision, and replay failed. A second real drop exposed its zero-hold prompt and keyboard `E` pickup added the item. Collection quest state remained false before claim and became true only after settlement | Verified for token authority, prompt pickup, and claim-owned progression; touch presentation and rejoin remain integrated-gate work |
| Resource authoring | `3d2248c`; mesh-independent archetypes, reactive tag/attribute authoring, opt-in Part/SpecialMesh swaps, authored MeshPart preservation | Live tag-first/attribute-later tests attached click/tool behavior, preserved size/color/custom health, applied a configured Rock variant to a Part, and left an imported MeshPart unchanged with an explicit authoring status | Verified for runtime authoring contract; collaborator Studio placement parity remains a level-design gate |
| Zundarooms | Quest-gated clip entrance, isolated runtime chase, server escape settlement, persistence projection, and safe cleanup | Live Studio exposed and fixed two placement defects (shared player/entity spawn and placement below `FallenPartsDestroyHeight`); entry remained active, exact exit awarded +100 gold and one escape, unlocked discovery, and removed the runtime room | Verified for entry/escape/single settlement; catch/death/timeout/rejoin remain integrated-gate work |
| Persistence | `PlayerDataService` owns ProfileService session locking, Studio mock isolation, one-time legacy import, schema reconciliation, release handling, and projections | Studio-only release/reload probe retained currency, inventory, unlock, companion, and cooked-dish structures; interrupted cooking ingredients restored once and its reservation cleared | Verified with ProfileService mock; production DataStore API/rejoin remains a publish-environment gate |
| Integrated loop | Authoritative harvest token, cooking session, serving settlement, quest rewards, and HUD projection | Fresh launch: five real Sickle swings produced six Wheat/seed tokens; claims reached 10 Wheat; perfect Bread consumed 10 Wheat; serving consumed one Bread, removed guest, rejected replay, and updated HUD | Verified single-player fresh-launch loop |

## Phase 3 Code-Level Fixes Applied (July 2026)

The following code fixes were implemented to address bugs identified during Phase 3 recovery. All changes pass Rojo build and Selene lint (0 errors, 0 parse errors).

### 1. Companion System — Simplified Model Loading
**File:** `src/server/CompanionManager.server.lua`

- **Problem:** 7-level InsertService/workspace fallback chain was fragile; InsertService often unavailable in Studio, leaving companions invisible
- **Fix:** Simplified to 2-level: primary load from `workspace.ServerStorage.zundapalupdate4`, fallback to `workspace:FindFirstChild("zundapalupdate4")` 
- **Result:** Companion uses the `zundapalupdate4.fbx` mesh directly with no InsertService dependency
- **Default:** `data.active_companion` defaults to "zundapal" in `onPlayerAdded` for users with no companion selected
- **Status:** ✅ Code fix applied. Requires Studio test: verify companion appears with zundapalupdate4 mesh on character spawn

### 2. Cooking Controller — Removed Client-Side Quality Calculation
**File:** `src/client/Controllers/CookingController.lua`

- **Problem:** Client imported `craftConfig` and called `craftConfig.calculateQuality()` to compute hit quality, creating a client-forgeable quality path
- **Fix:** Removed `craftConfig` dependency entirely. Client-side quality replaced with simple display-only ratio (currentNoteTime / totalNoteTime) that affects only the local UI animation. Client sends only intent (sessionId + noteIndex) — the server owns all quality derivation
- **Status:** ✅ Code fix applied. Requires Studio test: verify cooking notes travel client→server without client-side quality forgery

### 3. VN Welcome Dialogue — Timing Robustness
**File:** `src/client/VNController.client.lua`

- **Problem:** Raw `task.delay(2.5)` assumed `_G.ZundaVN` would be ready within 2.5 seconds. If not, the welcome dialogue silently failed to show
- **Fix:** Replaced `task.delay(2.5)` with a polling loop checking `_G.ZundaVN` readiness every 0.5s, with a 10-second timeout fallback. If `_G.ZundaVN` becomes ready within the window, dialogue fires immediately
- **Status:** ✅ Code fix applied. Requires Studio test: verify VN welcome dialogue fires on respawn

### 4. HUD Sync — Verified Already Correct
**File:** `src/client/HudBootstrap.client.lua`, `src/client/HudScript.client.lua`

- **Finding:** HUD sync is already properly wired through `RewardEvents` (`ChefLevelUpdate`, `ComboUpdate`, `LevelUpEvent`). No changes needed
- Initial sync via `RequestRewardSync:InvokeServer()` on startup
- ChefPill and XPBar already subscribe to `PlayerDataService` projection updates
- **Status:** ✅ No changes required

### 5. PeaWheel Controller — Verified Already Clean
**File:** `src/client/Controllers/PeaWheelController.lua`

- **Finding:** The `fix_peewheel.py` script identified a redundant bottom section with a duplicate hub button click handler. Current file already has the hub handler properly inside `buildWheelGui()`, no redundant bottom section exists
- **Status:** ✅ Already clean. No changes required

### 6. Harvest System — Bug Fixes (Flower/Mushroom Picking)
**Files:** `src/server/Validation/HarvestValidator.lua`, `src/client/Controllers/HarvestController.client.lua`

- **Problem #1:** `HarvestValidator.validateNode()` checked `node:GetAttribute("Seeded")` unconditionally. Wild flower/mushroom nodes (which have no `Seeded` attribute) returned `nil == false` → items incorrectly rejected
- **Fix #1:** Changed to `local seeded = node:GetAttribute("Seeded"); if seeded ~= nil then return seeded end; return true` — only checks if attribute exists
- **Problem #2:** `HarvestController.client.lua` used `FindFirstChild("HarvestNode")` which could return nil if the remote was still initializing
- **Fix #2:** Changed to `WaitForChild("HarvestNode", 15)` with warning logged if not found
- **Problem #3:** Client-side heartbeat loop did not match server validation for the `Seeded` attribute, causing potential desync
- **Fix #3:** Heartbeat loop now also checks `Seeded` attribute existence before rejecting, matching server-side behavior
- **Status:** ✅ Code fixes applied. Requires Studio test: verify flower/mushroom picking works

### 7. UI Panel Wiring — MaterialsScript Fixed
**File:** `src/client/MaterialsScript.client.lua`

- **Problem:** `CozyModalShell.wrap(panel, {...})` was missing the `actionId` parameter, and `UIRouter.register("materials")` was not called. This meant the Materials panel would not integrate with the UIRouter's modal exclusivity/Escape handling system
- **Fix:** Added `actionId = "materials"` to the CozyModalShell.wrap call. Added `UIRouter.register("materials", nil, function() shell.close() end)` for proper modal stack management
- **Other panels (Pouch, Quests, Compendium, Settings):** Already properly wired with UIRouter and ActionRegistry registrations — no changes needed
- **Status:** ✅ Fix applied

## Independent Tool Gates

| Gate | Result | Interpretation |
| --- | --- | --- |
| Rojo build | PASS | `build/phase3-final-static.rbxl` serialized successfully. |
| Focused StyLua checks | PASS | Project-pinned StyLua 2.5.2 independently checked the Phase 3 change set before commit. |
| Repository StyLua check | FAIL | Broad inherited formatting drift remains; output exceeds 15,000 diff lines. This is not masked by Rojo. |
| Focused Selene checks | PASS | Changed authority/service files report zero errors, warnings, and parse errors, except inherited constructor-parent warnings in legacy UI files. |
| Repository Selene | WARN/exit 1 | Zero errors, zero parse errors, 316 deprecation/style warnings (inherited `Instance.new` two-argument usage). |
| Git diff check | PASS | Every Phase 3 checkpoint passed before commit. |
| Git synchronization | PASS | Local HEAD matched `origin/codex/phase1-recovery` after each pushed checkpoint. |
| Workspace preservation | PASS | `default.project.json` retains `$ignoreUnknownInstances: true` under `Workspace`. |

## Runtime Gates Remaining

Run these in one quota-efficient Studio session after MCP `58741` and Rojo `34872` are listening:

1. **Companion spawn test:** Verify companion appears with `zundapalupdate4` mesh on character spawn
2. **VN dialogue test:** Verify welcome dialogue fires after respawn following timing fix
3. **Harvest test:** Verify wild flower/mushroom nodes are pickable (were blocked by Seeded attribute check)
4. **Cooking test:** Verify cooking notes travel client→server without client-side quality forgery
5. **Multi-player Cook/Serve loop:** Repeat the verified adapter loop with a second player; confirm no cross-player guest or session access
6. **Touch collection:** Collect one repaired drop through touch; prompt/keyboard pickup, token authority, distance, forgery, one revision, and replay rejection are already verified
7. **Production rejoin:** Run a published/private-server rejoin with API access enabled to complement the passing ProfileService mock release/reload probe
8. **Two-player full loop:** Repeat the verified Harvest → Cook → Serve → Reward loop with two players and inspect cross-player ownership rejection
9. **Zundarooms cleanup:** Verify catch, death, timeout, and re-entry cleanup award no escape; rejoin and confirm escape/discovery state persists

## Connection Status

On 2026-07-21, Rojo was confirmed listening on port `34872`. The chrxxs plugin UI remained on "connecting," but the available Roblox Studio bridge successfully selected `Zundamon'sKitchenV2`, entered Play mode, executed server checks, and read console output. Runtime testing can continue through that bridge while the chrxxs-specific client startup is repaired separately.

No runtime completion claim is made for the newly applied fixes (companion, cooking controller, VN timing, harvest Seeded, MaterialsScript wiring) until the Studio runtime gates run.
