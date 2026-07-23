# Roblox Studio & Rojo 7.7.0 Workspace Rules

### 1. Rojo Level Preservation ($ignoreUnknownInstances)
- When configuring `default.project.json`, ALWAYS include `"$ignoreUnknownInstances": true` under `"Workspace"`.
- This prevents Rojo from wiping out terrain, meshes, models, and 3D level geometry placed manually inside Roblox Studio during code synchronizations.

### 2. Client UI Decoupling & Visibility
- Never use `script.Parent` for UI references in client scripts synced to `StarterPlayerScripts`.
- All client UI scripts must dynamically construct or locate their interface in `PlayerGui` via `ClientGuiBootstrap`.
- Explicitly set `gui.ResetOnSpawn = false` on top-level `ScreenGui` instances to survive player respawns.
- Explicitly set `panel.Visible = false` on startup for modal/dialogue panels (e.g. `VNController`) to avoid UI overlaps on game start.

### 3. Wally Package Structure & Dependencies
- Server-only modules (such as `ProfileService`) must be declared under `[server-dependencies]` in `wally.toml`.
- `default.project.json` must map `"Packages": { "$path": "Packages" }` in `ReplicatedStorage` and `"ServerPackages": { "$path": "ServerPackages" }` in `ServerScriptService`.
- `.gitignore` must ignore `Packages/`, `ServerPackages/`, `wally.exe`, and `wally.zip`.

### 4. ServerScriptService Path Consistency
- When `src/server` is mapped directly to `ServerScriptService` in `default.project.json`, imports must use `ServerScriptService.Services.X` or `ServerScriptService.systems.X`. Never prepend an extra `.Server.` path segment.

### 5. MCP (Model Context Protocol) — Roblox Studio Integration
- Use **chrxxs/robloxstudio-mcp** (`@chrrxs/robloxstudio-mcp@latest`) as the Studio MCP server — 78 tools, actively maintained, MIT.
- `opencode.json` config: `{"command": ["cmd", "/c", "npx", "-y", "@chrrxs/robloxstudio-mcp@latest", "--auto-install-plugin"]}`
- Tool names follow the pattern `roblox-studio_<tool_name>` (e.g. `roblox-studio_execute_luau`, `roblox-studio_get_instance`, `roblox-studio_solo_playtest`).
- Ensure no other MCP server (e.g. paralov/roblox-studio-opencode-mcp on port 28821) is running — they conflict. Kill stale processes with `Stop-Process -Id <PID> -Force`.
- Use `get_connected_instances` to verify Studio is linked before calling other tools.
- Fallback: Roblox built-in MCP at `%LOCALAPPDATA%\Roblox\mcp.bat` (no plugin needed, limited tools).

### 6. Endless Gameplay Loop Systems
- **ChallengeModeService** (`src/server/Services/ChallengeModeService.lua`): Endless wave-based challenge mode inspired by Uma Musume's racing meets. Players face increasingly difficult guest waves, earning score and rewards. Tiers: Bronze → Silver → Gold → Platinum → Zunda.
- **DailyChallengeService** (`src/server/Services/DailyChallengeService.lua`): 3 rotating daily challenges + weekly boss challenge + streak rewards. Inspired by Uma Musume's daily races.
- **DailyChallengeConfig** (`src/shared/ConfigurationFiles/DailyChallengeConfig.lua`): Config for daily challenge pool, weekly boss, streak rewards, daily visitor (Nikki the Drifter), and daily resources.
- **ChefStatsConfig** (`src/shared/ConfigurationFiles/ChefStatsConfig.lua`): Chef stat system inspired by Infinity Nikki's style stats. Stats: Speed, Precision, Charisma, Stamina with diminishing returns. Style points system with outfit unlocks.
- **EndlessLoopWiring** (`src/server/Systems/EndlessLoopWiring.server.lua`): Wires together all new systems, connecting them to existing GuestManager, CookingService, and ServingSystem.
- RemoteEvents required: `ChallengeMode`, `ChallengeModeStatus`, `DailyChallenge`, `DailyChallengeStatus`, `ChefStatsUpdate`, `StylePointsUpdate`, `OutfitUnlock`.

### 7. Infinity Nikki Aesthetic
- UI colors: pastel palette (RGB(160, 210, 150) for Zunda green, RGB(255, 200, 80) for gold, RGB(255, 150, 200) for pink, RGB(145, 215, 195) for mint).
- Dialogue style: Zundamon speaks in ALL CAPS with exclamation marks, pea-themed metaphors, and frequent emojis (🫛🍡✨🔥🌸).
- Style points system: Earned from perfect cooks, stylish serving, companion coordination. Unlocks fashion items and outfit variants.
- Guest types: `magical_girl`, `fashionista`, `stylist`, `challenge_fighter` — all with Infinity Nikki themed dialogue.
- Quest naming: Dramatic and thematic (e.g., "Culinary Ascension", "The Great Zunda Hunt", "Friend of All").

### 8. Ollama Content Workers
- **ollama_client.py** (`scripts/ollama_client.py`): Reusable Ollama API client with Zundamon persona template, Lua formatter, and JSON extraction.
- **ollama_recipe_worker.py** (`scripts/ollama_recipe_worker.py`): Generates new cooking recipes in Lua format for CraftConfig.lua.
- **ollama_quest_worker.py** (`scripts/ollama_quest_worker.py`): Generates new quest entries in Lua format for QuestConfig.lua.
- **ollama_dialogue_worker.py** (`scripts/ollama_dialogue_worker.py`): Generates new companion/NPC dialogue in Lua format for VNDialogueData.lua.
- Usage: `python scripts/ollama_recipe_worker.py --count 8 --model deepseek-coder:6.7b`
- Output directory: `scripts/ollama_output/`
- Requires Ollama server running (`ollama serve`).

### 9. New Quest Types
- `challenge_wave`: Complete Challenge Mode waves
- `style_points`: Earn style points from cooking
- `outfit_collect`: Unlock companion fashion items
- `reputation_tier`: Achieve guest reputation tiers
- `cook_speed`: Cook dishes under time limits
- `cook_quality`: Achieve quality thresholds (great, perfect)
- `gather_unique`: Gather unique ingredient types
- `visit_zones_unique`: Visit unique locations
- `npc_chat_all`: Chat with all NPCs

### 10. Skybox — Kenney CC0 Cubemaps (Dynamic 3‑Set Swap)
- `SkyConfig.lua`: default set = Kenney Day (lines 33–45, edited)
- `DayNightSky.server.lua`: 3 `SKYBOX_SETS` (day/night/morning) at lines 78–119
  - Dawn 4.5–7.5 → morning, day 7.5–17 → day, dusk 17–19.5 → morning, night else → night
- Uploaded 18 face decals (1024×1024 RGBA, all approved)
- Sun icon: 123736711329002, Moon icon: 85079237605725

### 11. New Guest Types (Infinity Nikki Aesthetic)
- `magical_girl`: "By the power of sparkling cuisine! I need {recipe}! ✨💖"
- `fashionista`: "Darling, I require {recipe} — it MUST be Instagram-worthy! 📸💄"
- `stylist`: "I need {recipe} to complete my look today! 💇‍♀️🎨"
- `challenge_fighter`: "I've trained for this moment! Give me {recipe}! 💪🔥"
