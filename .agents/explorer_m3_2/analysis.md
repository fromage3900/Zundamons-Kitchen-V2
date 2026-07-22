# ZundaCLI.exe Styling, Layout & Formatting Specification Analysis

## Executive Summary
This document delivers the complete visual layout, styling, CRT phosphor themes, rich text formatting, auto-scroll management, and mobile touch architecture for `ZundaCLI.exe` (Milestone 3).

`ZundaCLI.exe` serves as the interactive retro console for **Zunda-OS 95**. This analysis establishes a zero-dependency, highly responsive CSS/HTML/JS framework that integrates monochrome CRT aesthetics, dynamic phosphor themes (`classic-green`, `amber`, `matrix`, `cozy-pea`), phosphor glow/flicker animations, structured tag/table/ASCII output formatters, smart non-intrusive auto-scrolling, and mobile touch input management.

---

## 1. Retro CRT Phosphor Green Monochrome Theme Styling

### 1.1 Color Token Architecture
The primary styling relies on high-contrast, glowing CRT phosphor aesthetics against dark obsidian backgrounds.

```css
/* Core Phosphor CSS Variables */
:root {
  --term-bg: #0a1a0a;            /* Dark obsidian phosphor background */
  --term-green: #33ff33;         /* Vibrant CRT phosphor green primary */
  --term-green-dim: #00aa44;     /* Secondary dimmed phosphor text */
  --term-glow-color: rgba(51, 255, 51, 0.7); /* Inner phosphor glow */
  --term-glow-far: rgba(0, 255, 102, 0.3);   /* Outer ambient diffuse glow */
  --term-highlight: #66ff66;     /* Command & emphasis highlight */
  --term-cursor: #33ff33;        /* Blinking block cursor color */
  --term-selection-bg: rgba(51, 255, 102, 0.3); /* Selection highlight background */
  --term-selection-text: #ffffff;/* Selection text color */
}
```

### 1.2 Multi-Tier Phosphor Glow & Selection
Standard single `text-shadow` can appear flat. The enhanced multi-tier bloom creates an authentic glowing CRT phosphor tube effect:

```css
.cli-body {
  background-color: var(--term-bg);
  color: var(--term-green);
  font-family: 'VT323', 'Courier New', Consolas, monospace;
  font-size: 15px;
  padding: 8px;
  position: relative;
  box-shadow: inset 0 0 18px rgba(0, 0, 0, 0.85), inset 0 0 4px var(--term-green-dim);
  border: 1px solid rgba(51, 255, 102, 0.2);
}

.cli-terminal-log {
  flex: 1;
  overflow-y: auto;
  padding: 6px;
  line-height: 1.4;
  text-shadow: 0 0 2px var(--term-green), 0 0 6px var(--term-glow-color), 0 0 12px var(--term-glow-far);
}

.cli-body ::selection {
  background-color: var(--term-selection-bg);
  color: var(--term-selection-text);
  text-shadow: 0 0 8px var(--term-green);
}
```

### 1.3 Retro Phosphor Webkit Scrollbar
Default browser scrollbars break retro terminal immersion. Custom styling ensures seamless visual integration:

```css
.cli-terminal-log::-webkit-scrollbar {
  width: 8px;
}
.cli-terminal-log::-webkit-scrollbar-track {
  background: var(--term-bg);
  border-left: 1px solid var(--term-green-dim);
}
.cli-terminal-log::-webkit-scrollbar-thumb {
  background: var(--term-green-dim);
  border-radius: 0px;
  box-shadow: 0 0 4px var(--term-green);
}
.cli-terminal-log::-webkit-scrollbar-thumb:hover {
  background: var(--term-green);
}
```

---

## 2. CRT Scanline Overlay, Flicker/Glow Effects, & Customizable Themes

### 2.1 Customizable CRT Themes Specification
Four distinct retro CRT color schemes are supported via `data-term-theme` attributes on `.cli-body` or `#window-zundacli`:

| Theme Name | Description | `--term-bg` | `--term-green` | `--term-green-dim` | `--term-glow-color` |
|------------|-------------|-------------|----------------|--------------------|---------------------|
| `classic-green` | Classic VT220 Phosphor Green | `#0a1a0a` | `#33ff33` | `#00aa44` | `rgba(51,255,51,0.7)` |
| `amber` | Retro VT100 Amber Terminal | `#140a00` | `#ffb000` | `#b37b00` | `rgba(255,176,0,0.7)` |
| `matrix` | Digital Rain Cyber Green | `#020d04` | `#00ff66` | `#008833` | `rgba(0,255,102,0.85)` |
| `cozy-pea` | Zunda Mochi Pastel Pea | `#0f1f10` | `#a3e048` | `#5c9422` | `rgba(163,224,72,0.6)` |

