# Explorer Handoff Report — Milestone 2: Audio Engine Remediation & Roblox UI Export Hooks

**Agent**: Explorer 3 (`teamwork_preview_explorer_m2_3`)  
**Milestone**: Milestone 2 — Zunda-OS 95 CLI Launch Page & Creative Hub  
**Date**: 2026-07-21  

---

## 1. Observation

1. **Audio Volume Persistence Failure**:
   - `site/assets/audio_engine.js:70-76` contains `setVolume(val)` which saves `localStorage.setItem('zunda_os_volume', this.volume.toString());`.
   - `site/assets/audio_engine.js:19-46` contains `ZundaAudio.init()`. While line 42 reads `localStorage.getItem('zunda_os_muted')`, `init()` never calls `localStorage.getItem('zunda_os_volume')`. `this.volume` stays at its initial default of `0.7` (line 13).

2. **Un-Attenuated Square Wave Burst on Unknown Click Variant**:
   - `site/assets/audio_engine.js:83-117` defines `playClickSFX(variant = 'down')`.
   - Lines 95–110 handle `variant === 'down'`, `'up'`, and `'start'`.
   - If `variant === 'invalid'` (or any unknown string), none of the `if / else if` conditions execute. `gain.gain` remains at the Web Audio API default value of `1.0` (un-attenuated full volume), and an un-attenuated square wave tone is produced for `0.03` seconds.

3. **BGM Stop Race Condition on Rapid Toggling**:
   - `site/assets/audio_engine.js:320-341` defines `stopCozyBGM()`.
   - Line 332 schedules a `setTimeout` for `1050`ms to stop and nullify `ZundaAudio.bgmPadOscs`.
   - `startCozyBGM()` (lines 255-318) does not track or clear pending stop timeouts. When `startCozyBGM()` is called within 1.05s of stopping BGM, the old timer fires after BGM restarts and kills the newly created `bgmPadOscs`.

4. **Roblox UI Export Mapping Requirement**:
   - Web UI layout elements in `site/index.html` use CSS pixel coordinates (`top`, `left`, `width`, `height`).
   - Roblox Studio UI importing requires mapping HTML window frames into Roblox `ScreenGui` hierarchy with `UDim2` positions, `UDim2` sizes, `ResetOnSpawn = false` compliance, and CSS theme color variables.

---

## 2. Logic Chain

1. **Volume Persistence**:
   - *Observation 1* shows that `zunda_os_volume` is saved during runtime but never loaded during startup in `ZundaAudio.init()`.
   - *Reasoning*: Reading `localStorage.getItem('zunda_os_volume')` at the beginning of `init()`, parsing with `parseFloat()`, clamping to `[0, 1]`, and setting `this.volume` ensures `masterGain` inherits the user's saved volume upon initialization.

2. **Attenuated Beep**:
   - *Observation 2* demonstrates that `playClickSFX('invalid')` bypasses all gain scheduling, causing an un-attenuated volume `1.0` burst.
   - *Reasoning*: Adding a fallback `else` branch in `playClickSFX` sets explicit frequency modulation (180Hz to 60Hz over 0.03s), initial attenuated gain (`0.15`), and an exponential gain ramp down to `0.001` over `0.03s`.

3. **BGM Toggle Race Condition**:
   - *Observation 3* identifies an unmanaged async `setTimeout` in `stopCozyBGM()`.
   - *Reasoning*: Storing the timer handle in `ZundaAudio.bgmStopTimeout` and calling `clearTimeout(ZundaAudio.bgmStopTimeout)` inside `startCozyBGM()` and `stopCozyBGM()` guarantees that rapid toggles cancel pending oscillator terminations.

4. **Roblox UI Export Mapping**:
   - *Observation 4* shows the need for a programmatic link between web window positions and Roblox `ScreenGui` frames.
   - *Reasoning*: Encapsulating window management into `site/window_manager.js` and exposing `WindowManager.exportScreenGuiLayout()` allows querying active window DOM bounds, converting pixel offsets to `UDim2`, extracting CSS theme variables, and producing a validated JSON mapping schema for Roblox Studio import.

---

## 3. Caveats

- **AudioContext Autoplay Policy**: Web Audio API requires user gesture activation. `resumeOnUserGesture()` handles this, but volume initialization depends on audio context instantiation on gesture.
- **Rojo Studio Importer**: `WindowManager.exportScreenGuiLayout()` produces the JSON layout structure. Importing into Studio requires executing a Luau script or MCP tool (e.g. `roblox-studio_execute_luau`) to construct the actual `ScreenGui` instances inside `StarterGui` or `PlayerGui`.

---

## 4. Conclusion

The specification in `analysis.md` addresses all three audio engine bugs in `site/assets/audio_engine.js` and delivers a complete design and code for `site/window_manager.js` to support Roblox Studio ScreenGui export layout mapping.

All proposed changes comply strictly with project rules:
- `$ignoreUnknownInstances: true` in `default.project.json` is preserved.
- `ScreenGui` layout exports specify `resetOnSpawn: false` and explicit panel visibility states.

---

## 5. Verification Method

1. **File Inspection**:
   - Inspect `site/assets/audio_engine.js` to verify `init()`, `playClickSFX()`, `startCozyBGM()`, and `stopCozyBGM()`.
   - Inspect `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_3\analysis.md` for exact code diffs and implementation details.

2. **Runtime Verification Steps**:
   - **LocalStorage Volume Persistence**:
     Open browser console on `site/index.html`. Run `ZundaAudio.setVolume(0.4)`. Reload page. Run `ZundaAudio.init()`. Check `ZundaAudio.volume === 0.4`.
   - **Attenuated Beep**:
     Run `playClickSFX('invalid')` in console. Audio should be a quiet, attenuated 0.03s low beep (gain 0.15 -> 0.001), never un-attenuated full volume 1.0.
   - **BGM Rapid Toggle**:
     Run `toggleCozyBGM(); setTimeout(toggleCozyBGM, 200); setTimeout(toggleCozyBGM, 400);` in console. Verify ambient BGM plays smoothly without pad oscillator cutoff.
   - **Roblox UI Layout Export**:
     Include `site/window_manager.js`. Run `WindowManager.exportScreenGuiLayout()` in console. Verify the returned object contains `screenGui` metadata with `resetOnSpawn: false`, theme variables, and window layout array mapping `UDim2` offsets.
