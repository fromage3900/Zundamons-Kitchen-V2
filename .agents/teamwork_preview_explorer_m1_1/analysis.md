# Zunda-OS 95 — HTML5 Architecture & DOM Specification

**Module**: Zunda-OS 95 CLI Launch Page & Creative Hub (Milestone 1)  
**Target File**: `site/index.html`  
**Author**: Explorer 1  
**Status**: Specification Complete — Handoff Ready  

---

## 1. Executive Summary & System Architecture

Zunda-OS 95 is a retro Windows 95-inspired web workspace for **Zundamon's Kitchen V2**. It serves as both an interactive CLI launch page and a creative hub featuring visual novel dialogue, recipe discovery, and quick-start documentation.

### Core Architectural Principles
1. **Zero External Runtime Dependencies**: 100% pure vanilla HTML5, CSS3, and JavaScript (ES6+). No npm packages, external CDN fonts/frameworks, jQuery, or React.
2. **Win95 Visual Authenticity with Zunda Theme**: Retro 3D inset/outset borders, pixelated font rendering, classic titlebars, paired with Zundamon's signature edamame green palette (`#70B244`, `#2D5A27`, `#EAF5E1`).
3. **Modular Window Manager Architecture**: Every application window shares a standardized DOM frame structure with minimize/maximize/close controls, draggable headers, and z-index depth management.
4. **CRT Retro Aesthetics**: Toggleable CRT scanline overlay (`#crt-overlay`) with subtle screen curvature and flicker effect.
5. **Cozy Audio & Taskbar Controls**: Fixed bottom taskbar featuring a start menu, active window tab bar, live digital clock, and BGM/SFX audio toggles.

---

## 2. Document Head & Meta Configuration

The HTML5 document head provides essential viewport, metadata, character encoding, and asset linkages.

```html
<!DOCTYPE html>
<html lang="en" data-theme="zunda-classic">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="description" content="Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub">
    <meta name="keywords" content="Zundamon, Roblox, Luau, Zunda-OS 95, CLI, Retro Web, Cookbook, Visual Novel">
    <meta name="author" content="Zundamon's Kitchen Team">

    <!-- Open Graph / Social Tags -->
    <meta property="og:title" content="Zundamon's Kitchen V2 — Zunda-OS 95">
    <meta property="og:description" content="Retro Win95 CLI Launch Page & Creative Hub for Zundamon's Kitchen V2">
    <meta property="og:type" content="website">

    <title>Zundamon's Kitchen V2 — Zunda-OS 95</title>

    <!-- Embedded Favicon (Edamame Pea SVG Data URI) -->
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🫛</text></svg>">

    <!-- Primary Stylesheets -->
    <link rel="stylesheet" href="css/zunda-os95.css">
</head>
```

---

## 3. DOM Tree Structure (`site/index.html`)

```
body.zunda-os95
├── #crt-overlay (CRT Scanline & Glow Overlay)
├── #desktop (Main Desktop Area)
│   ├── #particle-canvas (Background Pea Particle Effect Canvas)
│   ├── #desktop-icons (Shortcut Grid)
│   │   ├── .desktop-shortcut[data-app="zundacli"]
│   │   ├── .desktop-shortcut[data-app="cookbook"]
│   │   ├── .desktop-shortcut[data-app="vntalk"]
│   │   ├── .desktop-shortcut[data-app="quickstart"]
│   │   └── .desktop-shortcut[data-app="trash"]
│   └── #window-container (Floating Window Stack)
│       ├── #window-zundacli.window (ZundaCLI.exe)
│       ├── #window-cookbook.window (Cookbook.app)
│       ├── #window-vntalk.window (VNTalk.app)
│       └── #window-quickstart.window (QuickStart.txt)
└── #taskbar (Fixed Bottom Taskbar)
    ├── #start-btn (Start Zunda 🫛 Button)
    ├── #start-menu.start-menu-popup (Popup Start Menu)
    │   ├── .start-menu-banner (Vertical 'Zunda-OS 95' Sidebar)
    │   └── .start-menu-items (List of App Links, Toggles, External Links)
    ├── #taskbar-windows (Dynamic Window Buttons List)
    └── #taskbar-tray (System Tray)
        ├── #bgm-toggle (BGM Music Button)
        ├── #sfx-toggle (SFX Sound Button)
        └── #taskbar-clock (Digital Live Clock)
```

