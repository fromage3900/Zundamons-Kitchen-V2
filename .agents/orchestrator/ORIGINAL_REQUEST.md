# Original User Request

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

