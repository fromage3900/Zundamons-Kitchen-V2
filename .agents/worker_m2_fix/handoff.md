# Handoff Report: Milestone 2 Fix Pass - Cozy BGM Oscillator Cleanup

## 1. Observation
- Target File: `g:\Zundamons-kItchen-V2\site\assets\audio_engine.js`
- Prior State: In `audio_engine.js`, `startCozyBGM()` (lines 274-343) cleared `ZundaAudio.bgmStopTimeout` if active, but did not stop or disconnect any active oscillator nodes in `ZundaAudio.bgmPadOscs` before instantiating new pad oscillators and overwriting `ZundaAudio.bgmPadOscs`.
- Modified lines in `startCozyBGM()` (lines 282-288):
```javascript
  if (ZundaAudio.bgmPadOscs) {
    ZundaAudio.bgmPadOscs.forEach(osc => {
      try { osc.stop(); } catch (e) {}
      try { osc.disconnect(); } catch (e) {}
    });
    ZundaAudio.bgmPadOscs = null;
  }
```
- Tool verification commands and results:
  1. `node -c site/assets/audio_engine.js` executed with exit code 0 (clean JavaScript syntax, no errors).
  2. Node simulation test simulating rapid toggling / re-triggering of `startCozyBGM()` executed with result `Stopped count: 2 Disconnected count: 2`, exiting with 0.

## 2. Logic Chain
1. When BGM was stopped (`stopCozyBGM()`), `bgmPadGain` began a 1.0 second fade-out and scheduled a 1050ms timeout (`bgmStopTimeout`) to stop `bgmPadOscs` and clear the reference.
2. If `startCozyBGM()` was called during that 1050ms fade-out window (or if `startCozyBGM()` was called while `ZundaAudio.bgmPadOscs` still existed), `startCozyBGM()` cleared `bgmStopTimeout`.
3. Because `bgmStopTimeout` was cleared before its callback fired, the old oscillator nodes in `ZundaAudio.bgmPadOscs` were never stopped or disconnected, while new oscillators were created and stored in `ZundaAudio.bgmPadOscs`.
4. The un-stopped oscillators remained active in the Web Audio context graph indefinitely, causing audio node leakage on repeated BGM toggling.
5. By inserting an explicit check `if (ZundaAudio.bgmPadOscs)` inside `startCozyBGM()` that iterates through all existing oscillators, calls `stop()` and `disconnect()` on each (safely inside `try/catch` blocks), and resets `ZundaAudio.bgmPadOscs = null;` before instantiating new oscillators, all lingering pad oscillators are guaranteed to be cleaned up immediately upon starting BGM.

## 3. Caveats
No caveats. The fix is self-contained within `startCozyBGM()` in `site/assets/audio_engine.js` and targets Web Audio API standard `AudioNode` / `OscillatorNode` methods (`stop` and `disconnect`).

## 4. Conclusion
`startCozyBGM()` now cleanly stops and disconnects all existing pad oscillators in `ZundaAudio.bgmPadOscs` before starting new ones, preventing lingering audio nodes when toggling BGM off and on repeatedly. The file loads and parses with zero static syntax errors.

## 5. Verification Method
- **Syntax Check Command**:
  ```powershell
  node -c site/assets/audio_engine.js
  ```
  Expected result: Command completes cleanly with no stdout/stderr output and exit code 0.

- **Behavior Simulation Command**:
  ```powershell
  node -e "const fs = require('fs'); const window = global; global.window = window; global.localStorage = { getItem: () => null, setItem: () => {} }; const code = fs.readFileSync('./site/assets/audio_engine.js', 'utf8'); (0, eval)(code); let stoppedCount = 0, disconnectedCount = 0; function createMockOsc() { return { type: '', frequency: { setValueAtTime: () => {} }, connect: () => {}, start: () => {}, stop: () => { stoppedCount++; }, disconnect: () => { disconnectedCount++; } }; } const mockCtx = { currentTime: 0, state: 'running', createGain: () => ({ gain: { setValueAtTime: () => {}, setTargetAtTime: () => {}, linearRampToValueAtTime: () => {} }, connect: () => {} }), createBiquadFilter: () => ({ frequency: { setValueAtTime: () => {} }, connect: () => {} }), createOscillator: createMockOsc, destination: {} }; ZundaAudio.ctx = mockCtx; ZundaAudio.masterGain = mockCtx.createGain(); ZundaAudio.bgmGain = mockCtx.createGain(); startCozyBGM(); ZundaAudio.bgmPlaying = false; ZundaAudio.bgmStopTimeout = setTimeout(() => {}, 10000); startCozyBGM(); if (stoppedCount === 2 && disconnectedCount === 2) { console.log('PASS'); process.exit(0); } else { console.log('FAIL'); process.exit(1); }"
  ```
  Expected result: Output prints `PASS` and exits with code 0.