#### Theme CSS Mapping
```css
/* Theme 1: Classic Green (Default) */
.cli-body[data-term-theme="classic-green"] {
  --term-bg: #0a1a0a;
  --term-green: #33ff33;
  --term-green-dim: #00aa44;
  --term-glow-color: rgba(51, 255, 51, 0.7);
  --term-glow-far: rgba(0, 255, 102, 0.3);
  --term-highlight: #66ff66;
  --term-cursor: #33ff33;
}

/* Theme 2: Amber VT100 */
.cli-body[data-term-theme="amber"] {
  --term-bg: #140a00;
  --term-green: #ffb000;
  --term-green-dim: #b37b00;
  --term-glow-color: rgba(255, 176, 0, 0.7);
  --term-glow-far: rgba(255, 140, 0, 0.3);
  --term-highlight: #ffd166;
  --term-cursor: #ffb000;
}

/* Theme 3: Matrix Cyber Green */
.cli-body[data-term-theme="matrix"] {
  --term-bg: #020d04;
  --term-green: #00ff66;
  --term-green-dim: #008833;
  --term-glow-color: rgba(0, 255, 102, 0.85);
  --term-glow-far: rgba(0, 200, 80, 0.4);
  --term-highlight: #80ffb3;
  --term-cursor: #00ff66;
}

/* Theme 4: Cozy Pea Pastel Green */
.cli-body[data-term-theme="cozy-pea"] {
  --term-bg: #0f1f10;
  --term-green: #a3e048;
  --term-green-dim: #5c9422;
  --term-glow-color: rgba(163, 224, 72, 0.6);
  --term-glow-far: rgba(139, 195, 74, 0.35);
  --term-highlight: #c5f084;
  --term-cursor: #a3e048;
}
```

### 2.2 Window-Specific Scanline Overlay & Animations
```css
/* CRT In-Window Scanline Grid Overlay */
.cli-scanline-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  pointer-events: none;
  background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.3) 50%);
  background-size: 100% 4px;
  z-index: 2;
  opacity: 0.65;
}

/* Micro CRT Phosphor Flicker */
@keyframes crtPhosphorFlicker {
  0% { opacity: 0.99; }
  20% { opacity: 0.96; }
  40% { opacity: 0.99; }
  60% { opacity: 0.95; }
  80% { opacity: 1.0; }
  100% { opacity: 0.98; }
}

.cli-flicker {
  animation: crtPhosphorFlicker 0.18s infinite;
}

/* CRT Cold Boot Expansion Animation */
@keyframes crtPowerOn {
  0% { transform: scaleY(0.005) scaleX(0.2); filter: brightness(4); }
  50% { transform: scaleY(0.08) scaleX(1); filter: brightness(2); }
  100% { transform: scaleY(1) scaleX(1); filter: brightness(1); }
}

.cli-booting {
  animation: crtPowerOn 0.32s cubic-bezier(0.23, 1, 0.32, 1) forwards;
}
```

---

## 3. Rich Output Formatting Helpers

### 3.1 Colored Status Tag Framework
Rich status tags standardize CLI output headers across commands.

| Tag Name | Output Format | CSS Class | Color Palette |
|----------|---------------|-----------|---------------|
| `[OK]` | `[OK]` | `.cli-tag-ok` | Emerald Green (`#33ff33` on translucent bg) |
| `[RECIPE]` | `[RECIPE]` | `.cli-tag-recipe` | Zunda Sprout (`#8bc34a` on translucent bg) |
| `[AUDIO]` | `[AUDIO]` | `.cli-tag-audio` | Cyan Synth (`#00e5ff` on translucent bg) |
| `[INFO]` | `[INFO]` | `.cli-tag-info` | Cobalt Info (`#3399ff` on translucent bg) |
| `[WARN]` | `[WARN]` | `.cli-tag-warn` | Amber Warning (`#ffaa00` on translucent bg) |
| `[ERROR]` | `[ERROR]` | `.cli-tag-err` | Crimson Error (`#ff4444` on translucent bg) |
| `[SYSTEM]` | `[SYSTEM]` | `.cli-tag-system` | Lime System (`#a8e063` on translucent bg) |

