# 🫛 Zundamon’s Kitchen V2

> Gather slowly. Cook carefully. Feed somebody well.

**Zundamon’s Kitchen** is a cozy Roblox cooking adventure about harvesting ingredients, learning rhythm-based recipes, serving village guests, and travelling with a pea-spirit companion.

[Getting started](GETTING_STARTED.md) · [Contributing](CONTRIBUTING.md) · [Production handoff](docs/PRODUCTION_AND_LEVEL_DESIGN_HANDOFF.md) · [UI roadmap](docs/UI_UX_OVERHAUL_PLAN.md) · [Credits](CREDITS.md)

---

## The game today

The production baseline has a verified **Harvest → Collect → Cook → Serve → Reward** loop, persistence recovery, fishing, quests, companion following and dialogue, respawn-safe interfaces, and Rojo-authored resource behavior.

The codebase is undergoing a careful hybrid ECS migration:

- Matter ECS owns world simulation and transient entities.
- Services own persistence, rewards, economy, and domain transactions.
- Server adapters own remotes and request validation.
- Controllers and React-Lua own player interface state.

This is a working foundation, not a finished release. Build success is not treated as runtime proof.

## 🌱 Experience pillars

- **Gather:** trees, rocks, flowers, crops, and fishing spots provide useful ingredients.
- **Cook:** timing and recipe knowledge turn ingredients into dishes.
- **Serve:** guests exchange requested dishes for gold and chef XP.
- **Grow:** chef ranks, collections, quests, decorating, and village improvements provide long goals.
- **Befriend:** companions have distinct appearances, dialogue, and server-authoritative gifts.

The visual language combines mochi cream, edamame green, blush accents, friendly type, and the clear pressed/active states developed for the repository’s **Zunda-OS** website in [`site/`](site/).

## Five-minute setup

Requirements: Git, Roblox Studio, the Rojo Studio plugin, and the pinned command-line tools.

```powershell
git clone https://github.com/fromage3900/Zundamons-Kitchen-V2.git
cd Zundamons-Kitchen-V2
git switch codex/core-production-baseline
rokit install
wally install
rojo serve default.project.json --port 34872
```

Then:

1. Open the correct Zundamon’s Kitchen V2 place in Roblox Studio.
2. Connect the Rojo plugin to `localhost:34872`.
3. Confirm the place name before syncing or testing.
4. Press Play and check Studio Output for server/client bootstrap errors.
5. Run the smoke loop: harvest, collect, cook, serve, reward, respawn, and rejoin.

If `rokit` is unavailable, follow the alternative setup in [Getting Started](GETTING_STARTED.md).

## 🧺 Choose the right branch

| Branch | Purpose | Rule |
| --- | --- | --- |
| `codex/core-production-baseline` | Stable demo and level-design baseline | Protect it; use reviewed commits only |
| `codex/expanded-gameplay-experiments` | Pea Wheel, HUD V2, and bounded gameplay prototypes | Never publish directly |
| `main` | Historical/default integration branch | Do not assume it contains the newest recovery work |

Experimental work returns to production as small reviewed commits. Do not merge the experiment branch wholesale.

## 🛠 Everyday workflow

```powershell
git status --short --branch
git pull --ff-only
wally install
rojo serve default.project.json --port 34872
```

Before committing, run every gate independently:

```powershell
stylua --check <files-you-changed>
selene <files-you-changed>
rojo build default.project.json --output build/ZundamonsKitchenV2.rbxlx
git diff --check -- <files-you-changed>
git status --short
```

Full-source formatting still contains inherited debt. Do not bulk-format unrelated files to make a focused change pass.

## 🏡 Level designers

The authored world is Studio-owned. Code and reusable configuration are Rojo-owned.

- Keep `"$ignoreUnknownInstances": true` under `Workspace` in `default.project.json`.
- Save the Studio place before stopping Rojo or changing branches.
- Never place gameplay scripts inside imported meshes.
- Use tags and attributes from [Resource Node Authoring](docs/RESOURCE_NODE_AUTHORING.md).
- Use [Zundarooms Authoring](docs/ZUNDAROOMS_AUTHORING.md) for mystery spaces.
- Use the [Chef Master import contract](docs/ZUNDAMON_CHEF_MASTER_IMPORT.md) for the progression NPC and companion variants.

## ⚠ Must know before editing

- `PlayerDataService` is the persistence boundary.
- `RewardCore` is the reward and companion-buff boundary.
- `MarketplaceService` is the sole `ProcessReceipt` owner.
- Monetization fails closed and contains placeholder IDs. Do not enable it casually.
- External LLM chat has been removed from the production baseline.
- Remotes are owned by explicit server adapters; clients never decide rewards.
- UI scripts create or locate interfaces through `ClientGuiBootstrap`; top-level ScreenGuis survive respawn and modal panels start hidden.
- Matter systems use the explicit ordered registry. Do not restore recursive system loading.

Never stage owner source assets accidentally. In particular, do not use `git add -A` in a mixed workspace containing `.blend`, `.blend1`, `crucialassets/`, generated builds, or another agent’s work.

## Project map

```text
src/client/                         controllers, HUD, VN, and player input
src/server/                         adapters, services, systems, and validation
src/shared/ConfigurationFiles/      canonical gameplay and UI configuration
src/shared/components/              Matter component definitions
src/shared/Models/                  repository-authored reusable models
src/shared/AssetRegistry.lua        asset ID single source of truth
src/Workspace/                      Rojo-owned world scaffolding only
docs/                               recovery, authoring, production, and UX plans
docs/ASSET_MANAGEMENT.md           asset collaboration guide
docs/MCP_WORKFLOW.md               live Studio automation guide
scripts/                            build and extraction pipelines
site/                               Zunda-OS creative hub and design reference
default.project.json                Rojo DataModel mapping
wally.toml                          Roblox dependencies
aftman.toml / mise.toml             pinned toolchains
```

## Packages

Matter, React-Lua, ReactRoblox, ProfileService, ReplicaService, Promise, and Signal are managed through Wally. Generated `Packages/` and `ServerPackages/` directories are not committed.

## For collaborators and coding agents

Read these in order:

1. [`AGENTS.md`](AGENTS.md)
2. [Getting Started](GETTING_STARTED.md)
3. [Production and Level Design Handoff](docs/PRODUCTION_AND_LEVEL_DESIGN_HANDOFF.md)
4. [Phase 3 Acceptance Status](docs/PHASE3_ACCEPTANCE_STATUS.md)
5. [Collaborator Prompts](docs/COLLABORATOR_PROMPTS.md)
6. [Asset Management & Collaboration Guide](docs/ASSET_MANAGEMENT.md)
7. [MCP Workflow Guide](docs/MCP_WORKFLOW.md)

One task, one concern, one reviewable commit. Report static checks separately from Studio evidence. Stop and ask before changing schemas, production remotes, paid-product configuration, receipt ownership, terrain preservation, or publishing.

## Licensing and safety

Code is provided under the [MIT License](LICENSE). Asset and character rights may have different terms; consult [CREDITS.md](CREDITS.md) before commercial use. Keep all player-facing text age-appropriate, filter user-generated text through Roblox services, and never commit credentials or API keys.

---

<p align="center"><strong>🫛 Make something warm, leave the kitchen kinder. 🌸</strong></p>
