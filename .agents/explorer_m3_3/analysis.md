# Milestone 3 Analysis Report: Interactive Phosphor Web Terminal (`ZundaCLI.exe`) Command Suite & Zundamon Easter Eggs

**Author**: Explorer 3  
**Milestone**: Milestone 3 — Interactive Phosphor Web Terminal (`ZundaCLI.exe`)  
**Target Output**: `g:\Zundamons-kItchen-V2\.agents\explorer_m3_3\analysis.md`  
**Date**: 2026-07-21  

---

## 1. Executive Summary & Scope

This report provides the complete architecture and functional specification for the CLI command suite, interactive responses, secret Zundamon easter eggs, and Web Audio API feedback integration in `ZundaCLI.exe` (`site/terminal.js`).

`ZundaCLI.exe` acts as the command-line bridge between the browser user and the *Zundamon's Kitchen V2* universe. Grounded directly in existing game configuration modules (`CraftConfig.lua`, `GatherConfig.lua`, `MineableConfig.lua`, `ZoneLoreConfig.lua`, `VNDialogueData.lua`), workspace setup (`default.project.json`, `wally.toml`), and retro CRT visual design (`style.css`, `audio_engine.js`), this specification details:
1. **12 Core CLI Commands**: `help`, `info` / `about`, `recipes`, `gather`, `lore`, `play`, `music`, `clear`, `version`, `theme [mode]`, `rojo`, `wally`.
2. **7 Secret Zundamon Easter Eggs**: `nanoda`, `mochi`, `edamame`, `zunda`, `secret`, `dance`, `matrix`.
3. **Audio Feedback Integration**: Synthesized sound triggers for command execution, gathering swings, rhythm chimes, theme shifts, BGM toggling, and easter egg audio effects via `ZundaAudio`.

---

## 2. Core Command Suite Specifications

The terminal parser in `site/terminal.js` matches lowercased primary command strings and dispatches sub-arguments to dedicated handler functions. Below is the specification for each core command.

---

### Command 1: `help`
- **Description**: Displays a formatted directory of available terminal commands, organized by category, with syntax usage instructions.
- **Aliases**: `help`, `?`, `commands`
- **Arguments**: Optional category filter (e.g., `help core`, `help game`, `help dev`, `help secret`).
- **Interactive Output Structure**:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ ZundaCLI.exe v4.09.1995 — COMMAND DIRECTORY            │
  └────────────────────────────────────────────────────────┘
  CORE COMMANDS:
    • help [cat]       - Display command directory or category help
    • info / about     - System specs, author credits, project info
    • version          - Kernel version, build details & Rojo sync status
    • clear            - Clear terminal log buffer
    • theme [mode]     - Switch CRT visual theme (classic, amber, matrix, cozy)

  GAMEPLAY & EXPLORATION:
    • recipes [name]   - View edamame dishes & rhythm target scores
    • gather [node]    - Simulate harvesting tool swing & loot drops
    • lore [zone]      - Uncover Zundamon backstory & area lore
    • play             - Launch Roblox Zundamon's Kitchen experience

  AUDIO & DEVS:
    • music            - Toggle cozy BGM arpeggio synthesizer
    • rojo             - View Rojo 7.7.0 workspace tree & studio rules
    • wally            - Inspect Wally package manifest & versions

  EASTER EGGS:
    • Try typing secret keywords nanoda! (Hint: 'secret')
  ```
- **Audio SFX**: `playClickSFX('down')`

---

### Command 2: `info` / `about`
- **Description**: Displays hardware specs simulation, Zunda-OS 95 system diagnostic status, team credits, and project summary.
- **Aliases**: `info`, `about`, `sysinfo`, `specs`
- **Arguments**: None
- **Interactive Output Structure**:
  ```text
  [SYSTEM DIAGNOSTICS - Zunda-OS 95]
  OS Version   : Zunda-OS 95 [Version 4.09.1995]
  Kernel       : Edamame Engine 2.0 (Phosphor Web CLI)
  Memory       : 640KB RAM (512KB Free nanoda!)
  Audio Engine : Native WebAudio Synthesizer (Stereo / 44.1kHz)
  Workspace    : Rojo 7.7.0 Sync Active | $ignoreUnknownInstances: ON
  
  [PROJECT CREDITS]
  Title        : Zundamon's Kitchen V2 (Roblox & Web Hub)
  Description  : Cozy Infinity Nikki & Zen Edamame-Pea Cooking Sim
  Frameworks   : Matter ECS, ReplicaService, React, ProfileService
  Web UI       : Pure HTML5/CSS3 CRT Phosphor Interface (Zero External Assets)
  ```
- **Audio SFX**: `playClickSFX('down')`

---

### Command 3: `recipes`
- **Description**: Displays the complete recipe book sourced directly from `CraftConfig.lua`, showing ingredients, cook times, notes counts, and rhythm score targets (`PERFECT`, `GREAT`, `OK`).
- **Aliases**: `recipes`, `recipe`, `cook`
- **Arguments**: Optional dish name (e.g., `recipes mochi`, `cook Zunda Mochi`).
- **Interactive Output Structure**:
  - *Default Call (`recipes`)*: Shows recipe overview table categorized by Tier (Tier 1 Starter, Tier 2 Intermediate, Tier 3 Advanced, Tier 4 Expert).
  - *Detailed Dish Call (`recipes mochi` or `cook Zunda Mochi`)*:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ [RECIPE CARD] Zunda Mochi (ずんだ餅)                     │
  ├────────────────────────────────────────────────────────┤
  │ Tier       : Tier 2 (Intermediate)                   │
  │ Category   : Signature Dish (Classic Zunda)          │
  │ Ingredients: 🫛 Zunda Pea x5, 🌾 Wheat x8              │
  │ Cook Time  : 7 seconds                                 │
  │ Minigame   : 5 Notes | Speed: 1.7x                     │
  │ Score Target: PERFECT (>=3 Perfect Notes), GREAT (>=3 Hits)│
  │ Market Value: 160 Gold Coins                            │
  └────────────────────────────────────────────────────────┘
  [COOKING SIMULATION]: Cooking Zunda Mochi... Done! Nanoda! 🫛✨
  ```
