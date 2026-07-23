# Phase 3 — Finalization Handoff & Parallel Work Streams

Owner: fromage3900 · Last verified live in Studio: 2026-07-23
Entry point for any agent picking up work. Pairs with [PLAYTEST_NOTES.md](PLAYTEST_NOTES.md) (live issue tracker) and [PHASE3_FINALIZATION_PLAN.md](PHASE3_FINALIZATION_PLAN.md).

## Session close-out (2026-07-23, evening — Stream A + UI layering DONE)
- **Pushed through `48bca32` on `main`.** Stream A is fully fixed and verified live (`41ca95e`), the DisplayOrder ladder landed (`27f32dd`, see [FX_UI_LAYERING_PLAN.md](FX_UI_LAYERING_PLAN.md)), and 8 dead-generation GUI shells were destroyed + the starter-gift popup gated behind the tutorial (`ece9cec`).
- **⚠️ To ship the in-place fixes: File → Publish from Studio once.** The stray `ZundaResourceVisualAuthoring` plugin Model lives in the `.rbxl` (not Rojo), so its deletion — and everything else — only sticks after a publish/save.
- **⚠️ Starter gift rewards are display-only** — claim just closes the panel; no server grant exists (FX_UI_LAYERING_PLAN.md item 10). Wire or label before monetization review.
- **Known maintenance smell:** `site/` (GitHub Pages source) and `docs/` are kept in sync by `site/sync_site.js` (copies by filename, never deletes). They have diverged in git. Recommend picking one canonical dir and treating the other as generated; when renaming/adding assets, always mirror both or re-run `sync_site.js`.
- Next session: **Stream B** (emoji audit, Progression panel, parity audit) or the Nikki polish backlog in FX_UI_LAYERING_PLAN.md.

## Session close-out (2026-07-23, earlier)
- **Committed:** `7d2127b` — the 12 verified files (companion, PeaWheel, keybinds, lag, Rojo project fix, docs). Rojo build passes.
- **Scaffolding cleanup done:** `.agents/` untracked + gitignored (kept on disk); junk untracked; superseded phase docs moved to `docs/archive/`; the 15 mojibake gifs renamed to `zundamon_emote_<group><variant>.gif` in both `site/assets/` and `docs/assets/`.

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

### ~~Stream A — Load-time script errors~~ — ✅ DONE (`41ca95e`, verified live: zero client errors)
All 8 items fixed: NPCPatrolSystem Script→ModuleScript, GuestManager Kenney-rig part names (real mesh guests), VN speaker tables exported, CookingService.CookCompleted signal added, AudioEmitter parented to positioned part, 7 FX modules got final returns, DailyController passes Player, ConfigurationFiles path corrected in 5 files (+FontFace fix), stray Workspace plugin Model deleted (needs a place publish to persist).

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
- [x] Zero load-time script errors in a fresh play session (Stream A — verified live 2026-07-23; needs place publish to persist the Workspace plugin deletion).
- [ ] No tofu/empty-box glyphs anywhere; all UI icons render (Stream B1).
- [ ] Every deprecated UI function has a working new-UI equivalent; no duplicate panels (Stream B).
- [ ] PeaWheel + all 8 slices + all hotkeys single-toggle cleanly; Cook opens (verify live).
- [ ] Companion: correct mesh, upright, human-sized, textured (Stream C1–2).
- [x] Guests render as characters, not capsules (verified live: "Using mesh guest" in console).
- [ ] Multi-player + production DataStore rejoin pass (from PHASE3_ACCEPTANCE_STATUS.md runtime gates).
- [ ] Clean tree committed; Rojo build + focused Selene/StyLua pass (Stream D).
