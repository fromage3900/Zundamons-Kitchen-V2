# 🌸 ZUNDAMON'S KITCHEN V2 — MASTER ENGINE & MARKETING BLUEPRINT

> **Version**: 2.4.0 (Hybrid ECS & Viral Marketing Edition)  
> **Repository**: `g:\Zundamons-kItchen-V2`  
> **Rojo Place**: `build/Zundamons-kItchen.rbxl`  
> **Last Updated**: July 23, 2026  

---

## 🌐 1. Live Webfront & Telemetry Shareable Links

- 🎮 **Official Roblox Game Place**:  
  `https://www.roblox.com/games/102953611950557/Zundamons-Kitchen-V2-Electric-Boogaloo`
- 🖥️ **Main Web Portal (Zunda-OS 95 Hub)**:  
  `https://fromage3900.github.io/Zundamons-Kitchen-V2/`
- 📰 **Official Press Kit & Media Assets**:  
  `https://fromage3900.github.io/Zundamons-Kitchen-V2/presskit.html`
- 📡 **Real-Time Game Telemetry JSON API**:  
  `https://fromage3900.github.io/Zundamons-Kitchen-V2/api/game_info.json`

---

## 🛠️ 2. Comprehensive System Architecture & Audit Review

### A. 🫛 Pea Wheel Radial Menu Overlay (`src/client/Controllers/PeaWheelController.lua`)
- **Centered Layout**: Centered at `Position = UDim2.fromScale(0.5, 0.5)` with `AnchorPoint = Vector2.new(0.5, 0.5)` and backdrop blur.
- **Responsive Viewport Scale**: Includes `UIScale` auto-calculator (`0.55x` to `1.20x`) ensuring all 8 radial slices (`inventory`, `cook`, `quests`, `compendium`, `materials`, `map`, `shop`, `settings`) remain 100% visible on all monitor/mobile resolutions.
- **Input Binds**: Toggles instantly via `Tab` or `Q` key (ignoring text box inputs), or by clicking the bottom-right trigger button.

### B. ⌨️ Single Source of Truth Keybind Engine (`UIActionRegistry.lua`)
- **Deduplication**: Keybinds (`I`, `K`, `J`, `C`, `M`, `P`, `B`, `F1`) are handled exclusively by `UIActionRegistry.lua`.
- **Zero Double-Toggling**: Standalone `InputBegan` listeners in `CraftingScript.client.lua`, `StoreScript.client.lua`, and `PouchScript.client.lua` have been removed to eliminate single-frame double-toggle bugs.

### C. 🐾 Companion Catalog & Tier System (`CompanionConfig.lua` & `CompanionManager.server.lua`)
- **Free Tier (4 Companions)**: `parrot`, `dog`, `cat`, `ankomon` (unlocked by default, 0 Gold / 0 Robux).
- **Premium Tier (4 Companions)**: `cardamon`, `antimon`, `sakuradamon`, `tantanmon` (1,000 Robux each).
- **Playtest Fallback**: Automatically resolves `zundapalupdate4.fbx` character rig at `0.65x` compact scale when custom Roblox asset IDs are offline.

### D. 💬 Expanded Visual Novel Dialogue Trees (`VNDialogueData.lua`)
- **9 Companion Spirits Supported**: `zundamon`, `zundapal`, `zundacat`, `zundabunny`, `tantanmon`, `ankomon`, `cardamon`, `antimon`, `sakuradamon`.
- **Dynamic Branching**: Branches based on time of day (`morning`, `afternoon`, `evening`, `night`), chef level (`1-10`, `11-20`, `21-50`), and bond level.

### E. 🖼️ Local Drive Asset Integration (`docs/assets/`)
- Discovered and integrated:
  - 🎞️ `zundamon_animation.gif` (389 KB Animated GIF)
  - 🫛 `zunda_transparent.png` (3.6 MB High-Res Transparent Cutout)
  - 🖼️ `zundamon_art_1.png` & `zundamon_art_2.png` (Key Visual Artwork PNGs)
  - 🎨 `Tex_Head.png`, `Tex_Body.png`, `Tex_Hair.png` (3D Texture Maps)
  - 📦 `zundapalupdate4.fbx`, `SM_Pea.fbx`, `Zundamon's_Kitchen_Assets.blend` (3D Assets)
- Built interactive **`Gallery.app`** on the Zunda-OS 95 portal for 1-click HD downloads.

---

## 📣 3. Marketing & Autonomous Content Pipeline

### A. Short-Form Video & Post Generator (`scripts/generate_tiktok_video.py`)
Run the 1-click generator to create ready-to-upload TikTok/Shorts assets:
```bash
python scripts/generate_tiktok_video.py --count 5
```
- **Renders**: 9:16 vertical poster cards (`tiktok_card_1.svg`) with Zundamon renders, voiceover scripts, and CTAs.
- **Manifest**: Saved to `scripts/ollama_output/ready_to_upload/ready_to_upload_manifest.json`.

### B. Autonomous Social Media Publisher (`scripts/autonomous_social_publisher.py`)
Run the background daemon to post autonomously to X (Twitter) and Instagram every 4 hours:
```bash
python scripts/autonomous_social_publisher.py --daemon
```

### C. Active Roblox Promo Codes
- `ZUNDAMOCHI2026` — +500 Gold, 10x Fresh Zunda Mochi, 1x Rare Chef Apron
- `SOUPSEASON` — +1,000 Kitchen EXP, 5x Wild Mushroom Pack
- `HYBRIDECS` — +250 Gold, Matter ECS Developer Badge

---

## 📜 5. Definitive Legal Credits & Asset Licensing

### A. 🫛 SSS LLC — Zundamon Ownership & Royalty-Free Guidelines
- **Rights Holder**: **SSS LLC (合同会社SSS / Tohoku Zunko Project)** — [https://zunko.jp/](https://zunko.jp/)
- **Guidelines**: Used under official [SSS LLC Royalty-Free Character Guidelines](https://zunko.jp/guideline.html) for fan creative works and game development.
- **Voice Engine**: **VOICEVOX:ずんだもん** ([https://voicevox.hiroshiba.jp/](https://voicevox.hiroshiba.jp/)).

### B. 🎨 Kenney (www.kenney.nl) — 3D Environment, Skybox & NPC Assets
- **Author**: **Kenney** — [https://www.kenney.nl](https://www.kenney.nl)
- **Catalog**: [Kenney 3D Assets (Page 3)](https://kenney.nl/assets/category:3D/page:3)
- **License**: **CC0 1.0 Universal (Public Domain)**
- **Assets**: 3D nature props, food meshes, furniture, guest NPC avatars, and skybox cubemaps.

### C. 🎵 Nomagician — Audio, BGM & UI Sound Effects
- **Author**: **Nomagician**
- **Packs**: *Cozy Ambience by Nomagician* (TreeHouse BGM) and *Cute, Cozy & Magical UI SFX by Nomagician*.

### D. 🖱️ wappon_28_dev — Custom Cursors
- **Author**: **wappon_28_dev** (X: `@yurirofu`) — MIT License.

1. **Compiling Place File**:
   ```bash
   rojo build default.project.json -o build/Zundamons-kItchen.rbxl
   ```
2. **Running Preflight Audit**:
   ```bash
   python scripts/preflight_audit.py
   ```
3. **Local Ollama Content Generation**:
   - Ensure Ollama is running (`http://localhost:11434`).
   - Run recipe worker: `python scripts/ollama_recipe_worker.py --count 5`
   - Run quest worker: `python scripts/ollama_quest_worker.py --count 5`
