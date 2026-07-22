# Milestone 3 Analysis & Blueprint — Promos.app, Calculator.app & Updates.log

**Target Directory**: `g:\Zundamons-kItchen-V2\`  
**Target Files**: `site/index.html`, `site/app.js`, `site/style.css`, `site/terminal.js`  
**Author**: Explorer 2 (Milestone 3)  
**Date**: 2026-07-22  

---

## 1. Observation

### 1.1 Existing Architecture & File Audit
Direct inspection of `site/index.html`, `site/app.js`, `site/style.css`, and `site/terminal.js` reveals the following findings regarding the 3 targeted desktop applications:

#### A. Promos.app (`#window-promos`)
* **Current State in `site/index.html` (Lines 429–447)**:
  * The window contains a basic heading `<h3>🎁 Active Roblox Promo Codes</h3>` and three standalone copy buttons with `data-code` attributes (`ZUNDAMOCHI2026`, `SOUPSEASON`, `HYBRIDECS`).
  * **Missing Elements**:
    1. No interactive text input field (`#promo-input`) for manually entering or pasting codes.
    2. No "Redeem" action button (`#promo-redeem-btn`) to submit typed promo codes.
    3. No individual 1-click "Redeem Code" buttons on code cards (only "Copy").
    4. No code reward detail cards (only raw buttons without reward descriptions, expiry dates, or icons).
    5. No state persistence using `localStorage` / `sessionStorage` for redeemed codes (`zunda_redeemed_codes`), meaning codes cannot be tracked as "REDEEMED ✓" or disabled once claimed.
* **Current State in `site/app.js` (Lines 1185–1224)**:
  * `initPromosApp()` attaches click handlers to `.copy-code-btn` elements to copy code strings to `navigator.clipboard` and pop up a generic toast notification (`Code ZUNDAMOCHI2026 copied to clipboard! ✨`).
  * **Missing Logic**:
    * No promo validation dictionary / data structure mapping code strings to rewards and status.
    * No redeem code handler, input validation (trim/uppercase handling), error toasts ("Invalid Code", "Code Already Redeemed"), or successful redemption memory storage.

#### B. Calculator.app (`#window-calculator`)
* **Current State in `site/index.html` (Lines 449–482)**:
  * Contains a recipe `<select id="calc-dish-select">` with 4 hardcoded `<option>` elements containing hardcoded `data-cost` and `data-sell` attributes:
    * `zunda-mochi` (Cost: 20, Sell: 120)
    * `edamame-parfait` (Cost: 50, Sell: 300)
    * `zunda-shake` (Cost: 15, Sell: 80)
    * `dango-trio` (Cost: 30, Sell: 180)
  * Contains a quantity input `<input type="number" id="calc-qty" value="10">`.
  * Results panel displays: `#res-cost` (Total Crafting Cost), `#res-sell` (Estimated Revenue), `#res-profit` (Estimated Net Profit).
  * **Missing Elements**:
    1. Dropdown options are hardcoded in HTML rather than dynamically populated from `RECIPES` data array in `site/app.js` (which contains `Zunda Mochi`, `Zunda Matcha Latte`, `Zunda Parfait Deluxe`, `Zunda Tempura Udon`).
    2. Missing quick quantity adjustment controls (e.g., `-`, `+`, `+10`, `+50`, `MAX` buttons).
    3. Missing explicit Cost Per Unit and Sell Price Per Unit metric callouts alongside total sums.
    4. Missing **Profit Margin Indicator** (e.g., ROI % `(Profit/Cost)*100`, Profit Margin % `(Profit/Revenue)*100`, and a visual rating badge such as `🌟 EXCELLENT MARGIN (500% ROI)`).

