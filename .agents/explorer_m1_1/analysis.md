# Pea Wheel Radial Menu Overlay Analysis

**Milestone**: Milestone 1 — UI System Overhaul  
**Target File**: `src/client/Controllers/PeaWheelController.lua`  
**Explorer Agent**: Explorer 1 (`.agents/explorer_m1_1`)  
**Date**: 2026-07-23  

---

## 1. Executive Summary

An investigation of `src/client/Controllers/PeaWheelController.lua` and related UI files (`ClientGuiBootstrap.lua`, `UIActionRegistry.lua`, `KeybindsScript.client.lua`, `HudBootstrap.client.lua`) was performed to evaluate overlay frame positioning, anchor points, off-screen alignment issues, and opening trigger mechanisms (Tab key, Q key, Hub button click).

Key Findings:
1. `wheelFrame` (the radial container) defines `AnchorPoint = Vector2.new(0.5, 0.5)` and `Position = UDim2.fromScale(0.5, 0.5)`.
2. However, alignment and off-screen positioning issues occur because `wheelGui` (the top-level `ScreenGui`) is instantiated via `ClientGuiBootstrap.createScreenGui` without setting `IgnoreGuiInset = true`. As a result, Roblox's topbar inset (~36px) offsets the scale `(0.5, 0.5)` baseline, pushing the wheel menu downwards off physical center and leaving a top gap in the background `backdropFrame`.
3. In addition, opening animations scale `wheelFrame` size from `(40, 40)` to `(340, 340)`. Because slice buttons compute offsets relative to `wheelFrame` scale `0.5`, shrinking the parent container during opening/closing causes slice items to misalign and jump during animation.
4. Input triggering (Tab key / Q key) suffers from silent suppression when `gameProcessedEvent` (`processed`) is `true` (e.g. when Roblox CoreGui processes Tab for player lists/chat) and from a delayed hold threshold (`HOLD_THRESHOLD = 0.18s`) that prevents quick taps from toggling the menu.

---

## 2. Location of Position & Anchor Point Definitions

In `src/client/Controllers/PeaWheelController.lua`:

