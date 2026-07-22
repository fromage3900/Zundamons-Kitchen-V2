## 2026-07-22T04:35:18Z
You are Worker 3 for Zundamon's Kitchen V2 - Milestone 3.
Working directory: `g:\Zundamons-kItchen-V2\.agents\worker_m3`

Task:
Implement Milestone 3: Pastel Web Terminal (`ZundaCLI.exe`), Promos.app, Calculator.app & Updates.log.

Refer to the Explorer analysis reports:
- Explorer 1 Terminal Engine Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m3_1\analysis.md`
- Explorer 2 Utility Apps Engine Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m3_2\analysis.md`
- Explorer 3 Terminal & Utility Apps CSS Blueprint: `g:\Zundamons-kItchen-V2\.agents\explorer_m3_3\analysis.md`

Your tasks:
1. Update `g:\Zundamons-kItchen-V2\site\terminal.js` (`ZundaCLI.exe`):
   - Pastel terminal command parser with `zunda> ` prompt and glowing cursor.
   - Up/Down arrow command history navigation and Tab key autocomplete.
   - Keypress audio typing feedback (`ZundaAudio.playKey()`) and command execution audio (`ZundaAudio.playWinSFX()`).
   - Implement commands: `help`, `info`/`about`, `recipes`, `spirits`, `quests`, `promos`, `calc`/`calculator`, `clear`, `theme` (pastel, sakura, zunda, dark), `version`, `lore`, `play`, `music`, and easter eggs (`zundamon`, `nanoda`, `mochi`, `nikki`, `secret`).
2. Update `g:\Zundamons-kItchen-V2\site\app.js` & `g:\Zundamons-kItchen-V2\site\index.html`:
   - `Promos.app`: Code input `#promo-input`, `#promo-redeem-btn`, active codes (`ZUNDAMOCHI2026`, `SOUPSEASON`, `HYBRIDECS`), 1-click copy & redeem handlers, toast notifications, `localStorage` memory (`zunda_redeemed_codes`).
   - `Calculator.app`: Recipe selector `#calc-dish-select`, quantity counter `#calc-qty` (-10, -1, +1, +10, +50 buttons), unit & total cost/sell price displays (`#res-cost`, `#res-sell`, `#res-profit`), margin/ROI % badge.
   - `Updates.log`: Patch notes & Matter ECS release log viewer displaying v2.4.0 release highlights, hybrid ECS architecture, rhythm cooking validation updates, bug fixes.
3. Update `g:\Zundamons-kItchen-V2\site\style.css`:
   - Add styles for `.terminal-window`, `.terminal-output`, `.term-prompt`, `.term-input`, glowing cursor `@keyframes blink`, `.term-pink`, `.term-green`, `.term-cyan`, `.term-yellow`.
   - Add styles for `Promos.app` code redeemer cards & inputs, `Calculator.app` form & profit display cards, `Updates.log` patch version tags & ecs badges.
4. Verify syntax with `node -c site/terminal.js; node -c site/app.js; node -c site/window_manager.js; node -c site/sync_site.js`.
5. Run `node site/sync_site.js` to synchronize updated web assets from `site/` to `docs/`.

Write your changes to `g:\Zundamons-kItchen-V2\.agents\worker_m3\changes.md` and `handoff.md` and send a message back.
