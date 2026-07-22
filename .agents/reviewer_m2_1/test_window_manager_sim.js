/**
 * Independent Automated Test Suite for WindowManager (site/window_manager.js)
 * Using JSDOM to test DOM interactions, drag/touch clamping, taskbar sync, shortcuts, and exportScreenGuiLayout.
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

async function runTestSuite() {
  console.log('=== STARTING WINDOW MANAGER ENGINE INDEPENDENT VERIFICATION ===\n');

  const htmlPath = path.join(__dirname, '../../site/index.html');
  const jsPath = path.join(__dirname, '../../site/window_manager.js');

  const htmlContent = fs.readFileSync(htmlPath, 'utf8');

  // Setup JSDOM
  const dom = new JSDOM(htmlContent, {
    url: 'http://localhost/',
    runScripts: 'dangerously',
    resources: 'usable'
  });

  const { window } = dom;
  const { document } = window;

  // Attach JSDOM window and document to global Node environment
  global.window = window;
  global.document = document;

  // Polyfill viewport dimensions
  Object.defineProperty(window, 'innerWidth', { value: 1024, writable: true });
  Object.defineProperty(window, 'innerHeight', { value: 768, writable: true });
  Object.defineProperty(document.documentElement, 'clientWidth', { value: 1024, writable: true });
  Object.defineProperty(document.documentElement, 'clientHeight', { value: 768, writable: true });

  // Load WindowManager into Node/JSDOM context
  delete require.cache[require.resolve(jsPath)];
  const WindowManager = require(jsPath);
  window.WindowManager = WindowManager;

  const wm = new WindowManager();
  wm.init();

  // --------------------------------------------------------------------------
  // TEST 1: 7 Window Registration
  // --------------------------------------------------------------------------
  console.log('[TEST 1] Verifying 7 Window Registration...');
  const expectedIds = [
    'window-zundacli',
    'window-cookbook',
    'window-vntalk',
    'window-zundamon',
    'window-promos',
    'window-calculator',
    'window-updates'
  ];

  expectedIds.forEach(id => {
    const winEl = wm.getWindow(id);
    assert(winEl !== null, `Window element #${id} should be found in DOM.`);
    assert(wm.windows.has(id), `Window ID ${id} should be registered in wm.windows map.`);
    console.log(`  ✓ Window "${id}" registered properly.`);
  });
  assert.strictEqual(wm.windows.size, 7, 'wm.windows map should contain exactly 7 registered windows.');
  console.log('✅ TEST 1 PASSED: All 7 windows correctly registered.\n');

  // --------------------------------------------------------------------------
  // TEST 2: Z-Index Stack & Focus Fallback
  // --------------------------------------------------------------------------
  console.log('[TEST 2] Verifying Z-Index Stack & Focus Fallback...');
  wm.openWindow('window-zundacli');
  const z1 = parseInt(wm.getWindow('window-zundacli').style.zIndex, 10);
  assert(z1 > 100, `zundacli zIndex should be > 100 (got ${z1}).`);
  assert.strictEqual(wm.activeWindow, wm.getWindow('window-zundacli'), 'zundacli should be active window.');

  wm.openWindow('window-cookbook');
  const z2 = parseInt(wm.getWindow('window-cookbook').style.zIndex, 10);
  assert(z2 > z1, `cookbook zIndex (${z2}) should be higher than zundacli zIndex (${z1}).`);
  assert.strictEqual(wm.activeWindow, wm.getWindow('window-cookbook'), 'cookbook should now be active window.');

  wm.openWindow('window-vntalk');
  const z3 = parseInt(wm.getWindow('window-vntalk').style.zIndex, 10);
  assert(z3 > z2, `vntalk zIndex (${z3}) should be higher than cookbook zIndex (${z2}).`);

  // Close top window (vntalk) -> focus fallback should set cookbook as top active window
  wm.closeWindow('window-vntalk');
  assert(wm.getWindow('window-vntalk').classList.contains('hidden'), 'vntalk should be hidden after closing.');
  assert.strictEqual(wm.activeWindow, wm.getWindow('window-cookbook'), 'Focus should fall back to top visible window (cookbook).');

  // Minimize cookbook -> focus fallback should set zundacli as active window
  wm.minimizeWindow('window-cookbook');
  assert(wm.getWindow('window-cookbook').classList.contains('hidden'), 'cookbook should be hidden after minimizing.');
  assert.strictEqual(wm.activeWindow, wm.getWindow('window-zundacli'), 'Focus should fall back to remaining top visible window (zundacli).');

  // Close zundacli -> no visible windows remaining -> activeWindow should be null
  wm.closeWindow('window-zundacli');
  assert.strictEqual(wm.activeWindow, null, 'activeWindow should be null when all windows are closed/minimized.');
  console.log('✅ TEST 2 PASSED: Z-index stacking and focus fallback work correctly.\n');

  // --------------------------------------------------------------------------
  // TEST 3: Drag & Touch Viewport Clamping
  // --------------------------------------------------------------------------
  console.log('[TEST 3] Verifying Drag & Touch Viewport Clamping...');
  wm.openWindow('window-zundacli');
  const winZunda = wm.getWindow('window-zundacli');
  const header = winZunda.querySelector('.window-header');

  // Mock offset dimensions
  Object.defineProperty(winZunda, 'offsetWidth', { value: 680, writable: true });
  Object.defineProperty(winZunda, 'offsetHeight', { value: 440, writable: true });
  Object.defineProperty(winZunda, 'offsetLeft', { value: 80, writable: true });
  Object.defineProperty(winZunda, 'offsetTop', { value: 60, writable: true });

  // Simulate Mouse Down on Header
  const mousedownEvt = new window.MouseEvent('mousedown', { clientX: 100, clientY: 70, bubbles: true });
  header.dispatchEvent(mousedownEvt);

  // Drag far out of bounds (negative coordinates: -400, -400)
  const mousemoveNeg = new window.MouseEvent('mousemove', { clientX: -400, clientY: -400, bubbles: true });
  document.dispatchEvent(mousemoveNeg);

  assert.strictEqual(winZunda.style.left, '0px', `Left should be clamped to 0px (got ${winZunda.style.left})`);
  assert.strictEqual(winZunda.style.top, '0px', `Top should be clamped to 0px (got ${winZunda.style.top})`);
  console.log('  ✓ Clamping at minimum bounds (0, 0) passed.');

  // Drag far beyond viewport (e.g. clientX: 2000, clientY: 2000)
  // Max left = 1024 - 680 = 344px
  // Max top = 768 - 440 = 328px
  const mousemoveMax = new window.MouseEvent('mousemove', { clientX: 2000, clientY: 2000, bubbles: true });
  document.dispatchEvent(mousemoveMax);

  assert.strictEqual(winZunda.style.left, '344px', `Left should be clamped to max 344px (got ${winZunda.style.left})`);
  assert.strictEqual(winZunda.style.top, '328px', `Top should be clamped to max 328px (got ${winZunda.style.top})`);
  console.log('  ✓ Clamping at maximum bounds (344, 328) passed.');

  // Mouse Up to stop drag
  const mouseupEvt = new window.MouseEvent('mouseup', { bubbles: true });
  document.dispatchEvent(mouseupEvt);
  console.log('✅ TEST 3 PASSED: Viewport boundary clamping engine verified.\n');

  // --------------------------------------------------------------------------
  // TEST 4: Maximize/Restore & Geometry Memory
  // --------------------------------------------------------------------------
  console.log('[TEST 4] Verifying Maximize/Restore & Geometry Memory...');
  winZunda.style.left = '80px';
  winZunda.style.top = '60px';
  winZunda.style.width = '680px';
  winZunda.style.height = '440px';
  winZunda.classList.remove('maximized', 'window-maximized');

  // Maximize window
  wm.maximizeWindow(winZunda);
  assert(winZunda.classList.contains('maximized'), 'Window should have maximized class.');
  assert.strictEqual(winZunda.style.left, '0px');
  assert.strictEqual(winZunda.style.top, '0px');
  assert.strictEqual(winZunda.style.width, '100%');
  assert.strictEqual(winZunda.style.height, 'calc(100vh - 36px)');

  assert.strictEqual(winZunda.dataset.prevLeft, '80px', 'Geometry memory prevLeft should be saved.');
  assert.strictEqual(winZunda.dataset.prevTop, '60px', 'Geometry memory prevTop should be saved.');
  assert.strictEqual(winZunda.dataset.prevWidth, '680px', 'Geometry memory prevWidth should be saved.');
  assert.strictEqual(winZunda.dataset.prevHeight, '440px', 'Geometry memory prevHeight should be saved.');

  // Un-maximize window
  wm.maximizeWindow(winZunda);
  assert(!winZunda.classList.contains('maximized'), 'Window should no longer have maximized class.');
  assert.strictEqual(winZunda.style.left, '80px', 'Restored left should match geometry memory.');
  assert.strictEqual(winZunda.style.top, '60px', 'Restored top should match geometry memory.');
  assert.strictEqual(winZunda.style.width, '680px', 'Restored width should match geometry memory.');
  assert.strictEqual(winZunda.style.height, '440px', 'Restored height should match geometry memory.');
  console.log('✅ TEST 4 PASSED: Maximize/Restore geometry memory verified.\n');

  // --------------------------------------------------------------------------
  // TEST 5: Taskbar Sync & Start Popover
  // --------------------------------------------------------------------------
  console.log('[TEST 5] Verifying Taskbar Sync & Start Menu Popover...');
  wm.openWindow('window-zundacli');
  wm.updateTaskbar();
  const taskbarWinContainer = document.getElementById('taskbar-windows');
  assert.strictEqual(taskbarWinContainer.children.length, 7, 'Taskbar should render 7 window buttons.');

  let zundaTbBtn = taskbarWinContainer.querySelector('[data-window-target="window-zundacli"]');
  assert(zundaTbBtn !== null, 'Taskbar button for window-zundacli should exist.');
  assert(zundaTbBtn.classList.contains('active'), 'Taskbar button for active window-zundacli should have "active" class.');

  // Click active taskbar button -> should minimize window
  zundaTbBtn.click();
  assert(winZunda.classList.contains('hidden'), 'Clicking active taskbar button should minimize window.');

  // Re-query taskbar button as DOM was re-rendered by updateTaskbar()
  zundaTbBtn = taskbarWinContainer.querySelector('[data-window-target="window-zundacli"]');
  assert(zundaTbBtn.classList.contains('minimized'), 'Taskbar button for minimized window should have "minimized" class.');

  // Click minimized taskbar button -> should restore window
  zundaTbBtn.click();
  assert(!winZunda.classList.contains('hidden'), 'Clicking minimized taskbar button should restore window.');

  // Start menu popover test
  const startBtn = document.getElementById('start-btn');
  const startMenu = document.getElementById('start-menu');
  assert(startMenu.classList.contains('hidden'), 'Start menu should be hidden initially.');

  startBtn.click();
  assert(!startMenu.classList.contains('hidden'), 'Clicking start button should show start menu.');
  assert(startBtn.classList.contains('start-btn-active'), 'Start button should have start-btn-active class when menu open.');

  startBtn.click();
  assert(startMenu.classList.contains('hidden'), 'Clicking start button again should hide start menu.');
  console.log('✅ TEST 5 PASSED: Taskbar sync & start popover verified.\n');

  // --------------------------------------------------------------------------
  // TEST 6: Keyboard Shortcuts (Ctrl+Esc and Escape)
  // --------------------------------------------------------------------------
  console.log('[TEST 6] Verifying Keyboard Shortcuts...');
  // Ctrl+Esc -> toggle Start Menu open
  const ctrlEscEvt = new window.KeyboardEvent('keydown', { key: 'Escape', ctrlKey: true, bubbles: true });
  window.dispatchEvent(ctrlEscEvt);
  assert(!startMenu.classList.contains('hidden'), 'Ctrl+Esc should open start menu.');

  // Escape alone -> close Start Menu
  const escEvt = new window.KeyboardEvent('keydown', { key: 'Escape', ctrlKey: false, bubbles: true });
  window.dispatchEvent(escEvt);
  assert(startMenu.classList.contains('hidden'), 'Escape should close start menu.');
  console.log('✅ TEST 6 PASSED: Keyboard shortcuts verified.\n');

  // --------------------------------------------------------------------------
  // TEST 7: exportScreenGuiLayout()
  // --------------------------------------------------------------------------
  console.log('[TEST 7] Verifying exportScreenGuiLayout()...');
  const layout = wm.exportScreenGuiLayout();
  assert(layout && layout.ScreenGui, 'Export layout should return ScreenGui root object.');
  assert.strictEqual(layout.ScreenGui.Name, 'ZundaOS95ScreenGui');
  assert.strictEqual(layout.ScreenGui.ResetOnSpawn, false);
  assert.strictEqual(layout.ScreenGui.Children.length, 7, 'ScreenGui layout should contain 7 window frames.');

  const cliFrame = layout.ScreenGui.Children.find(c => c.Name === 'Win_zundacli');
  assert(cliFrame !== null, 'Win_zundacli frame should be present in exported hierarchy.');
  assert.strictEqual(cliFrame.ClassName, 'Frame');
  assert.strictEqual(cliFrame.Title, 'ZundaCLI.exe — Pastel Dev Console');
  assert.strictEqual(cliFrame.Children.length, 2, 'Window frame should contain Header and Body children.');
  assert.strictEqual(cliFrame.Children[0].Name, 'Header');
  assert.strictEqual(cliFrame.Children[1].Name, 'Body');
  console.log('✅ TEST 7 PASSED: exportScreenGuiLayout() structure verified.\n');

  console.log('===============================================================');
  console.log('🎉 ALL 7 INDEPENDENT VERIFICATION TESTS PASSED SUCCESSFULLY! 🎉');
  console.log('===============================================================');
}

runTestSuite().catch(err => {
  console.error('❌ VERIFICATION TEST FAILED:', err);
  process.exit(1);
});
