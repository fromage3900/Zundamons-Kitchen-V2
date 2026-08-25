# Roblox Studio & Rojo 7.7.0 Workspace Rules

### 1. Rojo Level Preservation ($ignoreUnknownInstances)
- When configuring `default.project.json`, ALWAYS include `"$ignoreUnknownInstances": true` under `"Workspace"`.
- This prevents Rojo from wiping out terrain, meshes, models, and 3D level geometry placed manually inside Roblox Studio during code synchronizations.

### 2. Client UI Decoupling & Visibility
- Never use `script.Parent` for UI references in client scripts synced to `StarterPlayerScripts`.
- All client UI scripts must dynamically construct or locate their interface in `PlayerGui` via `ClientGuiBootstrap`.
- Explicitly set `gui.ResetOnSpawn = false` on top-level `ScreenGui` instances to survive player respawns.
- Explicitly set `panel.Visible = false` on startup for modal/dialogue panels (e.g. `VNController`) to avoid UI overlaps on game start.

### 3. Wally Package Structure & Dependencies
- Server-only modules (such as `ProfileService`) must be declared under `[server-dependencies]` in `wally.toml`.
- `default.project.json` must map `"Packages": { "$path": "Packages" }` in `ReplicatedStorage` and `"ServerPackages": { "$path": "ServerPackages" }` in `ServerScriptService`.
- `.gitignore` must ignore `Packages/`, `ServerPackages/`, `wally.exe`, and `wally.zip`.

### 4. ServerScriptService Path Consistency
- When `src/server` is mapped directly to `ServerScriptService` in `default.project.json`, imports must use `ServerScriptService.Services.X` or `ServerScriptService.systems.X`. Never prepend an extra `.Server.` path segment.

### 5. MCP (Model Context Protocol) — Roblox Studio Integration
- Use **chrxxs/robloxstudio-mcp** (`@chrrxs/robloxstudio-mcp@latest`) as the Studio MCP server — 78 tools, actively maintained, MIT.
- `opencode.json` config: `{"command": ["cmd", "/c", "npx", "-y", "@chrrxs/robloxstudio-mcp@latest", "--auto-install-plugin"]}`
- Tool names follow the pattern `roblox-studio_<tool_name>` (e.g. `roblox-studio_execute_luau`, `roblox-studio_get_instance`, `roblox-studio_solo_playtest`).
- Ensure no other MCP server (e.g. paralov/roblox-studio-opencode-mcp on port 28821) is running — they conflict. Kill stale processes with `Stop-Process -Id <PID> -Force`.
- Use `get_connected_instances` to verify Studio is linked before calling other tools.
- Fallback: Roblox built-in MCP at `%LOCALAPPDATA%\Roblox\mcp.bat` (no plugin needed, limited tools).

### 6. Endless Gameplay Loop Systems
- **ChallengeModeService** (`src/server/Services/ChallengeModeService.lua`): Endless wave-based challenge mode inspired by Uma Musume's racing meets. Players face increasingly difficult guest waves, earning score and rewards. Tiers: Bronze → Silver → Gold → Platinum → Zunda.
- **DailyChallengeService** (`src/server/Services/DailyChallengeService.lua`): 3 rotating daily challenges + weekly boss challenge + streak rewards. Inspired by Uma Musume's daily races.
- **DailyChallengeConfig** (`src/shared/ConfigurationFiles/DailyChallengeConfig.lua`): Config for daily challenge pool, weekly boss, streak rewards, daily visitor (Nikki the Drifter), and daily resources.
- **ChefStatsConfig** (`src/shared/ConfigurationFiles/ChefStatsConfig.lua`): Chef stat system inspired by Infinity Nikki's style stats. Stats: Speed, Precision, Charisma, Stamina with diminishing returns. Style points system with outfit unlocks.
- **EndlessLoopWiring** (`src/server/systems/EndlessLoopWiring.server.lua`, lowercase `systems/`): Wires together all new systems, connecting them to existing GuestManager, CookingService, and ServingSystem. Daily-challenge player join init is owned by **DailyChallengeService.PlayerAdded alone** — never duplicate it (double-grant window). **Do not re-add the dead `IngredientGathered`/`GoldEarned` listener**; those remotes do not exist.
- RemoteEvents required: `ChallengeMode`, `ChallengeModeStatus`, `DailyChallenge`, `DailyChallengeStatus`, `DailyPreviewData`, `ChefStatsUpdate`, `StylePointsUpdate`, `OutfitUnlock`, `CollectionSnapshot`. RemoteFunctions: `GetCollectionSnapshot`.
- Server wiring is functional; the **client surface (challenge/daily UI) is not built yet** — status remotes fire into the void by design until Phase 4 UI.

