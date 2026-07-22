const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

// Mock Web Audio API for Node.js environment
function createMockAudioContext() {
  const oscillators = [];
  const gains = [];
  const filters = [];

  class MockAudioParam {
    constructor(defaultValue = 1) {
      this.value = defaultValue;
      this.calls = [];
    }
    setValueAtTime(val, time) {
      this.value = val;
      this.calls.push({ method: 'setValueAtTime', val, time });
    }
    exponentialRampToValueAtTime(val, time) {
      this.value = val;
      this.calls.push({ method: 'exponentialRampToValueAtTime', val, time });
    }
    linearRampToValueAtTime(val, time) {
      this.value = val;
      this.calls.push({ method: 'linearRampToValueAtTime', val, time });
    }
    setTargetAtTime(val, time, constant) {
      this.value = val;
      this.calls.push({ method: 'setTargetAtTime', val, time, constant });
    }
    cancelScheduledValues(time) {
      this.calls.push({ method: 'cancelScheduledValues', time });
    }
  }

  class MockGainNode {
    constructor() {
      this.gain = new MockAudioParam(1);
      gains.push(this);
    }
    connect(dest) {}
  }

  class MockOscillatorNode {
    constructor() {
      this.type = 'sine';
      this.frequency = new MockAudioParam(440);
      this.started = false;
      this.stopped = false;
      this.startTime = null;
      this.stopTime = null;
      oscillators.push(this);
    }
    connect(dest) {}
    start(time = 0) {
      if (this.started) throw new Error('Oscillator already started');
      this.started = true;
      this.startTime = time;
    }
    stop(time = 0) {
      if (!this.started) throw new Error('Cannot stop oscillator before start');
      if (this.stopped) throw new Error('Oscillator already stopped');
      this.stopped = true;
      this.stopTime = time;
    }
  }

  class MockBiquadFilterNode {
    constructor() {
      this.type = 'lowpass';
      this.frequency = new MockAudioParam(350);
      filters.push(this);
    }
    connect(dest) {}
  }

  class MockAudioContext {
    constructor() {
      this.currentTime = 0;
      this.state = 'running';
      this.destination = {};
    }
    createGain() {
      return new MockGainNode();
    }
    createOscillator() {
      return new MockOscillatorNode();
    }
    createBiquadFilter() {
      return new MockBiquadFilterNode();
    }
    resume() {
      this.state = 'running';
      return Promise.resolve();
    }
  }

  return { MockAudioContext, oscillators, gains, filters };
}

// LocalStorage mock
function createMockLocalStorage() {
  const store = {};
  return {
    getItem(key) {
      return store[key] !== undefined ? store[key] : null;
    },
    setItem(key, val) {
      store[key] = String(val);
    },
    removeItem(key) {
      delete store[key];
    },
    clear() {
      for (const k in store) delete store[k];
    },
    _store: store
  };
}

function setupDOMWindow() {
  const dom = new JSDOM(`<!DOCTYPE html><html><body></body></html>`, {
    url: 'http://localhost/'
  });
  const { MockAudioContext, oscillators, gains, filters } = createMockAudioContext();
  const mockLS = createMockLocalStorage();

  dom.window.AudioContext = MockAudioContext;
  dom.window.localStorage = mockLS;

  global.window = dom.window;
  global.document = dom.window.document;
  global.localStorage = mockLS;
  global.AudioContext = MockAudioContext;

  const audioCode = fs.readFileSync(path.join(__dirname, '../../site/assets/audio_engine.js'), 'utf8');
  // Evaluate in global scope context
  const evalFunc = new Function('window', 'document', 'localStorage', 'AudioContext', audioCode + '; return window;');
  const win = evalFunc(dom.window, dom.window.document, mockLS, MockAudioContext);

  return { dom, mockLS, win, ZundaAudio: win.ZundaAudio, oscillators, gains, filters };
}