- **Data Source Reference**: `src/shared/ConfigurationFiles/CraftConfig.lua`
- **Audio SFX**: `playWindowSFX('maximize')` for recipe card view; `playClickSFX('start')` on cook action.

---

### Command 4: `gather`
- **Description**: Simulates harvesting resources in Zunda Village. Simulates tool swinging (`*swish*... *clang!*`), node durability damage, and calculates drop loot based on `GatherConfig.lua` and `MineableConfig.lua`.
- **Aliases**: `gather`, `harvest`, `mine`
- **Arguments**: Optional node name (`gather rock`, `gather pea`, `gather tree`, `gather mushroom`, `gather mystery`).
- **Interactive Output Structure**:
  ```text
  [GATHERING]: Swinging Bronze Pickaxe at node 'GoldRock'...
  *SWISH* ... *CLANG!* (Hit 1/3 - 35 Damage)
  *SWISH* ... *CLANG!* (Hit 2/3 - 35 Damage)
  *SWISH* ... *CRACK!* (Node Harvested!)
  
  [LOOT DROPPED]:
    +2 🪙 Gold Ore
    +1 🪨 Marble Rock
    +1 🫛 Zunda Pea (Bonus Drop!)
  [EXP GAINED]: +25 Chef Gathering XP
  ```
- **Data Source Reference**: `src/shared/ConfigurationFiles/GatherConfig.lua` (Click Flora) & `MineableConfig.lua` (Tool Nodes).
- **Audio SFX**: Multi-stage audio cue: `playWindowSFX('drag')` for swing; high-pitch chime sound for loot drop.

---