#### Tag CSS Styling
```css
.cli-tag {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: bold;
  padding: 1px 5px;
  border-radius: 2px;
  margin-right: 6px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.cli-tag-ok     { background: rgba(51, 255, 102, 0.15); color: #33ff33; border: 1px solid #33ff33; }
.cli-tag-recipe { background: rgba(139, 195, 74, 0.15); color: #8bc34a; border: 1px solid #8bc34a; }
.cli-tag-audio  { background: rgba(0, 229, 255, 0.15); color: #00e5ff; border: 1px solid #00e5ff; }
.cli-tag-info   { background: rgba(51, 153, 255, 0.15); color: #3399ff; border: 1px solid #3399ff; }
.cli-tag-warn   { background: rgba(255, 170, 0, 0.15); color: #ffaa00; border: 1px solid #ffaa00; }
.cli-tag-err    { background: rgba(255, 68, 68, 0.15); color: #ff4444; border: 1px solid #ff4444; }
.cli-tag-system { background: rgba(168, 224, 99, 0.15); color: #a8e063; border: 1px solid #a8e063; }
```

### 3.2 ASCII Banner Renderer
To avoid text alignment corruption in proportional fallbacks, ASCII banners use clean monospace pre-formatted elements:

```html
<pre class="cli-ascii-banner">
███████╗██╗   ██╗███╗   ██╗██████╗  █████╗ 
╚══███╔╝██║   ██║████╗  ██║██╔══██╗██╔══██╗
  ███╔╝ ██║   ██║██╔██╗ ██║██║  ██║███████║
 ███╔╝  ██║   ██║██║╚██╗██║██║  ██║██╔══██║
███████╗╚██████╔╝██║ ╚████║██████╔╝██║  ██║
╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝
         [Zunda-OS 95 Kernel 4.09.1995]
</pre>
```

```css
.cli-ascii-banner {
  font-family: var(--font-mono);
  font-size: 11px;
  line-height: 1.15;
  color: var(--term-green);
  text-shadow: 0 0 6px var(--term-glow-color);
  white-space: pre;
  margin: 6px 0;
  overflow-x: auto;
}
```

### 3.3 Retro Table Layout Helper
CSS Flexbox provides clean responsive tabular layouts for command outputs like `recipes`, `gather`, and `status`:

```html
<div class="cli-table">
  <div class="cli-table-row cli-table-head">
    <span class="cli-col col-code">CODE</span>
    <span class="cli-col col-name">RECIPE NAME</span>
    <span class="cli-col col-type">CATEGORY</span>
    <span class="cli-col col-diff">DIFFICULTY</span>
  </div>
  <div class="cli-table-row">
    <span class="cli-col col-code">R-01</span>
    <span class="cli-col col-name">Zunda Mochi</span>
    <span class="cli-col col-type">Classic</span>
    <span class="cli-col col-diff">★☆☆☆☆</span>
  </div>
</div>
```

```css
.cli-table {
  margin: 6px 0;
  border: 1px dashed var(--term-green-dim);
  padding: 4px 8px;
  background: rgba(0, 0, 0, 0.2);
}
.cli-table-head {
  border-bottom: 1px solid var(--term-green-dim);
  font-weight: bold;
  color: var(--term-highlight);
}
.cli-table-row {
  display: flex;
  justify-content: space-between;
  padding: 2px 0;
}
.cli-col {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

---

## 4. Auto-Scroll Mechanics & Smart User-Scroll Detection

### 4.1 Non-Intrusive Auto-Scroll Logic
Automatically scrolling to the bottom on every output line can interrupt users who are reading earlier scrollback history. `ZundaCLI.exe` implements smart user scroll detection:

```javascript
class TerminalScrollManager {
  constructor(outputElement) {
    this.output = outputElement;
    this.userScrolledUp = false;
    this.scrollThreshold = 35; // px from bottom

    this.output.addEventListener('scroll', () => this.handleScroll());
  }

  handleScroll() {
    const distanceToBottom = this.output.scrollHeight - this.output.scrollTop - this.output.clientHeight;
    this.userScrolledUp = distanceToBottom > this.scrollThreshold;
    this.toggleResumePill(!this.userScrolledUp);
  }

