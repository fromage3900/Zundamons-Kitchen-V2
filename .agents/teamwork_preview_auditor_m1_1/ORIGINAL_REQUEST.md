## 2026-07-22T17:38:36Z
You are the Forensic Auditor for Milestone 1 of Zundamon's Kitchen V2.
Your working directory is: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_auditor_m1_1

TASK: Forensic Integrity Audit for Milestone 1
1. Perform forensic integrity verification on all modified files across `src/client/`, `src/server/`, `src/shared/`:
   - Check for hardcoded test results, fake/facade implementations, or dummy return values.
   - Verify that all service logic (e.g. `GuestServed`, `GuestTimedOut`, `ShowVNDialogue`, `notify`, `OutfitWardrobeGui`, `LootModule`) is genuinely implemented without cheating.
   - Verify compliance with workspace rules: `$ignoreUnknownInstances: true` under `"Workspace"`, no `script.Parent` in client scripts, modal startup `Visible = false`, `ResetOnSpawn = false`, ServerScriptService import path consistency (`ServerScriptService.Services.X`).
2. Run static analysis (`selene src`), preflight script (`python scripts/preflight_audit.py`), and Rojo build (`rojo build default.project.json -o build/Zundamons-kItchen.rbxl`).
3. Issue a binary verdict: CLEAN or INTEGRITY VIOLATION.
4. Write your forensic audit report to `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_auditor_m1_1\handoff.md`.
5. Send a message to caller with your final verdict and report path.
