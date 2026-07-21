# Contributing to Zundamon's kItchen V2

Thanks for helping build **Zundamon's kItchen**!

## Development Model

- Use **feature branches**: `feature/<short-name>` or `fix/<issue-number>-<description>`
- Open a **Pull Request** targeting `main`
- Prefer small PRs with clear descriptions and playtest steps
- Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md) completely

## Source of Truth: Rojo + `src/`

All gameplay **code and config modules** live under `src/` and sync to Studio via Rojo.

**DO commit:**
- Changes to `.lua` files under `src/`
- Updates to `default.project.json` when Studio hierarchy changes
- Documentation when conventions or architecture change
- Asset pipeline scripts and configs

**DO NOT commit:**
- `*.rbxl`, `*.rbxlx`, `*.rbxmx` — place/model exports (gitignored)
- `build/` outputs
- `node_modules/` or `Packages/`
- `.env` files with secrets

## Code Style

### Formatting
All Lua code must pass **StyLua** formatting:
```bash
stylua src/           # Auto-format
stylua --check src/   # Check without modifying
```

Settings (from `stylua.toml`):
- Column width: 120
- Indent: Tabs (width 4)
- Quotes: Auto-prefer double
- Line endings: Unix (LF)

### Linting
All code must pass **Selene** linting:
```bash
selene src/
```

> **⚠️ The Iron Gate:** `print()` and `warn()` calls are treated as **errors** by our Selene config. Remove ALL debugging statements before committing. Use a logging module instead for permanent diagnostics.

### Naming Conventions
| Element | Convention | Example |
|---------|------------|---------|
| Script files (server) | `PascalCase.server.lua` | `CraftManager.server.lua` |
| Script files (client) | `PascalCase.client.lua` | `HudScript.client.lua` |
| Module files | `PascalCase.lua` | `PlayerDataService.lua` |
| Local variables | `camelCase` | `local playerData` |
| Constants | `UPPER_SNAKE_CASE` | `local MAX_INVENTORY_SLOTS = 9` |
| RemoteEvents | `PascalCase` | `UpdateInventory`, `CraftItem` |
| Config table keys | `PascalCase` | `{ DisplayName = "Zunda Mochi" }` |

### Architecture Rules
1. **Server-authoritative**: Never trust client input. Validate everything server-side.
2. **No globals**: Use `local` for all variables. The `_G` table is only for legacy cross-script communication.
3. **Require via services**: Use `game.ReplicatedStorage`, `game.ServerScriptService`, etc.
4. **Timeout guards**: Always use `WaitForChild(name, timeout)` with a timeout value.
5. **Config-driven**: Game data belongs in `src/shared/ConfigurationFiles/`, not hardcoded in scripts.

## PR Checklist

- [ ] `src/` changes included for any code/config edits
- [ ] `stylua --check src/` passes
- [ ] `selene src/` passes with no errors
- [ ] `rojo build default.project.json -o build/test.rbxl` succeeds
- [ ] Playtested in Studio with Rojo connected
- [ ] No `print()`/`warn()` debugging statements remain
- [ ] No place/model binary files committed

## Reporting Issues

Use GitHub Issues with:
- Steps to reproduce
- Which game systems are affected
- Screenshots/video if UI-related
- Console output if available

## Questions?

Ask in the team chat or open a GitHub Discussion. Everyone was new once! 💚
