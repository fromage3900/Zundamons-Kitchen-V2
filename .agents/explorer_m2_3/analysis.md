# Web Audio API Synthesis Engine Blueprint — Zundamon's Kitchen V2 (Milestone 2)

**Target File**: `site/assets/audio_engine.js`  
**Author**: Explorer 3 (Milestone 2)  
**Scope**: Zero-dependency procedural Web Audio API audio synthesis engine for desktop jukebox, rain SFX generator, Zundamon vocal chirps, UI soundscapes, and browser autoplay unlocking.

---

## Executive Summary

Zundamon's Kitchen V2 launch page (`site/`) incorporates a Y2K/Win95-inspired Kawaii PC Desktop workspace. To ensure zero external asset dependencies (0.0 MB download for MP3/WAV files) and instant sub-millisecond audio playback, all music and sound effects are procedurally synthesized in real-time using native HTML5 Web Audio API (`AudioContext`, `OscillatorNode`, `GainNode`, `BiquadFilterNode`, `AudioBufferSourceNode`).

This document formulates the technical analysis and detailed implementation blueprint for four core audio synthesis subsystems:
1. **Web Audio API Synthesis Engine**: Multi-track procedural BGM jukebox (Pentatonic arpeggios, warm drone pads, sub-bass foundation).
2. **Rain SFX Generator**: Procedural pink/white noise buffer audio node with dual lowpass/highpass filtering and dynamic LFO volume modulation.
3. **Zundamon Vocal Chirps**: Pitch-swept sine/triangle oscillator chirps for companion clicks, speech bubbles, button feedback, and rhythm minigame hits.
4. **User Interaction Unlocking**: Auto-unlock handler complying with browser autoplay restrictions across Chrome, Edge, Safari, and Firefox.

---

## 1. Web Audio API Synthesis Engine (Procedural BGM Jukebox)

### 1.1 Current Implementation & Gaps
* **Current Code**: `site/assets/audio_engine.js` implements basic BGM using a 650ms `setInterval` to trigger random notes from an E Major Pentatonic scale (`[329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99] Hz`) over a soft E3/B3 lowpass-filtered drone pad.
* **Gaps**:
  1. `setInterval` timing is prone to browser main-thread jitter and tab throttling.
  2. Single hardcoded scale without melody phrasing or selectable jukebox tracks.
  3. Lack of sub-bass foundation node.

### 1.2 Enhanced Synthesizer Architecture Blueprint
The BGM synthesis engine uses a 3-track procedural Web Audio architecture running directly on `ZundaAudio.bgmGain`:

```
 [ AudioContext.currentTime Scheduler ]
                  │
   ┌──────────────┼──────────────┐
   ▼              ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Track 1  │ │ Track 2  │ │ Track 3  │
│ Soft Drone│ │ Melody   │ │ Sub-Bass │
│ Pad      │ │ Arp      │ │ Synth    │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     ▼            ▼            ▼
┌────────────────────────────────────┐
│      BiquadFilter (Lowpass 450Hz)  │
└──────────────────┬─────────────────┘
                   ▼
┌────────────────────────────────────┐
│         ZundaAudio.bgmGain         │
└──────────────────┬─────────────────┘
                   ▼
┌────────────────────────────────────┐
│        ZundaAudio.masterGain       │
└────────────────────────────────────┘
```

#### Track Specifications:
1. **Track 1: Warm Drone Pad (`bgmPadOscs`)**
   - **Oscillators**: Dual `sine` (Root note, e.g. E3 164.81Hz) + `triangle` (5th/7th note, e.g. B3 246.94Hz).
   - **Filter**: `BiquadFilterNode` (`type: 'lowpass'`, `frequency: 450Hz`).
   - **LFO Modulation**: Sub-audible LFO (0.08Hz sine) modulating filter cutoff between 350Hz and 550Hz for gentle organic swell.
   - **Envelope**: Linear gain ramp from `0.01` to `0.12` over 2.0s fade-in.

2. **Track 2: Pentatonic Lead Arpeggiator (`bgmMelody`)**
   - **Timing**: AudioContext precision time-scheduling (`ctx.currentTime + delta`) instead of `setInterval`.
   - **Scale Modal Presets**:
     - *Preset 1: "Zunda Cozy Kitchen"* — E Major Pentatonic `[329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99] Hz` (110 BPM).
     - *Preset 2: "Starlight Lullaby"* — A Major Pentatonic `[220.00, 246.94, 277.18, 329.63, 369.99, 440.00] Hz` (85 BPM).
     - *Preset 3: "Edamame Afternoon Waltz"* — C Major Pentatonic `[261.63, 293.66, 329.63, 392.00, 440.00, 523.25] Hz` (3/4 time feel, 100 BPM).
   - **Oscillator**: `sine` wave with 10ms attack, exponential gain decay to `0.0005` over 600ms.

