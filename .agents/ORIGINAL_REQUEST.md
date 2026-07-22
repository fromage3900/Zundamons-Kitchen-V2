# Original User Request

## 2026-07-21T17:52:18Z

Zundamon's Kitchen V2 is a cooperative Roblox life-sim. The project goal is to methodically audit, refactor, and fully integrate the core gameplay loop (Harvest → Cook → Serve → Reward → Repeat) into a working, bug-free state synced via Rojo 7.7.0.

Working directory: g:\Zundamons-kItchen-V2

Integrity mode: development

## Requirements

### R1. Harvesting & Resource Node System
Players can equip tools (Axe, Pickaxe, Sickle), swing to deal damage to resource nodes, see visual progress bars and particle effects, receive item drops, and have items saved in PlayerDataService.

### R2. Cooking & Rhythm Minigame System
Crafting recipes initiates a server-validated rhythm minigame (CookingValidationSystem). Accuracy grades (perfect, great, ok) determine quality bonuses, gold rewards, chef XP, and inventory dish delivery.

### R3. Guest Serving & Economy Loop
Customer NPCs spawn in workspace.Guests, display requested recipes and gold rewards, accept dishes from player inventory, trigger despawning, and award gold and chef XP via RewardCore.

### R4. Real-time HUD Synchronization
Player stats (Gold, Chef XP, Level, Combo, inventory notifications) update dynamically in the HUD UI (ZundaHUD, ChefPill, XPBar, ComboMeter) in real-time.

## Acceptance Criteria

### Functional Verification
- [ ] Swings with tools hit nodes, play progress UI/particles, drop items, and update inventory.
- [ ] Rhythm cooking minigame accurately tracks note hits, sends server validation, and grants cooked dishes.
- [ ] Guests accept ordered dishes, deduct items from inventory, pay gold, and despawn smoothly.
- [ ] HUD displays live gold, XP progress, and combo updates without requiring manual GUI refreshes.
- [ ] No script.Parent errors or missing package crashes appear in the Studio Output window.

## 2026-07-21T20:40:35Z

# Zundamon's Kitchen — Zunda-OS 95 CLI Launch Page & Creative Hub

> Status: Launched — delegated to teamwork_preview
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

Create an all-ages friendly (100% SFW, zero NSFW content), high-craft, anti-AI-slop GitHub Pages website, CLI launch page, and creative hub for **Zundamon's Kitchen V2** featuring a **Zunda-OS 95 / Retro Phosphor Console** visual aesthetic with a **Cozy Infinity Nikki & Zen Edamame-Pea** aesthetic twist!

Working directory: g:\Zundamons-kItchen-V2\site
Integrity mode: development

## Aesthetic: Zunda-OS 95 / Cozy Infinity Nikki Zen-Pea Console
- **90s Retro OS Interface**: Zunda & edamame green window borders (`#2e7d32`, `#4caf50`, `#8bc34a`, `#e8f5e9`, soft pastel green accents), retro titlebars with little pea pod icons, vintage taskbar with `[Start Zunda 🫛]` button, clock, and cozy background music toggle.
- **Cozy Infinity Nikki & Zen Aesthetic**: Soft ambient glowing gradients, gentle floating zunda mochi/pea petals, calming pastel dark/light themes, cozy UI soundscapes, and heartwarming companion dialogues.
- **CRT Green Phosphor Terminal (`ZundaCLI.exe`)**: Authentic CRT scanlines (toggleable), blinking prompt cursor (`zunda>`), monochrome green text output with retro & cozy command sound effects.
- **Draggable & Modular Windows**:
  1. `ZundaCLI.exe` — Full interactive web terminal parser.
  2. `Cookbook.app` — Recipe Cards & Rhythm Minigame score targets with cozy food illustrations.
  3. `VNTalk.app` — Companion Zundamon dialogue & lore preview.
  4. `QuickStart.txt` — Developer quick-start (`git clone`, `wally install`, `rojo serve`).
- **Roblox UI Export Readiness**: UI elements styled modularly using CSS variables so designs can directly map into Roblox ScreenGui elements.

## Requirements

### R1. Anti-AI-Slop Aesthetic & Zunda-OS 95 Zen-Pea Theme
Build a bespoke web design avoiding AI slop clichés (no generic generic purple/cyan blur blobs or corporate copy). Implement the Zunda-OS 95 theme infused with Cozy Infinity Nikki & Zen Edamame-Pea aesthetics: pastel zunda greens, soft rounded corners, pixel-art pea pods, CRT scanlines overlay, and cozy kitchen audio/visuals.

