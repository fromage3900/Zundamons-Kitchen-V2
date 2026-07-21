# Phase 2 Boot Recovery

## Outcome

Phase 2 restores a deterministic, reviewable bootstrap without claiming that the unfinished migration is feature-complete. Server and client Matter systems now use explicit ordered registries; proof-of-concept item grants and random cooking input are no longer production entrypoints; persistence and reward ownership remain with `PlayerDataService` and `RewardCore`.

## Tool and connection status (2026-07-21)

| Gate | Result | Evidence |
| --- | --- | --- |
| Rojo CLI | PASS | Pinned Rojo 7.7.0; `rojo build default.project.json` succeeds. |
| Rojo server | PASS | Listening on `127.0.0.1:34872`. |
| Rojo Studio sync | BLOCKED | The open Studio DataModel still exposes the pre-recovery tree. The 7.7.0 plugin was installed/updated, but Studio must reload the plugin and connect to `localhost:34872`. |
| chrxxs Studio MCP | PASS | One active Studio instance (`Zundamon'sKitchenV2`), Edit DataModel available, live Luau queries succeed. |
| Legacy MCP conflict | PASS | No listener on port 28821 and no live script containing the stale bridge marker. |
| Wally | PASS | 0.3.2. |
| StyLua tool | PASS | `@johnnymorganz/stylua-bin` 2.5.2 resolves; the prior nonexistent package command is removed. |
| Focused StyLua | PASS | All Phase 2 changed Lua files pass `--check`. |
| Full StyLua baseline | FAIL | Unrelated inherited source remains unformatted. This is no longer masked by Rojo build success. |
| Selene tool | PASS | 0.27.1 with generated Roblox standard library. |
| Full Selene baseline | FAIL | 15 errors, 332 warnings, 0 parse errors; tracked separately from build success. |
| Rojo serialization | PASS | `build/phase2-boot.rbxl` generated successfully. |
| Git whitespace | PASS | `git diff --check` succeeds. |

## Runtime corrections

- Server bootstrap registers only the production-ready cooking validation system instead of recursively requiring every module and utility.
- Client bootstrap registers companion following and streaming only. React inventory experiments, random cooking commands, and the delayed fake item grant were removed from startup.
- Component imports now match the actual `ReplicatedStorage.components` Rojo mapping.
- Boot-critical RemoteEvent, RemoteFunction, and BindableEvent classes are declared in Rojo metadata.
- `PlayerDataService` initializes default data through a valid forward declaration.
- The unfinished Profile/Replica replacement is now a dormant `LegacyProfileDataManager` ModuleScript, preventing a second persistence owner from auto-running.
- Several confirmed startup faults were corrected: HUD syntax, sprint compatibility, guest template shape, material UI fallbacks, inventory UI fallbacks, and HUD button naming.

## Explicitly deferred

- Fishing authority remains a Phase 3 domain decision. Its ECS system is deliberately not boot-registered while the RemoteFunction adapter contract is rebuilt.
- The broader Selene and formatting debt is recorded rather than mixed into boot-recovery commits.
- Full Harvest -> Cook -> Serve -> Reward and persistence parity require a Rojo-synchronized Studio smoke test, followed by Phase 3 authoritative-domain work.

## Rollback and commit boundaries

- `306e374` tooling and independent gates.
- `79b5253` replicated remote contracts.
- `1333aa8` server bootstrap and authoritative data ownership.
- `35ab045` client bootstrap and UI startup safety.
- Pre-Phase-2 rollback point: `e25411a`.
- Pre-recovery archive: `codex/archive-phase1-pre-recovery-20260721` at `060a120`.

No branch was pushed or published.

## Rebuild decision

Do not discard the project for a blank-slate rewrite. The fastest production route is a controlled in-place rebuild (strangler migration): retain the authored world, content/configuration, proven services, and working UI behaviors while replacing one authoritative gameplay domain at a time behind validated adapters. A clean-room rewrite would recreate a large content surface and rediscover Studio-only contracts without removing the need for parity testing. Reconsider a full rewrite only if the product scope changes materially or the retained code/assets cannot be trusted.

## Remaining live acceptance gate

1. Restart or reload Studio so the newly installed Rojo 7.7.0 plugin is active.
2. Connect the plugin to `localhost:34872` while `rojo serve` is running.
3. Confirm the live remote classes and `LegacyProfileDataManager` match the repository.
4. Run a focused server/client playtest and record console output.

