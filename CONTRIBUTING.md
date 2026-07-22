# Contributing

Thank you for helping with Zundamon’s Kitchen. The best contribution is small enough to understand, test, and undo.

## Start here

1. Read `AGENTS.md` and [Getting Started](GETTING_STARTED.md).
2. Run `git status --short --branch`.
3. Choose the correct branch.
4. State one bounded objective and its acceptance scenario.
5. Inspect the owning service/controller before editing.

## Branches

- Production-safe work: branch from `codex/core-production-baseline`.
- Gameplay/UI experiments: work on or branch from `codex/expanded-gameplay-experiments`.
- Never publish the experimental branch.
- Do not merge experiments wholesale. Cherry-pick reviewed commits after parity tests.

Suggested names: `feature/<short-name>`, `fix/<short-name>`, or `codex/<short-name>` for Codex-owned work.

## Architecture boundaries

- Matter ECS: world simulation, transient sessions/entities, companions, buffs, and streaming lifecycles.
- Services: persistence, rewards, economy, progression, and atomic domain transactions.
- Server adapters: RemoteEvent/RemoteFunction ownership, rate limits, payload validation, and ECS command handoff.
- Controllers/React: interface state and read-only projections.
- `PlayerDataService`: authoritative player-data boundary.
- `RewardCore`: authoritative reward and companion-buff boundary.
- `MarketplaceService`: sole `ProcessReceipt` owner.

Do not introduce a second implementation of an existing loop.

## Studio and Rojo safety

- Keep `Workspace.$ignoreUnknownInstances = true`.
- Save the Studio place before changing branches or stopping Rojo.
- Confirm the connected place before automation.
- Do not embed scripts inside imported art models.
- Put reusable model variants under `src/shared/Models/` and key behavior through configuration.
- Do not edit Rojo-owned scripts in Studio.

## Git safety

The workspace may contain owner assets and concurrent work. Never stage everything blindly.

```powershell
git status --short
git add path/to/intended-file
git diff --cached --check
git diff --cached --stat
```

Do not stage `.blend`, `.blend1`, `crucialassets/`, packages, generated places, secrets, `.agents` activity, or unrelated website work unless explicitly assigned.

## Luau style

- Format changed files with StyLua; do not bulk-format legacy files.
- Run Selene on changed files.
- Use clear camelCase locals and PascalCase modules/remotes.
- Prefer canonical configuration over duplicate tables.
- Mutators and transactional callbacks must not yield.
- Clean up event connections and entities on timeout, disconnect, streaming removal, and respawn.
- Avoid new globals; existing `_G`/`shared` usage is migration debt.

## UI rules

- Create or locate interfaces through `ClientGuiBootstrap` and `PlayerGui`.
- Top-level ScreenGuis use `ResetOnSpawn = false`.
- Modals begin hidden and register with the UI router as it is introduced.
- UI never inspects unrelated GUI trees to infer gameplay state.
- Support keyboard, touch, and gamepad; icons require labels or tooltips.
- Follow [the UI/UX overhaul plan](docs/UI_UX_OVERHAUL_PLAN.md) for new HUD work.

## Verification

Report each gate independently:

```powershell
stylua --check <changed-luau-files>
selene <changed-luau-files>
rojo build default.project.json --output build/ZundamonsKitchenV2.rbxlx
git diff --check -- <changed-files>
```

Behavioral changes also require focused Studio evidence. For the core loop, test harvest → collect → cook → serve → reward once, plus respawn/rejoin when persistence or UI is involved.

## Pull requests

Include:

- What changed and why.
- Files and system owners affected.
- Static check results.
- Studio scenarios tested.
- Known limitations.
- Rollback method.
- Screenshots or video for UI/level work.

Stop and request owner approval before changing persistence schemas, production remote contracts, marketplace IDs/enablement, receipt ownership, terrain preservation, licensing posture, or publishing.

Be kind in review. Protect the working loop. Leave a clear trail for the next person. 🌱
