## 2026-07-21T20:45:32Z
You are Worker 1 for Milestone 1 Fix Pass of Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub.
Working Directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1_fix
Target Site Directory: g:\Zundamons-kItchen-V2\site

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your objective:
Apply the 2 fixes to `site/style.css` identified by Challenger 2:
1. Mobile Taskbar Height Variable Fix:
   Inside `@media screen and (max-width: 768px)`, add `:root { --taskbar-height: 42px; }` so that `calc(100vh - var(--taskbar-height))` evaluates to `100vh - 42px`, preventing the 42px taskbar from overlapping mobile modal windows.
2. Cozy Dark Theme Mode CSS Variables:
   Add `[data-theme="zunda-dark"]` CSS token overrides in `site/style.css`:
   ```css
   [data-theme="zunda-dark"] {
     --zunda-dark: #1b5e20;
     --zunda-primary: #2e7d32;
     --zunda-light: #4caf50;
     --zunda-bg: #0a1b0e;
     --zunda-accent: #1e3a23;
     --zunda-pastel: #142819;
     --zunda-hover: #2e7d32;
     --win-bg: #122416;
     --win-content-bg: #0a180e;
     --win-border-light: #2e7d32;
     --win-border-mid: #1b5e20;
     --win-border-dark: #051408;
     --win-border-shadow: #000a03;
     --win-title-bg: linear-gradient(90deg, #1b5e20 0%, #2e7d32 100%);
     --win-title-text: #e8f5e9;
     --win-btn-bg: #1e3a23;
     --win-btn-hover: #2e7d32;
     --win-btn-active: #4caf50;
   }
   ```

Verify your fixes in `site/style.css`. Write `changes.md` and `handoff.md` in `g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m1_fix\`. Send a message when finished.
