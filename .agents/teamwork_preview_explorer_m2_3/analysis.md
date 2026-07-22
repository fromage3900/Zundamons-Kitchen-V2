# Specification & Analysis: Audio Engine Remediation & Roblox UI Export Hooks

**Target Files**: 
- `site/assets/audio_engine.js`
- `site/window_manager.js` (New Modular File / Script Integration)
- `site/index.html` (Reference Integration)

---

## 1. Executive Summary

This report provides the complete architecture and code specification for:
1. **Audio Engine Remediation (`site/assets/audio_engine.js`)**: Resolving three critical audio defects: missing volume persistence in `init()`, un-attenuated full volume 1.0 square wave bursts for `playClickSFX('invalid')`, and a timer race condition during rapid BGM toggling that terminates active ambient pads.
2. **Roblox UI ScreenGui Export Mapping Metadata (`site/window_manager.js`)**: Creating a modular `WindowManager` system with an `exportScreenGuiLayout()` API that parses active window states, dimensions, titlebars, and CSS custom variables into a Roblox Studio ScreenGui JSON mapping tree for seamless Luau UI import.

---

## 2. Audio Engine Remediation Analysis (`site/assets/audio_engine.js`)

### 2.1 Problem 1: LocalStorage Volume Persistence in `init()`

#### Root Cause Analysis
In `site/assets/audio_engine.js`:
- `setVolume(val)` (lines 70–76) writes `localStorage.setItem('zunda_os_volume', this.volume.toString());`.
- However, inside `ZundaAudio.init()` (lines 19–46), `this.volume` is initialized to the default `0.7` (line 13). `init()` loads `zunda_os_muted` but **never reads `zunda_os_volume`**.
- As a result, stored volume preferences are lost upon page reload or audio re-initialization.

#### Proposed Solution & Implementation
In `ZundaAudio.init()`:
1. Query `localStorage.getItem('zunda_os_volume')`.
2. If non-null, parse with `parseFloat(savedVol)`.
3. If numeric and within range, update `this.volume = Math.max(0, Math.min(1, parsedVol))` prior to creating and setting `this.masterGain`.

```javascript
// Load persisted state
const savedVol = localStorage.getItem('zunda_os_volume');
if (savedVol !== null) {
  const parsedVol = parseFloat(savedVol);
  if (!isNaN(parsedVol)) {
    this.volume = Math.max(0, Math.min(1, parsedVol));
  }
}
```

---

### 2.2 Problem 2: Attenuated SFX Beep for `'invalid'` / Unknown Variants

#### Root Cause Analysis
In `playClickSFX(variant = 'down')` (lines 83–117):
- An oscillator (`square` by default) and gain node are instantiated.
- The `if / else if` branches check for `variant === 'down'`, `variant === 'up'`, and `variant === 'start'`.
- When `playClickSFX('invalid')` or any unknown variant is passed, none of the conditional branches execute.
- `gain.gain` remains uninitialized, defaulting to Web Audio API's default value of **1.0 (100% full volume)**.
- `osc.start(now)` plays an un-attenuated, blaring square wave tone until `osc.stop(now + 0.03)`.

#### Proposed Solution & Implementation
Add an explicit `else` branch in `playClickSFX()` to capture `'invalid'` and unknown click variants:
1. Set low base frequency (180Hz ramping down to 60Hz over 0.03s).
2. Set initial gain to an attenuated level of `0.15` (never 1.0).
3. Apply an exponential gain ramp down to `0.001` over `0.03s`.

```javascript
  } else {
    // Attenuated SFX Beep for 'invalid' or unknown click variants
    osc.type = 'square';
    osc.frequency.setValueAtTime(180, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.03);
    gain.gain.setValueAtTime(0.15, now); // Attenuated initial gain (never 1.0)
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
  }
```

---

### 2.3 Problem 3: BGM Rapid Toggle Race Condition

