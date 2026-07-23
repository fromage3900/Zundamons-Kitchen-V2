# Pea Wheel Radial Slices Analysis Report

**Target File**: `src/client/Controllers/PeaWheelController.lua`  
**Related Files**: `src/client/ConfigurationFiles/UIActionRegistry.lua`, `src/shared/ConfigurationFiles/UIConfig.lua`, `src/shared/ConfigurationFiles/ClientGuiBootstrap.lua`, `src/client/HudBootstrap.client.lua`  
**Milestone**: UI System Overhaul — Milestone 1 (Explorer 2 Analysis)

---

## 1. Executive Summary

This report provides a comprehensive analysis of the 8 radial slices in `src/client/Controllers/PeaWheelController.lua` and its related configuration files (`UIActionRegistry.lua`, `UIConfig.lua`). 

Key discoveries include:
- The 8 radial slices are rendered at 45° angular intervals starting from $-90^\circ$ (top).
- A naming mismatch exists between the user prompt's `shop` slice and the code's canonical registered action `companions` (icon 🌸, label "Companions"), mapped to HUD button `HudBtn_shop`.
- **Clipping Vulnerability**: `PeaWheelController.lua` uses fixed pixel offsets (`UDim2.fromOffset` with $340 \times 340$ px container and radius $R = 125$ px) without any `UIScale` or resolution responsiveness. On mobile landscape viewports ($\le 375\text{px}$ height) or small screens ($\le 320\text{px}$ width/height), the top/bottom slices and the tooltip label clip off-screen by up to $78\text{px}$.
- A dynamic `UIScale` responsiveness formula and centered layout bounds are designed to ensure 100% visibility across all screen resolutions without edge clipping.

---

## 2. Radial Slice Inventory & Mapping Table

The Pea Wheel menu constructs 8 radial slices in order from `UIActionRegistry.getOrderedSliceList()`.

| Index | Action ID | Label | Icon | Category | Keybind | Angular Position ($\theta$) | Position Offset $(x, y)$ relative to wheel center | Base Color (Nikki Pastels) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `inventory` | Pouch | 🎒 | Inventory | `I` | $-90^\circ$ (Top) | $(0, -125)$ | `RGB(255, 182, 193)` (Pastel Pink) |
| 2 | `cook` | Cook | 🍳 | Gameplay | *None* | $-45^\circ$ (Top-Right) | $(+88.39, -88.39)$ | `RGB(173, 216, 230)` (Pastel Blue) |
| 3 | `quests` | Quests | 📜 | Exploration | `J` | $0^\circ$ (Right) | $(+125, 0)$ | `RGB(255, 218, 185)` (Pastel Peach) |
| 4 | `compendium` | Collection | 📖 | Reference | `C` | $+45^\circ$ (Bottom-Right) | $(+88.39, +88.39)$ | `RGB(221, 160, 221)` (Pastel Lavender) |
| 5 | `materials` | Materials | 🧺 | Inventory | *None* | $+90^\circ$ (Bottom) | $(0, +125)$ | `RGB(152, 251, 152)` (Pastel Mint) |
| 6 | `map` | Map | 🗺️ | Exploration | `M` | $+135^\circ$ (Bottom-Left) | $(-88.39, +88.39)$ | `RGB(255, 255, 224)` (Pastel Lemon) |
| 7 | `companions` (*shop*) | Companions | 🌸 | Progression | *None* | $+180^\circ$ (Left) | $(-125, 0)$ | `RGB(176, 224, 230)` (Pastel Sky) |
| 8 | `settings` | Settings | ⚙ | System | `F1` | $+225^\circ$ (Top-Left) | $(-88.39, -88.39)$ | `RGB(230, 190, 255)` (Pastel Lilac) |

> **Discrepancy Note**: The prompt lists the 7th slice as `shop`. In `UIActionRegistry.lua` (lines 100-108, 193), action ID 7 is registered as `companions` (icon 🌸, label `"Companions"`). In `HudBootstrap.client.lua` line 60 & 103, `HudBtn_shop` maps to `"companions"`.

