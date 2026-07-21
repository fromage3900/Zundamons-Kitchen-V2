# Zundamon's kItchen V2

A cooperative, massively persistent kitchen life-sim Roblox experience — gather ingredients, cook dishes with rhythm minigames, serve guests, and build your restaurant empire with your Zundamon companion.

> **Status:** Active recovery and hybrid ECS migration. Phase 2 restores deterministic boot; end-to-end gameplay parity is not yet certified. See [Phase 2 Boot Recovery](docs/PHASE2_BOOT_RECOVERY.md). · [MIT License](LICENSE) · [Privacy](PRIVACY.md) · [Security](SECURITY.md)

---

## 🎮 What Is This?

Zundamon's kItchen is a cozy Roblox experience featuring:
- **Gathering** — Harvest ingredients from world resource nodes (berries, mushrooms, wheat, etc.)
- **Cooking** — Rhythm-game minigames to craft recipes with combo scoring
- **Serving** — NPC guests arrive and order dishes; serve to earn gold
- **Companions** — Zundamon companions follow you, provide buffs, and have VN dialogues
- **Quests** — 68+ quests across gathering, cooking, serving, and exploration
- **Building** — Place furniture, decorate your kitchen plot
- **AI Mentor** — Optional LLM-powered Zundapal chat (requires Studio secrets)
- **Day/Night + Weather** — Dynamic sky, clouds, rain, aurora effects

---

## 🚀 Quick Start (5 Minutes)

```powershell
# 1. Clone
git clone https://github.com/fromage3900/Zundamons-kItchen-V2.git
cd Zundamons-kItchen-V2

# 2. Install tools (pick one)
mise install           # Option A: Mise (recommended — manages all tools)
npm install            # Option B: Node.js only (Rojo + StyLua via npm)

# 3. Install Wally packages (ECS, React, ProfileService)
wally install

# 4. Start syncing
rojo serve

# 5. Open the place file in Studio → Connect Rojo plugin → Press Play
```

> **New to all this?** See the full [Getting Started Guide](GETTING_STARTED.md) — it walks through every install step from scratch.

---

## 📁 Project Structure

```
Zundamons-kItchen-V2/
├── src/
│   ├── client/                 # StarterPlayerScripts (43 files)
│   │   ├── Controllers/        #   HarvestController
│   │   ├── systems/            #   Matter ECS client systems (new)
│   │   └── ui/                 #   React-Lua components (new)
│   ├── server/                 # ServerScriptService (41 files)
│   │   ├── DevTools/           #   Studio command-bar dev utilities
│   │   ├── Plugins/            #   Runtime effect plugins
│   │   ├── Services/           #   Core services (PlayerData, Admin, LLM, etc.)
│   │   ├── Validation/         #   Server-side harvest validation
│   │   └── systems/            #   Matter ECS server systems (new)
│   ├── shared/                 # ReplicatedStorage
│   │   ├── ConfigurationFiles/ #   41 game config modules (recipes, items, quests, etc.)
│   │   ├── Shared/Config/      #   Pipeline configs (architecture, landscape, VN)
│   │   ├── Shared/Modules/     #   Shared utility modules (MeshProvider, ModifierStack)
│   │   ├── RemoteEvents/       #   Remote event declarations (init.meta.json)
│   │   ├── RemoteFunctions/    #   Remote function declarations
│   │   ├── components/         #   Matter ECS component definitions (new)
│   │   └── ...                 #   Loot, Meshes, Models, ToolRemotes, RewardEvents
│   └── Workspace/              # Game world folder structure (.gitkeep hierarchy)
├── default.project.json        # Rojo project config
├── mise.toml                   # Toolchain versions (Rojo 7.7, Wally 0.3.2, etc.)
├── wally.toml                  # Wally package dependencies
├── selene.toml                 # Linter rules (print/warn = error)
├── stylua.toml                 # Formatter settings (tabs, 120-col)
├── package.json                # NPM scripts (lint, build, serve)
└── docs/                       # Architecture, design system, security docs
```

