const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const htmlContent = fs.readFileSync(path.join(__dirname, '../../site/index.html'), 'utf8');

const dom = new JSDOM(htmlContent, {
  url: 'http://localhost/'
});

const { window } = dom;
const { document } = window;

global.window = window;
global.document = document;

// Set viewport dimensions
Object.defineProperty(window, 'innerWidth', { value: 1024, writable: true, configurable: true });
Object.defineProperty(window, 'innerHeight', { value: 768, writable: true, configurable: true });
Object.defineProperty(document.documentElement, 'clientWidth', { value: 1024, writable: true, configurable: true });
Object.defineProperty(document.documentElement, 'clientHeight', { value: 768, writable: true, configurable: true });

// Require WindowManager
const WindowManager = require('../../site/window_manager.js');

const results = [];

function assert(condition, message) {
  if (condition) {
    results.push({ pass: true, message });
    console.log(`  ✓ PASS: ${message}`);
  } else {
    results.push({ pass: false, message });
    console.error(`  ✗ FAIL: ${message}`);
  }
}

console.log('====================================================');
console.log('  EMPIRICAL TEST SUITE: site/window_manager.js');
console.log('====================================================\n');

// Initialize WindowManager instance
const wm = new WindowManager({
  container: document.getElementById('window-container'),
  taskbarWindows: document.getElementById('taskbar-windows'),
  startMenu: document.getElementById('start-menu'),
  startBtn: document.getElementById('start-btn')
});

wm.init();

// Mock offset dimensions for windows in JSDOM
function mockWindowMetrics(win, left = 60, top = 40, width = 680, height = 440) {
  win.style.left = `${left}px`;
  win.style.top = `${top}px`;
  win.style.width = `${width}px`;
  win.style.height = `${height}px`;

  Object.defineProperty(win, 'offsetLeft', { get: () => parseInt(win.style.left, 10) || 0, configurable: true });
  Object.defineProperty(win, 'offsetTop', { get: () => parseInt(win.style.top, 10) || 0, configurable: true });
  Object.defineProperty(win, 'offsetWidth', { get: () => parseInt(win.style.width, 10) || width, configurable: true });
  Object.defineProperty(win, 'offsetHeight', { get: () => parseInt(win.style.height, 10) || height, configurable: true });
}

// Mock metrics for all windows
wm.windows.forEach(w => mockWindowMetrics(w));

// Helper to query live taskbar button
function getTaskbarButton(windowId) {
  const taskbarContainer = document.getElementById('taskbar-windows');
  const taskbarBtns = Array.from(taskbarContainer.querySelectorAll('.taskbar-item'));
  return taskbarBtns.find(b => b.dataset.windowTarget === windowId || b.dataset.windowTarget === `window-${windowId}`);
}

// ----------------------------------------------------
// SUITE 1: Window Drag & Viewport Clamping (Mouse & Touch)
// ----------------------------------------------------
console.log('SUITE 1: Window Drag & Viewport Clamping (Mouse & Touch)');

const cliWin = wm.getWindow('window-zundacli');
mockWindowMetrics(cliWin, 60, 40, 680, 440);

const header = cliWin.querySelector('.window-header');

// Test 1.1: Mouse Drag Normal Move
console.log('\n--- Test 1.1: Mouse Drag Normal Move ---');
const mouseDownEvent = new window.MouseEvent('mousedown', {
  bubbles: true,
  cancelable: true,
  clientX: 100,
  clientY: 100
});
header.dispatchEvent(mouseDownEvent);

const mouseMoveEvent1 = new window.MouseEvent('mousemove', {
  bubbles: true,
  cancelable: true,
  clientX: 150,
  clientY: 150
});
document.dispatchEvent(mouseMoveEvent1);

assert(cliWin.style.left === '110px', `Window left updated correctly on mousemove (Expected: 110px, Actual: ${cliWin.style.left})`);
assert(cliWin.style.top === '90px', `Window top updated correctly on mousemove (Expected: 90px, Actual: ${cliWin.style.top})`);

// Test 1.2: Mouse Drag Off-Screen Left Clamping
console.log('\n--- Test 1.2: Mouse Drag Off-Screen Left Clamping ---');
const mouseMoveLeft = new window.MouseEvent('mousemove', {
  bubbles: true,
  cancelable: true,
  clientX: -500,
  clientY: 100
});
document.dispatchEvent(mouseMoveLeft);
assert(cliWin.style.left === '0px', `Window left clamped at 0px when dragged far left (Actual: ${cliWin.style.left})`);

// Test 1.3: Mouse Drag Off-Screen Top Clamping
console.log('\n--- Test 1.3: Mouse Drag Off-Screen Top Clamping ---');
const mouseMoveTop = new window.MouseEvent('mousemove', {
  bubbles: true,
  cancelable: true,
  clientX: 100,
  clientY: -500
});
document.dispatchEvent(mouseMoveTop);
assert(cliWin.style.top === '0px', `Window top clamped at 0px when dragged far top (Actual: ${cliWin.style.top})`);

