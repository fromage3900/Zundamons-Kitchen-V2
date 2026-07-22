/**
 * Empirical Test Harness for Desktop Widgets & UI/UX (Milestone 2)
 */

const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const siteDir = path.resolve(__dirname, '../../site');
const htmlPath = path.join(siteDir, 'index.html');
const appJsPath = path.join(siteDir, 'app.js');
const audioEngineJsPath = path.join(siteDir, 'assets/audio_engine.js');
const windowManagerJsPath = path.join(siteDir, 'window_manager.js');
const terminalJsPath = path.join(siteDir, 'terminal.js');

const htmlContent = fs.readFileSync(htmlPath, 'utf8');
const appJsContent = fs.readFileSync(appJsPath, 'utf8');
const audioEngineJsContent = fs.readFileSync(audioEngineJsPath, 'utf8');
const windowManagerJsContent = fs.readFileSync(windowManagerJsPath, 'utf8');
const terminalJsContent = fs.readFileSync(terminalJsPath, 'utf8');

console.log('=== RUNNING EMPIRICAL TESTS FOR MILESTONE 2 DESKTOP WIDGETS ===\n');

const dom = new JSDOM(htmlContent, {
  url: 'http://localhost/',
  runScripts: 'dangerously',
  resources: 'usable'
});

const { window } = dom;
const { document } = window;

window.requestAnimationFrame = (cb) => setTimeout(cb, 16);
window.cancelAnimationFrame = (id) => clearTimeout(id);

// Mock Web Audio API for JSDOM environment
class MockAudioContext {
  constructor() {
    this.state = 'running';
    this.currentTime = 0;
    this.destination = {};
  }
  createGain() {
    return {
      gain: {
        setValueAtTime: () => {},
        linearRampToValueAtTime: () => {},
        exponentialRampToValueAtTime: () => {},
        value: 1
      },
      connect: () => {}
    };
  }
  createOscillator() {
    return {
      type: 'sine',
      frequency: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} },
      connect: () => {},
      start: () => {},
      stop: () => {},
      disconnect: () => {}
    };
  }
  createBiquadFilter() {
    return {
      type: 'lowpass',
      frequency: { setValueAtTime: () => {} },
      connect: () => {}
    };
  }
  createBufferSource() {
    return {
      buffer: null,
      loop: false,
      connect: () => {},
      start: () => {},
      stop: () => {}
    };
  }
  createBuffer() {
    return { getChannelData: () => new Float32Array(100) };
  }
  resume() {
    return Promise.resolve();
  }
}

window.AudioContext = MockAudioContext;
window.webkitAudioContext = MockAudioContext;

// Comprehensive Mock HTMLCanvasElement getContext for JSDOM
window.HTMLCanvasElement.prototype.getContext = function() {
  return {
    clearRect: () => {},
    beginPath: () => {},
    closePath: () => {},
    arc: () => {},
    fill: () => {},
    stroke: () => {},
    lineTo: () => {},
    moveTo: () => {},
    save: () => {},
    restore: () => {},
    scale: () => {},
    rotate: () => {},
    translate: () => {},
    transform: () => {},
    setTransform: () => {},
    globalAlpha: 1,
    fillStyle: '',
    strokeStyle: '',
    lineWidth: 1
  };
};

// Execute scripts using dom.window.eval
try {
  window.eval(audioEngineJsContent);
  window.eval(windowManagerJsContent);
  window.eval(terminalJsContent);
  window.eval(appJsContent);
} catch (e) {
  console.error('[SCRIPT EVAL ERROR]', e);
}

// Instantiate MainApp manually if not already instantiated
if (window.MainApp) {
  const app = new window.MainApp();
  app.init();
  window.mainApp = app;
}

const results = [];

function recordResult(testName, passed, details) {
  results.push({ testName, passed, details });
  console.log(`[${passed ? 'PASS' : 'FAIL'}] ${testName}: ${details}`);
}

// 1. DOM ID Alignment Verification
console.log('\n--- 1. DOM ID Alignment Verification ---');

const targetIDs = [
  'widget-digital-time',
  'widget-weather-pill',
  'widget-play-bgm',
  'widget-next-track',
  'rain-sfx-slider',
  'widget-zunda-sticker',
  'widget-speech-bubble'
];

