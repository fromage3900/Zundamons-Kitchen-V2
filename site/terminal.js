/**
 * ZundaCLI Terminal Engine (site/terminal.js)
 * Zundamon's Kitchen V2 — Zunda-OS 95 Interactive CRT Phosphor Web Terminal
 * 
 * Features:
 * - Command parser & history buffer (Up/Down arrow key traversal).
 * - Tab auto-complete with Longest Common Prefix (LCP) & match listing.
 * - Auto-scroll with smart manual scrolllock detection & resume pill (#cli-scroll-bottom-btn).
 * - Theme switcher (classic-green, amber, matrix, cozy-pea).
 * - 12 Primary CLI Commands: help, info/about, recipes, gather, lore, play, music, clear, version, theme, rojo, wally.
 * - 7 Secret Zundamon Easter Eggs: nanoda, mochi, edamame, zunda, secret, dance, matrix.
 * - Synthesized audio feedback via Web Audio API (ZundaAudio, playKeySFX, playClickSFX, playWindowSFX, toggleCozyBGM).
 * - Mobile touch helper toolbar integration (#cli-mobile-toolbar).
 */

class ZundaTerminal {
  /**
   * @param {Object} options Configuration & element overrides
   */
  constructor(options = {}) {
    // DOM Element References (with graceful fallback for Node environments or custom DOMs)
    this.options = options;
    
    this.prompt = options.prompt || 'zunda>';
    this.history = [];
    this.historyIndex = 0;
    this.currentDraft = '';
    this.currentTheme = options.theme || 'classic-green';
    this.edamameCount = 0;
    this.userScrolledUp = false;
    this.scrollThreshold = 35; // px from bottom
    this.isSecretMode = false;

    // Primary command suite & keywords for autocomplete
    this.commands = [
      'help', 'info', 'about', 'recipes', 'cook',
      'gather', 'harvest', 'mine', 'lore', 'zone', 'story',
      'play', 'roblox', 'launch', 'music', 'bgm',
      'clear', 'cls', 'version', 'ver', 'theme', 'color',
      'rojo', 'wally', 'deps',
      // Easter egg triggers
      'nanoda', 'mochi', 'edamame', 'zunda', 'secret', 'dance', 'matrix'
    ];

    // Node / Browser environment check
    if (typeof window !== 'undefined' && typeof document !== 'undefined') {
      this.bindDOM();
      this.init();
    }
  }

  /**
   * Resolve DOM element references from options or document IDs
   */
  bindDOM() {
    const opts = this.options;
    this.windowEl = opts.windowEl || document.getElementById('window-zundacli');
    this.bodyEl = opts.bodyEl || (this.windowEl ? this.windowEl.querySelector('.cli-body') : document.querySelector('.cli-body'));
    this.outputEl = opts.outputEl || document.getElementById('cli-output');
    this.formEl = opts.formEl || document.getElementById('cli-input-form');
    this.inputEl = opts.inputEl || document.getElementById('cli-input');
    this.labelEl = opts.labelEl || (this.formEl ? this.formEl.querySelector('.cli-prompt-label') : document.querySelector('.cli-prompt-label'));
    this.scrollBtnEl = opts.scrollBtnEl || document.getElementById('cli-scroll-bottom-btn');
    this.mobileToolbarEl = opts.mobileToolbarEl || document.getElementById('cli-mobile-toolbar');
  }

  /**
   * Initialize event listeners and baseline terminal state
   */
  init() {
    if (!this.inputEl || !this.outputEl) return;

    // Set initial prompt label
    if (this.labelEl) {
      this.labelEl.textContent = this.prompt;
    }

    // Input Keydown events
    this.inputEl.addEventListener('keydown', (e) => this.handleKeyDown(e));

    // Form submit guard
    if (this.formEl) {
      this.formEl.addEventListener('submit', (e) => {
        e.preventDefault();
        this.submitCommand();
      });
    }

    // Scrolllock listener
    this.outputEl.addEventListener('scroll', () => this.handleScroll());

    // Resume scroll pill button
    if (this.scrollBtnEl) {
      this.scrollBtnEl.addEventListener('click', () => {
        this.scrollToBottom(true);
        if (this.inputEl) this.inputEl.focus();
      });
    }

    // Body click focus retention
    if (this.bodyEl) {
      this.bodyEl.addEventListener('click', (e) => {
        const selection = window.getSelection ? window.getSelection() : null;
        if (selection && selection.toString().length > 0) return;
        if (e.target.tagName === 'A' || e.target.tagName === 'BUTTON' || e.target.tagName === 'INPUT') return;
        this.inputEl.focus();
      });
    }

    // Mobile touch toolbar bindings
    if (this.mobileToolbarEl) {
      this.mobileToolbarEl.addEventListener('click', (e) => {
        const btn = e.target.closest('.cli-vkey');
        if (!btn) return;
        this.handleMobileVKey(btn);
      });
    }

    // Audio Interface Guard: ensure ZundaAudio.playClick points to window.playClickSFX if unassigned
    if (typeof window !== 'undefined' && window.ZundaAudio && !window.ZundaAudio.playClick) {
      window.ZundaAudio.playClick = window.playClickSFX;
    }

    // Apply baseline theme attribute
    this.setTheme(this.currentTheme, false);
  }

