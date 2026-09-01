# Zundarooms Long-Term Loop — Implementation Handoff

Status: structurally complete on disk; majority UNCOMMITTED. Echo pipeline
committed and able to capture the loop's status events once the gameplay side
is committed and a client-1 capture is run.

## Design (committed doc)

`docs/ZUNDAROOMS_AUTHORING.md` — full long-term design doc (79 lines on disk).
Depth progression + memory fragments + Studio-authored override + tuning. The
canonical reference for what the loop is supposed to do.

## What the loop does (summary)

- Player serves first guest → Zundarooms unlock.
- Walking through a `ZundaroomsEntrance`-tagged part enters an isolated runtime
  room below the authored world.
- Reaching the pale exit awards: escape, gold, XP, discovery state, quest
  progress, **and the memory fragments the player carried out**.
- Caught / dying / timeout / leave / retry → cleanup, no escape, no persisted
  fragments.

### Depth progression
- `depth = min(zundarooms_escapes, maxDepth)` (maxDepth = 8).
- Each level adds: corridor segments (depthSegmentsPerLevel = 1), entity speed
  (depthEntitySpeedPerLevel = 0.8), session timeout (depthTimeoutPerSegment = 14s
  per extra segment), escape reward (depthGoldPerLevel = 35, depthXPPerLevel = 12).
- Depth 0 = pre-depth encounter (backward compatible).

### Memory fragments
- 12 authored memories in Config.memories (hum, menu, chair, soup, bell, apron,
  window, recipe, guest, edamame, clock, door).
- fragmentsPerRun = 2 spawned mid-corridor.
- Touching one: pays gold (25) + XP (10) immediately, speeds entity by 0.75 for
  the rest of the run ("it notices you"), destroys the visual.
- Only persist if player escapes with them. On escape:
  1. ids persisted into `zundarooms_memories` via `ZundaroomsCollectionHistory.merge`
     (future runs prefer lore the player has not yet recovered)
  2. `ZundaroomsStatus` fired with `status = "escaped"` and third arg = escaped
     memories list → client renders discovery

## File-by-file status

| File | Lines | Committed? | Notes |
| --- | --- | --- | --- |
| `src/shared/ConfigurationFiles/ZundaroomsConfig.lua` | 72 | NO (modified, +37 vs HEAD) | Depth + memories + fragments blocks added on disk; HEAD has old minimal config |
| `src/server/Services/ZundaroomsService.lua` | 668 | NO (modified, +260 vs HEAD) | Full server: CreateFragments/PickupFragment/ClearFragments/merge/finish/Heartbeat; HEAD has old partial service |
| `src/client/ZundaroomsController.client.lua` | 42 | YES (byte-identical to HEAD) | Listens to ZRStatus, shows banner per status |
| `src/client/ZundaroomsMemories.client.lua` | 144 | NO (NEW, untracked) | Client journal: one-shot escaped readout + persistent "Memories: X / 12" counter in ZundaHUD; listens for escaped + memories |
| `src/shared/RemoteEvents/ZundaroomsStatus.model.json` | 2 | YES (trivial trailing-comma diff) | RemoteEvent; working tree has trailing-comma lint fix |
| `docs/ZUNDAROOMS_AUTHORING.md` | 79 | NO (modified, +83 vs HEAD) | Full design doc on disk; HEAD has shorter old version |
| `docs/CODE_OWNERSHIP_MAP.md` | 132 | NO (NEW, untracked) | File-ownership map |

### Deleted dead files (committed deletion? NO — these are working-tree deletions)
- `src/server/ZundaroomsFragments.server.lua`
- `src/server/ZundaroomsLTR.server.lua`
- `src/server/ZundaroomsCollectionHistory.server.lua`
- Logic folded into `ZundaroomsService.lua`; must be `git rm`ed before commit.

## Server implementation detail (ZundaroomsService.lua, 668 lines)

Key functions:
- `CreateFragments(folder, slotX, corridorLength, runtime, runMemories)` → {Model}
  — spawns neon covers with SurfaceGui labels + PointLight glow along the corridor.
- `PickupFragment(session, fragment)` — reads id from `fragment.Name:match("^Fragment_(.+)$")`,
  awards gold/XP via RewardCore.settle, adds fragmentEntitySpeedBonus to
  session.entitySpeed, destroys visual. Guard: re-touch after collection is a no-op.
- `ClearFragments(session)` — no-op on happy path (room already destroyed); kept for
  correctness if fragments are re-parented out before destruction.
- `ZundaroomsCollectionHistory.merge(session)` — persists collected ids into
  `data.zundarooms_memories`, skipping dupes.
- `finish(session, outcome)` — on "escaped": builds escapedMemories from collected ids
  + Config.memories, fires `statusEvent:FireClient(player, "escaped", escapedMemories)`,
  returns player to origin, cleans up. On "caught": fires "caught", returns, cleans up.