3. **Track 3: Sub-Bass Foundation**
   - **Oscillator**: Deep `sine` wave (E2 82.41Hz / A2 110.00Hz / C2 65.41Hz) synced to root chord changes every 4 bars.
   - **Envelope**: `setValueAtTime(0.1, now)`, decay over 1.8s.

---

## 2. Rain SFX Generator (Ambient Noise Subsystem)

### 2.1 Technical Requirement
A procedural pink/white noise audio buffer node providing gentle ambient rain soundscapes for the desktop jukebox (`#widget-jukebox`), togglable independently or alongside BGM with custom volume control. Zero external sound files.

### 2.2 Rain Generator Audio Graph Blueprint

```
┌─────────────────────────────────────────┐
│ Procedural AudioBuffer (Pink/White Noise)│
│ (2.0s Stereo Float32Array ArrayBuffer)  │
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ AudioBufferSourceNode (loop = true)     │
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ BiquadFilterNode (Highpass, 150Hz Cutoff)│ (Removes harsh sub-rumble)
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ BiquadFilterNode (Lowpass, 1000Hz Cutoff)│ (Softens high hiss into rain)
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ GainNode (Rain Patter LFO Modulation)   │ (0.15Hz LFO for gentle rain volume swell)
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ ZundaAudio.rainGain (Gain: 0.0 - 1.0)   │
└────────────────────┬────────────────────┘
                     ▼
┌─────────────────────────────────────────┐
│ ZundaAudio.masterGain                   │
└─────────────────────────────────────────┘
```

### 2.3 Noise Generation Algorithm
* **White/Pink Noise Buffer Construction**:
  ```javascript
  function createRainNoiseBuffer(ctx, durationSec = 2.0) {
    const sampleRate = ctx.sampleRate;
    const bufferSize = sampleRate * durationSec;
    const buffer = ctx.createBuffer(2, bufferSize, sampleRate);
    
    for (let channel = 0; channel < 2; channel++) {
      const output = buffer.getChannelData(channel);
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        // Paul Kellet's Pink Noise filter algorithm
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        const pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
        b6 = white * 0.115926;
        output[i] = pink * 0.11; // Normalize amplitude
      }
    }
    return buffer;
  }
  ```

### 2.4 API Surface
* `ZundaAudio.startRainSFX()`: Spawns noise buffer node, connects filters & gain, starts looping.
* `ZundaAudio.stopRainSFX()`: Smoothly ramps `rainGain` to 0 over 500ms and stops buffer node.
* `ZundaAudio.toggleRainSFX()`: Toggles rain state; returns `boolean`.
* `ZundaAudio.setRainVolume(val)`: Adjusts rain gain multiplier (0.0 to 1.0).

---

## 3. Zundamon Vocal Chirps Subsystem

### 3.1 Unification Strategy
Currently, `playZundaVoiceLine` is defined in `site/app.js`, while `playClickSFX` and `playWindowSFX` are in `site/assets/audio_engine.js`. Unifying all vocal chirp synthesis functions into `ZundaAudio` inside `audio_engine.js` creates a single source of truth for audio synthesis.

### 3.2 Vocal Chirp Sound Matrix

| Vocal Type | Trigger Event | Oscillator Type | Pitch Sweep / Frequency Range | Envelope & Duration |
|---|---|---|---|---|
| `'chirp'` | Companion clicks, dialogue text blips | `sine` | 900Hz → 1200Hz (exponential sweep up) | 35ms duration, 12% max gain |
| `'nanoda_arpeggio'` | Catchphrase button, victory celebration | `triangle` | 3-note ascending triad: F5 (698.46Hz) → A5 (880.00Hz) → C6 (1046.50Hz) | 70ms step interval, 120ms note decay |
| `'speech_talk'` | VNTalk typewriter output, speech bubble updates | `sine` | Randomized blip: 750Hz – 1150Hz | 25ms micro-blips per character |
| `'companion_click'` | Clicking Zundamon desktop sticker | `sine` + `triangle` | Dual chirp: C6 (1046.50Hz) → G6 (1567.98Hz) | 50ms sweep duration |
| `'hit_perfect'` | Rhythm game Perfect hit | `triangle` | 880Hz → 1760Hz (crystalline chime) | 100ms duration, 30% max gain |
| `'hit_great'` | Rhythm game Great hit | `sine` | Fixed 660Hz bright pitch | 80ms duration, 25% max gain |
| `'hit_ok'` | Rhythm game OK hit | `square` | Fixed 440Hz mid click | 50ms duration, 18% max gain |
| `'hit_miss'` | Rhythm game Miss hit | `sawtooth` | 150Hz → 60Hz thud pitch drop | 100ms duration, 20% max gain |

