# Milestone 4 Analysis Report: Cookbook.app Specifications & Design

**Author**: Explorer 1  
**Milestone**: Milestone 4 (Creative Hub Applications — Cookbook.app)  
**Target Files**: `site/app.js`, `site/index.html`, `site/style.css`, `site/assets/`  
**Date**: 2026-07-21  

---

## 1. Executive Summary

This report establishes the complete specification, design architecture, data schema, UI layout, SVG asset design, and interactive rhythm minigame simulator engine for **`Cookbook.app`** in Zunda-OS 95.

Currently, `site/index.html` contains a static 5-card recipe grid with basic inline string filtering and `alert()` popups. `site/app.js` is not yet created. This investigation defines the modular architecture for `app.js` to transform `Cookbook.app` into an interactive split-pane application featuring:
1. **Dynamic Recipe Search & Filter UI** with category tabs (`All`, `Mochi`, `Tea`, `Desserts`, `Entrees`) and live keyword search matching names, categories, and ingredients.
2. **Detailed Recipe Card Inspector** displaying ingredient breakdowns, gold rewards (`🪙 Gold`), Chef XP (`⭐ XP`), and rhythm minigame score targets (`Perfect`, `Great`, `Ok` tolerances in ms).
3. **Cozy Vector SVG Food Illustrations** matching the Zunda-OS 95 green palette (`#4caf50`, `#8bc34a`, `#1b5e20`).
4. **Interactive Rhythm Minigame Preview Simulator Widget** featuring a real-time canvas/HTML note track, user keypress/tap timing evaluation, combo multipliers, Web Audio hit sound synthesis, and local high score tracking.

---

## 2. Evidence Chain & Baseline Code Analysis

| Component | File Path | Line Range | Observation |
|---|---|---|---|
| Window Container | `site/index.html` | L116–188 | `<section id="window-cookbook">` with placeholder cards (Zunda Mochi, Shake, Parfait, Dango, Latte) |
| Inline Script | `site/index.html` | L501–547 | Primitive `filterRecipes()` filtering `.recipe-card` elements by name/text. Card clicks trigger `alert()` |
| Window Manager | `site/window_manager.js` | L36, L218, L417 | `window-cookbook` registered in `managedIds` stack |
| Current CSS | `site/style.css` | L727–800 | Grid layout (`grid-template-columns: repeat(auto-fill, minmax(200px, 1fr))`) and `.recipe-card` hover effects |
| Audio Engine | `site/assets/audio_engine.js` | L7–86, L92–136 | Native Web Audio API synth ready for rhythm hit feedback synthesis |
| Existing SVG Assets | `site/assets/` | File list | `pea_pod.svg` (1031 B), `zundamon_mochi.svg` (1506 B) |

---

## 3. Detailed Component Specifications

### 3.1. Recipe Search & Filter UI
- **Category Filter Tabs**:
  - Standard categories: `All` (`all`), `Mochi` (`mochi`), `Tea` (`tea`), `Desserts` (`desserts`), `Entrees` (`entrees`).
  - Active button state styled with retro Zunda green highlight (`.win95-btn.active`).
- **Realtime Keyword Search**:
  - `#recipe-search` input filters dynamically on `input` events.
  - Matches case-insensitive strings across `name`, `japaneseName`, `category`, `badge`, and `ingredients` list items.
- **Empty State Component**:
  - Displays retro styled empty state container when 0 results match query/category filter:
    ```html
    <div class="recipe-empty-state">
      <span class="empty-icon">🫛🔍</span>
      <p>No recipes found matching "<span id="empty-search-query"></span>" nanoda!</p>
      <button class="win95-btn" id="btn-reset-recipe-filters">Reset Filters</button>
    </div>
    ```

