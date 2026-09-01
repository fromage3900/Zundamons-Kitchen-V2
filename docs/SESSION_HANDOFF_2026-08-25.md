# Session Handoff — 2026-08-25 (Zundarooms loop + echo pipeline)

Next session should start here. All commits below are on `main`; working tree
has uncommitted gameplay changes (see "Uncommitted" below).

## What shipped this session (committed)

|| Commit | What |
|| --- | --- |
|| `08ba56b` | **Playtest Echo pipeline** — `capture.luau` (LogService + state samples + ZRStatus timeline buffer), `echo_to_notes.mjs` (renders issues + Zundarooms status-event table + regression vs previous run), `compare_runs.mjs` (REGRESSED/RESOLVED/RECURRING keyed by script+message, now also indexes zrEvents), `live_run.py` + `client_capture.py` + `studio_mcp.py` + `mcp_call.py`, run archives under `tools/playtest-echo/runs/`. README documents the full run path and the client-context caveat. |

## Working tree — Zundarooms long-term loop (uncommitted, structurally complete on disk)

All files below are linted (selene + stylua) and structurally complete. Nothing
here is staged; `git status` shows them as modified/untracked.

### Config
- `src/shared/ConfigurationFiles/ZundaroomsConfig.lua` (72 lines) — depth 0..8,
  12 authored memories, fragmentsPerRun=2, fragmentEntitySpeedBonus=0.75,
  fragmentGold=25, fragmentXP=10, depth scaling constants.

### Server
- `src/server/Services/ZundaroomsService.lua` (668 lines) —
  CreateFragments / PickupFragment / ClearFragments / merge (into
  zundarooms_memories) / finish (fires escaped memories) / Heartbeat chase /
  start() entrance binding. Pre-populate bug fixed; pickup reads id from Name;
  finish fires escaped memories as third arg.

### Client
- `src/client/ZundaroomsController.client.lua` (42 lines) — listens to
  ZundaroomsStatus, shows banner messages per status.
- `src/client/ZundaroomsMemories.client.lua` (144 lines) — NEW, untracked.
  Client journal: one-shot escaped readout (panel w/ memory text list) + persistent
  "Memories: X / 12" counter in ZundaHUD. Listens for
  ZundaroomsStatus("escaped", memories).

### RemoteEvent
- `src/shared/RemoteEvents/ZundaroomsStatus.model.json` — RemoteEvent, working
  tree adds trailing-comma lint fix (was `{"ClassName": "RemoteEvent"}`).

### Deleted (dead files removed)
- `ZundaroomsFragments.server.lua`, `ZundaroomsLTR.server.lua`,
  `ZundaroomsCollectionHistory.server.lua` — deleted; logic folded into
  ZundaroomsService.lua.

## Current state (verified)

- Echo pipeline files byte-identical to HEAD; `node --check` passes on both .mjs;
  `python3 -m py_compile` passes on .py files.
- 8 run archives under `tools/playtest-echo/runs/` (live-001, live-002,
  verify-ui-actions-20260825, live-serve-20260825-1, ed21981e, a05e0cd1,
  305f2405, client-1787637552).
- `docs/PLAYTEST_NOTES.md`: Issues 3 & 4 ✅ verified live (2026-08-25) with
  evidence path `tools/playtest-echo/runs/verify-ui-actions-20260825.json`.
- `docs/CODE_OWNERSHIP_MAP.md`: file-ownership map, 132 lines, untracked.
- `docs/ZUNDAROOMS_AUTHORING.md`: full long-term design doc, 79 lines, committed.

## Known issues / gotchas (read before touching)

1. **Commit the Zundarooms loop before pushing.** The gameplay changes are
   uncommitted; `git status` shows 33 modified + ~35 untracked files. Stage
   the Zundarooms files in one batch (config + service + controller + memories
   + model.json + deleted-files cleanup) and commit with a clear message.
2. **Client-context caveat for ZRStatus capture.** `ZundaroomsStatus` is a
   server→client RemoteEvent. A capture.luau injection into edit/server context
   installs the OnClientEvent listener but will NOT hear server→client fires —
   `zundarooms_status_events` will be absent/empty. To capture the full status
   timeline (including memories carried on escape), run capture in client-1
   context (`"role": "client-1"`, the pattern `client_capture.py` uses).
