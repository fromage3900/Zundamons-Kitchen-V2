/**
 * Comprehensive Empirical Verification Test Harness for Milestone 3 Challenger 2
 * Target: site/index.html, site/style.css, site/terminal.js
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');
const { JSDOM } = require('jsdom');

async function runEmpiricalTests() {
  console.log('=== STARTING EMPIRICAL CHALLENGE SUITE (CHALLENGER 2 - MILESTONE 3) ===\n');

  // Read files
  const htmlPath = path.join(__dirname, '../../site/index.html');
  const cssPath = path.join(__dirname, '../../site/style.css');

  const htmlContent = fs.readFileSync(htmlPath, 'utf8');
  const cssContent = fs.readFileSync(cssPath, 'utf8');

  // -------------------------------------------------------------
  // TEST SECTION 1: CSS & HTML Static Analysis & Rule Verification
  // -------------------------------------------------------------
  console.log('--- TEST SECTION 1: Static Layout & CSS Variable/Rule Verification ---');

  // 1.1 CRT Scanline Overlay & Glow Elements
  assert(htmlContent.includes('id="crt-overlay"'), 'index.html missing #crt-overlay element');
  assert(htmlContent.includes('class="crt-scanlines"'), 'index.html missing .crt-scanlines element');
  assert(htmlContent.includes('class="crt-glow"'), 'index.html missing .crt-glow element');
  assert(htmlContent.includes('class="cli-scanline-overlay"'), 'index.html missing .cli-scanline-overlay inside CLI body');
  console.log('✅ 1.1 CRT Overlay elements verified in HTML structure.');

  // 1.2 CSS Phosphor Theme Variables
  const themeVars = ['classic-green', 'amber', 'matrix', 'cozy-pea'];
  themeVars.forEach(theme => {
    assert(cssContent.includes(`data-term-theme="${theme}"`) || cssContent.includes(`data-theme="${theme}"`), `style.css missing selector for theme: ${theme}`);
  });
  console.log('✅ 1.2 All 4 phosphor themes (classic-green, amber, matrix, cozy-pea) defined in style.css.');

  // 1.3 Micro-Flicker Keyframe Animation
  assert(cssContent.includes('@keyframes crtPhosphorFlicker'), 'style.css missing @keyframes crtPhosphorFlicker');
  assert(cssContent.includes('.cli-flicker'), 'style.css missing .cli-flicker class definition');
  console.log('✅ 1.3 Micro-flicker keyframe animation (@keyframes crtPhosphorFlicker) verified.');

  // 1.4 Mobile Touch Toolbar & VKey CSS
  assert(cssContent.includes('.cli-mobile-toolbar'), 'style.css missing .cli-mobile-toolbar rules');
  assert(cssContent.includes('.cli-vkey'), 'style.css missing .cli-vkey rules');
  assert(cssContent.includes('touch-action: manipulation'), 'style.css missing touch-action: manipulation for touch toolbar');
  console.log('✅ 1.4 Mobile touch toolbar CSS & touch-action rules verified.');

  // 1.5 Scrolllock Resume Pill CSS
  assert(cssContent.includes('.cli-scroll-bottom-btn'), 'style.css missing .cli-scroll-bottom-btn rules');
  console.log('✅ 1.5 Scrolllock resume pill CSS verified.');

  // 1.6 Responsive Viewport Breakpoints
  assert(cssContent.includes('@media screen and (max-width: 1024px)'), 'style.css missing 1024px breakpoint');
  assert(cssContent.includes('@media screen and (max-width: 768px)'), 'style.css missing 768px breakpoint');
  console.log('✅ 1.6 Viewport boundary responsive breakpoints verified.');


  // -------------------------------------------------------------
  // TEST SECTION 2: Dynamic DOM, Theme Switching & VKey Events (JSDOM)
  // -------------------------------------------------------------
  console.log('\n--- TEST SECTION 2: Dynamic JSDOM Terminal Behavioral Tests ---');

  const dom = new JSDOM(htmlContent, {
    url: 'http://localhost/'
  });

  const { window } = dom;
  const { document } = window;

  // Set global.window and global.document so ZundaTerminal detects environment correctly
  global.window = window;
  global.document = document;

  // Polyfill Web Audio API stubs & global window references for JSDOM
  window.ZundaAudio = {
    ctx: null,
    isMuted: false,
    toggleMute: () => true
  };
  window.playKeySFX = () => {};
  window.playClickSFX = () => {};
  window.playWindowSFX = () => {};
  window.toggleCozyBGM = () => true;

  // Require ZundaTerminal now that globals are set
  const ZundaTerminal = require('../../site/terminal.js');
  window.ZundaTerminal = ZundaTerminal;

  // Instantiate ZundaTerminal with bound DOM elements in JSDOM
  const terminal = new ZundaTerminal({
    windowEl: document.getElementById('window-zundacli'),
    bodyEl: document.querySelector('.cli-body'),
    outputEl: document.getElementById('cli-output'),
    formEl: document.getElementById('cli-input-form'),
    inputEl: document.getElementById('cli-input'),
    labelEl: document.querySelector('.cli-prompt-label'),
    scrollBtnEl: document.getElementById('cli-scroll-bottom-btn'),
    mobileToolbarEl: document.getElementById('cli-mobile-toolbar')
  });

  // 2.1 Baseline DOM layout bind check
  assert(terminal.outputEl, 'Terminal outputEl not bound');
  assert(terminal.inputEl, 'Terminal inputEl not bound');
  assert(terminal.formEl, 'Terminal formEl not bound');
  assert(terminal.scrollBtnEl, 'Terminal scrollBtnEl not bound');
  assert(terminal.mobileToolbarEl, 'Terminal mobileToolbarEl not bound');
  console.log('✅ 2.1 JSDOM DOM element binding verified.');

  // 2.2 Phosphor Theme Switching across all 4 themes
  const themesToTest = ['classic-green', 'amber', 'matrix', 'cozy-pea'];
  for (const theme of themesToTest) {
    terminal.setTheme(theme, false);
    assert.strictEqual(terminal.currentTheme, theme, `Terminal theme property failed for ${theme}`);
    const winAttr = terminal.windowEl.getAttribute('data-term-theme');
    assert.strictEqual(winAttr, theme, `data-term-theme attribute mismatch on windowEl for ${theme}`);
  }
  console.log('✅ 2.2 Dynamic theme switching across all 4 themes verified.');

  // 2.3 Mobile Touch Toolbar VKey Events & Input Focus
  console.log('\nTesting Mobile Touch Toolbar (vkey click events)...');
  const toolbar = terminal.mobileToolbarEl;
  const inputEl = terminal.inputEl;

  // Focus tracking flag
  let focusCalled = false;
  inputEl.focus = () => { focusCalled = true; };

  // Helper for clicking element in JSDOM
  function clickEl(el) {
    const evt = new window.MouseEvent('click', { bubbles: true, cancelable: true });
    el.dispatchEvent(evt);
  }

  // Test vkey Tab button
  const tabBtn = toolbar.querySelector('[data-key="Tab"]');
  assert(tabBtn, 'Tab vkey button missing');
  inputEl.value = 'nano';
  focusCalled = false;
  clickEl(tabBtn);
  assert.strictEqual(inputEl.value, 'nanoda ', 'vkey Tab autocomplete failed');
  assert(focusCalled, 'vkey click did not refocus inputEl');
  console.log('  └─ vkey Tab clicked -> Auto-completed "nanoda " & refocused input.');

  // Clear inputEl before history test
  inputEl.value = '';

  // Test vkey ArrowUp button
  const upBtn = toolbar.querySelector('[data-key="ArrowUp"]');
  assert(upBtn, 'ArrowUp vkey button missing');
  terminal.history = ['recipes', 'help'];
  terminal.historyIndex = 2;
  terminal.currentDraft = '';
  focusCalled = false;
  clickEl(upBtn);
  assert.strictEqual(inputEl.value, 'help', 'vkey ArrowUp history failed');
  assert(focusCalled, 'vkey click did not refocus inputEl');
  console.log('  └─ vkey ArrowUp clicked -> Retrieved history "help" & refocused input.');

  // Test vkey ArrowDown button
  const downBtn = toolbar.querySelector('[data-key="ArrowDown"]');
  assert(downBtn, 'ArrowDown vkey button missing');
  focusCalled = false;
  clickEl(downBtn);
  assert.strictEqual(inputEl.value, '', 'vkey ArrowDown history failed');
  assert(focusCalled, 'vkey click did not refocus inputEl');
  console.log('  └─ vkey ArrowDown clicked -> Restored draft "" & refocused input.');

  // Test vkey help command button
  const helpBtn = toolbar.querySelector('[data-cmd="help"]');
  assert(helpBtn, 'help vkey button missing');
  focusCalled = false;
  clickEl(helpBtn);
  assert(terminal.outputEl.innerHTML.includes('COMMAND DIRECTORY'), 'vkey help command execution failed');
  assert(focusCalled, 'vkey click did not refocus inputEl');
  console.log('  └─ vkey HELP clicked -> Executed help command & refocused input.');

  // Test vkey clear command button
  const clearBtn = toolbar.querySelector('[data-cmd="clear"]');
  assert(clearBtn, 'clear vkey button missing');
  focusCalled = false;
  clickEl(clearBtn);
  assert.strictEqual(terminal.outputEl.children.length, 0, 'vkey clear command execution failed');
  assert(focusCalled, 'vkey click did not refocus inputEl');
  console.log('  └─ vkey CLEAR clicked -> Cleared output buffer & refocused input.');

  console.log('✅ 2.3 Mobile touch toolbar vkey click handlers & focus management verified.');


  // -------------------------------------------------------------
  // TEST SECTION 3: Focus Management & Text Selection Bypass
  // -------------------------------------------------------------
  console.log('\n--- TEST SECTION 3: Focus Management & Text Selection Bypass ---');

  const bodyEl = terminal.bodyEl;

  // Case 3.1: Normal body click without selection -> Focuses input
  focusCalled = false;
  window.getSelection = () => ({ toString: () => '' });
  clickEl(bodyEl);
  assert(focusCalled, 'Body click without selection failed to focus input field');
  console.log('✅ 3.1 Body click without text selection correctly redirects focus to inputEl.');

  // Case 3.2: Body click with active text selection -> Does NOT focus input (selection preserved)
  focusCalled = false;
  window.getSelection = () => ({ toString: () => 'Zunda Mochi Recipe' });
  clickEl(bodyEl);
  assert(!focusCalled, 'Body click with active text selection improperly stole focus from user selection');
  console.log('✅ 3.2 Body click with active text selection correctly preserves user selection without stealing focus.');


  // -------------------------------------------------------------
  // TEST SECTION 4: Scrolllock & Resume Pill Functionality
  // -------------------------------------------------------------
  console.log('\n--- TEST SECTION 4: Scrolllock & Resume Pill Functionality ---');

  const outputEl = terminal.outputEl;
  const scrollBtnEl = terminal.scrollBtnEl;

  // Mock scroll metrics
  Object.defineProperty(outputEl, 'scrollHeight', { value: 1000, writable: true });
  Object.defineProperty(outputEl, 'clientHeight', { value: 300, writable: true });
  Object.defineProperty(outputEl, 'scrollTop', { value: 700, writable: true }); // at bottom (1000 - 700 - 300 = 0)

  // 4.1 Normal at-bottom state -> Pill is hidden
  terminal.handleScroll();
  assert.strictEqual(terminal.userScrolledUp, false, 'userScrolledUp false positive when at bottom');
  assert(scrollBtnEl.classList.contains('hidden'), '#cli-scroll-bottom-btn should be hidden when at bottom');
  console.log('✅ 4.1 At-bottom scroll state -> Resume pill is hidden.');

  // 4.2 User scrolls up (scrollTop = 400, distanceToBottom = 300 > threshold 35) -> Pill appears
  outputEl.scrollTop = 400;
  terminal.handleScroll();
  assert.strictEqual(terminal.userScrolledUp, true, 'userScrolledUp should be true when distance > 35px');
  assert(!scrollBtnEl.classList.contains('hidden'), '#cli-scroll-bottom-btn should be visible when scrolled up');
  console.log('✅ 4.2 User scrolled up -> userScrolledUp flag set to true & resume pill (#cli-scroll-bottom-btn) visible.');

  // 4.3 New output arrives while scrolled up -> User scrolllock preserved, output appended without forced jump
  terminal.appendOutput('<p>New Background Output Line</p>');
  assert.strictEqual(terminal.userScrolledUp, true, 'appendOutput should respect userScrolledUp scrolllock');
  console.log('✅ 4.3 Scrolllock defense -> New output appended without interrupting user scroll position.');

  // 4.4 User clicks resume pill button (#cli-scroll-bottom-btn) -> Scrolls to bottom, hides pill, refocused input
  focusCalled = false;
  clickEl(scrollBtnEl);
  assert.strictEqual(terminal.userScrolledUp, false, 'Resume pill click should reset userScrolledUp to false');
  assert(scrollBtnEl.classList.contains('hidden'), 'Resume pill click should hide #cli-scroll-bottom-btn');
  assert.strictEqual(outputEl.scrollTop, 1000, 'Resume pill click should scroll output to bottom (1000)');
  assert(focusCalled, 'Resume pill click should refocus input field');
  console.log('✅ 4.4 Resume pill click -> Smoothly scrolls to bottom, resets scrolllock state, hides pill, and refocused input.');


  console.log('\n======================================================');
  console.log('🎉 ALL EMPIRICAL CHALLENGE TESTS PASSED SUCCESSFULLY!');
  console.log('======================================================');
}

runEmpiricalTests().catch(err => {
  console.error('\n❌ EMPIRICAL TEST FAILED:', err);
  process.exit(1);
});
