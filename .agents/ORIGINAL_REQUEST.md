# Original User Request

## 2026-07-23T03:24:55Z

<USER_REQUEST>
Overhaul and fix the UI system for Zundamon's Kitchen V2, ensuring the Pea Wheel radial menu opens centered on-screen (eliminating off-screen invisibility), fixing double-toggle keybind conflicts, optimizing startup UI loading performance, and compiling the place via Rojo.

Working directory: g:\Zundamons-kItchen-V2

## Requirements

### R1. Centered Pea Wheel Radial Menu & Visibility
Fix PeaWheelController.lua:
- Center the Pea Wheel radial menu overlay in the middle of the screen (Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5)) when opened via Tab key, Q key, or hub button.
- Ensure all 8 radial slices (inventory, cook, quests, compendium, materials, map, shop, settings) are 100% visible on screen without clipping off-edge.

### R2. Single Source of Truth Keybind Dispatching
Fix keybind conflicts across client UI scripts:
- Deduplicate UserInputService.InputBegan listeners so UIActionRegistry.lua acts as the single source of truth.
- Remove duplicate InputBegan listeners in PouchScript.client.lua, CraftingScript.client.lua, StoreScript.client.lua, etc. to prevent double-toggle opening/closing bugs on keypress.

### R3. Fast UI Boot & Traversal Performance
Optimize 000_LegacyOverlayCleanup.client.lua and startup scripts:
- Consolidate multiple GetDescendants() loops into a single single-pass tree traversal on PlayerGui load.
- Eliminate blocking WaitForChild delays on UI panel initialization.

### R4. Rojo Build Compilation & Verification
Compile all changes directly into build/Zundamons-kItchen.rbxl.

## Acceptance Criteria

### UI & Keybind Validation
- [ ] Pressing Tab, Q, or clicking the Pea Wheel hub opens the radial menu centered on screen with all 8 slice icons visible.
- [ ] Keybinds (I, K, J, C, M, P, B, F1) toggle their respective panels ON/OFF cleanly on single keypress without double-toggling.
- [ ] rojo build default.project.json -o build/Zundamons-kItchen.rbxl compiles with 0 errors.
- [ ] python scripts/preflight_audit.py passes with 0 errors.
</USER_REQUEST>
