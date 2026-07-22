## 2026-07-22T08:29:25Z
<USER_REQUEST>
You are Worker 2 for Zundamon's Kitchen V2 - Milestone 2.
Working directory: `g:\Zundamons-kItchen-V2\.agents\worker_m2`

Task:
Implement Milestone 2: Interactive Desktop Window Manager & Pastel Desktop Widgets Engine.

Refer to the Explorer analysis reports:
- Explorer 1 Window Manager Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m2_1\analysis.md`
- Explorer 2 Widgets & Window Styling Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m2_2\analysis.md`
- Explorer 3 Web Audio Engine Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m2_3\analysis.md`

Your tasks:
1. Update `g:\Zundamons-kItchen-V2\site\window_manager.js`:
   - Register all 7 window IDs (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`).
   - Implement `bringToFront(id)` z-index stack management and `transferFocusToTopVisibleWindow()` focus fallback when an active window is closed or minimized.
   - Implement drag & touch movement on `.window-header` with viewport boundary clamping (`Math.max(0, Math.min(x, maxX))`).
   - Implement maximize / restore with inline geometry memory (`data-prev-left`, `data-prev-top`, `data-prev-width`, `data-prev-height`).
   - Implement dynamic taskbar buttons sync (`#taskbar-windows`), `#start-btn` popover menu toggle (`#start-menu`), `Ctrl+Esc` start menu shortcut, and `Escape` key close.
   - Implement `exportScreenGuiLayout()` for Roblox ScreenGui mapping.
2. Update `g:\Zundamons-kItchen-V2\site\style.css`:
   - Style glassmorphic window frames (`.window`), glossy Sakura Pink titlebars (`.window-header`), candy control buttons (`.win-minimize`, `.win-maximize`, `.win-close`), and pastel body frames (`.window-body`).
   - Style Desktop Widgets bar and 3 widgets: Digital Clock & Weather Widget (`#widget-clock-weather`), Lo-Fi Jukebox Widget (`#widget-jukebox`), Zundamon Desktop Sticker Widget (`#widget-zunda-sticker`).
3. Update `g:\Zundamons-kItchen-V2\site\assets\audio_engine.js`:
   - Implement native Web Audio API procedural BGM jukebox (pentatonic arpeggios, warm drone pads, sub-bass).
   - Implement Pink/White noise rain SFX generator with dual lowpass/highpass filter, LFO gain modulation, toggle & slider volume controls.
   - Implement Zundamon vocal chirp synthesizer (pitch-swept sine/triangle oscillator chirps for companion clicks, speech bubbles, minigame hits).
   - Add user interaction unlock listener on `window` (`click`, `keydown`, `touchstart`).
4. Update `g:\Zundamons-kItchen-V2\site\index.html` & `g:\Zundamons-kItchen-V2\site\app.js`:
   - Align DOM IDs (`#widget-digital-time`, `#widget-weather-pill`, `#widget-play-bgm`, `#widget-next-track`, `#rain-sfx-slider`, `#widget-zunda-sticker`).
   - Wire clock ticking, weather forecast cycling, jukebox BGM controls, rain SFX slider, and Zundamon desktop sticker click chirps & speech bubble popups.
5. Verify syntax with `node -c site/window_manager.js; node -c site/app.js; node -c site/assets/audio_engine.js; node -c site/sync_site.js`.
6. Run `node site/sync_site.js` to synchronize updated web assets from `site/` to `docs/`.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Write your changes to `g:\Zundamons-kItchen-V2\.agents\worker_m2\changes.md` and `handoff.md` and send a message back.
</USER_REQUEST>
