# Shared Asset Hub — Server-Replicated Storage as Source of Truth

> How Zundamon's Kitchen treats **ReplicatedStorage** as the runtime hub for
> shared content, git as the durable hub for source control, and what both must
> contain so the long-term working state is unbreakable.

## Why this doc exists

The game has three content owners (Rojo-authored code, Studio-authored level
geometry, and Wally packages). Without a written convention, new systems pick
random homes and the place + repo drift apart. This document pins the hub
contract: **everything shared and sharable flows through ReplicatedStorage**;
everything durable flows through **git via Rojo**.

## The ReplicatedStorage hub (runtime source of truth)

| Child | Owner | Content | Sync policy |
|---|---|---|---|
| `ConfigurationFiles` | Rojo | Gameplay/UI config, loot tables, dialogue, ClientGuiBootstrap | `$path` from `src/shared/ConfigurationFiles` |
| `Shared/Config` + `Shared/Modules` | Rojo | NPC config, UI assets, architecture loader | `$path` from `src/shared/Shared/*` |
| `components` | Rojo | Matter components (cooking, fishing, companion) | `$path` from `src/shared/components` |
| `Models` | Hybrid | Reusable models; keep `$ignoreUnknownInstances: true` | `$path` from `src/shared/Models` + Studio additions |
| `Meshes` | Rojo | Repository-held meshes | `$path` from `src/shared/Meshes` |
| `RemoteEvents` / `RemoteFunctions` / `RewardEvents` / `ToolRemotes` | Rojo | Every remote as `.model.json` | `$path` from `src/shared/*` |
| `AssetRegistry` | Rojo | Asset ID single source of truth | `src/shared/AssetRegistry.lua` |
| `QuestConfig`, `DataSchema`, `Loot`, `Packages` | Rojo | Canonical modules + Wally | `$path`/`Packages` |

Clients read from this hub only. State writes flow **client → remote →
server adapter → service**; clients never decide rewards or mutate hub data.

## MaterialService as the material hub

`MaterialService` holds the persistent `MaterialVariant`s used by the Zunda
material pipeline (see [src/Plugins/README.md](../src/Plugins/README.md)).
Variants persist with the place and survive Rojo sync through
`$ignoreUnknownInstances`. The canonical **values** live in git at
`src/Plugins/ZundaPalette.lua`; Studio and git must agree (edit the module,
then re-run the plugin's Register to copy into the place).

## Git hub (durable source of truth)

- Rojo-owned: everything under `src/` mapped by `default.project.json`.
- Studio-owned: level content under Workspace/ServerStorage (git does NOT hold
  it; the built `ZundamonsKitchen.rbxl` artifact is the shareable snapshot).
- Wally: `Packages/` + `ServerPackages/` are gitignored; `wally.toml` is the
  durable dependency manifest.
- Built artifacts: CI uploads `ZundamonsKitchen.rbxl` + `sourcemap.json`
  (90-day `rojo-build` artifact; `vX.Y.Z` tag → GitHub Release).

## Authoring rules

1. New shared config → `src/shared/ConfigurationFiles/` with a `default.project.json` entry.
2. New remote → `src/shared/RemoteEvents|RemoteFunctions|RewardEvents/` as a
   `.model.json`; server ownership in an adapter/service, never ad-hoc.
3. New reusable visual asset → `src/shared/Models/` or `src/shared/Meshes/` (repo) or
   Studio place via ignore-unknown (level-owned).
4. New MaterialVariant → add to `src/Plugins/ZundaPalette.lua`, let the material
   plugin register it (or paste its Export Config snippet).
5. Never `git add -A`; keep owner source assets (`crucialassets/`, `.blend*`,
   generated builds) out of commits.

## Playtest feedback flow

`docs/PLAYTEST_NOTES.md` is the intake hub; see README "Live playtest notes".