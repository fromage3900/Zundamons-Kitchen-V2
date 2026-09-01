# Playtest Echo Pipeline — Handoff

Status: committed (08ba56b), files byte-identical to HEAD, structurally verified.

## What the pipeline does

Captures a lightweight Studio session trace, archives it, and appends an error
summary + Zundarooms status-event timeline + regression vs previous run to
`docs/PLAYTEST_NOTES.md`.

## Files

| File | Lines | Role |
| --- | --- | --- |
| `tools/playtest-echo/README.md` | 79 | Run docs + Zundarooms integration + compare_runs usage |
| `tools/playtest-echo/capture.luau` | 361 | In-game capture scaffold: LogService + state samples + ZRStatus buffer |
| `tools/playtest-echo/echo_to_notes.mjs` | 324 | Notes renderer: issues table + ZR status events + regression + archive |
| `tools/playtest-echo/compare_runs.mjs` | 261 | Regression comparator: REGRESSED/RESOLVED/RECURRING w/ zrEvents indexing |
| `tools/playtest-echo/live_run.py` | 58 | Server-side injection orchestrator (runs capture.luau in edit context) |
| `tools/playtest-echo/client_capture.py` | 96 | Client-context capture pattern (client-1 role, PlayerStateChanged) |
| `tools/playtest-echo/studio_mcp.py` | — | Studio MCP helper |
| `tools/playtest-echo/mcp_call.py` | — | JSON-RPC call helper |
| `tools/playtest-echo/verify_ui_actions.luau` | — | Client-local verification probe (Issues 3 & 4) |
| `tools/playtest-echo/runs/` | 8 JSON | Archived run traces |

## Run a session (from README)

1. Start Rojo: `npm run rojo:serve`
2. Open place in Roblox Studio. Verify MCP: `roblox-studio_get_connected_instances`.
   Start solo playtest: `roblox-studio_solo_playtest`.
3. Execute `capture.luau` via `roblox-studio_execute_luau` (or paste into command bar).
   Installs `_G.PlaytestEcho`.
4. Start capture: `return _G.PlaytestEcho.start()`
5. Play normally. State sampled immediately + every 5s.
6. Before ending playtest: `_G.PlaytestEcho.stop()` then
   `return game:GetService("HttpService"):JSONEncode(_G.PlaytestEcho.dump())`
7. Save returned JSON, then from repo root: `node tools/playtest-echo/echo_to_notes.mjs trace.json`

The Node script appends `## Echo Run YYYY-MM-DD (<duration>s)` to
`docs/PLAYTEST_NOTES.md` and archives the trace at
`tools/playtest-echo/runs/<session_id>.json`.

**Important:** capture + dump must run in the same live Studio context.
Server-side injection captures server output; client-only output requires running
the scaffold in client context. Always dump before stopping the solo session (the
`_G` state ends with the playtest).

## Zundarooms integration (committed)

`capture.luau` listens to `ZundaroomsStatus` (existing
`ReplicatedStorage.RemoteEvents.ZundaroomsStatus` RemoteEvent) and buffers every
fired status into `_G.PlaytestEcho.zrEvents`. On dump, these surface as the
`zundarooms_status_events` trace field — array of `{ at_s, status, memories }`
entries timed from capture start.

`echo_to_notes.mjs` emits a `### Zundarooms status events` table
(`| at_s | status | memories carried |`) when the trace carries that field.

`compare_runs.mjs` indexes the same events (keyed by `status + memories.length`)
so the REGRESSED/RESOLVED/RECURRING classification covers Zundarooms
status-sequence changes across runs.

### Client-context caveat

`ZundaroomsStatus` is a server→client RemoteEvent. A `capture.luau` injection
into edit/server context installs the `OnClientEvent` listener but will NOT hear
server→client fires — `zundarooms_status_events` will be absent/empty.

To capture the full Zundarooms status timeline (including memories carried on
escape), run the capture in **client-1 context** using the same `execute_luau`
path with `"role": "client-1"` (the pattern `client_capture.py` already uses for
client-only state).

## Compare runs (regression)

Once 2+ runs are archived:

```
node tools/playtest-echo/compare_runs.mjs                    # two most recent
node tools/playtest-echo/compare_runs.mjs --from=<id> --to=<id>
node tools/playtest-echo/compare_runs.mjs --json             # machine-readable
```

REGRESSED = present in new run but not previous (newly broken).
RESOLVED = present in previous but gone now (fixed).
RECURRING = present in both (still broken).
Run order is by `started_at`; a session answers "did we fix anything, and did we
break anything?" without reading raw logs.

The classification now also covers Zundarooms status-sequence changes via
zrKey()/indexErrors().

## Verification

- `node --check` passes on both .mjs files.
- `python3 -m py_compile` passes on all .py files.
- 8 run archives in `tools/playtest-echo/runs/`.
- `docs/PLAYTEST_NOTES.md` has 2 echo runs rendered (2026-08-25 ~660s session +
  2026-08-25 56s session), both with issues tables.
- Issues 3 & 4 verified live with evidence path
  `tools/playtest-echo/runs/verify-ui-actions-20260825.json`.

## What's NOT yet captured

- No run archive yet contains `zundarooms_status_events` — all 8 archives are
  server-context captures (LogService + state samples) or client-state captures
  (PlayerStateChanged). To get a real ZRStatus timeline, run a client-1 capture
  during a Zundarooms playtest where the player enters, collects fragments, and
  escapes.

## Existing run archives (tools/playtest-echo/runs/)

| Session ID | Started | Duration | Notes |
| --- | --- | --- | --- |
| live-001 | 2026-08-25T01:23Z | — | Server-context capture |
| live-002 | 2026-08-25T01:25Z | — | Server-context capture |
| ed21981e | 2026-08-25T01:48Z | — | Server-context capture |
| a05e0cd1 | 2026-08-25T01:54Z | — | Server-context capture |
| 305f2405 | 2026-08-25T01:50Z | — | Server-context capture |
| client-1787637552 | — | — | Client-state capture (PlayerStateChanged) |
| live-serve-20260825-1 | 2026-08-25T05:40Z | 56s | Server-context, 10 errors, rendered to PLAYTEST_NOTES |
| verify-ui-actions-20260825 | 2026-08-25T02:05Z | — | Client-local probe (Issues 3 & 4 evidence) |

## Known gaps

- No client-1 ZRStatus capture run exists yet.
- No run with `zundarooms_status_events` populated exists yet.
- Dead duplicate `buildRegressionSection`/`previousSignaturesHas` was removed from
  echo_to_notes.mjs (was at lines 265-301, duplicated lines 227-263); the file is
  now 324 lines, clean.