| Component | Code Location (Line #) | Current AnchorPoint | Current Position | Current Size |
|---|---|---|---|---|
| **Top-level ScreenGui** (`wheelGui`) | Lines 64–65 | Default `(0, 0)` | Default `(0,0,0,0)` | Native Screen |
| **Backdrop Frame** (`backdropFrame`) | Lines 68–74 | Unset (defaults `(0,0)`) | Unset (defaults `(0,0,0,0)`) | `UDim2.fromScale(1, 1)` |
| **Wheel Container** (`wheelFrame`) | Lines 77–84 | `Vector2.new(0.5, 0.5)` | `UDim2.fromScale(0.5, 0.5)` | Initial: `(340, 340)` |
| **Center Hub Core** (`centerHub`) | Lines 87–93 | `Vector2.new(0.5, 0.5)` | `UDim2.fromScale(0.5, 0.5)` | `UDim2.fromOffset(88, 88)` |
| **Quick Trigger Button** (`hubButton`) | Lines 109–113 | `Vector2.new(1, 1)` | `UDim2.fromScale(1, 1) - UDim2.fromOffset(24, 24)` | `UDim2.fromOffset(64, 64)` |
| **Slice Buttons** (`sliceButtons`) | Lines 157–177 | `Vector2.new(0.5, 0.5)` | `UDim2.new(0.5, x, 0.5, y)` where `x, y = cos/sin(angle)*125` | `UDim2.fromOffset(68, 68)` |

### Code Snippets from `PeaWheelController.lua`

```lua
-- Line 64: ScreenGui Creation
wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
wheelGui.ResetOnSpawn = false

-- Lines 68-74: Backdrop Frame
backdropFrame = Instance.new("Frame")
backdropFrame.Name = "Backdrop"
backdropFrame.Size = UDim2.fromScale(1, 1)
backdropFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
backdropFrame.BackgroundTransparency = 0.55
backdropFrame.Visible = false
backdropFrame.Parent = wheelGui

-- Lines 77-84: Centered Wheel Container
wheelFrame = Instance.new("Frame")
wheelFrame.Name = "WheelFrame"
wheelFrame.Size = UDim2.fromOffset(340, 340)
wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
wheelFrame.Position = UDim2.fromScale(0.5, 0.5)
wheelFrame.BackgroundTransparency = 1
wheelFrame.Visible = false
wheelFrame.Parent = wheelGui
```

---

## 3. Root Cause Analysis of Off-Screen / Improper Alignment Issues

### Issue A: ScreenGui Topbar Inset (`IgnoreGuiInset = false`)
- **Mechanism**: `ClientGuiBootstrap.createScreenGui` creates `ScreenGui` instances with default `IgnoreGuiInset = false`.
- **Impact**: Roblox reserves a 36-pixel top bar inset for standard top bar icons (leaderboard, chat, Roblox menu).
- **Consequence**:
  1. `backdropFrame.Size = UDim2.fromScale(1, 1)` is offset down by 36px, leaving an unshaded gap at the top of the display viewport.
  2. `wheelFrame.Position = UDim2.fromScale(0.5, 0.5)` computes 50% of the *remaining viewport height below the topbar* (+ 36px offset), placing the radial menu 18 pixels lower than the physical screen center.

### Issue B: Dynamic Frame Resizing Distorting Slice Offsets
- **Mechanism**: `PeaWheelController.open()` (Line 237) forcibly sets `wheelFrame.Size = UDim2.fromOffset(40, 40)` before playing a `TweenService` animation to expand it to `(340, 340)`.
- **Impact**: Slice buttons are positioned using `UDim2.new(0.5, x, 0.5, y)`. The `0.5` scale is evaluated against `wheelFrame`'s width and height.
- **Consequence**: When `wheelFrame` is 40x40, `0.5 * 40 = 20px`. When `wheelFrame` is 340x340, `0.5 * 340 = 170px`. This 150px shift causes slice buttons to animate from distorted origins during the opening/closing pop tween.

### Issue C: Game Processed Event (`processed`) Swallowing Key Triggers
- **Mechanism**: `onInputBegan` checks `if processed then return end` (Line 282).
- **Impact**: In Roblox, `Tab` is natively bound to player list toggle or text chat focus.
- **Consequence**: When a player presses `Tab` while focus or CoreGui claims the input, `processed` is `true`, causing `onInputBegan` to abort silently. The Pea Wheel fails to open.

### Issue D: Hold Threshold Delay (`HOLD_THRESHOLD = 0.18s`)
- **Mechanism**: `onInputBegan` starts a `task.delay(0.18)` timer. If `onInputEnded` fires before 0.18 seconds elapse, `isHolding` is set to `false`.
- **Consequence**: Quick key taps fail to open the menu because the key release cancels the opening callback before 0.18s completes.

---

## 4. Proposed Code Changes for Position and Alignment Verification

To ensure perfect centering and alignment across all screen ratios, the following code updates are recommended in `PeaWheelController.lua`:

### Change 1: Set `IgnoreGuiInset = true` on `wheelGui`
```lua
-- In buildWheelGui() (Lines 64-66)
wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
wheelGui.ResetOnSpawn = false
wheelGui.IgnoreGuiInset = true -- Guarantees UDim2.fromScale(0.5, 0.5) hits absolute screen center
```

### Change 2: Explicitly Define `AnchorPoint` and `Position` on `backdropFrame`
```lua
-- In buildWheelGui() (Lines 68-75)
backdropFrame = Instance.new("Frame")
backdropFrame.Name = "Backdrop"
backdropFrame.AnchorPoint = Vector2.new(0.5, 0.5)
backdropFrame.Position = UDim2.fromScale(0.5, 0.5)
backdropFrame.Size = UDim2.fromScale(1, 1)
backdropFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
backdropFrame.BackgroundTransparency = 0.55
backdropFrame.Visible = false
backdropFrame.Parent = wheelGui
```

### Change 3: Preserve fixed `wheelFrame` scale center & use `UIScale` or transparency/size pop
Instead of collapsing `wheelFrame` to `(40, 40)` which distorts child slice `0.5` scale origins, maintain `wheelFrame.Size = UDim2.fromOffset(340, 340)` with `UIScale` tweening or fixed size pop:
```lua
-- In buildWheelGui()
local uiScale = Instance.new("UIScale")
uiScale.Name = "WheelScale"
uiScale.Scale = 1
uiScale.Parent = wheelFrame

-- In open()
uiScale.Scale = 0.1
TweenService:Create(uiScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Scale = 1,
}):Play()
```

---

## 5. Input Trigger Analysis (Tab Key, Q Key, Hub Button)

### Trigger Breakdown

1. **Tab Key & Q Key (`UserInputService.InputBegan`)**:
   - Defined in `onInputBegan` (Lines 285–299) and `onInputEnded` (Lines 322–326).
   - Currently requires `input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Q`.
   - **Recommended Trigger Fix**:
     - Allow instant toggle on `InputBegan` key press without forcing a 0.18s hold threshold.
     - For `Tab` key, bypass `if processed then return end` when `input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Q` unless typing in a `TextBox`.

2. **Hub Button Click (`hubButton`)**:
   - Defined in `buildWheelGui()` (Lines 109–130).
   - Click connection:
     ```lua
     hubButton.MouseButton1Click:Connect(function()
         if RunService:IsStudio() and RunService:IsEdit() then return end
         if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
         PeaWheelController.toggle()
     end)
     ```
   - Fixed positioning at bottom-right (`AnchorPoint = Vector2.new(1, 1)`, `Position = UDim2.fromScale(1, 1) - UDim2.fromOffset(24, 24)`). Works reliably.

3. **Global API Export (`_G.PeaWheel`)**:
   - Lines 333–334: `_G.PeaWheelController = PeaWheelController`, `_G.PeaWheel = PeaWheelController`.
   - Direct calls to `_G.PeaWheel.toggle()` or `_G.PeaWheel.open()` allow HUD buttons or radial triggers from external scripts.

---

## 6. Summary Matrix of Required Fixes

| Problem Area | Current State | Root Cause | Proposed Solution |
|---|---|---|---|
| Screen Centering | Off-center vertically by ~18px | `ScreenGui.IgnoreGuiInset` defaults to `false` | Set `wheelGui.IgnoreGuiInset = true` |
| Backdrop Overlay | Uncovered top gap (36px) | `backdropFrame` inherits topbar inset | Set `wheelGui.IgnoreGuiInset = true` & explicit `AnchorPoint/Position` |
| Opening Pop Animation | Slices jump during size tween | `wheelFrame` size shrinks to `(40,40)` altering `0.5` scale offset | Use `UIScale` instance on `wheelFrame` for scaling transitions |
| Tab Key Responsiveness | Tab key ignored when CoreGui processed | `if processed then return end` check in `onInputBegan` | Exclude `Tab`/`Q` from `processed` check unless `UserInputService:GetFocusedTextBox()` is active |
| Hold vs Tap Delay | 0.18s hold delay prevents quick tap toggle | `HOLD_THRESHOLD` cancels open on quick release | Trigger `PeaWheelController.toggle()` immediately on key down |
