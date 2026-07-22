# Adversarial Challenge Report — Zunda-OS 95 CLI Launch Page & Creative Hub (Milestone 1)

**Target Directory**: `g:\Zundamons-kItchen-V2\site`  
**Reviewer**: Challenger 2 (Empirical Challenger)  
**Date**: 2026-07-21  

---

## Challenge Summary

**Overall risk assessment**: **MEDIUM**  

While zero-dependency compliance and SVG vector XML validity are 100% compliant, empirical stress testing surfaced **two significant layout and CSS cascade failure modes**:
1. **Mobile Viewport Taskbar Overlap**: `--taskbar-height` is not updated inside `@media screen and (max-width: 768px)` despite `#taskbar` height increasing from 38px to 42px. This causes fixed taskbars to overlap the bottom 4px of modal windows and miscalculates start menu positioning.
2. **Inert Theme Toggle Feature**: `index.html` contains JavaScript logic to toggle `data-theme` between `zunda-classic` and `zunda-dark`, but `style.css` contains zero CSS selectors or overrides for `[data-theme="zunda-dark"]`. Clicking the button changes the HTML attribute but produces zero visual change.

---

## Challenges

### [Medium] Challenge 1: Mobile Taskbar Height Variable Cascade Mismatch (Layout Integrity)

- **Assumption challenged**: `--taskbar-height` in `:root` accurately reflects `#taskbar` element height across all viewports.
- **Attack scenario**: Viewing the application on mobile viewports (<=768px) such as 320px (iPhone SE) or 768px (iPad portrait).
- **Blast radius**: 
  - `:root` declares `--taskbar-height: 38px;`.
  - `@media screen and (max-width: 768px)` increases `#taskbar` height to `42px`.
  - `--taskbar-height` variable is NOT updated inside `@media screen and (max-width: 768px)`.
  - Mobile modal windows use `height: calc(100vh - var(--taskbar-height)) !important;` -> evaluates to `100vh - 38px`.
  - The fixed taskbar sits from `y = 100vh - 42px` to `100vh`.
  - **Result**: The taskbar overlaps the bottom 4px of mobile modal window bodies. Additionally, `#start-menu` positioning (`bottom: calc(var(--taskbar-height) + 2px);` = 40px) overlaps 2px with the top edge of the 42px taskbar.
- **Mitigation**: Update `--taskbar-height` inside the mobile media query:
  ```css
  @media screen and (max-width: 768px) {
    :root {
      --taskbar-height: 42px;
    }
    ...
  }
  ```

---

### [Medium] Challenge 2: Inert Theme Switcher Cascade Gap (CSS Cascade)

- **Assumption challenged**: Clicking "Toggle Theme Mode" in the Start Menu changes the application theme.
- **Attack scenario**: User clicks "Toggle Theme Mode" in the Start Menu (`#menu-toggle-theme`).
- **Blast radius**: 
  - `index.html` lines 574-582 toggle the `data-theme` attribute on `document.documentElement` between `zunda-classic` and `zunda-dark`.
  - `style.css` has zero rules for `[data-theme="zunda-dark"]` or `:root[data-theme="zunda-dark"]`.
  - **Result**: The HTML attribute changes, but zero visual color or theme changes occur.
- **Mitigation**: Add theme override rules in `style.css`:
  ```css
  [data-theme="zunda-dark"] {
    --zunda-bg: #1b381e;
    --win-bg: #223824;
    --win-content-bg: #142416;
    --win-border-light: #3e6341;
    --win-border-shadow: #0b170c;
    /* Dark theme palette overrides */
  }
  ```

---

### [Low] Challenge 3: Lack of Touch Event Listeners for Mobile Window Dragging

- **Assumption challenged**: Window dragging works identically on desktop and mobile devices.
- **Attack scenario**: User attempts to drag a window titlebar on a touch device.
- **Blast radius**: 
  - Window manager script binds `mousedown`, `mousemove`, `mouseup` to header, but omits `touchstart`, `touchmove`, `touchend`.
  - On mobile (<=768px), CSS `width: 100vw !important`, `top: 0 !important`, `left: 0 !important` prevents windows from being dragged offscreen, masking the issue. On tablets (769px-1024px) where CSS full-screen fallback does not apply, touch dragging fails.
- **Mitigation**: Add touch event listeners or pointer events (`pointerdown`, `pointermove`, `pointerup`) to window header dragging logic.

---

## Stress Test Results

| Scenario | Tested Viewport / State | Expected Behavior | Actual Behavior | Pass / Fail |
|---|---|---|---|---|
| Viewport 1920px Desktop | 1920x1080 | Floating windows, full desktop layout | Renders cleanly, icons float, windows stack properly | **PASS** |
| Viewport 1024px Laptop | 1024x768 | Window constraints max 92vw / 80vh | Renders cleanly, taskbar buttons constrain to 90px-130px | **PASS** |
| Viewport 768px Mobile/Tablet | 768x1024 | Mobile modal fallback window covers viewport above taskbar | Window height equals `100vh - 38px`, taskbar height is 42px. 4px overlap occurs at window bottom | **FAIL** |
| Viewport 320px Mobile | 320x568 | Mobile modal window fits screen, taskbar fits | Taskbar items scroll horizontally, window bottom 4px covered by taskbar | **FAIL** |
| Theme Toggle Button Click | User clicks "Toggle Theme Mode" | UI theme updates to dark edamame theme | `data-theme="zunda-dark"` set on `<html>`, zero visual change in CSS | **FAIL** |
| SVG Vector Rendering | 4 SVG assets in `site/assets/` | Clean XML vector without external references | Clean XML, valid viewBox, 0 `<image>`, 0 `xlink:href`, 0 remote calls | **PASS** |
| Zero-Dependency Network Audit | All 7 files in `site/` | 0 external network requests, 0 external font imports | 0 fetch/xhr/ws, 0 external font imports, 100% local Web Audio synthesis | **PASS** |

---

## Unchallenged Areas

- **Web Audio Synthesis**: `assets/audio_engine.js` synthesis algorithms (oscillators, gains, audio nodes) were audited for zero network calls, but audio frequency harmonics and sound quality were not subjected to acoustic analysis.
