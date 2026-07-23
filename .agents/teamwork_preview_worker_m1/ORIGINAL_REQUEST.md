## 2026-07-22T21:34:39Z
You are Worker 1 for Milestone 1 of Zundamon's Kitchen V2 - Companion System & Companion Shop Synchronization.

Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Objective:
Implement the Milestone 1 fixes for Companion Catalog & Pricing Configuration across shared configs, server shop handler, and client shop scripts.

Detailed Instructions:

1. `src/shared/ConfigurationFiles/CompanionConfig.lua`:
   - Ensure the 4 free companions are `parrot`, `dog`, `cat`, `ankomon` (plus starter `zundapal`), all having `free = true` and `price = 0`.
   - Ensure the 4 premium companion variants are `cardamon`, `antimon`, `sakuradamon`, `tantanmon`, all having `free = false`, `price = 1000`, `robux = 1000`.

2. `src/shared/ConfigurationFiles/MarketplaceConfig.lua`:
   - Update `products` table and `companionDevProductIds` to map `cardamon` (1111111101), `antimon` (1111111102), `sakuradamon` (1111111103), `tantanmon` (1111111104). Ensure legacy keys (`zundacat`, `zundabunny`) are removed or updated to match canonical companion names.

3. `src/server/CompanionShopServer.server.lua`:
   - Fix `GetOwnedCompanions.OnServerInvoke`:
     - Dynamically populate defaults from `CompanionConfig.companions` where `def.free == true` (which automatically unlocks `zundapal`, `dog`, `parrot`, `cat`, `ankomon`).
     - Do NOT default `tantanmon` to owned (`tantanmon` must be locked until purchased).
     - Merge player's saved `companion_owned_<compType>` flags from `PlayerDataService`.

4. `src/client/StoreScript.client.lua`:
   - Update `FREE_COMPANIONS` list to include `ankomon`, `zundapal`, `dog`, `parrot`, `cat`, and remove `tantanmon` and legacy keys (`zundacat`, `zundabunny`).
   - Fix temporary ScreenGui toast creation (lines 148 & 253) by setting `toast.ResetOnSpawn = false`.

5. `src/client/CompanionShopScript.client.lua`:
   - Update `TAB_ORDER` and category ordering to use canonical companion IDs: free (`zundapal`, `parrot`, `dog`, `cat`, `ankomon`) and premium (`cardamon`, `antimon`, `sakuradamon`, `tantanmon`).

Verification Tasks:
- Run `python scripts/preflight_audit.py` to ensure zero audit errors.
- Document all file modifications and verification results in your report.

Write your report to `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1\changes.md` and `handoff.md`, and send a summary back via send_message.
