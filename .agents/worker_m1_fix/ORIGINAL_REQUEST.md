## 2026-07-22T08:26:52Z

<USER_REQUEST>
You are Worker 1 for Zundamon's Kitchen V2 - Milestone 1 Fix Pass.
Working directory: `g:\Zundamons-kItchen-V2\.agents\worker_m1_fix`

Task:
Apply targeted fixes identified by Reviewers and Challengers for Milestone 1:

1. Fix Syntax Error in `site/terminal.js`:
   - Inspect lines 640-646 in `site/terminal.js`. Remove dangling `+` operator before `cmdPromos()`.
   - Run `node -c site/terminal.js` to verify zero syntax errors.

2. Fix Particle Canvas ID Mismatch in `site/app.js` & `site/index.html`:
   - In `site/app.js` line 1462, update canvas getter:
     `const canvas = document.getElementById('star-canvas') || document.getElementById('star-sparkle-canvas');`
   - In `site/index.html`, ensure `<canvas id="star-canvas" class="starburst-canvas"></canvas>` is cleanly present.

3. Fix Duplicate DOM ID & Missing `#recipes` Anchor in `site/index.html`:
   - Remove duplicate `id="promos"` on promo modal window (ensure section is `<section id="promos">` and modal window is `<div class="window window-promos" id="window-promos">`).
   - Ensure navbar `<a href="#recipes">` has a corresponding section anchor target: add `id="recipes"` to Cookbook section / section header or container.

4. Fix Calculator App Form Elements in `site/index.html` & Clean `window_manager.js`:
   - Inside `window-calculator` in `site/index.html`, ensure form elements `#calc-dish-select`, `#res-cost`, and `#res-sell` exist so `MainApp.updateCalc()` runs properly.
   - Clean up any stale `window-quickstart` references in `site/window_manager.js`.

5. Run Syntax Check & Dual Deployment Sync:
   - Run `node -c site/sync_site.js; node -c site/app.js; node -c site/terminal.js; node -c site/window_manager.js`
   - Run `node site/sync_site.js` to re-synchronize updated web assets from `site/` to `docs/`.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results or create dummy facades.

Write your changes to `g:\Zundamons-kItchen-V2\.agents\worker_m1_fix\changes.md` and `handoff.md` and send a message back.
</USER_REQUEST>