- `createRoom(player, origin)` → Session — builds corridor segments, spawns fragments
  from pickMemories (prefers unseen lore), sets up entity + exit + touch handlers.
- `ZundaroomsService.enter(player)` — unlocks check (guestsServed >= 1 OR
  locations_unlocked contains "Zundarooms"), character availability check, creates room,
  fires "entered".
- `ZundaroomsService.start()` — binds CollectionService-tagged entrances, fallback
  unstable wall if none tagged.
- Heartbeat — chase logic: entity tracks player root, catches at catchDistance (4),
  timeout at session.timeout, entity speed from session.entitySpeed (per-session,
  includes fragment bonus).

## Client implementation detail

### ZundaroomsController.client.lua (42 lines, committed)
- Creates a ScreenGui (ZundaroomsStatusGui, DisplayOrder 110) via
  ClientGuiBootstrap.
- Banner TextLabel (520×64, bottom center, hidden by default).
- Messages table: locked / entered / escaped / caught / timeout.
- `ZundaroomsStatus.OnClientEvent:Connect(function(status) ...)` — shows banner,
  auto-hides after 5s (entered) or 3.5s (other).

### ZundaroomsMemories.client.lua (144 lines, NEW untracked)
- `getOrCreateCounter()` — creates "ZundaroomsCounter" Frame in ZundaHUD
  (top-right, 220×30, dark bg, green stroke) with "Memories: 0" label.
- `showEscaped(memories)` — one-shot ScreenGui "ZundaroomsReadout" (center panel,
  380×140, dark bg, green stroke) listing each memory text as bullet points,
  tweens in then out over 6s, bumps the persistent counter.
- `statusEvent.OnClientEvent:Connect(function(status, memories) ...)` — on
  "escaped" + memories > 0, calls showEscaped.

## Echo pipeline integration (committed)

### capture.luau (361 lines)
- References `ZRStatus = ReplicatedStorage.RemoteEvents.ZundaroomsStatus`.
- On `start()`: installs `_G.PlaytestEcho.zrEvents = {}` and
  `ZRStatus.OnClientEvent:Connect(function(status, memories) ...)` that pushes
  `{ at_s, status, memories }` into the buffer.
- On `dump()`: deep-copies `_G.PlaytestEcho.zrEvents` into
  `zundarooms_status_events` trace field (array of `{ at_s, status, memories }`).
- `stop()` disconnects the ZRStatus listener.

### echo_to_notes.mjs (324 lines)
- `buildZundaroomsSection(trace)` — renders "### Zundarooms status events" table
  (`| at_s | status | memories carried |`) when trace has
  `zundarooms_status_events` with entries.
- Called from `buildSection()` after the regression block.

### compare_runs.mjs (261 lines)
- `zrKey(ev)` — deduplicates ZRStatus events by `status + memories.length`.
- `indexErrors(run)` — indexes `run.zundarooms_status_events` into the error index
  (script = "ZundaroomsStatus", message = ""), so REGRESSED/RESOLVED/RECURRING
  classification covers status-sequence changes (e.g. "escaped with 2 memories"
  appearing or disappearing across runs).

### README.md "Zundarooms integration" section
- Documents the zrEvents buffer, zundarooms_status_events trace field,
  buildZundaroomsSection rendering, compare_runs.mjs zrKey/indexErrors indexing.
- **Client-context caveat**: ZRStatus is server→client; server-context capture
  will NOT hear fires → zundarooms_status_events absent/empty. To capture the full
  timeline (with memories), run in client-1 context (`"role": "client-1"`).

## What's needed to close the loop

1. **Commit the Zundarooms loop** — stage config + service + controller + memories +
   model.json + deleted-files cleanup + authoring doc + CODE_OWNERSHIP_MAP, commit
   with a clear message. (Controller is already committed; can be included for
   completeness or left as-is.)
2. **Run a client-1 capture** during a playtest where the player enters Zundarooms,
   picks up fragments, and escapes — this captures the full `zundarooms_status_events`
   timeline including the "escaped" event with memories.
3. **Render to PLAYTEST_NOTES.md** via `node tools/playtest-echo/echo_to_notes.mjs
   <trace.json>` — appends the status events table.
4. **Compare runs** via `node tools/playtest-echo/compare_runs.mjs` — classifies any
   status-sequence regression.
5. **Verify the client journal** renders the escaped readout + bumps the counter in
   live play.

## Known gaps / open items

- **No live ZRStatus capture run yet** — echo pipeline is committed but no trace with
  `zundarooms_status_events` has been captured (all 8 run archives are server-context
  or client-state captures, none with ZRStatus timeline).
- **ZundaroomsMemories.client.lua is untracked** — must be `git add`ed.
- **Dead files not `git rm`ed** — ZundaroomsFragments/LTR/CollectionHistory.server.lua
  are deleted on disk but not staged for removal.
- **Wide modified zone** — 33 modified + ~35 untracked files beyond Zundarooms
  (Damon, LLM, cooking, VN, etc.) must not be mixed into the Zundarooms commit.
