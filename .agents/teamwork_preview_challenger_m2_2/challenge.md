# Adversarial Challenge Report — Milestone 2 (Challenger 2)

## Executive Summary

**Overall risk assessment**: HIGH  
**Verdict**: FAILED (3 of 4 checks passed; 1 critical audio oscillator leak bug discovered)

---

## Challenge Summary Table

| Requirement | Description | Empirical Status | Key Observation |
|---|---|---|---|
| 1. Volume Persistence | `ZundaAudio.init()` loads `zunda_os_volume` from LocalStorage | **VERIFIED (PASS)** | Correctly parses, clamps to [0,1], and defaults to 0.7 on invalid data. |
| 2. Invalid Click SFX Gain | `playClickSFX('invalid')` applies smooth gain ramp | **VERIFIED (PASS)** | Gain starts at 0.15 (no 1.0 blip) and ramps to 0.001 over 30ms. |
| 3. BGM Rapid Toggle Race | Rapid `startCozyBGM()` / `stopCozyBGM()` calls | **FAILED (BUG)** | Cleared `bgmStopTimeout` leaks previous pad oscillators (4/6 leaked). |
| 4. ScreenGui Export Schema | `WindowManager.exportScreenGuiLayout()` | **VERIFIED (PASS)** | Returns valid ScreenGui schema with `ResetOnSpawn: false` and `UDim2`. |

---

## Detailed Findings & Challenges

### [High] Challenge 1: BGM Rapid Toggle Oscillator Leak (FAILED)

- **Assumption challenged**: Calling `startCozyBGM()` while a BGM fade-out (`bgmStopTimeout`) is pending cleanly resets or restarts the audio engine state without leaking Web Audio API nodes.
- **Attack scenario**: User rapidly clicks the BGM toggle button or calls `startCozyBGM()` and `stopCozyBGM()` in quick succession (< 1050ms apart).
- **Blast radius**: `startCozyBGM()` clears `bgmStopTimeout` via `clearTimeout()`, but does **not** stop the active pad oscillators stored in `ZundaAudio.bgmPadOscs` before overwriting the array reference. The abandoned oscillators remain in `started` state indefinitely, causing CPU/audio graph resource accumulation and audio distortion over time.
- **Empirical evidence**:
  - Test command: `node g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m2_2\verify.js`
  - Sequence: 6 rapid calls to `toggleCozyBGM()` (3 start/stop cycles).
  - Result: 6 pad oscillators created. 1500ms after execution, 4 oscillators remained unstopped (`started=true, stopped=false`).
- **Mitigation proposal**:
  In `startCozyBGM()` (`site/assets/audio_engine.js` line 277), stop any existing `ZundaAudio.bgmPadOscs` prior to clearing the timeout and creating new oscillators:
  ```javascript
  if (ZundaAudio.bgmPadOscs) {
    ZundaAudio.bgmPadOscs.forEach(osc => {
      try { osc.stop(); } catch(e){}
    });
    ZundaAudio.bgmPadOscs = null;
  }
  if (ZundaAudio.bgmStopTimeout) {
    clearTimeout(ZundaAudio.bgmStopTimeout);
    ZundaAudio.bgmStopTimeout = null;
  }
  ```

---

### [Pass] Item 1: Volume Persistence from LocalStorage (VERIFIED)

- **Verification details**:
  - `localStorage.setItem('zunda_os_volume', '0.42')` -> `ZundaAudio.init()` sets `this.volume = 0.42` and `masterGain.gain` to `0.42`.
  - Edge cases tested:
    - Out-of-bounds high (`'1.5'`): Clamped to `1.0`.
    - Out-of-bounds low (`'-0.5'`): Clamped to `0.0`.
    - Non-numeric string (`'not_a_number'`): Retains default volume `0.7`.
    - Calling `setVolume(0.25)`: Persists `'0.25'` into LocalStorage.

---

### [Pass] Item 2: Gain Attenuation for `playClickSFX('invalid')` (VERIFIED)

- **Verification details**:
  - Invoking `playClickSFX('invalid')` triggers the fallback branch (`site/assets/audio_engine.js` line 123).
  - Initial gain node setup: `setValueAtTime(0.15, now)` — confirms initial gain is 0.15 (attenuated), avoiding full volume 1.0 audio pops.
  - Exponential decay: `exponentialRampToValueAtTime(0.001, now + 0.03)`.
  - Oscillator stop scheduled at `now + 0.035`s.

---

### [Pass] Item 3: `WindowManager.exportScreenGuiLayout()` JSON Schema (VERIFIED)

- **Verification details**:
  - `WindowManager.exportScreenGuiLayout()` (and static method `WindowManager.exportScreenGuiLayout()`) generates layout metadata mapping windows directly to Roblox `ScreenGui` frames.
  - `ScreenGui.ResetOnSpawn` is explicitly set to `false` (conforming to AGENTS.md Rule 2).
  - Frame layout uses Roblox `UDim2` format (`{ X: { Scale, Offset }, Y: { Scale, Offset } }`).
  - Managed window IDs mapped: `Win_zundacli`, `Win_cookbook`, `Win_vntalk`, `Win_quickstart`. Each includes `Header` and `Body` sub-frames.

---

## Stress Test Results Summary

- Volume Persistence -> LocalStorage value `0.42` -> Master gain initialized to `0.42` -> PASS
- Volume Persistence -> Out-of-bounds values -> Clamped to [0.0, 1.0] range -> PASS
- SFX Gain Attenuation -> `playClickSFX('invalid')` -> Initial gain 0.15, exponential ramp down to 0.001 -> PASS
- BGM Rapid Toggle -> 6 rapid start/stop toggles -> 4 leaked oscillators remaining unstopped -> FAIL
- Roblox ScreenGui Export -> `exportScreenGuiLayout()` -> Valid ScreenGui JSON with `ResetOnSpawn: false` -> PASS
