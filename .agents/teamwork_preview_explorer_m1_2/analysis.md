# CSS3 Styling Architecture Specification: Zunda-OS 95 & Cozy Infinity Nikki Zen Edamame-Pea Aesthetic

**Author**: Explorer 2 (`teamwork_preview_explorer_m1_2`)  
**Target Path**: `site/style.css` (Target Root Directory: `g:\Zundamons-kItchen-V2\site`)  
**Milestone**: Milestone 1 (Zunda-OS 95 CLI Launch Page & Creative Hub)  
**Status**: Specification Complete  

---

## Executive Summary

This document specifies the complete CSS3 styling architecture (`site/style.css`) for the Zunda-OS 95 CLI Launch Page and Creative Hub. The visual aesthetic fuses vintage 1990s desktop operating systems (Windows 95/98) with a cozy Infinity Nikki zen edamame-pea palette (`#2e7d32`, `#4caf50`, `#8bc34a`, `#e8f5e9`), CRT phosphor terminal luminescence, floating ambient zunda mochi animations, and modular Roblox ScreenGui UI token mappings.

---

## 1. CSS Design Tokens (`:root`)

The token system is structured into five functional groups: Primary Zunda Greens, Retro OS Window Palette, Terminal Phosphor Palette, Roblox UI Export Mapping Variables, and Typography/Geometry Tokens.

```css
/* ==========================================================================
   ZUNDA-OS 95 DESIGN TOKENS & CSS VARIABLES
   ========================================================================== */

:root {
  /* --- Primary Zunda Greens (Cozy Zen Edamame Palette) --- */
  --zunda-dark: #2e7d32;         /* Deep forest edamame green */
  --zunda-primary: #4caf50;      /* Fresh zunda green */
  --zunda-light: #8bc34a;        /* Bright sprout green */
  --zunda-bg: #e8f5e9;           /* Soft zen mint desktop background */
  --zunda-accent: #c8e6c9;       /* Pastel pea pod highlight */
  --zunda-pastel: #f1f8e9;       /* Warm mochi cream green */
  --zunda-hover: #3d8b40;        /* Hover state dark green */
  --zunda-shadow: rgba(46, 125, 50, 0.25); /* Ambient green drop shadow */

  /* --- Retro OS Palette (Zunda-OS 95 Windows & Bevels) --- */
  --win-bg: #e8f5e9;             /* Window surface background */
  --win-content-bg: #ffffff;     /* Window inner content panel background */
  --win-border-light: #ffffff;   /* 3D top/left bevel highlight */
  --win-border-mid: #a5d6a7;     /* 3D intermediate pastel bevel border */
  --win-border-dark: #2e7d32;    /* 3D bottom/right dark bevel shadow */
  --win-border-shadow: #1b5e20;  /* 3D deep edge shadow */
  --win-title-bg: linear-gradient(90deg, #2e7d32 0%, #4caf50 100%); /* Active titlebar gradient */
  --win-title-bg-inactive: linear-gradient(90deg, #78909c 0%, #b0bec5 100%); /* Inactive titlebar */
  --win-title-text: #ffffff;     /* Active titlebar text */
  --win-title-text-inactive: #eceff1; /* Inactive titlebar text */
  --win-btn-bg: #c8e6c9;         /* Retro control button background */
  --win-btn-hover: #a5d6a7;       /* Control button hover color */
  --win-btn-active: #8bc34a;      /* Control button active/pressed color */

  /* --- Terminal Phosphor Palette (ZundaCLI.exe CRT Console) --- */
  --term-bg: #0a150a;            /* Dark obsidian phosphor background */
  --term-green: #33ff66;         /* Classic CRT phosphor green text */
  --term-green-dim: #1eb844;     /* Secondary dim console text */
  --term-glow: 0 0 8px rgba(51, 255, 102, 0.6); /* CRT text glow shadow */
  --term-cursor: #33ff66;        /* Blinking block cursor color */
  --term-selection: rgba(51, 255, 102, 0.25); /* Console text highlight */

  /* --- Roblox UI Export Mapping Variables --- */
  /* Direct map to Roblox Studio ScreenGui, Frame, TextLabel, TextButton properties */
  --roblox-screengui-bg: var(--zunda-bg);
  --roblox-frame-border: var(--win-border-dark);
  --roblox-text-color: #1b5e20;
  --roblox-corner-radius: 0px;
  --roblox-titlebar-bg: var(--zunda-dark);
  --roblox-btn-bg: var(--zunda-accent);
  --roblox-font-family: 'MS Sans Serif', 'Segoe UI', Tahoma, monospace, sans-serif;

  /* --- Typography & Spacing Tokens --- */
  --font-os: 'MS Sans Serif', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  --font-mono: 'VT323', 'Courier New', Consolas, monospace;
  --font-pixel: 'Press Start 2P', monospace;
  --taskbar-height: 38px;
  --start-menu-width: 250px;
  --border-width-3d: 2px;
}
```

