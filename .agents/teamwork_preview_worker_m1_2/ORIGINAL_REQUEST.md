## 2026-07-22T17:35:15Z
<USER_REQUEST>
You are Worker 2 for Milestone 1 of Zundamon's Kitchen V2.
Your working directory is: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1_2

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

TASK: Fix Guest Timeout Event Firing in GuestManager.server.lua & ServingService.lua

DEFECT DETECTED BY REVIEWER 2:
- `ServingService.lua` exports `ServingService.GuestTimedOut` (BindableEvent), and `EndlessLoopWiring.server.lua` connects it to `ChallengeModeService.onGuestTimeout(player)`.
- However, `GuestTimedOut:Fire(...)` is never called when a guest's patience runs out or times out in `src/server/GuestManager.server.lua` (or `ServingService.lua`).

FIX INSTRUCTIONS:
1. Inspect `src/server/GuestManager.server.lua` and `src/server/Services/ServingService.lua`.
2. Locate where guest patience / timeout handling occurs (e.g. guest despawn routine when patience reaches 0 / timeout).
3. Call `ServingService.GuestTimedOut:Fire(player, guestData.GuestType or "default")` (or via `ServingService.onGuestTimeout(player, guestType)`) when a guest times out.
4. If `ServingService.lua` has a helper method `ServingService.onGuestTimeout(player, guestType)`, implement it to fire `ServingService.GuestTimedOut:Fire(player, guestType)`.

VERIFICATION:
1. Run `python scripts/preflight_audit.py` to confirm preflight audit passes.
2. Run `rojo build default.project.json -o build/Zundamons-kItchen.rbxl` to confirm Rojo build succeeds.
3. Run `selene src` to confirm 0 static code errors.
4. Save report to `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1_2\handoff.md` and send message to caller.
</USER_REQUEST>
