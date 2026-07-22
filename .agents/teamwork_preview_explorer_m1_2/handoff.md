# Handoff Report: Client UI Decoupling & Modal Visibility Audit

## 1. Observation

### System Mapping & Scope
- **File**: `default.project.json`
- **Lines 67-72**:
  ```json
  "StarterPlayer": {
    "$className": "StarterPlayer",
    "StarterPlayerScripts": {
      "$path": "src/client"
    }
  }
  ```
  *Observation*: `src/client` is mapped directly to `StarterPlayer.StarterPlayerScripts` in Rojo, meaning all 61 Lua files in `src/client/` run inside `StarterPlayerScripts`.

### Audit Criterion 2a: `script.Parent` for UI References
- *Command*: Executed AST / pattern search across all 61 Lua files in `src/client`.
- *Result*: Only 5 files contain `script.Parent`, and **all 5 instances are strictly for module requiring or script folder navigation**:
  1. `src/client/Controllers/PeaWheelController.lua` (Line 13):
     `local ActionRegistry = require(script.Parent.Parent.ConfigurationFiles.UIActionRegistry)`
  2. `src/client/PeaWheelBootstrap.client.lua` (Line 6):
     `local ActionRegistry = require(script.Parent.ConfigurationFiles.UIActionRegistry)`
  3. `src/client/TimedCookingScript.client.lua` (Line 2):
     `local Controllers = script.Parent:WaitForChild("Controllers")`
  4. `src/client/ui/cooking/stories/CookingHUD.story.lua` (Line 3):
     `local CookingHUD = require(script.Parent.Parent.components.CookingHUD)`
  5. `src/client/ui/inventory/components/InventoryHUD.lua` (Line 2):
     `local useInventory = require(script.Parent.Parent.hooks.useInventory)`
- *Verbatim Finding*: Zero (0) scripts use `script.Parent` to locate or access UI instances. All UI access is performed via `PlayerGui` (`player:WaitForChild("PlayerGui")`) or generated dynamically via `ClientGuiBootstrap` / `Instance.new("ScreenGui")`.

### Audit Criterion 2b: Modal/Dialogue Panel Startup Visibility (`panel.Visible = false`)
- *Command*: Audited all modal, dialogue, shop, and popup interfaces in `src/client/`.
- *Observed Initializations*:
  - `src/client/VNController.client.lua` (Lines 52, 64, 193, 206):
    `dimmer.Visible = false`, `panel.Visible = false`, `choiceFrame.Visible = false`, `nameBanner.Visible = false`
  - `src/client/CompanionShopScript.client.lua` (Lines 40, 50):
    `backdrop.Visible = false`, `panel.Visible = false`
  - `src/client/CompendiumScript.client.lua` (Line 83):
    `panel.Visible = false`
  - `src/client/Controllers/CookingController.lua` (Line 107):
    `mainPanel.Visible = false`
  - `src/client/CraftingScript.client.lua` (Line 39):
    `panel.Visible = false`
  - `src/client/DailyChecklistUI.client.lua` (Line 40):
    `panel.Visible = false`
  - `src/client/FishingMinigameScript.client.lua` (Lines 21, 30):
    `backdrop.Visible = false`, `panel.Visible = false`
  - `src/client/GuestServingUI.client.lua` (Lines 14, 24, 32):
    `gui.Enabled = false`, `backdrop.Visible = false`, `panel.Visible = false`
  - `src/client/KeybindsScript.client.lua` (Line 38):
    `panel.Visible = false`
  - `src/client/MaterialsScript.client.lua` (Line 43):
    `panel.Visible = false`
  - `src/client/OutfitWardrobeGui.client.lua` (Line 31):
    `mainFrame.Visible = false`
  - `src/client/PouchScript.client.lua` (Line 40):
    `panel.Visible = false`
  - `src/client/PromoCodeGui.client.lua` (Line 28):
    `mainFrame.Visible = false`
  - `src/client/QuestScript.client.lua` (Line 36):
    `panel.Visible = false`
  - `src/client/SettingsScreen.client.lua` (Lines 18, 28, 37):
    `gui.Enabled = false`, `backdrop.Visible = false`, `panel.Visible = false`
  - `src/client/StoreScript.client.lua` (Line 8):
    `panel.Visible = false`
  - `src/client/TeleportPicker.client.lua` (Line 13):
    `gui.Enabled = false`
  - `src/client/TutorialController.client.lua` (Line 121):
    `card.Visible = false`
  - `src/client/WelcomeStarterPackGui.client.lua` (Line 30):
    `mainFrame.Visible = false`
  - `src/client/ZundaroomsController.client.lua` (Line 24):
    `banner.Visible = false`
- *Verbatim Finding*: All 20 modal and dialogue systems explicitly set `panel.Visible = false` or `gui.Enabled = false` during script initialization.

### Audit Criterion 2c: Top-level ScreenGui `ResetOnSpawn = false`
- *Central Bootstrap*: `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua` (Lines 14-22):
  ```lua
  local screenGui = Instance.new("ScreenGui")
  screenGui.Name = name
  screenGui.ResetOnSpawn = false
  screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  if displayOrder then
      screenGui.DisplayOrder = displayOrder
  end
  screenGui.Parent = playerGui
  return screenGui
  ```
  `ClientGuiBootstrap` handles ScreenGui creation for 21 client modules and automatically enforces `ResetOnSpawn = false`.
