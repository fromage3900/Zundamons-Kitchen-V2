# Project Plan: Zundamon's Kitchen V2 — Kawaii PC Desktop x Game Showcase Launchpad

## Overview
Decompose, design, execute, and verify the Zundamon's Kitchen V2 webfront blending a Kawaii Y2K Infinity Nikki Game Showcase Launchpad with an Interactive PC Desktop workspace. Maintained in `g:\Zundamons-kItchen-V2\site` with automated dual deployment synchronization to `g:\Zundamons-kItchen-V2\docs`.

## Aesthetic & Architecture
- **Palette**: Sakura Pink (`#ffb7c5`, `#ff85a1`, `#ffe5ec`), Zunda Edamame Mint (`#4caf50`, `#8bc34a`, `#a5d6a7`), Magical Pearl Lavender (`#e8dff5`). Glossy rounded candy buttons, sparkling starburst canvas (`✨`), zero matrix blood cell overlays, 100% SFW anti-AI-slop copy.
- **Dual Experience**:
  1. **Game Showcase Launchpad**: Top Game Navbar with brand logo & `[ 🎮 PLAY ON ROBLOX NOW ]` CTA, Big Game Launch Hero Banner with live status (`🟢 LIVE ON ROBLOX · v2.4.0 HYBRID ECS`), dual CTAs, feature pills, Game Features Grid (Gathering, Rhythm Minigames, Companion Spirits, Restaurant Decorating), Active Promo Codes Box with 1-click clipboard copy (`ZUNDAMOCHI2026`, `SOUPSEASON`, `HYBRIDECS`).
  2. **Interactive Kawaii PC Desktop Workspace**: Clickable & draggable windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `Zundamon.app`, `Promos.app`, `Calculator.app`, `Updates.log`) and Desktop Widgets (digital clock & weather widget ⏰, Lo-Fi jukebox with rain FX 🎵, Zundamon Desktop Sticker 🫛).
- **Game Data Integration**: Live parsing/integration of Lua config data from `src/shared/ConfigurationFiles/` (`CompanionConfig.lua`, `CraftConfig.lua`, `ItemConfig.lua`, `DailyQuestConfig.lua`, `VNDialogueData.lua`).
- **Automated Dual Sync**: `sync_site.js` automated script mirroring `site/` to `docs/` for GitHub Pages.

## Directory Structure
- `site/` & `docs/`
  ├── `index.html` (Top Navbar, Hero Banner, Features Grid, Promo Codes, Embedded Desktop Workspace, Widgets, Canvas)
  ├── `style.css` (Kawaii Y2K Infinity Nikki design tokens, candy buttons, starburst canvas, glassmorphism, responsive grid)
  ├── `window_manager.js` (Modular Window Engine: drag, clamp, z-index focus, minimize/maximize/close, taskbar buttons, shortcuts)
  ├── `terminal.js` (Y2K Pastel Web Terminal `ZundaCLI.exe`, command parser, history, tab autocomplete, commands & easter eggs)
  ├── `app.js` (Interactive App Engines: `Cookbook.app`, `VNTalk.app`, `Zundamon.app`, `Promos.app`, `Calculator.app`, `Updates.log`, Widgets)
  ├── `sync_site.js` (Automated dual sync script copying web assets from `site/` to `docs/`)
  └── `assets/` (Icons, audio synthesizers, background music, rain FX sound synthesis)

## Milestones

### Milestone 1: Kawaii Y2K Infinity Nikki Design System, Showcase Architecture & Automated Dual Sync
- **Objective**: Implement complete HTML5 structure (`index.html`), Y2K Infinity Nikki CSS theme (`style.css`), top game navbar, hero banner with live status & dual CTAs, features grid, promo codes section with 1-click copy toast notification, sparkling starbursts canvas backdrop (removing CRT green blood cell overlays), and create `site/sync_site.js` script to automatically replicate `site/` -> `docs/`.
- **Target Files**: `site/index.html`, `site/style.css`, `site/sync_site.js`, `docs/*`
- **Dependencies**: None
- **Status**: DONE

### Milestone 2: Interactive Desktop Window Manager & Pastel Desktop Widgets Engine
- **Objective**: Refactor `window_manager.js` and CSS window styling to support 7 draggable/focusable windows (`ZundaCLI.exe`, `Cookbook.app`, `VNTalk.app`, `Zundamon.app`, `Promos.app`, `Calculator.app`, `Updates.log`). Implement smooth drag clamping, z-index stack management, taskbar button sync, active window focus fallback, keyboard shortcuts, and 3 interactive desktop widgets: (1) Live Clock & Weather Widget ⏰, (2) Lo-Fi Jukebox with Rain FX BGM player 🎵, and (3) Interactive Zundamon Desktop Sticker with speech bubble chirps 🫛.
- **Target Files**: `site/window_manager.js`, `site/style.css`, `site/index.html`, `site/assets/audio_engine.js`, `docs/*`
- **Dependencies**: Milestone 1
- **Status**: DONE

### Milestone 3: Pastel Web Terminal (`ZundaCLI.exe`), Promos.app, Calculator.app & Updates.log
- **Objective**: Refactor `terminal.js` and app engines for utility apps. Implement Y2K Pastel Web Terminal `ZundaCLI.exe` with command prompt (`zunda>`), history buffer, Tab autocomplete, commands (`help`, `info`, `recipes`, `spirits`, `quests`, `promos`, `calc`, `clear`, `theme`, easter eggs). Implement `Promos.app` (1-click code redeemer preview), `Calculator.app` (dish crafter profit calculator with ingredient & gold margin calculations), and `Updates.log` (Matter ECS patch notes).
- **Target Files**: `site/terminal.js`, `site/app.js`, `site/style.css`, `docs/*`
- **Dependencies**: Milestones 1 & 2
- **Status**: IN_PROGRESS

### Milestone 4: Game Data Integration (`Cookbook.app`, `VNTalk.app`, `Zundamon.app`), SFW Audit & Dual Deployment Verification
- **Objective**: Integrate real Lua game configuration data from `src/shared/ConfigurationFiles/` (`CraftConfig.lua`, `ItemConfig.lua`, `CompanionConfig.lua`, `DailyQuestConfig.lua`, `VNDialogueData.lua`) into `site/app.js`. Power `Cookbook.app` (recipe card search, ingredient requirements, rhythm minigame score targets), `VNTalk.app` (interactive visual novel dialogue preview), and `Zundamon.app` (companion spirit catalog, mood avatar `🟢 Happy`/`🍳 Cooking`/`💤 Sleeping`, vocal chirps). Execute full verification, zero external dependencies check, 100% SFW audit, and dual deployment verification in `site/` and `docs/`.
- **Target Files**: `site/app.js`, `site/index.html`, `site/sync_site.js`, `docs/*`
- **Dependencies**: Milestones 1, 2 & 3
- **Status**: PLANNED

## Verification & Audit Strategy
For each milestone:
1. **Exploration**: 3 Explorers analyze structure, design compliance, code layout, and requirements.
2. **Implementation**: 1 Worker implements target code files, executes node/browser validation tests, and reports verification output.
3. **Review**: 2 Reviewers independently assess code quality, responsiveness, zero external dependencies, and design fidelity.
4. **Adversarial Verification**: 2 Challengers stress-test interactions, edge cases, responsiveness, and clipboard/audio APIs.
5. **Integrity Audit**: 1 Forensic Auditor performs integrity verification (HARD VETO on hardcoded cheating or fake logic).