3. **The working tree has a wide modified zone beyond Zundarooms** (Damon/LLM
   configs, CookingController, CraftingScript, VN dialogue data, etc.). Do NOT
   mix those into the Zundarooms commit — keep batches isolated by topic.
4. **ZundaroomsStatus.model.json trailing comma** — the working tree version
   has a trailing comma after `"RemoteEvent"`. Either keep it (lint accepts it)
   or revert to the committed clean version before commit.
5. **ZundaroomsMemories.client.lua is untracked** — must be `git add`ed before
   it can be committed.
6. **Client load order is implicit** (000_ prefix-ordering hack) — documented
   smell in CODE_OWNERSHIP_MAP.md.
7. **GitHub origin unreachable (443 timeout)** — nothing pushed; re-check
   connectivity before pushing.

## Next session options (pick one, in priority order)

1. **Commit the Zundarooms loop** as one isolated batch: stage config + service +
   controller + memories + model.json, commit, verify gates (selene, stylua,
   rojo build). Then verify the echo pipeline can capture a full status timeline
   with memories by running a client-1 capture during a playtest.
2. **Run a live Zundarooms playtest** with the echo pipeline in client-1 context
   to capture a real `zundarooms_status_events` trace, render it to
   PLAYTEST_NOTES.md, and confirm the status→memories path end-to-end.
3. **Compare two runs** with `compare_runs.mjs` to classify any status-sequence
   regression (e.g. "escaped with 2 memories" appearing/disappearing across runs).
4. **Triage the wide modified zone** — group the 33 modified + ~35 untracked
   files by topic (Damon, LLM, cooking/VN, Zundarooms) and commit each batch
   separately with clear messages.
5. **Re-audit PLAYTEST_NOTES.md** — institute the "no row without Status" rule
   across all rows; currently Issues 3, 4, 7 have status; re-check rows 1, 2, 5, 6.

## Files most relevant to next-session work

- `src/shared/ConfigurationFiles/ZundaroomsConfig.lua` — tuning + memory set
- `src/server/Services/ZundaroomsService.lua` — full server loop
- `src/client/ZundaroomsMemories.client.lua` — client journal (NEW)
- `src/client/ZundaroomsController.client.lua` — status banner
- `src/shared/RemoteEvents/ZundaroomsStatus.model.json` — RemoteEvent
- `tools/playtest-echo/capture.luau` — echo capture w/ ZRStatus buffer
- `tools/playtest-echo/echo_to_notes.mjs` — notes renderer (ZR section + regression)
- `tools/playtest-echo/compare_runs.mjs` — regression comparator (zrEvents indexed)
- `tools/playtest-echo/README.md` — run docs + client-context caveat
- `docs/PLAYTEST_NOTES.md` — live intake; Issues 3 & 4 verified
- `docs/ZUNDAROOMS_AUTHORING.md` — long-term design doc
- `docs/CODE_OWNERSHIP_MAP.md` — file-ownership map (NEW)

## Expansion Wave: 100-Hour Systems

This expansion pass scales Zundamon's Kitchen V2 into a long-term companion collection, evolution, and live AI experience designed for 100+ hours of retention.

