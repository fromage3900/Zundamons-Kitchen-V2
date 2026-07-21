# Phase 2 Boot Recovery

## Outcome

Phase 2 restores a deterministic, reviewable bootstrap without claiming that the unfinished migration is feature-complete. Server and client Matter systems now use explicit ordered registries; proof-of-concept item grants and random cooking input are no longer production entrypoints; persistence and reward ownership remain with `PlayerDataService` and `RewardCore`.

## Tool and connection status (2026-07-21)

| Gate | Result | Evidence |
| --- | --- | --- |
| Rojo CLI | PASS | Pinned Rojo 7.7.0; `rojo build default.project.json` succeeds. |
| Rojo server | PASS | Listening on `127.0.0.1:34872`. |
| Rojo Studio sync | PASS | Studio is connected to localhost:34872; repository bootstraps, remote classes, and renamed persistence modules were verified live. |
| chrxxs Studio MCP | PASS | v2.22.3 listens on 127.0.0.1:58741; Studio has established connections and /ready succeeds for Edit and Server. |
| Legacy MCP conflict | PASS | RobloxStudioMCP.server.lua was identified as the port-28821 poller and quarantined as .disabled-phase2; no 28821 listener remains. |
| Wally | PASS | 0.3.2. |
| StyLua tool | PASS | `@johnnymorganz/stylua-bin` 2.5.2 resolves; the prior nonexistent package command is removed. |
| Focused StyLua bootstrap gate | PASS | The deterministic bootstrap repair set passes the formatter check; later compatibility fixes retain inherited file formatting and remain covered by the separately failing full baseline. |
| Full StyLua baseline | FAIL | Unrelated inherited source remains unformatted. This is no longer masked by Rojo build success. |
| Selene tool | PASS | 0.27.1 with generated Roblox standard library. |
| Full Selene error gate | PASS | 0 errors and 0 parse errors after targeted correctness repairs. |
| Full Selene warning gate | FAIL | 332 inherited warnings, principally deprecated two-argument Instance.new usage; tracked separately from build success. |
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
- Selene correctness errors were eliminated without bulk-reformatting the repository: invalid forward references, React keys, duplicate branches/keys, empty blocks, an admin command argument, and obsolete type checks were repaired.
- Invalid lowercase children metadata was replaced by concrete Rojo .model.json instances; live remotes now match their declared classes.
- The registered cooking wrapper is a real Matter system function and uses the Matter 0.8.5 event iterator contract.
- The unfinished fishing adapter now fails closed instead of returning success without creating or rewarding an authoritative session.
- Nine exact failing scripts embedded in imported Workspace decorations were disabled in Studio; models and geometry were preserved.
- A 35-second playtest and forced respawn completed with no runtime stack traces. HUD and modal interfaces retained ResetOnSpawn = false; modal panels returned hidden.

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

## Live Studio follow-up

Save the open place to retain the Editor-only safety changes: nine imported asset scripts and five scripts inside explicitly documented legacy StarterGui shells were disabled. Other legacy StarterGui scripts still clone briefly before the runtime compatibility cleanup removes them; disabling all remaining embedded StarterGui scripts requires explicit owner approval because some may represent intentionally retained UI behavior.
