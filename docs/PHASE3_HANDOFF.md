# Phase 3 — Finalization Handoff & Parallel Work Streams

Owner: fromage3900 · Last verified live in Studio: 2026-07-23
Entry point for any agent picking up work. Pairs with [PLAYTEST_NOTES.md](PLAYTEST_NOTES.md) (live issue tracker) and [PHASE3_FINALIZATION_PLAN.md](PHASE3_FINALIZATION_PLAN.md).

## Session close-out (2026-07-23)
- **Committed:** `7d2127b` on `codex/core-production-baseline` — the 12 verified files (companion, PeaWheel, keybinds, lag, Rojo project fix, docs). Rojo build passes.
- **NOT committed (Stream D):** ~124 other tracked changes from a prior batch remain staged/modified (the user's — leave them), plus untracked `ZUNDAMONS_KITCHEN_MASTER_BLUEPRINT.md` and `docs/assets/*` / `site/assets/*` binaries.
- **Scaffolding cleanup done (2026-07-23):** `.agents/` untracked + gitignored (kept on disk); junk untracked (`mcp_req.json`, `test_terminal_sim.js`, `*.blend`); superseded phase docs moved to `docs/archive/`; the 15 mojibake gifs renamed to `zundamon_emote_<group><variant>.gif` in both `site/assets/` and `docs/assets/`; authoring-plugin fail-safe guard added.
- **Known maintenance smell:** `site/` (GitHub Pages source) and `docs/` are kept in sync by `site/sync_site.js` (copies by filename, never deletes). They have diverged in git. Recommend picking one canonical dir and treating the other as generated; when renaming/adding assets, always mirror both or re-run `sync_site.js`.
- A fresh Sonnet session should branch from `7d2127b` and start with **Stream A** (load-time errors) — biggest playtest-smoothness win.

## How to work here (read first)
- **Verify everything in the live game**, not the status docs — historically the docs claimed fixes the code never made.
- Studio is usually open, synced via **chrxxs MCP** + **Rojo on 34872**. Use play mode + `execute_luau` + console output to reproduce and confirm each fix.
- **Source of truth for UI actions is `UIActionRegistry`** (single keyboard dispatcher) + the **Pea Wheel**. Panels expose behaviour via `ActionRegistry.registerCallback(id, fn)`. Do NOT add stray `InputBegan` listeners for panel hotkeys.
- `default.project.json` is Rojo-strict: instance properties go under `$properties`, never as bare keys. Don't add a BOM.

## ✅ Done & verified live
- Companion = real level mesh `Workspace.Meshes/zundapalupdate4` (id 124750913039753), human-scaled, cube impossible.
- PeaWheel module load crash fixed (`GuiService.ReducedMotionEnabled`); builds 8 slices.
- Lag: removed 3 per-frame offenders (SkyOverlay invalid TileOffset, WireframeOutline & ReverbHandler full-workspace scans + bad enum).
- Keybinds: central dispatcher in `UIActionRegistry`; Cook slice wired to K; F1 freed for Keybinds panel.
- Legacy overlay cleanup crash fixed → ~30 legacy scripts + duplicate shells now removed.
- Rojo project parse error fixed (`Lighting.$properties`).

## 🔴 Remaining work — parallelizable streams

### Stream A — Load-time script errors (blocks smooth playtest) — HIGH
Each is independent; one agent can take the batch.
1. `GuestManager:390` — `require` invalid arg → guests spawn as capsules ("Mesh missing Torso"). Same class as the companion mesh bug; find the real guest character source.
2. `VNController:200` — `attempt to index nil with 'zundamon'` on welcome show (speaker table lookup).
3. `EndlessLoopWiring:115` — `CookCompleted` not a member of `CookingService`; wire the correct signal/name.
4. `AmbientZoneAudio:52` — `CFrame` not valid on `AudioEmitter`; use the emitter's parent part CFrame.
5. `FXController:11` — "Module code did not return exactly one value"; fix the return.
6. `DailyController`/`PlayerDataService:123` — passes the Character model; pass the Player.
7. `OutfitWardrobeGui`/`WelcomeStarterPackGui`/`PromoCodeGui` — infinite-yield on `ReplicatedStorage.Shared:WaitForChild("ConfigurationFiles")`; correct path is `ReplicatedStorage.ConfigurationFiles`.
8. `ResourceVisualAuthoringPlugin:13` — a Studio **plugin** script is parented in Workspace and runs at play; remove it from the place/`src/Workspace`.

### Stream B — UI source-of-truth completion — HIGH
1. **Emoji audit** — replace unsupported emoji (notably `🫛` U+1FAD8, and any tofu-box glyphs) with supported emoji or image assets across all UI. This is the "empty boxes."
2. **PeaWheel hub button** — confirm click toggles in play; the tutorial overlay likely intercepts clicks on spawn. Ensure hub button sits above modal overlays or the tutorial yields input.
3. **Progression panel** — `UpdateScript` skips it ("No GUI with MainFrame found"); a deprecated function not yet recovered in the new UI. Rebuild or wire it as a Pea Wheel/HUD action.
4. **Deprecated-function parity audit** — confirm every old-UI function has a new-UI equivalent: inventory, cook, quests, compendium, materials, map, shop, settings, companions, daily, keybinds, progression. (progression is the known gap.)

### Stream C — Companion polish — MEDIUM
1. Orientation constant `ORIENT_CORRECTION` in `CompanionManager.server.lua` (~L340) — user tuning; try `CFrame.Angles(math.rad(180),0,0)` if still inverted.
2. Companion mesh is **untextured (white)** — needs a texture/SurfaceAppearance.
3. Baked animations — needs a rigged/skinned zundapal asset or animation IDs (blocked on asset).

### Stream D — Repo hygiene & commit — MEDIUM
- ~6k lines uncommitted. Commit in logical chunks (fixes / hygiene / formatting).
- Untrack build artifacts + `test_terminal_sim.js`, `mcp_req.json`; gitignore `*.rbxl`, `build/`.
- Reconcile/retire the stale `.agents/` boards (they contradict each other and mislead).
- Validate the wally dependency fork swap (ProfileService/ReplicaService).

## Phase 3 publishing criteria (definition of done)
- [ ] Zero load-time script errors in a fresh play session (Stream A).
- [ ] No tofu/empty-box glyphs anywhere; all UI icons render (Stream B1).
- [ ] Every deprecated UI function has a working new-UI equivalent; no duplicate panels (Stream B).
- [ ] PeaWheel + all 8 slices + all hotkeys single-toggle cleanly; Cook opens (verify live).
- [ ] Companion: correct mesh, upright, human-sized, textured (Stream C1–2).
- [ ] Guests render as characters, not capsules (Stream A1).
- [ ] Multi-player + production DataStore rejoin pass (from PHASE3_ACCEPTANCE_STATUS.md runtime gates).
- [ ] Clean tree committed; Rojo build + focused Selene/StyLua pass (Stream D).