#### C. Updates.log (`#window-updates`)
* **Current State in `site/index.html` (Lines 484–507)**:
  * Contains a single static bullet list with 5 high-level summary points under `Version 2.4.0 Patch Notes (Hybrid ECS Release)`.
  * **Missing Elements**:
    1. Lacks categorized tabs/sections detailing specific engine components:
       * **Release Highlights** (Matter ECS integration, 60fps loop, Y2K UI).
       * **Hybrid ECS Architecture** (Query pipelines, state replication between Server/Client, component storage).
       * **Rhythm Cooking Validation Updates** (Audio beat sync tolerances, S-Rank accuracy thresholds, voice synthesis).
       * **Bug Fixes & System Stability** (UI decoupling, `ResetOnSpawn = false`, `$ignoreUnknownInstances` level preservation, memory leak cleanup).
    2. No version timeline / selector (e.g., v2.4.0, v2.3.0, v2.2.0) to browse historical patch notes.
    3. Static HTML layout without collapsible change categories or rich status tags (`[ECS]`, `[Rhythm]`, `[UI/UX]`, `[Rojo]`).

---

## 2. Logic Chain

1. **User Experience & Requirements Alignment**:
   * Desktop simulation apps must feel functional, interactive, and responsive, matching the Y2K Windows 95 aesthetic.
   * `Promos.app` needs a full redemption cycle: Users can copy active codes or paste/type them into an input field, click "Redeem", receive immediate feedback via toast notifications, and see claimed codes marked as `REDEEMED ✓` across page refreshes.
   * `Calculator.app` must dynamically sync with `RECIPES` in `site/app.js` so any recipe additions/updates automatically reflect in the crafter calculator. Showing ROI % and Profit Margin % provides player utility for game planning.
   * `Updates.log` serves as both a dev log and patch notes reader. Structuring notes into clear tabs (Highlights, Architecture, Rhythm Engine, Bug Fixes) with version history creates an authentic software log viewer.

2. **Data Consistency**:
   * `RECIPES` array in `site/app.js` already defines `id`, `name`, `japaneseName`, `goldReward`, etc. We will add explicit `craftingCost` (e.g., 25 Gold) and `baseSellPrice` (e.g., 150 Gold) properties to `RECIPES` items so `CalculatorApp` stays in 100% sync with `CookbookApp`.
   * Promo codes data structure in `site/app.js` will specify code, rewards, expiration status, and description.
   * `localStorage` keys will use clean, prefixed naming conventions (`zunda_redeemed_codes`, `zunda_calc_last_dish`).

---

## 3. Caveats

1. **Browser Storage Fallback**:
   * If `localStorage` is disabled or throws `SecurityError` (e.g. strict third-party cookie blocking or private browsing), code memory must gracefully fall back to an in-memory `Set()` / JS object so app interaction never crashes.
2. **Read-Only Explorer Mandate**:
   * This analysis is read-only. Source changes will be executed by the assigned Implementer agent following this blueprint.

---

## 4. Conclusion & Detailed Execution Blueprint

### 4.1 `Promos.app` Blueprint & Implementation Plan

#### Data Structure (`PROMO_CODES`) in `site/app.js`
```javascript
const PROMO_CODES = [
  {
    code: 'ZUNDAMOCHI2026',
    rewardText: '+500 Gold, 10x Fresh Zunda Mochi, 1x Rare Chef Apron',
    icon: '🍡',
    gold: 500,
    items: ['10x Zunda Mochi', '1x Rare Chef Apron'],
    category: 'Featured'
  },
  {
    code: 'SOUPSEASON',
    rewardText: '+1,000 Kitchen EXP, 5x Wild Mushroom Pack',
    icon: '🍄',
    exp: 1000,
    items: ['5x Wild Mushroom Pack'],
    category: 'Seasonal'
  },
  {
    code: 'HYBRIDECS',
    rewardText: '+250 Gold, Matter ECS Developer Badge',
    icon: '⚡',
    gold: 250,
    items: ['Matter ECS Developer Badge'],
    category: 'System'
  }
];
```