async function runTests() {
  console.log('=== STARTING EMPIRICAL CHALLENGE TESTS ===\n');
  const results = {
    test1_volume_persistence: false,
    test2_click_sfx_attenuation: false,
    test3_bgm_rapid_toggle_race: false,
    test4_export_layout_schema: false,
    details: {}
  };

  // -------------------------------------------------------------
  // TEST 1: ZundaAudio.init() Volume Persistence
  // -------------------------------------------------------------
  console.log('--- TEST 1: Volume Persistence from LocalStorage ---');
  try {
    const { mockLS, ZundaAudio } = setupDOMWindow();

    // Load persisted state: 0.42
    mockLS.setItem('zunda_os_volume', '0.42');
    mockLS.setItem('zunda_os_muted', 'false');

    ZundaAudio.init();

    const volLoaded = ZundaAudio.volume;
    const masterGainValue = ZundaAudio.masterGain.gain.value;

    console.log(`Loaded volume: ${volLoaded} (expected: 0.42)`);
    console.log(`Master gain value: ${masterGainValue} (expected: 0.42)`);

    // Test setVolume(0.25)
    ZundaAudio.setVolume(0.25);
    const setVolLS = mockLS.getItem('zunda_os_volume');
    console.log(`setVolume(0.25) saved to LS: '${setVolLS}'`);

    // Test clamping with 1.5
    const scope2 = setupDOMWindow();
    scope2.mockLS.setItem('zunda_os_volume', '1.5');
    scope2.ZundaAudio.init();
    const volClampedHigh = scope2.ZundaAudio.volume;
    console.log(`Clamped high volume (1.5 -> ${volClampedHigh})`);

    // Test clamping with -0.5
    const scope3 = setupDOMWindow();
    scope3.mockLS.setItem('zunda_os_volume', '-0.5');
    scope3.ZundaAudio.init();
    const volClampedLow = scope3.ZundaAudio.volume;
    console.log(`Clamped low volume (-0.5 -> ${volClampedLow})`);

    // Test invalid string fallback
    const scope4 = setupDOMWindow();
    scope4.mockLS.setItem('zunda_os_volume', 'not_a_number');
    scope4.ZundaAudio.init();
    const volInvalid = scope4.ZundaAudio.volume;
    console.log(`Invalid volume fallback ('not_a_number' -> ${volInvalid})`);

    if (volLoaded === 0.42 && masterGainValue === 0.42 && setVolLS === '0.25' && volClampedHigh === 1.0 && volClampedLow === 0 && volInvalid === 0.7) {
      results.test1_volume_persistence = true;
      console.log('PASSED Test 1');
    } else {
      console.error('FAILED Test 1');
    }
  } catch (err) {
    console.error('ERROR Test 1:', err);
  }

  // -------------------------------------------------------------
  // TEST 2: playClickSFX('invalid') Smooth Gain Attenuation
  // -------------------------------------------------------------
  console.log('\n--- TEST 2: playClickSFX("invalid") Gain Attenuation ---');
  try {
    const { win, ZundaAudio, oscillators, gains } = setupDOMWindow();

    ZundaAudio.init();

    // Clear tracked nodes from init
    oscillators.length = 0;
    gains.length = 0;

    // Call playClickSFX('invalid')
    win.playClickSFX('invalid');

    console.log(`Created ${oscillators.length} oscillator(s), ${gains.length} gain node(s)`);

    let passed2 = false;
    if (gains.length > 0 && oscillators.length > 0) {
      const clickGain = gains[gains.length - 1];
      const clickOsc = oscillators[oscillators.length - 1];

      const calls = clickGain.gain.calls;
      console.log('Gain audio param calls for "invalid":', JSON.stringify(calls, null, 2));

      const setValCall = calls.find(c => c.method === 'setValueAtTime');
      const rampCall = calls.find(c => c.method === 'exponentialRampToValueAtTime');

      console.log(`setValueAtTime val: ${setValCall ? setValCall.val : undefined}`);
      console.log(`exponentialRampToValueAtTime val: ${rampCall ? rampCall.val : undefined}`);
      console.log(`Oscillator stopped: ${clickOsc.stopped}, stopTime: ${clickOsc.stopTime}`);

      if (setValCall && setValCall.val <= 0.15 && setValCall.val > 0 && rampCall && rampCall.val === 0.001 && clickOsc.stopped) {
        passed2 = true;
      }
    }

    if (passed2) {
      results.test2_click_sfx_attenuation = true;
      console.log('PASSED Test 2');
    } else {
      console.error('FAILED Test 2');
    }
  } catch (err) {
    console.error('ERROR Test 2:', err);
  }

  // -------------------------------------------------------------
  // TEST 3: BGM Rapid Toggle Race Condition & Oscillator Leaks
  // -------------------------------------------------------------
  console.log('\n--- TEST 3: BGM Rapid Toggle Race Condition ---');
  try {
    const { win, ZundaAudio, oscillators, gains } = setupDOMWindow();

    ZundaAudio.init();

    oscillators.length = 0;
    gains.length = 0;

    console.log('Simulating rapid BGM start/stop toggles...');

    // Rapid toggle sequence
    win.ZundaAudio.bgmPlaying = false; // ensure initial state
    // Top-level functions in audio_engine.js:
    // startCozyBGM and stopCozyBGM are inside audio_engine script scope.
    // toggleCozyBGM is on window.
    win.toggleCozyBGM(); // starts BGM (creates pad Osc 1 & 2)
    win.toggleCozyBGM(); // stops BGM (schedules stop timeout)
    win.toggleCozyBGM(); // starts BGM (clears timeout, creates pad Osc 3 & 4)
    win.toggleCozyBGM(); // stops BGM (schedules stop timeout)
    win.toggleCozyBGM(); // starts BGM (clears timeout, creates pad Osc 5 & 6)
    win.toggleCozyBGM(); // stops BGM (schedules stop timeout)

    const totalOscillatorsCreated = oscillators.length;
    console.log(`Total pad/melody oscillators created during rapid toggles: ${totalOscillatorsCreated}`);

    // Wait for timeout (1050ms stop timeout in stopCozyBGM)
    await new Promise(resolve => setTimeout(resolve, 1500));

    const unstoppedOscs = oscillators.filter(osc => !osc.stopped);
    console.log(`Oscillators remaining unstopped after timeout: ${unstoppedOscs.length}`);

    oscillators.forEach((osc, idx) => {
      console.log(`Osc #${idx + 1}: started=${osc.started}, stopped=${osc.stopped}`);
    });

    if (unstoppedOscs.length === 0) {
      results.test3_bgm_rapid_toggle_race = true;
      console.log('PASSED Test 3: Zero oscillator leaks detected!');
    } else {
      console.error(`FAILED Test 3: ${unstoppedOscs.length} leaked oscillator(s) found!`);
      results.details.test3_leaked_count = unstoppedOscs.length;
      results.details.test3_leaked_oscillators = unstoppedOscs.map(o => ({ started: o.started, stopped: o.stopped }));
    }
  } catch (err) {
    console.error('ERROR Test 3:', err);
  }

  // -------------------------------------------------------------
  // TEST 4: WindowManager.exportScreenGuiLayout() Schema Verification
  // -------------------------------------------------------------
  console.log('\n--- TEST 4: WindowManager.exportScreenGuiLayout() Schema ---');
  try {
    const htmlContent = fs.readFileSync(path.join(__dirname, '../../site/index.html'), 'utf8');
    const dom4 = new JSDOM(htmlContent, { url: 'http://localhost/' });

    global.window = dom4.window;
    global.document = dom4.window.document;

    const WindowManager = require(path.join(__dirname, '../../site/window_manager.js'));
    const wm = new WindowManager();
    wm.init();

    const layout = wm.exportScreenGuiLayout();

    let passed4 = true;
    const checks = [];

    // Verify ScreenGui root
    if (!layout || !layout.ScreenGui) {
      passed4 = false;
      checks.push('Missing layout.ScreenGui root');
    } else {
      const sg = layout.ScreenGui;
      if (sg.Name !== 'ZundaOS95ScreenGui') { passed4 = false; checks.push(`Unexpected Name: ${sg.Name}`); }
      if (sg.ResetOnSpawn !== false) { passed4 = false; checks.push(`ResetOnSpawn should be false, got: ${sg.ResetOnSpawn}`); }
      if (sg.ZIndexBehavior !== 'Sibling') { passed4 = false; checks.push(`ZIndexBehavior should be Sibling, got: ${sg.ZIndexBehavior}`); }
      if (!Array.isArray(sg.Children)) { passed4 = false; checks.push('Children is not an array'); }

      const expectedManagedWindows = ['Win_zundacli', 'Win_cookbook', 'Win_vntalk', 'Win_quickstart'];
      const childNames = sg.Children.map(c => c.Name);
      console.log('Child window frame names in ScreenGui:', childNames);

      expectedManagedWindows.forEach(expectedName => {
        if (!childNames.includes(expectedName)) {
          passed4 = false;
          checks.push(`Missing frame for ${expectedName}`);
        }
      });

      // Verify structure of each window frame
      sg.Children.forEach(frame => {
        if (frame.ClassName !== 'Frame') { passed4 = false; checks.push(`Invalid ClassName in ${frame.Name}`); }
        if (!frame.Position || typeof frame.Position.X.Offset !== 'number' || typeof frame.Position.Y.Offset !== 'number') {
          passed4 = false; checks.push(`Invalid Position UDim2 format in ${frame.Name}`);
        }
        if (!frame.Size || typeof frame.Size.X.Offset !== 'number' || typeof frame.Size.Y.Offset !== 'number') {
          passed4 = false; checks.push(`Invalid Size UDim2 format in ${frame.Name}`);
        }
        if (typeof frame.ZIndex !== 'number') { passed4 = false; checks.push(`Missing ZIndex in ${frame.Name}`); }
        if (typeof frame.Visible !== 'boolean') { passed4 = false; checks.push(`Missing Visible in ${frame.Name}`); }
        if (!Array.isArray(frame.Children) || frame.Children.length < 2) {
          passed4 = false; checks.push(`Missing Header/Body subframes in ${frame.Name}`);
        }
      });
    }

    // Also test static method exportScreenGuiLayout
    const staticLayout = WindowManager.exportScreenGuiLayout();
    if (!staticLayout || !staticLayout.ScreenGui) {
      passed4 = false;
      checks.push('Static exportScreenGuiLayout failed');
    }

    if (passed4) {
      results.test4_export_layout_schema = true;
      console.log('PASSED Test 4: ScreenGui schema is valid!');
    } else {
      console.error('FAILED Test 4 failures:', checks);
    }
  } catch (err) {
    console.error('ERROR Test 4:', err);
  }

  console.log('\n=== SUMMARY ===');
  console.log(JSON.stringify(results, null, 2));
  return results;
}

runTests();
