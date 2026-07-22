## 2026-07-22T04:28:24Z
You are Explorer 1 for Zundamon's Kitchen V2 - Milestone 2.
Working directory: `g:\Zundamons-kItchen-V2\.agents\explorer_m2_1`

Task:
Analyze `site/window_manager.js` requirements for managing all 7 interactive desktop app windows (`window-zundacli`, `window-cookbook`, `window-vntalk`, `window-zundamon`, `window-promos`, `window-calculator`, `window-updates`).

Formulate a detailed execution plan covering:
1. Window Lifecycle: Opening, closing, minimizing to taskbar, maximizing/restoring, focusing (`z-index` stack incrementing).
2. Drag & Touch Engine: Drag-to-move header handles with viewport clamping (preventing window titlebars from moving out of bounds), mouse and touch event listeners (`touchstart`, `touchmove`, `touchend`).
3. Focus Fallback Logic: When active window is closed or minimized, fallback focus to the next highest z-index window in the stack.
4. Taskbar & Start Menu Sync: Dynamic taskbar window buttons sync, active state toggling, start menu popover toggling with `Ctrl+Esc`, closing active popovers on `Escape`.

Write your findings and blueprint to `g:\Zundamons-kItchen-V2\.agents\explorer_m2_1\analysis.md` and send a message back.