### 7. Infinity Nikki Aesthetic
- UI colors: pastel palette (RGB(160, 210, 150) for Zunda green, RGB(255, 200, 80) for gold, RGB(255, 150, 200) for pink, RGB(145, 215, 195) for mint).
- Dialogue style: Zundamon speaks in ALL CAPS with exclamation marks, pea-themed metaphors, and frequent emojis (🫛🍡✨🔥🌸).
- Style points system: Earned from perfect cooks, stylish serving, companion coordination. Unlocks fashion items and outfit variants.
- Guest types: `magical_girl`, `fashionista`, `stylist`, `challenge_fighter` — all with Infinity Nikki themed dialogue.
- Quest naming: Dramatic and thematic (e.g., "Culinary Ascension", "The Great Zunda Hunt", "Friend of All").

### 8. Ollama Content Workers
- **ollama_client.py** (`scripts/ollama_client.py`): Reusable Ollama API client with Zundamon persona template, Lua formatter, and JSON extraction.
- **ollama_recipe_worker.py** (`scripts/ollama_recipe_worker.py`): Generates new cooking recipes in Lua format for CraftConfig.lua.
- **ollama_quest_worker.py** (`scripts/ollama_quest_worker.py`): Generates new quest entries in Lua format for QuestConfig.lua.
- **ollama_dialogue_worker.py** (`scripts/ollama_dialogue_worker.py`): Generates new companion/NPC dialogue in Lua format for VNDialogueData.lua.
- Usage: `python scripts/ollama_recipe_worker.py --count 8 --model deepseek-coder:6.7b`
- Output directory: `scripts/ollama_output/`
- Requires Ollama server running (`ollama serve`).

### 9. New Quest Types
- `challenge_wave`: Complete Challenge Mode waves
- `style_points`: Earn style points from cooking
- `outfit_collect`: Unlock companion fashion items
- `reputation_tier`: Achieve guest reputation tiers
- `cook_speed`: Cook dishes under time limits
- `cook_quality`: Achieve quality thresholds (great, perfect)
- `gather_unique`: Gather unique ingredient types
- `visit_zones_unique`: Visit unique locations
- `npc_chat_all`: Chat with all NPCs

### 10. Skybox — Kenney CC0 Cubemaps (Dynamic 3‑Set Swap)
- `SkyConfig.lua`: default set = Kenney Day (lines 33–45, edited)
- `DayNightSky.server.lua`: 3 `SKYBOX_SETS` (day/night/morning) at lines 78–119
  - Dawn 4.5–7.5 → morning, day 7.5–17 → day, dusk 17–19.5 → morning, night else → night
- Uploaded 18 face decals (1024×1024 RGBA, all approved)
- Sun icon: 123736711329002, Moon icon: 85079237605725

### 11. New Guest Types (Infinity Nikki Aesthetic)
- `magical_girl`: "By the power of sparkling cuisine! I need {recipe}! ✨💖"
- `fashionista`: "Darling, I require {recipe} — it MUST be Instagram-worthy! 📸💄"
- `stylist`: "I need {recipe} to complete my look today! 💇‍♀️🎨"
- `challenge_fighter`: "I've trained for this moment! Give me {recipe}! 💪🔥"

### 12. CI/CD & Quality Gates (Longterm Scaffolding)
- **Toolchain parity is mandatory**: aftman.toml, rokit.toml, and mise.toml must pin the SAME versions (StyLua 2.5.2, Selene 0.27.1, Rojo 7.7.0, Wally 0.3.2, Blink 0.18.8). Drift between local and CI formatting/lint output breaks the gate — never bump one file alone.
- **Gates** (all three must pass before commit; CI runs them on every push/PR):
  1. `stylua --check src` (formatting, tabs/120col)
  2. `selene --allow-warnings src` (errors block; warnings reported)
  3. `rojo build default.project.json` (project must always build)
