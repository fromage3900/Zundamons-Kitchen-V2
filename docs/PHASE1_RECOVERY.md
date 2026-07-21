# Phase 1 Recovery Record

## Anchors

- Remote rollback anchor: `925b658547b88db12a235debccd56ece3c68311a` (`origin/main` at the start of Phase 1).
- Untouched migration archive: branch `codex/archive-phase1-pre-recovery-20260721`, commit `060a120`.
- Reconstructed recovery branch: `codex/phase1-recovery`.

The archive commit contains every tracked modification and every Git-visible untracked file present before reconstruction. Local ignored dependencies and the embedded `.roblox-mcp` checkout remain on disk and were not deleted.

## Classification policy

| Class | Repository treatment |
| --- | --- |
| Gameplay, shared contracts, ECS, UI, and Rojo mappings | Track in subsystem commits. |
| Wally manifests and lockfiles | Track with toolchain/Rojo configuration. |
| Project documentation and agent audit records | Track separately from runtime code. |
| `opencode.json` using `@chrrxs/robloxstudio-mcp` | Track as project MCP configuration. |
| Package installs, Wally binaries, Roblox builds, and Rojo sourcemaps | Ignore as generated output. |
| `Saved/`, `.agents/mcp/`, `.opencode/`, and `.roblox-mcp/` | Ignore as local runtime or cache state. |

## Reconstruction rule

Changes are replayed from the archive by ownership boundary. Each commit must be independently explainable and reversible. No Phase 1 commit is pushed or published automatically.

## Verification

Phase 1 is complete only when:

1. The recovery branch has no unexplained tracked or untracked changes.
2. Its tracked snapshot matches the archive for all retained project files.
3. Differences from the archive are limited to documented local/generated exclusions and this recovery policy.
4. Commit boundaries separate repository policy, documentation/audits, project structure, shared contracts, server domains, and client domains.
5. `git diff --check` passes and Git reports deterministic LF normalization for repository text.