---

## 4. Detailed Component HTML Structures

### 4.1 CRT Scanline Overlay (`#crt-overlay`)

```html
<!-- CRT Scanline & Curved Glass CRT Overlay -->
<div id="crt-overlay" class="crt-enabled" aria-hidden="true">
    <div class="crt-scanlines"></div>
    <div class="crt-glow"></div>
</div>
```

### 4.2 Desktop Canvas & Desktop Icons (`#desktop`)

```html
<main id="desktop" role="main">
    <!-- Interactive Background Pea Particle Canvas -->
    <canvas id="particle-canvas" width="1920" height="1080"></canvas>

    <!-- Desktop Icons Grid -->
    <div id="desktop-icons" role="region" aria-label="Desktop Shortcuts">
        <button class="desktop-shortcut" data-open-window="window-zundacli" tabindex="0">
            <div class="shortcut-icon cli-icon">💻</div>
            <span class="shortcut-label">ZundaCLI.exe</span>
        </button>

        <button class="desktop-shortcut" data-open-window="window-cookbook" tabindex="0">
            <div class="shortcut-icon book-icon">📖</div>
            <span class="shortcut-label">Cookbook.app</span>
        </button>

        <button class="desktop-shortcut" data-open-window="window-vntalk" tabindex="0">
            <div class="shortcut-icon vn-icon">💬</div>
            <span class="shortcut-label">VNTalk.app</span>
        </button>

        <button class="desktop-shortcut" data-open-window="window-quickstart" tabindex="0">
            <div class="shortcut-icon txt-icon">📝</div>
            <span class="shortcut-label">QuickStart.txt</span>
        </button>

        <button class="desktop-shortcut" data-open-window="window-trash" tabindex="0">
            <div class="shortcut-icon trash-icon">🗑️</div>
            <span class="shortcut-label">Zunda Bin</span>
        </button>
    </div>

    <!-- Window Manager Floating Stack -->
    <div id="window-container">
        <!-- 4 Core Windows Placed Here -->
    </div>
</main>
```

---

### 4.3 Core Window 1: `ZundaCLI.exe` (`#window-zundacli`)

```html
<section id="window-zundacli" class="window active-window" data-window-id="zundacli" style="top: 40px; left: 60px; width: 680px; height: 440px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">💻</span>
            <span class="window-title-text">ZundaCLI.exe — Command Prompt</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize" aria-label="Minimize Window">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize" aria-label="Maximize Window">🗖</button>
            <button class="win-btn win-close" data-action="close" title="Close" aria-label="Close Window">✕</button>
        </div>
    </div>
    
    <div class="window-menu-bar">
        <span class="menu-item">File</span>
        <span class="menu-item">Edit</span>
        <span class="menu-item">View</span>
        <span class="menu-item">Help</span>
    </div>

    <div class="window-body cli-body">
        <div id="cli-output" class="cli-terminal-log" role="log" aria-live="polite">
            <p class="cli-welcome">Zunda-OS 95 [Version 4.09.1995]</p>
            <p class="cli-welcome">(C) Zundamon's Kitchen V2. Type <span class="cli-highlight">'help'</span> or <span class="cli-highlight">'recipes'</span> for commands.</p>
            <p class="cli-line"><span class="cli-system">[SYSTEM]:</span> Initialized edamame kernel matrix... nanoda!</p>
        </div>
        <form id="cli-input-form" class="cli-prompt-line" autocomplete="off" onsubmit="return false;">
            <label for="cli-input" class="cli-prompt-label">zunda@os95:~$</label>
            <input type="text" id="cli-input" class="cli-input-field" placeholder="Enter command (e.g., help, cook, launch)..." spellcheck="false">
        </form>
    </div>
</section>
```

---

### 4.4 Core Window 2: `Cookbook.app` (`#window-cookbook`)