### Command 5: `lore`
- **Description**: Displays zone lore entries and dialogue from `ZoneLoreConfig.lua` and `VNDialogueData.lua`.
- **Aliases**: `lore`, `zone`, `story`
- **Arguments**: Optional zone ID (`lore village`, `lore kitchen`, `lore ruins`, `lore shrine`, `lore market`).
- **Interactive Output Structure**:
  - *Default Call (`lore`)*: Lists available zones in Zunda Village.
  - *Zone Call (`lore ruins`)*:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ [ZONE LORE] Ancient Ruins (古代の調理場跡)              │
  └────────────────────────────────────────────────────────┘
  Speaker: 👁 Ancient Voice (古代の記録者)
  
  "...Who enters the Ancient Kitchen...?"
  "Long ago, the first Zunda recipe was crafted on this very altar."
  "The secret ingredient... it slumbers still. Prove your worth, chef."
  
  [LORE NOTE]: Ancient Zunda alchemy increases recipe mastery yield by +15%.
  ```
- **Data Source Reference**: `src/shared/ConfigurationFiles/ZoneLoreConfig.lua`.
- **Audio SFX**: `playWindowSFX('focus')` soft dual-tone.

---

### Command 6: `play`
- **Description**: Generates an interactive Roblox launch banner with experience details, status indicators, and direct web link/window action.
- **Aliases**: `play`, `roblox`, `launch`, `start`
- **Arguments**: None
- **Interactive Output Structure**:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ 🎮 ROBLOX EXPERIENCE — Zundamon's Kitchen V2           │
  ├────────────────────────────────────────────────────────┤
  │ Status     : [ONLINE] Server Active                    │
  │ Players    : 1,420 Chefs Online                        │
  │ Genre      : Cozy Cooking & Gathering Simulation        │
  │ Link       : https://www.roblox.com/                   │
  └────────────────────────────────────────────────────────┘
  [ACTION]: Click link above or launch via VNTalk.app to play nanoda!
  ```
- **Audio SFX**: `playClickSFX('start')`

---

### Command 7: `music`
- **Description**: Toggles ambient cozy background music arpeggio synthesizer on/off via `window.toggleCozyBGM()`.
- **Aliases**: `music`, `bgm`, `audio`, `soundtrack`
- **Arguments**: Optional (`on`, `off`, `toggle`).
- **Interactive Output Structure**:
  ```text
  [AUDIO ENGINE]: Toggling Cozy BGM Synthesizer...
  Status: [AUDIO ACTIVE] Playing E Major Pentatonic Ambient Loop (650ms tempo).
  Note  : Synthesized procedurally using native Web Audio API oscillators.
  ```
- **Audio SFX**: Direct invocation of `toggleCozyBGM()`.

---

### Command 8: `clear`
- **Description**: Flushes the `#cli-output` buffer and resets terminal screen view.
- **Aliases**: `clear`, `cls`
- **Arguments**: None
- **Interactive Output Structure**: Clears DOM elements inside `#cli-output`, re-prints welcome line if configured.
- **Audio SFX**: `playClickSFX('up')`

---

### Command 9: `version`
- **Description**: Outputs exact build information, CRT renderer parameters, and Roblox Studio Rojo compatibility version.
- **Aliases**: `version`, `ver`, `v`
- **Arguments**: None
- **Interactive Output Structure**:
  ```text
  ZundaCLI.exe [Version 4.09.1995]
  Build Tag   : v2.0.0-Phosphor-Release (2026.07)
  Rojo Sync   : Rojo 7.7.0 Compliant
  CRT Renderer: Phosphor Green Monospace Canvas Overlay
  License     : MIT License (C) Zundamon's Kitchen Team
  ```
- **Audio SFX**: `playKeySFX('Enter')`

---

### Command 10: `theme [mode]`
- **Description**: Changes terminal & window visual palette. Supports `classic-green` (default CRT green `#33ff33`), `amber` (warm retro CRT amber `#ffb000`), `matrix` (neon green cyber `#00ff66`), and `cozy-pea` (pastel green `#8bc34a`).
- **Aliases**: `theme`, `color`, `palette`
- **Arguments**: `classic`, `amber`, `matrix`, `cozy`
- **Interactive Output Structure**:
  ```text
  [THEME SWITCHER]: Terminal palette updated to 'amber' (CRT Phosphor Amber).
  [CSS TARGET]    : Applied data-terminal-theme="amber" to #window-zundacli.
  ```
- **Audio SFX**: `playWindowSFX('maximize')`

---