### R2. Interactive Terminal (`ZundaCLI.exe`) & Window System
Provide an interactive web terminal window (`ZundaCLI.exe`) alongside floating retro app windows.
- **Interactive Terminal**: Supports commands like `help`, `about`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme`, and hidden Zundamon easter eggs.
- **Window Management**: Windows can be focused, dragged, minimized to taskbar, or maximized.

### R3. All-Ages Cozy Creative Hub & Asset Showcase
Create a creative hub inside `Cookbook.app` and `VNTalk.app` containing:
- **Recipe & Ingredients Index**: Interactive recipe search powered by game data (mushrooms, berries, zunda mochi, tea, etc.).
- **Zundamon Lore & Audio/VN Corner**: All-ages cozy character dialogues and voice line previews.
- **Downloads & Quick Launch**: Direct links to play on Roblox, read getting started guides, and view code on GitHub.
- **100% SFW Safety Guarantee**: Strictly wholesome, family-friendly content throughout.

### R4. Production-Ready GitHub Pages Deployment Package
Structure the codebase cleanly in `g:\Zundamons-kItchen-V2\site` as a lightweight, zero-dependency HTML5/CSS3/JS application ready for immediate GitHub Pages deployment (`index.html`, `style.css`, `app.js`, `terminal.js`, `window_manager.js`, `assets/`).

## Acceptance Criteria

### Aesthetic & Quality (Anti-Slop)
- [ ] 100% SFW, wholesome, all-ages appropriate content.
- [ ] Zunda-OS 95 visual identity complete with taskbar, start menu, draggable windows, CRT toggle, cozy Infinity Nikki / Zen Edamame-pea styling, and sound toggles.
- [ ] Responsive across desktop, tablet, and mobile browsers.

### Terminal & Interactivity
- [ ] Fully functional web terminal with command history (up/down arrow navigation), auto-complete (`Tab`), help menus, and interactive responses.
- [ ] Working commands: `help`, `info`, `recipes`, `lore`, `quickstart`, `clear`, `theme`, `play`.

### Hub Content & GitHub Pages Packaging
- [ ] Complete landing page with feature cards, quickstart instructions, recipe explorer, and project documentation links.
- [ ] Clean directory structure in `g:\Zundamons-kItchen-V2\site` with valid HTML5/CSS3/JS that runs directly in any browser or local static HTTP server.

## 2026-07-21T20:50:09Z

You are the Successor Orchestrator (Generation 2) for Zundamon's Kitchen V2 — Zunda-OS 95 CLI Launch Page & Creative Hub project.

Resume work at g:\Zundamons-kItchen-V2\.agents\orchestrator. Read handoff.md, BRIEFING.md, ORIGINAL_REQUEST.md, plan.md, and progress.md for current state.
Your parent is 20d5c6d7-e2ed-4df9-8b00-b8997021dc80 — use this ID for all escalation and status reporting (send_message).

Your immediate mission:
1. Dispatch Worker for Milestone 2 Fix Pass (`site/assets/audio_engine.js` BGM oscillator cleanup).
2. Mark Milestone 2 DONE in progress.md and plan.md.
3. Execute Milestone 3 (Interactive Phosphor Web Terminal ZundaCLI.exe in site/terminal.js).
4. Execute Milestone 4 (Creative Hub Applications site/app.js, Cookbook.app, VNTalk.app, QuickStart.txt, GitHub Pages Deployment Package).
5. Verify 100% SFW safety, zero external runtime dependencies, conduct gate checks & Forensic Audit, and notify parent when victory is claimed.

## 2026-07-22T04:21:00Z

# Zundamon's Kitchen V2 — Kawaii PC Desktop x Game Showcase Launchpad

> Status: Launched — delegated to teamwork_preview
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

Create an all-ages friendly (100% SFW, zero NSFW content), high-craft, anti-AI-slop webfront for **Zundamon's Kitchen V2** that seamlessly blends a **Kawaii PC Desktop Setup** with a modern **Game Showcase Launchpad**, designed through a dreamy **Y2K Infinity Nikki** lens.

Working directory: g:\Zundamons-kItchen-V2\site
Integrity mode: development

## Design Vision & Aesthetic: Kawaii Y2K Infinity Nikki Showcase
- **Kawaii Y2K Infinity Nikki Lens**: Soft Sakura Pink (`#ffb7c5`, `#ff85a1`, `#ffe5ec`), Zunda Edamame Mint (`#4caf50`, `#8bc34a`, `#a5d6a7`), and Magical Pearl Lavender (`#e8dff5`). Glossy rounded candy buttons, sparkling starbursts (`✨`), zero creepy dark overlays, and human, charming, non-AI-sounding copy.
- **Game Showcase Launchpad Format**:
  - Top Game Navbar with brand logo, quick navigation links, and pulsing `[ 🎮 PLAY ON ROBLOX NOW ]` CTA.
  - Big Game Launch Hero Banner with live server status (`🟢 LIVE ON ROBLOX · v2.4.0 HYBRID ECS`), tagline, dual CTAs, and feature pills.
  - Game Features Grid (Gathering, Rhythm Minigames, Companion Spirits, Restaurant Decorating).
  - Active Promo Codes Box with 1-click clipboard copy buttons (`ZUNDAMOCHI2026`, `SOUPSEASON`, `HYBRIDECS`).