#### Root Cause Analysis
In `stopCozyBGM()` (lines 320–341):
- When stopping BGM, `ZundaAudio.bgmPadGain.gain.linearRampToValueAtTime(0.001, now + 1.0)` is scheduled, followed by a `setTimeout(..., 1050)` that stops the pad oscillators (`bgmPadOscs`) and sets `ZundaAudio.bgmPadOscs = null`.
- If the user rapidly toggles BGM off and back on within 1.05 seconds:
  1. `stopCozyBGM()` schedules the 1050ms timeout.
  2. `startCozyBGM()` is invoked immediately, sets `bgmPlaying = true`, creates *new* pad oscillators, and assigns them to `ZundaAudio.bgmPadOscs`.
  3. The previously scheduled 1050ms timeout fires and executes `ZundaAudio.bgmPadOscs.forEach(osc => osc.stop())`, killing the newly created BGM pad oscillators while BGM is playing!

#### Proposed Solution & Implementation
1. Add property `bgmStopTimeout: null` to `ZundaAudio`.
2. In `startCozyBGM()`: If `this.bgmStopTimeout` is present, call `clearTimeout(this.bgmStopTimeout)` and reset `this.bgmStopTimeout = null`.
3. In `stopCozyBGM()`: Clear any existing `bgmStopTimeout` before creating a new timer, and store the handle in `ZundaAudio.bgmStopTimeout`.

```javascript
// In startCozyBGM():
if (ZundaAudio.bgmStopTimeout) {
  clearTimeout(ZundaAudio.bgmStopTimeout);
  ZundaAudio.bgmStopTimeout = null;
}

// In stopCozyBGM():
if (ZundaAudio.bgmStopTimeout) {
  clearTimeout(ZundaAudio.bgmStopTimeout);
  ZundaAudio.bgmStopTimeout = null;
}
ZundaAudio.bgmStopTimeout = setTimeout(() => {
  if (ZundaAudio.bgmPadOscs) {
    ZundaAudio.bgmPadOscs.forEach(osc => {
      try { osc.stop(); } catch(e){}
    });
    ZundaAudio.bgmPadOscs = null;
  }
  ZundaAudio.bgmStopTimeout = null;
}, 1050);
```

---

## 3. Roblox UI ScreenGui Export Mapping Metadata (`site/window_manager.js`)

### 3.1 Architecture Overview & Decoupling

To align with workspace rules:
- **Client UI Decoupling**: UI layout data exported from web can be consumed by Roblox client bootstrap scripts (`ClientGuiBootstrap`) to build or configure UI frames inside `PlayerGui`.
- **Top-Level ScreenGui Settings**: Standardized `ResetOnSpawn = false` on export.
- **Modal Visibility**: Default `panel.Visible = false` or explicit window visibility state.

`site/window_manager.js` acts as an object-oriented Window Manager module for Zunda-OS 95, managing active window state, z-indexing, dragging, window controls, and exposing `WindowManager.exportScreenGuiLayout()`.

---

### 3.2 `WindowManager.exportScreenGuiLayout()` Design

#### Method Signature & Workflow
`WindowManager.exportScreenGuiLayout(options = {})`
1. **DOM Query & Resolution**: Queries all window elements (`.window`) within `#window-container`.
2. **CSS Custom Property Extraction**: Reads theme color variables (`--win95-bg`, `--win95-title-bg`, `--win95-title-text`, `--zunda-green`, `--win95-border-light`, `--win95-border-dark`) from `document.documentElement` computed style.
3. **Bounding Rect & Geometry Resolution**: Extracts left, top, width, and height values in pixels and converts them to Roblox `UDim2` representations:
   - `Position = UDim2.new(0, left, 0, top)`
   - `Size = UDim2.new(0, width, 0, height)`
4. **Hierarchical Mapping**:
   - **ScreenGui**: Container metadata (`ResetOnSpawn: false`, `DisplayOrder: 10`).
   - **Window Frame**: Master window frame (`ClassName: "Frame"`, `Name: "Window_" + id`, `ZIndex`, `Visible`).
   - **TitleBar Frame**: Titlebar child frame (`Name: "TitleBar"`, `Size: UDim2.new(1, 0, 0, 24)`, `BackgroundColor3Hex`).
   - **TitleText Label**: (`ClassName: "TextLabel"`, `Text`, `TextColor3Hex`).
   - **Control Buttons**: (`MinimizeBtn`, `MaximizeBtn`, `CloseBtn`).
   - **MenuBar Frame**: Optional menu items list.
   - **Window Body Frame**: Main content area (`ClassName: "Frame"`, `Name: "WindowBody"`).