// Test 1.4: Mouse Drag Off-Screen Right Clamping
console.log('\n--- Test 1.4: Mouse Drag Off-Screen Right Clamping ---');
const mouseMoveRight = new window.MouseEvent('mousemove', {
  bubbles: true,
  cancelable: true,
  clientX: 2000,
  clientY: 100
});
document.dispatchEvent(mouseMoveRight);
assert(cliWin.style.left === '344px', `Window left clamped at 344px (viewportWidth - winWidth) when dragged far right (Actual: ${cliWin.style.left})`);

// Test 1.5: Mouse Drag Off-Screen Bottom Clamping
console.log('\n--- Test 1.5: Mouse Drag Off-Screen Bottom Clamping ---');
const mouseMoveBottom = new window.MouseEvent('mousemove', {
  bubbles: true,
  cancelable: true,
  clientX: 100,
  clientY: 2000
});
document.dispatchEvent(mouseMoveBottom);
assert(cliWin.style.top === '328px', `Window top clamped at 328px (viewportHeight - winHeight) when dragged far bottom (Actual: ${cliWin.style.top})`);

// Mouse Up
const mouseUpEvent = new window.MouseEvent('mouseup', { bubbles: true });
document.dispatchEvent(mouseUpEvent);

cliWin.style.left = '100px';
cliWin.style.top = '100px';
const mouseMoveAfterUp = new window.MouseEvent('mousemove', { bubbles: true, clientX: 200, clientY: 200 });
document.dispatchEvent(mouseMoveAfterUp);
assert(cliWin.style.left === '100px' && cliWin.style.top === '100px', 'Mouse drag unbinds after mouseup event');

// Reset window position
cliWin.style.left = '60px';
cliWin.style.top = '40px';

// Test 1.6: Touch Drag Normal & Clamped Move
console.log('\n--- Test 1.6: Touch Drag (touchstart, touchmove, touchend) & Clamping ---');

function createTouchEvent(type, touchList) {
  const evt = new window.CustomEvent(type, { bubbles: true, cancelable: true });
  evt.touches = touchList;
  return evt;
}

const touchStartEvt = createTouchEvent('touchstart', [{ clientX: 100, clientY: 100 }]);
header.dispatchEvent(touchStartEvt);

const touchMoveEvt1 = createTouchEvent('touchmove', [{ clientX: 180, clientY: 140 }]);
document.dispatchEvent(touchMoveEvt1);

assert(cliWin.style.left === '140px', `Touchmove updated left position (Expected: 140px, Actual: ${cliWin.style.left})`);
assert(cliWin.style.top === '80px', `Touchmove updated top position (Expected: 80px, Actual: ${cliWin.style.top})`);

// Touch move off-screen left and top
const touchMoveOffscreen = createTouchEvent('touchmove', [{ clientX: -999, clientY: -999 }]);
document.dispatchEvent(touchMoveOffscreen);
assert(cliWin.style.left === '0px', `Touchmove clamped left at 0px (Actual: ${cliWin.style.left})`);
assert(cliWin.style.top === '0px', `Touchmove clamped top at 0px (Actual: ${cliWin.style.top})`);

// Touch move off-screen right and bottom
const touchMoveOffscreen2 = createTouchEvent('touchmove', [{ clientX: 9999, clientY: 9999 }]);
document.dispatchEvent(touchMoveOffscreen2);
assert(cliWin.style.left === '344px', `Touchmove clamped right at 344px (Actual: ${cliWin.style.left})`);
assert(cliWin.style.top === '328px', `Touchmove clamped bottom at 328px (Actual: ${cliWin.style.top})`);

// Touch end
const touchEndEvt = createTouchEvent('touchend', []);
document.dispatchEvent(touchEndEvt);

cliWin.style.left = '100px';
cliWin.style.top = '100px';
const touchMoveAfterEnd = createTouchEvent('touchmove', [{ clientX: 500, clientY: 500 }]);
document.dispatchEvent(touchMoveAfterEnd);
assert(cliWin.style.left === '100px' && cliWin.style.top === '100px', 'Touch drag unbinds after touchend event');

// Test 1.7: Header Controls Exclusion (win-btn does not trigger drag)
console.log('\n--- Test 1.7: Header Controls Exclusion ---');
cliWin.style.left = '60px';
cliWin.style.top = '40px';
const minBtn = cliWin.querySelector('.win-minimize');
const btnMouseDown = new window.MouseEvent('mousedown', { bubbles: true, clientX: 100, clientY: 100 });
minBtn.dispatchEvent(btnMouseDown);

