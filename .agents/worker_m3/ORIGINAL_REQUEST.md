## 2026-07-21T20:52:12Z
<USER_REQUEST>
You are Worker 3 for Milestone 3 (Interactive Phosphor Web Terminal ZundaCLI.exe).
Working directory for your metadata: g:\Zundamons-kItchen-V2\.agents\worker_m3
Target file to create: g:\Zundamons-kItchen-V2\site\terminal.js
Target files to update: g:\Zundamons-kItchen-V2\site\index.html, g:\Zundamons-kItchen-V2\site\style.css

Explorer reports to follow:
- Explorer 1: g:\Zundamons-kItchen-V2\.agents\explorer_m3_1\analysis.md
- Explorer 2: g:\Zundamons-kItchen-V2\.agents\explorer_m3_2\analysis.md
- Explorer 3: g:\Zundamons-kItchen-V2\.agents\explorer_m3_3\analysis.md

Task:
1. Create `site/terminal.js` implementing the `ZundaTerminal` ES6 class:
   - Command parser, history buffer with Up/Down arrow key traversal, Tab auto-complete (with LCP math & match listing).
   - Prompt state (`zunda>`), command echo, auto-scroll with manual scrolllock detection (`.cli-scroll-bottom-btn`).
   - Complete command suite: `help`, `info`/`about`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme [mode]`, `rojo`, `wally`.
   - Secret Zundamon easter eggs: `nanoda`, `mochi`, `edamame`, `zunda`, `secret`, `dance`, `matrix`.
   - Theme switching (`classic-green`, `amber`, `matrix`, `cozy-pea`) modifying `data-theme` on `#window-zundacli` or `.cli-body`.
   - Web Audio API integration using `window.playKeySFX`, `window.playClickSFX`, `window.toggleCozyBGM`, and `ZundaAudio`.
2. Update `site/index.html`:
   - Remove the old primitive inline CLI script (lines 487-553).
   - Add `<script src="terminal.js"></script>` right after `audio_engine.js` / `window_manager.js`.
   - Ensure `#cli-output`, `#cli-input-form`, `#cli-input`, `.cli-prompt-label` match terminal.js bindings.
   - Add mobile touch helper toolbar (`.cli-mobile-toolbar`) with virtual `Tab`, `▲`, `▼` buttons.
3. Update `site/style.css`:
   - Add CRT phosphor terminal theme variables (`classic-green`, `amber`, `matrix`, `cozy-pea`), inner scanline overlay `.cli-scanline-overlay`, micro-flicker keyframe animation `@keyframes crtPhosphorFlicker`, colored status tags (`.cli-tag-ok`, `.cli-tag-recipe`, `.cli-tag-audio`, `.cli-tag-info`, `.cli-tag-warn`, `.cli-tag-error`, `.cli-tag-system`), `.cli-table` styling, and `.cli-mobile-toolbar` styling.
4. Verification:
   - Run `node -c site/terminal.js` to ensure 0 syntax errors.
   - Perform node simulation tests verifying command execution, history, autocomplete, themes, and easter eggs.

Write your handoff report in `g:\Zundamons-kItchen-V2\.agents\worker_m3\handoff.md` and report back via send_message.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
</USER_REQUEST>
