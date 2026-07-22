## 2026-07-22T17:55:23Z
You are Worker 5 (Milestone 2 Telemetry & Web Hub Implementer).
Your metadata working directory is `.agents/teamwork_preview_worker_m2_1`.

### Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

### Objectives:
1. Update `src/server/Services/PromoCodeService.lua`:
   - Register `HYBRIDECS` code: `{ gold = 2000, gems = 200, item = "5x Whim Gacha Tickets" }` in `PromoCodeService.activeCodes`.

2. Update `src/server/Services/WebInfoSyncService.lua`:
   - Fix runtime bug indexing `DailyChallengeConfig.challenges` (it should use `DailyChallengeConfig.dailyPool` and `DailyChallengeConfig.weeklyBoss`).
   - Implement complete, schema-compliant `exportGameStateJson()` returning valid JSON string matching the structure:
     - `last_updated`: UTC timestamp (e.g., `os.date("!%Y-%m-%dT%H:%M:%SZ")`)
     - `online_players`: `{ count = activeCount, status = "online", version = "2.4.0 HYBRID ECS" }` (where `activeCount` falls back to baseline `125` if `#Players:GetPlayers() == 0`).
     - `active_challenges`: `{ daily = [...], weekly = [...] }` (mapped from `DailyChallengeConfig.dailyPool` and `weeklyBoss`).
     - `gacha_banners`: array of banners from `GachaConfig.banners` with `rates` (`legendary`: "5%", `epic`: "20%", `rare`: "75%").
     - `promo_codes`: array of active codes from `PromoCodeService.activeCodes` or fallback list including `ZUNDAMOCHI2026`, `SOUPSEASON`, `KAWAIIZUNDA`, `NIKKIFASHION`, and `HYBRIDECS` with reward summaries.
     - `global_stats`: `{ total_dishes_cooked = 142850, edamame_harvested = 89420, total_gacha_pulls = 38920, active_event = { name = "🌸 Whims of Gourmet - Spring Festival", active = true, multiplier = "2.0x Style Points & Gold" } }`.

3. Create `site/api/game_info.json` and update `docs/api/game_info.json`:
   - Provide clean, formatted, valid telemetry JSON adhering to the schema above.

4. Create `site/presskit.html`:
   - Create `site/presskit.html` mirroring `docs/presskit.html` (or with updated dynamic ticker script and telemetry bindings) so it stays in sync.

5. Update `site/index.html`, `site/app.js`, and `site/style.css`:
   - In `site/app.js`, implement `TelemetryService` fetching `api/game_info.json`.
   - Provide `STATIC_GAME_INFO_FALLBACK` object so if fetch fails or runs under `file://` protocol, telemetry renders seamlessly without console errors.
   - Dynamic rendering: status pill text (`LIVE ON ROBLOX · v2.4.0 HYBRID ECS (125 CHEFS ONLINE)`), live ticker banner (`hero-live-ticker`), active daily challenges list, dynamic promo codes copy buttons, and community dishes cooked progress bar.
   - Add styles in `site/style.css` for ticker banner and telemetry cards if needed.

6. Synchronize and Verify:
   - Run `node site/sync_site.js` to mirror `site/` to `docs/`.
   - Run `python scripts/preflight_audit.py` to ensure 0 errors.

7. Write `handoff.md` in `.agents/teamwork_preview_worker_m2_1/handoff.md` detailing:
   - Modifications made per file.
   - Command outputs for `sync_site.js` and `preflight_audit.py`.
   - Verification status.