#### HTML Markup Blueprint (`#window-promos` in `site/index.html`)
```html
<div class="window window-promos hidden" id="window-promos" data-window-id="promos" style="top: 140px; left: 200px; width: 620px; height: 480px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">🎁</span>
            <span class="window-title-text">Promos.app — Roblox Promo Codes</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize">□</button>
            <button class="win-btn win-close" data-action="close" title="Close">✕</button>
        </div>
    </div>
    <div class="window-body promos-body">
        <!-- Interactive Redeem Bar -->
        <div class="promo-redeem-box bevel-inset">
            <label for="promo-input" class="promo-label">🎁 Enter Code:</label>
            <div class="promo-input-group">
                <input type="text" id="promo-input" class="win95-input" placeholder="e.g. ZUNDAMOCHI2026" autocomplete="off" spellcheck="false">
                <button id="promo-redeem-btn" class="win95-btn btn-candy">Redeem Code</button>
            </div>
            <div id="promo-status-msg" class="promo-status-msg"></div>
        </div>

        <!-- Active Codes List -->
        <h4 class="promo-section-title">✨ Active Available Codes</h4>
        <div id="promo-codes-list" class="codes-grid"></div>
    </div>
</div>
```

#### Class Specification: `PromosApp` in `site/app.js`
* **Responsibilities**:
  1. Read redeemed codes array from `localStorage.getItem('zunda_redeemed_codes')`.
  2. Dynamically render promo code cards with `Copy Code` and `Redeem` buttons.
  3. Validate input in `#promo-input` against `PROMO_CODES`.
  4. Display toast notifications and update UI state on redemption.
  5. Play appropriate voice line / SFX (`hit_perfect` on success, `hit_miss` on invalid/already redeemed).

---

### 4.2 `Calculator.app` Blueprint & Implementation Plan

#### HTML Markup Blueprint (`#window-calculator` in `site/index.html`)
```html
<section id="window-calculator" class="window hidden" data-window-id="calculator" style="top: 160px; left: 240px; width: 580px; height: 460px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">🧮</span>
            <span class="window-title-text">Calculator.app — Dish Profit Calculator</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize">□</button>
            <button class="win-btn win-close" data-action="close" title="Close">✕</button>
        </div>
    </div>
    <div class="window-body calc-body">
        <div class="calc-panel bevel-inset" style="padding: 14px; background: #ffffff;">
            <!-- Recipe Selector -->
            <div class="calc-form-group">
                <label for="calc-dish-select" class="calc-label">📖 Select Recipe:</label>
                <select id="calc-dish-select" class="win95-input calc-select"></select>
            </div>

            <!-- Quantity Counter with Preset Buttons -->
            <div class="calc-form-group">
                <label for="calc-qty" class="calc-label">🍳 Quantity to Cook:</label>
                <div class="qty-control-wrapper">
                    <button class="win95-btn qty-btn" data-qty-delta="-10">-10</button>
                    <button class="win95-btn qty-btn" data-qty-delta="-1">-1</button>
                    <input type="number" id="calc-qty" value="10" min="1" max="999" class="win95-input qty-input">
                    <button class="win95-btn qty-btn" data-qty-delta="1">+1</button>
                    <button class="win95-btn qty-btn" data-qty-delta="10">+10</button>
                    <button class="win95-btn qty-btn" data-qty-delta="50">+50</button>
                </div>
            </div>

            <!-- Unit Cost & Sell Rates Breakdown -->
            <div class="calc-unit-rates-grid">
                <div class="rate-card">
                    <span class="rate-label">Unit Cost</span>
                    <span id="unit-cost-val" class="rate-val">20 Gold</span>
                </div>
                <div class="rate-card">
                    <span class="rate-label">Unit Sell Price</span>
                    <span id="unit-sell-val" class="rate-val">150 Gold</span>
                </div>
                <div class="rate-card">
                    <span class="rate-label">Profit / Unit</span>
                    <span id="unit-profit-val" class="rate-val">+130 Gold</span>
                </div>
            </div>

            <!-- Calculation Summary Results -->
            <div class="calc-results-card">
                <div class="res-row">
                    <span>Total Crafting Cost:</span>
                    <strong id="res-cost" class="res-num cost-num">200 Gold</strong>
                </div>
                <div class="res-row">
                    <span>Estimated Revenue:</span>
                    <strong id="res-sell" class="res-num sell-num">1,500 Gold</strong>
                </div>
                <div class="res-row main-profit-row">
                    <span>Estimated Net Profit:</span>
                    <strong id="res-profit" class="res-num profit-num">+1,300 Gold</strong>
                </div>
                <div class="margin-indicator-box">
                    <span class="margin-label">Profit Margin / ROI:</span>
                    <span id="calc-margin-badge" class="margin-badge margin-high">86.7% Margin (650% ROI) 🌟</span>
                </div>
            </div>
        </div>
    </div>
</section>
```