## Interactive Kawaii PC Desktop Experience
- **Embedded Desktop Setup**: An interactive PC desktop workspace right on the launch page!
- **Clickable & Draggable Windows**:
  1. `ZundaCLI.exe` — Pastel Web Terminal with command prompt, history, autocomplete, and lore.
  2. `Cookbook.app` — Interactive recipe book & rhythm score targets.
  3. `VNTalk.app` — Companion visual novel dialogue player.
  4. `Zundamon.app` — Real companion stats, mood avatar (`🟢 Happy`, `🍳 Cooking`, `💤 Sleeping`), and vocal chirps.
  5. `Promos.app` — 1-click code redeemer.
  6. `Calculator.app` — Dish profit & crafter calculator.
  7. `Updates.log` — Patch Notes & Matter ECS log.
- **Desktop Widgets**: Live digital clock & weather widget (⏰), Lo-Fi Jukebox BGM player with rain FX (🎵), and interactive Zundamon Desktop Sticker with speech bubbles (🫛).

## Requirements

### R1. Kawaii Y2K Infinity Nikki Aesthetic & Showcase Architecture
Build a bespoke web application avoiding generic AI slop tropes. Implement the Kawaii Y2K Infinity Nikki palette with crisp typography, glossy glassmorphism window frames, cute sticker decorations, sparkling starburst canvas, and zero dark green matrix blood cell overlays.

### R2. Dual Experience: Game Showcase Launchpad + Interactive PC Desktop
Structure the site so it operates both as a high-converting Roblox game landing page (hero banner, CTAs, feature grid, promo codes) AND an interactive PC desktop setup where visitors can click desktop icons, drag windows, interact with widgets, and run terminal commands.

### R3. Real Game Data Integration & Authentic Charming Copy
Integrate authentic Lua game configuration data from `src/shared/ConfigurationFiles/` (companion spirit catalog, recipe rewards, daily quests) and provide a 100% wholesome, family-friendly experience with charming, human, non-generic copy.

### R4. Automated Dual Deployment (`/site` & `/docs` for GitHub Pages)
Ensure all web assets (`index.html`, `style.css`, `app.js`, `terminal.js`, `window_manager.js`, `assets/`, `.nojekyll`) are lightweight, zero-dependency, and synced automatically to both `g:\Zundamons-kItchen-V2\site` and `g:\Zundamons-kItchen-V2\docs` for instant GitHub Pages hosting.

## Acceptance Criteria

### Aesthetic & Quality (Anti-Slop)
- [ ] 100% SFW, wholesome, all-ages appropriate content.
- [ ] Dreamy Y2K Infinity Nikki styling complete with glossy pastel windows, sparkling star canvas, and responsive design across desktop and mobile.

### Interactive PC Desktop & Game Showcase
- [ ] Functional game launch hero banner with working `[ 🎮 PLAY ON ROBLOX NOW ]` CTA and section navigation.
- [ ] Interactive PC desktop setup with working window manager (drag, minimize, maximize, z-index), pastel terminal (`ZundaCLI.exe`), cookbook, real companion stats, promo code copy buttons, and desktop widgets.

### GitHub Pages Packaging
- [ ] Clean code in `site/` and `docs/` ready for immediate live deployment on GitHub Pages.

## 2026-07-22T17:19:17Z

Deeply audit Zundamon's Kitchen V2 codebase for loose ends, fix any lingering bugs or edge cases, and complete the real-time Roblox game data telemetry sync on the Zunda-OS 95 website hub.

Working directory: g:\Zundamons-kItchen-V2
Integrity mode: development

## Requirements

### R1. Deep Codebase Audit & Loose-Ends Fixes
Conduct a comprehensive review across all server, client, shared, and script modules to catch and fix any missing remote definitions, decoupled UI visibility bugs, unhandled errors, or broken contracts.

### R2. Real-Time Game Telemetry & Web Integration
Enhance and verify the live connection between the Roblox game backend (WebInfoSyncService) and the Zunda-OS 95 web portal (docs/index.html, docs/presskit.html, docs/api/game_info.json) so website visitors can view real-time player counts, active daily challenges, live gacha banners, and community milestone progress.

### R3. Preflight & Acceptance Verification
Ensure all preflight automated audits pass cleanly with zero Luau static errors, full Rojo level preservation ($ignoreUnknownInstances: true), and decoupled UI rules.

## Acceptance Criteria

### Comprehensive Quality Bar
- [ ] Preflight audit script (python scripts/preflight_audit.py) passes cleanly with 0 errors.
- [ ] Real-time game JSON telemetry (docs/api/game_info.json) contains valid, structured live data for challenges, banners, codes, and global stats.
- [ ] Web pages (docs/index.html and docs/presskit.html) render live ticker data and dynamic event banners cleanly without browser console errors.
- [ ] All client UI scripts follow ClientGuiBootstrap and explicitly hide modals (Visible = false) on startup.
