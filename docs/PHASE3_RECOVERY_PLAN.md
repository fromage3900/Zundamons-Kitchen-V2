# Phase 3 Authoritative Core-Loop Recovery

## Objective

Restore one server-authoritative implementation for fishing and the Harvest -> Cook -> Serve -> Reward loop while preserving `PlayerDataService` as the persistence boundary, `RewardCore` as the monetary/XP boundary, the Studio-authored world, and the hybrid ECS standard. Phase 3 is measured by transactional correctness and parity, not by the percentage of scripts converted to Matter.

## Confirmed starting state

- Fishing is deliberately fail-closed. `FishingServer.server.lua` owns `OnServerInvoke`; the unscheduled ECS draft cannot also consume that callback as an event.
- Cooking is disconnected: `CraftManager.server.lua` deducts ingredients and fires a `ServerScriptService` BindableEvent, while the registered Matter wrapper listens for `ReplicatedStorage.RemoteEvents.CookingStartEvent`. No producer reaches that listener.
- Cooking trusts client-supplied hit quality and lacks a session token, authoritative note schedule, sequence validation, and one-session guard.
- Serving trusts client-supplied quality. `RewardCore` increments lifetime gold, then `ServingSystem` increments it again.
- Cooking and serving both mutate `recipes_served_count`, conflating cooked and served facts.
- Harvest validation is a useful baseline, but generated loot codes can be redeemed without validating a live nearby pickup.
- `PlayerDataService` is the canonical practical schema. The incompatible nested `DataSchema` and dormant `ItemGatherSystem` are not runtime truth and must not be enabled.

## Progress checkpoint (2026-07-21)

- 3.1 is committed as `668e88d`: versioned player projections, serialized rollback-safe mutations, inventory helpers, and RewardCore ownership are active.
- 3.2 is implemented and focused-verification complete pending its commit. `FishingServer` is the sole remote owner; `FishingService` owns one Matter session per player, server simulation, lifecycle cleanup, and atomic settlement.
- A real Studio catch granted one `Fish: Trout`, advanced the data revision once, and rejected replay. Duplicate begin, forged session, legacy client-result, and repeated cancellation requests were rejected.
- Product decision: a catch becomes a visible raw inventory item named `Fish: <species>` plus chef XP. It does not grant immediate gold, preserving fish for later recipe or selling design without double-paying the economy.
- The local Blender and `crucialassets/` sources remain owner-controlled and untracked.

## Architecture contract

1. Explicit server adapters own RemoteEvents and RemoteFunctions, validate payload shape and rate limits, and call a domain service or enqueue an ECS command.
2. `PlayerDataService` exposes narrow read, mutation, inventory grant/consume, and projection helpers. Domain code does not invent a second profile owner.
3. `RewardCore` alone owns gold, lifetime gold, XP, level, combo, and reward notifications. Domain services own their semantic counters.
4. Matter owns simulation-friendly session and world state. It does not own persistence, UI, networking callbacks, or transactional policy.
5. Clients send intent, never quality, payment, reward, or terminal success. Every terminal settlement is server-decided and idempotent.
6. UI consumes canonical projections and domain results. React state stays outside gameplay ECS.

## Execution sequence and commit boundaries

### 3.1 Data contract and reward ownership

- Define current flat profile-field semantics and separate cooked-versus-served counters.
- Add serialized mutation and inventory helpers plus a minimal read-only projection.
- Remove serving's duplicate lifetime-gold mutation.
- Preserve the `AdvancedRewards` subscriber while stabilizing its event payload.

Exit: one mutation boundary can atomically validate and apply a domain settlement; RewardCore awards are counted once.

Commit: `fix(data): establish authoritative mutation and reward contracts`

### 3.2 Authoritative fishing vertical slice

- Keep one RemoteFunction owner and replace the fail-closed body with validated dispatch.
- Validate loaded data, living character, equipped rod type/name, zone eligibility, rate limit, and one session per player.
- Roll fish once on the server and create one session through an explicit service API or ECS command queue.
- Replace client-reported success with bounded input intent; server owns tension, progress, RNG, timeout, and terminal result.
- Clean up on death, unequip, respawn, timeout, and disconnect; award exactly once.
- Decide whether fish are ingredients or sellable catches before wiring inventory/rewards.

Exit: forged or repeated results award nothing; two players can fish concurrently; rejoin restores exactly one legitimate catch.

Commits: contract/session ownership; simulation/lifecycle; inventory/reward integration; tests/docs.