- **Pre-commit hook** (`.githooks/pre-commit`, install via `npm run hooks:install`): gates only staged `.lua` files.
- **Rojo sync via GitHub**: CI uploads `ZundamonsKitchen.rbxl` + `sourcemap.json` as the `rojo-build` artifact (90 days); tagging `vX.Y.Z` publishes a GitHub Release with the same artifacts (workflows: `.github/workflows/ci.yml`, `.github/workflows/release.yml`).
- **Selene policy**: keep `incorrect_standard_library_use` at default severity; valid newer-API false positives are annotated with `-- selene: allow(incorrect_standard_library_use)` on the exact line (e.g. `os.getenv`, `AudioReceiver`). Do NOT relax the rule project-wide — it catches real bugs (it flagged a nonexistent `Enum.Material.DeepWater`).
- **Never** bypass gates with `--no-verify`, and never commit `print()` debug statements intended for scratch debugging (PR template enforces this).

### 13. Shared Asset Hub & Material Pipeline
- **ReplicatedStorage is the runtime shared hub** (see `docs/SHARED_ASSET_HUB.md`): ConfigurationFiles, Shared/, components, Models/Meshes, remotes, AssetRegistry — clients read from it; state writes go client → remote → server adapter.
- **MaterialService is the material hub**: persistent `MaterialVariant`s live there (place-owned, survive Rojo via `$ignoreUnknownInstances`); canonical values live in git at `src/Plugins/ZundaPalette.lua`. Edit the module, re-run the plugin's Register, never hand-edit the place.
- **ZundaMaterialAuthoring plugin** (`src/Plugins/ZundaMaterialAuthoring.plugin.lua`, build `src/Plugins/material-plugin.project.json`): palette browser → apply MaterialVariant/direct paint → suggested attributes → Export Config snippets into Rojo-owned modules.
- **Live playtest intake**: append findings to `docs/PLAYTEST_NOTES.md` (raw log at bottom; issues table on top). Stability fixes quote the entry they resolve.

### 14. Server Stability Guards (do not regress)
- **Matter loop runs systems wrapped in `pcall`** (`src/server/ServerMain.server.lua`): a system error must never kill the heartbeat.
- **No `task.wait` inside event handlers**: use `task.delay`/Debris (Mineable respawn is the reference fix).
- **Guest attributes are client-mutable** (they replicate): `ServingService` clamps `PayAmount` ≤ 500 and `BonusGold` ≤ 200 at serve; guest cap is **per player** in GuestManager.
- **Style/chef-stat writes go through `PlayerDataService.mutate`** (`EndlessLoopWiring.syncPlayerWardrobe`); direct `data.x +=` writes bypass revision + projection — route new writes through mutate.
- **Challenge mode scoring**: cooking (`onCookComplete`) never increments guests served (`onGuestServed`); style points are granted once via `syncPlayerWardrobe`, never inside ChallengeModeService.

### 15. Branch State & Repo Hygiene
- **`main` is the only active branch** (2026-08-12): it is the production baseline and all pushes run CI gates. `codex/*` branches are archived history — never branch from them, never advertise them in docs as live.
- **One concern per commit**: group by feature area (e.g. `feat(server):`, `assets:`, `chore:`); do not sweep unrelated files (e.g. stray root scratch, temp PNGs, one-off scripts) into feature commits.
- **Never `git add -A` in a mixed workspace** — owner source assets (`crucialassets/`, root `*.fbx`/`*.blend`) and generated builds can be staged by accident. Stage explicit paths per commit.
- **Configs cross-reference each other** (`scripts/check_config_crossrefs.py` runs in CI): ScatterConfig variants must exist in `ResourceVisualCatalog`, Mineable/click ids in `ResourceNodeRegistry`, and AGENTS-listed remotes must be declared. Keep them in sync or CI fails.
- **Owner source assets live in `crucialassets/`** (tracked, never stage casually); everything new of that kind goes there too, not at the repo root.

