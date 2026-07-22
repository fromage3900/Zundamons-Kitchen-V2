# Changes Summary — Milestone 2: Interactive Desktop Window Manager & Pastel Desktop Widgets Engine

## Modified Files

1. `site/window_manager.js`
   - Registered all 7 window IDs (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`).
   - Implemented `bringToFront(id)` z-index stack management (base 100, max 8999) with active/inactive visual class management.
   - Implemented `transferFocusToTopVisibleWindow()` focus fallback when an active window is closed or minimized.
   - Implemented drag & touch pointer movement on `.window-header` with viewport boundary clamping (`Math.max(0, Math.min(x, maxX))`).
   - Implemented maximize / restore with inline geometry memory (`data-prev-left`, `data-prev-top`, `data-prev-width`, `data-prev-height`).
   - Implemented dynamic taskbar buttons sync (`#taskbar-windows`), `#start-btn` popover menu toggle (`#start-menu`), `bindStartMenuEvents()` outside click dismissal, `Ctrl+Esc` start menu shortcut, and `Escape` key close.
   - Implemented `exportScreenGuiLayout()` layout tree mapping for Roblox ScreenGui integration (`ResetOnSpawn: false`).

2. `site/style.css`
   - Glassmorphic window frames (`.window`), glossy Sakura Pink titlebars (`.window-header`), candy window control buttons (`.win-minimize`, `.win-maximize`, `.win-close`), and pastel scrollable body frames (`.window-body`).
   - Styled Desktop Widgets bar and 3 widgets:
     - Digital Clock & Weather Widget (`#widget-clock-weather`, `.clock-display-pill`, `.weather-display-pill`, `.weather-icon`).
     - Lo-Fi Jukebox BGM & Rain FX Widget (`#widget-jukebox`, `.jukebox-track-info`, `.jukebox-icon.spinning`, `.jukebox-controls`, `.rain-sfx-container`, `.rain-slider`).
     - Zundamon Desktop Sticker Widget (`#widget-zunda-sticker`, `.zunda-sticker-widget`, `.sticker-mascot-box`, `.sticker-bubble` with arrow tail, hover/click bounce animations).

3. `site/assets/audio_engine.js`
   - Native Web Audio API procedural BGM jukebox with pentatonic arpeggiator, warm drone pads (sine + triangle), sub-bass foundation node, and next track preset switching (`nextBGMTrack`).
   - Pink/White noise rain SFX generator with dual highpass (150Hz) / lowpass (1100Hz) filters, dynamic gain control (`setRainVolume`), toggle & slider volume controls.
   - Zundamon vocal chirp synthesizer (`playZundaVoiceLine`): pitch-swept sine/triangle chirps for `'chirp'`, `'nanoda_arpeggio'`, `'speech_talk'`, `'companion_click'`, `'hit_perfect'`, `'hit_great'`, `'hit_ok'`, `'hit_miss'`.
   - Centralized user interaction unlock listener (`initAutoUnlock`) on `window` (`click`, `keydown`, `pointerdown`, `touchstart`) to handle browser autoplay policies.

4. `site/index.html`
   - Aligned DOM elements for all 3 desktop widgets (`#widget-clock-weather`, `#widget-digital-time`, `#widget-weather-pill`, `#widget-jukebox`, `#widget-play-bgm`, `#widget-next-track`, `#rain-sfx-slider`, `#widget-zunda-sticker`, `#widget-speech-bubble`).
   - Standardized maximize control button symbol across windows to `□`.

5. `site/app.js`
   - Refactored `initDesktopWidgets()` to wire live clock ticking, micro-weather forecast cycling on click, jukebox BGM play/pause & spinning disc toggle, next track selection, rain SFX volume slider, and Zundamon desktop sticker click chirps (`'companion_click'`) and speech bubble popups.

6. `docs/*` (Synced via `node site/sync_site.js`)
   - Synchronized all 5 updated web assets (`app.js`, `assets/audio_engine.js`, `index.html`, `style.css`, `window_manager.js`) to GitHub Pages target directory `docs/`.
