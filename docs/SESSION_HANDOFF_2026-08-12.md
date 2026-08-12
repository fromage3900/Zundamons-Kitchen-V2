# Session Handoff — 2026-08-12 (Harvest Visuals + Phase 4 UI Surface)

Next session should start here. All commits below are on `main` and gated.

## What shipped this session (8 commits)

| Commit | What |
| --- | --- |
| `3aa5481` | **Runtime resource visuals killed.** `ResourceVisualService` is authored-only — no scatter cubes, no spawn/tween pipeline, no flicker. Scatter/visual remotes fire into the void by design until a real client surface exists. |
| `49d9f96` | **Part-built harvest props.** Deleted the 16-mesh Candidate showcase (mesh IDs were in-level embedded content; synced refs rendered as giant/textureless blobs). Replaced with pure-Part click-gather nodes at real scale along the loop (x=40..85, z=30): Mushroom (Sickle tool node) + ZundaFlower, ZundaPea, EdamamePod, ZundaLeaf, SweetPea, PeaFlower (click nodes with authored ClickDetectors, `MaxActivationDistance=16`). All wired through `ResourceNodeRegistry`/`GatheringNodes` — adopt automatically via `ResourceNodeBootstrap`. |
| `b3f6c3f` | **HeroRock** converted from mesh `5003626535` to a 5-ball part boulder (PickAxe. All `src/Workspace` is now **zero `MeshId` dependencies**. |
| `755b3ea` | **Server:** client-invokable `ChallengeStart`/`ChallengeAbandon`/`ChallengeCompleteWave`/`DailyClaimReward`/`DailyClaimWeekly` RemoteFunctions in `ReplicatedStorage.RemoteFunctions`. Challenge settlement (gold+xp+style+legendary) collapsed into ONE `PlayerDataService.mutate`; DailyChallengeService all durable writes routed through mutate; visitor/resources/weekly settlements fail closed on `settle` failure. |
| `d22971d` | **Client:** `src/client/ChallengeModeUI.client.lua` — full modal (ClientGuiBootstrap, ResetOnSpawn=false, panel hidden on start), wave/tier/score live updates, start/abandon, daily streak + claim cards, weekly boss. Registers `challenge` action in `UIActionRegistry` (button-only, no key). |
| `4799cb6` | **Client:** golden `!` beacon + top-left guest counter in `GuestDetector`; serve UI now reads live `PlayerStateChanged` projection (dish list = `cookedDishes[dish]` totals, not raw inventory scan); tutorial +2 steps (serve, challenge). |
| `8e337ff` | **Cooking:** server sends authoritative `perfectWindow`/`greatWindow`/`okWindow`/`startDelay` in the session payload; client falls back to `PEA_CONFIG` only if absent. |
| `ebb7bed` | Dead `ItemGatherSystem` replaced with documented no-op (was never registered; bypassed mutate). |
| `0320d81` | Guest pacing halved (spawn 15–30s, first guest 8s, new players 10–20s). |

## Current state (verified)

- All 3 gates green: StyLua, Selene (0 errors; 357 pre-existing warnings), `rojo build`.
- Working tree clean.
- Harvest props exist **in the repo** (`src/Workspace/GameplayLoopArea/GatheringNodes/`) — they appear in Studio after the next Rojo sync. Studio needs to be open with the Rojo plugin connected (MCP plugin was disconnected at session end).

## Known issues / gotchas (read before touching)

1. **Don't reintroduce mesh assets.** The 2026-08-12 level scan IDs (mushroom `77467866039933`, candidates, etc.) are *embedded place content* — they render correctly only inside the authored file. Any new prop should be **part-built** or a verified public upload.
2. **Part names must not substring-match archetype aliases** (`Pea`, `Leaf`, `Pod`, `Root`, `Mushroom`, `Flower`, `Tree`, `Rock`, …) or `ResourceNodeRegistry.infer` will register them as extra nodes. Current props use safe names (`Pickup`, `Stem`, `Petal`, `Cluster`, `Seed`, `Blossom`, `Boulder`, `Foliage`, `Vine` — none substring-collide with registered aliases). Verify new names against aliases in `ResourceNodeRegistry.lua`.
3. **Click nodes need the ClickDetector authored in the model.json** (applies on `BasePart` targets only). Tool nodes (Mushroom, HeroRock) get tags via the `Mineable` path — no detector.
4. **`_G.ZundaShowServeUI(guest, data)`** signature changed usage: GuestDetector now passes the reactive projection, not `_G.data`. Any legacy caller passing stale `_G.data` will show an empty dish list.
5. **ChallengeModeUI is Phase-4 surface but not playtest-verified end-to-end yet** — remote names match the wiring, but wave completion + abandonment flow need a live playtest (player presses Start → serves guests → completes → claims).
6. Player-added vital UI (`GuestLocatorGui`, `ChallengeModeGui`) uses `ClientGuiBootstrap` + `ResetOnSpawn=false` + hidden panels — keep that contract if refactoring.

## Next session options (pick one, in priority order)

1. **Playtest the full loop** with the MCP plugin connected: start solo playtest → verify harvest props are clickable (part-built nodes), serve flow with beacons, challenge panel end-to-end (start → wave → abandon/complete → claim), cooking hit windows. Log findings in `docs/PLAYTEST_NOTES.md`.
2. **Verify Rojo sync did not resurrect** the deleted candidates and the parts render at real scale; adjust y-positions in `src/Workspace` model.json if they clip terrain (they were authored pre-terrain-check).
3. **Challenge/daily polish pass**: the UIActionRegistry "challenge" action has no key binding; consider `N` for Challenge (Quest is `J`, Inventory is `E`/`I`). Also add a `Challenges` HUD button if the Pea Wheel doesn't surface it.
4. **Guest patience ring** (Phase 4 Plan §B1) — currently only the `!` beacon exists; patience feedback still pending.
5. **Companion white-render investigation** (Phase 4 Plan §D1) — oldest open visual bug.

## Files most relevant to next-session work

- `src/Workspace/GameplayLoopArea/GatheringNodes/*` — part-built harvest props (edit model.json to move/restyle)
- `docs/RESOURCE_NODE_AUTHORING.md` — the canonical tag/attribute contract
- `src/server/systems/EndlessLoopWiring.server.lua` — RemoteFunction surface for challenge/daily
- `src/client/ChallengeModeUI.client.lua` — the new UI surface
- `src/server/Services/DailyChallengeService.lua`, `ChallengeModeService.lua` — mutate-routed settlements