### Rojo Mapping (How Disk → Studio)

| Disk Path | Studio Location | What's There |
|-----------|-----------------|--------------|
| `src/server/` | `ServerScriptService` | All server scripts (flat) |
| `src/client/` | `StarterPlayer.StarterPlayerScripts` | All client scripts (flat) |
| `src/shared/ConfigurationFiles/` | `ReplicatedStorage.ConfigurationFiles` | 41 config modules |
| `src/shared/RemoteEvents/` | `ReplicatedStorage.RemoteEvents` | Event declarations |
| `src/shared/Shared/Config/` | `ReplicatedStorage.Shared.Config` | Pipeline configs |
| `src/shared/Shared/Modules/` | `ReplicatedStorage.Shared.Modules` | Utility modules |
| `src/Workspace/` | `Workspace` | World folder hierarchy |

> **Why this mapping?** All scripts use `game.ReplicatedStorage.ConfigurationFiles.X` — the Rojo config maps each subdirectory individually to preserve these paths.

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| [Mise](https://mise.jdx.dev/) | — | Universal toolchain manager (one `mise install` gets everything) |
| [Rojo](https://rojo.space/) | 7.7.0 | File sync between VS Code and Roblox Studio (preserves Studio level design via `$ignoreUnknownInstances`) |
| [Wally](https://wally.run/) | 0.3.2 | Roblox package manager (Matter, React, ProfileService) |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | 2.5.2 | Lua code formatter |
| [Selene](https://kampfkarren.github.io/selene/) | 0.27.1 | Lua linter |
| [Blink](https://github.com/1axen/blink) | latest | Network event compiler |
| [Matter](https://matter-ecs.github.io/matter/) | 0.8.4 | Entity-Component-System framework |
| [React-Lua](https://github.com/jsdotlua/react-lua) | 17.1.0 | Declarative UI rendering |
| [ProfileService](https://madstudioroblox.github.io/ProfileService/) | 1.0.4 | Player data persistence |
| [ReplicaService](https://madstudioroblox.github.io/ReplicaService/) | 1.0.1 | State replication |

---

## 📋 NPM Scripts

| Command | What It Does |
|---------|--------------|
| `npm run rojo:serve` | Start Rojo file sync (connect Studio plugin) |
| `npm run rojo:build` | Build `.rbxl` from project config |
| `npm run lint` | Run StyLua format check + Selene lint |
| `npm run lint:stylua` | StyLua format check only |
| `npm run lint:selene` | Selene lint only |

---

## 🔐 The Iron Gate (Code Quality)

Before any code reaches `main`:

1. **`stylua src/`** — Auto-format all Lua files
2. **`selene src/`** — Lint check (⚠️ `print()`/`warn()` are **errors**, not warnings)
3. **`rojo build`** — Verify the project compiles
4. **PR Review** — Fill out the template, get approval
5. **CI Pipeline** — GitHub Actions runs all checks automatically

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide covering:
- Branch naming conventions
- Code style rules (naming, formatting, architecture)
- PR checklist
- How to report issues

---

## 📖 Documentation

| Document | What It Covers |
|----------|---------------|
| [AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md) | Multi-agent coordination guide for Antigravity, Cline, DeepSeek, & Ollama |
| [GETTING_STARTED.md](GETTING_STARTED.md) | Step-by-step setup for first-timers |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branch workflow, code style, PR process |
| [CREDITS.md](CREDITS.md) | Asset licenses and attributions |
| [PRIVACY.md](PRIVACY.md) | Player data handling and AI chat policy |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting and secure dev practices |

---

## ⚖️ License

[MIT License](LICENSE) — see [CREDITS.md](CREDITS.md) for third-party asset licenses.

*This is a fan project. Zundamon is a character from the ZUNKO PJ project. No commercial use is intended.*