targetIDs.forEach(id => {
  const el = document.getElementById(id);
  if (el) {
    recordResult(`DOM ID Alignment: #${id}`, true, `Element found <${el.tagName.toLowerCase()}> tag in HTML`);
  } else {
    recordResult(`DOM ID Alignment: #${id}`, false, `Element #${id} NOT found in HTML`);
  }
});

// Check sub-IDs used in app.js
const subIDs = [
  'widget-weather-icon',
  'widget-weather-text',
  'jukebox-disc-icon',
  'jukebox-track-title',
  'bgm-toggle',
  'sfx-toggle'
];

subIDs.forEach(id => {
  const el = document.getElementById(id);
  if (el) {
    recordResult(`Sub DOM ID: #${id}`, true, `Element found <${el.tagName.toLowerCase()}> tag in HTML`);
  } else {
    recordResult(`Sub DOM ID: #${id}`, false, `Element #${id} NOT found in HTML`);
  }
});

// 2. MainApp Instance & Clock HH:MM:SS Live Ticking
console.log('\n--- 2. Clock Live Ticking Test ---');
if (window.mainApp) {
  recordResult('MainApp Instance', true, 'window.mainApp initialized successfully');
} else {
  recordResult('MainApp Instance', false, 'window.mainApp is undefined');
}

const timeEl = document.getElementById('widget-digital-time');

// Simulate clock interval tick
setTimeout(() => {
  const timeTextAfter = timeEl ? timeEl.textContent : '';
  const isFormatted = /\d{1,2}:\d{2}:\d{2}/.test(timeTextAfter);
  recordResult('Clock Live Ticking Format', isFormatted, `Live clock formatted time output: "${timeTextAfter}"`);
}, 1100);

// 3. Weather Status Click Cycling
console.log('\n--- 3. Weather Status Click Cycling ---');
const weatherPill = document.getElementById('widget-weather-pill');
const weatherIcon = document.getElementById('widget-weather-icon');
const weatherText = document.getElementById('widget-weather-text');

if (weatherPill && weatherIcon && weatherText) {
  const initialIcon = weatherIcon.textContent;
  const initialText = weatherText.textContent;

  weatherPill.click(); // Click 1 -> Sakura Forest
  const c1Icon = weatherIcon.textContent;
  const c1Text = weatherText.textContent;

  weatherPill.click(); // Click 2 -> Cozy Rain
  const c2Icon = weatherIcon.textContent;
  const c2Text = weatherText.textContent;

  weatherPill.click(); // Click 3 -> Clear Night
  const c3Icon = weatherIcon.textContent;
  const c3Text = weatherText.textContent;

  weatherPill.click(); // Click 4 -> Back to Clear (Wrap)
  const c4Icon = weatherIcon.textContent;
  const c4Text = weatherText.textContent;

  const cyclePassed = c1Text.includes('Sakura') && c2Text.includes('Cozy Rain') && c3Text.includes('Starry') && c4Text === initialText;
  recordResult('Weather Click Cycling', cyclePassed, `Cycles through 4 states correctly: Initial="${initialText}", 1="${c1Text}", 2="${c2Text}", 3="${c3Text}", 4="${c4Text}"`);
} else {
  recordResult('Weather Click Cycling', false, 'Weather elements missing');
}

// 4. Jukebox BGM Play/Pause & Spinning Disc Toggle
console.log('\n--- 4. Jukebox BGM Play/Pause & Spinning Disc Toggle ---');
const playBgmBtn = document.getElementById('widget-play-bgm');
const discIcon = document.getElementById('jukebox-disc-icon');

if (playBgmBtn && discIcon) {
  const initialBtnText = playBgmBtn.textContent;
  const initialSpin = discIcon.classList.contains('spinning');

  playBgmBtn.click(); // Play
  const playBtnText = playBgmBtn.textContent;
  const playSpin = discIcon.classList.contains('spinning');
  const bgmStatePlay = window.ZundaAudio ? window.ZundaAudio.bgmPlaying : false;

  playBgmBtn.click(); // Pause
  const pauseBtnText = playBgmBtn.textContent;
  const pauseSpin = discIcon.classList.contains('spinning');
  const bgmStatePause = window.ZundaAudio ? window.ZundaAudio.bgmPlaying : true;

  const playPausePassed = (playBtnText.includes('Pause') && playSpin && bgmStatePlay) &&
                            (pauseBtnText.includes('▶') && !pauseSpin && !bgmStatePause);
  recordResult('Jukebox BGM Play/Pause Toggle', playPausePassed, 
    `Play: text="${playBtnText}", spinning=${playSpin}, bgmPlaying=${bgmStatePlay} | Pause: text="${pauseBtnText}", spinning=${pauseSpin}, bgmPlaying=${bgmStatePause}`);
} else {
  recordResult('Jukebox BGM Play/Pause Toggle', false, 'Jukebox elements missing');
}