```html
<section id="window-cookbook" class="window hidden" data-window-id="cookbook" style="top: 80px; left: 140px; width: 720px; height: 500px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">📖</span>
            <span class="window-title-text">Cookbook.app — Zunda Recipe Book</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize" aria-label="Minimize Window">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize" aria-label="Maximize Window">🗖</button>
            <button class="win-btn win-close" data-action="close" title="Close" aria-label="Close Window">✕</button>
        </div>
    </div>

    <div class="window-body cookbook-body">
        <div class="recipe-toolbar">
            <input type="search" id="recipe-search" class="win95-input" placeholder="Search recipes (e.g. Mochi, Shake, Dango)...">
            <div class="recipe-filter-tags">
                <button class="win95-btn active" data-filter="all">All Recipes</button>
                <button class="win95-btn" data-filter="classic">Classic Zunda</button>
                <button class="win95-btn" data-filter="desserts">Sweets & Desserts</button>
                <button class="win95-btn" data-filter="drinks">Drinks</button>
            </div>
        </div>

        <div id="recipe-grid" class="recipe-grid-container">
            <!-- Sample Recipe Card 1 -->
            <article class="recipe-card" data-category="classic">
                <div class="recipe-thumbnail">🫛🍡</div>
                <div class="recipe-info">
                    <h3 class="recipe-title">Zunda Mochi (ずんだ餅)</h3>
                    <p class="recipe-desc">Sweetened crushed edamame paste draped over warm, chewy rice cakes.</p>
                    <span class="recipe-badge">Signature Dish</span>
                </div>
            </article>

            <!-- Sample Recipe Card 2 -->
            <article class="recipe-card" data-category="drinks">
                <div class="recipe-thumbnail">🫛🥤</div>
                <div class="recipe-info">
                    <h3 class="recipe-title">Zunda Shake (ずんだシェイク)</h3>
                    <p class="recipe-desc">Rich vanilla cream blended with freshly crushed green zunda beans.</p>
                    <span class="recipe-badge">Refreshing</span>
                </div>
            </article>

            <!-- Sample Recipe Card 3 -->
            <article class="recipe-card" data-category="desserts">
                <div class="recipe-thumbnail">🫛🍨</div>
                <div class="recipe-info">
                    <h3 class="recipe-title">Zunda Parfait (ずんだパフェ)</h3>
                    <p class="recipe-desc">Layered dessert with green tea ice cream, zunda paste, and fresh fruit.</p>
                    <span class="recipe-badge">Deluxe Sweets</span>
                </div>
            </article>
        </div>
    </div>
</section>
```

---

### 4.5 Core Window 3: `VNTalk.app` (`#window-vntalk`)

```html
<section id="window-vntalk" class="window hidden" data-window-id="vntalk" style="top: 100px; left: 220px; width: 640px; height: 460px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">💬</span>
            <span class="window-title-text">VNTalk.app — Zundamon Visual Novel</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize" aria-label="Minimize Window">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize" aria-label="Maximize Window">🗖</button>
            <button class="win-btn win-close" data-action="close" title="Close" aria-label="Close Window">✕</button>
        </div>
    </div>

    <div class="window-body vn-body">
        <!-- Visual Novel Stage Area -->
        <div id="vn-stage" class="vn-stage-background">
            <div id="vn-portrait" class="vn-character-portrait" data-expression="happy">
                <div class="portrait-avatar">🫛💚</div>
            </div>
        </div>

        <!-- Dialogue Box Overlay -->
        <div id="vn-dialogue-box" class="vn-dialogue-panel">
            <div id="vn-speaker" class="vn-speaker-tag">Zundamon (ずんだもん)</div>
            <div id="vn-text" class="vn-text-content">
                Welcome to Zundamon's Kitchen V2 nanoda! What delicious edamame treats shall we cook today?
            </div>
            <div id="vn-choices" class="vn-choices-container">
                <button class="vn-choice-btn" data-vn-choice="1">Let's check the recipe book!</button>
                <button class="vn-choice-btn" data-vn-choice="2">Launch Roblox Zundamon's Kitchen!</button>
                <button class="vn-choice-btn" data-vn-choice="3">Tell me a fun Zunda fact, nanoda!</button>
            </div>
        </div>
    </div>
</section>
```