#### Class Specification: `CalculatorApp` in `site/app.js`
```javascript
class CalculatorApp {
  init() {
    this.dishSelect = document.getElementById('calc-dish-select');
    this.qtyInput = document.getElementById('calc-qty');
    this.resCost = document.getElementById('res-cost');
    this.resSell = document.getElementById('res-sell');
    this.resProfit = document.getElementById('res-profit');
    this.unitCost = document.getElementById('unit-cost-val');
    this.unitSell = document.getElementById('unit-sell-val');
    this.unitProfit = document.getElementById('unit-profit-val');
    this.marginBadge = document.getElementById('calc-margin-badge');

    this.populateSelectOptions();
    this.bindEvents();
    this.calculate();
  }

  populateSelectOptions() {
    if (!this.dishSelect) return;
    this.dishSelect.innerHTML = RECIPES.map(recipe => `
      <option value="${recipe.id}" data-cost="${recipe.craftingCost || 20}" data-sell="${recipe.goldReward || 150}">
        ${recipe.name} (${recipe.japaneseName}) — Cost: ${recipe.craftingCost || 20}g, Sell: ${recipe.goldReward || 150}g
      </option>
    `).join('');
  }

  calculate() {
    // Math formulas:
    // totalCost = costPerUnit * qty
    // totalRevenue = sellPerUnit * qty
    // netProfit = totalRevenue - totalCost
    // profitMarginPct = (netProfit / totalRevenue) * 100
    // roiPct = (netProfit / totalCost) * 100
  }
}
```

---

### 4.3 `Updates.log` Blueprint & Implementation Plan

#### HTML Markup Blueprint (`#window-updates` in `site/index.html`)
```html
<section id="window-updates" class="window hidden" data-window-id="updates" style="top: 180px; left: 280px; width: 680px; height: 500px;" tabindex="0">
    <div class="window-header">
        <div class="window-title">
            <span class="window-icon">📜</span>
            <span class="window-title-text">Updates.log — Patch Notes & ECS Engine Log</span>
        </div>
        <div class="window-controls">
            <button class="win-btn win-minimize" data-action="minimize" title="Minimize">_</button>
            <button class="win-btn win-maximize" data-action="maximize" title="Maximize">□</button>
            <button class="win-btn win-close" data-action="close" title="Close">✕</button>
        </div>
    </div>
    <div class="window-body updates-body">
        <!-- Updates Toolbar with Version Selector & Category Tabs -->
        <div class="updates-toolbar">
            <div class="version-select-box">
                <label for="updates-version-select">Version:</label>
                <select id="updates-version-select" class="win95-input">
                    <option value="v2.4.0" selected>v2.4.0 — Hybrid ECS & UI Overhaul (Latest)</option>
                    <option value="v2.3.0">v2.3.0 — Rhythm Minigame & Voice Synth</option>
                    <option value="v2.2.0">v2.2.0 — Companion Spirits & Gathering</option>
                </select>
            </div>
            <div class="updates-tabs">
                <button class="win95-btn update-tab-btn active" data-tab="all">All Logs</button>
                <button class="win95-btn update-tab-btn" data-tab="ecs">⚡ Hybrid ECS</button>
                <button class="win95-btn update-tab-btn" data-tab="rhythm">🎵 Rhythm Engine</button>
                <button class="win95-btn update-tab-btn" data-tab="fixes">🐛 Bug Fixes</button>
            </div>
        </div>

        <!-- Log List Container -->
        <div id="updates-log-content" class="updates-log-content bevel-inset">
            <!-- Dynamic Log Items Rendered Here -->
        </div>
    </div>
</section>
```