const btnMouseMove = new window.MouseEvent('mousemove', { bubbles: true, clientX: 300, clientY: 300 });
document.dispatchEvent(btnMouseMove);
assert(cliWin.style.left === '60px' && cliWin.style.top === '40px', 'Window drag excluded when clicking win-btn window control');


// ----------------------------------------------------
// SUITE 2: Active Focus Fallback
// ----------------------------------------------------
console.log('\nSUITE 2: Active Focus Fallback');

const cookbookWin = wm.getWindow('window-cookbook');
const vntalkWin = wm.getWindow('window-vntalk');
const quickstartWin = wm.getWindow('window-quickstart');

// Open CLI, Cookbook, VNTalk sequentially
wm.openWindow('window-zundacli');    // zIndex e.g. 101
wm.openWindow('window-cookbook');   // zIndex e.g. 102
wm.openWindow('window-vntalk');     // zIndex e.g. 103

assert(wm.activeWindow === vntalkWin, `VNTalk is initial active window (Actual: ${wm.activeWindow?.id})`);
assert(vntalkWin.classList.contains('active-window'), 'VNTalk has active-window class');
assert(cookbookWin.classList.contains('inactive-window'), 'Cookbook is inactive');

// Test 2.1: Close top window -> fallback to next highest visible window
console.log('\n--- Test 2.1: Close top window fallback ---');
wm.closeWindow('window-vntalk');
assert(vntalkWin.classList.contains('hidden'), 'VNTalk window is now hidden');
assert(wm.activeWindow === cookbookWin, `Focus fell back to Cookbook (Expected: window-cookbook, Actual: ${wm.activeWindow?.id})`);
assert(cookbookWin.classList.contains('active-window'), 'Cookbook now has active-window class');

// Test 2.2: Minimize top window -> fallback to next highest visible window
console.log('\n--- Test 2.2: Minimize top window fallback ---');
wm.minimizeWindow('window-cookbook');
assert(cookbookWin.classList.contains('hidden'), 'Cookbook window is now hidden');
assert(wm.activeWindow === cliWin, `Focus fell back to ZundaCLI (Expected: window-zundacli, Actual: ${wm.activeWindow?.id})`);
assert(cliWin.classList.contains('active-window'), 'ZundaCLI now has active-window class');

// Test 2.3: Close/Minimize all windows -> activeWindow becomes null
console.log('\n--- Test 2.3: Close all remaining windows fallback ---');
wm.minimizeWindow('window-zundacli');
wm.minimizeWindow('window-quickstart');
assert(wm.activeWindow === null, 'activeWindow is null when all windows are closed/minimized');
wm.windows.forEach(w => {
  assert(!w.classList.contains('active-window'), `Window ${w.id} does not have active-window class when all hidden`);
});


// ----------------------------------------------------
// SUITE 3: Taskbar Sync & Minimized Window Restoration
// ----------------------------------------------------
console.log('\nSUITE 3: Taskbar Sync & Minimized Window Restoration');

// Re-open ZundaCLI and Cookbook
wm.openWindow('window-zundacli');
wm.openWindow('window-cookbook');
// Cookbook is active, ZundaCLI is visible inactive, VNTalk and QuickStart are minimized (hidden).

// Test 3.1: Taskbar item status check
console.log('\n--- Test 3.1: Taskbar item status check ---');
let cliTbBtn = getTaskbarButton('window-zundacli');
let cookbookTbBtn = getTaskbarButton('window-cookbook');
let vntalkTbBtn = getTaskbarButton('window-vntalk');

assert(cookbookTbBtn && cookbookTbBtn.classList.contains('active'), 'Active window taskbar button has class "active"');
assert(cookbookTbBtn && !cookbookTbBtn.classList.contains('minimized'), 'Active window taskbar button does NOT have class "minimized"');

assert(cliTbBtn && !cliTbBtn.classList.contains('active') && !cliTbBtn.classList.contains('minimized'), 'Inactive visible window taskbar button is neither active nor minimized');

assert(vntalkTbBtn && vntalkTbBtn.classList.contains('minimized'), 'Minimized window taskbar button has class "minimized"');
assert(vntalkTbBtn && !vntalkTbBtn.classList.contains('active'), 'Minimized window taskbar button does NOT have class "active"');

// Test 3.2: Click minimized taskbar button -> restores window & makes active
console.log('\n--- Test 3.2: Restore minimized window via taskbar click ---');
vntalkTbBtn.click();
vntalkTbBtn = getTaskbarButton('window-vntalk'); // Re-query live element after click & taskbar rebuild
assert(!vntalkWin.classList.contains('hidden'), 'VNTalk window is unhidden after clicking taskbar item');
assert(wm.activeWindow === vntalkWin, 'VNTalk is now active window after taskbar restore');
assert(vntalkTbBtn && vntalkTbBtn.classList.contains('active'), 'VNTalk taskbar button now has class "active"');
assert(vntalkTbBtn && !vntalkTbBtn.classList.contains('minimized'), 'VNTalk taskbar button no longer has class "minimized"');

