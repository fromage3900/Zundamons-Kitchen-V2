# Architecture & Technical Design Specification: Interactive Phosphor Web Terminal (`site/terminal.js`)

## Executive Summary
This document defines the complete software architecture, data structures, event models, command algorithms, audio integrations, and DOM bindings for `site/terminal.js` (`ZundaCLI.exe`).

---

## 1. Component Architecture & Class Design

`site/terminal.js` will export a modular ES6 class `ZundaTerminal` (instantiated as a global singleton `window.zundaTerminal`).

### 1.1 State Schema
```javascript
class ZundaTerminal {
  constructor(options = {}) {
    // DOM Element References
    this.windowEl = options.windowEl || document.getElementById('window-zundacli');
    this.bodyEl = options.bodyEl || document.querySelector('#window-zundacli .cli-body');
    this.outputEl = options.outputEl || document.getElementById('cli-output');
    this.formEl = options.formEl || document.getElementById('cli-input-form');
    this.inputEl = options.inputEl || document.getElementById('cli-input');
    this.labelEl = options.labelEl || document.querySelector('.cli-prompt-label');

    // Terminal Configuration & State
    this.prompt = options.prompt || 'zunda>';
    this.history = [];
    this.historyIndex = 0;
    this.currentDraft = '';
    this.currentTheme = 'phosphor';
    this.edamameCount = 0;

    // Command Keyword Registry
    this.commands = [
      'help', 'info', 'recipes', 'gather', 'lore', 
      'play', 'music', 'clear', 'version', 'theme', 'edamame'
    ];

    // Alias / Convenience Commands
    this.aliases = ['cook', 'vn', 'roblox', 'status', 'about'];
  }
}
```

---

## 2. Terminal Prompt State & Input Handling

### 2.1 Prompt State Rendering
- **Prompt String**: Standardized prompt label set to `zunda>` (or HTML `<span class="cli-prompt-label">zunda&gt;</span>`).
- **Input Line DOM**:
  ```html
  <form id="cli-input-form" class="cli-prompt-line" autocomplete="off" onsubmit="return false;">
      <label for="cli-input" class="cli-prompt-label">zunda&gt;</label>
      <input type="text" id="cli-input" class="cli-input-field" placeholder="Type a command (e.g., help, gather, recipes)..." spellcheck="false">
  </form>
  ```
- **Echoing Prompts**: Upon command submission, an echo element is appended to `#cli-output`:
  ```javascript
  const echoLine = document.createElement('p');
  echoLine.className = 'cli-line cli-user-echo';
  echoLine.innerHTML = `<span class="cli-prompt-label">${this.prompt}</span> ${escapeHTML(rawCommand)}`;
  this.outputEl.appendChild(echoLine);
  ```

### 2.2 Cursor & Focus Management
- **Cursor Rendering**: Native input field cursor using CSS `caret-color: var(--term-cursor)` with glowing retro phosphor styling.
- **Focus Retention**: 
  - Clicking anywhere inside `#window-zundacli` or `.cli-body` automatically shifts focus to `this.inputEl`.
  - When `windowManager.bringToFront('window-zundacli')` activates, `this.inputEl.focus()` is triggered.

---

## 3. Command History Buffer & Navigation Algorithm

### 3.1 Data Flow
- `this.history`: Array of strings containing past submitted commands.
- `this.historyIndex`: Integer pointing to current position in `this.history` (0 to `history.length`).
- `this.currentDraft`: String storing uncommitted typed text before initiating history traversal.

### 3.2 Up / Down Arrow Key Algorithm
```javascript
handleKeyDown(e) {
  if (e.key === 'ArrowUp') {
    e.preventDefault();
    if (this.history.length === 0) return;

    // Preserve unsaved draft when starting upward navigation
    if (this.historyIndex === this.history.length) {
      this.currentDraft = this.inputEl.value;
    }

    if (this.historyIndex > 0) {
      this.historyIndex--;
      this.inputEl.value = this.history[this.historyIndex];
      this.moveCursorToEnd();
      this.playKeySound('ArrowUp');
    }
  } else if (e.key === 'ArrowDown') {
    e.preventDefault();
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
}
```

### 3.3 Submission History Push
Upon pressing `Enter`:
- Trimmed command is added to `this.history` if non-empty and not identical to immediate predecessor (`history[history.length - 1] !== command`).
- Reset `this.historyIndex = this.history.length`.
- Clear `this.currentDraft = ''`.

---

## 4. Tab Auto-Completion Algorithm

