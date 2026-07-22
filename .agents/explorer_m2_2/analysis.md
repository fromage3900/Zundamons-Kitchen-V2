# Desktop Widgets & Window Styling Analysis & Execution Plan

**Project**: Zundamon's Kitchen V2 — Milestone 2  
**Role**: Explorer 2 (`explorer_m2_2`)  
**Target Files**: `site/style.css`, `site/index.html`, `site/window_manager.js`, `site/app.js`, `site/assets/audio_engine.js`  
**Date**: 2026-07-22  

---

## 1. Executive Summary

Milestone 2 establishes an interactive **Kawaii Y2K Infinity Nikki PC Desktop Workspace** containing 7 draggable app windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `Zundamon.app`, `Promos.app`, `Calculator.app`, `Updates.log`) and 3 desktop widgets.

This analysis details the exact CSS design specifications, HTML DOM updates, and JS engine hooks needed to implement:
1. **Glassmorphic Window Frame Styling**: Glossy Sakura Pink titlebars (`.window-header`), candy window control buttons (minimize `_`, maximize `□`, close `✕`), pastel window body frames (`.window-body`), rounded corners, and multi-layered Y2K drop shadows.
2. **Widget 1: Digital Clock & Weather Widget (`#widget-clock-weather`)**: Digital clock layout, weather condition indicator styling, and interactive micro-weather cycle engine.
3. **Widget 2: Lo-Fi Jukebox BGM Player Widget (`#widget-jukebox`)**: Jukebox layout, play/pause candy button, spinning track disc, track title display, and Web Audio rain SFX slider control.
4. **Widget 3: Zundamon Desktop Sticker Widget (`#widget-zunda-sticker`)**: Clickable companion mascot sticker, speech bubble positioning (`.sticker-bubble`) with arrow tail, and hover/click animations.

---

## 2. Component 1: Glassmorphic Window Frame Styling

### 2.1 Direct Observations & Current Gap Analysis
- **Current HTML Structure (`site/index.html`)**:
  - Standard `.window` structure contains `.window-header` with `.window-title` and `.window-controls`.
  - Control buttons use symbols `_`, `🗖`, `✕`. Noticeable inconsistency in maximize icon (`🗖` vs standard `□`).
- **Current CSS (`site/style.css`)**:
  - `.window` currently has solid white background (`#ffffff`) and standard border (`2px solid var(--sakura-hot)`).
  - `.window-header` uses horizontal gradient (`linear-gradient(90deg, var(--sakura-hot), var(--zunda-base))`).
  - `.win-btn` buttons are basic white translucent circles (`rgba(255, 255, 255, 0.25)`) without distinct candy coloring for minimize, maximize, and close.

### 2.2 Execution Blueprint & CSS Specification

#### A. Glossy Sakura Pink Titlebars (`.window-header`)
```css
/* Glossy Sakura Pink Window Header */
.window-header {
  background: linear-gradient(180deg, var(--sakura-vibrant) 0%, var(--sakura-hot) 100%);
  color: #ffffff;
  padding: 10px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: move;
  user-select: none;
  border-bottom: 2px solid rgba(255, 255, 255, 0.4);
  box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.7), inset 0 -2px 4px rgba(0, 0, 0, 0.15);
  position: relative;
  overflow: hidden;
}

/* Header Sheen Highlight */
.window-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 50%;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.4) 0%, rgba(255, 255, 255, 0.05) 100%);
  pointer-events: none;
}

/* Inactive Window Header State */
.window.inactive-window .window-header,
.window.window-inactive .window-header {
  background: linear-gradient(180deg, #ffc1cc 0%, #ffa4b6 100%);
  opacity: 0.85;
}
```

#### B. Candy Window Control Buttons (`.win-btn`)
```css
/* Candy Control Buttons */
.window-controls {
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 2;
}

.win-btn {
  border: 1px solid rgba(255, 255, 255, 0.8);
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 900;
  color: #ffffff;
  cursor: pointer;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.9), 0 2px 6px rgba(0, 0, 0, 0.2);
  transition: transform var(--transition-bounce), filter var(--transition-fast);
  outline: none;
}

/* Candy Button Color Variants */
.win-minimize {
  background: linear-gradient(180deg, #a5d6a7 0%, #4caf50 100%) !important; /* Edamame Mint Candy */
}

.win-maximize {
  background: linear-gradient(180deg, #ffe082 0%, #ffb300 100%) !important; /* Citrus Yellow Candy */
}

.win-close {
  background: linear-gradient(180deg, #ff85a1 0%, #ef4444 100%) !important; /* Hot Sakura Candy */
}

.win-btn:hover {
  transform: scale(1.18);
  filter: brightness(1.15);
}

.win-btn:active {
  transform: scale(0.92);
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.4);
}
```

