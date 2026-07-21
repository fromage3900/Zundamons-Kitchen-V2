## 2026-07-21T18:02:50Z
You are Reviewer 1 for Milestone 2 (R2: Cooking & Rhythm Minigame System).
Working directory: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m2_1
Project root: g:\Zundamons-kItchen-V2
Plan file: g:\Zundamons-kItchen-V2\.agents\orchestrator\plan.md
Workspace rules: g:\Zundamons-kItchen-V2\AGENTS.md
Worker Handoff: g:\Zundamons-kItchen-V2\.agents\teamwork_preview_worker_m2\handoff.md

Task:
1. Conduct a rigorous code review of all changes in src/ made for Milestone 2 (Cooking & Rhythm Minigame System).
2. Verify strict compliance with AGENTS.md rules:
   - $ignoreUnknownInstances: true in default.project.json under Workspace.
   - PlayerGui decoupling (no script.Parent in StarterPlayerScripts client scripts).
   - Wally package structures.
   - ServerScriptService import path consistency (no relative script.Parent or .Server. paths).
3. Verify that RewardCore.lua is located at src/server/Services/RewardCore.lua and imported correctly.
4. Report pass/fail verdict and detailed findings in g:\Zundamons-kItchen-V2\.agents\teamwork_preview_reviewer_m2_1\handoff.md.