### 16. Single Authoritative Clone + Rojo Process Discipline
- **EXACTLY ONE authoritative clone drives Rojo/Studio** — currently `G:\Zundamons-kItchen-V2`, kept in sync with `origin/main`. Every `rojo serve` must run from that copy. Syncing Studio from an older/orphaned second clone overwrites the game with stale scripts and looks exactly like "everything broke" — that is a repo/process failure, NOT a code bug, so do not chase a phantom regression before ruling it out.
- **`main` is the only branch ever served.** Before serving, run `git fetch origin` and confirm `git status -sb` shows `## main...origin/main` with no ahead/behind, and a clean tree. Never serve a branch that has diverged or is behind.
- **Exactly one `rojo serve` at a time.** The `pre-push` hook catches stale pushes, but always run `scripts/rojo-health.ps1` to verify no duplicate serves before starting a session.
- **Never reflexively `git reset --hard` on a "stale/diverged" claim.** Confirm the local tree is genuinely behind and that no unique local work exists (compare `git log` against `origin/main`) before any hard reset.
- **Electra/session handoff:** if another collaborator acts as its own "the project," reconcile to ONE clone before serving.

### 17. VSCode & Git Pipeline (team-shared, new collaborators inherit on clone)
- **VSCode is the recommended editor** and ships team-shared config in-repo: `.vscode/extensions.json` (Luau LSP, StyLua, Selene, EditorConfig), `.vscode/settings.json` (StyLua format-on-save, Luau LSP auto-sourcemap), `.vscode/tasks.json` (build/serve/check/format), plus a root `.editorconfig` mirroring `stylua.toml`.
- **Luau LSP** (`JohnnyMorganz.luau-lsp`) auto-generates `sourcemap.json` from `default.project.json` for Roblox intellisense — no separate watcher needed.
- **Git hooks** (install: `npm run hooks:install`; uninstall: `npm run hooks:uninstall`):
  1. `.githooks/pre-commit` — StyLua + Selene on staged `.lua` only (fast).
  2. `.githooks/commit-msg` — enforces Conventional Commits format.
  3. `.githooks/pre-push` — runs full `npm run check` **and** warns if local main is behind origin.
- **Never** commit with `--no-verify` outside genuine emergencies.

### 18. Zundamon Voice (VO) Pipeline — VOICEVOX
- **Four stages, in order.** Each is a script in `scripts/`; none of them is hand-edited output:
  1. `voiceline_manifest.py` — **the line script** (the only file you author). Moment → Japanese text → VOICEVOX style → prosody.
  2. `voicevox_voiceline_worker.py` — renders every line to WAV (lossless master) **and** derives an MP3. Writes `voicevox_output/manifest.json`.
  3. `upload_audio.py` — uploads the MP3s via Open Cloud, writes `asset_id` back into the manifest. Resumable and checkpointed per clip.
  4. `emit_voice_config.py` — generates `src/shared/ConfigurationFiles/VoiceConfig.lua` from the manifest.
- **`VoiceConfig.lua` is GENERATED — never hand-edit it.** Change the manifest and re-run stages 2–4. `emit_voice_config.py --check` fails if the file is stale (CI-ready).
- **Roblox rejects WAV.** Audio uploads must be MP3/OGG; the worker derives MP3 via ffmpeg for exactly this reason. Uploaded audio also passes through moderation and may not play immediately.
- **Japanese VO over English UI is deliberate**: VOICEVOX synthesizes Japanese only and Zundamon is canonically Japanese-voiced. Do not "fix" this by dropping the VO.
- **Voice is a single channel with barge-in** (`ZundaSoundController.playVoice`): a new line stops the previous one. Overlapping character voice is the fastest way to make VO feel broken.
- **Every moment is cooldown-throttled** in `VoiceConfig.Cooldowns`. High-frequency moments (serve, cook) get long cooldowns; ceremonial ones (level_up, tier_up) get 0. When adding a call site, pick the cooldown deliberately — VO spam is the main failure mode.
- **Keep gameplay lines under ~2.5s.** The worker warns above that. Ceremonial and ambient/ASMR lines may exceed it; rhythm-minigame lines must not, or they talk over the next note.
- **Voice loads defensively**: `ZundaSoundController` requires `VoiceConfig` in a `pcall`, so a missing or malformed generated file degrades voice to silent instead of killing all UI SFX.
- **Attribution is mandatory** (`CREDITS.md`): VOICEVOX:ずんだもん; character rights SSS LLC.
- Generation needs the local engine — `python scripts/voicevox_client.py --serve` (auto-started by the worker). Upload needs `ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_CREATOR_USER_ID`; `upload_audio.py --check` diagnoses a bad key.