  scrollToBottom(force = false) {
    if (!this.userScrolledUp || force) {
      this.output.scrollTop = this.output.scrollHeight;
      this.userScrolledUp = false;
      this.toggleResumePill(true);
    }
  }

  toggleResumePill(isAtBottom) {
    const pill = document.getElementById('cli-scroll-bottom-btn');
    if (pill) {
      if (isAtBottom) {
        pill.classList.add('hidden');
      } else {
        pill.classList.remove('hidden');
      }
    }
  }
}
```

### 4.2 Resume Scroll Pill UI
```html
<button id="cli-scroll-bottom-btn" class="cli-scroll-bottom-btn hidden" title="Scroll to Bottom">
  ↓ New Output Below
</button>
```

```css
.cli-scroll-bottom-btn {
  position: absolute;
  bottom: 45px;
  right: 15px;
  background: var(--term-bg);
  color: var(--term-green);
  border: 1px solid var(--term-green);
  font-family: var(--font-mono);
  font-size: 11px;
  padding: 3px 8px;
  border-radius: 3px;
  cursor: pointer;
  box-shadow: 0 0 8px var(--term-glow-color);
  z-index: 5;
  transition: opacity 0.2s ease;
}
.cli-scroll-bottom-btn:hover {
  background: var(--term-green);
  color: var(--term-bg);
}
```

---

## 5. Mobile Touch, Virtual Key Toolbar & Focus Management

### 5.1 Click/Tap Focus Delegation
Tapping anywhere inside `.cli-body` delegates focus to `#cli-input`, opening the keyboard on mobile devices:

```javascript
const cliBody = document.querySelector('.cli-body');
const cliInput = document.getElementById('cli-input');

if (cliBody && cliInput) {
  cliBody.addEventListener('click', (e) => {
    // Only focus if user didn't select text or click a link/button
    const selection = window.getSelection();
    if (selection && selection.toString().length > 0) return;
    if (e.target.tagName === 'A' || e.target.tagName === 'BUTTON') return;
    
    cliInput.focus();
  });
}
```

### 5.2 iOS Viewport Zoom Prevention
On iOS mobile browsers, `<input>` font sizes below `16px` trigger automatic screen zoom-in, breaking window frames.

```css
@media screen and (max-width: 768px) {
  .cli-input-field {
    font-size: 16px !important; /* Prevents auto-zoom on mobile safari */
    touch-action: manipulation;
  }
}
```

### 5.3 Mobile Virtual Key Touch Helper Toolbar
Mobile keyboards lack physical `Tab` (autocomplete) and `Up/Down` arrow keys. An on-screen touch toolbar provides full CLI control on mobile devices:

```html
<div id="cli-mobile-toolbar" class="cli-mobile-toolbar">
  <button type="button" class="cli-vkey" data-key="Tab">TAB ⇥</button>
  <button type="button" class="cli-vkey" data-key="ArrowUp">▲ HIST</button>
  <button type="button" class="cli-vkey" data-key="ArrowDown">▼ HIST</button>
  <button type="button" class="cli-vkey" data-cmd="help">HELP</button>
  <button type="button" class="cli-vkey" data-cmd="clear">CLEAR</button>
</div>
```

```css
.cli-mobile-toolbar {
  display: flex;
  gap: 4px;
  padding: 4px;
  background: rgba(10, 26, 10, 0.95);
  border-top: 1px solid var(--term-green-dim);
  overflow-x: auto;
  white-space: nowrap;
  touch-action: manipulation;
}

.cli-vkey {
  background: rgba(51, 255, 102, 0.1);
  color: var(--term-green);
  border: 1px solid var(--term-green-dim);
  font-family: var(--font-mono);
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 2px;
  cursor: pointer;
  user-select: none;
  touch-action: manipulation;
}

.cli-vkey:active {
  background: var(--term-green);
  color: var(--term-bg);
}
```

---

## 6. Implementation Checklist & File Reference

| Target File | Required Additions |
|-------------|-------------------|
| `site/style.css` | Add phosphor theme variables, status tag styles, ASCII banner rules, custom webkit scrollbars, scanline keyframes, mobile toolbar styles. |
| `site/index.html` | Add scanline overlay container, scroll-to-bottom resume pill, mobile toolbar buttons, and link `terminal.js`. |
| `site/terminal.js` | Implement `TerminalUI` manager class covering auto-scroll lock, theme switcher (`theme <name>`), format helper functions, and mobile touch events. |

