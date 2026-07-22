## 2026-07-22T17:56:02Z
<USER_REQUEST>
You are the Forensic Auditor for Milestone 2 (Real-Time Game Telemetry & Web Hub Integration).
Your working directory is `.agents/teamwork_preview_auditor_m2`.

### Task:
Perform independent forensic integrity verification on Milestone 2 work products:
1. Check for integrity violations: hardcoded fake test results, dummy/facade implementations, cheated outputs, or bypasses.
2. Audit `src/server/Services/WebInfoSyncService.lua`, `src/server/Services/PromoCodeService.lua`, `site/api/game_info.json`, `docs/api/game_info.json`, `site/presskit.html`, `site/index.html`, `site/app.js`, `site/style.css`, `site/sync_site.js`.
3. Verify genuine implementation of `exportGameStateJson()`, `PromoCodeService`, `TelemetryService`, static fallback handling, and site sync.
4. Run `python scripts/preflight_audit.py` and verify genuine passing status.
5. Write your forensic audit report in `.agents/teamwork_preview_auditor_m2/handoff.md` with explicit verdict: CLEAN or INTEGRITY VIOLATION.
</USER_REQUEST>
