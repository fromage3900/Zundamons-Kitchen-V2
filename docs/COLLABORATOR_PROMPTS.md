# Collaborator Prompts

## Level design

> Work only on layout, terrain, lighting, props, and tagged resource authoring. Preserve `Workspace.$ignoreUnknownInstances = true`. Do not edit persistence, remotes, marketplace code, schemas, or startup bootstraps. Follow `docs/RESOURCE_NODE_AUTHORING.md` and `docs/ZUNDAROOMS_AUTHORING.md`. Save the Studio place, report changed areas and tags/attributes, and do not publish without the owner.

## Expanded gameplay experiment

> Work only on `codex/expanded-gameplay-experiments`. Prototype one bounded mechanic behind a configuration flag or isolated adapter. Do not change live product IDs, persistence schemas, receipt ownership, or production remotes. Add an acceptance scenario and rollback note. Never publish this branch or merge it wholesale.

## Production maintenance

> Treat `codex/core-production-baseline` as protected. Make the smallest reviewable fix, preserve the hybrid boundary (ECS simulation; services/adapters for persistence, networking, transactions, and UI), and verify StyLua, Selene, Rojo, diff check, and the affected Studio loop. Do not enable monetization or external API costs without explicit owner approval and private-release receipt testing.
