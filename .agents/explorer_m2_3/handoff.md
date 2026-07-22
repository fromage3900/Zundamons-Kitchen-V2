# Handoff Report — Explorer 3 (Milestone 2)

**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m2_3`  
**Target Module**: `site/assets/audio_engine.js` (and related `site/` scripts)  
**Task**: Analyze Web Audio API audio synthesis requirements for desktop jukebox, rain SFX generator, Zundamon vocal chirps, and user interaction unlocking.

---

## 1. Observation

1. **Existing Audio Engine Structure (`site/assets/audio_engine.js`)**:
   - `ZundaAudio` singleton initialized at `site/assets/audio_engine.js:7-86`.
   - `masterGain`, `sfxGain`, and `bgmGain` audio node hierarchy initialized at lines 41-55.
   - Mechanical click UI SFX (`playClickSFX`) implemented at lines 92-136.
   - Window operation SFX (`playWindowSFX`) implemented at lines 142-213.
   - CRT terminal key SFX (`playKeySFX`) implemented at lines 219-255.
   - BGM synthesizer (`startCozyBGM`, `stopCozyBGM`, `toggleCozyBGM`) implemented at lines 260-380 using E Major Pentatonic `[329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99] Hz` with 650ms `setInterval` arpeggiator and dual sine/triangle drone pad (164.81Hz / 246.94Hz).

2. **Decoupled Vocal Chirps (`site/app.js:33-122`)**:
   - `playZundaVoiceLine(type)` function is currently implemented inside `site/app.js:33` rather than `site/assets/audio_engine.js`.
   - Handles `'nanoda_arpeggio'` (F5 -> A5 -> C6 ascending triangle triad), `'chirp'` (900-1300Hz sine sweep), and rhythm minigame hit types (`hit_perfect`, `hit_great`, `hit_ok`, `hit_miss`).

3. **Missing Rain SFX Generator**:
   - `site/index.html:292-296` defines `#widget-jukebox` ("Zunda Lo-Fi Beats"), but `site/assets/audio_engine.js` currently lacks a noise buffer generator node or ambient rain sound generator (`startRainSFX`).

4. **Autoplay Policy Handling (`site/assets/audio_engine.js:57-62`)**:
   - `resumeOnUserGesture()` checks `this.ctx.state === 'suspended'` and calls `this.ctx.resume()`.
   - Currently relies on individual UI click/window event calls; lacks a global document event listener (`click`, `keydown`, `pointerdown`) registered at startup to automatically unlock `AudioContext` on the very first user interaction.

---

## 2. Logic Chain

1. **Zero External Dependency Requirement**:
   - Relying on external `.mp3` or `.wav` files introduces network request latency, CORS issues, and asset loading failures.
   - Using HTML5 Web Audio API (`AudioContext`, `OscillatorNode`, `GainNode`, `BiquadFilterNode`, `AudioBufferSourceNode`) allows 100% procedural sound synthesis in real-time with 0.0 MB extra download footprint.

2. **Rain Noise Subsystem Architecture**:
   - Rain ambience is synthesized by passing Pink Noise or filtered White Noise through a dual `BiquadFilterNode` chain (`highpass` at 150Hz to remove sub-rumble, `lowpass` at 1000Hz to soften high hiss).
   - Adding a slow 0.15Hz LFO gain envelope simulates natural rain volume swells.
   - Exposing `startRainSFX()`, `stopRainSFX()`, `toggleRainSFX()`, and `setRainVolume()` provides clean control for both `#widget-jukebox` and ZundaCLI commands.

3. **Vocal Chirp Unification**:
   - Moving `playZundaVoiceLine` into `site/assets/audio_engine.js` consolidates all Web Audio API procedural synthesis into a single source of truth.
   - Expanding vocal types (`'speech_talk'` micro-chirps for VNTalk dialogue typing, `'companion_click'` double sweeps for Zundamon desktop stickers) enhances UI reactivity.

4. **Autoplay Policy Compliance**:
   - Modern browser autoplay policies suspend `AudioContext` until a user gesture is captured.
   - Registering a global capture-phase event listener (`click`, `keydown`, `pointerdown`, `touchstart`) on `window` during `ZundaAudio.initAutoUnlock()` guarantees immediate resume upon user interaction.

---

## 3. Caveats

1. **AudioContext Browser Support**:
   - Supported across modern desktop and mobile browsers. Legacy browsers without `AudioContext` or `webkitAudioContext` will gracefully degrade (audio checks `if (!this.ctx) return`).
2. **Tab Throttling**:
   - Browser tabs running in the background may throttle timers. Switching BGM arpeggio scheduling from `setInterval` to `AudioContext.currentTime` scheduling ensures drift-free playback.
3. **Read-Only Scope**:
   - As Explorer 3, project source code was not modified. The findings and architectural blueprint are documented in `analysis.md` and this `handoff.md`.

---

## 4. Conclusion

The Web Audio API synthesis engine requirements for `site/assets/audio_engine.js` are fully analyzed and architected. The blueprint covers:
- **Procedural BGM Jukebox**: Multi-track pentatonic arpeggiation, warm lowpass-filtered drone pads, and sub-bass foundation.
- **Rain SFX Generator**: Pink/white noise buffer audio node with highpass (150Hz) and lowpass (1000Hz) filters, dynamic volume modulation, and standalone controls.
- **Zundamon Vocal Chirps**: Consolidated pitch-swept sine/triangle oscillators for clicks, dialogue typing, catchphrase arpeggios, and rhythm hits.
- **Autoplay Interaction Unlocking**: Global capture-phase event listener on `window` to seamlessly resume suspended `AudioContext` instances.

Detailed blueprint document written to:  
`g:\Zundamons-kItchen-V2\.agents\explorer_m2_3\analysis.md`

---

## 5. Verification Method

To verify the blueprint implementation once completed by an Implementer agent:

1. **File Path Inspection**:
   - Verify `site/assets/audio_engine.js` contains `ZundaAudio.initAutoUnlock()`, `startRainSFX()`, `stopRainSFX()`, and `playZundaVoiceLine()`.

2. **Browser Console Verification**:
   - Open `site/index.html` in Chrome/Edge/Firefox.
   - Open Developer Console and execute:
     ```javascript
     ZundaAudio.resumeOnUserGesture();
     console.log('AudioContext state:', ZundaAudio.ctx.state); // Should be 'running' after user click
     toggleCozyBGM(); // Should play BGM loop
     ZundaAudio.toggleRainSFX(); // Should play procedural rain sound
     playZundaVoiceLine('nanoda_arpeggio'); // Should play 3-note catchphrase
     ```

3. **Autoplay Verification**:
   - Reload `site/index.html` with zero clicks. Perform a single click anywhere on the page and verify `ZundaAudio.ctx.state` changes from `'suspended'` to `'running'`.