- *Manual Compliant Implementations*: 16 client scripts create `ScreenGui` directly or fetch existing ones and explicitly set `ResetOnSpawn = false` (e.g. `AdminConsole.client.lua:13`, `CompanionHUD.client.lua:14`, `HarvestController.client.lua:59`, `CookingResultCard.client.lua:11`, `FurniturePlacement.client.lua:19`, `GuestServingUI.client.lua:12`, `HudBootstrap.client.lua:14`, `HudScript.client.lua:14,19`, `InventoryController.client.lua:26`, `PlayerStateHud.client.lua:19`, `RecipeUnlockToast.client.lua:10`, `SettingsScreen.client.lua:16`, `TeleportPicker.client.lua:11`, `UpdateScript.client.lua:12`, `WeatherClient.client.lua:75`, `ZundaFrameAnim.client.lua:10`).
- *Non-Compliant Implementations (Bugs Identified)*:
  - **`src/client/StoreScript.client.lua` (Line 148)**:
    `local toast=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))`
    (`PurchaseToast`) — missing `toast.ResetOnSpawn = false`.
  - **`src/client/StoreScript.client.lua` (Line 253)**:
    `local toast=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))`
    (`SuccessToast`) — missing `toast.ResetOnSpawn = false`.

---

## 2. Logic Chain

1. **Premise 1**: Under Rojo, scripts mapped to `StarterPlayerScripts` execute under `PlayerScripts`. If a script uses `script.Parent` to reference a GUI, it assumes it is parented inside a ScreenGui in `StarterGui`, which breaks when moved to `StarterPlayerScripts`.
   - **Observation Ref**: `default.project.json` maps `src/client` to `StarterPlayerScripts`. All 5 occurrences of `script.Parent` in `src/client` were verified to be script/module require paths.
   - **Deduction**: Client UI decoupling is fully maintained across all client scripts.

2. **Premise 2**: Modal/dialogue panels left visible in Studio or uninitialized in client scripts will appear on screen when a player joins, causing overlapping UI bugs.
   - **Observation Ref**: All 20 modal, shop, and dialogue controllers explicitly assign `panel.Visible = false` or `gui.Enabled = false` during top-level execution before listening for events or user input.
   - **Deduction**: Startup modal visibility handling fully complies with AGENTS.md Rule 2.

3. **Premise 3**: Top-level `ScreenGui` instances that omit `ResetOnSpawn = false` will be destroyed by Roblox when the player character respawns, resetting client UI state unexpectedly.
   - **Observation Ref**: `ClientGuiBootstrap` enforces `ResetOnSpawn = false` for 21 modules, and 16 standalone scripts set it manually. However, `StoreScript.client.lua` creates two temporary `ScreenGui` instances (`PurchaseToast` at line 148 and `SuccessToast` at line 253) using direct instantiation `Instance.new("ScreenGui", playerGui)` without setting `ResetOnSpawn = false`.
   - **Deduction**: `StoreScript.client.lua` has a minor non-compliance bug with Rule 2c that should be fixed by setting `toast.ResetOnSpawn = false` or using `ClientGuiBootstrap`.

---

## 3. Caveats

- **Studio Instance Inspection**: Static code analysis was performed on all 61 Lua files in `src/client/`. Pre-built `.rbxl` binary places stored outside git were not inspected directly; however, `000_LegacyOverlayCleanup.client.lua` actively cleans up any legacy studio GUI shells or grey full-screen frames upon player launch.
- **Roact Component State**: For Roact components (`ui/cooking/components/CookingHUD.lua` and `ui/inventory/components/InventoryHUD.lua`), visibility is managed via React/Roact state props (`Visible = false` in story/parent wrapper).

---

## 4. Conclusion

- **Client UI Decoupling (Rule 2a)**: **100% PASS**. No client script uses `script.Parent` for UI references.
- **Modal / Dialogue Visibility (Rule 2b)**: **100% PASS**. All 20 modal and dialogue panels set `panel.Visible = false` or `gui.Enabled = false` on startup.
- **ScreenGui ResetOnSpawn (Rule 2c)**: **96.7% PASS**. 59 of 61 files are fully compliant. 1 file (`src/client/StoreScript.client.lua`) has 2 lines (148 and 253) where temporary toast `ScreenGui` instances omit `ResetOnSpawn = false`.

### Proposed Fixes for Implementer:

#### Proposed Change 1: `src/client/StoreScript.client.lua` (Lines 148 & 253)
Set `toast.ResetOnSpawn = false` for both toast ScreenGuis:

```lua
-- Replace line 148:
local toast = Instance.new("ScreenGui")
toast.Name = "PurchaseToast"
toast.ResetOnSpawn = false
toast.DisplayOrder = 1000
toast.Parent = player:WaitForChild("PlayerGui")

-- Replace line 253:
local toast = Instance.new("ScreenGui")
toast.Name = "SuccessToast"
toast.ResetOnSpawn = false
toast.DisplayOrder = 1001
toast.Parent = player:WaitForChild("PlayerGui")
```

---

## 5. Verification Method

### Step 1: Automated Verification Script
Run the Python audit script in your working directory:
```powershell
python g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m1_2\audit.py
```
*Expected Output*:
- 0 `script.Parent` UI reference warnings.
- 0 `ResetOnSpawn` missing warnings (after applying proposed fix to `StoreScript.client.lua`).

### Step 2: Code Inspection
Inspect `src/client/StoreScript.client.lua` lines 148 & 253 to verify `ResetOnSpawn = false` is added.

### Invalidation Conditions
- Any new `.client.lua` script added to `src/client/` that calls `Instance.new("ScreenGui")` without setting `ResetOnSpawn = false`.
- Any modal frame instantiated without an explicit `.Visible = false` initial property assignment.
