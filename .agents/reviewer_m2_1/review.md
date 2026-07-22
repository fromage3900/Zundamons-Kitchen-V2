# Code Review Report: Milestone 2 Window Manager Engine (`site/window_manager.js`)

**Reviewer**: Reviewer 1 (`reviewer_m2_1`)  
**Date**: 2026-07-22  
**Target**: `site/window_manager.js`, `site/index.html`  
**Verdict**: **APPROVE**  

---

## Executive Summary

An independent code review and automated DOM test suite execution was conducted for the Milestone 2 Window Manager Engine (`site/window_manager.js`). The implementation fully satisfies all 4 core requirements:
1. **7 Window Registration**: All 7 managed windows (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`) are correctly identified, registered in the `WindowManager` instance Map, and linked to DOM elements.
2. **Z-Index Stack & Focus Fallback**: `bringToFront()` correctly increments z-index and manages active/inactive classes. `transferFocusToTopVisibleWindow()` correctly falls back to the top visible window ordered by z-index when windows are closed or minimized.
3. **Drag & Touch Clamping**: Pointer and touch drag engine bound to `.window-header` applies viewport boundary clamping (`Math.max(0, Math.min(pos, max))`) preventing windows from being dragged off-screen.
4. **Maximize/Restore & Taskbar Sync**: Geometry memory saves inline/computed dimensions prior to maxing (`0px, 0px, 100%, calc(100vh - 36px)`), taskbar buttons dynamically reflect active/minimized states, Start Menu popover toggles on `#start-btn` / `Ctrl+Esc` / `Escape`, and `exportScreenGuiLayout()` generates a compliant Roblox `ScreenGui` JSON hierarchy with `ResetOnSpawn: false`.

No integrity violations, facades, or dummy implementations were detected.

---

## Detailed Evaluation by Dimension

### 1. Requirement Verification

#### Requirement 1: 7 Window Registration
- **Code Inspection**: `registerWindows()` in `site/window_manager.js` queries all `.window` elements and explicitly ensures the 7 target window IDs (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`) are registered in `this.windows`.
- **DOM Inspection**: `site/index.html` contains all 7 window elements under `#window-container`.
- **Test Result**: Verified via JSDOM test suite — `wm.windows.size === 7`. All 7 elements resolve properly via `wm.getWindow()`.

#### Requirement 2: Z-Index Stack & Focus Fallback
- **Code Inspection**:
  - `bringToFront(winTarget)` increments `this.currentZIndex`, assigns `winEl.style.zIndex`, toggles `active-window` / `window-active` classes, sets `this.activeWindow`, and triggers `updateTaskbar()`.
  - `transferFocusToTopVisibleWindow()` scans all registered visible windows (where `!isHidden`), identifies the highest `zIndex`, and calls `bringToFront(topWin)`. If no window is visible, `activeWindow` is reset to `null` and taskbar state updates.
- **Test Result**: Verified via JSDOM test suite — closing or minimizing top windows sequentially shifts focus back to the next highest visible window in the stack.

#### Requirement 3: Drag & Touch Clamping
- **Code Inspection**:
  - `setupDragEngine(win, header)` attaches both `mousedown` and `touchstart` event listeners to `.window-header`.
  - Ignores drag triggers on `.window-controls` and `.win-btn`.
  - Calculates movement delta (`dx`, `dy`) and applies the viewport clamping formula:
    `const maxLeft = Math.max(0, viewportWidth - winWidth)`  
    `const maxTop = Math.max(0, viewportHeight - winHeight)`  
    `const clampedLeft = Math.max(0, Math.min(rawLeft, maxLeft))`  
    `const clampedTop = Math.max(0, Math.min(rawTop, maxTop))`
- **Test Result**: Verified via JSDOM test suite — mousemove events with out-of-bound coordinates (`-400, -400` and `2000, 2000`) were successfully clamped to `(0, 0)` and `(344, 328)`.

#### Requirement 4: Maximize/Restore & Taskbar Sync
- **Code Inspection**:
  - `maximizeWindow(winTarget)` saves `dataset.prevLeft`, `prevTop`, `prevWidth`, `prevHeight` before switching to maximized state. Toggling maximize restores saved dataset values.
  - `updateTaskbar()` builds taskbar items inside `#taskbar-windows`, setting `active` or `minimized` CSS classes and toggling minimize/restore on click.
  - `bindStartMenuEvents()` & `bindKeyboardShortcuts()` handle `#start-btn` clicks, outside click dismissal, `Ctrl+Esc` shortcut toggle, and `Escape` key dismissal.
  - `exportScreenGuiLayout()` returns a structured Roblox `ScreenGui` payload with `ResetOnSpawn: false` and `ZIndexBehavior: "Sibling"`.
- **Test Result**: All features verified via JSDOM test suite.

---

## Adversarial Stress-Test Findings & Critic Analysis

### Finding 1 (Minor / Advisory): Z-Index Capping without Normalization
- **Observation**: `this.currentZIndex` is capped at `this.maxZIndex` (8999) via `Math.min(this.maxZIndex, this.currentZIndex + 1)`.
- **Risk**: If a user clicks between windows 8,899 times without reloading the page, all active windows will eventually share `z-index = 8999`, causing z-index ordering to fall back to DOM order.
- **Severity**: Low (edge case under extreme interaction longevity).
- **Recommendation**: Add a reset/normalization routine when `currentZIndex` approaches `maxZIndex` to re-scale all window z-indexes while preserving relative stacking order.

### Finding 2 (Informational): DOM Re-rendering in `updateTaskbar()`
- **Observation**: `updateTaskbar()` sets `this.taskbarWindows.innerHTML = ''` and recreates button elements on every focus/visibility state change.
- **Risk**: External references to taskbar button DOM elements will become detached after window focus shifts.
- **Severity**: Low (WindowManager internally manages click handlers on creation).

---

## Integrity Check Verification

| Check | Result | Details |
|---|---|---|
| Hardcoded Test Results | **PASS** | No hardcoded scores or fake returns found. |
| Facade / Dummy Logic | **PASS** | Real DOM event listeners, z-index calculation, and geometry memory implemented. |
| Task Shortcuts / Bypasses | **PASS** | Built strictly to specifications. |
| Self-Certifying Work | **PASS** | Verified via independent automated JSDOM test script (`test_window_manager_sim.js`). |

---

## Verification Method

Run the independent JSDOM test suite from the project root:
```bash
node .agents/reviewer_m2_1/test_window_manager_sim.js
```
Expected output: All 7 test categories pass successfully with exit code 0.

---

## Conclusion

**Verdict: APPROVE**  
The Milestone 2 Window Manager Engine (`site/window_manager.js`) is robust, fully compliant with requirements, clean in design, and verified by independent automated testing.