5. **Output**: Structured JSON layout object ready for serialization or direct Roblox Studio import via Luau / MCP tools.

---

### 3.3 Exported JSON Schema Example

```json
{
  "$schema": "https://zundamon.kitchen/schemas/roblox-screengui-v1.json",
  "exportedAt": "2026-07-21T20:46:04Z",
  "screenGui": {
    "name": "ZundaOS95ScreenGui",
    "resetOnSpawn": false,
    "displayOrder": 10,
    "themeVariables": {
      "bgBackgroundColor": "#c0c0c0",
      "titleBarActiveColor": "#008080",
      "titleBarInactiveColor": "#808080",
      "titleTextColor": "#ffffff",
      "borderLightColor": "#ffffff",
      "borderDarkColor": "#404040",
      "zundaGreenAccent": "#2e7d32"
    },
    "windows": [
      {
        "id": "zundacli",
        "elementId": "window-zundacli",
        "robloxName": "Window_ZundaCLI",
        "className": "Frame",
        "visible": true,
        "zIndex": 101,
        "layout": {
          "position": { "scaleX": 0, "offsetX": 60, "scaleY": 0, "offsetY": 40 },
          "size": { "scaleX": 0, "offsetX": 680, "scaleY": 0, "offsetY": 440 },
          "anchorPoint": { "x": 0, "y": 0 }
        },
        "style": {
          "backgroundColorHex": "#c0c0c0",
          "borderStyle": "Inset3D"
        },
        "components": {
          "titleBar": {
            "robloxName": "TitleBar",
            "className": "Frame",
            "backgroundColorHex": "#008080",
            "size": { "scaleX": 1, "offsetX": 0, "scaleY": 0, "offsetY": 24 },
            "titleText": "ZundaCLI.exe — Command Prompt",
            "titleTextColorHex": "#ffffff",
            "controls": [
              { "name": "MinimizeBtn", "text": "_", "action": "minimize" },
              { "name": "MaximizeBtn", "text": "🗖", "action": "maximize" },
              { "name": "CloseBtn", "text": "✕", "action": "close" }
            ]
          },
          "menuBar": {
            "visible": true,
            "items": ["File", "Edit", "View", "Help"]
          },
          "body": {
            "robloxName": "WindowBody",
            "className": "Frame",
            "backgroundColorHex": "#000000",
            "textColorHex": "#33ff66",
            "contentType": "CLI"
          }
        }
      }
    ]
  }
}
```

---

## 4. Proposed Code Diffs & File Implementations

### 4.1 Remediation Patch for `site/assets/audio_engine.js`

```javascript
<<<<
  init() {
    if (this.ctx) return;
    const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtxClass) return;

    this.ctx = new AudioCtxClass();

    // Master Gain Node
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.volume, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    // SFX Bus Gain
    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.setValueAtTime(0.8, this.ctx.currentTime);
    this.sfxGain.connect(this.masterGain);

    // BGM Bus Gain
    this.bgmGain = this.ctx.createGain();
    this.bgmGain.gain.setValueAtTime(0.4, this.ctx.currentTime);
    this.bgmGain.connect(this.masterGain);

    // Load persisted state
    const savedMute = localStorage.getItem('zunda_os_muted');
    if (savedMute !== null) {
      this.setMute(savedMute === 'true');
    }
  },
====
  bgmStopTimeout: null,

  init() {
    if (this.ctx) return;
    const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtxClass) return;

    // Load persisted volume state before node initialization
    const savedVol = localStorage.getItem('zunda_os_volume');
    if (savedVol !== null) {
      const parsedVol = parseFloat(savedVol);
      if (!isNaN(parsedVol)) {
        this.volume = Math.max(0, Math.min(1, parsedVol));
      }
    }

    this.ctx = new AudioCtxClass();

    // Master Gain Node
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : this.volume, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    // SFX Bus Gain
    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.setValueAtTime(0.8, this.ctx.currentTime);
    this.sfxGain.connect(this.masterGain);

    // BGM Bus Gain
    this.bgmGain = this.ctx.createGain();
    this.bgmGain.gain.setValueAtTime(0.4, this.ctx.currentTime);
    this.bgmGain.connect(this.masterGain);

    // Load persisted mute state
    const savedMute = localStorage.getItem('zunda_os_muted');
    if (savedMute !== null) {
      this.setMute(savedMute === 'true');
    }
  },
>>>>
```

