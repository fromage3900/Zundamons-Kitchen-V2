# Technical Specification: Web Audio Engine & SVG Asset Infrastructure
**Milestone 1 — Zunda-OS 95 CLI Launch Page & Creative Hub**
**Author**: Explorer 3 (`teamwork_preview_explorer_m1_3`)

---

## Executive Summary
This document establishes the architecture for the **Web Audio API Sound Synthesizer Engine**, **SVG Asset Infrastructure**, and **Roblox UI Export Readiness Mapping** for Zunda-OS 95 (`site/assets/`). 

Key architectural guarantees:
1. **Zero External File Dependencies**: All UI sound effects (`playClickSFX`, `playWindowSFX`, `playKeySFX`) and ambient background music (`playCozyBGM`) are procedurally generated in real time using the browser's native `AudioContext` and web audio oscillator nodes.
2. **Resolution-Independent SVG Vector Suite**: Pixel-perfect retro 90s OS vector graphics (`pea_pod.svg`, `zundamon_mochi.svg`, `crt_monitor.svg`, `disc_icon.svg`) with CSS variable tinting.
3. **Roblox UI Export Mapping Matrix**: Direct 1:1 translation rules mapping HTML DOM structure, CSS flexbox/grid, and CSS design tokens directly to Roblox Studio `ScreenGui`, `Frame`, `UIListLayout`, `UICorner`, and `UIStroke` instances.

---

## 1. Web Audio API Sound Synthesizer Architecture (`audio_engine.js`)

### 1.1 Global State & Autoplay Lifecycle Manager
Browsers enforce strict AudioContext autoplay policies requiring user interaction before unmuting audio. The `ZundaAudio` manager lazily initializes the `AudioContext` upon the first click, keypress, or drag event across the window.

```js
/**
 * ZundaAudio — Central Audio Synthesizer & State Manager
 */
const ZundaAudio = {
  ctx: null,
  masterGain: null,
  bgmGain: null,
  sfxGain: null,
  isMuted: false,
  volume: 0.7,
  bgmPlaying: false,
  bgmInterval: null,

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

  resumeOnUserGesture() {
    if (!this.ctx) this.init();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  },

  setMute(muteState) {
    this.isMuted = muteState;
    localStorage.setItem('zunda_os_muted', muteState ? 'true' : 'false');
    if (this.masterGain && this.ctx) {
      const now = this.ctx.currentTime;
      this.masterGain.gain.cancelScheduledValues(now);
      this.masterGain.gain.setTargetAtTime(this.isMuted ? 0 : this.volume, now, 0.02);
    }
  },

  toggleMute() {
    this.setMute(!this.isMuted);
    return this.isMuted;
  },

  setVolume(val) {
    this.volume = Math.max(0, Math.min(1, val));
    localStorage.setItem('zunda_os_volume', this.volume.toString());
    if (this.masterGain && this.ctx && !this.isMuted) {
      this.masterGain.gain.setValueAtTime(this.volume, this.ctx.currentTime);
    }
  }
};
```

---

### 1.2 Sound Effects Synthesizers

#### A. Retro Click SFX Generator (`playClickSFX(variant)`)
Simulates physical 90s OS button clicks, taskbar toggles, and start menu selection.

```js
/**
 * Synthesizes a crisp, mechanical UI click sound effect.
 * @param {'down' | 'up' | 'start'} variant - Click action type
 */
function playClickSFX(variant = 'down') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  osc.type = variant === 'start' ? 'triangle' : 'square';

  if (variant === 'down') {
    // Sharp high-to-low frequency sweep over 25ms
    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(150, now + 0.025);
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);
  } else if (variant === 'up') {
    // Soft upward click over 20ms
    osc.frequency.setValueAtTime(300, now);
    osc.frequency.exponentialRampToValueAtTime(800, now + 0.020);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.020);
  } else if (variant === 'start') {
    // Retro Start Menu popup chime blip (dual pitch)
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
```

---

#### B. Window Action SFX Generator (`playWindowSFX(action)`)
Provides warm retro OS audio feedback for window operations (focus, drag start, minimize, maximize, close).

