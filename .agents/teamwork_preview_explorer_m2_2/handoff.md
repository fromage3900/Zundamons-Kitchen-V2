# Handoff Report: Zunda-OS 95 Window Manager Architecture & Design Specification

**Agent**: Explorer 2  
**Milestone**: Milestone 2 — Modular Desktop & Window Manager Engine  
**Target File**: `site/window_manager.js`  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\`  

---

## 1. Observation

### 1.1 Existing Layout & Code Structure
* **`site/index.html`**:
  * Lines 71–261 define `#window-container` holding four core Zunda-OS 95 application windows:
    1. `#window-zundacli` (`ZundaCLI.exe`) — line 74
    2. `#window-cookbook` (`Cookbook.app`) — line 108
    3. `#window-vntalk` (`VNTalk.app`) — line 182
    4. `#window-quickstart` (`QuickStart.txt`) — line 219
  * Lines 318–322 define `#taskbar-windows` container for active taskbar window items.
  * Lines 265–315 define `#taskbar` and `#start-menu` popover.
  * Lines 340–550 contain an inline JavaScript prototype for basic window dragging and event handling.
* **`site/style.css`**:
  * Lines 286–332 define `.window`, `.window.active-window`, `.window.window-active`, `.window.inactive-window`, `.window.window-inactive`, and `.window.maximized`.
  * Lines 711–871 define `#taskbar`, `#start-menu`, `.taskbar-item`, `.taskbar-item.active`.

### 1.2 Identified Gaps & Deficiencies in Prototype Inline Code
1. **Focus Depth Stack Unbounded Increment**:
   * Inline script line 382 uses `zIndexCount++` naively. Clicking windows repeatedly causes `z-index` to grow without bound, risking z-index overflow past the taskbar (`z-index: 9000`).
2. **Missing Active Focus Fallback**:
   * Inline script lines 405–418 (`closeWindow` and `minimizeWindow`) hide the target window, but **fail to transfer focus** to the top-most remaining visible window. When the active window is closed/minimized, no window remains focused (`.window-active`).
3. **Taskbar Button Retention Bug on Minimize**:
   * Inline script line 434 (`if (!win.classList.contains('hidden'))`) filtered out hidden windows when rebuilding `#taskbar-windows`. When a window was minimized, its taskbar button disappeared completely from `#taskbar-windows`, breaking the Win95 requirement that taskbar buttons MUST retain minimized windows so users can restore them.
4. **Missing Keyboard Shortcuts**:
   * Prototype inline script had no listeners for `Ctrl+Esc` or `Escape` keypresses to toggle `#start-menu`.
5. **No Roblox ScreenGui Layout Exporter**:
   * Prototype inline script lacked layout export hooks for Roblox ScreenGui conversion.

---

## 2. Logic Chain

1. **Depth Stack Management**:
   * Maintaining a `focusStack` array of window DOM elements ordered by focus recency allows deterministic `z-index` re-assignment (`100 + i`). This guarantees windows stay within range `100–8999`, safely below `#taskbar` (`z-index: 9000`) and `#start-menu` (`z-index: 9500`).
   * Applying both `.window-active` / `.active-window` and `.window-inactive` / `.window-inactive` ensures complete CSS compatibility across all existing style declarations in `style.css`.

2. **Active Focus Fallback**:
   * When closing or minimizing the currently focused window, filtering `focusStack` for remaining visible windows (`!hidden` and `!window-minimized`) and focusing the top-most remaining element guarantees a seamless desktop experience without orphaned focus states.

3. **Minimize / Maximize / Restore State Engine & Taskbar Sync**:
   * Adding `.window-minimized` to minimized windows while keeping taskbar buttons visible in `#taskbar-windows` fulfills the retro Windows 95 taskbar behavior requirement.
   * Storing original cascaded coordinates in HTML5 dataset properties (`dataset.prevTop`, `dataset.prevLeft`, `dataset.prevWidth`, `dataset.prevHeight`) allows flawless Maximize (`.maximized`) and Restore transitions.
   * Updating taskbar button click behavior:
     * Active window taskbar button click -> Minimize.
     * Inactive visible window taskbar button click -> Focus & bring to front.
     * Minimized window taskbar button click -> Restore & focus.

4. **Keyboard Shortcuts Interceptor**:
   * Listening to global `keydown` for `Ctrl + Esc` toggles `#start-menu` and updates `#start-btn` active class (`.start-btn-active`).
   * Listening for `Escape` closes `#start-menu` when open.

5. **Roblox ScreenGui Export Hook**:
   * Providing `exportRobloxScreenGuiLayout()` formats all open/minimized window dimensions into Luau `UDim2` dictionary format, satisfying AGENTS.md Rule 4 and Milestone 2 requirements.

---

## 3. Caveats

* **Read-Only Explorer Investigation**: Code implementation in `site/window_manager.js` is delegated to the Worker agent. This report provides the complete architecture and verification specification.
* **Audio Synthesizer Dependency**: Audio trigger calls (`playWindowSFX`, `playClickSFX`) check `typeof window.playWindowSFX === 'function'` before invoking to ensure graceful operation even if `assets/audio_engine.js` is omitted or delayed.
* **Touch Drag Clamping**: Touch event handlers (`touchstart`, `touchmove`, `touchend`) must mirror mouse dragging logic and clamp coordinates within `#desktop` bounds.

---

## 4. Conclusion

The architecture for `site/window_manager.js` has been fully designed and specified in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\analysis.md`. 

Key deliverables provided in specification:
1. `WindowManager` class structure with clean API methods (`init`, `focusWindow`, `minimizeWindow`, `maximizeWindow`, `restoreWindow`, `closeWindow`, `openWindow`, `syncTaskbar`, `toggleStartMenu`, `handleKeyDown`, `exportRobloxScreenGuiLayout`).
2. Data structures (`focusStack` array, window geometry datasets).
3. Active Focus Fallback algorithm.
4. Taskbar retention & toggle logic for minimized windows.
5. Keyboard shortcuts (`Ctrl+Esc`, `Escape`).
6. Roblox ScreenGui UDim2 export mapping.

---

## 5. Verification Method

To verify the implementation of `site/window_manager.js`:

1. **Inspect Analysis File**:
   * Confirm `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\analysis.md` exists and contains complete design specs.

2. **Verify Focus Depth Stack & Fallback**:
   * In browser preview, open multiple windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`). Click each window to confirm `z-index` updates and active header styling toggles.
   * Close or minimize the top active window. Verify focus automatically transfers to the next visible top window and its taskbar button becomes highlighted (`.active`).

3. **Verify Taskbar Sync & Minimized Retention**:
   * Click minimize button (`_`) on a window. Verify window content hides but taskbar button remains in `#taskbar-windows`.
   * Click the taskbar button for the minimized window. Verify window un-minimizes and receives active focus.
   * Click the taskbar button for an active window. Verify window minimizes.

4. **Verify Maximize / Restore**:
   * Click maximize button (`🗖`). Verify window resizes to full viewport and icon changes to restore (`🗗`). Click again to verify window returns to original size and position.

5. **Verify Keyboard Shortcuts**:
   * Press `Ctrl+Esc`. Verify Start Menu opens/toggles.
   * Press `Escape` while Start Menu is open. Verify Start Menu closes.