```javascript
<<<<
function playClickSFX(variant = 'down') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  osc.type = variant === 'start' ? 'triangle' : 'square';

  if (variant === 'down') {
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(150, now + 0.025);
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);
  } else if (variant === 'up') {
    osc.frequency.setValueAtTime(300, now);
    osc.frequency.exponentialRampToValueAtTime(800, now + 0.020);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.020);
  } else if (variant === 'start') {
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.setValueAtTime(659.25, now + 0.03); // E5
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
  }

  osc.connect(gain);
  gain.connect(ZundaAudio.sfxGain);

  osc.start(now);
  osc.stop(now + (variant === 'start' ? 0.085 : 0.03));
}
====
function playClickSFX(variant = 'down') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  osc.type = variant === 'start' ? 'triangle' : 'square';

  if (variant === 'down') {
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(150, now + 0.025);
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);
  } else if (variant === 'up') {
    osc.frequency.setValueAtTime(300, now);
    osc.frequency.exponentialRampToValueAtTime(800, now + 0.020);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.020);
  } else if (variant === 'start') {
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.setValueAtTime(659.25, now + 0.03); // E5
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
  } else {
    // Attenuated SFX Beep for 'invalid' or unknown variants
    osc.type = 'square';
    osc.frequency.setValueAtTime(180, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.03);
    gain.gain.setValueAtTime(0.15, now); // Attenuated initial gain (never 1.0)
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
  }

  osc.connect(gain);
  gain.connect(ZundaAudio.sfxGain);

  osc.start(now);
  osc.stop(now + (variant === 'start' ? 0.085 : 0.03));
}
>>>>
```

```javascript
<<<<
function startCozyBGM() {
  if (ZundaAudio.bgmPlaying || !ZundaAudio.ctx) return;
  ZundaAudio.bgmPlaying = true;
====
function startCozyBGM() {
  if (ZundaAudio.bgmPlaying || !ZundaAudio.ctx) return;

  // Clear any pending BGM stop timeouts from rapid toggles
  if (ZundaAudio.bgmStopTimeout) {
    clearTimeout(ZundaAudio.bgmStopTimeout);
    ZundaAudio.bgmStopTimeout = null;
  }

  ZundaAudio.bgmPlaying = true;
>>>>
```

```javascript
<<<<
function stopCozyBGM() {
  if (!ZundaAudio.bgmPlaying) return;
  ZundaAudio.bgmPlaying = false;

  if (ZundaAudio.bgmInterval) {
    clearInterval(ZundaAudio.bgmInterval);
    ZundaAudio.bgmInterval = null;
  }

  if (ZundaAudio.bgmPadGain && ZundaAudio.ctx) {
    const now = ZundaAudio.ctx.currentTime;
    ZundaAudio.bgmPadGain.gain.linearRampToValueAtTime(0.001, now + 1.0);
    setTimeout(() => {
      if (ZundaAudio.bgmPadOscs) {
        ZundaAudio.bgmPadOscs.forEach(osc => {
          try { osc.stop(); } catch(e){}
        });
        ZundaAudio.bgmPadOscs = null;
      }
    }, 1050);
  }
}
====
function stopCozyBGM() {
  if (!ZundaAudio.bgmPlaying) return;
  ZundaAudio.bgmPlaying = false;

  if (ZundaAudio.bgmInterval) {
    clearInterval(ZundaAudio.bgmInterval);
    ZundaAudio.bgmInterval = null;
  }

  if (ZundaAudio.bgmPadGain && ZundaAudio.ctx) {
    const now = ZundaAudio.ctx.currentTime;
    ZundaAudio.bgmPadGain.gain.linearRampToValueAtTime(0.001, now + 1.0);

    if (ZundaAudio.bgmStopTimeout) {
      clearTimeout(ZundaAudio.bgmStopTimeout);
      ZundaAudio.bgmStopTimeout = null;
    }

    ZundaAudio.bgmStopTimeout = setTimeout(() => {
      if (ZundaAudio.bgmPadOscs) {
        ZundaAudio.bgmPadOscs.forEach(osc => {
          try { osc.stop(); } catch(e){}
        });
        ZundaAudio.bgmPadOscs = null;
      }
      ZundaAudio.bgmStopTimeout = null;
    }, 1050);
  }
}
>>>>
```