```js
/**
 * Synthesizes window manipulation sound effects.
 * @param {'focus' | 'drag' | 'minimize' | 'maximize' | 'close'} action 
 */
function playWindowSFX(action = 'focus') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  if (action === 'focus') {
    // Warm 2-tone major fifth chime (E5 -> B5)
    const notes = [659.25, 987.77];
    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.04);
      gain.gain.setValueAtTime(0.18, now + idx * 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.04 + 0.09);
      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.04);
      osc.stop(now + idx * 0.04 + 0.1);
    });
  } else if (action === 'drag') {
    // Subtle low woodblock tick on drag start
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(440, now);
    osc.frequency.exponentialRampToValueAtTime(110, now + 0.015);
    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.015);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.02);
  } else if (action === 'minimize') {
    // Descending 2-tone glissando (B5 -> E5)
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(987.77, now);
    osc.frequency.exponentialRampToValueAtTime(659.25, now + 0.07);
    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.085);
  } else if (action === 'maximize') {
    // Ascending 3-tone arpeggio (E5 -> G#5 -> B5)
    [659.25, 830.61, 987.77].forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now + idx * 0.035);
      gain.gain.setValueAtTime(0.18, now + idx * 0.035);
      gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.035 + 0.07);
      osc.connect(gain);
      gain.connect(ZundaAudio.sfxGain);
      osc.start(now + idx * 0.035);
      osc.stop(now + idx * 0.035 + 0.075);
    });
  } else if (action === 'close') {
    // Quick low resonant pop
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(350, now);
    osc.frequency.exponentialRampToValueAtTime(80, now + 0.04);
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.045);
  }
}
```

---

#### C. Terminal Keypress SFX Generator (`playKeySFX(key)`)
Simulates authentic CRT monitor green-screen terminal keystrokes with randomized pitch micro-variations.

```js
/**
 * Synthesizes CRT terminal keyboard typing clicks & blips.
 * @param {string} key - Character key pressed
 */
function playKeySFX(key = '') {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx || ZundaAudio.isMuted) return;

  const ctx = ZundaAudio.ctx;
  const now = ctx.currentTime;

  const osc = ctx.createOscillator();
  const gain = ctx.createGain();

  // Enter key produces distinct lower confirmation tone
  if (key === 'Enter') {
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.exponentialRampToValueAtTime(261.63, now + 0.04);
    gain.gain.setValueAtTime(0.22, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
    osc.connect(gain);
    gain.connect(ZundaAudio.sfxGain);
    osc.start(now);
    osc.stop(now + 0.045);
    return;
  }

  // Standard keypress: micro frequency jitter (1100Hz - 1300Hz)
  const baseFreq = 1200 + (Math.random() * 200 - 100);
  osc.type = 'square';
  osc.frequency.setValueAtTime(baseFreq, now);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.3, now + 0.012);

  gain.gain.setValueAtTime(0.08, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.012);

  osc.connect(gain);
  gain.connect(ZundaAudio.sfxGain);

  osc.start(now);
  osc.stop(now + 0.015);
}
```

---

