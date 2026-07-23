# Technical Analysis: ClientGuiBootstrap, UI Decoupling Rules & Startup Visibility for Pea Wheel System

**Target Scope**: Milestone 1 — UI System Overhaul  
**Target Files Analyzed**:
- `src/client/Controllers/PeaWheelController.lua`
- `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua`
- `src/client/000_LegacyOverlayCleanup.client.lua`
- `src/client/PeaWheelStarter.client.lua`
- `src/client/PeaWheelBootstrap.client.lua`
- `src/shared/ConfigurationFiles/LegacyGuiConfig.lua`

---

## Executive Summary

An investigation was conducted on `PeaWheelController.lua`, `ClientGuiBootstrap.lua`, and `000_LegacyOverlayCleanup.client.lua` to evaluate compliance with Roblox Studio & Rojo UI Decoupling rules, startup visibility controls, and lifetime persistence across player respawns (`ResetOnSpawn = false`).

### Key Findings:
1. **`ResetOnSpawn = false` Compliance**: **VERIFIED**. Both `ClientGuiBootstrap.createScreenGui` (line 16) and `PeaWheelController.lua` (line 65) explicitly assign `screenGui.ResetOnSpawn = false`. The top-level `PeaWheelGui` persists under `PlayerGui` across player character respawns without losing UI bindings or dropping instance references.
2. **Startup Visibility Control**: **VERIFIED**. In `PeaWheelController.lua`, the modal backdrop frame (`backdropFrame.Visible = false`, line 73), the radial menu container (`wheelFrame.Visible = false`, line 83), and the action label (`tooltipLabel.Visible = false`, line 143) are explicitly set to `Visible = false` upon initial creation. The overlay does not display, block raycasts, or overlap other HUD elements on game startup before explicit user activation (via Tab/Q keypress or `HubButton` click).
3. **Decoupled UI & Bootstrap Interaction**: **VERIFIED**. `PeaWheelController.lua` consumes `ClientGuiBootstrap` to construct its `ScreenGui` dynamically in `PlayerGui` without referencing `script.Parent`. When `PeaWheelGui` is added to `PlayerGui`, `000_LegacyOverlayCleanup.client.lua` evaluates it via its `ChildAdded` listener (`cleanupScreenGui`); `PeaWheelGui` passes cleanup safely without being destroyed or stripped because it is not listed in `LegacyGuiConfig.destroyScreenGuis` or `destroyLegacyStarterShells`, and contains no legacy grey fullscreen frames or embedded LocalScripts.

---

## Detailed Code & Evidence Analysis

### 1. `ResetOnSpawn = false` Verification

#### Observations:
- **`src/shared/ConfigurationFiles/ClientGuiBootstrap.lua`**:
```lua
14: 	local screenGui = Instance.new("ScreenGui")
15: 	screenGui.Name = name
16: 	screenGui.ResetOnSpawn = false
17: 	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
```
- **`src/client/Controllers/PeaWheelController.lua`**:
```lua
64: 	wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
65: 	wheelGui.ResetOnSpawn = false
```

