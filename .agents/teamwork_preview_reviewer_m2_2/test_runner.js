const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

console.log('=== Zunda-OS 95 WindowManager Verification Suite ===\n');

const htmlPath = path.join(__dirname, '../../site/index.html');
const jsPath = path.join(__dirname, '../../site/window_manager.js');

const html = fs.readFileSync(htmlPath, 'utf8');

const dom = new JSDOM(html, {
  url: 'http://localhost/',
  runScripts: 'dangerously',
  resources: 'usable',
  beforeParse(win) {
    win.requestAnimationFrame = (cb) => setTimeout(cb, 16);
    win.cancelAnimationFrame = (id) => clearTimeout(id);
    win.HTMLCanvasElement.prototype.getContext = () => ({
      clearRect: () => {},
      beginPath: () => {},
      arc: () => {},
      fill: () => {},
      stroke: () => {}
    });
  }
});

const { window } = dom;
const { document } = window;

// Set window global and require WindowManager
global.window = window;
global.document = document;

const WindowManager = require(jsPath);
window.WindowManager = WindowManager;

let passedTests = 0;
let failedTests = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`[PASS] ${message}`);
    passedTests++;
  } else {
    console.error(`[FAIL] ${message}`);
    failedTests++;
  }
}

// -------------------------------------------------------------
// Test 1: Initialization & Registration
// -------------------------------------------------------------
console.log('--- Test Group 1: Initialization & Registration ---');
const wm = new WindowManager();
wm.init();

assert(wm.windows.size >= 4, `Registered ${wm.windows.size} windows (expected >= 4)`);
assert(wm.windows.has('window-zundacli'), 'window-zundacli is registered');
assert(wm.windows.has('window-cookbook'), 'window-cookbook is registered');
assert(wm.windows.has('window-vntalk'), 'window-vntalk is registered');
assert(wm.windows.has('window-quickstart'), 'window-quickstart is registered');

// -------------------------------------------------------------
// Test 2: Z-Index Stack & Active State Styling
// -------------------------------------------------------------
console.log('\n--- Test Group 2: Z-Index Depth Stack & Styling ---');
assert(wm.baseZIndex === 100, 'baseZIndex is 100');
assert(wm.maxZIndex === 8999, 'maxZIndex is 8999');

const winCLI = wm.getWindow('window-zundacli');
const winCookbook = wm.getWindow('window-cookbook');
const winVN = wm.getWindow('window-vntalk');

wm.bringToFront(winCLI);
const z1 = parseInt(winCLI.style.zIndex, 10);
assert(z1 > 100, `winCLI zIndex is ${z1} (> 100)`);
assert(winCLI.classList.contains('window-active'), 'winCLI has .window-active class');
assert(!winCLI.classList.contains('window-inactive'), 'winCLI does not have .window-inactive class');
assert(wm.activeWindow === winCLI, 'wm.activeWindow is winCLI');

wm.bringToFront(winCookbook);
const z2 = parseInt(winCookbook.style.zIndex, 10);
assert(z2 > z1, `winCookbook zIndex (${z2}) > winCLI zIndex (${z1})`);
assert(winCookbook.classList.contains('window-active'), 'winCookbook has .window-active class');
assert(winCLI.classList.contains('window-inactive'), 'winCLI now has .window-inactive class');
assert(wm.activeWindow === winCookbook, 'wm.activeWindow is winCookbook');

// Test Max Z-Index Cap
wm.currentZIndex = 8998;
wm.bringToFront(winVN);
assert(parseInt(winVN.style.zIndex, 10) === 8999, 'zIndex incremented to 8999 max cap');
wm.bringToFront(winCLI);
assert(parseInt(winCLI.style.zIndex, 10) === 8999, 'zIndex clamped at maxZIndex 8999');

// Reset currentZIndex for remaining tests
wm.currentZIndex = 100;

// -------------------------------------------------------------
// Test 3: Active Focus Fallback (transferFocusToTopVisibleWindow)
// -------------------------------------------------------------
console.log('\n--- Test Group 3: Active Focus Fallback ---');
// Set up explicit z-indices & visibility
wm.openWindow('window-zundacli');
winCLI.style.zIndex = '110';
wm.openWindow('window-cookbook');
winCookbook.style.zIndex = '120';
wm.openWindow('window-vntalk');
winVN.style.zIndex = '130';

wm.transferFocusToTopVisibleWindow();
assert(wm.activeWindow === winVN, 'Top visible window initially is winVN (z=130)');

// Close top window (winVN)
wm.closeWindow('window-vntalk');
assert(winVN.classList.contains('hidden'), 'winVN is hidden');
assert(wm.activeWindow === winCookbook, 'Focus fell back to winCookbook (z=120)');

// Minimize active window (winCookbook)
wm.minimizeWindow('window-cookbook');
assert(winCookbook.classList.contains('hidden'), 'winCookbook is hidden');
assert(wm.activeWindow === winCLI, 'Focus fell back to winCLI (z=110)');

// Minimize remaining window (winCLI)
wm.minimizeWindow('window-zundacli');
assert(winCLI.classList.contains('hidden'), 'winCLI is hidden');
assert(wm.activeWindow === null, 'wm.activeWindow is null when all windows hidden');

// -------------------------------------------------------------
// Test 4: Taskbar Sync & Click Matrix
// -------------------------------------------------------------
console.log('\n--- Test Group 4: Taskbar Sync & Click Matrix ---');
// Restore winCLI and winCookbook
wm.restoreWindow('window-zundacli');
wm.restoreWindow('window-cookbook'); // winCookbook active now (z=102), winCLI is visible but inactive (z=101)

