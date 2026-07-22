# Handoff Report — Milestone 1 Zunda-OS 95 CLI Launch Page Empirical Testing

**Agent**: Challenger 1 (`teamwork_preview_challenger_m1_1`)  
**Role**: Empirical Challenger (critic, specialist)  
**Date**: 2026-07-22  
**Target Files**: `site/index.html`, `site/assets/audio_engine.js`  
**Verdict**: **FAILED**

---

## 1. Observation

Direct observations obtained by writing and executing an automated empirical JSDOM test suite (`run_empirical_tests.js`) and analyzing source code in `site/index.html` and `site/assets/audio_engine.js`:

1. **Window Drag Boundary Omission**:
   - `site/index.html` lines 477–483:
     ```javascript
     function onMouseMove(e) {
         if (!isDragging) return;
         const dx = e.clientX - startX;
         const dy = e.clientY - startY;
         win.style.left = `${initialLeft + dx}px`;
         win.style.top = `${initialTop + dy}px`;
     }
     ```
   - *Test Observation*: Dragging window header with `clientX: -1000, clientY: -1000` resulted in `win.style.left = "-1100px"` and `win.style.top = "-1100px"`. Window disappears off-screen.

2. **Mobile Touch Drag Omission**:
   - `site/index.html` lines 466–494: Window header drag logic only attaches `mousedown`, `mousemove`, and `mouseup` listeners.
   - *Test Observation*: Header contains 0 listeners for `touchstart`, `touchmove`, or `touchend`. Touch gestures on mobile viewports fail to drag windows.

3. **Taskbar Minimized Window Button Deletion**:
   - `site/index.html` lines 433–457 (`updateTaskbar` function):
     ```javascript
     windows.forEach(win => {
         if (!win.classList.contains('hidden')) {
             // ... create taskbar button
         }
     });
     ```
   - *Test Observation*: Clicking minimize `_` button adds `.hidden` to window and calls `updateTaskbar()`. `updateTaskbar()` excludes all `.hidden` windows. Taskbar button is destroyed, leaving user with no way to restore minimized window from taskbar.

4. **Focus Fallback Omission on Close / Minimize**:
   - `site/index.html` lines 405–419: `closeWindow()` and `minimizeWindow()` add `.hidden` to the target window and call `updateTaskbar()`, but do not update active window class or z-index for remaining visible windows.
   - *Test Observation*: Closing the top active window leaves `Remaining active window: NONE`. Visible windows remain in `.window-inactive` state.

5. **Missing Keyboard Shortcut Listeners**:
   - `site/index.html` lines 527–592 (Start Menu controller): Zero `keydown` listeners attached for `Ctrl+Esc` or `Escape`.
   - *Test Observation*: `site/index.html` line 242 (`QuickStart.txt`) advertises `Open Start Menu: Click [Start Zunda 🫛] or press Ctrl+Esc`. Dispatching `KeyboardEvent('keydown', { key: 'Escape', ctrlKey: true })` does not trigger Start Menu.

6. **LocalStorage Volume Persistence Omission**:
   - `site/assets/audio_engine.js` lines 19–46 (`ZundaAudio.init()`):
     ```javascript
     const savedMute = localStorage.getItem('zunda_os_muted');
     if (savedMute !== null) {
       this.setMute(savedMute === 'true');
     }
     ```
   - *Test Observation*: `ZundaAudio.setVolume(val)` writes `localStorage.setItem('zunda_os_volume', ...)`, but `ZundaAudio.init()` never reads `zunda_os_volume`. Volume resets to `0.7` on init.

7. **Un-attenuated Square Wave Beep on Invalid SFX Variant**:
   - `site/assets/audio_engine.js` lines 83–117 (`playClickSFX`):
     ```javascript
     osc.type = variant === 'start' ? 'triangle' : 'square';
     if (variant === 'down') { ... }
     else if (variant === 'up') { ... }
     else if (variant === 'start') { ... }
     osc.connect(gain);
     gain.connect(ZundaAudio.sfxGain);
     osc.start(now);
     osc.stop(now + 0.03);
     ```
   - *Test Observation*: Passing an unrecognized variant (e.g. `'invalid'`) bypasses all `if` blocks. `gain.gain.setValueAtTime` is never scheduled. Web Audio API GainNode defaults to `1.0`, emitting a full-volume square wave beep.