// Test 3.3: Click active window taskbar button -> minimizes window
console.log('\n--- Test 3.3: Minimize active window via taskbar click ---');
vntalkTbBtn.click(); // vntalk is currently active live button
vntalkTbBtn = getTaskbarButton('window-vntalk'); // Re-query live element
cookbookTbBtn = getTaskbarButton('window-cookbook');
assert(vntalkWin.classList.contains('hidden'), 'VNTalk window is hidden (minimized) after clicking active taskbar item');
assert(vntalkTbBtn && vntalkTbBtn.classList.contains('minimized'), 'VNTalk taskbar button now has class "minimized"');
assert(wm.activeWindow === cookbookWin, 'Focus fell back to Cookbook after active window was minimized via taskbar');

// Test 3.4: Click inactive visible window taskbar button -> brings to front & activates
console.log('\n--- Test 3.4: Focus inactive window via taskbar click ---');
cliTbBtn = getTaskbarButton('window-zundacli');
cliTbBtn.click(); // CLI was inactive visible live button
cliTbBtn = getTaskbarButton('window-zundacli'); // Re-query live element
assert(wm.activeWindow === cliWin, 'ZundaCLI is now active window after clicking its taskbar item');
assert(cliTbBtn && cliTbBtn.classList.contains('active'), 'ZundaCLI taskbar button is now active');


// ----------------------------------------------------
// SUITE 4: Keyboard Shortcuts (Ctrl+Esc and Escape)
// ----------------------------------------------------
console.log('\nSUITE 4: Keyboard Shortcuts');

const startMenu = document.getElementById('start-menu');
const startBtn = document.getElementById('start-btn');

// Start menu initial state check
assert(startMenu.classList.contains('hidden'), 'Start menu is initially hidden');

// Test 4.1: Ctrl+Esc toggles Start Menu ON
console.log('\n--- Test 4.1: Ctrl+Esc toggles Start Menu ON ---');
const ctrlEscEvent = new window.KeyboardEvent('keydown', {
  key: 'Escape',
  ctrlKey: true,
  bubbles: true,
  cancelable: true
});
window.dispatchEvent(ctrlEscEvent);

assert(!startMenu.classList.contains('hidden'), 'Start Menu is shown after Ctrl+Esc');
assert(startBtn.classList.contains('start-btn-active'), 'Start Button receives active class after Ctrl+Esc');

// Test 4.2: Ctrl+Esc toggles Start Menu OFF
console.log('\n--- Test 4.2: Ctrl+Esc toggles Start Menu OFF ---');
window.dispatchEvent(ctrlEscEvent);

assert(startMenu.classList.contains('hidden'), 'Start Menu is hidden after second Ctrl+Esc');
assert(!startBtn.classList.contains('start-btn-active'), 'Start Button active class removed after second Ctrl+Esc');

// Test 4.3: Escape key closes open Start Menu
console.log('\n--- Test 4.3: Escape key closes Start Menu ---');
// First open with Ctrl+Esc
window.dispatchEvent(ctrlEscEvent);
assert(!startMenu.classList.contains('hidden'), 'Start Menu re-opened via Ctrl+Esc');

// Dispatch Escape key alone (ctrlKey: false)
const escEvent = new window.KeyboardEvent('keydown', {
  key: 'Escape',
  ctrlKey: false,
  bubbles: true,
  cancelable: true
});
window.dispatchEvent(escEvent);

assert(startMenu.classList.contains('hidden'), 'Start Menu is closed after pressing Escape');
assert(!startBtn.classList.contains('start-btn-active'), 'Start Button active class removed after Escape');

// Test 4.4: Pressing Escape when Start Menu is already closed does nothing
console.log('\n--- Test 4.4: Escape when closed does nothing ---');
window.dispatchEvent(escEvent);
assert(startMenu.classList.contains('hidden'), 'Start Menu remains hidden when Escape is pressed while closed');


// ----------------------------------------------------
// SUMMARY RESULTS
// ----------------------------------------------------
console.log('\n====================================================');
const total = results.length;
const passed = results.filter(r => r.pass).length;
const failed = results.filter(r => !r.pass).length;

console.log(`TOTAL TESTS: ${total}`);
console.log(`PASSED:      ${passed}`);
console.log(`FAILED:      ${failed}`);
console.log('====================================================');

if (failed > 0) {
  console.error('\nVERDICT: FAILED');
  process.exit(1);
} else {
  console.log('\nVERDICT: VERIFIED');
  process.exit(0);
}
