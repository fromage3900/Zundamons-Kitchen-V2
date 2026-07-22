# Empirical Challenge Report & Verification Log

**Target**: Zunda-OS 95 CLI Launch Page & Creative Hub (`site/index.html`, `site/assets/audio_engine.js`)  
**Date**: 2026-07-22  
**Tester**: Challenger 1 (Empirical Challenger)  
**Overall Verdict**: **FAILED** (12 FAILED / 25 TOTAL TESTS)

---

## Challenge Summary

**Overall risk assessment**: **HIGH**

Empirical stress testing of `site/index.html` and `site/assets/audio_engine.js` revealed 9 distinct failure modes across window dragging, focus stacking, taskbar synchronization, start menu accessibility, and audio engine persistence/synthesis. While core UI layout and basic click handlers function under happy-path scenarios, boundary stress testing exposed critical usability, mobile compatibility, and state persistence defects.

---

## Confirmed Vulnerabilities & Failures

### 1. [High] Unrestricted Window Drag Boundary (Off-Screen Loss)
- **Assumption challenged**: Windows remain within visible viewport bounds during mouse dragging.
- **Attack scenario**: Drag window header to negative mouse coordinates (`clientX < 0`, `clientY < 0`) or beyond viewport width/height (`clientX > 2000`).
- **Blast radius**: `win.style.left` and `win.style.top` receive un-clamped values (e.g. `left: -1100px, top: -1100px`), causing windows to disappear off-screen. Users lose access to window controls and header drag bar, requiring a full page refresh to recover.
- **Mitigation**: Wrap drag calculations in `Math.max(0, Math.min(newLeft, window.innerWidth - winWidth))` and `Math.max(0, Math.min(newTop, window.innerHeight - headerHeight))`.

### 2. [High] Missing Touch Event Listeners for Window Dragging (Mobile Incompatibility)
- **Assumption challenged**: Window dragging works across desktop and mobile touch devices.
- **Attack scenario**: Attempt to drag window header on mobile viewport using touch gestures (`touchstart`, `touchmove`, `touchend`).
- **Blast radius**: Window header script in `site/index.html` only attaches `mousedown`, `mousemove`, and `mouseup` listeners. Touch events are completely unhandled, rendering window dragging impossible on mobile/tablet devices.
- **Mitigation**: Add equivalent `touchstart`, `touchmove`, and `touchend` event handlers to window headers.

### 3. [High] Taskbar Deletes Minimized Windows (Win95 UX Violation)
- **Assumption challenged**: Taskbar synchronization preserves access to minimized windows.
- **Attack scenario**: Click the minimize `_` button on any window.
- **Blast radius**: `minimizeWindow(win)` adds `.hidden` to the window element and calls `updateTaskbar()`. `updateTaskbar()` filters out all windows containing `.hidden`. Consequently, the minimized window's taskbar button is completely removed from `#taskbar-windows`, preventing users from un-minimizing or restoring the window from the taskbar.
- **Mitigation**: Update `updateTaskbar()` to display buttons for all non-closed windows (including `.hidden` minimized windows), styling minimized taskbar buttons as inactive.

### 4. [Medium] No Active Window Fallback on Close / Minimize
- **Assumption challenged**: Closing or minimizing the active window automatically shifts focus to the next top visible window.
- **Attack scenario**: Open multiple windows (e.g., CLI and Cookbook), focus Cookbook, and click Cookbook's close `✕` or minimize `_` button.
- **Blast radius**: The top active window becomes `.hidden`, but `closeWindow()` and `minimizeWindow()` do not activate any remaining open window. The UI is left with `Remaining active window: NONE`, leaving remaining windows in `.window-inactive` visual state with inactive taskbar buttons.
- **Mitigation**: After closing or minimizing a window, inspect remaining visible windows and call `bringToFront()` on the window with the highest `z-index`.

### 5. [Medium] Advertised Keyboard Shortcuts Missing (Ctrl+Esc / Escape)
- **Assumption challenged**: Advertised keyboard shortcuts for Start Menu operate as documented.
- **Attack scenario**: Press `Ctrl+Esc` or `Escape` while browsing the desktop as stated in `QuickStart.txt` (line 242).
- **Blast radius**: No `keydown` listener exists in `site/index.html` for `Ctrl+Esc` or `Escape`. Users following `QuickStart.txt` instructions experience non-responsive keyboard controls.
- **Mitigation**: Add a global `keydown` event listener checking for `e.ctrlKey && e.key === 'Escape'` or `e.key === 'Escape'` to toggle/close the Start Menu.

### 6. [Medium] Audio Engine Ignores Saved LocalStorage Volume State
- **Assumption challenged**: User-configured master volume persists across browser sessions.
- **Attack scenario**: Call `ZundaAudio.setVolume(0.3)` (which writes `localStorage.setItem('zunda_os_volume', '0.3')`), then reload the page or call `ZundaAudio.init()`.
- **Blast radius**: `ZundaAudio.init()` only checks `localStorage.getItem('zunda_os_muted')` and never reads `zunda_os_volume`. Volume resets to default `0.7` on every initialization.
- **Mitigation**: Read `zunda_os_volume` in `ZundaAudio.init()` and invoke `this.setVolume(parseFloat(savedVol))`.

### 7. [Medium] Full-Volume Square Wave Beep on Invalid SFX Variant
- **Assumption challenged**: SFX functions handle unexpected or fallback parameters gracefully.
- **Attack scenario**: Invoke `playClickSFX('invalid_variant')` or `playClickSFX(null)`.
- **Blast radius**: `osc.type` defaults to `'square'`, but none of the parameter branches (`'down'`, `'up'`, `'start'`) execute. `gain.gain.setValueAtTime` is never scheduled, causing Web Audio API's default GainNode value of `1.0` (100% full volume) to play an un-attenuated 440Hz square wave beep.
- **Mitigation**: Add a default fallback branch in `playClickSFX` setting standard gain attenuation and frequency ramp.