8. **BGM Rapid Toggle Race Condition**:
   - `site/assets/audio_engine.js` lines 320–341 (`stopCozyBGM`):
     ```javascript
     setTimeout(() => {
       if (ZundaAudio.bgmPadOscs) {
         ZundaAudio.bgmPadOscs.forEach(osc => { try { osc.stop(); } catch(e){} });
         ZundaAudio.bgmPadOscs = null;
       }
     }, 1050);
     ```
   - *Test Observation*: Rapidly toggling BGM (start -> stop -> start within 500ms) re-populates `ZundaAudio.bgmPadOscs`. When the 1050ms `setTimeout` from the previous stop completes, it stops the new pad Oscillators and sets `bgmPadOscs` to `null`.

---

## 2. Logic Chain

1. *From Observation 1*: In `onMouseMove`, `win.style.left` and `win.style.top` are calculated strictly as `initialLeft + dx` and `initialTop + dy` without `Math.max` or viewport boundary limits. Therefore, dragging past screen edges moves windows off-screen, breaking window recovery.
2. *From Observation 2*: Window header drag event handlers are registered exclusively for mouse events (`mousedown`). Therefore, touch inputs on mobile screens do not trigger drag handlers, failing cross-device compatibility.
3. *From Observation 3*: `updateTaskbar()` filters `windows` array using `if (!win.classList.contains('hidden'))`. Minimized windows have `.hidden` class applied. Therefore, minimizing a window removes its taskbar button entirely, violating Windows 95 UI specifications and preventing window un-minimization from the taskbar.
4. *From Observation 4*: `closeWindow()` and `minimizeWindow()` hide the active window but do not calculate or set `.window-active` / `.active-window` on the highest remaining `z-index` window. Therefore, closing a top window leaves all remaining windows in inactive states.
5. *From Observation 5*: `site/index.html` contains text advertising `Ctrl+Esc` keyboard navigation in `QuickStart.txt`, but lacks a global `keydown` event listener for keyboard navigation. Therefore, advertised keyboard shortcuts fail to work.
6. *From Observation 6*: `ZundaAudio.init()` checks `localStorage.getItem('zunda_os_muted')` on line 42, but contains no call to `localStorage.getItem('zunda_os_volume')`. Therefore, custom volume settings are lost upon page reload.
7. *From Observation 7*: `playClickSFX` creates an oscillator and gain node regardless of `variant`, but only sets gain ramps inside specific `if/else if` blocks. Passing an unhandled variant leaves `GainNode.gain` at its default `1.0` value, producing full-volume audio output.
8. *From Observation 8*: `stopCozyBGM` schedules an asynchronous 1050ms timer to clean up pad oscillators without tracking or canceling previous timeout handles. Restarting BGM before the timer fires allows the stale timer to terminate active BGM pad oscillators.

---

## 3. Caveats

- **CSS & Rendering Engine**: Verification was performed via DOM structure, event dispatching, and Web Audio API node state inspection. Visual rendering (such as physical CRT scanlines or exact pixel layout) was not evaluated on hardware screens.
- **Review-Only Constraint**: In accordance with agent constraints, no source code fixes were applied to `site/index.html` or `site/assets/audio_engine.js`. Failure modes are handed off for developer remediation.

---

## 4. Conclusion

Empirical testing of Milestone 1 (`site/index.html` and `site/assets/audio_engine.js`) resulted in **12 FAILED tests out of 25 total execution tests**.

**Final Verdict**: **FAILED**

The implementation requires fixes for:
1. Window drag boundary clamping (preventing negative and off-screen positions).
2. Mobile touch support (`touchstart`, `touchmove`, `touchend` event handlers).
3. Taskbar button retention for minimized windows (Win95 standard behavior).
4. Active window fallback focus on window close / minimize.
5. Keyboard shortcut event listener (`Ctrl+Esc` / `Escape` for Start Menu).
6. LocalStorage volume persistence in `ZundaAudio.init()`.
7. Guard / fallback gain setting for invalid `playClickSFX` variants.
8. Cancellation of pending `setTimeout` handle when restarting BGM.

---

## 5. Verification Method

To independently verify these findings:

1. Navigate to `.agents/teamwork_preview_challenger_m1_1`
2. Run the empirical test harness command:
   ```bash
   node run_empirical_tests.js
   ```
3. Inspect output log for test results and failure details (or read `challenge.md`).
4. Invalidation conditions: The implementation is verified (PASS) if all 25 test assertions in `run_empirical_tests.js` pass with 0 failures.