  /**
   * Keyboard event handler for terminal input field
   * @param {KeyboardEvent} e 
   */
  handleKeyDown(e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      this.submitCommand();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      this.handleHistoryUp();
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      this.handleHistoryDown();
    } else if (e.key === 'Tab') {
      e.preventDefault();
      this.handleTabCompletion();
    } else if (e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
      this.playKeySound(e.key);
    }
  }

  /**
   * Up Arrow: Navigate backwards in command history
   */
  handleHistoryUp() {
    if (this.history.length === 0) return;

    // Save unsaved draft when beginning upward navigation
    if (this.historyIndex === this.history.length) {
      this.currentDraft = this.inputEl.value;
    }

    if (this.historyIndex > 0) {
      this.historyIndex--;
      this.inputEl.value = this.history[this.historyIndex];
      this.moveCursorToEnd();
      this.playKeySound('ArrowUp');
    }
  }

  /**
   * Down Arrow: Navigate forwards in command history
   */
  handleHistoryDown() {
    if (this.historyIndex < this.history.length) {
      this.historyIndex++;
      if (this.historyIndex === this.history.length) {
        this.inputEl.value = this.currentDraft;
      } else {
        this.inputEl.value = this.history[this.historyIndex];
      }
      this.moveCursorToEnd();
      this.playKeySound('ArrowDown');
    }
  }

  /**
   * Move input caret to the end of text
   */
  moveCursorToEnd() {
    if (!this.inputEl) return;
    const len = this.inputEl.value.length;
    if (typeof this.inputEl.setSelectionRange === 'function') {
      this.inputEl.setSelectionRange(len, len);
    }
  }

  /**
   * Tab key handler: Auto-completes keywords using exact match or LCP math
   */
  handleTabCompletion() {
    const rawInput = this.inputEl.value;
    const trimmed = rawInput.trimStart().toLowerCase();

    if (!trimmed) return;

    // Unique list of candidate commands
    const candidates = Array.from(new Set(this.commands));
    const matches = candidates.filter(cmd => cmd.startsWith(trimmed));

    if (matches.length === 1) {
      // 1. Single exact prefix match -> complete string with trailing space
      this.inputEl.value = matches[0] + ' ';
      this.playKeySound('Tab');
    } else if (matches.length > 1) {
      // 2. Multiple matches -> calculate Longest Common Prefix (LCP)
      const lcp = this.getLongestCommonPrefix(matches);
      if (lcp.length > trimmed.length) {
        this.inputEl.value = lcp;
      }

      // Display match candidates in terminal output
      const matchLine = document.createElement('p');
      matchLine.className = 'cli-line cli-tab-matches';
      matchLine.innerHTML = `<span class="cli-prompt-label">${this.escapeHTML(this.prompt)}</span> ${this.escapeHTML(rawInput)}<br>` +
                            `<span class="cli-highlight">Matches:</span> ${matches.map(m => `<span class="cli-system">${this.escapeHTML(m)}</span>`).join('  ')}`;
      this.outputEl.appendChild(matchLine);
      this.scrollToBottom(true);
      this.playKeySound('Tab');
    } else {
      // 3. No match found
      this.playKeySound('Error');
    }
  }

  /**
   * Calculate Longest Common Prefix across candidate strings
   * @param {string[]} strings 
   * @returns {string} LCP prefix
   */
  getLongestCommonPrefix(strings) {
    if (!strings || strings.length === 0) return '';
    let prefix = strings[0];
    for (let i = 1; i < strings.length; i++) {
      while (strings[i].indexOf(prefix) !== 0) {
        prefix = prefix.substring(0, prefix.length - 1);
        if (!prefix) return '';
      }
    }
    return prefix;
  }

  /**
   * Command Submission Logic
   * @param {string} [overrideText] Optional command text override
   */
  submitCommand(overrideText) {
    const rawInput = overrideText !== undefined ? overrideText : (this.inputEl ? this.inputEl.value : '');
    const trimmed = rawInput.trim();

    this.playKeySound('Enter');

    if (!trimmed) {
      if (this.inputEl) this.inputEl.value = '';
      return;
    }

    // Echo input to output log
    const echoLine = document.createElement('p');
    echoLine.className = 'cli-line cli-user-echo';
    echoLine.innerHTML = `<span class="cli-prompt-label">${this.escapeHTML(this.prompt)}</span> ${this.escapeHTML(rawInput)}`;
    this.outputEl.appendChild(echoLine);

    // Push to history buffer (avoid duplicate immediate consecutive entries)
    if (this.history.length === 0 || this.history[this.history.length - 1] !== trimmed) {
      this.history.push(trimmed);
    }
    this.historyIndex = this.history.length;
    this.currentDraft = '';

    if (this.inputEl) this.inputEl.value = '';

    // Execute parsed command
    this.executeCommand(trimmed);

    // Auto-scroll to bottom
    this.scrollToBottom();
  }

  /**
   * Parse command name and arguments, then route to handler
   * @param {string} commandStr 
   */
  executeCommand(commandStr) {
    const parts = commandStr.split(/\s+/);
    const cmd = parts[0].toLowerCase();
    const args = parts.slice(1);

    switch (cmd) {
      case 'help':
      case '?':
      case 'commands':
        this.cmdHelp(args);
        break;
      case 'info':
      case 'about':
      case 'sysinfo':
      case 'specs':
        this.cmdInfo(args);
        break;
      case 'recipes':
      case 'recipe':
      case 'cook':
        this.cmdRecipes(args);
        break;
      case 'gather':
      case 'harvest':
      case 'mine':
        this.cmdGather(args);
        break;
      case 'lore':
      case 'zone':
      case 'story':
        this.cmdLore(args);
        break;
      case 'play':
      case 'roblox':
      case 'launch':
      case 'start':
        this.cmdPlay(args);
        break;
      case 'music':
      case 'bgm':
      case 'audio':
      case 'soundtrack':
        this.cmdMusic(args);
        break;
      case 'clear':
      case 'cls':
        this.cmdClear();
        break;
      case 'version':
      case 'ver':
      case 'v':
        this.cmdVersion();
        break;
      case 'theme':
      case 'color':
      case 'palette':
        this.cmdTheme(args);
        break;
      case 'rojo':
      case 'rojostatus':
      case 'sync':
        this.cmdRojo();
        break;
      case 'wally':
      case 'packages':
      case 'deps':
        this.cmdWally();
        break;

      // Secret Zundamon Easter Eggs
      case 'nanoda':
      case 'nanoda!':
      case 'nano':
        this.eggNanoda();
        break;
      case 'mochi':
      case 'zundamochi':
        this.eggMochi();
        break;
      case 'edamame':
      case 'pea':
      case 'zundapea':
        this.eggEdamame();
        break;
      case 'zunda':
      case 'zundamon':
        this.eggZunda();
        break;
      case 'secret':
      case 'hidden':
      case 'easteregg':
        this.eggSecret();
        break;
      case 'dance':
      case 'zundadance':
        this.eggDance();
        break;
      case 'matrix':
      case 'hack':
      case 'cyber':
        this.eggMatrix();
        break;

      default:
        this.cmdUnknown(cmd);
        break;
    }
  }

  // =========================================================================
  // PRIMARY COMMAND HANDLERS (12 Core Commands)
  // =========================================================================

  /**
   * `help`: Output directory of available terminal commands
   */
  cmdHelp(args) {
    this.playClickSound('down');
    const category = args[0] ? args[0].toLowerCase() : 'all';

    let html = '';

    if (category === 'core' || category === 'all') {
      html += `<div class="cli-line"><span class="cli-highlight">CORE SYSTEM COMMANDS:</span></div>` +
              `<div class="cli-line">  • <span class="cli-system">help [cat]</span>      - Command directory (cat: core, game, dev, secret)</div>` +
              `<div class="cli-line">  • <span class="cli-system">info / about</span>    - System specs, kernel diagnostics, project credits</div>` +
              `<div class="cli-line">  • <span class="cli-system">version</span>         - Kernel build version & Rojo sync status</div>` +
              `<div class="cli-line">  • <span class="cli-system">clear</span>           - Flush output log buffer</div>` +
              `<div class="cli-line">  • <span class="cli-system">theme [mode]</span>    - Change CRT phosphor palette (classic, amber, matrix, cozy)</div>`;
    }

    if (category === 'game' || category === 'all') {
      if (html) html += `<br>`;
      html += `<div class="cli-line"><span class="cli-highlight">GAMEPLAY & EXPLORATION:</span></div>` +
              `<div class="cli-line">  • <span class="cli-system">recipes [dish]</span>  - View edamame dishes & cooking score targets</div>` +
              `<div class="cli-line">  • <span class="cli-system">gather [node]</span>   - Simulate tool swing & harvesting loot drops</div>` +
              `<div class="cli-line">  • <span class="cli-system">lore [zone]</span>     - Uncover Zundamon backstory & area lore</div>` +
              `<div class="cli-line">  • <span class="cli-system">play</span>            - Launch Roblox Zundamon's Kitchen experience</div>`;
    }

    if (category === 'dev' || category === 'all') {
      if (html) html += `<br>`;
      html += `<div class="cli-line"><span class="cli-highlight">AUDIO & DEVELOPMENT:</span></div>` +
              `<div class="cli-line">  • <span class="cli-system">music</span>           - Toggle ambient cozy BGM synthesizer</div>` +
              `<div class="cli-line">  • <span class="cli-system">rojo</span>            - View Rojo 7.7.0 tree & level preservation rule</div>` +
              `<div class="cli-line">  • <span class="cli-system">wally</span>           - Inspect Wally package manifest & versions</div>`;
    }

    if (category === 'secret' || category === 'all') {
      if (html) html += `<br>`;
      html += `<div class="cli-line"><span class="cli-highlight">SECRET EASTER EGGS:</span></div>` +
              `<div class="cli-line">  • Try typing secret keywords nanoda! (Try: <span class="cli-system">'nanoda'</span>, <span class="cli-system">'mochi'</span>, <span class="cli-system">'dance'</span>, <span class="cli-system">'matrix'</span>)</div>`;
    }

    const box = `<div class="cli-table">` +
                `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
                `<div class="cli-table-head">│ ZundaCLI.exe v4.09.1995 — COMMAND DIRECTORY            │</div>` +
                `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
                `<div style="padding: 4px 0;">${html}</div>` +
                `</div>`;
    this.appendOutput(box);
  }

  /**
   * `info` / `about`: Hardware specs simulation & project summary
   */
  cmdInfo() {
    this.playClickSound('down');
    const content = 
      `<div class="cli-line"><span class="cli-tag cli-tag-info">[INFO]</span> <span class="cli-highlight">SYSTEM DIAGNOSTICS - Zunda-OS 95</span></div>` +
      `<div class="cli-line">  OS Version   : Zunda-OS 95 [Version 4.09.1995]</div>` +
      `<div class="cli-line">  Kernel       : Edamame Engine 2.0 (Phosphor Web CLI)</div>` +
      `<div class="cli-line">  Memory       : 640KB RAM (512KB Free nanoda!)</div>` +
      `<div class="cli-line">  Audio Engine : Native WebAudio Synthesizer (Stereo / 44.1kHz)</div>` +
      `<div class="cli-line">  Workspace    : Rojo 7.7.0 Sync Active | $ignoreUnknownInstances: ON</div>` +
      `<br>` +
      `<div class="cli-line"><span class="cli-tag cli-tag-system">[SYSTEM]</span> <span class="cli-highlight">PROJECT CREDITS</span></div>` +
      `<div class="cli-line">  Title        : Zundamon's Kitchen V2 (Roblox & Web Hub)</div>` +
      `<div class="cli-line">  Description  : Cozy Infinity Nikki & Zen Edamame-Pea Cooking Sim</div>` +
      `<div class="cli-line">  Frameworks   : Matter ECS, ReplicaService, React, ProfileService</div>` +
      `<div class="cli-line">  Web Interface: Pure HTML5/CSS3 CRT Phosphor Interface (Zero External Assets)</div>`;
    this.appendOutput(content);
  }

  /**
   * `recipes`: Recipe book & cooking minigame target scores
   */
  cmdRecipes(args) {
    const query = args.join(' ').toLowerCase().trim();

    const recipesData = [
      { code: 'R-01', name: 'Zunda Mochi', nameJp: 'ずんだ餅', tier: 'Tier 2', category: 'Classic', time: '7s', ingredients: '🫛 Zunda Pea x5, 🌾 Wheat x8', notes: 5, target: 'PERFECT (>=3 Perfect Notes)', value: '160 Gold Coins' },
      { code: 'R-02', name: 'Zunda Shake', nameJp: 'ずんだシェイク', tier: 'Tier 1', category: 'Drinks', time: '5s', ingredients: '🫛 Zunda Pea x3, 🥛 Milk x4', notes: 4, target: 'GREAT (>=3 Hits)', value: '120 Gold Coins' },
      { code: 'R-03', name: 'Zunda Parfait', nameJp: 'ずんだパフェ', tier: 'Tier 3', category: 'Desserts', time: '10s', ingredients: '🫛 Zunda Pea x6, 🍨 Ice Cream x2, 🍓 Fruit x3', notes: 7, target: 'PERFECT (>=5 Perfect Notes)', value: '280 Gold Coins' },
      { code: 'R-04', name: 'Zunda Dango', nameJp: 'ずんだ団子', tier: 'Tier 1', category: 'Classic', time: '6s', ingredients: '🫛 Zunda Pea x4, 🌾 Rice Flour x5', notes: 4, target: 'GREAT (>=2 Hits)', value: '140 Gold Coins' },
      { code: 'R-05', name: 'Zunda Matcha Latte', nameJp: 'ずんだ抹茶', tier: 'Tier 2', category: 'Drinks', time: '8s', ingredients: '🫛 Zunda Pea x4, 🍵 Matcha x3, 🥛 Oat Milk x4', notes: 5, target: 'GREAT (>=3 Hits)', value: '190 Gold Coins' }
    ];

    if (query) {
      // Find specific recipe card
      const match = recipesData.find(r => r.name.toLowerCase().includes(query) || r.nameJp.includes(query) || r.code.toLowerCase() === query);
      if (match) {
        this.playWinSound('maximize');
        const card = 
          `<div class="cli-table">` +
          `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
          `<div class="cli-table-head">│ <span class="cli-tag cli-tag-recipe">[RECIPE CARD]</span> ${match.name} (${match.nameJp})</div>` +
          `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
          `<div class="cli-line">│ Code       : ${match.code}</div>` +
          `<div class="cli-line">│ Tier       : ${match.tier} (${match.category})</div>` +
          `<div class="cli-line">│ Ingredients: ${match.ingredients}</div>` +
          `<div class="cli-line">│ Cook Time  : ${match.time} | Rhythm Notes: ${match.notes}</div>` +
          `<div class="cli-line">│ Target     : <span class="cli-highlight">${match.target}</span></div>` +
          `<div class="cli-line">│ Market Val : ${match.value}</div>` +
          `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
          `<div class="cli-line"><span class="cli-tag cli-tag-ok">[COOK SIM]</span> Preparing ${match.name}... Done! Nanoda! 🫛✨</div>` +
          `</div>`;
        this.appendOutput(card);
        this.playClickSound('start');
        return;
      }
    }

    // Default: Show Recipe Directory Table
    this.playWinSound('focus');
    let rows = recipesData.map(r => 
      `<div class="cli-table-row">` +
      `<span class="cli-col" style="flex:0.6">${r.code}</span>` +
      `<span class="cli-col" style="flex:1.8"><span class="cli-highlight">${r.name}</span></span>` +
      `<span class="cli-col" style="flex:1">${r.category}</span>` +
      `<span class="cli-col" style="flex:1">${r.tier}</span>` +
      `</div>`
    ).join('');

    const table = 
      `<div class="cli-table">` +
      `<div class="cli-table-head"><span class="cli-tag cli-tag-recipe">[RECIPE BOOK]</span> Signature Zunda Dishes (CraftConfig.lua)</div>` +
      `<div class="cli-table-row cli-table-head">` +
      `<span class="cli-col" style="flex:0.6">CODE</span>` +
      `<span class="cli-col" style="flex:1.8">DISH NAME</span>` +
      `<span class="cli-col" style="flex:1">CATEGORY</span>` +
      `<span class="cli-col" style="flex:1">TIER</span>` +
      `</div>` +
      rows +
      `<div class="cli-line" style="margin-top:4px"><span class="cli-system">Tip:</span> Type <span class="cli-highlight">'recipes &lt;name&gt;'</span> or <span class="cli-highlight">'cook mochi'</span> to view detailed recipe card!</div>` +
      `</div>`;
    this.appendOutput(table);
  }

  /**
   * `gather`: Harvest resource nodes and loot drops
   */
  cmdGather(args) {
    const nodeInput = args[0] ? args[0].toLowerCase() : 'pea';
    this.edamameCount++;

    this.playWinSound('drag');

    let nodeName = 'Zunda Pea Bush';
    let toolName = 'Bronze Harvester';
    let lootItems = ['+2 🫛 Zunda Pea Pods', '+1 🌿 Mint Leaf'];
    let xpGained = 25;

    if (nodeInput.includes('rock') || nodeInput.includes('mine') || nodeInput.includes('gold')) {
      nodeName = 'Gold Rock Vein';
      toolName = 'Bronze Pickaxe';
      lootItems = ['+2 🪙 Gold Ore', '+1 🪨 Marble Rock', '+1 🫛 Zunda Pea (Bonus Drop!)'];
      xpGained = 35;
    } else if (nodeInput.includes('tree') || nodeInput.includes('wood')) {
      nodeName = 'Peawood Tree';
      toolName = 'Bronze Axe';
      lootItems = ['+3 🪵 Softwood Log', '+1 🫛 Zunda Pea Pod'];
      xpGained = 30;
    }

    const log = 
      `<div class="cli-line"><span class="cli-tag cli-tag-ok">[GATHERING]</span> Swinging ${toolName} at node '<span class="cli-highlight">${nodeName}</span>'...</div>` +
      `<div class="cli-line">  *SWISH* ... *CLANG!* (Hit 1/2 - 50 Damage)</div>` +
      `<div class="cli-line">  *SWISH* ... *CRACK!* (Node Harvested!)</div>` +
      `<div class="cli-line"><span class="cli-highlight">[LOOT DROPPED]:</span></div>` +
      lootItems.map(item => `<div class="cli-line">    ${item}</div>`).join('') +
      `<div class="cli-line">  <span class="cli-system">[EXP GAINED]:</span> +${xpGained} Chef Gathering XP | Total Pods Harvested: <span class="cli-highlight">${this.edamameCount}</span></div>`;
    
    this.appendOutput(log);

    // Audio loot chime
    setTimeout(() => {
      this.playWinSound('maximize');
    }, 150);
  }

  /**
   * `lore`: Display Zunda Village zone lore & backstory
   */
  cmdLore(args) {
    this.playWinSound('focus');
    const zoneInput = args[0] ? args[0].toLowerCase() : 'village';

    const loreEntries = {
      village: {
        title: 'Zunda Village (ずんだ村)',
        speaker: '🫛 Elder Edamame',
        quote: '"Welcome to Zunda Village! Here, every recipe tells a story of peaceful harmony between nature and culinary craft."',
        note: 'Center of the Zundamon Kingdom. Home to legendary mochi kitchens.'
      },
      kitchen: {
        title: 'Royal Zunda Kitchen (王立厨房)',
        speaker: '🍳 Chef Zundamon',
        quote: '"The key to perfect Zunda Mochi is pounding fresh green edamame beans with love and rhythm nanoda!"',
        note: 'Increases cooking rhythm note multiplier by +10%.'
      },
      ruins: {
        title: 'Ancient Altar Ruins (古代の遺跡)',
        speaker: '👁 Ancient Voice',
        quote: '"Long ago, the first Zunda Arrow was forged in this celestial oven. The secret recipe slumbers still..."',
        note: 'Unlocks rare ingredient drop rate bonuses.'
      },
      shrine: {
        title: 'Pea Pod Shrine (枝豆神社)',
        speaker: '⛩️ Shrine Guardian',
        quote: '"Offer sweet mochi to receive the blessing of perpetual harvest. May your dough never stick!"',
        note: 'Restores stamina during gathering minigames.'
      }
    };

    const entry = loreEntries[zoneInput] || loreEntries.village;

    const card = 
      `<div class="cli-table">` +
      `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
      `<div class="cli-table-head">│ <span class="cli-tag cli-tag-info">[ZONE LORE]</span> ${entry.title}</div>` +
      `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
      `<div class="cli-line"><span class="cli-highlight">Speaker:</span> ${entry.speaker}</div>` +
      `<div class="cli-line" style="font-style:italic; margin:4px 0;">${entry.quote}</div>` +
      `<div class="cli-line"><span class="cli-system">[LORE NOTE]:</span> ${entry.note}</div>` +
      `</div>`;

    this.appendOutput(card);
  }

  /**
   * `play` / `roblox`: Generate interactive Roblox experience banner
   */
  cmdPlay() {
    this.playClickSound('start');
    const card = 
      `<div class="cli-table">` +
      `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
      `<div class="cli-table-head">│ 🎮 ROBLOX EXPERIENCE — Zundamon's Kitchen V2           │</div>` +
      `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
      `<div class="cli-line">│ Status     : <span class="cli-tag cli-tag-ok">[ONLINE]</span> Server Active</div>` +
      `<div class="cli-line">│ Players    : <span class="cli-highlight">1,420 Chefs Online</span></div>` +
      `<div class="cli-line">│ Genre      : Cozy Cooking & Gathering Simulation</div>` +
      `<div class="cli-line">│ Link       : <a href="https://www.roblox.com/" target="_blank" style="color:var(--term-green); text-decoration:underline">https://www.roblox.com/</a></div>` +
      `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
      `<div class="cli-line"><span class="cli-system">[ACTION]:</span> Click link above to launch Roblox experience nanoda! 🫛✨</div>` +
      `</div>`;
    this.appendOutput(card);
  }

  /**
   * `music`: Toggle ambient cozy BGM synthesizer
   */
  cmdMusic(args) {
    if (typeof window !== 'undefined' && typeof window.toggleCozyBGM === 'function') {
      const isPlaying = window.toggleCozyBGM();
      const statusText = isPlaying 
        ? `<span class="cli-tag cli-tag-audio">[AUDIO ACTIVE]</span> Playing E Major Pentatonic Ambient Loop (650ms tempo).`
        : `<span class="cli-tag cli-tag-warn">[AUDIO PAUSED]</span> Ambient BGM Synthesizer paused.`;
      
      const output = `<div class="cli-line">${statusText}</div>` +
                     `<div class="cli-line"><span class="cli-system">Engine:</span> Native Web Audio API procedural synthesis (Zero external MP3s).</div>`;
      this.appendOutput(output);
    } else {
      this.appendOutput(`<div class="cli-line"><span class="cli-tag cli-tag-audio">[AUDIO]</span> Web Audio BGM Synthesizer engine standard response state.</div>`);
    }
  }

  /**
   * `clear`: Flush terminal output log
   */
  cmdClear() {
    this.playClickSound('up');
    if (this.outputEl) {
      this.outputEl.innerHTML = '';
    }
  }

  /**
   * `version`: Output kernel build specs & Rojo version
   */
  cmdVersion() {
    this.playKeySound('Enter');
    const content = 
      `<div class="cli-line"><span class="cli-highlight">ZundaCLI.exe [Version 4.09.1995]</span></div>` +
      `<div class="cli-line">Build Tag   : v2.0.0-Phosphor-Release (2026.07)</div>` +
      `<div class="cli-line">Rojo Sync   : Rojo 7.7.0 Compliant</div>` +
      `<div class="cli-line">CRT Renderer: Phosphor Green Monospace Canvas Overlay</div>` +
      `<div class="cli-line">License     : MIT License (C) Zundamon's Kitchen Team</div>`;
    this.appendOutput(content);
  }

  /**
   * `theme [mode]`: Switch CRT phosphor color theme
   */
  cmdTheme(args) {
    const rawMode = args[0] ? args[0].toLowerCase().trim() : '';

    if (!rawMode) {
      this.appendOutput(
        `<div class="cli-line"><span class="cli-tag cli-tag-info">[THEME]</span> Current CRT theme: '<span class="cli-highlight">${this.currentTheme}</span>'.</div>` +
        `<div class="cli-line">Available themes: <span class="cli-system">classic-green</span>, <span class="cli-system">amber</span>, <span class="cli-system">matrix</span>, <span class="cli-system">cozy-pea</span></div>` +
        `<div class="cli-line">Usage: <span class="cli-highlight">theme amber</span> or <span class="cli-highlight">theme matrix</span></div>`
      );
      return;
    }

    this.setTheme(rawMode, true);
  }

  /**
   * Apply CRT phosphor visual palette
   * @param {string} mode 
   * @param {boolean} [printFeedback=true] 
   */
  setTheme(mode, printFeedback = true) {
    let normalized = 'classic-green';
    if (mode.includes('amber')) normalized = 'amber';
    else if (mode.includes('matrix') || mode.includes('cyber') || mode.includes('hack')) normalized = 'matrix';
    else if (mode.includes('cozy') || mode.includes('pea') || mode.includes('mochi')) normalized = 'cozy-pea';
    else if (mode.includes('classic') || mode.includes('green')) normalized = 'classic-green';

    this.currentTheme = normalized;

    if (typeof document !== 'undefined') {
      const targets = [this.windowEl, this.bodyEl, document.getElementById('window-zundacli')].filter(Boolean);
      targets.forEach(el => {
        el.setAttribute('data-term-theme', normalized);
        el.setAttribute('data-theme', normalized);
      });
    }

    if (printFeedback) {
      this.playWinSound('maximize');
      this.appendOutput(
        `<div class="cli-line"><span class="cli-tag cli-tag-ok">[OK]</span> Applied CRT Phosphor visual theme: '<span class="cli-highlight">${normalized}</span>'.</div>`
      );
    }
  }

  /**
   * `rojo`: Displays Rojo 7.7.0 workspace mapping tree & Level Preservation Rule
   */
  cmdRojo() {
    this.playClickSound('down');
    const content = 
      `<div class="cli-table">` +
      `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
      `<div class="cli-table-head">│ 🛠️ ROJO 7.7.0 WORKSPACE STRUCTURE & SYNC CONFIG         │</div>` +
      `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
      `<div class="cli-line">│ Project    : default.project.json</div>` +
      `<div class="cli-line">│ Mapping    :</div>` +
      `<div class="cli-line">│   ├── ReplicatedStorage  -&gt; src/shared &amp; Packages</div>` +
      `<div class="cli-line">│   ├── ServerScriptService-&gt; src/server &amp; ServerPackages</div>` +
      `<div class="cli-line">│   ├── StarterPlayer      -&gt; src/client</div>` +
      `<div class="cli-line">│   └── Workspace          -&gt; src/Workspace</div>` +
      `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
      `<div class="cli-line">│ ⚠️ <span class="cli-highlight">ROJO LEVEL PRESERVATION RULE (#1):</span></div>` +
      `<div class="cli-line">│ <span class="cli-tag cli-tag-ok">"$ignoreUnknownInstances": true</span> [ENABLED]</div>` +
      `<div class="cli-line">│ Prevents Rojo from wiping Studio-built terrain &amp; maps!</div>` +
      `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
      `</div>`;
    this.appendOutput(content);
  }

  /**
   * `wally`: Displays Wally package dependencies from wally.toml
   */
  cmdWally() {
    this.playClickSound('down');
    const content = 
      `<div class="cli-table">` +
      `<div class="cli-table-head">┌────────────────────────────────────────────────────────┐</div>` +
      `<div class="cli-table-head">│ 📦 WALLY PACKAGE DEPENDENCIES (fromage3900/zundamons-kitchen) │</div>` +
      `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
      `<div class="cli-line">│ <span class="cli-highlight">SHARED DEPENDENCIES (ReplicatedStorage/Packages):</span></div>` +
      `<div class="cli-line">│  • Matter         : matter-ecs/matter@0.8.4</div>` +
      `<div class="cli-line">│  • ReplicaService : barenton/replicaservice@1.0.1</div>` +
      `<div class="cli-line">│  • React          : jsdotlua/react@17.1.0</div>` +
      `<div class="cli-line">│  • ReactRoblox    : jsdotlua/react-roblox@17.1.0</div>` +
      `<div class="cli-line">│  • Promise        : evaera/promise@4.0.0</div>` +
      `<div class="cli-line">│  • Signal         : sleitnick/signal@2.0.1</div>` +
      `<div class="cli-table-head">├────────────────────────────────────────────────────────┤</div>` +
      `<div class="cli-line">│ <span class="cli-highlight">SERVER DEPENDENCIES (ServerScriptService/ServerPackages):</span></div>` +
      `<div class="cli-line">│  • ProfileService : alreadypro/profileservice@1.0.4</div>` +
      `<div class="cli-table-head">└────────────────────────────────────────────────────────┘</div>` +
      `</div>`;
    this.appendOutput(content);
  }

  /**
   * Unknown command fallback handler
   */
  cmdUnknown(cmd) {
    this.playKeySound('Error');
    this.appendOutput(
      `<div class="cli-line"><span class="cli-tag cli-tag-err">[ERROR]</span> Command not recognized: '<span style="color:#ff6b6b">${this.escapeHTML(cmd)}</span>'. Type <span class="cli-highlight">'help'</span> for available commands.</div>`
    );
  }

  // =========================================================================
  // SECRET ZUNDAMON EASTER EGGS (7 Eggs)
  // =========================================================================

  /**
   * Egg 1: `nanoda`
   */
  eggNanoda() {
    this.playEasterEggSound('nanoda');
    const content = 
      `<div class="cli-table">` +
      `<div class="cli-line"><span class="cli-highlight">(๑&gt;◡&lt;๑) Nanoda! 🫛 Nanoda!</span></div>` +
      `<div class="cli-line">Zundamon is here to support your cooking journey, nanoda!</div>` +
      `<div class="cli-line"><span class="cli-system">Catchphrase:</span> "Zunda Mochi is the greatest dish in the universe nanoda!"</div>` +
      `</div>`;
    this.appendOutput(content);
  }

  /**
   * Egg 2: `mochi`
   */
  eggMochi() {
    this.playEasterEggSound('mochi');
    const content = 
      `<pre class="cli-ascii-banner">` +
      `  🍡 [ 🫛🫛🫛 ] 🍡\n` +
      `  ZUNDA MOCHI DELIGHT\n` +
      `</pre>` +
      `<div class="cli-line"><span class="cli-tag cli-tag-recipe">[FUN FACT]</span> Zunda Mochi paste is made from sweet crushed young edamame beans!</div>`;
    this.appendOutput(content);
  }

  /**
   * Egg 3: `edamame`
   */
  eggEdamame() {
    this.edamameCount += 5;
    this.playEasterEggSound('edamame');
    const content = 
      `<div class="cli-line"><span class="cli-highlight">🫛 🫛 🫛 EDAMAME BURST! 🫛 🫛 🫛</span></div>` +
      `<div class="cli-line">Gathered +5 Bonus Edamame Pods! (Total: <span class="cli-system">${this.edamameCount}</span>)</div>` +
      `<div class="cli-line"><span class="cli-system">Trivia:</span> Edamame beans are harvested while immature and soft inside their pods!</div>`;
    this.appendOutput(content);
  }

  /**
   * Egg 4: `zunda`
   */
  eggZunda() {
    this.playEasterEggSound('zunda');
    const content = 
      `<pre class="cli-ascii-banner">` +
      ` (๑&gt;◡&lt;๑)  ZUNDA POWER MAX!\n` +
      `  / | \\   Zunda Arrow Loaded!\n` +
      `  /   \\   Edamame Kingdom Champion!\n` +
      `</pre>`;
    this.appendOutput(content);
  }

  /**
   * Egg 5: `secret`
   */
  eggSecret() {
    this.isSecretMode = !this.isSecretMode;
    this.prompt = this.isSecretMode ? 'zunda@secret:~$ ' : 'zunda>';
    if (this.labelEl) this.labelEl.textContent = this.prompt;

    this.playEasterEggSound('secret');
    const content = 
      `<div class="cli-line"><span class="cli-tag cli-tag-system">[SECRET UNLOCKED]</span> Developer Terminal Mode: <span class="cli-highlight">${this.isSecretMode ? 'ENABLED' : 'DISABLED'}</span></div>` +
      `<div class="cli-line">Legendary Recipe Formula: <span class="cli-system">"Zunda Paradise"</span> = 🫛 Zunda Pea x10 + 🍯 Golden Honey x5 + ✨ Starlight Shards x3</div>`;
    this.appendOutput(content);
  }

  /**
   * Egg 6: `dance`
   */
  eggDance() {
    this.playEasterEggSound('dance');
    const frames = [
      `( &gt;'-')&gt;  ZUNDA DANCE!`,
      `^('-')^   NANODA!`,
      `&lt;('-'&lt;)  MOCHI BOOGIE!`,
      `v('-')v   🫛✨`
    ];

    frames.forEach((f, idx) => {
      setTimeout(() => {
        this.appendOutput(`<div class="cli-line"><span class="cli-highlight">${f}</span></div>`);
      }, idx * 180);
    });
  }

  /**
   * Egg 7: `matrix`
   */
  eggMatrix() {
    this.setTheme('matrix', false);
    this.playEasterEggSound('matrix');
    const codeStream = 
      `<div class="cli-line"><span class="cli-highlight">[KERNEL] HACKING EDAMAME MAINFRAME...</span></div>` +
      `<div class="cli-line">01001010 01010101 01001110 01000100 01000001</div>` +
      `<div class="cli-line">[ACCESS GRANTED]: Cyber Zunda Matrix Engaged nanoda!</div>`;
    this.appendOutput(codeStream);
  }

  // =========================================================================
  // DOM & UTILITY HELPERS
  // =========================================================================

  /**
   * Append HTML snippet to terminal output log
   * @param {string} html 
   */
  appendOutput(html) {
    if (!this.outputEl) return;
    const wrapper = document.createElement('div');
    wrapper.innerHTML = html;
    this.outputEl.appendChild(wrapper);
    this.scrollToBottom();
  }

  /**
   * Non-intrusive auto-scroll logic with manual scrolllock detection
   * @param {boolean} [force=false] Force scroll to bottom regardless of scrolllock
   */
  scrollToBottom(force = false) {
    if (!this.outputEl) return;

    if (!this.userScrolledUp || force) {
      this.outputEl.scrollTop = this.outputEl.scrollHeight;
      this.userScrolledUp = false;
      this.toggleScrollPill(false);
    }
  }

  /**
   * Output log scroll event listener for user scroll-up detection
   */
  handleScroll() {
    if (!this.outputEl) return;
    const distanceToBottom = this.outputEl.scrollHeight - this.outputEl.scrollTop - this.outputEl.clientHeight;
    this.userScrolledUp = distanceToBottom > this.scrollThreshold;
    this.toggleScrollPill(this.userScrolledUp);
  }

  /**
   * Toggle visibility of '#cli-scroll-bottom-btn' resume pill
   * @param {boolean} show 
   */
  toggleScrollPill(show) {
    if (this.scrollBtnEl) {
      if (show) {
        this.scrollBtnEl.classList.remove('hidden');
      } else {
        this.scrollBtnEl.classList.add('hidden');
      }
    }
  }

  /**
   * Handle mobile virtual keyboard toolbar buttons
   * @param {HTMLElement} btn 
   */
  handleMobileVKey(btn) {
    const key = btn.dataset.key;
    const cmd = btn.dataset.cmd;

    if (key === 'Tab') {
      this.handleTabCompletion();
    } else if (key === 'ArrowUp') {
      this.handleHistoryUp();
    } else if (key === 'ArrowDown') {
      this.handleHistoryDown();
    } else if (cmd) {
      this.submitCommand(cmd);
    }

    if (this.inputEl) this.inputEl.focus();
  }

  /**
   * Sanitize string for HTML insertion
   * @param {string} str 
   * @returns {string} Escaped string
   */
  escapeHTML(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // =========================================================================
  // AUDIO ENGINE SYNTHESIS WRAPPERS
  // =========================================================================

  playKeySound(key) {
    if (typeof window !== 'undefined' && typeof window.playKeySFX === 'function') {
      window.playKeySFX(key);
    }
  }

  playClickSound(variant) {
    if (typeof window !== 'undefined' && typeof window.playClickSFX === 'function') {
      window.playClickSFX(variant);
    }
  }

  playWinSound(action) {
    if (typeof window !== 'undefined' && typeof window.playWindowSFX === 'function') {
      window.playWindowSFX(action);
    }
  }

  playEasterEggSound(type) {
    if (typeof window !== 'undefined' && window.ZundaAudio && window.ZundaAudio.ctx && !window.ZundaAudio.isMuted) {
      try {
        const ctx = window.ZundaAudio.ctx;
        const now = ctx.currentTime;

        if (type === 'nanoda' || type === 'zunda') {
          // Ascending 4-note arpeggio chime (E5-G5-B5-E6)
          [659.25, 783.99, 987.77, 1318.51].forEach((freq, idx) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, now + idx * 0.04);
            gain.gain.setValueAtTime(0.2, now + idx * 0.04);
            gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.04 + 0.1);
            osc.connect(gain);
            gain.connect(window.ZundaAudio.sfxGain);
            osc.start(now + idx * 0.04);
            osc.stop(now + idx * 0.04 + 0.11);
          });
        } else if (type === 'mochi') {
          // Low-pass pitch squish slide
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(400, now);
          osc.frequency.exponentialRampToValueAtTime(700, now + 0.05);
          osc.frequency.exponentialRampToValueAtTime(200, now + 0.12);
          gain.gain.setValueAtTime(0.25, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.13);
          osc.connect(gain);
          gain.connect(window.ZundaAudio.sfxGain);
          osc.start(now);
          osc.stop(now + 0.14);
        } else if (type === 'edamame') {
          // Staccato triple high pop
          [1200, 1500, 1800].forEach((freq, idx) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'square';
            osc.frequency.setValueAtTime(freq, now + idx * 0.03);
            gain.gain.setValueAtTime(0.12, now + idx * 0.03);
            gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.03 + 0.025);
            osc.connect(gain);
            gain.connect(window.ZundaAudio.sfxGain);
            osc.start(now + idx * 0.03);
            osc.stop(now + idx * 0.03 + 0.03);
          });
        } else if (type === 'secret') {
          // Mystery descending synth chime
          [987.77, 783.99, 659.25, 493.88].forEach((freq, idx) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, now + idx * 0.06);
            gain.gain.setValueAtTime(0.2, now + idx * 0.06);
            gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.06 + 0.15);
            osc.connect(gain);
            gain.connect(window.ZundaAudio.sfxGain);
            osc.start(now + idx * 0.06);
            osc.stop(now + idx * 0.06 + 0.16);
          });
        } else if (type === 'matrix') {
          // Cyber glitch frequency sweep
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(1500, now);
          osc.frequency.linearRampToValueAtTime(200, now + 0.15);
          gain.gain.setValueAtTime(0.18, now);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
          osc.connect(gain);
          gain.connect(window.ZundaAudio.sfxGain);
          osc.start(now);
          osc.stop(now + 0.17);
        } else {
          this.playClickSound('start');
        }
      } catch (err) {
        this.playClickSound('down');
      }
    } else {
      this.playClickSound('down');
    }
  }
}

// Global window export and auto-instantiation
if (typeof window !== 'undefined') {
  window.ZundaTerminal = ZundaTerminal;
  document.addEventListener('DOMContentLoaded', () => {
    if (!window.zundaTerminal) {
      window.zundaTerminal = new ZundaTerminal();
    }
  });
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ZundaTerminal;
}