---

## 2. Zunda-OS 95 Window Styling Architecture

### 2.1 3D Bevel Border Mechanics
Zunda-OS 95 utilizes realistic 90s dual-layer outset and inset 3D bevels via layered `box-shadow` and `border` definitions:
- **Outset Bevel (`.bevel-outset`)**: Applied to window containers, popups, and unpressed buttons. Top-left edges are crisp white (`#ffffff`), while bottom-right edges are dark green (`#2e7d32` / `#1b5e20`).
- **Inset Bevel (`.bevel-inset`)**: Applied to terminal screens, text inputs, status bars, content viewports, and pressed buttons. Reverse light direction gives an engraved look.

```css
/* --- 3D Bevel Classes --- */
.bevel-outset {
  border-top: 2px solid var(--win-border-light);
  border-left: 2px solid var(--win-border-light);
  border-right: 2px solid var(--win-border-shadow);
  border-bottom: 2px solid var(--win-border-shadow);
  box-shadow: 
    inset 1px 1px 0px var(--zunda-pastel),
    inset -1px -1px 0px var(--win-border-dark);
}

.bevel-inset {
  border-top: 2px solid var(--win-border-shadow);
  border-left: 2px solid var(--win-border-shadow);
  border-right: 2px solid var(--win-border-light);
  border-bottom: 2px solid var(--win-border-light);
  box-shadow: 
    inset 1px 1px 0px var(--win-border-dark),
    inset -1px -1px 0px var(--zunda-pastel);
}
```

### 2.2 Window Component Hierarchy
- `.window`: Base class for interactive floating app windows (`position: absolute`, `display: flex`, `flex-direction: column`, `background: var(--win-bg)`).
- `.window-header` / `.window-titlebar`: Active gradient bar holding pea pod icon (`🫛`), window title, and retro window action buttons (`_`, `□`, `X`).
- `.window-body` / `.window-content`: Main content container (`flex: 1`, `overflow: auto`, `background: var(--win-content-bg)`).

```css
/* --- Window Component Base --- */
.window {
  position: absolute;
  min-width: 280px;
  min-height: 180px;
  background-color: var(--win-bg);
  padding: 3px;
  box-sizing: border-box;
  user-select: none;
  display: flex;
  flex-direction: column;
}

/* Active Window State */
.window.window-active {
  z-index: 100;
  box-shadow: 
    4px 4px 16px var(--zunda-shadow),
    inset 1px 1px 0px var(--win-border-light),
    inset -1px -1px 0px var(--win-border-dark);
}

.window.window-active .window-titlebar {
  background: var(--win-title-bg);
  color: var(--win-title-text);
}

/* Inactive Window State */
.window.window-inactive {
  z-index: 1;
  opacity: 0.95;
}

.window.window-inactive .window-titlebar {
  background: var(--win-title-bg-inactive);
  color: var(--win-title-text-inactive);
}

/* Titlebar & Controls */
.window-titlebar {
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 4px;
  font-family: var(--font-os);
  font-size: 12px;
  font-weight: bold;
  letter-spacing: 0.5px;
}

.window-titlebar-left {
  display: flex;
  align-items: center;
  gap: 6px;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.window-icon {
  width: 16px;
  height: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
}

.window-controls {
  display: flex;
  gap: 3px;
}

.win-btn {
  width: 18px;
  height: 16px;
  background: var(--win-btn-bg);
  border-top: 1px solid var(--win-border-light);
  border-left: 1px solid var(--win-border-light);
  border-right: 1px solid var(--win-border-dark);
  border-bottom: 1px solid var(--win-border-dark);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-os);
  font-size: 10px;
  font-weight: bold;
  color: #1b5e20;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}

.win-btn:hover {
  background: var(--win-btn-hover);
}

.win-btn:active {
  border-top: 1px solid var(--win-border-dark);
  border-left: 1px solid var(--win-border-dark);
  border-right: 1px solid var(--win-border-light);
  border-bottom: 1px solid var(--win-border-light);
  padding: 1px 0 0 1px;
}

.win-btn-close:hover {
  background: #e57373;
  color: #ffffff;
}
```

