# Getting Started

This guide gets a new collaborator from a clean clone to a safe Studio playtest. Read `AGENTS.md` before editing.

## 1. Install

Install:

- Git
- Roblox Studio
- Rojo Studio plugin
- Rokit, or Mise as the fallback tool manager

Clone and install pinned tools:

```powershell
git clone https://github.com/fromage3900/Zundamons-Kitchen-V2.git
cd Zundamons-Kitchen-V2
git switch codex/core-production-baseline
rokit install
wally install
```

Mise fallback:

```powershell
mise install
wally install
```

Do not rely on the npm Rojo package for gameplay work; the repository’s Roblox toolchain is pinned separately.

## 2. Verify Git before opening Studio

```powershell
git status --short --branch
git log -5 --oneline
git remote -v
```

Expected production branch: `codex/core-production-baseline`.

Do not stage local Blender files, `crucialassets/`, generated place files, packages, `.agents` activity, or another collaborator’s work. Use explicit paths with `git add`.

## 3. Connect Rojo

```powershell
rojo serve default.project.json --port 34872
```

In Studio:

1. Open the intended V2 place.
2. Save a recoverable local or published version.
3. Open Plugins → Rojo.
4. Connect to `localhost:34872`.
5. Confirm scripts appear in the expected services.

`Workspace.$ignoreUnknownInstances` must remain `true`. It protects manually authored terrain, meshes, and level geometry.

Studio automation uses `@chrrxs/robloxstudio-mcp@latest` when available. Verify the connected instance before executing anything. Do not run a competing port-28821 MCP server.

## 4. Understand ownership

| Work | Source of truth |
| --- | --- |
| Luau scripts and configuration | Git under `src/` |
| Terrain and hand-authored level geometry | Roblox Studio place |
| Reusable repository models | `src/shared/Models/` |
| Wally packages | `wally.toml`; generated folders stay ignored |
| Recovery and design decisions | `docs/` |

Avoid editing Rojo-owned scripts in Studio because the next sync can replace them.

## 5. First smoke test

Start a fresh server and verify:

1. Server and client boot without red errors.
2. Equip the correct tool and harvest a node.
3. Collect its loot and confirm inventory changes.
4. Cook one available recipe.
5. Serve the correct dish to one guest.
6. Confirm gold, XP, and HUD update exactly once.
7. Complete one fishing attempt.
8. Respawn; top-level UI remains and modals stay hidden.
9. Rejoin; inventory, currency, progression, and companion state return.

Rojo build success alone does not certify this runtime loop.

## 6. Make a focused change

- Create or switch to the correct feature/experiment branch.
- Inspect before editing.
- Keep transactions in services and simulation in ECS systems.
- Keep UI state in controllers/React, not gameplay ECS.
- Preserve existing user changes in a dirty worktree.
- Add an acceptance scenario and rollback note for behavioral work.

For experimental UI such as the Pea Wheel, use `codex/expanded-gameplay-experiments` and follow [the UI plan](docs/UI_UX_OVERHAUL_PLAN.md).

## 7. Check and commit

Run checks independently against the files you changed:

```powershell
stylua --check <changed-luau-files>
selene <changed-luau-files>
rojo build default.project.json --output build/ZundamonsKitchenV2.rbxlx
git diff --check -- <changed-files>
git status --short
```

Then stage explicit paths:

```powershell
git add path/to/file1 path/to/file2
git diff --cached --check
git diff --cached --stat
git commit -m "type(scope): concise change"
```

Do not commit or publish merely because a build passed. Record the Studio playtest result in the PR.

## 8. Before publishing

- Use `codex/core-production-baseline`, never the experimental branch.
- Stop play mode and save the place.
- Take a recoverable Studio version.
- Repeat the fresh-server and rejoin smoke tests.
- Confirm monetization and external-cost integrations remain disabled unless deliberately released.
- Review experience maturity, asset rights, thumbnails, descriptions, and Roblox policy settings.
- Publish only with owner approval.

Welcome to the kitchen. Start small and leave it safer than you found it. 🫛
