## 2026-07-22T13:56:40Z
<USER_REQUEST>
You are Worker 6 (Milestone 2 Audio Engine Remediation Worker).
Your metadata working directory is `.agents/teamwork_preview_worker_m2_fix`.

### Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

### Objective:
Fix the BGM rapid toggle oscillator race condition in `site/assets/audio_engine.js`:
1. In `startCozyBGM()` (in `site/assets/audio_engine.js`), when clearing `ZundaAudio.bgmStopTimeout`, also iterate over any existing `ZundaAudio.bgmPadOscs` and `ZundaAudio.bgmMelodyOscs` and call `osc.stop()` (inside a try-catch block) before clearing or overwriting the arrays.
2. Ensure `stopCozyBGM()` and `startCozyBGM()` maintain zero unstopped oscillator leaks under rapid toggle conditions.
3. Run `node g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m2_2\verify.js` to verify all 4 tests pass (100% pass, 0 failures).
4. Run `node site/sync_site.js` to synchronize `site/` -> `docs/`.
5. Run `python scripts/preflight_audit.py` to confirm 0 errors.
6. Write your handoff report in `.agents/teamwork_preview_worker_m2_fix/handoff.md`.
</USER_REQUEST>
