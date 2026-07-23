# Production and Level Design Handoff

## Safe baseline

Use `codex/core-production-baseline` for production. Expanded mechanics belong on `codex/expanded-gameplay-experiments`; never merge that branch wholesale. Bring proven changes back as small reviewed commits after build, static, and Studio smoke gates pass.

Never add the local Blender files or `crucialassets/` to Git. Keep `Workspace.$ignoreUnknownInstances` set to `true` in `default.project.json` so Rojo cannot remove manually authored terrain, meshes, or level geometry.

## Level designer workflow

1. Check out and pull the production baseline before a session.
2. Open the intended Studio place, connect Rojo, and confirm the place name.
3. Build terrain and geometry in Studio. Use `RESOURCE_NODE_AUTHORING.md` for tagged trees, rocks, flowers, and Kenney mesh swaps; use `ZUNDAROOMS_AUTHORING.md` for Zundaroom spaces.
4. Save the Studio place before changing branches or stopping Rojo. Never publish from the experiment branch.

Do not edit persistence, schemas, remotes, receipt ownership, or startup bootstraps during a level-design session.

## Startup systems that materially affect play

- Profile/data startup gates inventory, currency, progression, companions, and rewards.
- Tool/resource startup attaches harvest behavior to tagged world objects.
- Guest management starts serving and guest timeout lifecycles.
- Matter bootstraps start transient simulation and must remain ordered and single-run.
- GUI bootstrap owns respawn-safe UI; modal panels begin hidden.
- Marketplace startup owns the sole `ProcessReceipt` callback and currently fails closed.
- External Zundapal LLM chat/hints were removed; scripted companion dialogue remains.

Avoid new top-level startup scripts for experiments. Prefer an explicit adapter/service and the ordered system registry.

## Monetization launch gate

`MarketplaceConfig.enabled` is intentionally `false`, and current IDs are placeholders. Before selling anything:

1. Create products under the correct published experience and replace every placeholder ID.
2. Verify client display and server receipts use the canonical config.
3. Test success, cancellation, delay, duplication, disconnect, and rejoin in a private published build.
4. Confirm every grant uses `PlayerDataService` and `MarketplaceService` remains the only receipt owner.
5. Confirm durability after rejoin, then enable monetization in a dedicated reviewed release commit.

Favor optional cosmetics, decorating, companion expression, and convenience that preserves cozy progression.

## Pre-publish checklist

- Stop playtest and save the place; publish only from the production baseline after a recoverable Studio backup.
- Confirm no accidental runtime files are modified.
- Run StyLua, Selene, Rojo build, and `git diff --check` independently.
- Fresh-server smoke: harvest, collect, cook, serve, one reward/HUD update, respawn, and rejoin.
- Smoke fishing once and confirm one session/one award.
- Confirm modal UI starts hidden, top-level UI survives respawn, and paid prompts remain unavailable.

Keep production boring: small commits, explicit migrations, fail-closed paid systems, no external-cost integrations by default, and one authoritative owner per remote and transaction.