---

### 4.6 Core Window 4: `QuickStart.txt` (`#window-quickstart`)

```html
<section id="window-quickstart" class="window hidden" data-window-id="quickstart" style="top: 60px; left: 300px; width: 600px; height: 420px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">📝</span>
            <span class="window-title-text">QuickStart.txt — Notepad</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize" aria-label="Minimize Window">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize" aria-label="Maximize Window">🗖</button>
            <button class="win-btn win-close" data-action="close" title="Close" aria-label="Close Window">✕</button>
        </div>
    </div>

    <div class="window-body notepad-body">
        <textarea class="notepad-editor" readonly spellcheck="false">
=====================================================
  ZUNDAMON'S KITCHEN V2 — QUICK START GUIDE (Zunda-OS 95)
=====================================================

Welcome to Zunda-OS 95!

[KEYBOARD SHORTCUTS]
• Double-click desktop icons or single-click taskbar items to open/focus apps.
• Open Start Menu: Click [Start Zunda 🫛] or press Ctrl+Esc.
• Toggle CRT Overlay: Use Start Menu -> Toggle CRT Scanlines.
• Execute CLI Commands: Type commands into ZundaCLI.exe (try 'help', 'status', 'roblox').

[FEATURES & APPS]
1. ZundaCLI.exe : Terminal interface to inspect game state & build tools.
2. Cookbook.app : Discover signature Zundamon edamame recipes & stats.
3. VNTalk.app   : Interactive visual novel dialogue with Zundamon.
4. System Tray  : BGM & SFX audio controls with live time clock.

[GAME LINKS]
• Roblox Game Page : https://www.roblox.com/
• GitHub Repository: https://github.com/

Enjoy your cozy culinary experience nanoda! 🫛
        </textarea>
    </div>
</section>
```

---

### 4.7 Vintage Taskbar (`#taskbar`) & Start Menu (`#start-menu`)

```html
<footer id="taskbar" role="contentinfo">
    <!-- Start Button -->
    <button id="start-btn" class="win95-start-btn" aria-haspopup="true" aria-expanded="false" tabindex="0">
        <span class="start-icon">🫛</span>
        <span class="start-text">Start Zunda</span>
    </button>

    <!-- Start Menu Popup -->
    <div id="start-menu" class="start-menu-popup hidden" role="menu" aria-label="Start Menu">
        <div class="start-menu-banner">
            <span class="banner-text">Zunda-OS <strong>95</strong></span>
        </div>
        <div class="start-menu-items">
            <button class="start-item" data-open-window="window-zundacli" role="menuitem">
                <span class="item-icon">💻</span> ZundaCLI.exe
            </button>
            <button class="start-item" data-open-window="window-cookbook" role="menuitem">
                <span class="item-icon">📖</span> Cookbook.app
            </button>
            <button class="start-item" data-open-window="window-vntalk" role="menuitem">
                <span class="item-icon">💬</span> VNTalk.app
            </button>
            <button class="start-item" data-open-window="window-quickstart" role="menuitem">
                <span class="item-icon">📝</span> QuickStart.txt
            </button>

            <div class="start-divider"></div>

            <button id="menu-toggle-crt" class="start-item" role="menuitem">
                <span class="item-icon">📺</span> Toggle CRT Scanlines
            </button>
            <button id="menu-toggle-theme" class="start-item" role="menuitem">
                <span class="item-icon">🎨</span> Toggle Theme Mode
            </button>

            <div class="start-divider"></div>

            <a href="https://github.com/" target="_blank" rel="noopener noreferrer" class="start-item" role="menuitem">
                <span class="item-icon">🌐</span> GitHub Repository
            </a>
            <a href="https://www.roblox.com/" target="_blank" rel="noopener noreferrer" class="start-item" role="menuitem">
                <span class="item-icon">🎮</span> Roblox Game Page
            </a>

            <div class="start-divider"></div>

            <button id="menu-shutdown" class="start-item" role="menuitem">
                <span class="item-icon">🔌</span> Shut Down Zunda-OS...
            </button>
        </div>
    </div>

    <!-- Active Windows List Container -->
    <div id="taskbar-windows" class="taskbar-windows-container">
        <!-- Dynamically managed taskbar buttons per open window -->
        <button class="taskbar-item active" data-window-target="window-zundacli">
            <span class="tb-icon">💻</span> ZundaCLI.exe
        </button>
    </div>

    <!-- System Tray -->
    <div id="taskbar-tray" class="taskbar-tray-container">
        <button id="bgm-toggle" class="tray-btn" title="Toggle Cozy BGM Music" aria-label="Toggle BGM">
            <span class="tray-icon">🎵</span>
        </button>
        <button id="sfx-toggle" class="tray-btn" title="Toggle Sound Effects" aria-label="Toggle SFX">
            <span class="tray-icon">🔊</span>
        </button>
        <div id="taskbar-clock" class="tray-clock" title="Current Time">12:00:00 PM</div>
    </div>
</footer>
```

