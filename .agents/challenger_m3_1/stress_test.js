/**
 * Custom Empirical Stress Test Suite for ZundaCLI.exe (site/terminal.js)
 * Challenger 1 - Milestone 3
 */

const assert = require('assert');
const path = require('path');

// Mock Minimal DOM Environment
class MockElement {
  constructor(tagName = 'div', id = '', className = '') {
    this.tagName = tagName.toUpperCase();
    this.id = id;
    this.className = className;
    this.children = [];
    this._innerHTML = '';
    this.value = '';
    this.attributes = {};
    this.classList = {
      classes: new Set(className ? className.split(/\s+/) : []),
      add: (c) => this.classList.classes.add(c),
      remove: (c) => this.classList.classes.delete(c),
      contains: (c) => this.classList.classes.has(c),
      toggle: (c) => {
        if (this.classList.classes.has(c)) this.classList.classes.delete(c);
        else this.classList.classes.add(c);
      }
    };
    this.listeners = {};
    this.scrollTop = 0;
    this.scrollHeight = 100;
    this.clientHeight = 50;
    this.dataset = {};
  }

  get innerHTML() {
    let str = this._innerHTML || '';
    if (this.children.length > 0) {
      str += this.children.map(c => (typeof c === 'string' ? c : (c.innerHTML || c.textContent || ''))).join('');
    }
    return str;
  }

  set innerHTML(val) {
    this._innerHTML = val;
    this.children = [];
  }

  appendChild(child) {
    this.children.push(child);
    return child;
  }

  addEventListener(event, fn) {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event].push(fn);
  }

  dispatchEvent(eventObj) {
    const type = eventObj.type || eventObj;
    if (this.listeners[type]) {
      this.listeners[type].forEach(fn => fn(eventObj));
    }
  }

  querySelector(selector) {
    return this.children.find(c => c.className && c.className.includes(selector.replace('.', ''))) || new MockElement();
  }

  querySelectorAll(selector) {
    return this.children.filter(c => c.className && c.className.includes(selector.replace('.', '')));
  }

  closest(selector) {
    return this;
  }

  setAttribute(attr, val) {
    this.attributes[attr] = String(val);
  }

  getAttribute(attr) {
    return this.attributes[attr] || null;
  }

  focus() {
    this.isFocused = true;
  }

  setSelectionRange(start, end) {
    this.selectionStart = start;
    this.selectionEnd = end;
  }
}

// Setup Global Browser Mocks
global.document = {
  getElementById: (id) => new MockElement('div', id),
  querySelector: (sel) => new MockElement('div', '', sel.replace('#', '').replace('.', '')),
  querySelectorAll: (sel) => [],
  createElement: (tag) => new MockElement(tag),
  getSelection: () => ({ toString: () => '' }),
  addEventListener: () => {}
};

global.window = {
  document: global.document,
  getSelection: global.document.getSelection,
  playKeySFX: (key) => { window.audioLog.push(`key:${key}`); },
  playClickSFX: (variant) => { window.audioLog.push(`click:${variant}`); },
  playWindowSFX: (action) => { window.audioLog.push(`win:${action}`); },
  toggleCozyBGM: () => { window.audioLog.push(`bgm:toggle`); return true; },
  ZundaAudio: {
    ctx: null,
    isMuted: false,
    sfxGain: {}
  },
  audioLog: []
};

// Require ZundaTerminal from target path relative to project root
const terminalPath = path.resolve(__dirname, '../../site/terminal.js');
const ZundaTerminal = require(terminalPath);