const taskbarContainer = document.getElementById('taskbar-windows');
assert(taskbarContainer !== null, '#taskbar-windows element found');

const buttons = taskbarContainer.querySelectorAll('.taskbar-item');
assert(buttons.length >= 4, `Taskbar has ${buttons.length} buttons (retains all windows including minimized)`);

// 1. Minimized window taskbar button
const btnVN = taskbarContainer.querySelector('[data-window-target="window-vntalk"]');
assert(btnVN !== null, 'Taskbar button for minimized window-vntalk exists');
assert(btnVN.classList.contains('minimized'), 'Taskbar button for window-vntalk has .minimized class');

// Click minimized window button -> restores & focuses
btnVN.click(); // winVN becomes active
assert(!winVN.classList.contains('hidden'), 'Clicking minimized taskbar button restored winVN');
assert(wm.activeWindow === winVN, 'winVN became active window after restore');

// 2. Active window taskbar button
const btnActiveVN = document.querySelector('#taskbar-windows [data-window-target="window-vntalk"]');
assert(btnActiveVN.classList.contains('active'), 'winVN taskbar button is active');
btnActiveVN.click(); // winVN minimizes, focus falls back to winCookbook (z=102)
assert(winVN.classList.contains('hidden'), 'Clicking active window taskbar button minimized winVN');
assert(wm.activeWindow === winCookbook, 'winCookbook gained focus after winVN minimized');

// 3. Inactive visible window taskbar button (winCLI is visible, but winCookbook is active)
const btnInactiveCLI = document.querySelector('#taskbar-windows [data-window-target="window-zundacli"]');
assert(!btnInactiveCLI.classList.contains('active'), 'winCLI taskbar button is inactive');
btnInactiveCLI.click(); // restores & focuses winCLI
assert(wm.activeWindow === winCLI, 'Clicking inactive taskbar button focused winCLI');
assert(winCLI.classList.contains('window-active'), 'winCLI has .window-active class');

// -------------------------------------------------------------
// Test 5: Keyboard Shortcuts (Ctrl+Esc & Escape)
// -------------------------------------------------------------
console.log('\n--- Test Group 5: Keyboard Shortcuts ---');
const startMenu = document.getElementById('start-menu');
const startBtn = document.getElementById('start-btn');

assert(startMenu !== null, '#start-menu element found');
assert(startBtn !== null, '#start-btn element found');

assert(startMenu.classList.contains('hidden'), 'Start menu initially hidden');

// Test Ctrl+Esc (Open)
const ctrlEscEvt = new window.KeyboardEvent('keydown', { key: 'Escape', ctrlKey: true, bubbles: true, cancelable: true });
window.dispatchEvent(ctrlEscEvt);
assert(!startMenu.classList.contains('hidden'), 'Ctrl+Esc opened Start Menu');
assert(startBtn.classList.contains('start-btn-active'), 'Start button has start-btn-active class');

// Test Escape alone (Close)
const escEvt = new window.KeyboardEvent('keydown', { key: 'Escape', ctrlKey: false, bubbles: true, cancelable: true });
window.dispatchEvent(escEvt);
assert(startMenu.classList.contains('hidden'), 'Escape alone closed Start Menu');
assert(!startBtn.classList.contains('start-btn-active'), 'Start button removed start-btn-active class');

// Test Escape alone when already closed (Does not open)
window.dispatchEvent(escEvt);
assert(startMenu.classList.contains('hidden'), 'Escape alone while closed keeps Start Menu closed');

// Test Ctrl+Esc (Toggle Close)
window.dispatchEvent(ctrlEscEvt); // open
assert(!startMenu.classList.contains('hidden'), 'Ctrl+Esc opened Start Menu again');
window.dispatchEvent(ctrlEscEvt); // close
assert(startMenu.classList.contains('hidden'), 'Ctrl+Esc toggled Start Menu closed');

// -------------------------------------------------------------
// Test 6: Roblox exportScreenGuiLayout Metadata Format
// -------------------------------------------------------------
console.log('\n--- Test Group 6: exportScreenGuiLayout Export ---');
const exportData = WindowManager.exportScreenGuiLayout();

assert(exportData && exportData.ScreenGui, 'exportScreenGuiLayout returns ScreenGui object');
assert(exportData.ScreenGui.Name === 'ZundaOS95ScreenGui', 'ScreenGui Name is ZundaOS95ScreenGui');
assert(exportData.ScreenGui.ResetOnSpawn === false, 'ResetOnSpawn is false');
assert(exportData.ScreenGui.ZIndexBehavior === 'Sibling', 'ZIndexBehavior is Sibling');
assert(Array.isArray(exportData.ScreenGui.Children), 'Children is an array');

const cliFrame = exportData.ScreenGui.Children.find(c => c.Name === 'Win_zundacli');
assert(cliFrame !== undefined, 'Win_zundacli frame exists in Roblox export hierarchy');
assert(cliFrame.ClassName === 'Frame', 'cliFrame ClassName is Frame');
assert(cliFrame.Title.includes('ZundaCLI'), 'cliFrame Title is populated correctly');
assert(typeof cliFrame.Position.X.Offset === 'number', 'Position X Offset is a number');
assert(typeof cliFrame.Size.X.Offset === 'number', 'Size X Offset is a number');
assert(cliFrame.Children.length === 2, 'Frame contains Header and Body child frames');

console.log(`\n=== Verification Results: ${passedTests} PASSED, ${failedTests} FAILED ===`);
process.exit(failedTests > 0 ? 1 : 0);
