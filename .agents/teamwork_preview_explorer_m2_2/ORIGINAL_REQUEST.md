## 2026-07-21T17:59:06Z
<USER_REQUEST>
You are Explorer 2 for Milestone 2 (R2: Cooking & Rhythm Minigame System).
Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2
Project root: g:\Zundamons-kItchen-V2
Plan file: g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md
Workspace rules: g:\Zundamons-kItchen-V2\AGENTS.md

Task:
1. Audit server-side cooking validation (src/server/Services/CookingValidationSystem.lua and src/shared/ConfigurationFiles/Recipes.lua).
2. Examine ingredient requirements, recipe crafting checks, note validation algorithms, anti-exploit score verification, and dish creation.
3. Check AGENTS.md Rule 4 import path consistency (ServerScriptService.Services... without script.Parent or .Server.).
4. Identify missing recipe definitions, validation exploits, or inventory deduction bugs.
5. Report findings to g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\handoff.md.
</USER_REQUEST>

## 2026-07-21T20:46:04Z
<USER_REQUEST>
You are Explorer 2 for Milestone 2 of Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub.
Working Directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2
Target Site Directory: g:\Zundamons-kItchen-V2\site

Your task:
Analyze and design the Focus Stacking, Taskbar Sync, and State Engine architecture for `site/window_manager.js`.
Requirements to cover:
1. Z-Index Depth Stack & Active Focus Management:
   - Dynamic `z-index` calculation when clicking any part of a window.
   - Updating `.window-active` and `.window-inactive` CSS classes across all open windows.
   - Active Focus Fallback: When a window is closed or minimized, automatically transfer focus to the top-most remaining visible window (`.window-active`).
2. Minimize, Maximize & Restore State Engine:
   - Minimize: Hide window content (`.window-minimized` / `display: none`), retain taskbar button in `#taskbar-windows`, remove active state.
   - Maximize / Restore: Toggle full desktop viewport size vs original cascades, update button icon (`□` / `🗗`).
   - Taskbar Sync: Taskbar window buttons MUST retain minimized windows so users can click to restore/un-minimize. Clicking an active window's taskbar button minimizes it; clicking an inactive/minimized window's taskbar button restores & focuses it.
3. Keyboard Shortcuts:
   - Listen for `Ctrl+Esc` and `Escape` keypresses to toggle the Start Menu (`#start-menu`).

Write your specification in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\analysis.md` and handoff in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_explorer_m2_2\handoff.md`. Send a message when finished.
</USER_REQUEST>