#### C. Glassmorphic Window Frame & Pastel Body (`.window-body`)
```css
/* Glassmorphic Window Frame */
.window {
  position: absolute;
  pointer-events: auto;
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: var(--glass-backdrop-filter);
  -webkit-backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--sakura-base);
  border-radius: 20px;
  box-shadow: 0 16px 48px rgba(91, 33, 182, 0.2), 0 4px 16px rgba(255, 133, 161, 0.25);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
}

/* Focused Active Window Ring */
.window.active-window, .window.window-active {
  border-color: var(--sakura-hot);
  box-shadow: 0 20px 56px rgba(255, 71, 126, 0.35), 0 0 0 3px rgba(255, 183, 197, 0.5);
}

/* Pastel Window Body */
.window-body {
  padding: 18px;
  overflow-y: auto;
  flex: 1;
  background: linear-gradient(180deg, rgba(255, 245, 248, 0.95) 0%, rgba(255, 255, 255, 0.98) 100%);
  border-radius: 0 0 18px 18px;
}

/* Custom Pastel Scrollbar for Window Body */
.window-body::-webkit-scrollbar {
  width: 8px;
}
.window-body::-webkit-scrollbar-track {
  background: var(--sakura-light);
  border-radius: 9999px;
}
.window-body::-webkit-scrollbar-thumb {
  background: var(--sakura-base);
  border-radius: 9999px;
}
.window-body::-webkit-scrollbar-thumb:hover {
  background: var(--sakura-hot);
}
```

---

## 3. Component 2: Widget 1 — Digital Clock & Weather Widget (`#widget-clock-weather`)

### 3.1 Direct Observations & Code Audit Findings
- **DOM Container**: `#widget-clock-weather` inside `.desktop-widgets-bar`.
- **Bug Alert**: `app.js` line 1392 looks for `document.getElementById('widget-clock')`, whereas `index.html` line 286 defines `<span id="widget-digital-time">`.
- **Target Enhancement**: Integrate live digital clock and clickable weather condition indicator with simulated micro-weather forecast cycling.

### 3.2 Detailed Execution Blueprint

#### HTML Structure (`index.html`)
```html
<!-- Widget 1: Digital Clock & Weather Widget -->
<div id="widget-clock-weather" class="desktop-widget clock-weather-widget" title="Click weather to cycle forecast nanoda!">
  <div class="clock-display-pill">
    <span class="clock-icon">⏰</span>
    <span id="widget-digital-time" class="widget-time">12:00:00 PM</span>
  </div>
  <div class="weather-display-pill" id="widget-weather-pill">
    <span id="widget-weather-icon" class="weather-icon">🌤️</span>
    <span id="widget-weather-text" class="widget-weather">Zunda Village: 22°C Clear</span>
  </div>
</div>
```

#### CSS Styling (`style.css`)
```css
/* Digital Clock & Weather Widget */
.clock-weather-widget {
  background: rgba(255, 255, 255, 0.94);
  backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--sakura-base);
  border-radius: 9999px;
  padding: 6px 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 4px 14px rgba(255, 183, 197, 0.25);
  transition: var(--transition-bounce);
}

.clock-weather-widget:hover {
  border-color: var(--sakura-hot);
  transform: translateY(-2px);
}

.clock-display-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 15px;
  font-weight: 800;
  color: var(--zunda-deep);
  background: var(--zunda-light);
  padding: 3px 10px;
  border-radius: 9999px;
  border: 1px solid var(--zunda-soft);
  text-shadow: 0 0 6px rgba(76, 175, 80, 0.3);
}

.weather-display-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 700;
  color: #334155;
  cursor: pointer;
  user-select: none;
  padding: 3px 8px;
  border-radius: 9999px;
  transition: background var(--transition-fast);
}

.weather-display-pill:hover {
  background: var(--sakura-soft);
  color: var(--sakura-hot);
}

.weather-icon {
  font-size: 16px;
  display: inline-block;
  animation: float-emoji 3s ease-in-out infinite;
}
```