### 3.2. Recipe Data Model & Detail Card Renderer (`site/app.js`)
- **Data Schema (`RECIPES` Data Array)**:
```javascript
const RECIPES = [
  {
    id: 'zunda-mochi',
    name: 'Zunda Mochi',
    japaneseName: 'ずんだ餅',
    category: 'mochi',
    badge: 'Signature Dish',
    iconSvg: 'mochi',
    description: 'Sweetened crushed edamame paste draped generously over warm, chewy glutinous rice cakes.',
    ingredients: [
      { name: 'Young Edamame Beans', amount: '200g' },
      { name: 'Mochi Rice Cake', amount: '4 pcs' },
      { name: 'Cane Sugar', amount: '2 tbsp' },
      { name: 'Sea Salt', amount: '1 pinch' }
    ],
    goldReward: 150,
    chefXP: 45,
    rhythmConfig: {
      bpm: 120,
      targetScore: 1200,
      tolerances: { perfect: 50, great: 120, ok: 200 },
      notePattern: ['🫛', '🍡', '🫛', '✨', '🫛', '🍡', '✨', '🎉']
    }
  },
  {
    id: 'zunda-matcha-tea',
    name: 'Zunda Matcha Latte',
    japaneseName: 'ずんだ抹茶ラテ',
    category: 'tea',
    badge: 'Cozy Brew',
    iconSvg: 'tea',
    description: 'Steamed oat milk poured over ceremonial Uji matcha and sweet edamame syrup.',
    ingredients: [
      { name: 'Uji Matcha Powder', amount: '2 tsp' },
      { name: 'Oat Milk', amount: '250ml' },
      { name: 'Zunda Edamame Syrup', amount: '30ml' }
    ],
    goldReward: 110,
    chefXP: 30,
    rhythmConfig: {
      bpm: 100,
      targetScore: 1000,
      tolerances: { perfect: 50, great: 120, ok: 200 },
      notePattern: ['🍵', '🫛', '🍵', '✨', '🍵', '🫛']
    }
  },
  {
    id: 'zunda-parfait',
    name: 'Zunda Parfait Deluxe',
    japaneseName: 'ずんだパフェ',
    category: 'desserts',
    badge: 'Deluxe Sweets',
    iconSvg: 'dessert',
    description: 'Layered dessert with green tea gelato, crushed zunda paste, vanilla cream, and dango.',
    ingredients: [
      { name: 'Matcha Gelato', amount: '2 scoops' },
      { name: 'Crushed Zunda Paste', amount: '80g' },
      { name: 'Whipped Cream', amount: '50g' },
      { name: 'Mini Dango Skewer', amount: '1 pc' }
    ],
    goldReward: 220,
    chefXP: 70,
    rhythmConfig: {
      bpm: 135,
      targetScore: 1800,
      tolerances: { perfect: 45, great: 100, ok: 180 },
      notePattern: ['🍨', '🫛', '🍡', '✨', '🍨', '🫛', '🍡', '✨', '🎉']
    }
  },
  {
    id: 'zunda-tempura-udon',
    name: 'Zunda Tempura Udon',
    japaneseName: 'ずんだ天ぷらうどん',
    category: 'entrees',
    badge: 'Hot Special',
    iconSvg: 'entree',
    description: 'Thick sanuki udon noodles in dashi broth topped with crispy edamame & vegetable tempura.',
    ingredients: [
      { name: 'Udon Noodles', amount: '200g' },
      { name: 'Dashi Broth', amount: '350ml' },
      { name: 'Edamame Tempura Kakiage', amount: '2 pcs' },
      { name: 'Scallions', amount: '1 tbsp' }
    ],
    goldReward: 280,
    chefXP: 95,
    rhythmConfig: {
      bpm: 140,
      targetScore: 2200,
      tolerances: { perfect: 40, great: 90, ok: 160 },
      notePattern: ['🍜', '🫛', '🍤', '🍜', '✨', '🫛', '🍤', '🎉']
    }
  }
];
```

### 3.3. Cozy Food Illustrations / Inline SVG Icons
- **SVG Icon Palette**: `#4caf50` (Primary Green), `#8bc34a` (Lime Accent), `#1b5e20` (Dark Contour), `#ffffff` (Mochi/Cream), `#ffd54f` (Golden Tea/Udon).
- **Inline SVG Helper Functions** in `app.js`:
  - `renderSvgIcon('mochi')`: Returns SVG markup for Mochi dish.
  - `renderSvgIcon('tea')`: Returns SVG markup for Tea cup.
  - `renderSvgIcon('dessert')`: Returns SVG markup for Parfait glass.
  - `renderSvgIcon('entree')`: Returns SVG markup for Udon bowl.
  - `renderSvgIcon('pea')`: Returns SVG markup for Edamame pod (`pea_pod.svg`).

### 3.4. Interactive Rhythm Minigame Preview Simulator
- **UI Component Layout**:
  - Located inside `#recipe-detail-panel` on the right side of `Cookbook.app`.
  - Display Elements:
    - **Header**: Active Recipe Title + High Score badge.
    - **Track Canvas / Track Container**: `#rhythm-track` containing target hit zone (`#hit-target-zone` at 15% position).
    - **Control Button**: `<button id="btn-hit-beat" class="win95-btn rhythm-hit-btn">🫛 HIT BEAT (Spacebar)</button>`
    - **Start/Reset Button**: `<button id="btn-start-rhythm" class="win95-btn">▶ Start Cooking Practice</button>`
    - **Live Dashboard**:
      - `Score: <span id="rhythm-score">0</span>`
      - `Combo: <span id="rhythm-combo">x0</span>`
      - `Grade: <span id="rhythm-grade">-</span>`
      - `Feedback Banner`: `<div id="rhythm-feedback" class="feedback-text">READY!</div>`
- **Timing Evaluation Algorithm**:
  ```
  Δt = | currentTime - targetHitTime | (in milliseconds)
  
  if (Δt <= tolerances.perfect) -> PERFECT! (+100 * comboMult), Synth Chime (880Hz)
  else if (Δt <= tolerances.great) -> GREAT! (+75 * comboMult), Synth Pitch (660Hz)
  else if (Δt <= tolerances.ok) -> OK (+40), Synth Click (440Hz)
  else -> MISS! (0 pts, combo reset to 0), Low Thud (150Hz)
  ```