### Damon & Progression Configuration (`src/shared/ConfigurationFiles/`)
- `DamonTypeConfig.lua` (263 lines) — 8-element type system (Pea, Spice, Blossom, Shadow, Celestial, Fermented, Ancient, Ink), 26 companion assignments, and 13 party cooking/gathering synergy mechanics.
- `DamonEvolutionConfig.lua` (253 lines) — 8 companion evolution pairs requiring Bond Tier 3 + perfect signature recipe + rare ingredient, granting +30–50% buff boosts and triggering VN cutscenes.
- `DamonDexConfig.lua` (329 lines) — Pokémon-style registry for companions #001–#026 with 4 W-stats (Warmth, Wit, Wildness, Wisdom), rarity ratings (Common to Mythic), discovery hints, and canon lore.
- `LLMConfig.lua` (67 lines) — Single configuration hub for live LLM companion chat and custom creation; controls feature toggle, local bridge URLs (port 8742), cooldowns, context budgets, and deterministic fallbacks.
- `ZundaLoreConfig.lua` (225 lines) — 21 encyclopedic lore entries grounded in official SSS LLC / VOICEVOX Tohoku Zunko canon across 5 categories with progression unlock hooks.
- `SeasonalEventConfig.lua` (430 lines) — 4 quarterly seasonal events (Spring Blossom Fest, Summer Harvest Rush, Autumn Moon Gathering, Winter Zunda Vigil) with 4 exclusive Mythic damons, seasonal tokens, exclusive recipes, and 7-day quest chains.
- `TournamentConfig.lua` (193 lines) — Weekly PvP cooking tournament system with deterministic scoring formulas, 5 ranking brackets (Zunda Grand Master to Bronze Whisk), weekly UTC reset cycle, and tournament token rewards.
- `DamonTextureConfig.lua` (60 lines) — Auto-generated mapping of companion keys to uploaded Roblox decal `rbxassetid://` URIs with fallback helper methods.
- `CompanionConfig.lua` (643 lines) — Expanded companion catalog to 26 damons (including Tohoku canon cohort: kiritandamon, itakodamon, zunkodamon, zunabunny, nanonadamon) with complete stats, buffs, and LLM personas.
- `VNDialogueData.lua` (1289 lines) — Expanded visual novel dialogue trees for all 26 companions (morning/afternoon/evening/night, bond tiers 1/2/3, quest hints) and evolution awakening scenes.
- `VNPortraitConfig.lua` (106 lines) — Portrait image mappings and bond-tier emote associations for all 26 companions.
- `CraftConfig.lua` (251 lines) — Expanded cooking database containing recipes, cooking times, and difficulty ratings for all 26 companion signature dishes.
- `QuestConfig.lua` (1992 lines, 154 quests) — Added 45+ new quests comprising 15 multi-stage companion unlock quests and 30 grand questline stages across 3 arcs ("The Zunda Origin", "Culinary Ascension", "The Great Tohoku Reunion").
- `ProgressionConfig.lua` (212 lines) — Integrated 5-tier Prestige system (+10% permanent gold multiplier per tier up to +50%) with persistence and reset rules.
- `VoiceConfig.lua` (141 lines) — Auto-generated mapping of character voiceline moments to uploaded VOICEVOX audio asset IDs.

### Tooling, AI & Pipelines (`scripts/`)
- `companion_ai_server.py` (308 lines) — Lightweight Python stdlib HTTP bridge on port 8742 routing Roblox HttpService requests to local Ollama inference (`/companion-chat`, `/generate-companion`, `/health`) with offline fallback.
- `export_companion_personas.py` — Extracts `llmPersona` strings from `CompanionConfig.lua` into `scripts/companion_personas.json` with `--check` CI validation.
- `damon_texture_gen.py` (257 lines) — Pillow-based 512×512 PNG card generator rendering custom silhouettes, glow colors, sparkle palettes, and type badges for all companions.
- `damon_texture_upload.py` — Resumable Open Cloud asset uploader for damon card PNGs with `--check` credential verification and JSON checkpointing.
- `emit_damon_texture_config.py` (108 lines) — Compiles `scripts/damon_textures/manifest.json` into `DamonTextureConfig.lua` with `--check` CI validation.
- `voiceline_manifest.py` (201+ lines) — Master manifest of Japanese voice lines, VOICEVOX styles, and prosody presets for Zundamon and companions.
- `emit_voice_config.py` (105 lines) — Compiles `voiceline_manifest.py` into `VoiceConfig.lua` with `--check` CI validation.
- `check_config_crossrefs.py` (156+ lines) — CI cross-reference auditor enforcing consistency across visual catalogs, node registries, scatter configs, production remotes, and damon textures.

### Documentation (`docs/`)
- `LLM_PIPELINE.md` (241 lines) — Architectural guide, setup instructions, Ollama model recommendations, request schema, and rate-limiting patterns for live AI companion chat.
- `TEXTURE_PIPELINE.md` (159 lines) — Complete workflow guide for generating programmatic damon cards, replacing them with hand-painted 512×512 artwork, and publishing decals via Roblox Open Cloud.