### 8. [Medium] Rapid BGM Toggle Race Condition (Drone Oscillator Termination)
- **Assumption challenged**: BGM toggle handles rapid user clicks cleanly.
- **Attack scenario**: Call `toggleCozyBGM()` (Start), `toggleCozyBGM()` (Stop), and `toggleCozyBGM()` (Start) within 1000ms.
- **Blast radius**: `stopCozyBGM()` queues a 1050ms `setTimeout` to stop pad oscillators. When the user rapidly restarts BGM, new oscillators are assigned to `ZundaAudio.bgmPadOscs`. The pending `setTimeout` from the previous stop fires 1050ms later, stopping the NEW active pad oscillators and setting `bgmPadOscs` to `null`, leaving BGM playing arpeggios without background drone pads.
- **Mitigation**: Store timer handle `bgmStopTimeout` and call `clearTimeout(bgmStopTimeout)` inside `startCozyBGM()`.

---

## Empirical Test Results Log (25 Execution Tests)

| Test ID | Suite | Scenario Description | Expected Behavior | Actual Behavior | Result |
|---|---|---|---|---|---|
| **TEST-01** | Window Drag | Drag window header with mouse | Window position updates by delta | Window moves to left=210px, top=240px | **PASS** |
| **TEST-02** | Window Drag | Drag window off top/left (`clientX: -1000`) | Position clamped to min 0px | Window moves to `left: -1100px, top: -1100px` | **FAIL** |
| **TEST-03** | Window Drag | Drag window off right/bottom (`clientX: 10000`) | Position clamped to viewport | Window moves to `left: 9900px, top: 9900px` | **FAIL** |
| **TEST-04** | Window Drag | Touch drag gesture on mobile | Window position updates | Touch event listeners missing; drag fails | **FAIL** |
| **TEST-05** | Window Drag | Mousemove/mouseup without mousedown | Ignored cleanly without errors | No console errors thrown | **PASS** |
| **TEST-06** | Focus Stacking | Click window header of inactive window | Z-index increases, `.window-active` set | Z-index incremented, classes toggled correctly | **PASS** |
| **TEST-07** | Focus Stacking | Sequential window clicks | Stacking order updates monotonically | Z-index increases sequentially | **PASS** |
| **TEST-08** | Focus Stacking | Close top active window | Focus falls back to next top window | Active state left as NONE (no fallback) | **FAIL** |
| **TEST-09** | Window Controls | Click maximize `🗖` button | Toggles `.maximized` class | `.maximized` class toggled on window | **PASS** |
| **TEST-10** | Window Controls | Click minimize `_` button | Window receives `.hidden` class | Window hidden correctly | **PASS** |
| **TEST-11** | Taskbar Sync | Minimize window and check taskbar | Minimized button remains in taskbar | Button deleted from `#taskbar-windows` | **FAIL** |
| **TEST-12** | Taskbar Sync | Click taskbar item for minimized window | Unminimizes window | Window restored if button present | **PASS** |
| **TEST-13** | Taskbar Sync | Click close `✕` button | Window hidden, taskbar button removed | Taskbar button removed | **PASS** |
| **TEST-14** | Start Menu | Click `#start-btn` | Toggles `#start-menu` visibility | Start menu opens/closes correctly | **PASS** |
| **TEST-15** | Start Menu | Click outside start menu | Auto-closes start menu | Start menu closes on outside click | **PASS** |
| **TEST-16** | Start Menu | Click menu item (Cookbook.app) | Opens window & closes menu | Window opens, menu closes | **PASS** |
| **TEST-17** | Start Menu | Press `Ctrl+Esc` or `Escape` | Toggles/closes start menu | No keyboard listener exists; shortcut ignored | **FAIL** |
| **TEST-18** | Audio Engine | `ZundaAudio.init()` | AudioContext & Gain nodes initialized | Master, SFX, BGM gain nodes created | **PASS** |
| **TEST-19** | Audio Persistence | Load saved mute state from LocalStorage | `isMuted` restored on init | Saved mute state loaded correctly | **PASS** |
| **TEST-20** | Audio Persistence | Load saved volume state from LocalStorage | `volume` restored on init | Volume ignored; resets to 0.7 | **FAIL** |
| **TEST-21** | Audio Synthesis | `playClickSFX('down' / 'up' / 'start')` | Synthesizes click audio ramps | Oscillators & Gain ramps created | **PASS** |
| **TEST-22** | Audio Synthesis | `playClickSFX('invalid')` | Fallback gain attenuation applied | Gain not set; plays 100% volume square wave | **FAIL** |
| **TEST-23** | Audio Synthesis | `playWindowSFX('focus' / 'close' / etc.)` | Synthesizes window sound effects | Window SFX synthesized properly | **PASS** |
| **TEST-24** | Audio Synthesis | `playKeySFX('a' / 'Enter')` | Synthesizes keyboard clicks | Typing sound effects synthesized | **PASS** |
| **TEST-25** | Audio Synthesis | `toggleCozyBGM()` rapid toggle | BGM pad oscillators preserved | `setTimeout` kills active BGM pad oscillators | **FAIL** |

---

## Unchallenged Areas

- **CSS visual styling & CRT scanline shader rendering**: Evaluated for DOM logic state, but visual pixel-perfect layout on physical CRT hardware was not tested.
- **Canvas particle FPS performance under low-end CPU throttling**: Tested canvas animation lifecycle, but not low-end GPU benchmark rendering.
