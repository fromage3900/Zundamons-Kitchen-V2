# Zundarooms Encounter (long-term)

The Zundarooms are a small server-owned escape encounter unlocked after the
player serves their first guest. The design goal is repeatable tension with a
slowly escalating loop rather than a one-shot jump-scare.

## Level-design entry

Tag any `BasePart` with `ZundaroomsEntrance`. Walking through the part attempts
to enter the encounter. A thin, non-collidable wall produces the intended
accidental "clip through reality" effect.

If no tagged entrance exists, the server creates a translucent runtime-only
unstable wall near the first `SpawnLocation`. This fallback is never serialized
over authored Studio geometry.

## Encounter behavior

- Each player receives an isolated runtime room below the authored world.
- The unidentified entity and escape result are server-controlled.
- Reaching the pale exit awards one escape, gold, XP, discovery state, quest
  progress, **and the memory fragments the player carried out**.
- Being caught, dying, timing out, leaving, or retrying cleans the runtime room
  without granting an escape or persisting fragments.

## Long-term loop: depth progression

A player's **depth** is `min(zundarooms_escapes, maxDepth)` (see
`ConfigurationFiles/ZundaroomsConfig.lua`). Each successful escape raises depth
by one until `maxDepth`.

Per level of depth the server increases:

- corridor segments (`segmentCount = base + depth * depthSegmentsPerLevel`)
- entity speed (`entitySpeed = base + depth * depthEntitySpeedPerLevel`)
- session timeout to give the longer corridor a fair chance, and the escape
  reward (`depthGoldPerLevel`, `depthXPPerLevel`)
- catches also pay the fragment bonus a player collected that run, so a deeper
  run still rewards the riskier mid-run collection even if it fails

Depth 0 is exactly the pre-depth encounter — backward compatible.

## Memory fragments

Lore collectibles spawned mid-corridor from `Config.memories`. Touching one:

- pays gold/XP immediately (fair even if the player later gets caught)
- speeds the entity for the rest of that run ("it notices you") — a deliberate
  risk/reward tradeoff, not a free collect
- destroys the visual so it cannot double-collect

Fragments only persist if the player escapes with them. On escape the server:

1. persists the ids into `zundarooms_memories` via
   `ZundaroomsCollectionHistory.merge` — future runs prefer lore the player
   has not yet recovered
2. fires `ZundaroomsStatus` with `status = "escaped"` and a third argument
   listing the escaped memories, so the client reads out the discovery

Client-side, `ZundaroomsMemories.client.lua` shows a one-shot discovery readout
for the escaped run and keeps a persistent "Memories: X / 12" badge in the
existing ZundaHUD.

## Studio-authored override

To replace the pursuer without editing scripts, import the FBX as a Model named
`ZundaroomsEntity`, set its PrimaryPart, and place it directly under
`ServerStorage`. The service clones, sanitizes, welds, and moves that authored
visual while retaining its invisible server-owned chase root. The procedural
black pursuer remains the safe fallback.

Corridor visuals can also be swapped segment-by-segment: place a Model named
`RoomSegment` under `ServerStorage.AssetLibrary.Zundarooms`. When absent the
service falls back to the procedural box — an empty catalog never blocks play.

## Tuning

All numbers live in `ConfigurationFiles/ZundaroomsConfig.lua`: base corridor
size, `segmentCount`, `entitySpeed`, `catchDistance`, `sessionTimeout`, the
depth-scaling constants, and the full `memories` set.