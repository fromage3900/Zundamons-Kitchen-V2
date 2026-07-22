## 2026-07-22T04:22:27Z
<USER_REQUEST>
You are Explorer 3 for Zundamon's Kitchen V2 - Milestone 1.
Your working directory is `g:\Zundamons-kItchen-V2\.agents\explorer_m1_3`.

Task:
Analyze the Automated Dual Deployment sync requirement (R4) to synchronize `g:\Zundamons-kItchen-V2\site` with `g:\Zundamons-kItchen-V2\docs`.
Review `g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md`, `site/`, and `docs/`.

Formulate a detailed specification for `site/sync_site.js` (or node sync runner) that:
1. Copies web assets (`index.html`, `style.css`, `app.js`, `terminal.js`, `window_manager.js`, `.nojekyll`, `sync_site.js`, `assets/`) recursively from `g:\Zundamons-kItchen-V2\site` to `g:\Zundamons-kItchen-V2\docs`.
2. Preserves existing markdown documentation files in `docs/` (`AGENT_HANDOFF.md`, `ASSET_MANAGEMENT.md`, `UI_UX_OVERHAUL_PLAN.md`, etc.).
3. Provides dry-run and sync modes, logging copied/updated files.
4. Can be executed via `node site/sync_site.js` cleanly without third-party npm packages (using Node native `fs` and `path`).

Write your findings and recommendations to `g:\Zundamons-kItchen-V2\.agents\explorer_m1_3\analysis.md` and send a message back.
</USER_REQUEST>
