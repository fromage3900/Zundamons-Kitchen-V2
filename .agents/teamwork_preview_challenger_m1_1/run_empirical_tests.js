const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

// Define Paths
const siteDir = path.join(__dirname, '..', '..', 'site');
const htmlPath = path.join(siteDir, 'index.html');
const audioJsPath = path.join(siteDir, 'assets', 'audio_engine.js');

const htmlContent = fs.readFileSync(htmlPath, 'utf8');
const audioJsContent = fs.readFileSync(audioJsPath, 'utf8');

// Web Audio API Mock Builder
function createWebAudioMock() {
  const calls = {
    oscCreated: 0,
    gainCreated: 0,
    filterCreated: 0,
    scheduledValues: []
  };

  class MockAudioParam {
    constructor(defaultValue = 1) {
      this.value = defaultValue;
    }
    setValueAtTime(val, time) {
      this.value = val;
      calls.scheduledValues.push({ type: 'setValueAtTime', val, time });
    }
    exponentialRampToValueAtTime(val, time) {
      this.value = val;
      calls.scheduledValues.push({ type: 'exponentialRampToValueAtTime', val, time });
    }
    linearRampToValueAtTime(val, time) {
      this.value = val;
      calls.scheduledValues.push({ type: 'linearRampToValueAtTime', val, time });
    }
    setTargetAtTime(val, time, target) {
      this.value = val;
      calls.scheduledValues.push({ type: 'setTargetAtTime', val, time, target });
    }
    cancelScheduledValues(time) {
      calls.scheduledValues.push({ type: 'cancelScheduledValues', time });
    }
  }

  class MockGainNode {
    constructor() {
      calls.gainCreated++;
      this.gain = new MockAudioParam(1);
    }
    connect(dest) {}
  }

  class MockOscillatorNode {
    constructor() {
      calls.oscCreated++;
      this.type = 'sine';
      this.frequency = new MockAudioParam(440);
    }
    connect(dest) {}
    start(time) {}
    stop(time) {}
  }

  class MockBiquadFilterNode {
    constructor() {
      calls.filterCreated++;
      this.type = 'lowpass';
      this.frequency = new MockAudioParam(350);
    }
    connect(dest) {}
  }

  class MockAudioContext {
    constructor() {
      this.currentTime = 0;
      this.state = 'running';
      this.destination = {};
    }
    createGain() { return new MockGainNode(); }
    createOscillator() { return new MockOscillatorNode(); }
    createBiquadFilter() { return new MockBiquadFilterNode(); }
    resume() { this.state = 'running'; }
  }

  return { MockAudioContext, calls };
}

// LocalStorage Mock
class MockLocalStorage {
  constructor() {
    this.store = {};
  }
  getItem(key) {
    return this.store.hasOwnProperty(key) ? this.store[key] : null;
  }
  setItem(key, value) {
    this.store[key] = String(value);
  }
  removeItem(key) {
    delete this.store[key];
  }
  clear() {
    this.store = {};
  }
}

// Setup Environment
function setupEnvironment(initialLocalStorage = {}) {
  const { MockAudioContext, calls } = createWebAudioMock();
  const storage = new MockLocalStorage();
  Object.keys(initialLocalStorage).forEach(k => storage.setItem(k, initialLocalStorage[k]));

  // Replace external script tag with inline script
  const inlineHtml = htmlContent.replace('<script src="assets/audio_engine.js"></script>', `<script>${audioJsContent}</script>`);

  const dom = new JSDOM(inlineHtml, {
    runScripts: 'dangerously',
    resources: 'usable',
    url: 'http://localhost/',
    beforeParse(window) {
      window.AudioContext = MockAudioContext;
      window.webkitAudioContext = MockAudioContext;
      window.requestAnimationFrame = (cb) => setTimeout(cb, 16);
      window.cancelAnimationFrame = (id) => clearTimeout(id);

      // Attach LocalStorage
      Object.defineProperty(window, 'localStorage', {
        value: storage,
        writable: true
      });

      // Mock Canvas Context
      window.HTMLCanvasElement.prototype.getContext = function() {
        return {
          clearRect: () => {},
          save: () => {},
          restore: () => {},
          translate: () => {},
          rotate: () => {},
          beginPath: () => {},
          ellipse: () => {},
          fill: () => {},
          stroke: () => {}
        };
      };
    }
  });

  const { window } = dom;
  window.document.dispatchEvent(new window.Event('DOMContentLoaded'));
  return { dom, window, audioCalls: calls, storage };
}