- **Grade Thresholds**:
  - **S Grade**: Accuracy >= 90% or Score >= `targetScore`
  - **A Grade**: Accuracy >= 75%
  - **B Grade**: Accuracy >= 60%
  - **C Grade**: Accuracy < 60%

---

## 4. Split-Pane Layout Architecture for `Cookbook.app`

`site/index.html` window body structure should be updated to a responsive split-pane layout:

```html
<div class="window-body cookbook-body">
    <!-- Left Pane: Search, Category Tags, Recipe Grid -->
    <div class="cookbook-sidebar">
        <div class="recipe-toolbar">
            <input type="search" id="recipe-search" class="win95-input" placeholder="Search recipes (e.g. Mochi, Tea, Udon)...">
            <div class="recipe-filter-tags">
                <button class="win95-btn active" data-filter="all">All</button>
                <button class="win95-btn" data-filter="mochi">Mochi</button>
                <button class="win95-btn" data-filter="tea">Tea</button>
                <button class="win95-btn" data-filter="desserts">Desserts</button>
                <button class="win95-btn" data-filter="entrees">Entrees</button>
            </div>
        </div>
        <div id="recipe-grid" class="recipe-grid-container">
            <!-- Dynamic Recipe Cards Rendered Here -->
        </div>
    </div>

    <!-- Right Pane: Recipe Inspector & Rhythm Minigame Simulator -->
    <div id="cookbook-detail-view" class="cookbook-detail-panel">
        <!-- Dynamic Detail View & Rhythm Simulator Rendered Here -->
    </div>
</div>
```

---

## 5. CSS Extensions (`site/style.css`)

Proposed CSS enhancements to support the split-pane layout, rhythm track, and feedback badges:

```css
/* Cookbook Split Pane Layout */
.cookbook-body {
  display: flex;
  flex-direction: row;
  height: 100%;
  gap: 12px;
  background: #f4f8f3;
  padding: 10px;
  overflow: hidden;
}

.cookbook-sidebar {
  flex: 0 0 280px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border-right: 2px solid var(--win-border-shadow);
  padding-right: 10px;
}

.cookbook-detail-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow-y: auto;
  background: #ffffff;
  border: 2px inset var(--win-border-shadow);
  padding: 12px;
  border-radius: 2px;
}

/* Recipe Card active state */
.recipe-card.selected {
  border-color: #2e7d32;
  background: var(--zunda-pastel);
  box-shadow: inset 0 0 4px rgba(46, 125, 50, 0.3);
}

/* Rhythm Simulator Widget */
.rhythm-widget-container {
  background: #1b2e1e;
  color: #aed581;
  border: 2px solid #2e7d32;
  border-radius: 4px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.rhythm-track-area {
  position: relative;
  height: 48px;
  background: #0d190f;
  border: 1px solid #4caf50;
  overflow: hidden;
  display: flex;
  align-items: center;
}

.rhythm-target-zone {
  position: absolute;
  left: 15%;
  width: 36px;
  height: 100%;
  border-left: 2px dashed #ffeb3b;
  border-right: 2px dashed #ffeb3b;
  background: rgba(255, 235, 59, 0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: #ffeb3b;
  font-weight: bold;
}

.rhythm-note-node {
  position: absolute;
  font-size: 24px;
  transform: translateX(-50%);
  transition: linear;
}

.rhythm-feedback-banner {
  font-family: 'Courier New', monospace;
  font-weight: bold;
  font-size: 16px;
  text-align: center;
  min-height: 24px;
}

.feedback-perfect { color: #00e676; text-shadow: 0 0 6px #00e676; }
.feedback-great   { color: #b9f6ca; text-shadow: 0 0 4px #b9f6ca; }
.feedback-ok      { color: #ffeb3b; }
.feedback-miss    { color: #ff5252; }
```

---

## 6. Verification & Test Plan

1. **Category Tag Verification**: Verify clicking `All`, `Mochi`, `Tea`, `Desserts`, `Entrees` filter buttons instantly updates the visible recipe list.
2. **Search Input Verification**: Type `udon`, `mochi`, `sugar`, or `green` into the search box to verify live matching across dish names, categories, and ingredients.
3. **Recipe Card Selection**: Verify clicking any card updates the right detail pane with dish details, SVG icon, ingredients, rewards, and rhythm widget configuration.
4. **Rhythm Simulator Execution**: Click `▶ Start Cooking Practice` and press `Spacebar` / click `🫛 HIT BEAT`. Confirm hit timing calculations (`PERFECT`, `GREAT`, `OK`, `MISS`), score updating, Web Audio SFX output, and end-of-game grade calculation.
5. **No External Dependencies**: Confirm all assets and scripts run 100% offline without external network calls.

---
