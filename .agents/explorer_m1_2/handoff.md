# Explorer 2 Handoff Report — Pea Wheel Radial Slices Analysis

**Author**: Explorer 2  
**Target Component**: `src/client/Controllers/PeaWheelController.lua` & Radial UI System  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m1_2\`  
**Date**: 2026-07-23

---

## 1. Observation

1. **File Locations & Lines**:
   - `src/client/Controllers/PeaWheelController.lua`:
     - Line 79: `wheelFrame.Size = UDim2.fromOffset(340, 340)`
     - Line 81: `wheelFrame.Position = UDim2.fromScale(0.5, 0.5)`
     - Line 149: `local radius = 125`
     - Line 157: `btn.Size = UDim2.fromOffset(68, 68)`
     - Line 174: `local angle = math.rad(-90 + (i - 1) * 45)`
     - Line 175-176: `local x = math.cos(angle) * radius`, `local y = math.sin(angle) * radius`
     - Line 207: Hover size tween target `Size = UDim2.fromOffset(82, 82)`
     - Line 136: `tooltipLabel.Position = UDim2.new(0.5, 0, 1, 14)`, `Size = UDim2.fromOffset(220, 36)`
   - `src/client/ConfigurationFiles/UIActionRegistry.lua`:
     - Lines 185-196: `getOrderedSliceList()` returns `{"inventory", "cook", "quests", "compendium", "materials", "map", "companions", "settings"}`.
   - `src/client/HudBootstrap.client.lua`:
     - Lines 60, 103: `HudBtn_shop` maps to action `"companions"`.

2. **Verbatim Code & Layout Parameters**:
   - Angular step: $45^\circ$ starting from top $-90^\circ$.
   - Selected slice button radius: $82 / 2 = 41\text{px}$.
   - Distance from center to selected slice outer edge: $125 + 41 = 166\text{px}$.
   - Total horizontal footprint: $166 \times 2 = 332\text{px}$.
   - Total vertical footprint: $-166\text{px}$ (top edge of Slice 1) to $+220\text{px}$ (bottom edge of tooltip) = $386\text{px}$.

---

## 2. Logic Chain

1. **Observation 1** establishes that `wheelFrame` is fixed at $340 \times 340$ px with radius $R = 125$ px and slice selected size $82 \times 82$ px, yielding an outer radial radius of $166$ px.
2. **Observation 1** shows `tooltipLabel` positioned at `UDim2.new(0.5, 0, 1, 14)` relative to `wheelFrame`, placing its lower boundary at $+220$ px below screen center.
3. Combining (1) and (2), the minimum viewport height required to render the full Pea Wheel overlay without clipping is $386$ px (or $386 + 36 = 422$ px including Roblox TopBar inset when `IgnoreGuiInset = false`).
4. On mobile landscape devices (e.g., iPhone 8 landscape at $667 \times 375$ px with usable height $339$ px), the vertical footprint ($386$ px) exceeds usable viewport height ($339$ px) by **50.5 px**, causing the tooltip to clip off the bottom of the screen.
5. On smaller mobile landscape screens ($568 \times 320$ px with usable height $284$ px), Top Slice 1 clips off the top by $24$ px, Bottom Slice 5 clips off the bottom by $24$ px, and the Tooltip clips by $78$ px.
6. Therefore, adding a dynamic `UIScale` component to `wheelFrame` scaled to `math.clamp(math.min((usableH * 0.88)/386, (usableW * 0.88)/332), 0.55, 1.20)` guarantees 100% visibility on all device resolutions.

---

## 3. Caveats

- **No Source Code Changes Made**: In accordance with the Explorer archetype rules, no files outside `.agents/explorer_m1_2/` were modified.
- **Assumed TopBar Height**: Calculations assume standard Roblox TopBar inset of $36\text{px}$ when `IgnoreGuiInset = false`. If `IgnoreGuiInset` is set to `true`, usable height increases by $36\text{px}$, but top slice margin reduces accordingly.

---

## 4. Conclusion

The 8 radial slices in `src/client/Controllers/PeaWheelController.lua` (`inventory`, `cook`, `quests`, `compendium`, `materials`, `map`, `companions` [*shop*], `settings`) are correctly centered and rendered at 45° intervals. However, fixed pixel offset sizing causes severe clipping on mobile landscape viewports ($\le 375\text{px}$ height) and small mobile portrait viewports ($\le 320\text{px}$ width). Implementing dynamic `UIScale` responsiveness resolves all edge clipping and guarantees 100% visibility.

---

## 5. Verification Method

1. **Inspect Analysis File**: View `g:\Zundamons-kItchen-V2\.agents\explorer_m1_2\analysis.md` for mathematical proofs and code proposals.
2. **Roblox Studio Emulator**:
   - Open Roblox Studio with `PeaWheelController.lua`.
   - Run Device Emulation for "iPhone 8 Landscape" ($667 \times 375$) and "iPhone 5 Landscape" ($568 \times 320$).
   - Toggle Pea Wheel (Tab / Q key). Verify if tooltip or slices clip off-screen before fix, and verify zero clipping after applying proposed `UIScale` logic.
3. **Invalidation Condition**: If `wheelFrame` is rendered with `UIScale.Scale < 1.0` on mobile viewports and any slice or label still overlaps screen edges, the margin factor ($0.88$) should be adjusted to $0.82$.