---

## 4. User Interaction Unlocking Subsystem

### 4.1 Autoplay Policy Compliance
Modern web browsers (Chrome 66+, Safari 11+, Edge, Firefox) prohibit `AudioContext` from outputting sound automatically on page load until a user interaction gesture occurs. If instantiated beforehand, `AudioContext.state` remains `'suspended'`.

### 4.2 Global Auto-Unlock Blueprint
To guarantee smooth audio playback across all desktop icons, buttons, window header drags, and CLI keystrokes without audio dropping, a centralized unlock handler attaches to `window` on page load:

```javascript
ZundaAudio.initAutoUnlock = function() {
  const events = ['click', 'keydown', 'pointerdown', 'touchstart'];
  
  const unlockHandler = () => {
    if (!this.ctx) {
      this.init();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().then(() => {
        // Successfully unlocked
        events.forEach(evt => window.removeEventListener(evt, unlockHandler, { capture: true }));
      }).catch(err => {
        console.warn('AudioContext resume failed:', err);
      });
    } else if (this.ctx && this.ctx.state === 'running') {
      events.forEach(evt => window.removeEventListener(evt, unlockHandler, { capture: true }));
    }
  };

  events.forEach(evt => {
    window.addEventListener(evt, unlockHandler, { capture: true, once: false });
  });
};
```

### 4.3 Redundant Safeguard Layer
Each individual sound playback function (`playClickSFX`, `playWindowSFX`, `playKeySFX`, `playZundaVoiceLine`, `startCozyBGM`, `startRainSFX`) executes `ZundaAudio.resumeOnUserGesture()` at the top of execution as a secondary failsafe.

---

## 5. Execution & Refactoring Plan for Implementers

1. **Step 1 (`site/assets/audio_engine.js`)**:
   - Refactor `ZundaAudio` singleton object:
     - Add `rainGain`, `rainBufferNode`, `rainFilterNode`, `rainLfoNode`, `rainPlaying` properties.
     - Add `initAutoUnlock()` and invoke automatically upon DOM load.
     - Integrate Pink Noise buffer generator `createRainNoiseBuffer()`.
     - Implement `startRainSFX()`, `stopRainSFX()`, `toggleRainSFX()`, `setRainVolume()`.

2. **Step 2 (`site/assets/audio_engine.js` & `site/app.js`)**:
   - Migrate `playZundaVoiceLine(type)` into `site/assets/audio_engine.js`.
   - Add `'speech_talk'` and `'companion_click'` vocal chirp types.
   - Retain window attachments: `window.ZundaAudio`, `window.playClickSFX`, `window.playWindowSFX`, `window.playKeySFX`, `window.playZundaVoiceLine`, `window.toggleCozyBGM`, `window.toggleRainSFX`.

3. **Step 3 (`site/app.js` & `#widget-jukebox` UI Integration)**:
   - Update Lo-Fi Jukebox widget `#widget-jukebox` in `site/index.html` and `site/app.js` to expose dual controls for BGM and Rain SFX.
   - Bind CLI `music` and `rain` commands in `site/terminal.js` to `ZundaAudio.toggleRainSFX()`.

---

## 6. Verification & Test Plan

1. **Autoplay Resume Test**: Open `site/index.html` in an un-muted browser window. Observe `ZundaAudio.ctx.state === 'suspended'`. Perform a single click anywhere on the document. Verify `ZundaAudio.ctx.state` transitions to `'running'` immediately.
2. **Rain SFX Test**: Execute `ZundaAudio.startRainSFX()`. Verify white/pink noise buffer plays smoothly through lowpass filter (1000Hz cutoff) without clipping or distortion. Test volume modulation `setRainVolume(0.5)`.
3. **BGM Jukebox Test**: Execute `toggleCozyBGM()`. Verify dual-oscillator drone pad and pentatonic arpeggiator play without main-thread stutter.
4. **Vocal Chirps Test**: Execute `playZundaVoiceLine('nanoda_arpeggio')`, `playZundaVoiceLine('chirp')`, `playZundaVoiceLine('speech_talk')`. Verify crisp pitch-swept sine/triangle audio feedback.