// 4b. Jukebox Next Track Toggle
console.log('\n--- 4b. Jukebox Next Track Toggle ---');
const nextTrackBtn = document.getElementById('widget-next-track');
const trackTitleEl = document.getElementById('jukebox-track-title');

if (nextTrackBtn && trackTitleEl) {
  const initialTitle = trackTitleEl.textContent;
  nextTrackBtn.click(); // Track 1
  const t1 = trackTitleEl.textContent;
  nextTrackBtn.click(); // Track 2
  const t2 = trackTitleEl.textContent;
  nextTrackBtn.click(); // Track 0
  const t3 = trackTitleEl.textContent;

  recordResult('Jukebox Next Track Rotation', (t1 !== initialTitle && t2 !== t1), `Initial="${initialTitle}" -> T1="${t1}" -> T2="${t2}" -> T3="${t3}"`);
} else {
  recordResult('Jukebox Next Track Rotation', false, 'Next track elements missing');
}

// 5. Rain SFX Slider Test
console.log('\n--- 5. Rain SFX Slider Test ---');
const rainSlider = document.getElementById('rain-sfx-slider');
if (rainSlider) {
  const initialVal = rainSlider.value;
  
  // Dispatch input event to set volume to 80
  rainSlider.value = "80";
  rainSlider.dispatchEvent(new window.Event('input', { bubbles: true }));
  const vol80 = window.ZundaAudio ? window.ZundaAudio.rainVolume : null;
  const rainPlaying80 = window.ZundaAudio ? window.ZundaAudio.rainPlaying : false;

  // Dispatch input event to set volume to 0
  rainSlider.value = "0";
  rainSlider.dispatchEvent(new window.Event('input', { bubbles: true }));
  const vol0 = window.ZundaAudio ? window.ZundaAudio.rainVolume : null;
  const rainPlaying0 = window.ZundaAudio ? window.ZundaAudio.rainPlaying : true;

  const sliderPassed = (vol80 === 0.8 && rainPlaying80) && (vol0 === 0 && !rainPlaying0);
  recordResult('Rain SFX Slider', sliderPassed, `Initial=${initialVal}, Val 80 -> vol=${vol80}, rainPlaying=${rainPlaying80} | Val 0 -> vol=${vol0}, rainPlaying=${rainPlaying0}`);
} else {
  recordResult('Rain SFX Slider', false, 'Rain slider element missing');
}

// 6. Zundamon Sticker & Speech Bubble Updates
console.log('\n--- 6. Zundamon Sticker & Speech Bubble Updates ---');
const zundaSticker = document.getElementById('widget-zunda-sticker');
const speechBubble = document.getElementById('widget-speech-bubble');

if (zundaSticker && speechBubble) {
  const initialBubbleText = speechBubble.textContent;
  
  zundaSticker.click(); // Click 1
  const click1Text = speechBubble.textContent;
  const opacity1 = speechBubble.style.opacity;

  zundaSticker.click(); // Click 2
  const click2Text = speechBubble.textContent;

  zundaSticker.click(); // Click 3
  const click3Text = speechBubble.textContent;

  const stickerPassed = (click1Text !== initialBubbleText) && (click2Text !== click1Text) && (opacity1 === '1');
  recordResult('Zundamon Sticker Interactivity', stickerPassed, 
    `Initial="${initialBubbleText}" -> C1="${click1Text}", opacity=${opacity1} -> C2="${click2Text}" -> C3="${click3Text}"`);
} else {
  recordResult('Zundamon Sticker Interactivity', false, 'Sticker or bubble element missing');
}

setTimeout(() => {
  console.log('\n=== EMPIRICAL TEST SUMMARY ===');
  const total = results.length;
  const passedCount = results.filter(r => r.passed).length;
  const failedCount = total - passedCount;
  console.log(`Total: ${total} | Passed: ${passedCount} | Failed: ${failedCount}`);
  process.exit(failedCount > 0 ? 1 : 0);
}, 1500);