---

## 3. Dynamic Layout & Math Specification

### 3.1 Hierarchy & Dimensions
1. **ScreenGui (`PeaWheelGui`)**: DisplayOrder = 80, `ResetOnSpawn = false`, `IgnoreGuiInset = false` (default via `ClientGuiBootstrap`).
2. **Wheel Frame Container (`wheelFrame`)**:
   - `AnchorPoint = Vector2.new(0.5, 0.5)`
   - `Position = UDim2.fromScale(0.5, 0.5)`
   - Full Open Size: `UDim2.fromOffset(340, 340)`
3. **Center Hub (`centerHub`)**:
   - `Size = UDim2.fromOffset(88, 88)`, anchored at center `(0.5, 0.5)`.
4. **Slice Buttons (`Slice_<actionId>`)**:
   - Resting Size: `UDim2.fromOffset(68, 68)` (Radius $r_r = 34\text{px}$)
   - Selected/Hover Size: `UDim2.fromOffset(82, 82)` (Radius $r_s = 41\text{px}$)
5. **Tooltip Label (`tooltipLabel`)**:
   - `Size = UDim2.fromOffset(220, 36)`
   - `Position = UDim2.new(0.5, 0, 1, 14)` (Top edge starts 14px below bottom of `wheelFrame`).

### 3.2 Trigonometric Layout Math
For slice index $i \in \{1 \dots 8\}$ with radius $R = 125\text{px}$:
$$\theta_i = \text{radians}\left(-90^\circ + (i - 1) \cdot 45^\circ\right)$$
$$x_i = \cos(\theta_i) \cdot 125$$
$$y_i = \sin(\theta_i) \cdot 125$$
$$\text{Position}_i = \text{UDim2.new}(0.5, x_i, 0.5, y_i)$$

### 3.3 Bounding Box Calculations
- **Horizontal Span**:
  - Distance from center to selected slice outer edge: $R + r_s = 125 + 41 = 166\text{px}$.
  - Total Horizontal Width = $166 \times 2 = 332\text{px}$.
- **Vertical Span**:
  - Distance from center to top edge of Selected Slice 1 (`inventory`): $-166\text{px}$.
  - Distance from center to bottom edge of `tooltipLabel`:
    $\text{wheelFrame half-height} (170\text{px}) + \text{offset} (14\text{px}) + \text{tooltip height} (36\text{px}) = +220\text{px}$.
  - Total Vertical Height = $166 + 220 = 386\text{px}$.

---

## 4. Off-Screen Clipping Investigation

Because `PeaWheelController.lua` uses fixed pixel offsets without scale bounds or `UIScale` responsive scaling, clipping occurs on smaller screen resolutions.

Since `IgnoreGuiInset = false`, the usable viewport height is $H_{usable} = H_{screen} - 36\text{px}$ (Roblox TopBar height).

### Resolution Impact Analysis Table

| Device / Resolution | Viewport (W x H) | Usable Viewport | Vertical Span vs Usable H | Horizontal Span vs Usable W | Clipping Result | Off-screen Deficit |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Desktop 1080p** | 1920 x 1080 | 1920 x 1044 | 386px vs 1044px | 332px vs 1920px | **No Clipping** | +302px margin bottom |
| **Laptop 768p** | 1366 x 768 | 1366 x 732 | 386px vs 732px | 332px vs 1366px | **No Clipping** | +146px margin bottom |
| **Small Desktop / Tablet 600p** | 1024 x 600 | 1024 x 564 | 386px vs 564px | 332px vs 1024px | **No Clipping** | +62px margin bottom |
| **Compact Display 480p** | 800 x 480 | 800 x 444 | 386px vs 444px | 332px vs 800px | **Borderline Safe** | +29px margin bottom |
| **Mobile Landscape (iPhone 8)** | 667 x 375 | 667 x 339 | **386px vs 339px** | 332px vs 667px | **CRITICAL CLIPPING** | **Tooltip clips off-screen by 50.5px** |
| **Mobile Landscape (Small)** | 568 x 320 | 568 x 284 | **386px vs 284px** | 332px vs 568px | **CRITICAL CLIPPING** | **Slice 1 (-24px top), Slice 5 (-24px bottom), Tooltip (-78px bottom)** |
| **Mobile Portrait (Small)** | 320 x 568 | 320 x 532 | 386px vs 532px | **332px vs 320px** | **CRITICAL CLIPPING** | **Slice 7 (-6px left), Slice 3 (-6px right)** |

