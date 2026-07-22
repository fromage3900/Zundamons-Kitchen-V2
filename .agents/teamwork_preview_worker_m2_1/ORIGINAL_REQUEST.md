## 2026-07-21T20:47:01Z
You are Worker 2 for Milestone 2 of Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub.
Working Directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2_1
Target Site Directory: g:\Zundamons-kItchen-V2\site

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your objective:
Implement `site/window_manager.js` and apply audio engine remediation in `site/assets/audio_engine.js` and `site/index.html`:

1. `site/window_manager.js`:
   - Create ES6 modular `WindowManager` class managing windows: `ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `QuickStart.txt`.
   - Dual Mouse (`mousedown`, `mousemove`, `mouseup`) and Touch (`touchstart`, `touchmove`, `touchend`) drag engine with viewport boundary clamping (`Math.max(0, Math.min(pos, max))`).
   - Dynamic z-index depth stack (100 to 8999) with `.window-active` and `.window-inactive` state synchronization.
   - Active Focus Fallback (`transferFocusToTopVisibleWindow()`): Automatically focus the top-most remaining visible window when a window is closed or minimized.
   - Minimize, Maximize, and Restore state engine with geometry memory (`dataset.prevLeft`, `dataset.prevTop`, `dataset.prevWidth`, `dataset.prevHeight`).
   - Taskbar Sync: Taskbar buttons MUST retain minimized windows (`#taskbar-windows`). Clicking taskbar buttons: active window -> minimizes; inactive or minimized window -> restores & focuses.
   - Keyboard Shortcuts: Global `Ctrl+Esc` and `Escape` keydown listeners toggling Start Menu (`#start-menu`).
   - Roblox UI Export Hook: Expose `WindowManager.exportScreenGuiLayout()` returning JSON layout structure mapping windows directly to Roblox ScreenGui frame hierarchies.

2. `site/assets/audio_engine.js`:
   - In `ZundaAudio.init()`, read `localStorage.getItem('zunda_os_volume')` and set `this.volume = parseFloat(savedVol)`.
   - In `playClickSFX()`, add fallback gain ramp down (0.15 -> 0.001 over 0.03s) for invalid/unknown variants.
   - In `startCozyBGM()` and `stopCozyBGM()`, handle `bgmStopTimeout` with `clearTimeout()` to prevent rapid toggle race conditions.

3. `site/index.html`:
   - Update script tags to load `<script src="assets/audio_engine.js"></script>` and `<script src="window_manager.js"></script>`, ensuring clean modular initialization of `WindowManager`.

Verification requirements:
- Run `node -c site/window_manager.js` and `node -c site/assets/audio_engine.js` (exit code 0).
- Confirm zero external script or style dependencies.
- Document implementation details in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2_1\changes.md` and `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2_1\handoff.md`. Send a message when completed.
