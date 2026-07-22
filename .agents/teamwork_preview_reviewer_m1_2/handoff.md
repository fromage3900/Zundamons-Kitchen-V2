# Handoff Report — Milestone 1 Service Wiring & Workspace Rule Audit

**Reviewer Agent**: `teamwork_preview_reviewer_m1_2`  
**Roles**: Reviewer, Critic  
**Date**: 2026-07-22  
**Verdict**: **REJECTED** (REQUEST_CHANGES)

---

## 1. Observation

### 1.1 Service Wiring & Remote Events Audit
1. **`ServingService.lua` BindableEvents & Firing**:
   - `ServingService.lua` (lines 19-20) instantiates two `BindableEvent` objects:
     ```lua
     ServingService.GuestServed = Instance.new("BindableEvent")
     ServingService.GuestTimedOut = Instance.new("BindableEvent")
     ```
   - In `ServingService.serve()` (line 169), `ServingService.GuestServed` is fired:
     ```lua
     ServingService.GuestServed:Fire(player, guestType, quality)
     ```
   - **CRITICAL DEFECT**: `ServingService.GuestTimedOut:Fire(...)` is **NEVER** called anywhere in `ServingService.lua`, `GuestManager.server.lua`, or any other file in the repository.

2. **`EndlessLoopWiring.server.lua` Wiring**:
   - Lines 36-45 connect `ServingService.GuestServed.Event` to `ChallengeModeService.onGuestServed(player, quality, guestType)` and `DailyChallengeService.updateProgress(player, "serve", 1)`.
   - Lines 48-54 connect `ServingService.GuestTimedOut.Event` to `ChallengeModeService.onGuestTimeout(player)`:
     ```lua
     if ServingService and ServingService.GuestTimedOut then
         ServingService.GuestTimedOut.Event:Connect(function(player)
             if ChallengeModeService.isInChallenge(player) then
                 ChallengeModeService.onGuestTimeout(player)
             end
         end)
     end
     ```
   - Because `ServingService.GuestTimedOut` is never fired by `GuestManager` or `ServingService` during a guest timeout, `ChallengeModeService.onGuestTimeout(player)` is never executed when a guest times out.

3. **`ShowVNDialogue` Spelling & Listening**:
   - `ServingService.lua` (line 76), `GuestManager.server.lua` (lines 213, 392), and `VNController.client.lua` (line 634) all use the exact string `"ShowVNDialogue"`.
   - `VNController.client.lua` (lines 633-646) listens via `RE:WaitForChild("ShowVNDialogue", 10)` and routes messages to `_G.ZundaVN.show`.

4. **`OutfitWardrobeGui.client.lua` Remote Event Listeners**:
   - Lines 273-320 register listeners for `ChefStatsUpdate`, `StylePointsUpdate`, and `OutfitUnlock`.

5. **`ServerMain.server.lua` Module Boot Requirements**:
   - Line 9 requires `LootModule`:
     ```lua
     local LootModule = require(ReplicatedStorage.ConfigurationFiles.LootModule)
     ```

### 1.2 Workspace Rules Compliance Audit
1. **Rojo Level Preservation (`$ignoreUnknownInstances: true`)**:
   - `default.project.json` (lines 73-77) correctly specifies `"$ignoreUnknownInstances": true` under `"Workspace"`.
2. **Client UI Decoupling**:
   - No client UI script in `src/client` accesses UI elements via `script.Parent`. All UI elements are built dynamically via `ClientGuiBootstrap.createScreenGui` or located in `PlayerGui`.
3. **Startup Modal Visibility**:
   - Modals and overlay panels across `VNController.client.lua` (lines 52, 64), `OutfitWardrobeGui.client.lua` (line 31), `CompanionShopScript.client.lua` (lines 40, 50), `CompendiumScript.client.lua` (line 84), and `DailyChecklistUI.client.lua` (line 40) explicitly set `panel.Visible = false` / `backdrop.Visible = false` on initialization.
4. **`ResetOnSpawn = false`**:
   - `ClientGuiBootstrap.createScreenGui` (line 16) explicitly enforces `screenGui.ResetOnSpawn = false`.
   - Temporary toast ScreenGuis in `StoreScript.client.lua` (lines 149, 254) explicitly set `toast.ResetOnSpawn = false`.
5. **ServerScriptService Import Path Consistency**:
   - All server modules import services via `ServerScriptService.Services.X` or `ServerScriptService.systems.X`. No files use `.Server.` path segments.

---

## 2. Logic Chain

1. `EndlessLoopWiring.server.lua` attempts to handle guest timeouts in Challenge Mode by listening to `ServingService.GuestTimedOut.Event`.
2. `ServingService.lua` exports `ServingService.GuestTimedOut` as a `BindableEvent`.
3. Guest timeouts are detected and processed inside `GuestManager.server.lua` (`guestTimeoutLoop` -> `removeGuest(guest, "timeout")`).
4. `removeGuest` in `GuestManager.server.lua` destroys the guest instance and fires `ShowVNDialogue` for the timeout text, but does **not** call `ServingService.GuestTimedOut:Fire(player)` (or `GuestService` equivalent).
5. As a direct consequence, the `BindableEvent` signal is never emitted, causing `ChallengeModeService.onGuestTimeout(player)` to remain unreachable during gameplay.
6. In Challenge Mode, guest timeouts fail to break player combos or trigger the `"guest_timeout"` status payload to the client. This represents a missing signal emitter / broken service event wiring.

---

## 3. Caveats

- All workspace layout, UI decoupling, and import path rules fully pass.
- All remote event name spellings (`ShowVNDialogue`, `ChefStatsUpdate`, `StylePointsUpdate`, `OutfitUnlock`) match perfectly between client and server.
- The single functional blocker for Milestone 1 is the un-emitted `ServingService.GuestTimedOut` BindableEvent during guest timeouts.

---

## 4. Conclusion

**Verdict**: **REJECTED** (REQUEST_CHANGES)

While Workspace Rules adherence is 100% compliant, the service event wiring contains a critical flaw: `ServingService.GuestTimedOut` is instantiated and connected to `ChallengeModeService`, but is **never fired** when guest timeouts occur in `GuestManager.server.lua`. 

### Required Remediation:
1. Fire `ServingService.GuestTimedOut:Fire(servingPlayer)` inside `removeGuest(guest, "timeout")` in `GuestManager.server.lua` (or export a method on `ServingService`/`GuestService` to handle timeout notifications).

---

## 5. Verification Method

1. **Inspect Event Definitions and Calls**:
   - Run grep for `GuestTimedOut`:
     `grep_search` query `GuestTimedOut` in `src/`
   - Confirm `GuestTimedOut:Fire(...)` is called when `removeGuest(guest, "timeout")` executes in `GuestManager.server.lua`.
2. **Run Linter**:
   - Execute `selene src` in PowerShell to ensure syntax and lint cleanliness.