---

### 4.2 Code Implementation for `site/window_manager.js`

```javascript
/**
 * WindowManager — Zunda-OS 95 Floating Window Stack & Roblox Export Integration
 * Manages window focus, drag-and-drop movement, window state transitions,
 * and exports metadata formatted for Roblox Studio ScreenGui import.
 */

const WindowManager = {
  highestZIndex: 100,
  windows: new Map(),

  init() {
    const windowEls = document.querySelectorAll('.window');
    windowEls.forEach(win => {
      const id = win.dataset.windowId || win.id.replace('window-', '');
      this.windows.set(id, {
        id,
        element: win,
        title: win.querySelector('.window-title-text')?.textContent || id,
        visible: !win.classList.contains('hidden'),
        maximized: win.classList.contains('maximized')
      });
    });
  },

  /**
   * Helper to convert computed CSS hex or RGB color strings to clean Hex (#RRGGBB).
   */
  rgbToHex(col) {
    if (!col) return '#c0c0c0';
    if (col.startsWith('#')) return col;
    const matches = col.match(/\d+/g);
    if (!matches || matches.length < 3) return '#c0c0c0';
    const r = parseInt(matches[0]).toString(16).padStart(2, '0');
    const g = parseInt(matches[1]).toString(16).padStart(2, '0');
    const b = parseInt(matches[2]).toString(16).padStart(2, '0');
    return `#${r}${g}${b}`;
  },

  /**
   * Reads CSS custom variables from document styles.
   */
  getCssVariables() {
    const rootStyle = getComputedStyle(document.documentElement);
    return {
      bgBackgroundColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-bg').trim() || '#c0c0c0'),
      titleBarActiveColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-title-bg').trim() || '#008080'),
      titleBarInactiveColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-title-inactive').trim() || '#808080'),
      titleTextColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-title-text').trim() || '#ffffff'),
      borderLightColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-border-light').trim() || '#ffffff'),
      borderDarkColor: this.rgbToHex(rootStyle.getPropertyValue('--win95-border-dark').trim() || '#404040'),
      zundaGreenAccent: this.rgbToHex(rootStyle.getPropertyValue('--zunda-green').trim() || '#2e7d32')
    };
  },

  /**
   * Exposes window layout and metadata for Roblox Studio ScreenGui import.
   * Maps window positions, sizes, titlebar properties, and CSS variables directly to Roblox ScreenGui Frame hierarchy.
   * @returns {Object} JSON Layout Object
   */
  exportScreenGuiLayout() {
    const cssVars = this.getCssVariables();
    const windowContainer = document.getElementById('window-container');
    const windowElements = Array.from(document.querySelectorAll('.window'));

    const exportedWindows = windowElements.map(win => {
      const winId = win.dataset.windowId || win.id.replace('window-', '');
      const titleText = win.querySelector('.window-title-text')?.textContent.trim() || winId;
      const isVisible = !win.classList.contains('hidden');
      
      const computed = getComputedStyle(win);
      const left = parseFloat(win.style.left || computed.left || '0');
      const top = parseFloat(win.style.top || computed.top || '0');
      const width = parseFloat(win.style.width || computed.width || '600');
      const height = parseFloat(win.style.height || computed.height || '400');
      const zIndex = parseInt(win.style.zIndex || computed.zIndex || '100', 10);

      // Child Frames Mapping
      const titleBarEl = win.querySelector('.window-header') || win.querySelector('.window-titlebar');
      const menuBarEl = win.querySelector('.window-menu-bar');
      const bodyEl = win.querySelector('.window-body');

      // TitleBar Controls
      const controls = Array.from(win.querySelectorAll('.win-btn')).map(btn => ({
        name: btn.classList.contains('win-minimize') ? 'MinimizeBtn' :
              btn.classList.contains('win-maximize') ? 'MaximizeBtn' : 'CloseBtn',
        text: btn.textContent.trim(),
        action: btn.dataset.action || 'unknown'
      }));

      // Menu Bar Items
      const menuItems = menuBarEl 
        ? Array.from(menuBarEl.querySelectorAll('.menu-item')).map(item => item.textContent.trim()) 
        : [];

      return {
        id: winId,
        elementId: win.id,
        robloxName: `Window_${winId.charAt(0).toUpperCase() + winId.slice(1)}`,
        className: 'Frame',
        visible: isVisible,
        zIndex: zIndex,
        layout: {
          position: {
            scaleX: 0,
            offsetX: Math.round(left),
            scaleY: 0,
            offsetY: Math.round(top)
          },
          size: {
            scaleX: 0,
            offsetX: Math.round(width),
            scaleY: 0,
            offsetY: Math.round(height)
          },
          anchorPoint: { x: 0, y: 0 }
        },
        style: {
          backgroundColorHex: cssVars.bgBackgroundColor,
          borderStyle: 'Inset3D',
          borderWidth: 2
        },
        components: {
          titleBar: {
            robloxName: 'TitleBar',
            className: 'Frame',
            backgroundColorHex: cssVars.titleBarActiveColor,
            size: { scaleX: 1, offsetX: 0, scaleY: 0, offsetY: 24 },
            titleText: titleText,
            titleTextColorHex: cssVars.titleTextColor,
            controls: controls
          },
          menuBar: {
            visible: menuItems.length > 0,
            items: menuItems
          },
          body: {
            robloxName: 'WindowBody',
            className: 'Frame',
            backgroundColorHex: bodyEl?.classList.contains('cli-body') ? '#000000' : cssVars.bgBackgroundColor,
            textColorHex: bodyEl?.classList.contains('cli-body') ? '#33ff66' : '#000000',
            contentType: winId.toUpperCase()
          }
        }
      };
    });

    return {
      $schema: 'https://zundamon.kitchen/schemas/roblox-screengui-v1.json',
      exportedAt: new Date().toISOString(),
      screenGui: {
        name: 'ZundaOS95ScreenGui',
        resetOnSpawn: false, // Roblox Client UI Rule Compliance
        displayOrder: 10,
        themeVariables: cssVars,
        windows: exportedWindows
      }
    };
  }
};

window.WindowManager = WindowManager;
```

---

## 5. Verification Plan

1. **Volume Persistence Verification**:
   - Set volume via `ZundaAudio.setVolume(0.35)`.
   - Refresh or call `ZundaAudio.init()`. Confirm `ZundaAudio.volume` evaluates to `0.35` and `masterGain` is initialized to `0.35`.
2. **SFX Attenuation Verification**:
   - Execute `playClickSFX('invalid')` or `playClickSFX('foo_bar')`.
   - Confirm gain starts at `0.15` and ramps exponentially to `0.001` over `0.03s` without spiking to volume `1.0`.
3. **BGM Race Condition Verification**:
   - Execute `toggleCozyBGM()` twice in rapid succession (< 500ms apart).
   - Confirm `clearTimeout(ZundaAudio.bgmStopTimeout)` cancels the pending pad shutdown and background arpeggios/pads remain audible without unexpected silences.
4. **Roblox UI Export Verification**:
   - Execute `WindowManager.exportScreenGuiLayout()` in the browser console.
   - Verify returned object contains `resetOnSpawn: false`, CSS variable hex codes, and standard `UDim2` offset mappings for all floating windows.