---

## 5. CSS & Variable Tokens Architecture (`css/zunda-os95.css`)

```css
:root {
    /* Zunda Theme Palette */
    --zunda-green-primary: #70B244;
    --zunda-green-dark: #2D5A27;
    --zunda-green-light: #EAF5E1;
    --zunda-green-accent: #A8E063;
    
    /* Win95 Retro UI Palette */
    --win-bg: #C0C0C0;
    --win-border-light: #FFFFFF;
    --win-border-dark: #808080;
    --win-border-shadow: #000000;
    --win-title-active-bg: linear-gradient(90deg, #2D5A27 0%, #70B244 100%);
    --win-title-inactive-bg: #808080;
    --win-title-text: #FFFFFF;
    
    /* CRT & Terminal Palette */
    --terminal-bg: #0C1609;
    --terminal-text: #61E046;
    --crt-scanline-color: rgba(18, 30, 15, 0.25);
}
```

---

## 6. JavaScript State Architecture (`js/zunda-os95.js`)

The front-end state is managed via lightweight vanilla JS modules:

1. **WindowManager (`js/window-manager.js`)**:
   - Manages z-index focus ordering (`bringToFront`).
   - Drag-and-drop window positioning (`initDraggable`).
   - Window state transitions (`minimize`, `maximize`, `restore`, `close`).
   - Synchronizes window states with `#taskbar-windows` buttons.

2. **StartMenuManager (`js/start-menu.js`)**:
   - Manages `#start-btn` toggle & backdrop click auto-close.
   - Binds menu shortcut clicks to window actions.

3. **CRTController (`js/crt-controller.js`)**:
   - Manages scanline state (`#crt-overlay` toggle).
   - Saves preferences to `localStorage`.

4. **PeaParticleSystem (`js/pea-particles.js`)**:
   - 2D Canvas background rendering floating edamame particles.

5. **AudioSystem (`js/audio-system.js`)**:
   - Synthesizes Web Audio API retro chimes & manages BGM/SFX audio toggles.

6. **ClockSystem (`js/clock-system.js`)**:
   - Updates `#taskbar-clock` every 1000ms with formatted local time.

---

## 7. Verification & Compliance Checklist

- [x] **Complete HTML5 document skeleton**: Viewport, UTF-8 meta, OG tags, Title.
- [x] **Desktop Container (`#desktop`)**: Background canvas, desktop icons, window container.
- [x] **CRT Scanline Overlay (`#crt-overlay`)**: Toggleable CSS/DOM overlay structure.
- [x] **Four Core Application Windows**:
  - `ZundaCLI.exe` with terminal log & prompt.
  - `Cookbook.app` with recipe filter & cards.
  - `VNTalk.app` with stage, portrait, dialogue & choices.
  - `QuickStart.txt` with retro notepad text area.
- [x] **Vintage Taskbar (`#taskbar`)**:
  - Start Button (`#start-btn`).
  - Start Menu Popup (`#start-menu`) with app shortcuts, toggles, external links, shutdown.
  - Window items container (`#taskbar-windows`).
  - System Tray (`#taskbar-tray`) with BGM toggle, SFX toggle, Live Clock.
- [x] **Zero external dependencies**: Standard Vanilla HTML5 markup ready for styling and scripting.
