# Review & Adversarial Critic Report: Milestone 2 Desktop Widgets & Audio Engine

**Reviewer**: Reviewer 2 (`reviewer_m2_2`)  
**Target Files**: `site/assets/audio_engine.js`, `site/style.css`, `site/app.js`, `site/index.html`  
**Date**: 2026-07-22  

---

## Review Summary

**Verdict**: **REQUEST_CHANGES**

**Rationale**:  
While the Web Audio synthesis engine (`audio_engine.js`), rain noise generator, jukebox controls, and desktop widgets are overall well-designed and feature zero external audio file dependencies, a **Major Functional Defect** was identified in `site/app.js`:  
`app.js` re-defines `function playZundaVoiceLine(type = 'chirp')` in the global scope (lines 33–122), shadowing the complete implementation exported by `audio_engine.js` (lines 409–530). The duplicate function in `app.js` omits the `'companion_click'` and `'speech_talk'` voice line branches. Consequently, when the user clicks the Zundamon mascot sticker (`#widget-zunda-sticker`), `app.js` calls `playZundaVoiceLine('companion_click')`, which falls through all conditions without creating audio oscillators—silencing companion mascot click audio.

---

## Findings

### [Major] Finding 1: Global Function Shadowing in `app.js` Silences Mascot Click Chirps

- **What**: `app.js` re-defines `function playZundaVoiceLine(type = 'chirp')` at global scope (lines 33–122) instead of delegating to `audio_engine.js`. The definition in `app.js` is incomplete and omits handling for `'companion_click'` and `'speech_talk'`.
- **Where**: `site/app.js` (lines 33–122, line 1479) vs `site/assets/audio_engine.js` (lines 409–530).
- **Why**: Because `<script src="app.js"></script>` loads after `<script src="assets/audio_engine.js"></script>` in `index.html`, `app.js`'s definition overrides `window.playZundaVoiceLine` in global scope. When clicking `#widget-zunda-sticker`, `app.js` line 1479 calls `playZundaVoiceLine('companion_click')`. Since `app.js`'s version has no handler for `'companion_click'`, zero audio oscillators are created and no sound is emitted.
- **Suggestion**: Remove the duplicate `function playZundaVoiceLine` declaration from `app.js` and delegate to `window.ZundaAudio` / `audio_engine.js`'s implementation (matching the pattern used by `playClick`, `playWinSFX`, and `playKey`).

### [Minor] Finding 2: Rain SFX Slider Value Sync on Page Load

- **What**: `#rain-sfx-slider` is rendered with `value="40"` in `index.html` and `rainVolume` defaults to `0.4` in `audio_engine.js`, but `rainPlaying` starts as `false`.
- **Where**: `site/index.html` (line 309), `site/assets/audio_engine.js` (line 31), `site/app.js` (line 1453).
- **Why**: The UI slider visually displays 40% rain volume on initial load, but rain SFX is not synthesized until the user interacts with the slider or triggers audio context start.
- **Suggestion**: Either set initial slider value to `0` in HTML/CSS, or auto-start rain synthesis when volume > 0 upon initial user gesture resume.

---

## Verified Claims

| Claim | Verification Method | Result | Notes |
|---|---|---|---|
| Zero external audio file dependencies | Static code scan for `.mp3`/`.wav`/`.ogg` and network requests | **PASS** | 100% native Web Audio API synthesis |
| Procedural BGM Jukebox Synthesizer | Node JSDOM mock AudioContext test of `startCozyBGM()`, `stopCozyBGM()`, `nextBGMTrack()` | **PASS** | 3 tracks, lowpass filter pads, sub-bass, pentatonic arpeggio loop |
| Oscillator cleanup on BGM restart | Node behavior simulation test of rapid re-triggering of `startCozyBGM()` | **PASS** | Confirmed `ZundaAudio.bgmPadOscs` nodes are stopped & disconnected cleanly |
| Pink/White noise Rain Generator | Executed `createRainNoiseBuffer()` algorithm inspection and buffer test | **PASS** | Stereo 2.0s buffer using 7-pole pink noise filter + dual Biquad filters |
| Digital Clock & Weather Widget | JSDOM click test on `#widget-weather-pill` and clock timer inspection | **PASS** | Time updates every 1s; cycles 4 weather states on click |
| Lo-Fi Jukebox Widget | JSDOM click test on `#widget-play-bgm`, `#widget-next-track`, `#rain-sfx-slider` | **PASS** | Controls track name, `.spinning` disc class, rain volume |
| Zundamon Sticker Widget DOM & Text | JSDOM click test on `#widget-zunda-sticker` | **PASS** | Cycles 6 quotes, updates speech bubble, applies float animation |
| Zundamon Companion Click SFX | Function call `playZundaVoiceLine('companion_click')` | **FAIL** | Shadowed by `app.js` definition; 0 oscillators generated |

---

## Coverage Gaps

- **Safari webkitAudioContext Autoplay Handling**: Unmuted Web Audio initialization depends on user gesture listeners (`initAutoUnlock`). Tested logic in JSDOM, but actual iOS Safari physical user gesture resume requires device testing.

---

## Unverified Items

- **Physical browser audio output quality**: Procedural sound frequencies verified mathematically and in mock Web Audio graphs; subjective audio fidelity requires listening in browser.

---

## Adversarial Challenge & Stress Test Results

### 1. Assumption Stress-Testing
- **Assumption 1**: `app.js` helper functions seamlessly delegate to `audio_engine.js`.
  - *Challenge*: `playZundaVoiceLine` was re-declared in `app.js` with missing branches.
  - *Result*: **FAILED**. Confirmed 0 oscillators created when calling `'companion_click'`.
- **Assumption 2**: Rapid BGM track switching does not leak Web Audio nodes.
  - *Challenge*: Rapidly call `nextBGMTrack()` multiple times in succession.
  - *Result*: **PASSED**. Old pad oscillators in `ZundaAudio.bgmPadOscs` are stopped and disconnected before new nodes are instantiated.
- **Assumption 3**: Rain slider input handles boundary values (0% and 100%).
  - *Challenge*: Pass 0, 100, -10, and 150 into `setRainVolume()`.
  - *Result*: **PASSED**. `Math.max(0, Math.min(1, val / 100))` clamps volume safely; setting 0 stops rain node.

### 2. Overall Risk Assessment
**MEDIUM RISK** (Single code duplication defect blocking mascot click sound effects; core audio engine and UI widgets otherwise solid).