#### Technical Reasoning & Safety:
- When a Roblox player resets or respawns, `ScreenGui` instances with `ResetOnSpawn = true` (Roblox's default) are automatically destroyed by the Roblox engine and recreated from `StarterGui`.
- Because `PeaWheelController` builds its GUI dynamically via `ClientGuiBootstrap` (decoupled from `StarterGui`), destroying `PeaWheelGui` on respawn would leave stale, dangling Lua references (`wheelGui`, `wheelFrame`, `backdropFrame`) pointing to destroyed instances.
- Double-setting `ResetOnSpawn = false` in `ClientGuiBootstrap` and `PeaWheelController.lua` guarantees that `PeaWheelGui` remains under `PlayerGui` across player respawns, preserving event connections (`MouseButton1Click`, `InputBegan`, `MouseEnter`) and preventing null reference exceptions post-respawn.

---

### 2. Startup Visibility (`Visible = false`) Verification

#### Observations:
- **`src/client/Controllers/PeaWheelController.lua`**:
```lua
68: 	backdropFrame = Instance.new("Frame")
69: 	backdropFrame.Name = "Backdrop"
70: 	backdropFrame.Size = UDim2.fromScale(1, 1)
71: 	backdropFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
72: 	backdropFrame.BackgroundTransparency = 0.55
73: 	backdropFrame.Visible = false
...
77: 	wheelFrame = Instance.new("Frame")
78: 	wheelFrame.Name = "WheelFrame"
79: 	wheelFrame.Size = UDim2.fromOffset(340, 340)
80: 	wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
81: 	wheelFrame.Position = UDim2.fromScale(0.5, 0.5)
82: 	wheelFrame.BackgroundTransparency = 1
83: 	wheelFrame.Visible = false
...
132: 	tooltipLabel = Instance.new("TextLabel")
...
143: 	tooltipLabel.Visible = false
...
331: 	buildWheelGui()
```

#### Technical Reasoning & Safety:
- `buildWheelGui()` is invoked immediately when `PeaWheelController` module is required (line 331).
- Upon invocation, `backdropFrame`, `wheelFrame`, and `tooltipLabel` are initialized with `Visible = false`.
- Controller state starts at `isOpen = false` (line 28).
- The quick trigger launcher button (`HubButton`, lines 109-124) remains visible at the bottom-right corner (`Position = UDim2.fromScale(1, 1) - UDim2.fromOffset(24, 24)`), which is the intended HUD quick-access trigger.
- The 360° radial menu panel (`wheelFrame`) and screen-dimming backdrop (`backdropFrame`) do not display or block inputs until `PeaWheelController.open()` or `.toggle()` is invoked.
- When `PeaWheelController.close()` is called, `wheelFrame` scales down via `TweenService` and after a 0.16s delay both `wheelFrame.Visible` and `backdropFrame.Visible` are set back to `false` (lines 255-256).

---

### 3. Cleanup & Decoupling Interaction (`000_LegacyOverlayCleanup.client.lua`)

#### Observations:
- **`src/client/000_LegacyOverlayCleanup.client.lua`**:
```lua
131: local function cleanupScreenGui(gui: ScreenGui)
132: 	if destroyOverlayGui(gui) then
133: 		return
134: 	end
135: 	if destroyLegacyStarterShell(gui) then
136: 		return
137: 	end
138: 	-- Single-pass descendant cleanup to maximize startup performance
139: 	for _, inst in ipairs(gui:GetDescendants()) do
140: 		if isStudioGreyFullscreen(inst) then
141: 			inst:Destroy()
142: 			logRemoved("grey fullscreen " .. inst:GetFullName())
143: 		elseif inst:IsA("LocalScript") then
144: 			inst.Enabled = false
145: 			inst:Destroy()
146: 			logRemoved("Embedded LocalScript " .. inst:GetFullName())
147: 		elseif isLegacyVignetteFrame(inst) then
148: 			inst:Destroy()
149: 			logRemoved("Vignette " .. inst:GetFullName())
150: 		end
151: 	end
152: end
...
164: playerGui.ChildAdded:Connect(function(child)
165: 	task.defer(function()
166: 		if child:IsA("ScreenGui") then
167: 			cleanupScreenGui(child)
168: 		end
169: 	end)
170: end)
```

- **`src/shared/ConfigurationFiles/LegacyGuiConfig.lua`**:
```lua
8: LegacyGuiConfig.destroyScreenGuis = {
9: 	"ZundaFX",
10: 	"PostProcessOverlay",
11: }
...
23: LegacyGuiConfig.destroyLegacyStarterShells = {
24: 	"ZundaVN",
25: 	"ZundaPouch",
26: 	"QuestPanel",
27: 	"CompanionShop",
28: 	"ZundaShop",
29: }
```

#### Technical Reasoning & Safety:
- `000_LegacyOverlayCleanup.client.lua` operates on `PlayerGui.ChildAdded`.
- When `ClientGuiBootstrap.createScreenGui` parents `PeaWheelGui` to `PlayerGui`, `cleanupScreenGui` checks:
  1. `destroyOverlayGui`: `PeaWheelGui` is not in `destroyScreenGuis` -> Retained.
  2. `destroyLegacyStarterShell`: `PeaWheelGui` is not in `destroyLegacyStarterShells` -> Retained.
  3. Single-pass descendant inspection:
     - `Backdrop`: `BackgroundTransparency = 0.55` (> 0.05 limit in `isStudioGreyFullscreen`), `BackgroundColor3 = RGB(10,8,16)` -> Retained.
     - `WheelFrame`: `BackgroundTransparency = 1` -> Retained.
     - UIStrokes, UICorners, TextButtons: Not LocalScripts or Vignettes -> Retained.
- Result: `PeaWheelGui` cleanly coexists with `000_LegacyOverlayCleanup.client.lua` without race conditions or accidental destruction.

---

## Non-Critical Discoveries & Recommendations

1. **`PeaWheelStarter.client.lua` Print Message Consistency**:
   - `PeaWheelStarter.client.lua` line 8 contains `print("[PeaWheelStarter] PeaWheelController loaded — wheel ready on Tab/G key")`.
   - `PeaWheelController.lua` listens to `Tab` and `Q` keys (line 285).
   - *Recommendation*: Update print statement in `PeaWheelStarter.client.lua` line 8 to reference `Tab/Q key`.

2. **`PeaWheelStarter.client.lua` Comment Accuracy**:
   - `PeaWheelStarter.client.lua` line 6 comment states `-- The PeaWheelController builds its GUI lazily on first open/toggle.`.
   - `PeaWheelController.lua` actually calls `buildWheelGui()` at module load (line 331).
   - *Recommendation*: Update comment in `PeaWheelStarter.client.lua` line 6 for clarity.

3. **Dead Code in `000_LegacyOverlayCleanup.client.lua`**:
   - Lines 49-129 contain legacy helper functions (`destroyNamedDescendants`, `destroyHeuristicVignettes`, `destroyStudioGreyFullscreen`, `stripEmbeddedScripts`) which are unused because `cleanupScreenGui` (lines 131-152) inline-handles single-pass descendant inspection.
   - *Recommendation*: Flag for dead-code cleanup during Milestone 3 (Performance Traversal Overhaul).

---

## Conclusion

The architecture of `PeaWheelController.lua`, `ClientGuiBootstrap.lua`, and `000_LegacyOverlayCleanup.client.lua` fully satisfies all client UI decoupling guidelines and startup visibility requirements:
- `ResetOnSpawn = false` is active on `PeaWheelGui`.
- Modal frames are hidden on game start (`Visible = false`).
- Startup cleanup in `000_LegacyOverlayCleanup.client.lua` safely passes `PeaWheelGui`.