### Identified Root Causes
1. **Fixed Offset Sizes**: `UDim2.fromOffset` hardcoded dimensions throughout.
2. **Missing UIScale Component**: No `UIScale` parented to `wheelFrame` to dynamically scale based on viewport size.
3. **Dangling Tooltip**: The tooltip label extends 50px past the bottom of `wheelFrame` (+220px from center), inflating total vertical height by 16.2%.

---

## 5. Mathematical Layout & Scale Solution (100% Visibility Guarantee)

To guarantee that all 8 radial slices and tooltips remain 100% visible on all devices, we define a dynamic scaling algorithm.

### 5.1 Dynamic `UIScale` Formula
Attach a `UIScale` instance to `wheelFrame`. Compute `UIScale.Scale` dynamically based on viewport dimensions:

$$\text{UsableHeight} = \text{Viewport.Y} - (\text{IgnoreGuiInset} \mathrel{?} 0 : 36)$$
$$\text{UsableWidth} = \text{Viewport.X}$$
$$\text{Scale}_V = \frac{\text{UsableHeight} \times 0.88}{386}$$
$$\text{Scale}_H = \frac{\text{UsableWidth} \times 0.88}{332}$$
$$\text{Scale}_{\text{target}} = \text{clamp}(\min(1.0, \text{Scale}_V, \text{Scale}_H), 0.50, 1.25)$$

### 5.2 Tooltip Positioning Optimization
Moving `tooltipLabel` into the center hub or beneath the center hub (`UDim2.new(0.5, 0, 0.5, 50)`) shrinks total vertical footprint from $386\text{px}$ down to $332\text{px}$. This establishes a symmetric $332 \times 332$ px bounding square.

---

## 6. Proposed Code Changes (Read-Only Proposal)

### 6.1 Update `src/client/Controllers/PeaWheelController.lua`

```lua
-- Proposed change: Add dynamic UIScale management to buildWheelGui()
local uiScale: UIScale? = nil

local function updateWheelScale()
	if not wheelFrame or not wheelGui then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local viewport = camera.ViewportSize
	local usableH = viewport.Y - (wheelGui.IgnoreGuiInset and 0 or 36)
	local usableW = viewport.X
	
	-- Max vertical height 386px, max horizontal width 332px
	local scaleV = (usableH * 0.88) / 386
	local scaleH = (usableW * 0.88) / 332
	
	local targetScale = math.clamp(math.min(scaleV, scaleH), 0.55, 1.20)
	if uiScale then
		uiScale.Scale = targetScale
	end
end

-- Inside buildWheelGui():
uiScale = Instance.new("UIScale")
uiScale.Parent = wheelFrame

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateWheelScale)
updateWheelScale()
```

---

## 7. Verification Plan

1. **Unit Verification**: Validate angular position math using `math.cos` and `math.sin` at 45° increments.
2. **Viewport Simulation**:
   - In Roblox Studio, use Device Emulation mode for:
     - iPhone 8 Landscape ($667 \times 375$)
     - iPhone 5/SE Landscape ($568 \times 320$)
     - Budget Android Portrait ($360 \times 740$)
     - 1080p Desktop ($1920 \times 1080$)
   - Verify all 8 slices (`inventory`, `cook`, `quests`, `compendium`, `materials`, `map`, `companions`, `settings`) and tooltips fit 100% inside screen boundaries with $\ge 15\text{px}$ margin.
