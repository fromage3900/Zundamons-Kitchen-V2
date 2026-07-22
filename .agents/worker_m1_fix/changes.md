# Milestone 1 Fix Pass — Changes Log

## Modified Files

### 1. `site/terminal.js`
- **Issue**: Syntax error at line 645 (`cmdPromos()`) due to an unclosed `card` string concatenation ending with a dangling `+` operator in `cmdLore()`, and orphaned template literals following `cmdCalc()`.
- **Fix**: Re-assembled `cmdLore()` to cleanly construct `card` with `quote`, `note`, closing `</div>`, `this.appendOutput(card);`, and method closing brace. Removed orphaned code fragments after `cmdCalc()`.

### 2. `site/app.js`
- **Issue**: Particle canvas getter in `initParticleCanvas()` looked only for `star-sparkle-canvas`, failing when `star-canvas` was used in DOM.
- **Fix**: Updated getter at line 1462 to: `const canvas = document.getElementById('star-canvas') || document.getElementById('star-sparkle-canvas');`.
- **Cleanup**: Updated `executeAction('open_quickstart')` to target `'window-updates'`.

### 3. `site/index.html`
- **Issue**: Duplicate ID reference and missing `#recipes` section anchor. Missing calculator form elements `#calc-dish-select`, `#res-cost`, `#res-sell`.
- **Fix**:
  - Added `id="recipes"` to Cookbook window header (`<div class="window-header" id="recipes">`) matching `<a href="#recipes">`.
  - Updated promo modal container element to `<div class="window window-promos hidden" id="window-promos" ...>` ensuring `<section id="promos">` remains unique for the page anchor.
  - Added form elements `#calc-dish-select` (with recipe options having `data-cost` and `data-sell` attributes), `#res-cost`, and `#res-sell` to `calc-body` inside `window-calculator`.

### 4. `site/window_manager.js`
- **Issue**: Stale `window-quickstart` ID in `managedIds`, `managedOrder`, and `targetIds` arrays.
- **Fix**: Updated all three arrays to list active window IDs: `['window-zundacli', 'window-cookbook', 'window-vntalk', 'window-zundamon', 'window-promos', 'window-calculator', 'window-updates']`.

### 5. `docs/` Assets (via `node site/sync_site.js`)
- Re-synchronized web assets from `site/` to `docs/`.
- 4 files updated: `app.js`, `index.html`, `terminal.js`, `window_manager.js`.