#### Detailed Patch Notes Data Structure (`UPDATES_LOG_DATA`) in `site/app.js`
```javascript
const UPDATES_LOG_DATA = {
  'v2.4.0': {
    version: 'v2.4.0',
    title: 'Hybrid ECS & Y2K Desktop Launch',
    date: '2026-07-22',
    highlights: [
      'Integrated Matter ECS query pipeline for 60fps server-side updates in Luau.',
      'Full $ignoreUnknownInstances level preservation sync enabled for Rojo 7.7.0.',
      'Kawaii PC Desktop workspace with 7 interactive application windows and CRT monitor overlay.'
    ],
    sections: [
      {
        category: 'ecs',
        tag: '⚡ HYBRID ECS',
        title: 'Matter ECS Architecture & Replication',
        items: [
          'Implemented entity query loops running at fixed 60Hz tick rates in ServerScriptService.systems.',
          'Created ClientGuiBootstrap to decouple client UI from script.Parent and handle respawn persistent state.',
          'Configured Wally packages (Matter, ProfileService, ReplicaService) in default.project.json.'
        ]
      },
      {
        category: 'rhythm',
        tag: '🎵 RHYTHM ENGINE',
        title: 'Beat Sync & S-Rank Validation',
        items: [
          'Added 4 signature recipes with Web Audio API beat sync (Zunda Mochi, Latte, Parfait, Udon).',
          'Calibrated hit tolerances (Perfect: ±50ms, Great: ±120ms, OK: ±200ms).',
          'Integrated procedural voice synthesizer for catchphrases on Perfect combos.'
        ]
      },
      {
        category: 'fixes',
        tag: '🐛 BUG FIXES',
        title: 'System Stability & Rojo Fixes',
        items: [
          'Fixed studio level geometry wipe by adding $ignoreUnknownInstances: true under Workspace in default.project.json.',
          'Resolved memory leak in rhythm loop by cleaning up frame animation listeners upon window close.',
          'Fixed ScreenGui ResetOnSpawn behavior for modal dialogue and companion UI widgets.'
        ]
      }
    ]
  }
};
```

---

## 5. Verification Method

To verify the implementation once complete:
1. Open `site/index.html` in browser (or via local HTTP server).
2. Test `Promos.app`:
   - Click "Copy Code" on `ZUNDAMOCHI2026` -> Verify toast message pops up and clipboard contains string.
   - Click "Redeem Code" -> Verify status updates to "REDEEMED ✓", toast shows reward message, voice line plays, and refreshing the page keeps code marked as redeemed (`localStorage`).
   - Type an invalid code like `INVALID123` into `#promo-input` and click Redeem -> Verify error toast/status message.
3. Test `Calculator.app`:
   - Select `Zunda Mochi` -> Verify Unit Cost displays `20g`, Unit Sell displays `150g`, Unit Profit displays `+130g`.
   - Click `+10` quantity -> Qty changes to `20`, Total Cost updates to `400g`, Revenue to `3,000g`, Net Profit to `+2,600g`.
   - Check Profit Margin badge -> Displays correct % Margin and ROI rating badge.
4. Test `Updates.log`:
   - Click through category tabs (`All Logs`, `⚡ Hybrid ECS`, `🎵 Rhythm Engine`, `🐛 Bug Fixes`) -> Verify filtered log entries match selected category.
   - Switch version dropdown from `v2.4.0` to `v2.3.0` -> Verify log content updates smoothly.