---

## 3. Taskbar & Start Menu Styling Architecture

### 3.1 Pinned Vintage Taskbar (`#taskbar`)
The taskbar is permanently fixed to the viewport bottom (`height: 38px`), matching authentic Windows 95 spatial metrics while adopting Zunda green glass/pastel tones.

```css
/* --- Taskbar Architecture --- */
#taskbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: var(--taskbar-height);
  background-color: var(--win-bg);
  border-top: 2px solid var(--win-border-light);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 2px 4px;
  z-index: 9999;
  box-sizing: border-box;
  user-select: none;
}

/* Start Button */
#start-btn {
  height: 30px;
  padding: 0 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-os);
  font-size: 13px;
  font-weight: bold;
  color: var(--win-border-shadow);
  background: var(--win-btn-bg);
  cursor: pointer;
}

#start-btn.start-btn-active {
  border-top: 2px solid var(--win-border-shadow);
  border-left: 2px solid var(--win-border-shadow);
  border-right: 2px solid var(--win-border-light);
  border-bottom: 2px solid var(--win-border-light);
  background: var(--zunda-accent);
}

/* Taskbar Windows Bar */
#taskbar-windows {
  display: flex;
  gap: 4px;
  flex: 1;
  margin: 0 8px;
  overflow-x: auto;
}

.taskbar-btn {
  height: 28px;
  min-width: 120px;
  max-width: 180px;
  padding: 0 8px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-os);
  font-size: 12px;
  color: #1b5e20;
  background: var(--win-btn-bg);
  cursor: pointer;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
}

.taskbar-btn.active {
  font-weight: bold;
  background: var(--zunda-pastel);
  border-top: 2px solid var(--win-border-dark);
  border-left: 2px solid var(--win-border-dark);
  border-right: 2px solid var(--win-border-light);
  border-bottom: 2px solid var(--win-border-light);
}

/* System Tray */
#system-tray {
  height: 28px;
  padding: 0 8px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: var(--font-os);
  font-size: 12px;
  color: var(--win-border-shadow);
  background: var(--win-bg);
}

.tray-icon {
  cursor: pointer;
  font-size: 14px;
  opacity: 0.85;
  transition: opacity 0.15s ease;
}

.tray-icon:hover {
  opacity: 1;
}

#tray-clock {
  font-weight: bold;
  font-size: 11px;
}
```

### 3.2 Retro Start Menu Popup (`#start-menu`)
The start menu renders a side banner with vertical "Zunda-OS 95" branding alongside a list of launcher items.

```css
/* --- Start Menu Popup --- */
#start-menu {
  position: fixed;
  bottom: calc(var(--taskbar-height) + 2px);
  left: 2px;
  width: var(--start-menu-width);
  background: var(--win-bg);
  display: flex;
  z-index: 10000;
  padding: 3px;
  box-shadow: 3px 3px 10px rgba(0,0,0,0.3);
}

#start-menu.hidden {
  display: none !important;
}

.start-menu-banner {
  width: 32px;
  background: linear-gradient(180deg, #1b5e20 0%, #4caf50 100%);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding-bottom: 12px;
}

.start-menu-banner-text {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-family: var(--font-os);
  font-size: 16px;
  font-weight: bold;
  color: #ffffff;
  letter-spacing: 2px;
}

.start-menu-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 4px 0;
}

.start-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  font-family: var(--font-os);
  font-size: 13px;
  color: #1b5e20;
  cursor: pointer;
  text-decoration: none;
}

.start-menu-item:hover {
  background-color: var(--zunda-dark);
  color: #ffffff;
}

.start-menu-divider {
  height: 1px;
  border-top: 1px solid var(--win-border-dark);
  border-bottom: 1px solid var(--win-border-light);
  margin: 4px 2px;
}
```

---

## 4. CRT Scanlines Overlay & Cozy Atmosphere Keyframe Animations

### 4.1 CRT Scanlines Layer (`#crt-overlay`)
A non-interactive overlay screen simulating nostalgic CRT TV/Monitor raster lines and RGB subpixel tinting. Toggleable via `.crt-off`.

