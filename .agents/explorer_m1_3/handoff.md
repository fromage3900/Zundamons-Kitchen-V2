# Handoff Report: UI Decoupling, ResetOnSpawn & Startup Visibility Analysis for Pea Wheel System

**Agent**: Explorer 3 (Milestone 1 — UI System Overhaul)  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m1_3\`  
**Target Module**: Pea Wheel Radial Menu & Startup GUI Bootstrap  

---

## 1. Observation

Direct observations from inspection of codebase files:

1. **`src/shared/ConfigurationFiles/ClientGuiBootstrap.lua` (lines 14-17)**:
   ```lua
   local screenGui = Instance.new("ScreenGui")
   screenGui.Name = name
   screenGui.ResetOnSpawn = false
   screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   ```
2. **`src/client/Controllers/PeaWheelController.lua` (lines 64-65)**:
   ```lua
   wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
   wheelGui.ResetOnSpawn = false
   ```
3. **`src/client/Controllers/PeaWheelController.lua` (lines 73, 83, 143, 331)**:
   ```lua
   73: backdropFrame.Visible = false
   ...
   83: wheelFrame.Visible = false
   ...
   143: tooltipLabel.Visible = false
   ...
   331: buildWheelGui()
   ```
4. **`src/client/000_LegacyOverlayCleanup.client.lua` (lines 131-152, 164-170)**:
   ```lua
   131: local function cleanupScreenGui(gui: ScreenGui)
   132: 	if destroyOverlayGui(gui) then return end
   133: 	if destroyLegacyStarterShell(gui) then return end
   134: 	for _, inst in ipairs(gui:GetDescendants()) do
   135: 		if isStudioGreyFullscreen(inst) then inst:Destroy() ... end
   136: 	end
   137: end
   ...
   164: playerGui.ChildAdded:Connect(function(child)
   165: 	task.defer(function() if child:IsA("ScreenGui") then cleanupScreenGui(child) end end)
   166: end)
   ```
5. **`src/shared/ConfigurationFiles/LegacyGuiConfig.lua` (lines 8-29)**:
   - `destroyScreenGuis`: `{"ZundaFX", "PostProcessOverlay"}`
   - `destroyLegacyStarterShells`: `{"ZundaVN", "ZundaPouch", "QuestPanel", "CompanionShop", "ZundaShop"}`
   - `PeaWheelGui` is NOT listed in either destruction table.
6. **`src/client/PeaWheelStarter.client.lua` (lines 6, 8)**:
   - Line 6 comment: `-- The PeaWheelController builds its GUI lazily on first open/toggle.`
   - Line 8 print: `print("[PeaWheelStarter] PeaWheelController loaded — wheel ready on Tab/G key")` (Note: `PeaWheelController.lua` line 285 listens to `Tab` and `Q` keys).

---

## 2. Logic Chain

1. **`ResetOnSpawn = false` Rule Verification**:
   - Observation 1 demonstrates `ClientGuiBootstrap.createScreenGui` explicitly sets `ResetOnSpawn = false` on every created `ScreenGui`.
   - Observation 2 demonstrates `PeaWheelController.lua` (line 65) reinforces `wheelGui.ResetOnSpawn = false`.
   - Therefore, `PeaWheelGui` will persist under `PlayerGui` when a player character respawns, preserving internal controller reference variables (`wheelGui`, `wheelFrame`, `backdropFrame`, `sliceButtons`) and avoiding null reference crashes or lost bindings.

2. **Startup Visibility Control Verification**:
   - Observation 3 shows `buildWheelGui()` runs at module load (line 331).
   - In `buildWheelGui()`, `backdropFrame.Visible` (line 73), `wheelFrame.Visible` (line 83), and `tooltipLabel.Visible` (line 143) are all set to `false`.
   - Controller state variable `isOpen` defaults to `false` (line 28).
   - `HubButton` (quick launcher button at bottom-right) remains `Visible = true` by default as an intentional launcher button.
   - Therefore, the radial wheel overlay and dimming backdrop are completely invisible on game start, preventing UI overlap or input blocking until explicitly opened by keypress (`Tab`/`Q`) or `HubButton` click.

3. **Decoupling & Cleanup Interaction Verification**:
   - Observation 1 & 2 show `PeaWheelController.lua` constructs UI dynamically in `PlayerGui` via `ClientGuiBootstrap`, complying with decoupling rule #2 (no `script.Parent` usage).
   - Observation 4 & 5 show `000_LegacyOverlayCleanup.client.lua` intercepts `PeaWheelGui` creation via `PlayerGui.ChildAdded`. `PeaWheelGui` is checked against `LegacyGuiConfig.destroyScreenGuis` and `destroyLegacyStarterShells` (where it is absent), and its descendants are scanned for legacy vignettes / grey frames (none present).
   - Therefore, `PeaWheelGui` survives startup overlay cleanup intact without race conditions or unexpected deletion.

---

## 3. Caveats

- **Scope boundary**: This analysis focused strictly on `PeaWheelController.lua`, `ClientGuiBootstrap.lua`, and `000_LegacyOverlayCleanup.client.lua`. Slice position centering math (`UDim2.fromScale(0.5, 0.5)` / `AnchorPoint = (0.5, 0.5)`) and keybind deduplication are analyzed in detail by Explorer 1 (`explorer_m1_1`) and Explorer 2 (`explorer_m1_2`).
- **Assumption**: No runtime scripts outside `000_LegacyOverlayCleanup.client.lua` manipulate `PlayerGui` child instances directly during startup.
- **Alternative Interpretation**: While `PeaWheelStarter.client.lua` line 6 claims lazy loading, `PeaWheelController.lua` actually eagerly constructs `PeaWheelGui` on module load (line 331). This eager construction is safe because startup visibility is set to `false`.

---

## 4. Conclusion

- **`ResetOnSpawn = false`**: **PASS**. Fully compliant in both `ClientGuiBootstrap` and `PeaWheelController.lua`.
- **Startup Panel Visibility (`Visible = false`)**: **PASS**. `wheelFrame`, `backdropFrame`, and `tooltipLabel` are initialized with `Visible = false`.
- **Decoupled UI & Startup Cleanup Interaction**: **PASS**. Dynamically created via `ClientGuiBootstrap`, passes `000_LegacyOverlayCleanup.client.lua` without interference.
- **Minor Cleanups Recommended**:
  1. Update `PeaWheelStarter.client.lua` line 8 print string from `Tab/G key` to `Tab/Q key`.
  2. Update `PeaWheelStarter.client.lua` line 6 comment to accurately describe eager initialization with `Visible = false` startup panels.

---

## 5. Verification Method

1. **File Inspection**:
   - Inspect `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua` line 16 for `screenGui.ResetOnSpawn = false`.
   - Inspect `src/client/Controllers/PeaWheelController.lua` line 65 (`wheelGui.ResetOnSpawn = false`), line 73 (`backdropFrame.Visible = false`), and line 83 (`wheelFrame.Visible = false`).
   - Inspect `src/client/000_LegacyOverlayCleanup.client.lua` lines 131-152 for single-pass descendant cleanup logic.

2. **Preflight Audit Command**:
   - Run `python scripts/preflight_audit.py` from project root directory to confirm 0 static rule violations.

3. **Invalidation Conditions**:
   - Analysis is invalidated if any new script modifies `PeaWheelGui.ResetOnSpawn` to `true`, or removes `Visible = false` initialization on `wheelFrame` or `backdropFrame`.