function createTerminalInstance() {
  const mockOutput = new MockElement('div', 'cli-output', 'cli-terminal-log');
  const mockInput = new MockElement('input', 'cli-input', 'cli-input-field');
  const mockForm = new MockElement('form', 'cli-input-form', 'cli-prompt-line');
  const mockLabel = new MockElement('label', '', 'cli-prompt-label');
  const mockWindow = new MockElement('div', 'window-zundacli', 'window');
  const mockBody = new MockElement('div', '', 'cli-body');
  const mockScrollBtn = new MockElement('button', 'cli-scroll-bottom-btn', 'cli-scroll-bottom-btn hidden');
  const mockToolbar = new MockElement('div', 'cli-mobile-toolbar', 'cli-mobile-toolbar');

  const terminal = new ZundaTerminal({
    windowEl: mockWindow,
    bodyEl: mockBody,
    outputEl: mockOutput,
    formEl: mockForm,
    inputEl: mockInput,
    labelEl: mockLabel,
    scrollBtnEl: mockScrollBtn,
    mobileToolbarEl: mockToolbar
  });

  return { terminal, mockInput, mockOutput, mockForm, mockWindow, mockBody, mockLabel, mockScrollBtn, mockToolbar };
}

async function runStressTests() {
  console.log('======================================================');
  console.log('🔥 STARTING ZUNDATERMINAL ADVERSARIAL STRESS TEST SUITE 🔥');
  console.log('======================================================\n');

  let passedTests = 0;
  let totalTests = 0;

  function runTest(name, fn) {
    totalTests++;
    try {
      fn();
      console.log(`✅ [PASS] ${name}`);
      passedTests++;
    } catch (err) {
      console.error(`❌ [FAIL] ${name}:`, err.message);
      throw err;
    }
  }

  // ------------------------------------------------------------------------
  // TEST GROUP 1: Empty Command Inputs & Whitespace Variations
  // ------------------------------------------------------------------------
  runTest('1. Empty Command Inputs & Whitespaces', () => {
    const { terminal, mockInput, mockOutput } = createTerminalInstance();

    const emptyInputs = ['', ' ', '   ', '\t', '\n', '\r\n', '  \t  \n  '];
    emptyInputs.forEach((input) => {
      mockInput.value = input;
      terminal.submitCommand();
    });

    // Submitting empty lines should not pollute output or history
    assert.strictEqual(terminal.history.length, 0, 'History should remain empty');
    assert.strictEqual(mockOutput.children.length, 0, 'Output log should remain empty');
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 2: Extremely Long Strings (Buffer Stress)
  // ------------------------------------------------------------------------
  runTest('2. Long Strings & Large Payload Handling', () => {
    const { terminal, mockInput, mockOutput } = createTerminalInstance();

    const longStr10k = 'a'.repeat(10000);
    const longStr100k = 'b'.repeat(100000);
    const longArgCmd = 'recipes ' + 'c'.repeat(50000);

    // Submit 10k
    mockInput.value = longStr10k;
    terminal.submitCommand();
    assert.strictEqual(terminal.history[0], longStr10k);

    // Submit 100k
    mockInput.value = longStr100k;
    terminal.submitCommand();
    assert.strictEqual(terminal.history[1], longStr100k);

    // Submit long subcommand
    mockInput.value = longArgCmd;
    terminal.submitCommand();

    assert(mockOutput.children.length >= 3, 'Outputs appended without memory/overflow crashes');
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 3: Special Characters & HTML Injection Prevention
  // ------------------------------------------------------------------------
  runTest('3. Special Characters & HTML Sanitization', () => {
    const { terminal, mockInput, mockOutput } = createTerminalInstance();

    const payloadXSS = '<script>alert("XSS")</script>';
    const payloadTags = '<div style="background:red">TEST</div><img src=x onerror=alert(1)>';
    const payloadQuotes = 'recipes "mochi" \'dango\' `parfait` \\ \\\\ \\n \\t';
    const payloadUnicode = '🫛🍡✨ 𝓩𝓾𝓷𝓭𝓪 日本語 語録 💣 \0 \u0000 \uFFFF';

    [payloadXSS, payloadTags, payloadQuotes, payloadUnicode].forEach(payload => {
      mockInput.value = payload;
      terminal.submitCommand();
    });

    const outputHTML = mockOutput.innerHTML;
    // Ensure raw `<script>` or unescaped HTML tags from input are escaped in echoed output
    assert(!outputHTML.includes('<script>alert("XSS")</script>'), 'XSS script tag should be escaped');
    assert(outputHTML.includes('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;'), 'XSS tag correctly converted to HTML entities');
    assert(!outputHTML.includes('<img src=x onerror=alert(1)>'), 'IMG tag should be escaped');
    assert(outputHTML.includes('&lt;img src=x onerror=alert(1)&gt;'), 'IMG tag correctly escaped');
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 4: Rapid Tab Completions & Edge Cases
  // ------------------------------------------------------------------------
  runTest('4. Rapid Tab Completions & Edge Cases', () => {
    const { terminal, mockInput } = createTerminalInstance();

    // Edge Case A: Tab on empty input
    mockInput.value = '';
    terminal.handleKeyDown({ key: 'Tab', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, '');

    // Edge Case B: Tab on spaces only
    mockInput.value = '   ';
    terminal.handleKeyDown({ key: 'Tab', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, '   ');

    // Edge Case C: Tab on non-existent prefix
    mockInput.value = 'nonexistentprefix123';
    terminal.handleKeyDown({ key: 'Tab', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, 'nonexistentprefix123');

    // Edge Case D: Rapid Tab Loop (100 iterations) across varying inputs
    const testPrefixes = ['g', 'r', 'z', 'm', 'c', 'v', 'w', 'nano', 'edam', 'rec', 'xyz'];
    for (let i = 0; i < 100; i++) {
      const prefix = testPrefixes[i % testPrefixes.length];
      mockInput.value = prefix;
      terminal.handleKeyDown({ key: 'Tab', preventDefault: () => {} });
    }
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 5: Invalid Subcommands
  // ------------------------------------------------------------------------
  runTest('5. Invalid Subcommands & Fallbacks', () => {
    const { terminal, mockInput, mockOutput } = createTerminalInstance();

    const invalidCmds = [
      'recipes non_existent_dish_xyz',
      'recipes 12345!@#$%^&*()',
      'gather non_existent_resource_node',
      'lore non_existent_zone_abc',
      'help non_existent_category_123',
      'theme invalid_theme_name',
      'unknowncommand12345 sub1 sub2 sub3'
    ];

    invalidCmds.forEach(cmd => {
      mockInput.value = cmd;
      terminal.submitCommand();
    });

    assert(mockOutput.innerHTML.includes('recipes'), 'Recipes handled invalid query gracefully');
    assert(mockOutput.innerHTML.includes('Command not recognized'), 'Unknown command produced clean error message');
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 6: Theme Switcher & Rapid Theme Switching Loop
  // ------------------------------------------------------------------------
  runTest('6. Invalid Themes & Rapid Theme Switching (1000 cycles)', () => {
    const { terminal, mockInput, mockWindow } = createTerminalInstance();

    // Invalid theme command
    mockInput.value = 'theme invalid_theme_xyz';
    terminal.submitCommand();
    assert.strictEqual(terminal.currentTheme, 'classic-green', 'Invalid theme falls back to classic-green');

    // Rapid switching loop (1000 iterations)
    const themesToTest = ['amber', 'matrix', 'cozy-pea', 'classic-green', 'cyber', 'hack', 'mochi', 'invalid', 'unknown'];
    for (let i = 0; i < 1000; i++) {
      const target = themesToTest[i % themesToTest.length];
      terminal.cmdTheme([target]);
      assert(terminal.currentTheme, 'Current theme is always defined');
    }
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 7: Command History Boundary Conditions & Underflow/Overflow
  // ------------------------------------------------------------------------
  runTest('7. Command History Boundary Conditions', () => {
    const { terminal, mockInput } = createTerminalInstance();

    // Boundary A: Up/Down on empty history
    terminal.handleKeyDown({ key: 'ArrowUp', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, '');
    terminal.handleKeyDown({ key: 'ArrowDown', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, '');

    // Boundary B: Underflow & Overflow with items
    mockInput.value = 'cmd1';
    terminal.submitCommand();
    mockInput.value = 'cmd2';
    terminal.submitCommand();
    mockInput.value = 'cmd3';
    terminal.submitCommand();

    assert.strictEqual(terminal.historyIndex, 3);

    // ArrowUp 10 times (should cap at 0 without error)
    for (let i = 0; i < 10; i++) {
      terminal.handleKeyDown({ key: 'ArrowUp', preventDefault: () => {} });
    }
    assert.strictEqual(terminal.historyIndex, 0);
    assert.strictEqual(mockInput.value, 'cmd1');

    // ArrowDown 10 times (should cap at 3 and restore draft)
    for (let i = 0; i < 10; i++) {
      terminal.handleKeyDown({ key: 'ArrowDown', preventDefault: () => {} });
    }
    assert.strictEqual(terminal.historyIndex, 3);
    assert.strictEqual(mockInput.value, '');

    // Boundary C: Draft retention while navigating history
    mockInput.value = 'unsubmitted draft text';
    // Navigate up
    terminal.handleKeyDown({ key: 'ArrowUp', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, 'cmd3');
    terminal.handleKeyDown({ key: 'ArrowUp', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, 'cmd2');
    // Navigate down back to bottom
    terminal.handleKeyDown({ key: 'ArrowDown', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, 'cmd3');
    terminal.handleKeyDown({ key: 'ArrowDown', preventDefault: () => {} });
    assert.strictEqual(mockInput.value, 'unsubmitted draft text', 'Draft restored correctly!');

    // Boundary D: High volume history (1000 unique commands)
    for (let i = 0; i < 1000; i++) {
      mockInput.value = `unique_cmd_${i}`;
      terminal.submitCommand();
    }
    assert.strictEqual(terminal.history.length, 1003);
    assert.strictEqual(terminal.historyIndex, 1003);
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 8: Mobile Touch Toolbar & Keydown Fuzzing
  // ------------------------------------------------------------------------
  runTest('8. Mobile Touch Toolbar & Keydown Fuzzing', () => {
    const { terminal, mockInput } = createTerminalInstance();

    // Mobile toolbar virtual keys
    const mockVKeyTab = new MockElement('button');
    mockVKeyTab.dataset = { key: 'Tab' };
    terminal.handleMobileVKey(mockVKeyTab);

    const mockVKeyUp = new MockElement('button');
    mockVKeyUp.dataset = { key: 'ArrowUp' };
    terminal.handleMobileVKey(mockVKeyUp);

    const mockVKeyCmd = new MockElement('button');
    mockVKeyCmd.dataset = { cmd: 'recipes' };
    terminal.handleMobileVKey(mockVKeyCmd);

    // Keydown event fuzzing with various keys
    const keysToFuzz = ['a', 'Enter', 'Tab', 'ArrowUp', 'ArrowDown', 'Shift', 'Control', 'Alt', 'Meta', 'Escape', 'Backspace', 'F12'];
    keysToFuzz.forEach(key => {
      terminal.handleKeyDown({ key, preventDefault: () => {} });
    });
  });

  // ------------------------------------------------------------------------
  // TEST GROUP 9: Random Input Fuzz Generator (500 Iterations)
  // ------------------------------------------------------------------------
  runTest('9. Random Input Fuzzing (500 Iterations)', () => {
    const { terminal, mockInput } = createTerminalInstance();

    const charPool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 <>/\\"\';:!@#$%^&*()_+-=[]{}|`~🫛🍡';

    for (let i = 0; i < 500; i++) {
      const len = Math.floor(Math.random() * 100);
      let randomInput = '';
      for (let j = 0; j < len; j++) {
        randomInput += charPool.charAt(Math.floor(Math.random() * charPool.length));
      }

      mockInput.value = randomInput;
      // Alternate between submit and keydown handlers
      if (i % 3 === 0) {
        terminal.handleKeyDown({ key: 'Tab', preventDefault: () => {} });
      } else if (i % 3 === 1) {
        terminal.handleKeyDown({ key: 'ArrowUp', preventDefault: () => {} });
      } else {
        terminal.submitCommand();
      }
    }
  });

  console.log('\n======================================================');
  console.log(`🎉 ALL ${passedTests}/${totalTests} STRESS TEST SUITES PASSED WITH 0 CRASHES!`);
  console.log('======================================================\n');
}

runStressTests().catch(err => {
  console.error('\n❌ CRITICAL STRESS TEST FAILURE:', err);
  process.exit(1);
});