### Command 11: `rojo`
- **Description**: Displays Rojo 7.7.0 workspace mapping tree, sync configuration, and highlights workspace rule `#1`: `$ignoreUnknownInstances: true`.
- **Aliases**: `rojo`, `rojostatus`, `sync`
- **Arguments**: None
- **Interactive Output Structure**:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ 🛠️ ROJO 7.7.0 WORKSPACE STRUCTURE & SYNC CONFIG         │
  ├────────────────────────────────────────────────────────┤
  │ Project    : default.project.json                      │
  │ Mapping    :                                           │
  │   ├── ReplicatedStorage  -> src/shared & Packages       │
  │   ├── ServerScriptService-> src/server & ServerPackages│
  │   ├── StarterPlayer      -> src/client                 │
  │   └── Workspace          -> src/Workspace              │
  ├────────────────────────────────────────────────────────┤
  │ ⚠️ ROJO LEVEL PRESERVATION RULE:                       │
  │ "$ignoreUnknownInstances": true  [ENABLED]             │
  │ Prevents Rojo from wiping Studio-built terrain & maps! │
  └────────────────────────────────────────────────────────┘
  ```
- **Data Source Reference**: `g:\Zundamons-kItchen-V2\default.project.json` and `AGENTS.md`.
- **Audio SFX**: `playClickSFX('down')`

---

### Command 12: `wally`
- **Description**: Displays Wally package manifest, declared dependencies in `wally.toml`, realm mapping, and registry source.
- **Aliases**: `wally`, `packages`, `deps`
- **Arguments**: None
- **Interactive Output Structure**:
  ```text
  ┌────────────────────────────────────────────────────────┐
  │ 📦 WALLY PACKAGE DEPENDENCIES (fromage3900/zundamons-kitchen) │
  ├────────────────────────────────────────────────────────┤
  │ SHARED DEPENDENCIES (ReplicatedStorage/Packages):      │
  │  • Matter         : matter-ecs/matter@0.8.4             │
  │  • ReplicaService : barenton/replicaservice@1.0.1      │
  │  • React          : jsdotlua/react@17.1.0               │
  │  • ReactRoblox    : jsdotlua/react-roblox@17.1.0        │
  │  • Promise        : evaera/promise@4.0.0                │
  │  • Signal         : sleitnick/signal@2.0.1             │
  ├────────────────────────────────────────────────────────┤
  │ SERVER DEPENDENCIES (ServerScriptService/ServerPackages):│
  │  • ProfileService : alreadypro/profileservice@1.0.4     │
  └────────────────────────────────────────────────────────┘
  ```
- **Data Source Reference**: `g:\Zundamons-kItchen-V2\wally.toml`.
- **Audio SFX**: `playClickSFX('down')`

---

## 3. Secret Zundamon Easter Eggs Specifications

The terminal features 7 secret Zundamon easter eggs triggered by typing special terms.

| Easter Egg Command | Primary Keyword / Triggers | Interactive Visual Response | Audio SFX Trigger |
|---|---|---|---|
| **1. `nanoda`** | `nanoda`, `nanoda!`, `nano` | Prints Zundamon's iconic catchphrase artwork and dialogue: `"Nanoda! 🫛 Nanoda! Zundamon is here to support your cooking journey, nanoda!"` | **Signature Chime**: Multi-frequency rapid ascending melody (E5-G5-B5-E6 arpeggio blip). |
| **2. `mochi`** | `mochi`, `zundamochi`, `mochi!` | Renders ASCII Zunda Mochi card art: `🍡 [ 🫛🫛🫛 ]` with a recipe fun fact: *"Zunda Mochi paste is made from sweet crushed young edamame beans!"* | **Mochi Squish SFX**: Low-pass filtered pitch-bend slide (`sine` 400Hz -> 600Hz -> 200Hz). |
| **3. `edamame`** | `edamame`, `pea`, `zundapea` | Triggers a visual burst of green pea emoji floating across the CLI window and prints an edamame trivia card. | **Pea Pop SFX**: Staccato triple high-pitch bubble pop (`1200Hz`, `1500Hz`, `1800Hz` square blips). |
| **4. `zunda`** | `zunda`, `zundamon` | Renders ASCII Zundamon Avatar portrait and cheerleader ascii banner: `(๑>◡<๑) ZUNDA POWER MAX!` | **Cheer Fanfare**: 4-note victory flourish (C5-E5-G5-C6). |
| **5. `secret`** | `secret`, `hidden`, `easteregg` | Unlocks secret developer terminal mode `zunda@secret:~$` and reveals the legendary recipe formula for `"Zunda Paradise"`. | **Secret Reveal SFX**: Mystery descending synth chime with low-frequency resonance. |
| **6. `dance`** | `dance`, `zundadance` | Plays a 4-frame ASCII animation sequence in the CLI log showing Zundamon dancing: `(>'-')>` `^('-')^` `<('-'<)` `v('-')v` `nanoda!` | **Dance Beat SFX**: Rhythmic 4-step upbeat arpeggio synth sequence. |
| **7. `matrix`** | `matrix`, `hack`, `cyber` | Instantly sets theme to `matrix`, turns text bright neon green `#00ff66`, and outputs a simulated Zunda-OS 95 phosphor code stream: `[KERNEL]: HACKING EDAMAME MAINFRAME... ACCESS GRANTED!` | **Matrix Sound Effect**: Glitchy fast-frequency sweep sound. |