#### JS Logic Integration (`app.js`)
```javascript
initClockAndWeatherWidget() {
  const timeEl = document.getElementById('widget-digital-time');
  const weatherPill = document.getElementById('widget-weather-pill');
  const weatherIcon = document.getElementById('widget-weather-icon');
  const weatherText = document.getElementById('widget-weather-text');

  // 1. Live Digital Clock Update
  const updateClock = () => {
    if (timeEl) {
      const now = new Date();
      timeEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    }
  };
  setInterval(updateClock, 1000);
  updateClock();

  // 2. Interactive Weather Forecast Cycle
  const weatherStates = [
    { icon: '🌤️', text: 'Zunda Village: 22°C Clear' },
    { icon: '🌸', text: 'Sakura Forest: 20°C Blossom Breeze' },
    { icon: '🌧️', text: 'Edamame Fields: 18°C Cozy Rain' },
    { icon: '🌙', text: 'Starry Heights: 16°C Clear Night' }
  ];
  let weatherIdx = 0;

  if (weatherPill) {
    weatherPill.addEventListener('click', () => {
      if (typeof playClick === 'function') playClick('down');
      weatherIdx = (weatherIdx + 1) % weatherStates.length;
      const state = weatherStates[weatherIdx];
      if (weatherIcon) weatherIcon.textContent = state.icon;
      if (weatherText) weatherText.textContent = state.text;
    });
  }
}
```

---

## 4. Component 3: Widget 2 — Lo-Fi Jukebox BGM Player Widget (`#widget-jukebox`)

### 4.1 Direct Observations & Gaps
- **Current HTML**: Has title `"Zunda Lo-Fi Beats"` and single play button `#widget-play-bgm`.
- **Target Expansion**: Add rain SFX slider control (`#rain-sfx-slider`), next track selector (`#widget-next-track`), spinning audio disc indicator when active, and procedural rain synthesizer control in `audio_engine.js`.

### 4.2 Detailed Execution Blueprint

#### HTML Structure (`index.html`)
```html
<!-- Widget 2: Lo-Fi Jukebox & Rain FX Widget -->
<div id="widget-jukebox" class="desktop-widget jukebox-widget">
  <div class="jukebox-track-info">
    <span id="jukebox-disc-icon" class="jukebox-icon">🎵</span>
    <span id="jukebox-track-title" class="jukebox-title">Zunda Lo-Fi Beats</span>
  </div>
  <div class="jukebox-controls">
    <button id="widget-play-bgm" class="btn-candy jukebox-btn" title="Play / Pause Cozy BGM">▶ BGM</button>
    <button id="widget-next-track" class="btn-candy jukebox-btn mini-btn" title="Next Track">⏭</button>
  </div>
  <div class="rain-sfx-container" title="Rain Ambience SFX Volume">
    <span class="rain-icon">🌧️</span>
    <input type="range" id="rain-sfx-slider" min="0" max="100" value="40" class="rain-slider">
  </div>
</div>
```

#### CSS Styling (`style.css`)
```css
/* Lo-Fi Jukebox Widget */
.jukebox-widget {
  background: rgba(255, 255, 255, 0.94);
  backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--sakura-base);
  border-radius: 9999px;
  padding: 6px 14px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 4px 14px rgba(255, 183, 197, 0.25);
}

.jukebox-track-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 800;
  font-size: 12px;
  color: var(--zunda-deep);
}

.jukebox-icon {
  font-size: 16px;
  display: inline-block;
  transition: transform var(--transition-bounce);
}

.jukebox-icon.spinning {
  animation: spin-disc 4s linear infinite;
}

@keyframes spin-disc {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.jukebox-controls {
  display: flex;
  gap: 6px;
}

.jukebox-btn {
  padding: 5px 12px !important;
  font-size: 11px !important;
}

.jukebox-btn.mini-btn {
  padding: 5px 8px !important;
}

/* Rain SFX Slider Control */
.rain-sfx-container {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(232, 223, 245, 0.6);
  padding: 3px 10px;
  border-radius: 9999px;
  border: 1px solid var(--lavender-pearl);
}

.rain-icon {
  font-size: 14px;
}

.rain-slider {
  -webkit-appearance: none;
  appearance: none;
  width: 60px;
  height: 6px;
  background: var(--sakura-soft);
  border-radius: 9999px;
  outline: none;
  cursor: pointer;
}

.rain-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--zunda-base);
  border: 1px solid #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: transform var(--transition-fast);
}

.rain-slider::-webkit-slider-thumb:hover {
  transform: scale(1.2);
  background: var(--sakura-hot);
}
```

