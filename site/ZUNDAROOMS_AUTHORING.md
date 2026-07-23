# Zundarooms Encounter

The Zundarooms are a small server-owned escape encounter unlocked after the player serves their first guest.

## Level-design entry

Tag any `BasePart` with `ZundaroomsEntrance`. Walking through the part attempts to enter the encounter. A thin, non-collidable wall produces the intended accidental “clip through reality” effect.

If no tagged entrance exists, the server creates a translucent runtime-only unstable wall near the first `SpawnLocation`. This fallback is never serialized over authored Studio geometry.

## Encounter behavior

- Each player receives an isolated runtime room below the authored world.
- The unidentified entity and escape result are server-controlled.
- Reaching the pale exit awards one escape, gold, XP, discovery state, and quest progress.
- Being caught, dying, timing out, leaving, or retrying cleans the runtime room without granting an escape.
- `locations_unlocked`, `zones_visited.Zundarooms`, and `zundarooms_escapes` persist through `PlayerDataService`.

Tuning lives in `ConfigurationFiles/ZundaroomsConfig.lua`. To replace the pursuer
without editing scripts, import the FBX as a Model named `ZundaroomsEntity`, set
its PrimaryPart, and place it directly under `ServerStorage`. The service clones,
sanitizes, welds, and moves that authored visual while retaining its invisible
server-owned chase root. The procedural black pursuer remains the safe fallback.
