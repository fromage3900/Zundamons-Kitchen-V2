# Playtest Echo

Playtest Echo captures a lightweight Studio session trace, archives it, and appends an error summary to
`docs/PLAYTEST_NOTES.md`.

## Run a session

1. Start Rojo from the repository root:

   ```powershell
   npm run rojo:serve
   ```

2. Open the place in Roblox Studio and verify the Studio MCP connection with
   `roblox-studio_get_connected_instances`. Start a solo playtest with `roblox-studio_solo_playtest`.

3. While the playtest is running, execute the full contents of `capture.luau` through
   `roblox-studio_execute_luau`, or paste it into the Studio command bar. It installs the API at
   `_G.PlaytestEcho` in that execution context.

4. Start a fresh capture:

   ```luau
   return _G.PlaytestEcho.start()
   ```

5. Play normally. State is sampled immediately and then every five seconds.

6. Before ending the solo playtest, stop the capture and return its dump as JSON:

   ```luau
   _G.PlaytestEcho.stop()
   return game:GetService("HttpService"):JSONEncode(_G.PlaytestEcho.dump())
   ```

7. Save the returned JSON string as a file, then process it from the repository root:

   ```powershell
   node tools/playtest-echo/echo_to_notes.mjs trace.json
   ```

The Node script appends an `## Echo Run YYYY-MM-DD (<duration>s)` section to `docs/PLAYTEST_NOTES.md` and
archives the complete trace at `tools/playtest-echo/runs/<session_id>.json`.

The capture and dump must run in the same live Studio context. A server-side injection captures server output;
client-only output requires running the scaffold in the client context. Always dump before stopping the solo session,
because its `_G` state ends with the playtest.

## Zundarooms integration

`capture.luau` now listens to `ZundaroomsStatus` (the existing `ReplicatedStorage.RemoteEvents.ZundaroomsStatus`
RemoteEvent) and buffers every fired status into `_G.PlaytestEcho.zrEvents`. On dump, these are surfaced as the
`zundarooms_status_events` trace field — an array of `{ at_s, status, memories }` entries timed from capture start.

The `echo_to_notes.mjs` renderer emits a `### Zundarooms status events` table (`| at_s | status | memories carried |`)
when the trace carries that field. `compare_runs.mjs` indexes the same events (keyed by `status` + `memories.length`)
so the `REGRESSED` / `RESOLVED` / `RECURRING` classification also covers Zundarooms status-sequence changes across runs
(e.g. "escaped with 2 memories" appearing or disappearing).

**Client-context caveat.** `ZundaroomsStatus` is a server→client RemoteEvent. A `capture.luau` injection into the
edit/server context will install the `OnClientEvent` listener but will not hear server→client fires — the
`zundarooms_status_events` field will be absent/empty. To capture the full Zundarooms status timeline (including
memories carried on escape), run the capture in client-1 context using the same `execute_luau` path with
`"role": "client-1"` (the pattern `client_capture.py` already uses for client-only state).

## Compare runs (regression)

Once two or more runs are archived, compare the two most recent (or a specific pair) to classify every error as
REGRESSED / RESOLVED / RECURRING, keyed by script + message:

```powershell
node tools/playtest-echo/compare_runs.mjs                    # two most recent runs
node tools/playtest-echo/compare_runs.mjs --from=<id> --to=<id>
node tools/playtest-echo/compare_runs.mjs --json             # machine-readable output
```

`REGRESSED` = present in the new run but not the previous (newly broken). `RESOLVED` = present in the previous run
but gone now (fixed). `RECURRING` = present in both (still broken). Run order is by each trace's `started_at`, so a
session can answer "did we fix anything, and did we break anything?" without reading raw logs.