### 3.3 Authoritative cooking transaction

- Replace the split BindableEvent/RemoteEvent start path with one server-owned session service.
- Validate station, proximity, recipe/unlock, ingredients, and no active session before reservation.
- Use an opaque session token, server note schedule, sequence index, timing windows, expiry, and explicit refund/consume policy.
- Client sends session token and note intent only; server derives quality.
- Completion atomically converts ingredients to a dish carrying server-owned quality and updates cooked counters exactly once.

Exit: invalid, duplicate, premature, forged, expired, or disconnected actions cannot lose ingredients incorrectly or create a dish/reward.

Commits: authoritative server session; client contract and focused tests.

### 3.4 Authoritative serving settlement

- Client sends guest and selected dish identifier, never quality or pay.
- Validate guest assignment/state/proximity and server-owned dish quantity/quality.
- Atomically consume one dish, lock/remove one guest, increment served counters, and award through RewardCore once.
- Preserve V1 dialogue, mastery, reputation, and daily progression only after successful settlement.

Exit: replayed, distant, stale, wrong-owner, wrong-dish, missing-dish, and forged-quality requests award zero.

Commit: `fix(serving): settle dish and rewards exactly once`

### 3.5 Authoritative harvest grants

- Preserve current level behavior and validation while allowlisting nodes and consolidating all producers.
- Use validate -> reserve node -> mutate inventory -> project result -> respawn ordering.
- Prefer direct profile grants; if physical drops remain, server validates the live pickup and distance.
- Consolidate Kenney and future resource visuals behind an asset/variant registry. Gameplay behavior is assigned through CollectionService tags and configured attributes, so collaborators can swap tree, rock, flower, and crop meshes without editing harvest scripts.

Exit: every `ResourceType` grants once; failures do not strand nodes; remote replay and distant pickup grant zero.

Commit: `fix(harvest): consolidate validated inventory grants`

### 3.6 Full-loop acceptance gate

- Fresh launch completes Harvest -> inventory -> Cook -> dish -> Serve -> gold/XP -> HUD once.
- Rejoin restores inventory, dish state, currency, XP, progression, unlocks, and companion state.
- Fishing begin/input/result is server-authoritative and cleans up on every terminal path.
- Independent Rojo, StyLua, Selene, path-contract, and Studio smoke results are recorded.
- V1 behavior retained or deliberately changed is documented as a product decision.

Commit: `test(core-loop): prove authoritative phase 3 contracts`

## Acceptance matrix

| Domain | Must accept | Must reject without mutation |
| --- | --- | --- |
| Harvest | Nearby allowlisted available node; configured yield once | Invalid instance, wrong folder/tag, unavailable or distant node, rate-limit breach, replay, distant pickup |
| Fishing | Equipped rod, valid zone, one live server session, bounded input | Forged success, unknown/stale session, duplicate begin, premature input, timeout, death, unequip, disconnect |
| Cooking | Valid station/recipe/unlock/ingredients; ordered notes in server windows | Forged quality/token, duplicate/out-of-order/too-fast note, duplicate start, expiry, disconnect |
| Serving | Assigned live nearby guest plus owned matching server-quality dish | Forged quality/pay, missing/wrong dish, stale/distant/wrong-owner guest, replay |
| Persistence | Successful transaction survives save/rejoin exactly once | Failed or cancelled transaction leaves no partial reward or schema loss |

## V1 parity decisions

- Retain V1's player-facing fishing, gathering, cooking, serving, dialogue, quest, mastery, and reward feel where it remains compatible.
- Do not restore V1 fishing authority: it trusted the client's success boolean.
- Prefer direct-inventory cooked dishes over V1 world drops unless a product review explicitly chooses physical pickup friction.
- Preserve serving dialogue, daily progress, mastery, reputation, and challenge rewards, but trigger them only after an idempotent settlement.
- Preserve the authored Studio world and its real rods, water/zone objects, gathering nodes, guests, kitchen stations, meshes, and attributes.

## Rollback and coordination

- One writer owns a domain at a time; Studio is a single-writer resource.
- Static inventories, parity matrices, lint classification, and test drafting may be delegated read-only.
- Do not combine ECS expansion, UI redesign, bulk formatting, or persistence replacement with Phase 3 domain commits.
- Preserve `$ignoreUnknownInstances: true`; never regenerate or replace the authored world as part of a code migration.
- Do not push, publish, or stage owner Blender/archive assets without explicit authorization.
