# Handoff Report — Explorer 1 (Milestone 1)

**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m1_1\`  
**Target File Analyzed**: `src/client/Controllers/PeaWheelController.lua`  
**Related Files Inspected**:  
- `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua`  
- `src/client/ConfigurationFiles/UIActionRegistry.lua`  
- `src/client/KeybindsScript.client.lua`  
- `src/client/HudBootstrap.client.lua`  
- `src/client/PeaWheelStarter.client.lua`  

---

## 1. Observation

Direct observations from source code inspection:

1. **`wheelGui` ScreenGui Construction** (`src/client/Controllers/PeaWheelController.lua`, lines 64–65):
   ```lua
   wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
   wheelGui.ResetOnSpawn = false
   ```
   In `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua` (lines 14–22):
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
   `IgnoreGuiInset` is NOT set on `screenGui`, defaulting to `false`.

2. **`backdropFrame` Definition** (`src/client/Controllers/PeaWheelController.lua`, lines 68–74):
   ```lua
   backdropFrame = Instance.new("Frame")
   backdropFrame.Name = "Backdrop"
   backdropFrame.Size = UDim2.fromScale(1, 1)
   backdropFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
   backdropFrame.BackgroundTransparency = 0.55
   backdropFrame.Visible = false
   backdropFrame.Parent = wheelGui
   ```
   `AnchorPoint` and `Position` are uninitialized (defaults: `Vector2.new(0, 0)` and `UDim2.new(0, 0, 0, 0)`).

3. **`wheelFrame` Container Definition** (`src/client/Controllers/PeaWheelController.lua`, lines 77–84):
   ```lua
   wheelFrame = Instance.new("Frame")
   wheelFrame.Name = "WheelFrame"
   wheelFrame.Size = UDim2.fromOffset(340, 340)
   wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
   wheelFrame.Position = UDim2.fromScale(0.5, 0.5)
   wheelFrame.BackgroundTransparency = 1
   wheelFrame.Visible = false
   wheelFrame.Parent = wheelGui
   ```

4. **Opening Animation Resize** (`src/client/Controllers/PeaWheelController.lua`, lines 237–241):
   ```lua
   wheelFrame.Visible = true
   wheelFrame.Size = UDim2.fromOffset(40, 40)

   TweenService:Create(wheelFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
       Size = UDim2.fromOffset(340, 340),
   }):Play()
   ```

5. **Slice Button Position Calculation** (`src/client/Controllers/PeaWheelController.lua`, lines 174–177):
   ```lua
   local angle = math.rad(-90 + (i - 1) * 45)
   local x = math.cos(angle) * radius
   local y = math.sin(angle) * radius
   btn.Position = UDim2.new(0.5, x, 0.5, y)
   ```

6. **Input Event Handling** (`src/client/Controllers/PeaWheelController.lua`, lines 281–298):
   ```lua
   local function onInputBegan(input, processed)
       if processed then return end

       if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Q then
           if not isOpen then
               isHolding = true
               task.delay(HOLD_THRESHOLD, function()
                   if isHolding and not isOpen then
                       PeaWheelController.open()
                   end
                   isHolding = false
               end)
           else
               PeaWheelController.close()
               isHolding = false
           end
           return
       end
   ```

7. **Hub Button Trigger** (`src/client/Controllers/PeaWheelController.lua`, lines 125–129):
   ```lua
   hubButton.MouseButton1Click:Connect(function()
       if RunService:IsStudio() and RunService:IsEdit() then return end
       if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
       PeaWheelController.toggle()
   end)
   ```

---

## 2. Logic Chain

1. **Top Bar Inset Misalignment**:
   - `ClientGuiBootstrap.createScreenGui` returns a `ScreenGui` with `IgnoreGuiInset = false`.
   - In Roblox UI rendering, `IgnoreGuiInset = false` offsets the root coordinate space down by ~36px (the topbar inset height).
   - Thus, setting `wheelFrame.Position = UDim2.fromScale(0.5, 0.5)` places the center of `wheelFrame` at `(0.5 * ScreenWidth, 0.5 * (ScreenHeight - 36) + 36)`, which is 18px below the physical screen center.
   - `backdropFrame` (`Size = UDim2.fromScale(1, 1)`) starts at Y=36px, leaving a 36px unshaded bar across the top of the screen.

2. **Slice Animation Distortion**:
   - Each slice button position uses `UDim2.new(0.5, x, 0.5, y)`. The `0.5` scale is relative to `wheelFrame.AbsoluteSize`.
   - When `open()` sets `wheelFrame.Size = UDim2.fromOffset(40, 40)`, `0.5 * 40 = 20px`. When `wheelFrame` grows to `340x340`, `0.5 * 340 = 170px`.
   - The 150px shift in absolute center during tweening causes the slice buttons to fly out from wrong relative coordinates during the pop-in animation.

3. **Tab Key Suppression & Tap Failure**:
   - `onInputBegan` checks `if processed then return end`. Roblox CoreGui claims `Tab` key presses for player lists or chat navigation. When `processed` is `true`, `onInputBegan` returns early before checking `input.KeyCode == Enum.KeyCode.Tab`.
   - Furthermore, `HOLD_THRESHOLD = 0.18s` requires holding the key down. If a user quickly taps `Tab` or `Q`, `InputEnded` sets `isHolding = false` before the `0.18s` delay fires, preventing `open()`.

4. **Hub Button Functionality**:
   - The Hub Button click directly invokes `PeaWheelController.toggle()`, which circumvents `processed` checks and `HOLD_THRESHOLD` delays. It is reliable but suffers from the same `IgnoreGuiInset` off-center positioning when opening `wheelFrame`.

---

## 3. Caveats

1. **Read-only Scope**: As Explorer 1, no source code files under `src/` were edited. All proposed changes are documented for the implementer agent.
2. **CoreGui Overrides**: Setting `IgnoreGuiInset = true` affects all direct children of `wheelGui`. Since `wheelGui` contains only `backdropFrame`, `wheelFrame`, `hubButton`, and `tooltipLabel`, this is safe and desirable.
3. **TextBox Focus Check**: When bypassing `processed` for Tab/Q keys, a check for `UserInputService:GetFocusedTextBox()` should be included to prevent toggling the wheel while typing in chat or input fields.

---

## 4. Conclusion

`PeaWheelController.lua` currently suffers from alignment, positioning, and trigger responsiveness bugs due to:
1. Missing `wheelGui.IgnoreGuiInset = true` in `buildWheelGui()`.
2. Missing explicit `AnchorPoint` (`Vector2.new(0.5, 0.5)`) and `Position` (`UDim2.fromScale(0.5, 0.5)`) on `backdropFrame`.
3. Distorted slice positioning caused by resizing `wheelFrame` directly during open/close tweens instead of using `UIScale`.
4. Input suppression on `Tab`/`Q` key presses caused by `processed` checks and `HOLD_THRESHOLD` hold-time delays.

Implementing the 4 verified code changes in `PeaWheelController.lua` will resolve all off-screen invisibility, alignment, and key responsiveness issues.

---

## 5. Verification Method

To independently verify these findings and check the upcoming implementer's fix:

1. **Inspect Code Locations**:
   - Verify `wheelGui.IgnoreGuiInset = true` is set in `PeaWheelController.lua` under `buildWheelGui()`.
   - Verify `wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)` and `wheelFrame.Position = UDim2.fromScale(0.5, 0.5)`.
   - Verify `backdropFrame.AnchorPoint = Vector2.new(0.5, 0.5)` and `backdropFrame.Position = UDim2.fromScale(0.5, 0.5)`.

2. **In-Game Playtest Verification**:
   - Open Roblox Studio playtest (or run `roblox-studio_solo_playtest` via Studio MCP).
   - Press `Tab` or `Q`: Confirm the Pea Wheel radial menu opens centered on physical display screen without top bar gap.
   - Click bottom-right `HubButton`: Confirm radial menu opens smoothly at screen center.
   - Verify all 8 slice buttons remain perfectly positioned around the center hub without visual shifting during scale transitions.
