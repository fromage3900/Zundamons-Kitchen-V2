# Project Plan: Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub

## Overview
Decompose, design, execute, and verify the Zunda-OS 95 GitHub Pages website and Creative Hub in `g:\Zundamons-kItchen-V2\site`. The project combines retro 90s OS windows (Zunda-OS 95), CRT phosphor console styling, Cozy Infinity Nikki & Zen Edamame-Pea aesthetics, an interactive CLI terminal (`ZundaCLI.exe`), floating app windows (`Cookbook.app`, `VNTalk.app`, `QuickStart.txt`), and Roblox ScreenGui-ready modular CSS variables.

## Architecture & Code Layout
- Target Directory: `g:\Zundamons-kItchen-V2\site\`
  ├── `index.html` (Main layout, taskbar, start menu, CRT overlay canvas, audio elements, window container)
  ├── `style.css` (Zunda-OS 95 visual design tokens, pastel green theme `#2e7d32`, `#4caf50`, `#8bc34a`, `#e8f5e9`, Roblox ScreenGui CSS variables, CRT scanline overlay, window styling, responsive layout)
  ├── `window_manager.js` (Modular window lifecycle: create, drag with viewport bounds clamping, touch drag support, z-index stack management, minimize to taskbar, maximize/restore, close, active window focus fallback, taskbar sync, keyboard shortcuts `Ctrl+Esc`/`Escape`)
  ├── `terminal.js` (CRT phosphor web terminal engine `ZundaCLI.exe`, command parser, history buffer, Tab autocomplete, commands: `help`, `info`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme`, easter eggs)
  ├── `app.js` (Creative hub app logic, `Cookbook.app` recipe index & rhythm targets, `VNTalk.app` Zundamon dialogue & voice preview, `QuickStart.txt` developer guides, audio engine synthesizers, SFW assets)
  └── `assets/` (SVG icons, pea pod graphics, web audio sound synthesizers / audio clips)

## Milestones

### Milestone 1: Zunda-OS 95 Core Aesthetic, CSS Variables & HTML Layout Infrastructure
- **Objective**: Establish the complete HTML5 structure (`index.html`) and Zunda-OS 95 CSS theme (`style.css`). Define modular CSS variables mapping directly to Roblox ScreenGui UI components. Implement taskbar (`[Start Zunda 🫛]`, clock, sound toggle), retro titlebar styles with pea icons, CRT scanline overlay toggle, ambient floating Zunda pea/mochi effects, and Web Audio API sound engine foundation.
- **Target Files**: `site/index.html`, `site/style.css`, `site/assets/`
- **Dependencies**: None
- **Status**: DONE

### Milestone 2: Modular Desktop & Window Manager Engine
- **Objective**: Develop `site/window_manager.js` to manage interactive floating windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `QuickStart.txt`). Implement drag-to-move with viewport boundary clamping, touch event listeners (`touchstart`, `touchmove`, `touchend`), click-to-focus with active state management (`z-index` stack & `.window-active`), active focus fallback upon close/minimize, minimize to taskbar with taskbar button retention, maximize/restore, close, Start Menu `Ctrl+Esc` keyboard shortcut, and taskbar button sync. Add hooks for Roblox ScreenGui layout export mapping.
- **Target Files**: `site/window_manager.js`, `site/style.css`, `site/index.html`
- **Dependencies**: Milestone 1
- **Status**: DONE


### Milestone 3: Interactive Phosphor Web Terminal (`ZundaCLI.exe`)
- **Objective**: Develop `site/terminal.js` providing an interactive CRT terminal console. Support command parsing, prompt (`zunda>`), monochrome green/cozy color modes, command history with Up/Down arrow keys, Tab completion, CRT scanlines toggle, audio sound effects for keypress/execution, and rich output formatting for commands: `help`, `info`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme`, and Zundamon easter eggs.
- **Target Files**: `site/terminal.js`, `site/style.css`, `site/index.html`
- **Dependencies**: Milestones 1 & 2
- **Status**: DONE

### Milestone 4: Creative Hub Applications & GitHub Pages Package Integration
- **Objective**: Develop `site/app.js` and assemble the complete deployment package. Implement `Cookbook.app` (recipe card search, ingredient details, rhythm minigame targets), `VNTalk.app` (Zundamon companion dialogues & voice line previews), `QuickStart.txt` (developer launch docs & Roblox links). Ensure 100% SFW compliance, zero external dependencies, responsive design across devices, and end-to-end static browser deployment verification.
- **Target Files**: `site/app.js`, `site/index.html`, `site/style.css`, `site/assets/`
- **Dependencies**: Milestones 1, 2 & 3
- **Status**: IN_PROGRESS


## Verification & Audit Strategy
For each milestone:
1. **Exploration**: 3 Explorers examine structure, styles, logic, and requirement compliance.
2. **Implementation**: 1 Worker implements target code files, tests execution, and reports verification output.
3. **Review**: 2 Reviewers independently evaluate code quality, zero-dependency requirement, and feature compliance.
4. **Adversarial Verification**: 2 Challengers stress-test edge cases, browser rendering, and interaction bounds.
5. **Integrity Audit**: 1 Forensic Auditor verifies authentic implementation (HARD VETO on cheating / hardcoding).
