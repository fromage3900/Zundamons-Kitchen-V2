## 2026-07-21T20:48:22Z
You are Reviewer 2 for Milestone 2 of Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub.
Working Directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m2_2
Target Site Directory: g:\Zundamons-kItchen-V2\site

Your task:
Review window lifecycle, state engine, and Roblox export features in `site/window_manager.js`:
1. Verify Z-index depth stack (100 to 8999) and active state styling (`.window-active` / `.window-inactive`).
2. Verify Active Focus Fallback (`transferFocusToTopVisibleWindow()`) when closing or minimizing windows.
3. Verify Taskbar Sync: Taskbar buttons MUST retain minimized windows (`#taskbar-windows`). Click matrix: active window -> minimizes; inactive or minimized window -> restores & focuses.
4. Verify Keyboard Shortcuts: `Ctrl+Esc` and `Escape` toggling/closing Start Menu (`#start-menu`).
5. Verify `WindowManager.exportScreenGuiLayout()` metadata format maps DOM layout to Roblox ScreenGui frame hierarchy.

Document your review in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m2_2\review.md` and deliver `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m2_2\handoff.md`. Send a message to orchestrator with your verdict (APPROVED / REJECTED).
