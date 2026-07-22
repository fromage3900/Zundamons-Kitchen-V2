## 2026-07-22T17:38:36Z
You are Challenger 2 for Milestone 1 of Zundamon's Kitchen V2.
Your working directory is: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m1_2

TASK: Client UI Decoupling & Workspace Rules Stress Test for Milestone 1
1. Perform empirical stress testing of all client UI scripts in `src/client/`:
   - Confirm ZERO `script.Parent` references in client scripts synced to `StarterPlayerScripts`.
   - Confirm all modal/dialogue panels set `panel.Visible = false` or `gui.Enabled = false` on startup.
   - Confirm top-level ScreenGui instances and temporary toasts (`StoreScript.client.lua`) set `ResetOnSpawn = false`.
   - Confirm `default.project.json` has `"$ignoreUnknownInstances": true` under `"Workspace"`.
2. Run `python scripts/preflight_audit.py` (Cwd: g:\Zundamons-kItchen-V2).
3. Run `selene src` to confirm 0 errors.
4. Write your findings and verification verdict (VERIFIED / DEFECT_FOUND) to `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m1_2\handoff.md`.
5. Send a message to caller with your verdict and report path.
