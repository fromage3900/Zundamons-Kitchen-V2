# CSS Design System Requirements & Execution Plan (`site/style.css`)
**Target Aesthetic**: Dreamy Kawaii Y2K Infinity Nikki Game Showcase & PC Desktop Launchpad  
**Target File**: `g:\Zundamons-kItchen-V2\site\style.css`  
**Author**: Explorer 2 (CSS Design System Specialist)  
**Date**: 2026-07-22  

---

## 1. Palette Design Tokens Architecture

### 1.1 Color Palette Specifications
The design system for Zundamon's Kitchen V2 transitions the visual identity into a soft, dreamlike Kawaii Y2K aesthetic inspired by games like Infinity Nikki, featuring glossy candy surfaces, pastel gradients, and glowing accents.

```css
:root {
  /* --- 🌸 Sakura Pink Palette --- */
  --sakura-light: #fff0f5;        /* Softest pastel background tint */
  --sakura-soft: #ffe5ec;         /* Soft Sakura body/card gradient */
  --sakura-base: #ffb7c5;         /* Classic Sakura Pink border/accent */
  --sakura-vibrant: #ff85a1;      /* Active button base & hover highlights */
  --sakura-hot: #ff477e;          /* High contrast text, badge & accent glow */

  /* --- 🫛 Zunda Edamame Mint Palette --- */
  --zunda-light: #f1f8e9;         /* Mint tint background transition */
  --zunda-soft: #a5d6a7;          /* Soft Edamame Mint accent */
  --zunda-leaf: #8bc34a;          /* Bright leaf highlight */
  --zunda-base: #4caf50;          /* Primary Zunda Edamame Green */
  --zunda-deep: #2e7d32;          /* Deep Zunda Green typography & dark CTA */
  --zunda-dark: #1b5e20;          /* High contrast dark text on light mint */

  /* --- ✨ Pearl Lavender & Cream Accents --- */
  --lavender-pearl: #e8dff5;      /* Magical Pearl Lavender accent */
  --lavender-deep: #5b21b6;       /* Contrast purple text for CLI pill */
  --cream-white: #fff5f8;         /* Primary body background top tint */

  /* --- 💎 Glassmorphism & Surface Tokens --- */
  --glass-bg: rgba(255, 255, 255, 0.88);
  --glass-bg-hover: rgba(255, 255, 255, 0.96);
  --glass-border: 2px solid rgba(255, 183, 197, 0.6);
  --glass-border-hover: 2px solid rgba(255, 71, 126, 0.8);
  --glass-backdrop-filter: blur(14px);

  /* --- 🍬 Gloss & Shadow Tokens --- */
  --shadow-soft-pink: 0 10px 30px rgba(255, 133, 161, 0.25);
  --shadow-soft-mint: 0 10px 30px rgba(76, 175, 80, 0.25);
  --shadow-candy-button: 0 6px 20px rgba(255, 71, 126, 0.35);
  --shadow-roblox-button: 0 8px 25px rgba(46, 125, 50, 0.4);
  --shadow-window: 0 16px 48px rgba(91, 33, 182, 0.2);
  --inset-gloss-top: inset 0 2px 0 rgba(255, 255, 255, 0.85);
  --inset-gloss-bottom: inset 0 -2px 0 rgba(0, 0, 0, 0.12);

  /* --- 💻 Terminal Palette (Pastel Console) --- */
  --term-bg: #231b2e;
  --term-pink: #f472b6;
  --term-cyan: #38bdf8;
  --term-yellow: #fef08a;

  /* --- 🔤 Typography & Transitions --- */
  --font-main: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Nunito', Roboto, sans-serif;
  --font-mono: 'VT323', 'Cascadia Code', 'Courier New', monospace;
  --transition-fast: 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-normal: 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  --transition-bounce: 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

---

## 2. Glossy Candy Buttons & Badge Styling

### 2.1 Candy Button Base (`.btn-candy`)
Designed for interactive triggers, code copying, and call-to-actions across the showcase.
- **Visual Features**: Pill shape (`border-radius: 9999px`), dual inset gloss glare (light highlight line on top, soft shadow edge on bottom), 3D linear gradient fill, drop shadow.
- **Interactive Micro-interactions**:
  - `hover`: Scaling up `transform: translateY(-2px) scale(1.03)`, enhanced glow shadow (`--shadow-candy-button`), sheen sweep animation.
  - `active`: Press animation `transform: translateY(1px) scale(0.98)`, shadow collapse.
  - `focus-visible`: 3px outline in `--sakura-hot` with 2px offset.

### 2.2 Roblox Play Button (`.btn-roblox-play` & `.play-roblox-nav-btn`)
Primary conversion CTA leading players directly to Roblox Studio / Roblox Web launcher.
- **Gradient Fill**: `linear-gradient(180deg, #8bc34a 0%, #4caf50 50%, #2e7d32 100%)`.
- **Pulse Animation**: `@keyframes roblox-play-pulse` pulsing a dual-ring ambient glow around the button continuously.
- **Sheen Effect**: Sweeping shimmer overlay (`::after` element moving left-to-right on a 3-second cycle).

### 2.3 Live Status Pill & Badges (`.badge-live` & `.status-pill`)
Indicates server build status (`🟢 LIVE ON ROBLOX · v2.4.0 HYBRID ECS`).
- **Styling**: Floating pill with pearl white semi-transparent background (`rgba(255, 255, 255, 0.95)`), 2px Sakura Pink border, 20px border-radius.
- **Live Indicator Dot (`.pill-dot`)**: Green glowing dot with continuous scale/opacity pulse animation (`@keyframes dot-ping`).

```css
/* Glossy Candy Button System */
.btn-candy {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 26px;
  border-radius: 9999px;
  font-weight: 700;
  font-size: 14px;
  color: #ffffff;
  background: linear-gradient(180deg, var(--sakura-vibrant) 0%, var(--sakura-hot) 100%);
  border: 1px solid rgba(255, 255, 255, 0.6);
  box-shadow: var(--inset-gloss-top), var(--inset-gloss-bottom), var(--shadow-candy-button);
  cursor: pointer;
  text-decoration: none;
  transition: var(--transition-bounce);
  position: relative;
  overflow: hidden;
}

.btn-candy:hover {
  transform: translateY(-3px) scale(1.03);
  box-shadow: var(--inset-gloss-top), var(--inset-gloss-bottom), 0 10px 28px rgba(255, 71, 126, 0.45);
}

.btn-candy:active {
  transform: translateY(1px) scale(0.98);
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Pulsing Roblox CTA */
.btn-roblox-play, .play-roblox-nav-btn {
  background: linear-gradient(180deg, var(--zunda-leaf) 0%, var(--zunda-base) 50%, var(--zunda-deep) 100%);
  border: 1px solid rgba(255, 255, 255, 0.8);
  box-shadow: var(--inset-gloss-top), var(--shadow-roblox-button);
  animation: roblox-glow-pulse 3s infinite ease-in-out;
}

@keyframes roblox-glow-pulse {
  0%, 100% { box-shadow: var(--inset-gloss-top), 0 6px 20px rgba(76, 175, 80, 0.4); }
  50% { box-shadow: var(--inset-gloss-top), 0 10px 32px rgba(139, 195, 74, 0.75); }
}

/* Sheen Shimmer Overlay */
.btn-candy::after, .btn-roblox-play::after {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: linear-gradient(60deg, transparent 30%, rgba(255, 255, 255, 0.4) 50%, transparent 70%);
  transform: rotate(25deg) translateX(-100%);
  transition: transform 0.6s ease;
}

.btn-candy:hover::after, .btn-roblox-play:hover::after {
  transform: rotate(25deg) translateX(100%);
}

/* Live Status Badge */
.status-pill, .badge-live {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.92);
  backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--sakura-base);
  padding: 6px 16px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 800;
  color: var(--zunda-deep);
  box-shadow: 0 4px 14px rgba(255, 183, 197, 0.3);
}

.pill-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  background-color: var(--zunda-base);
  border-radius: 50%;
  box-shadow: 0 0 8px var(--zunda-base);
  animation: dot-pulse 2s infinite ease-in-out;
}

@keyframes dot-pulse {
  0%, 100% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.3); opacity: 0.6; }
}
```

---

## 3. Starburst Canvas & Background Styling

### 3.1 Background Gradient & Starburst Backdrop
- **Background Gradient**: Dreamy multi-stop pastel backdrop transitions smoothly from Soft Sakura (`#fff5f8`), down through Lavender Pearl (`#ffe5ec` to `#e8dff5`), ending in fresh Edamame Mint (`#f1f8e9`).
- **Canvas Selectors (`#star-canvas` & `#star-sparkle-canvas`)**:
  - Position fixed covering full viewport (`width: 100vw; height: 100vh`).
  - `pointer-events: none` to prevent interfering with mouse/touch clicks on links and windows.
  - `z-index: 1` placed safely behind content sections (`z-index: 10`) and sticky navbar (`z-index: 1000`).

### 3.2 Complete Removal of Dark CRT / Matrix Overlays
- **Audit Result**: Zero dark green matrix lines, CRT scanline grids, or dark blood cell overlays. All background graphics feature soft sparkling starbursts (`✨`), pastel ambient glows, and clean glass surfaces.

```css
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  min-height: 100vh;
  font-family: var(--font-main);
  background: linear-gradient(180deg, var(--cream-white) 0%, var(--sakura-soft) 35%, var(--lavender-pearl) 70%, var(--zunda-light) 100%);
  background-attachment: fixed;
  color: #2d3748;
  overflow-x: hidden;
  scroll-behavior: smooth;
}

/* Starburst Sparkle Canvas */
#star-canvas, #star-sparkle-canvas {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  pointer-events: none;
  z-index: 1;
  overflow: hidden;
}
```

---

## 4. Showcase Layout Sections

### 4.1 Sticky Top Game Navbar (`.game-navbar`)
- Sticky position at `top: 0`, `z-index: 1000`.
- Glassmorphism background: `rgba(255, 255, 255, 0.92)` with `backdrop-filter: blur(14px)`.
- Bottom border: `2px solid var(--sakura-base)`.
- Brand section featuring animated `🫛` emoji bounce and badge `V2`.
- Right-aligned navigation links + dual quick action buttons (`ZundaCLI.exe` window shortcut and Roblox CTA).

### 4.2 Hero Banner Section (`.game-hero`)
- Layout: 2-column grid (`grid-template-columns: 1fr 360px`) on desktop.
- Headline: Gradient highlighted typography using `.highlight-text`.
- Hero Action Buttons: `.btn-candy`, `.btn-roblox-play`, `.secondary-cta`, and `.terminal-cta`.
- Feature Tag Pills (`.hero-pills` & `.hero-tag`): Glossy pills with subtle Sakura borders.
- Hero Companion Card Preview (`.zunda-hero-avatar-box`): Interactive SVG avatar inside a pearl-framed glass container with 3D shadow.

### 4.3 Interactive Zunda-OS Desktop Launcher (`.os-app-launcher-grid`)
- Grid layout wrapping 7 clickable desktop app tiles (`ZundaCLI.exe`, `Cookbook.app`, `Zundamon.app`, `Promos.app`, `VNTalk.app`, `Calculator.app`, `Updates.log`).
- `.os-app-tile`: Glass tile cards with hover elevation (`transform: translateY(-5px)`), border color highlight, and icon floating animation.

### 4.4 Feature Showcase Grid (`.features-grid` & `.feature-card`)
- Layout: Responsive grid `grid-template-columns: repeat(auto-fit, minmax(250px, 1fr))`.
- Card Styling: White glass surface (`--glass-bg`), 2px Sakura border, rounded corners (`border-radius: 20px`), shadow (`--shadow-soft-pink`).
- Hover Micro-interaction: Smooth lift + icon pop effect (`.feat-icon` scale 1.15).

### 4.5 Active Promo Codes Cards (`.codes-grid` & `.code-box`)
- Card Styling: Voucher style border with pastel mint line (`border: 2px dashed var(--zunda-soft)`).
- Monospace Code Display (`.code-val`): Bold monospace typography.
- 1-Click Copy Button (`.copy-code-btn` / `.btn-copy`): Glossy button triggers clipboard copy and invokes toast notification.

### 4.6 Dynamic Toast Notification System (`.toast-container` & `.toast-message`)
- Fixed container at bottom right (`bottom: 24px; right: 24px; z-index: 9999`).
- Toast bubble: Floating pill with green checkmark, drop shadow, and smooth entrance/exit keyframe animations (`@keyframes toast-slide-in`, `@keyframes toast-fade-out`).

```css
/* Toast Notification System */
.toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 10px;
  pointer-events: none;
}

.toast-message {
  pointer-events: auto;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  background: rgba(255, 255, 255, 0.96);
  backdrop-filter: var(--glass-backdrop-filter);
  border: 2px solid var(--sakura-vibrant);
  padding: 12px 22px;
  border-radius: 9999px;
  font-weight: 700;
  font-size: 13px;
  color: var(--zunda-deep);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  animation: toast-slide-in 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
}

.toast-message.fade-out {
  animation: toast-fade-out 0.3s ease forwards;
}

@keyframes toast-slide-in {
  from { opacity: 0; transform: translateY(20px) scale(0.9); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

@keyframes toast-fade-out {
  from { opacity: 1; transform: translateY(0) scale(1); }
  to { opacity: 0; transform: translateY(10px) scale(0.95); }
}
```

---

## 5. Responsive Breakpoints Specification

### 5.1 Desktop (>= 1024px)
- Max container width: `1200px` centered (`margin: 0 auto`).
- Hero container: 2 columns (`1fr 360px`).
- Features grid: 4 columns (`repeat(4, 1fr)`).
- Desktop app launcher: 7 tiles across 1-2 balanced rows.
- Full navbar links and CTA buttons visible.

### 5.2 Tablet (768px - 1023px)
- Hero container: Collapses to single column (`1fr`) with preview card centered underneath.
- Features grid: 2 columns (`repeat(2, 1fr)`).
- Promo codes grid: 2 columns (`repeat(2, 1fr)`).
- Windows modal container: Drag bounds clamped within 90% viewport.

### 5.3 Mobile (< 768px & < 480px)
- Hero title font size scales down (`42px` -> `28px - 32px`).
- Hero action buttons stack vertically (`width: 100%`).
- Features grid & promo cards collapse to single column (`1fr`).
- Desktop launcher app grid: 2 columns (`repeat(2, 1fr)`).
- Toast notification container repositions to bottom center (`bottom: 16px; left: 50%; transform: translateX(-50%)`).

```css
/* Responsive Breakpoints */
@media screen and (max-width: 1024px) {
  .hero-container {
    grid-template-columns: 1fr;
    text-align: center;
  }
  .hero-actions {
    justify-content: center;
  }
  .hero-pills {
    justify-content: center;
  }
  .hero-card-preview {
    margin-top: 20px;
    display: flex;
    justify-content: center;
  }
}

@media screen and (max-width: 768px) {
  .nav-links a:not(.nav-btn) {
    display: none; /* Keep clean navigation on smaller screens */
  }
  .hero-title {
    font-size: 30px;
  }
  .hero-actions {
    flex-direction: column;
    width: 100%;
  }
  .cta-btn, .btn-candy {
    width: 100%;
    justify-content: center;
  }
  .toast-container {
    left: 16px;
    right: 16px;
    bottom: 16px;
    align-items: center;
  }
  .toast-message {
    width: 100%;
    justify-content: center;
  }
  .window {
    max-width: 94vw !important;
    left: 3vw !important;
  }
}
```

---

## 6. Execution Plan & Implementation Steps for Worker
1. **Token Update**: Replace `:root` definitions in `site/style.css` with the expanded Kawaii Y2K token dictionary.
2. **Candy Buttons & Badges**: Add `.btn-candy`, `.btn-roblox-play`, `.badge-live`, and sheen animations.
3. **Background & Canvas**: Update body background gradient, set `#star-canvas, #star-sparkle-canvas` fixed viewport styling.
4. **Showcase Layout & Components**: Enhance grid layouts for features, companions, promo codes, desktop app launcher, and toast container.
5. **Responsive Media Queries**: Append desktop, tablet, and mobile media queries to enforce clean layout scaling across all devices.