### 4.1 Keyword Spectrum
Keywords: `help`, `info`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme`, `edamame`.

### 4.2 Tab Algorithm Logic
```javascript
handleTabCompletion(e) {
  e.preventDefault();
  const rawInput = this.inputEl.value;
  const trimmed = rawInput.trimStart().toLowerCase();
  
  if (!trimmed) return;

  const matches = this.commands.filter(cmd => cmd.startsWith(trimmed));

  if (matches.length === 1) {
    // 1. Single exact prefix match -> completion with space
    this.inputEl.value = matches[0] + ' ';
    this.playKeySound('Tab');
  } else if (matches.length > 1) {
    // 2. Multiple matches -> calculate Longest Common Prefix (LCP)
    const lcp = getLongestCommonPrefix(matches);
    if (lcp.length > trimmed.length) {
      this.inputEl.value = lcp;
    }
    
    // Output match options into terminal output log
    const matchLine = document.createElement('p');
    matchLine.className = 'cli-line cli-tab-matches';
    matchLine.innerHTML = `<span class="cli-system">${this.prompt} ${rawInput}</span><br>` +
                          `<span class="cli-highlight">Matches:</span> ${matches.join('  ')}`;
    this.outputEl.appendChild(matchLine);
    this.scrollToBottom();
    this.playKeySound('Tab');
  } else {
    // 3. No match found -> audio feedback indicator
    this.playKeySound('Error');
  }
}
```

---

## 5. Web Audio API & Sound Trigger Integration

### 5.1 Sound Interface Alignment
The terminal interfaces directly with `site/assets/audio_engine.js`:
- `window.playKeySFX(key)`: Triggers synthesizer for character typing (`square`/`triangle` wave pitch blip).
- `window.playClickSFX(variant)`: UI action click sound (`down`, `up`, `start`).
- `window.toggleCozyBGM()`: Ambient background music trigger.
- **Unified Alias Guard**: `terminal.js` attaches `ZundaAudio.playClick = window.playClickSFX` if unassigned to guarantee backward compatibility with `ZundaAudio.playClick()`.

### 5.2 Sound Trigger Matrix
| Action | Audio Method | Parameters | Rationale |
|---|---|---|---|
| Typing key down | `playKeySFX(key)` | `e.key` | Mechanical terminal key click |
| Enter key submit | `playKeySFX('Enter')` | `'Enter'` | Low-frequency terminal return bump |
| Tab completion | `playKeySFX('Tab')` | `'Tab'` | Completion blip |
| `music` / `play` command | `toggleCozyBGM()` | - | Synthesizer BGM toggle |
| `clear` / `theme` command | `playClickSFX('start')` | `'start'` | Chime feedback for system state change |

---

## 6. Primary Command Specification Matrix

| Command | Arguments | Execution Behavior | Output Output Format |
|---|---|---|---|
| `help` | None | Displays grouped list of commands | Green phosphor list with command names & descriptions |
| `info` | None | System diagnostics & version specs | OS Version, CPU, Memory (640KB), Audio Engine status |
| `recipes` | None | Lists signature Zunda dishes | Recipe card list with index numbers & icons |
| `gather` | None | Increments `edamameCount`, text minigame | "Gathered +1 Edamame Pod! 🫛 (Total: N)" |
| `lore` | None | Displays Zundamon lore text | Retro backstory of Zunda Arrow & Edamame Kingdom |
| `play` / `music` | None | Calls `toggleCozyBGM()` | "Cozy BGM state: [PLAYING / PAUSED] nanoda!" |
| `clear` | None | Clears `#cli-output` DOM children | Output buffer cleared, input field focused |
| `version` | None | Displays build release details | `ZundaCLI.exe v2.0.0 [Build 1995.04.09]` |
| `theme` | `[name]` | Changes CSS color theme | Applied theme notification (`phosphor`, `amber`, `cozy`, `cyan`) |
| `edamame` | None | Easter Egg ASCII art | Zundamon ASCII face + "Zunda nanoda! 🫛✨" |

---

## 7. DOM & HTML Integration Specification

1. **Script Tag in `site/index.html`**:
   Insert before closing `</body>`:
   ```html
   <script src="assets/audio_engine.js"></script>
   <script src="window_manager.js"></script>
   <script src="terminal.js"></script>
   ```

2. **Markup Alignment in `#window-zundacli`**:
   Update prompt label to `zunda>` for consistent CLI identity.

3. **CSS Theme Hooks in `site/style.css`**:
   Add support for terminal theme data attributes:
   ```css
   .cli-body[data-theme="amber"] {
     color: #ffb000;
     text-shadow: 0 0 8px rgba(255, 176, 0, 0.6);
   }
   .cli-body[data-theme="cyan"] {
     color: #00f3ff;
     text-shadow: 0 0 8px rgba(0, 243, 255, 0.6);
   }
   ```
