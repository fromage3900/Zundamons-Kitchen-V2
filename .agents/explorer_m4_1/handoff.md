# Handoff Report: Milestone 4 — Cookbook.app Specifications & Design

**Author**: Explorer 1  
**Working Directory**: `g:\Zundamons-kItchen-V2\.agents\explorer_m4_1`  
**Date**: 2026-07-21  

---

## 1. Observation

1. **Scope & Plan Requirement**:
   - `g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md` (Lines 36–41): Milestone 4 requires implementing `Cookbook.app` in `site/app.js` with recipe search, ingredient details, rhythm minigame targets, 100% SFW compliance, and zero external dependencies.
2. **Current HTML State**:
   - `site/index.html` (Lines 116–188): `#window-cookbook` currently renders a simple grid of 5 static recipes with filter buttons (`all`, `classic`, `desserts`, `drinks`).
   - `site/index.html` (Lines 501–547): Inline script provides basic `.recipe-card` visibility toggling and an `alert()` box on card click.
3. **Current Window Stack & CSS**:
   - `site/window_manager.js` (Lines 36, 218, 417): `window-cookbook` is already registered as a managed floating desktop window.
   - `site/style.css` (Lines 727–800): Defines `.cookbook-body`, `.recipe-grid-container`, and `.recipe-card` hover states.
4. **Current Assets**:
   - `site/assets/audio_engine.js`: Web Audio API synthesizer ready for UI click and rhythm hit sound generation.
   - `site/assets/pea_pod.svg` and `site/assets/zundamon_mochi.svg`: Existing cozy SVG illustrations.

---

## 2. Logic Chain

1. **Observation**: The current `Cookbook.app` in `site/index.html` uses inline script tags and standard browser `alert()` popups. `site/app.js` does not yet exist.
2. **Step 1**: To meet Milestone 4 objectives, `site/app.js` must be created as a modular application script that manages `Cookbook.app` state, recipe database, rendering, and rhythm minigame physics.
3. **Step 2**: The recipe category filters must be updated from (`all`, `classic`, `desserts`, `drinks`) to the specified set: (`All`, `Mochi`, `Tea`, `Desserts`, `Entrees`).
4. **Step 3**: The single-column grid view should be refactored into a split-pane layout (`.cookbook-sidebar` and `.cookbook-detail-panel`) inside `#window-cookbook`.
5. **Step 4**: The detailed recipe Inspector will render selected recipe metadata: dish title, Japanese name, category badge, ingredient list with quantities, gold rewards (`🪙 Gold`), Chef XP (`⭐ XP`), and cooking score targets.
6. **Step 5**: An interactive rhythm minigame simulator widget must be embedded into the recipe detail panel. Notes scroll across a track toward a hit zone at a designated BPM. Pressing `Spacebar` or clicking `🫛 HIT BEAT` evaluates timing errors against `Perfect` (±50ms), `Great` (±120ms), and `Ok` (±200ms) tolerances, calculating live score, combo multipliers, Web Audio hit feedback, and end-of-game S/A/B/C letter grades.

---

## 3. Caveats

- **Script Tag Inclusion**: `site/index.html` must include `<script src="app.js"></script>` before the closing `</body>` tag (after `terminal.js` or `window_manager.js`).
- **Inline Audio Synthesis**: Rhythm hit audio triggers should use `window.ZundaAudio` (or synthesize tone frequencies via native `AudioContext`) to preserve zero external audio file dependencies.
- **Responsive Layout**: On mobile viewports (<640px), the split-pane layout should stack vertically or convert to tabbed switching so the rhythm track remains usable on small screens.

---

## 4. Conclusion

`Cookbook.app` specifications and design architecture are fully analyzed and ready for implementation. The comprehensive design specification report is saved in `g:\Zundamons-kItchen-V2\.agents\explorer_m4_1\analysis.md`.

Key deliverables established for the Implementer:
1. Category tag update (`All`, `Mochi`, `Tea`, `Desserts`, `Entrees`).
2. Recipe schema with 4 default recipes (Zunda Mochi, Zunda Matcha Latte, Zunda Parfait Deluxe, Zunda Tempura Udon).
3. Split-pane layout structure in `site/index.html` and `site/style.css`.
4. Rhythm minigame simulator widget with `Perfect`/`Great`/`Ok` tolerance calculations, combo counters, Web Audio sound synthesis, and local high score tracking.

---

## 5. Verification Method

1. **File Existence Check**:
   - Confirm `g:\Zundamons-kItchen-V2\.agents\explorer_m4_1\analysis.md` exists and contains complete design specs.
2. **HTML & CSS Verification**:
   - Inspect `site/index.html` for `#window-cookbook` split-pane layout elements (`.cookbook-sidebar`, `.cookbook-detail-panel`).
   - Inspect `site/style.css` for `.rhythm-widget-container`, `.rhythm-track-area`, and `.rhythm-target-zone`.
3. **Application Logic Verification**:
   - Load `site/index.html` in a web browser.
   - Open `Cookbook.app`. Test category buttons (`Mochi`, `Tea`, `Desserts`, `Entrees`) and keyword search.
   - Select a recipe, start the cooking practice simulator, press `Spacebar`, and verify score increase, hit feedback (`PERFECT!`, `GREAT!`), synth sound, and final grade calculation.