---

## 4. Audio Feedback Integration Architecture

Audio feedback is integrated directly with the Web Audio synthesizer in `site/assets/audio_engine.js`. 

To ensure complete modularity without relying on external WAV/MP3 audio files, `terminal.js` invokes synthesized helper functions attached to `window.ZundaAudio` or custom audio functions added to `audio_engine.js`:

```javascript
// Sound Trigger Interface Map for ZundaCLI.exe:
1. Typing Input        -> playKeySFX(key)              // Synthesizes mechanical keyboard click
2. Command Submit      -> playKeySFX('Enter')          // Synthesizes carriage return tone
3. Core Command Exec   -> playClickSFX('down')         // Standard button press click
4. Recipe Cooking      -> playClickSFX('start')        // Ascending dual-tone execution chime
5. Gathering Swing     -> playWindowSFX('drag')        // Pitch-drop swing impact sound
6. Loot Drop Harvest   -> playWindowSFX('maximize')    // Bright 3-note ascending reward chime
7. Theme Change        -> playWindowSFX('focus')       // Dual sine tone transition sound
8. BGM Toggle          -> toggleCozyBGM()              // Starts/Stops ambient pentatonic pad loop
9. Easter Egg Chimes   -> playEasterEggSFX(eggType)    // Synthesizes specific easter egg fanfare
```

---

## 5. Implementation Design for `site/terminal.js`

To maintain clean separation of concerns and high readability, `terminal.js` should follow this functional structure:

```javascript
/**
 * ZundaCLI Terminal Engine
 * Interactive CRT Phosphor Terminal for Zunda-OS 95
 */
(function() {
  // Command registry
  const COMMAND_REGISTRY = {
    help: handleHelp,
    info: handleInfo,
    about: handleInfo,
    recipes: handleRecipes,
    cook: handleRecipes,
    gather: handleGather,
    harvest: handleGather,
    mine: handleGather,
    lore: handleLore,
    play: handlePlay,
    roblox: handlePlay,
    launch: handlePlay,
    music: handleMusic,
    bgm: handleMusic,
    clear: handleClear,
    cls: handleClear,
    version: handleVersion,
    ver: handleVersion,
    theme: handleTheme,
    rojo: handleRojo,
    wally: handleWally,
    // Easter Eggs
    nanoda: handleNanoda,
    mochi: handleMochi,
    edamame: handleEdamame,
    zunda: handleZunda,
    secret: handleSecret,
    dance: handleDance,
    matrix: handleMatrix
  };

  // Parser & Dispatcher
  function parseAndExecute(rawInput) {
    const trimmed = rawInput.trim();
    if (!trimmed) return;

    const parts = trimmed.split(/\s+/);
    const cmd = parts[0].toLowerCase();
    const args = parts.slice(1);

    if (COMMAND_REGISTRY[cmd]) {
      COMMAND_REGISTRY[cmd](args, rawInput);
    } else {
      handleUnknownCommand(cmd);
    }
  }
})();
```

---

## 6. Verification Strategy

1. **Syntactical Verification**: Validate that all 12 core commands and 7 easter egg keywords execute without errors or exceptions in browser console.
2. **Data Consistency Audit**: Confirm that recipes (`CraftConfig.lua`), gathering nodes (`GatherConfig.lua`, `MineableConfig.lua`), lore (`ZoneLoreConfig.lua`), and packages (`wally.toml`) match project source files exactly.
3. **Audio Verification**: Verify that every command invocation triggers appropriate synthesized SFX via `ZundaAudio` without missing AudioContext gesture errors.
4. **Theme Verification**: Verify that `theme` and `matrix` commands correctly apply visual CSS attributes (`data-terminal-theme`) to the CRT container.