```css
/* --- CRT Scanlines Effect --- */
#crt-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  pointer-events: none;
  z-index: 9000;
  background: 
    linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%),
    linear-gradient(90deg, rgba(255, 0, 0, 0.02), rgba(0, 255, 0, 0.01), rgba(0, 0, 255, 0.02));
  background-size: 100% 3px, 6px 100%;
  box-shadow: inset 0 0 80px rgba(10, 21, 10, 0.35);
  transition: opacity 0.3s ease;
}

/* CRT Toggle Off State */
body.crt-off #crt-overlay,
#crt-overlay.crt-off {
  display: none !important;
  opacity: 0 !important;
}

/* Terminal Viewport Phosphor Styling */
.terminal-viewport {
  background-color: var(--term-bg);
  color: var(--term-green);
  font-family: var(--font-mono);
  font-size: 15px;
  line-height: 1.4;
  padding: 12px;
  text-shadow: var(--term-glow);
  overflow-y: auto;
  flex: 1;
}
```

### 4.2 Keyframe Animations
Floating pea pods and zunda mochi floating keyframes for cozy atmosphere, terminal pulse, and blinking block cursor.

```css
/* --- Keyframe Animations --- */

/* Floating Pea Pod / Mochi Animation */
@keyframes floatPea {
  0% {
    transform: translateY(0px) rotate(0deg) scale(1);
  }
  50% {
    transform: translateY(-12px) rotate(4deg) scale(1.04);
  }
  100% {
    transform: translateY(0px) rotate(0deg) scale(1);
  }
}

.floating-pea-asset {
  animation: floatPea 4s ease-in-out infinite;
}

/* CRT Terminal Text Glow Pulse */
@keyframes terminalPulse {
  0%, 100% {
    text-shadow: 0 0 8px rgba(51, 255, 102, 0.6);
  }
  50% {
    text-shadow: 0 0 14px rgba(51, 255, 102, 0.9), 0 0 3px rgba(255, 255, 255, 0.4);
  }
}

/* Classic Block Cursor Blink */
@keyframes cursorBlink {
  0%, 49% {
    opacity: 1;
  }
  50%, 100% {
    opacity: 0;
  }
}

.terminal-cursor {
  display: inline-block;
  width: 8px;
  height: 15px;
  background-color: var(--term-cursor);
  animation: cursorBlink 1s infinite;
  vertical-align: middle;
  margin-left: 2px;
}
```

---

## 5. Responsive Layout Architecture

Adaptive media queries ensuring functional UI presentation across Desktop (>1024px), Tablet (768px - 1024px), and Mobile (<768px).

```css
/* --- Responsive Breakpoints --- */

/* Desktop (>1024px): Default multi-window floating workspace */

/* Tablet Display (768px to 1024px) */
@media screen and (max-width: 1024px) {
  .window {
    max-width: 92vw;
    max-height: 80vh;
  }
  
  .taskbar-btn {
    min-width: 90px;
    max-width: 130px;
  }
}

/* Mobile Display (<768px) */
@media screen and (max-width: 768px) {
  /* Force active window into full-screen modal mode */
  .window {
    width: 100vw !important;
    height: calc(100vh - var(--taskbar-height)) !important;
    top: 0 !important;
    left: 0 !important;
    margin: 0 !important;
    border-radius: 0 !important;
    min-width: 100vw;
  }

  #start-menu {
    width: calc(100vw - 4px);
    left: 2px;
  }

  .win-btn {
    width: 24px;
    height: 22px;
    font-size: 12px;
  }

  #taskbar {
    height: 42px;
  }

  #start-btn {
    height: 34px;
    padding: 0 12px;
  }

  .terminal-viewport {
    font-size: 13px;
    padding: 8px;
  }
}
```

---

## 6. Implementation Checklist for Worker (`teamwork_preview_worker_m1`)

1. Create `site/style.css` in `g:\Zundamons-kItchen-V2\site\style.css`.
2. Insert `:root` design token block with exact color codes (`#2e7d32`, `#4caf50`, `#8bc34a`, `#e8f5e9`, `#c8e6c9`, `#f1f8e9`, `#0a150a`, `#33ff66`).
3. Ensure `.bevel-outset` and `.bevel-inset` 3D border shadows render accurately.
4. Wire up `.window`, `.window-active`, `.window-inactive`, `.window-titlebar`, and `.win-btn` control buttons.
5. Setup `#taskbar` (38px bottom pin), `#start-btn`, `#taskbar-windows`, `#system-tray`.
6. Setup `#start-menu` with vertical sidebar branding.
7. Implement `#crt-overlay` scanline gradient overlay with `.crt-off` toggle support.
8. Define `@keyframes floatPea` floating mochi animation.
9. Include tablet (1024px) and mobile (768px) media query overrides.
