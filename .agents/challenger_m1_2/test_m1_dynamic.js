/**
 * Dynamic JSDOM Runtime Simulation Test Suite for Milestone 1
 * Location: g:\Zundamons-kItchen-V2\.agents\challenger_m1_2\test_m1_dynamic.js
 */

const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const siteDir = path.join(__dirname, '..', '..', 'site');
const htmlPath = path.join(siteDir, 'index.html');
const jsPath = path.join(siteDir, 'app.js');
const windowManagerPath = path.join(siteDir, 'window_manager.js');
const audioEnginePath = path.join(siteDir, 'assets', 'audio_engine.js');

const htmlContent = fs.readFileSync(htmlPath, 'utf8');
const jsContent = fs.readFileSync(jsPath, 'utf8');
const windowManagerContent = fs.readFileSync(windowManagerPath, 'utf8');
const audioEngineContent = fs.readFileSync(audioEnginePath, 'utf8');

console.log("=================================================");
console.log("   DYNAMIC JSDOM SIMULATION — MILESTONE 1 UI/UX");
console.log("=================================================\n");

async function runTests() {
  const dom = new JSDOM(htmlContent, {
    url: 'http://localhost/site/index.html',
    runScripts: 'outside-only',
    resources: 'usable'
  });

  const { window } = dom;
  const { document } = window;

  window.AudioContext = window.AudioContext || function() {
    return {
      currentTime: 0,
      state: 'running',
      createGain: () => ({ gain: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {} }),
      createOscillator: () => ({ type: '', frequency: { setValueAtTime: () => {}, exponentialRampToValueAtTime: () => {} }, connect: () => {}, start: () => {}, stop: () => {} }),
      destination: {}
    };
  };

  window.HTMLCanvasElement.prototype.getContext = function(type) {
    if (type === '2d') {
      return {
        clearRect: () => {},
        fillRect: () => {},
        beginPath: () => {},
        closePath: () => {},
        moveTo: () => {},
        lineTo: () => {},
        fill: () => {},
        stroke: () => {},
        save: () => {},
        restore: () => {},
        translate: () => {},
        rotate: () => {},
        scale: () => {}
      };
    }
    return null;
  };

  window.navigator.clipboard = {
    writeText: (text) => Promise.resolve()
  };

  window.eval(audioEngineContent);
  window.eval(windowManagerContent);
  window.eval(jsContent);

  const evt = document.createEvent('Event');
  evt.initEvent('DOMContentLoaded', true, true);
  document.dispatchEvent(evt);

  let passed = 0;
  let failed = 0;

  function assert(condition, message, details = '') {
    if (condition) {
      console.log(`[PASS] ${message}`);
      passed++;
    } else {
      console.log(`[FAIL] ${message}`);
      if (details) console.log(`       Details: ${details}`);
      failed++;
    }
  }

  // ----------------------------------------------------------------------------
  // Test 1: Window Manager & Recipes Link Click
  // ----------------------------------------------------------------------------
  console.log("--- Test 1: Recipes Anchor & Window Manager Binding ---");

  const recipesLink = document.querySelector('a[href="#recipes"]');
  assert(recipesLink !== null, `Recipes link element <a href="#recipes"> found in DOM`);

  const cookbookWinBefore = document.getElementById('window-cookbook');
  assert(cookbookWinBefore && cookbookWinBefore.classList.contains('hidden'), `Cookbook window is initially hidden`);

  if (recipesLink) {
    recipesLink.dispatchEvent(new window.MouseEvent('click', { bubbles: true, cancelable: true }));

    const cookbookWinAfter = document.getElementById('window-cookbook');
    assert(!cookbookWinAfter.classList.contains('hidden'), `Clicking Recipes link opens Cookbook window ('window-cookbook')`);

    const anchorTargetEl = document.getElementById('recipes');
    assert(anchorTargetEl !== null, `DOM contains element matching anchor href="#recipes"`, 
      anchorTargetEl !== null ? `Found element` : `No element with id="recipes" in DOM! Browser anchor jump fails/resets!`);
  }

  // ----------------------------------------------------------------------------
  // Test 2: Promo Code Copy Buttons & Toast Delivery
  // ----------------------------------------------------------------------------
  console.log("\n--- Test 2: Promo Code Copy Buttons & Toast Notifications ---");

  const toastContainer = document.getElementById('toast-container');
  assert(toastContainer !== null, `#toast-container element exists in DOM`);

  const copyBtns = document.querySelectorAll('.copy-code-btn');
  console.log(`Found ${copyBtns.length} '.copy-code-btn' elements in DOM.`);

  if (copyBtns.length > 0) {
    const firstBtn = copyBtns[0];
    const codeToCopy = firstBtn.dataset.code;
    assert(!!codeToCopy, `First promo copy button has data-code="${codeToCopy}"`);

    // Simulate click
    firstBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true, cancelable: true }));

    // Wait for promise microtask
    await new Promise(r => setTimeout(r, 50));

    const toastMsg = toastContainer.querySelector('.toast-message');
    assert(toastMsg !== null, `Toast notification element created in #toast-container upon promo copy button click`);
    if (toastMsg) {
      assert(toastMsg.textContent.includes(codeToCopy), `Toast message contains copied code "${codeToCopy}" (Text: "${toastMsg.textContent.trim()}")`);
    }
  }

  // ----------------------------------------------------------------------------
  // Test 3: Particle Canvas (#star-canvas vs #star-sparkle-canvas) ---
  // ----------------------------------------------------------------------------
  console.log("\n--- Test 3: Particle Canvas (#star-canvas vs #star-sparkle-canvas) ---");

  const starCanvasHtml = document.getElementById('star-canvas');
  assert(starCanvasHtml !== null, `<canvas id="star-canvas"> exists in HTML`);

  const starSparkleCanvasHtml = document.getElementById('star-sparkle-canvas');
  assert(starSparkleCanvasHtml === null, `<canvas id="star-sparkle-canvas"> does NOT exist in HTML`);

  // Check if #star-canvas width/height modified by mainApp.initParticleCanvas()
  const isCanvasResized = starCanvasHtml && (starCanvasHtml.width > 0 || starCanvasHtml.height > 0);
  assert(isCanvasResized, `#star-canvas width/height initialized by particle system`, 
    isCanvasResized ? `Canvas dimensions: ${starCanvasHtml.width}x${starCanvasHtml.height}` : `#star-canvas width/height remains 0x0 because app.js targets 'star-sparkle-canvas'!`);

  // ----------------------------------------------------------------------------
  // Test 4: Start Menu & App Launcher Tiles ---
  // ----------------------------------------------------------------------------
  console.log("\n--- Test 4: Start Menu & App Launcher Tiles ---");

  const startBtn = document.getElementById('start-btn');
  const startMenu = document.getElementById('start-menu');

  assert(startBtn !== null, `Start button #start-btn exists`);
  assert(startMenu !== null && startMenu.classList.contains('hidden'), `Start menu popover #start-menu exists and is initially hidden`);

  if (startBtn && startMenu) {
    startBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true, cancelable: true }));
    assert(!startMenu.classList.contains('hidden'), `Clicking start button toggles start menu visibility`);
  }

  const appTiles = document.querySelectorAll('.os-app-tile');
  assert(appTiles.length === 7, `7 OS app tiles exist in desktop grid (Found: ${appTiles.length})`);

  console.log("\n=================================================");
  console.log(` DYNAMIC TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log("=================================================");
}

runTests();
