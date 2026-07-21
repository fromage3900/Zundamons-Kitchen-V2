# Phase 3 Acceptance Status

Updated: 2026-07-21
Branch: `codex/phase1-recovery`

This document separates implemented source, static/build evidence, live Studio evidence, and acceptance still requiring an external reconnect.

## Domain status

| Domain | Implementation evidence | Live evidence | Status |
| --- | --- | --- | --- |
| Data and rewards | `668e88d`; serialized rollback-safe mutations, projections, inventory helpers, atomic `RewardCore.settle` | Rejected/thrown mutation rollback, grants/consumption, gold lifetime accounting, and client projection tested in Studio | Verified |
| Fishing | `3a304c5`; sole adapter, opaque session, server simulation, bounded input, cleanup, atomic catch settlement | Duplicate/forged/legacy/replay rejection verified; real Trout catch granted one item and one revision | Verified for single-player session; multi-player/rejoin remains integrated-gate work |
| Cooking | `48fa918`; reservation journal, opaque session, server note schedule/quality, atomic quality-owned dish settlement | Real perfect Apple Pie consumed 3 Apples/5 Wheat and settled once; death restored ingredients and created no dish | Verified for completion and death refund; crash/rejoin remains integrated-gate work |
| Serving | `7f62ba8`; owner/state/proximity validation, server-selected dish quality, locked atomic dish/reward settlement; fail-safe guest cleanup | Real client cooking produced Bread through timed server hits; real `ServeGuest` consumed one perfect Bread, settled once, removed the guest, rejected replay, and projected gold/guest changes to the HUD | Verified for the single-player adapter loop; multi-player/rejoin remains integrated-gate work |
| Harvest pickup | `74af38e`; expiring player/item/position token, distance and replay validation, prompt plus touch, atomic inventory/XP; Rojo-backed loot templates | Real harvest issued a Zunda Flower token; forged item and distant claims failed, valid nearby claim added one item/one revision, and replay failed. A second real drop exposed its zero-hold prompt and keyboard `E` pickup added the item | Verified for token authority and prompt pickup; touch presentation and rejoin remain integrated-gate work |
| Resource authoring | `3d2248c`; mesh-independent archetypes, opt-in visual swaps, authored-geometry preservation | Static/serialization only | Runtime pending |
| Zundarooms | Quest-gated clip entrance, isolated runtime chase, server escape settlement, persistence projection, and safe cleanup | Live Studio exposed and fixed two placement defects (shared player/entity spawn and placement below `FallenPartsDestroyHeight`); entry remained active, exact exit awarded +100 gold and one escape, unlocked discovery, and removed the runtime room | Verified for entry/escape/single settlement; catch/death/timeout/rejoin remain integrated-gate work |

## Independent tool gates

| Gate | Result | Interpretation |
| --- | --- | --- |
| Rojo build | PASS | `build/phase3-final-static.rbxl` serialized successfully. |
| Focused StyLua checks | PASS | Each Phase 3 domain file set passed before its commit. |
| Repository StyLua check | FAIL | Broad inherited formatting drift remains; output exceeds 15,000 diff lines. This is not masked by Rojo. |
| Focused Selene checks | PASS | Changed authority/service files report zero errors, warnings, and parse errors, except inherited constructor-parent warnings in legacy UI files. |
| Repository Selene | WARN/exit 1 | Zero errors, zero parse errors, 316 deprecation/style warnings. |
| Git diff check | PASS | Every Phase 3 checkpoint passed before commit. |
| Git synchronization | PASS | Local HEAD matched `origin/codex/phase1-recovery` after each pushed checkpoint. |
| Workspace preservation | PASS | `default.project.json` retains `$ignoreUnknownInstances: true` under `Workspace`. |

## Runtime gates remaining

Run these in one quota-efficient Studio session after MCP `58741` and Rojo `34872` are listening:

1. Repeat the verified Cook -> Serve adapter loop with a second player and after rejoin; confirm no cross-player guest or session access.
2. Collect one repaired drop through touch; visible prompt/keyboard pickup, token authority, distance, forgery, one revision, and replay rejection are already verified.
3. Verify `ResourceNodeBootstrap` recognizes an existing node without changing its mesh. Duplicate it, change `ResourceArchetype`, and confirm the appropriate tool/click behavior. Enable `UseRegistryMesh` only on a disposable test node and verify the selected variant.
4. Leave during an active cooking reservation, rejoin, and confirm ingredients restore once. Rejoin after successful cooking/fishing/serving and confirm inventory, dish-quality counts, currency, XP, unlocks, and companion data persist.
5. Complete Harvest -> Cook -> Serve -> Reward once from a fresh launch and inspect console output for duplicate listeners, duplicate rewards, missing paths, or infinite waits.
6. Verify Zundarooms catch, death, timeout, and re-entry cleanup award no escape; rejoin and confirm the already verified escape/discovery state persists.

## Connection status

On 2026-07-21, Rojo was confirmed listening on port `34872`. The chrxxs plugin UI remained on "connecting," but the available Roblox Studio bridge successfully selected `Zundamon'sKitchenV2`, entered Play mode, executed server checks, and read console output. Runtime testing can therefore continue through that bridge while the chrxxs-specific client startup is repaired separately.

No runtime completion claim is made yet for serving, repaired pickup, resource authoring, persistence/rejoin, or the integrated loop until those gates run.