// Test Runner Framework
const results = {
  passed: 0,
  failed: 0,
  tests: []
};

function recordTest(suite, name, pass, details) {
  results.tests.push({ suite, name, pass, details });
  if (pass) {
    results.passed++;
    console.log(`[PASS] [${suite}] ${name}`);
  } else {
    results.failed++;
    console.log(`[FAIL] [${suite}] ${name}\n       -> ${details}`);
  }
}

// ==========================================
// TEST SUITES
// ==========================================

async function runAllTests() {
  console.log("==================================================");
  console.log("STARTING EMPIRICAL CHALLENGE TEST SUITE (Zunda-OS 95)");
  console.log("==================================================\n");

  // ------------------------------------------
  // SUITE 1: WINDOW DRAG EVENT HANDLERS
  // ------------------------------------------
  {
    const { dom, window } = setupEnvironment();
    const document = window.document;

    const cliWin = document.getElementById('window-zundacli');
    const header = cliWin.querySelector('.window-header');

    // Test 1.1: Basic Mouse Drag
    let initialLeft = cliWin.offsetLeft;
    let initialTop = cliWin.offsetTop;

    const mouseDownEvt = new window.MouseEvent('mousedown', {
      bubbles: true,
      cancelable: true,
      clientX: 100,
      clientY: 100
    });
    header.dispatchEvent(mouseDownEvt);

    const mouseMoveEvt = new window.MouseEvent('mousemove', {
      bubbles: true,
      cancelable: true,
      clientX: 250,
      clientY: 300
    });
    document.dispatchEvent(mouseMoveEvt);

    let newLeft = parseInt(cliWin.style.left, 10);
    let newTop = parseInt(cliWin.style.top, 10);

    const draggedSuccessfully = (newLeft === initialLeft + 150) && (newTop === initialTop + 200);
    recordTest("Suite 1: Drag", "Basic Mouse Drag Movement", draggedSuccessfully, 
      `Expected left: ${initialLeft + 150}px, top: ${initialTop + 200}px | Actual left: ${cliWin.style.left}, top: ${cliWin.style.top}`);

    // Test 1.2: Off-Screen Drag (Negative Coordinates)
    const moveOffScreenNeg = new window.MouseEvent('mousemove', {
      bubbles: true,
      cancelable: true,
      clientX: -1000,
      clientY: -1000
    });
    document.dispatchEvent(moveOffScreenNeg);

    const negLeft = parseInt(cliWin.style.left, 10);
    const negTop = parseInt(cliWin.style.top, 10);
    const hasOffScreenBoundsProtection = (negLeft >= 0 && negTop >= 0);

    recordTest("Suite 1: Drag", "Off-Screen Drag Protection (Negative Boundary)", hasOffScreenBoundsProtection,
      `Window dragged to negative coordinates: left=${negLeft}px, top=${negTop}px. No minimum 0px clamping implemented!`);

    // Test 1.3: Off-Screen Drag (Viewport Over-extension)
    const moveOffScreenFar = new window.MouseEvent('mousemove', {
      bubbles: true,
      cancelable: true,
      clientX: 10000,
      clientY: 10000
    });
    document.dispatchEvent(moveOffScreenFar);

    const mouseUpEvt = new window.MouseEvent('mouseup', { bubbles: true, cancelable: true });
    document.dispatchEvent(mouseUpEvt);

    const farLeft = parseInt(cliWin.style.left, 10);
    const farTop = parseInt(cliWin.style.top, 10);
    const hasMaxBoundsProtection = (farLeft <= (window.innerWidth || 1920) - 100 && farTop <= (window.innerHeight || 1080) - 100);

    recordTest("Suite 1: Drag", "Off-Screen Drag Protection (Viewport Boundary)", hasMaxBoundsProtection,
      `Window dragged far off-screen: left=${farLeft}px, top=${farTop}px. No viewport boundary clamping!`);

    // Test 1.4: Touch Drag Support
    const indexHtmlRaw = fs.readFileSync(htmlPath, 'utf8');
    const hasTouchListenersInCode = indexHtmlRaw.includes('touchstart') || indexHtmlRaw.includes('touchmove');
    recordTest("Suite 1: Drag", "Touch Screen Drag Support", hasTouchListenersInCode,
      `Window header script lacks 'touchstart', 'touchmove', 'touchend' event listeners! Mobile touch drag is completely unsupported.`);

    // Test 1.5: Stray mousemove/mouseup without console crash
    let consoleErrors = [];
    window.console.error = (msg) => consoleErrors.push(msg);
    document.dispatchEvent(new window.MouseEvent('mousemove', { clientX: 50, clientY: 50 }));
    document.dispatchEvent(new window.MouseEvent('mouseup'));
    recordTest("Suite 1: Drag", "Stray Mouse Event Handling", consoleErrors.length === 0,
      `Console errors captured: ${consoleErrors.join('; ')}`);
  }

  // ------------------------------------------
  // SUITE 2: WINDOW FOCUS STACKING & ACTIVE CLASS
  // ------------------------------------------
  {
    const { dom, window } = setupEnvironment();
    const document = window.document;

    const cliWin = document.getElementById('window-zundacli');
    const cookbookWin = document.getElementById('window-cookbook');
    const vnWin = document.getElementById('window-vntalk');

    // Open Cookbook and VN Talk
    cookbookWin.classList.remove('hidden');
    vnWin.classList.remove('hidden');

    // Test 2.1: Focus switching - click Cookbook header
    const cookbookHeader = cookbookWin.querySelector('.window-header');
    cookbookHeader.dispatchEvent(new window.MouseEvent('mousedown', { bubbles: true }));

    const cookbookZ = parseInt(cookbookWin.style.zIndex, 10);
    const cliZ = parseInt(cliWin.style.zIndex || '0', 10);
    const cookbookIsActive = cookbookWin.classList.contains('window-active') || cookbookWin.classList.contains('active-window');
    const cliIsInactive = cliWin.classList.contains('window-inactive') || cliWin.classList.contains('inactive-window');

    recordTest("Suite 2: Focus Stacking", "Clicking Window Updates Z-Index & Active Class", 
      (cookbookZ > cliZ) && cookbookIsActive && cliIsInactive,
      `Cookbook Z-index: ${cookbookZ}, CLI Z-index: ${cliZ}, Cookbook Active: ${cookbookIsActive}, CLI Inactive: ${cliIsInactive}`);

    // Test 2.2: Stacking Order Cycle
    const vnHeader = vnWin.querySelector('.window-header');
    vnHeader.dispatchEvent(new window.MouseEvent('mousedown', { bubbles: true }));
    const vnZ = parseInt(vnWin.style.zIndex, 10);
    recordTest("Suite 2: Focus Stacking", "Sequential Focus Z-Index Increment",
      (vnZ > cookbookZ),
      `VN Z-Index: ${vnZ}, Cookbook Z-Index: ${cookbookZ}`);

    // Test 2.3: Focus behavior on Close/Minimize of active top window
    // Active window is vnWin. Let's close vnWin.
    const closeBtn = vnWin.querySelector('.win-btn.win-close');
    closeBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const remainingActive = document.querySelector('.window:not(.hidden).window-active, .window:not(.hidden).active-window');
    recordTest("Suite 2: Focus Stacking", "Active Window Fallback on Close/Minimize",
      remainingActive !== null,
      `When top active window was closed, no remaining visible window was activated! Remaining active window: ${remainingActive ? remainingActive.id : 'NONE'}`);
  }

  // ------------------------------------------
  // SUITE 3: WINDOW CONTROLS & TASKBAR SYNC
  // ------------------------------------------
  {
    const { dom, window } = setupEnvironment();
    const document = window.document;

    const cliWin = document.getElementById('window-zundacli');
    const cookbookWin = document.getElementById('window-cookbook');
    const taskbarWindows = document.getElementById('taskbar-windows');

    // Test 3.1: Maximize Toggle
    const maxBtn = cliWin.querySelector('.win-btn.win-maximize');
    maxBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const isMaximized = cliWin.classList.contains('maximized');
    recordTest("Suite 3: Controls & Taskbar", "Maximize Button Toggles .maximized Class",
      isMaximized, `CLI window maximized class present: ${isMaximized}`);

    // Test 3.2: Minimize Window & Taskbar Synchronization
    const minBtn = cliWin.querySelector('.win-btn.win-minimize');
    minBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const cliIsHidden = cliWin.classList.contains('hidden');
    const taskbarBtnForCli = taskbarWindows.querySelector('button[data-window-target="window-zundacli"]');

    recordTest("Suite 3: Controls & Taskbar", "Minimize Window Hides Window", cliIsHidden, `CLI hidden: ${cliIsHidden}`);

    // Standard Win95 Taskbar check: Minimized window MUST keep its button in the taskbar!
    recordTest("Suite 3: Controls & Taskbar", "Taskbar Preserves Minimized Window Button (Win95 Standard)",
      taskbarBtnForCli !== null,
      `When window was minimized, updateTaskbar() removed its taskbar button entirely! User cannot un-minimize window from taskbar.`);

    // Test 3.3: Taskbar Item Click Un-minimizes Window
    if (taskbarBtnForCli) {
      taskbarBtnForCli.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
      recordTest("Suite 3: Controls & Taskbar", "Taskbar Button Click Unminimizes Window",
        !cliWin.classList.contains('hidden'),
        `CLI hidden state after taskbar click: ${cliWin.classList.contains('hidden')}`);
    }

    // Test 3.4: Close Window Removes Taskbar Button
    cookbookWin.classList.remove('hidden');
    const closeBtn = cookbookWin.querySelector('.win-btn.win-close');
    closeBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const taskbarBtnForCookbook = taskbarWindows.querySelector('button[data-window-target="window-cookbook"]');
    recordTest("Suite 3: Controls & Taskbar", "Close Window Removes Taskbar Button",
      taskbarBtnForCookbook === null,
      `Closed window taskbar button present: ${taskbarBtnForCookbook !== null}`);
  }

  // ------------------------------------------
  // SUITE 4: START MENU & AUTO-CLOSE & KEYBOARD
  // ------------------------------------------
  {
    const { dom, window } = setupEnvironment();
    const document = window.document;

    const startBtn = document.getElementById('start-btn');
    const startMenu = document.getElementById('start-menu');

    // Test 4.1: Start Button Toggle
    startBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const menuOpen = !startMenu.classList.contains('hidden') && startBtn.classList.contains('start-btn-active');
    recordTest("Suite 4: Start Menu", "Start Button Opens Start Menu", menuOpen,
      `Start menu hidden: ${startMenu.classList.contains('hidden')}, Button active: ${startBtn.classList.contains('start-btn-active')}`);

    // Test 4.2: Click Outside Auto-Close
    const desktop = document.getElementById('desktop');
    document.dispatchEvent(new window.MouseEvent('click', { bubbles: true, target: desktop }));
    const menuClosedAfterOutsideClick = startMenu.classList.contains('hidden') && !startBtn.classList.contains('start-btn-active');
    recordTest("Suite 4: Start Menu", "Click Outside Auto-Closes Start Menu", menuClosedAfterOutsideClick,
      `Start menu hidden after click outside: ${startMenu.classList.contains('hidden')}`);

    // Test 4.3: Start Menu Item Launches Window & Closes Menu
    startBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    const cookbookMenuItem = startMenu.querySelector('button[data-open-window="window-cookbook"]');
    cookbookMenuItem.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));

    const cookbookWin = document.getElementById('window-cookbook');
    const cookbookOpened = !cookbookWin.classList.contains('hidden');
    const menuAutoClosed = startMenu.classList.contains('hidden');

    recordTest("Suite 4: Start Menu", "Start Menu Item Launches Window & Auto-Closes",
      cookbookOpened && menuAutoClosed,
      `Cookbook opened: ${cookbookOpened}, Start menu auto-closed: ${menuAutoClosed}`);

    // Test 4.4: Keyboard Shortcut (Ctrl+Esc or Escape)
    const indexHtmlRaw = fs.readFileSync(htmlPath, 'utf8');
    const startMenuKeyboardHandled = indexHtmlRaw.includes('Escape') && indexHtmlRaw.includes('startMenu');

    recordTest("Suite 4: Start Menu", "Keyboard Shortcut (Ctrl+Esc / Escape) Opens Start Menu",
      startMenuKeyboardHandled,
      `QuickStart.txt advertises Ctrl+Esc shortcut, but index.html has no keydown listener for Ctrl+Esc or Escape for Start Menu!`);
  }

  // ------------------------------------------
  // SUITE 5: AUDIO ENGINE SYNTHESIZERS & LOCALSTORAGE
  // ------------------------------------------
  {
    // Test 5.1: LocalStorage Saved Mute Loading on Init
    {
      const { dom, window, audioCalls } = setupEnvironment({ 'zunda_os_muted': 'true' });
      window.ZundaAudio.init();
      recordTest("Suite 5: Audio Engine", "Init loads saved Mute state from LocalStorage",
        window.ZundaAudio.isMuted === true,
        `ZundaAudio.isMuted: ${window.ZundaAudio.isMuted} (Expected: true)`);
    }

    // Test 5.2: LocalStorage Saved Volume Loading on Init
    {
      const { dom, window, storage } = setupEnvironment({ 'zunda_os_volume': '0.35' });
      window.ZundaAudio.init();
      recordTest("Suite 5: Audio Engine", "Init loads saved Volume state from LocalStorage",
        window.ZundaAudio.volume === 0.35,
        `ZundaAudio.volume: ${window.ZundaAudio.volume} (Expected: 0.35). Note: ZundaAudio.init() ignores saved zunda_os_volume key!`);
    }

    // Test 5.3: playClickSFX Variants & Invalid Variant Fallback
    {
      const { dom, window, audioCalls } = setupEnvironment();
      window.ZundaAudio.init();

      audioCalls.oscCreated = 0;
      window.playClickSFX('down');
      window.playClickSFX('up');
      window.playClickSFX('start');

      const validCallsOk = audioCalls.oscCreated === 3;

      audioCalls.scheduledValues = [];
      window.playClickSFX('invalid_variant');

      const setGainForInvalid = audioCalls.scheduledValues.some(v => v.type === 'setValueAtTime' && (v.val === 0.3 || v.val === 0.2 || v.val === 0.25));

      recordTest("Suite 5: Audio Engine", "playClickSFX Handles Valid Variants", validCallsOk,
        `Oscillators created: ${audioCalls.oscCreated}`);
      recordTest("Suite 5: Audio Engine", "playClickSFX Prevents Un-attenuated Beep on Invalid Variant", setGainForInvalid,
        `Invalid variant played oscillator without setting gain ramp in any branch! Defaults to 100% volume 440Hz square wave.`);
    }

    // Test 5.4: playWindowSFX & playKeySFX
    {
      const { dom, window, audioCalls } = setupEnvironment();
      window.ZundaAudio.init();

      audioCalls.oscCreated = 0;
      window.playWindowSFX('focus');
      window.playWindowSFX('drag');
      window.playWindowSFX('minimize');
      window.playWindowSFX('maximize');
      window.playWindowSFX('close');

      const sfxCount = audioCalls.oscCreated;
      recordTest("Suite 5: Audio Engine", "playWindowSFX Synthesizes Window Sounds", sfxCount > 0,
        `Oscillators created for window SFX: ${sfxCount}`);

      audioCalls.oscCreated = 0;
      window.playKeySFX('a');
      window.playKeySFX('Enter');
      recordTest("Suite 5: Audio Engine", "playKeySFX Synthesizes Typing Clicks", audioCalls.oscCreated === 2,
        `Oscillators created for key SFX: ${audioCalls.oscCreated}`);
    }

    // Test 5.5: BGM Toggle & Arpeggiator Timer
    {
      const { dom, window, audioCalls } = setupEnvironment();
      window.ZundaAudio.init();

      const bgmStarted = window.toggleCozyBGM();
      const isPlaying1 = window.ZundaAudio.bgmPlaying;
      const hasInterval = window.ZundaAudio.bgmInterval !== null;

      window.toggleCozyBGM(); // stop
      const isPlaying2 = window.ZundaAudio.bgmPlaying;

      recordTest("Suite 5: Audio Engine", "toggleCozyBGM Starts and Stops BGM",
        bgmStarted && isPlaying1 && hasInterval && !isPlaying2,
        `Started: ${bgmStarted}, Playing1: ${isPlaying1}, Interval: ${hasInterval}, Playing2: ${isPlaying2}`);
    }

    // Test 5.6: BGM Rapid Toggle Race Condition
    {
      const { dom, window } = setupEnvironment();
      window.ZundaAudio.init();

      // Call 1: Start
      window.toggleCozyBGM();
      const osc1 = window.ZundaAudio.bgmPadOscs;

      // Call 2: Stop (queues 1050ms setTimeout)
      window.toggleCozyBGM();

      // Call 3: Start immediately (within 100ms)
      window.toggleCozyBGM();
      const osc3 = window.ZundaAudio.bgmPadOscs;

      // Fast-forward timer by 1150ms to trigger Call 2's setTimeout callback
      await new Promise(r => setTimeout(r, 1150));

      const oscAfterTimeout = window.ZundaAudio.bgmPadOscs;

      recordTest("Suite 5: Audio Engine", "BGM Rapid Toggle Race Condition Protection",
        oscAfterTimeout !== null && window.ZundaAudio.bgmPlaying === true,
        `Rapid start->stop->start left bgmPadOscs nullified! Timeout from previous stop killed active BGM oscillators.`);
    }
  }

  console.log("\n==================================================");
  console.log(`TEST SUMMARY: TOTAL=${results.passed + results.failed} | PASSED=${results.passed} | FAILED=${results.failed}`);
  console.log("==================================================\n");

  return results;
}

runAllTests().catch(err => console.error("Test execution error:", err));