#### Audio Synthesizer Rain Generator (`site/assets/audio_engine.js`)
```javascript
// Rain Ambient Noise Synthesizer Node
ZundaAudio.rainGain = null;
ZundaAudio.rainNode = null;

ZundaAudio.initRainSynthesizer = function() {
  if (!this.ctx) this.init();
  if (this.rainNode) return;

  const bufferSize = 2 * this.ctx.sampleRate;
  const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
  const output = noiseBuffer.getChannelData(0);

  // Generate Pink/Brownian Rain Noise
  let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
  for (let i = 0; i < bufferSize; i++) {
    const white = Math.random() * 2 - 1;
    b0 = 0.99886 * b0 + white * 0.0555179;
    b1 = 0.99332 * b1 + white * 0.0750759;
    b2 = 0.96900 * b2 + white * 0.1538520;
    b3 = 0.86650 * b3 + white * 0.3104856;
    b4 = 0.55000 * b4 + white * 0.5329522;
    b5 = -0.7616 * b5 - white * 0.0168980;
    output[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
    output[i] *= 0.05;
    b6 = white * 0.115926;
  }

  const whiteNoise = this.ctx.createBufferSource();
  whiteNoise.buffer = noiseBuffer;
  whiteNoise.loop = true;

  // Bandpass Filter for gentle rain effect
  const filter = this.ctx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(1000, this.ctx.currentTime);

  this.rainGain = this.ctx.createGain();
  this.rainGain.gain.setValueAtTime(0.04, this.ctx.currentTime);

  whiteNoise.connect(filter);
  filter.connect(this.rainGain);
  this.rainGain.connect(this.masterGain);

  whiteNoise.start();
  this.rainNode = whiteNoise;
};

ZundaAudio.setRainVolume = function(val) {
  if (!this.rainNode) this.initRainSynthesizer();
  if (this.rainGain && this.ctx) {
    const volume = Math.max(0, Math.min(1, val / 100)) * 0.15;
    this.rainGain.gain.setValueAtTime(volume, this.ctx.currentTime);
  }
};
```

---

## 5. Component 4: Widget 3 — Zundamon Desktop Sticker Widget (`#widget-zunda-sticker`)

### 5.1 Direct Observations & Gaps
- **Current HTML**: `<div id="widget-zunda-sticker" class="desktop-widget zunda-sticker">` with `<div id="widget-speech-bubble" class="sticker-bubble">`.
- **Bug Alert**: `app.js` line 1403 queries `document.getElementById('zunda-sticker-widget')`, mismatching the HTML ID `#widget-zunda-sticker`.
- **Target Enhancement**: Implement interactive mascot companion, positioning speech bubble above/beside mascot with speech tail arrow, hover scale/bounce, and vocal chirp voice lines on click.

### 5.2 Detailed Execution Blueprint

#### HTML Structure (`index.html`)
```html
<!-- Widget 3: Zundamon Desktop Sticker Widget -->
<div id="widget-zunda-sticker" class="desktop-widget zunda-sticker-widget" title="Click Zundamon nanoda!">
  <div class="sticker-mascot-box">
    <span class="sticker-emoji">🫛</span>
    <span class="sticker-sparkle">✨</span>
  </div>
  <div id="widget-speech-bubble" class="sticker-bubble">Nanoda! ✨</div>
</div>
```

#### CSS Styling & Speech Bubble Positioning (`style.css`)
```css
/* Zundamon Desktop Sticker Widget */
.zunda-sticker-widget {
  position: relative;
  background: rgba(255, 255, 255, 0.94);
  backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--zunda-base);
  border-radius: 9999px;
  padding: 6px 16px;
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(76, 175, 80, 0.25);
  transition: transform var(--transition-bounce), border-color var(--transition-fast);
  animation: sticker-idle-float 3s ease-in-out infinite;
}

@keyframes sticker-idle-float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  50% { transform: translateY(-4px) rotate(2deg); }
}

.zunda-sticker-widget:hover {
  transform: scale(1.1) rotate(-3deg);
  border-color: var(--sakura-hot);
  box-shadow: 0 8px 24px rgba(255, 71, 126, 0.35);
}

.zunda-sticker-widget:active {
  animation: sticker-pop 0.3s ease;
}

@keyframes sticker-pop {
  0% { transform: scale(1); }
  40% { transform: scale(0.85); }
  70% { transform: scale(1.25); }
  100% { transform: scale(1.1); }
}

.sticker-mascot-box {
  display: flex;
  align-items: center;
  gap: 4px;
}

.sticker-emoji {
  font-size: 22px;
}

.sticker-sparkle {
  font-size: 12px;
  animation: float-emoji 2s ease-in-out infinite;
}

/* Speech Bubble Positioning & Arrow Tail */
.sticker-bubble {
  position: absolute;
  bottom: calc(100% + 10px);
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(180deg, var(--sakura-hot) 0%, #e11d48 100%);
  color: #ffffff;
  padding: 6px 14px;
  border-radius: 14px;
  font-size: 12px;
  font-weight: 800;
  white-space: nowrap;
  box-shadow: 0 6px 20px rgba(255, 71, 126, 0.4);
  pointer-events: none;
  z-index: 10;
  transition: opacity 0.3s ease, transform 0.3s ease;
}

/* Bubble Arrow Tail */
.sticker-bubble::after {
  content: '';
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border-width: 6px 6px 0 6px;
  border-style: solid;
  border-color: #e11d48 transparent transparent transparent;
}
```