### 1.3 Cozy Ambient BGM Loop Synthesizer (`playCozyBGM()`)
A procedural ambient audio loop inspired by Zen Edamame and Infinity Nikki cozy aesthetics. Uses pentatonic notes (E Major Pentatonic: E4, F#4, G#4, B4, C#5, E5) over an ambient sine pad drone.

```js
/**
 * Starts or toggles the ambient cozy background music synthesizer.
 */
function toggleCozyBGM() {
  ZundaAudio.resumeOnUserGesture();
  if (!ZundaAudio.ctx) return false;

  if (ZundaAudio.bgmPlaying) {
    stopCozyBGM();
    return false;
  } else {
    startCozyBGM();
    return true;
  }
}

function startCozyBGM() {
  if (ZundaAudio.bgmPlaying || !ZundaAudio.ctx) return;
  ZundaAudio.bgmPlaying = true;

  const ctx = ZundaAudio.ctx;

  // E Major Pentatonic Scale frequencies (Hz)
  const scale = [329.63, 369.99, 415.30, 493.88, 554.37, 659.25, 739.99];

  // 1. Soft Low Drone Pad (E3 + B3)
  const padOsc1 = ctx.createOscillator();
  const padOsc2 = ctx.createOscillator();
  const padGain = ctx.createGain();
  const filter = ctx.createBiquadFilter();

  padOsc1.type = 'sine';
  padOsc1.frequency.setValueAtTime(164.81, ctx.currentTime); // E3

  padOsc2.type = 'triangle';
  padOsc2.frequency.setValueAtTime(246.94, ctx.currentTime); // B3

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(450, ctx.currentTime);

  padGain.gain.setValueAtTime(0.01, ctx.currentTime);
  padGain.gain.linearRampToValueAtTime(0.12, ctx.currentTime + 2.0); // 2s smooth fade in

  padOsc1.connect(filter);
  padOsc2.connect(filter);
  filter.connect(padGain);
  padGain.connect(ZundaAudio.bgmGain);

  padOsc1.start();
  padOsc2.start();

  ZundaAudio.bgmPadOscs = [padOsc1, padOsc2];
  ZundaAudio.bgmPadGain = padGain;

  // 2. Arpeggiated Melody Sequence Generator
  let step = 0;
  ZundaAudio.bgmInterval = setInterval(() => {
    if (!ZundaAudio.bgmPlaying || ZundaAudio.isMuted) return;

    const now = ctx.currentTime;
    const freq = scale[Math.floor(Math.random() * scale.length)];

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, now);

    // Kalimba / Glockenspiel envelope
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.0005, now + 0.6);

    osc.connect(gain);
    gain.connect(ZundaAudio.bgmGain);

    osc.start(now);
    osc.stop(now + 0.65);

    step++;
  }, 650); // Note interval: 650ms
}

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
```

---

## 2. SVG Asset Definitions Infrastructure (`site/assets/`)

All SVG graphics must be standalone valid SVG files in `site/assets/` AND embeddable directly as inline `<svg>` elements or `data:image/svg+xml` URIs for zero latency loading.

### 2.1 Pea Pod Icon (`site/assets/pea_pod.svg`)
Used in: Titlebars, Start Menu `[Start Zunda 🫛]`, Taskbar button, and Favicon.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="none">
  <!-- Outer Pod Shell -->
  <path d="M 4,16 C 6,6 18,4 28,6 C 26,18 16,28 4,28 C 4,24 4,20 4,16 Z" 
        fill="#4caf50" stroke="#1b5e20" stroke-width="2" stroke-linejoin="round"/>
  <!-- Pod Inner Shadow -->
  <path d="M 6,17 C 8,9 18,7 26,8 C 24,18 15,26 6,26 Z" 
        fill="#388e3c" opacity="0.4"/>
  <!-- Pea 1 (Left) -->
  <circle cx="10" cy="20" r="3.5" fill="#8bc34a" stroke="#1b5e20" stroke-width="1.5"/>
  <circle cx="9" cy="19" r="1" fill="#dce775"/>
  <!-- Pea 2 (Center) -->
  <circle cx="16" cy="15" r="4" fill="#8bc34a" stroke="#1b5e20" stroke-width="1.5"/>
  <circle cx="14.8" cy="13.8" r="1.2" fill="#dce775"/>
  <!-- Pea 3 (Right) -->
  <circle cx="22" cy="10" r="3.5" fill="#8bc34a" stroke="#1b5e20" stroke-width="1.5"/>
  <circle cx="21" cy="9" r="1" fill="#dce775"/>
  <!-- Stem Leaf -->
  <path d="M 4,16 C 2,13 1,9 3,7 C 6,7 8,10 6,14 Z" 
        fill="#2e7d32" stroke="#1b5e20" stroke-width="1.5"/>
</svg>
```

---

### 2.2 Zundamon Mochi Avatar (`site/assets/zundamon_mochi.svg`)
Used in: `VNTalk.app`, desktop hero branding header, and popup dialogues.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64" fill="none">
  <!-- Mochi Soft Body -->
  <ellipse cx="32" cy="38" rx="24" ry="18" fill="#f4f8f3" stroke="#2e7d32" stroke-width="2.5"/>
  <ellipse cx="32" cy="38" rx="22" ry="16" fill="#ffffff"/>

  <!-- Zunda Paste Hair / Ears (Left & Right Edamame Tufts) -->
  <path d="M 12,28 C 4,20 6,10 16,16 C 20,20 18,28 12,28 Z" fill="#4caf50" stroke="#1b5e20" stroke-width="2"/>
  <circle cx="11" cy="18" r="2" fill="#aed581"/>
  
  <path d="M 52,28 C 60,20 58,10 48,16 C 44,20 46,28 52,28 Z" fill="#4caf50" stroke="#1b5e20" stroke-width="2"/>
  <circle cx="53" cy="18" r="2" fill="#aed581"/>

  <!-- Center Zunda Crest -->
  <path d="M 26,22 C 32,12 38,22 32,26 Z" fill="#8bc34a" stroke="#1b5e20" stroke-width="1.5"/>

  <!-- Eyes (Kawaii Retro Anime Style) -->
  <ellipse cx="22" cy="36" rx="3" ry="4" fill="#1b5e20"/>
  <circle cx="21" cy="34.5" r="1.2" fill="#ffffff"/>
  
  <ellipse cx="42" cy="36" rx="3" ry="4" fill="#1b5e20"/>
  <circle cx="41" cy="34.5" r="1.2" fill="#ffffff"/>

  <!-- Blushing Cheeks -->
  <ellipse cx="16" cy="40" rx="3" ry="1.8" fill="#ff8a80" opacity="0.75"/>
  <ellipse cx="48" cy="40" rx="3" ry="1.8" fill="#ff8a80" opacity="0.75"/>

  <!-- Cute Mouth -->
  <path d="M 29,40 Q 32,43 35,40" stroke="#1b5e20" stroke-width="2" stroke-linecap="round" fill="none"/>

  <!-- Red Accent Ribbon -->
  <path d="M 27,52 L 32,48 L 37,52 L 32,54 Z" fill="#e53935" stroke="#b71c1c" stroke-width="1.5"/>
</svg>
```

---

### 2.3 Retro CRT Monitor Icon (`site/assets/crt_monitor.svg`)
Used in: Start Menu `ZundaCLI.exe` entry, CRT Scanlines Toggle control.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="none">
  <!-- Outer Beige Cabinet Body -->
  <rect x="3" y="4" width="26" height="20" rx="2" fill="#e0e0e0" stroke="#424242" stroke-width="2"/>
  <rect x="5" y="6" width="22" height="16" rx="1" fill="#bdbdbd"/>
  
  <!-- CRT Phosphor Screen (Retro Green Glow) -->
  <rect x="7" y="8" width="18" height="12" rx="2" fill="#051f08" stroke="#1b5e20" stroke-width="1.5"/>
  <rect x="8" y="9" width="16" height="10" rx="1" fill="#00e676" opacity="0.25"/>
  
  <!-- Terminal Prompt Symbol (>_) inside CRT -->
  <path d="M 10,12 L 13,14 L 10,16" stroke="#00e676" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <line x1="15" y1="16" x2="18" y2="16" stroke="#00e676" stroke-width="1.5"/>

  <!-- Power LED & Knobs -->
  <circle cx="24" cy="20" r="1" fill="#00e676"/>
  <line x1="20" y1="20" x2="22" y2="20" stroke="#616161" stroke-width="1"/>

  <!-- CRT Monitor Stand Base -->
  <path d="M 11,24 L 21,24 L 23,28 L 9,28 Z" fill="#9e9e9e" stroke="#424242" stroke-width="1.5"/>
</svg>
```

---

### 2.4 Retro Floppy Disc Icon (`site/assets/disc_icon.svg`)
Used in: Start Menu `Cookbook.app`, `QuickStart.txt`, Save indicator.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32" fill="none">
  <!-- Main Floppy Disk Body (Pastel Zunda Green) -->
  <path d="M 4,4 L 24,4 L 28,8 L 28,28 L 4,28 Z" fill="#4caf50" stroke="#1b5e20" stroke-width="2" stroke-linejoin="round"/>
  
  <!-- Metal Slider Guard (Top) -->
  <rect x="8" y="4" width="12" height="9" fill="#b0bec5" stroke="#37474f" stroke-width="1.5"/>
  <rect x="11" y="6" width="3" height="5" fill="#37474f"/>

  <!-- Label Area (Bottom White Sticker) -->
  <rect x="7" y="16" width="18" height="10" rx="1" fill="#f5f5f5" stroke="#1b5e20" stroke-width="1.5"/>
  
  <!-- Label Lines -->
  <line x1="10" y1="19" x2="22" y2="19" stroke="#8bc34a" stroke-width="2"/>
  <line x1="10" y1="23" x2="19" y2="23" stroke="#9e9e9e" stroke-width="1.5"/>
</svg>
```

---

## 3. Roblox UI Export Readiness Mapping Rules

To ensure that the Zunda-OS 95 web presentation layer translates seamlessly into Roblox Studio `ScreenGui` layouts for present and future game integration, all HTML/CSS components adhere to the following strict conversion mapping rules.

### 3.1 Layout & Display Translation Matrix

| HTML / CSS Property | Roblox UI Class | Key Roblox Properties / Children |
| :--- | :--- | :--- |
| `<div class="window">` | `Frame` | `Name="WindowFrame"`, `Active=true`, `Draggable=true`, `ClipsDescendants=true` |
| `display: flex; flex-direction: column;` | `UIListLayout` | `FillDirection=Enum.FillDirection.Vertical`, `SortOrder=Enum.SortOrder.LayoutOrder` |
| `display: flex; flex-direction: row;` | `UIListLayout` | `FillDirection=Enum.FillDirection.Horizontal`, `VerticalAlignment=Enum.VerticalAlignment.Center` |
| `gap: 8px;` | `UIListLayout` | `Padding=UDim.new(0, 8)` |
| `display: grid; grid-template-columns: repeat(..., 120px);` | `UIGridLayout` | `CellSize=UDim2.new(0, 120, 0, 120)`, `CellPadding=UDim2.new(0, 8, 0, 8)` |
| `border-radius: 4px;` | `UICorner` | `CornerRadius=UDim.new(0, 4)` |
| `border: 2px solid var(--zunda-border);` | `UIStroke` | `Color=Color3.fromRGB(27,94,32)`, `Thickness=2`, `ApplyStrokeMode=Enum.ApplyStrokeMode.Border` |
| `box-shadow: 2px 2px 0px #000000;` | `Frame` / `UIStroke` | Secondary offset shadow `Frame` or `UIStroke` with `LineJoinMode=Enum.LineJoinMode.Miter` |
| `padding: 12px;` | `UIPadding` | `PaddingTop=UDim.new(0,12)`, `PaddingBottom=UDim.new(0,12)`, `PaddingLeft=UDim.new(0,12)`, `PaddingRight=UDim.new(0,12)` |
| `aspect-ratio: 1 / 1;` | `UIAspectRatioConstraint` | `AspectRatio=1`, `AspectType=Enum.AspectType.FitWithinMaxSize` |

---

### 3.2 Design Token & CSS Variable Mapping Table

| CSS Variable | Value | Roblox `Color3` / Enum Equivalent | Used In Roblox Instances |
| :--- | :--- | :--- | :--- |
| `--zunda-green-main` | `#4caf50` | `Color3.fromRGB(76, 175, 80)` | Window Titlebars, Active Buttons, Taskbar |
| `--zunda-green-dark` | `#1b5e20` | `Color3.fromRGB(27, 94, 32)` | Borders, Heavy Bevels, Primary Text |
| `--zunda-green-light` | `#8bc34a` | `Color3.fromRGB(139, 195, 74)` | Highlights, Selected States, Accent Lines |
| `--zunda-green-bg` | `#e8f5e9` | `Color3.fromRGB(232, 245, 233)` | Window Backgrounds, Dialog Panels |
| `--zunda-crt-bg` | `#051f08` | `Color3.fromRGB(5, 31, 8)` | Terminal Container `BackgroundColor3` |
| `--zunda-crt-text` | `#00e676` | `Color3.fromRGB(0, 230, 118)` | Terminal Text `TextColor3` |
| `--zunda-font-retro` | `'MS Gothic', monospace` | `Enum.Font.Code` / `Enum.Font.Retro` | All retro headers and CLI prompts |
| `--zunda-font-body` | `'Comic Sans MS', sans-serif` | `Enum.Font.FredokaOne` / `Enum.Font.SourceSans` | Dialogue text, recipes, instructions |

---

### 3.3 Complete Roblox Hierarchy Translation Blueprint

Below is the standard Luau / Rojo GUI structure that corresponds directly to `site/index.html` window components:

```
ScreenGui (Name="ZundaOS95_Gui", ResetOnSpawn=false)
 ├── Frame (Name="DesktopContainer", Size=UDim2.new(1, 0, 1, -36))
 │    ├── Frame (Name="Window_ZundaCLI", Size=UDim2.new(0, 640, 0, 420), Active=true)
 │    │    ├── UICorner (CornerRadius=UDim.new(0, 4))
 │    │    ├── UIStroke (Color=Color3.fromRGB(27,94,32), Thickness=2)
 │    │    ├── Frame (Name="TitleBar", Size=UDim2.new(1, 0, 0, 28), BackgroundColor3=Color3.fromRGB(76,175,80))
 │    │    │    ├── UIListLayout (FillDirection=Horizontal, VerticalAlignment=Center)
 │    │    │    ├── ImageLabel (Name="TitleIcon", Image="rbxassetid://<pea_pod_id>", Size=UDim2.new(0, 20, 0, 20))
 │    │    │    ├── TextLabel (Name="TitleText", Text="ZundaCLI.exe", Font=Enum.Font.Retro, TextColor3=Color3.fromRGB(255,255,255))
 │    │    │    └── Frame (Name="WindowControls")
 │    │    │         ├── TextButton (Name="MinimizeBtn", Text="_")
 │    │    │         ├── TextButton (Name="MaximizeBtn", Text="□")
 │    │    │         └── TextButton (Name="CloseBtn", Text="X", BackgroundColor3=Color3.fromRGB(229,57,53))
 │    │    └── Frame (Name="WindowContent", Size=UDim2.new(1, 0, 1, -28), BackgroundColor3=Color3.fromRGB(5,31,8))
 │    │         └── ScrollingFrame (Name="TerminalScrollBuffer")
 └── Frame (Name="TaskBar", Size=UDim2.new(1, 0, 0, 36), Position=UDim2.new(0, 0, 1, -36), BackgroundColor3=Color3.fromRGB(232,245,233))
      ├── UIListLayout (FillDirection=Horizontal, VerticalAlignment=Center)
      ├── TextButton (Name="StartButton", Text="🫛 Start Zunda", Font=Enum.Font.Retro)
      ├── Frame (Name="TaskbarAppList")
      └── Frame (Name="SystemTray")
           ├── TextButton (Name="AudioToggleBtn", Text="🔊")
           └── TextLabel (Name="ClockLabel", Text="12:00 PM")
```

---

## 4. Summary & Implementation Instructions for Worker

1. **Audio Synthesis implementation (`site/assets/audio_engine.js`)**:
   - Save the synthesizers (`ZundaAudio`, `playClickSFX`, `playWindowSFX`, `playKeySFX`, `toggleCozyBGM`) in `site/assets/audio_engine.js`.
   - Ensure zero external audio file dependencies.

2. **SVG Assets creation (`site/assets/`)**:
   - Save `pea_pod.svg`, `zundamon_mochi.svg`, `crt_monitor.svg`, and `disc_icon.svg` into `site/assets/`.
   - Provide inline SVG representations or helper functions so buttons and windows can render icons instantly.

3. **Roblox Readiness Verification**:
   - Maintain naming conventions and CSS variables aligned with the Roblox UI tokens defined in Section 3.