#### JS Logic Integration (`app.js`)
```javascript
initZundaStickerWidget() {
  const stickerWidget = document.getElementById('widget-zunda-sticker');
  const bubbleTalk = document.getElementById('widget-speech-bubble');

  if (stickerWidget) {
    const quotes = [
      '"Welcome to Zunda-OS 95, nanoda! 🫛✨"',
      '"Have you cooked fresh Zunda Mochi today, nanoda? 🍡"',
      '"Tap ZundaCLI.exe to type commands, nanoda! 💻"',
      '"Sakura petals drift through the kitchen! 🌸"',
      '"Zundamon loves warm mochi draped in edamame paste! 💚"',
      '"Master rhythm targets for S-Rank rewards, nanoda! 🍳"'
    ];
    let quoteIdx = 0;
    let autoHideTimer = null;

    stickerWidget.addEventListener('click', () => {
      if (typeof playClick === 'function') playClick('down');
      if (typeof playZundaVoiceLine === 'function') playZundaVoiceLine('nanoda_arpeggio');

      quoteIdx = (quoteIdx + 1) % quotes.length;
      if (bubbleTalk) {
        bubbleTalk.textContent = quotes[quoteIdx];
        bubbleTalk.style.opacity = '1';
        bubbleTalk.style.transform = 'translateX(-50%) translateY(0)';

        if (autoHideTimer) clearTimeout(autoHideTimer);
        autoHideTimer = setTimeout(() => {
          bubbleTalk.style.opacity = '0.9';
        }, 5000);
      }
    });
  }
}
```

---

## 6. Code Audit & ID Alignment Matrix

| Feature | Target Element | Current HTML ID | Current JS Selector | Action Required |
|---|---|---|---|---|
| Window Controls | Control buttons | `.win-btn` | `.win-btn` | Update maximize button icon to `□`, add `.win-minimize`, `.win-maximize`, `.win-close` gradient CSS |
| Widget 1 | Digital Clock | `#widget-digital-time` | `#widget-clock` (mismatch) | Update JS in `app.js` to target `#widget-digital-time` |
| Widget 1 | Weather Indicator | `#widget-clock-weather` | Static text string | Add `#widget-weather-pill` click event to cycle micro-weather |
| Widget 2 | Jukebox BGM | `#widget-jukebox` | `#widget-play-bgm` | Add `#rain-sfx-slider` control, `#widget-next-track`, and rain synthesizer in `audio_engine.js` |
| Widget 3 | Zundamon Sticker | `#widget-zunda-sticker` | `#zunda-sticker-widget` (mismatch) | Align JS target ID in `app.js` to `#widget-zunda-sticker`, style speech bubble tail |

---

## 7. Handoff Implementation Roadmap for Worker

1. **Step 1 (`site/style.css`)**:
   - Update `.window`, `.window-header`, `.win-btn`, `.win-minimize`, `.win-maximize`, `.win-close`, `.window-body` with Glassmorphic Y2K styles.
   - Add Widget CSS for `.clock-weather-widget`, `.jukebox-widget`, `.rain-sfx-container`, and `.zunda-sticker-widget` + `.sticker-bubble::after`.
2. **Step 2 (`site/index.html`)**:
   - Update window control button symbols to standardize maximize `□`.
   - Update Widget 1, 2, and 3 HTML markup to match the enhanced DOM structures.
3. **Step 3 (`site/assets/audio_engine.js`)**:
   - Implement `ZundaAudio.initRainSynthesizer()` and `ZundaAudio.setRainVolume(val)`.
4. **Step 4 (`site/app.js`)**:
   - Refactor `initDesktopWidgets()` to fix element ID mismatches (`#widget-digital-time`, `#widget-zunda-sticker`).
   - Wire up rain slider event listener and micro-weather click cycle.
5. **Step 5 (`site/sync_site.js`)**:
   - Execute node sync script to mirror `site/` -> `docs/`.
