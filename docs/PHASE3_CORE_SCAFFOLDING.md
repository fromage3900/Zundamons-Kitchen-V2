# Phase 3 — Core Gameplay Scaffolding: Deep Study & Close-Out

Author: Opus review pass, 2026-07-24. Every "verified" claim below was checked
**live in a Studio Play session tonight**, not read from prior docs. Where this
contradicts older docs (esp. `PHASE3_ACCEPTANCE_STATUS.md` dated 2026-07-21),
**this document is correct** — several older "Verified" claims were tested on a
controlled fresh-launch and do not hold in the shipped world state.

---

## 1. The core loop — what actually connects to what

```
   GATHER ──▶ (ingredients) ──▶ COOK ──▶ (dishes) ──▶ SERVE ──▶ (gold + rep)
     ▲                            │                       │           │
     │                            ▼                        ▼           ▼
  tools/click               rhythm minigame           guests      REWARD/DATA
  loot tokens              server-authoritative     patience     RewardCore.settle
                                                                       │
                                                                       ▼
                                                    QUESTS ◀── progression, XP, tiers
                                                    COMPANION (buffs the above)
                        side loops: FISHING · ZUNDAROOMS (escape) · SHOP · WARDROBE
```

The spine is **Gather → Cook → Serve → Reward → Progress**. It is real and,
as of tonight, unbroken end-to-end for a single player. The side loops
(fishing, Zundarooms, shops) hang off the reward/data layer.

---

## 2. System-by-system verified state

### Gather / Harvest — ⚠️ PARTIALLY SOLID (fixed tonight, world gaps remain)
Three independent subsystems, all real:
- **Click-gather** (`ZundaGatherServer`): `ResourceType` attribute + `ClickDetector` → `HarvestNode` remote → `generateLoot` → pickup token → collect. **Was broken** (world used generic `ResourceType="flower"`, server spoke canonical `"ZundaFlower"`; also scanned an empty folder). **Fixed `b65eb50`**: config-driven grants via `GatherConfig` + alias map + workspace-wide scan. Flowers now grant.
- **Tool-mine** (`Mineable.server.lua` + `MineableConfig`): `Mineable` tag → tool hit depletes `Health` → loot by tier. Self-contained, 29 nodes, works.
- **Planters** (`Planters.server.lua`): decorative watering, 80 planters. Cosmetic, not a harvest source.
- **World gap (NOT code)**: standalone Zunda Pea and Zunda Mushroom *nodes* don't exist in the live world — only 1 `SaltedPeaBouquet` + mushroom meshes decoratively nested inside flowers. Mushrooms are sickle/Mineable by design (`GatherConfig` comment). Peas need nodes placed. Loot templates for both exist in `ReplicatedStorage.Loot`, so once nodes are authored they work with zero code.

### Cooking — ✅ SOLID
`CookingController` (client rhythm minigame, intent-only) → `CraftManager`/`CookingService` (server owns quality, reservation journal, atomic settlement). Verified previously for completion + death-refund. Reward-moment audio (bubbles SFX) wired tonight.

### Serving — ✅ SOLID (single-player)
`ServingSystem` — owner/state/proximity validation, server-selected quality, atomic dish/reward settlement, guest cleanup. Guests spawn as real Kenney meshes (not capsules). Two-player cross-ownership gate remains untested (needs a real 2nd client).

### Reward / Data — ✅ SOLID (mock), ⛔ production rejoin untested
`RewardCore.settle` (atomic, rollback-safe) + `PlayerDataService` over ProfileService (session lock, Studio mock isolation, schema reconciliation). Items are **top-level keys** on the profile (`data["Zunda Flower"] = n`). Verified via ProfileService mock release/reload. **Production DataStore rejoin cannot be tested in Studio** — needs a published session with API access. This is the single biggest untested-in-Studio gate.

### Quests — ✅ SOLID engine, content is thin
`QuestManager v2` — dynamic, config-driven (`QuestConfig`), tracks cooking quality/companion/npc_chats/etc. Fires correctly live (`quest_first_100_gold`, `quest_gold_rush_1` complete on fresh launch). Engine is strong; **content volume is a Phase 4 item** (Ollama quest workers exist in `scripts/`).

### Companion — ✅ SOLID (mesh/anim/identity), texture pending
Spawns from authored `ServerStorage.CompanionVisualCatalog.Prefabs.zundamon`, real skinned mesh + `AnimationController`/`Animator`, upright (180° orient correction — user-confirmed), `SurfaceAppearance` wired. Idle/walk anim driver is nil-safe and waits on real animation IDs (import via Animation Editor still pending). Texture *render* pending Roblox moderation of tonight's uploads.

### Fishing — ✅ SOLID
`FishingService` (authoritative, opaque session, atomic catch). Verified single-player + mock rejoin. Reward SFX wired tonight.

### Zundarooms — ✅ SOLID (entry/escape), relocation pending
Quest-gated liminal-corridor escape encounter, server chase, atomic escape settlement (+100 gold). 6-segment corridor with an authored-prefab override slot (`AssetLibrary.Zundarooms.RoomSegment`, populated from uploaded Greybox_Kit). User wants the **entrance relocated near the beach tunnel** (open task #25).

### UI dispatch — ✅ SOLID
`UIActionRegistry` (single keyboard dispatcher, now with queue+retry for the load-order race) + `PeaWheel` (all 8 slice callbacks verify ✓ live). Panels register via `ActionRegistry.registerCallback`. No rogue `InputBegan` listeners remain.

---

## 3. Structural risks — the recurring footguns

1. **Baked non-Rojo instances vs Rojo source** — *the #1 recurring issue in this project.* `ServerStorage.CompanionVisualCatalog`, `ServerStorage.AssetLibrary`, the whole `Workspace` tree, and several `Configuration` scripts (e.g. `japanese shrine lantern`) live in the `.rbxl`, not in `src/`. A `src/` code fix **cannot** touch them; a live Studio edit **reverts on Studio restart** unless File→Publish/Save is run. The shrine-lantern `require(assetId)` crash *still throws live* for exactly this reason — the `src/` copy was fixed, the baked instance wasn't published. **Rule: after any manual ServerStorage/Workspace instance edit, publish immediately.**
2. **Doc-vs-reality drift** — `PHASE3_ACCEPTANCE_STATUS.md` marked harvest "Verified"; it was broken in the shipped world. Always verify live.
3. **Load-order races** — several server scripts capture remotes via `FindFirstChild` at init instead of `WaitForChild`; if the remote hasn't replicated, the handler silently never connects. Audit candidate for hardening.
4. **Asset ownership** — *solved.* `tools/asset-pipeline/` (Open Cloud upload + Blender `.obj→.glb`) mints assets under the correct creator. No longer a blocker.

---

## 4. Phase 3 close-out checklist (verified real state, 2026-07-24)

| Criterion | State | Note |
| --- | --- | --- |
| Zero load-time script errors | ⚠️ **1 remains** | `japanese shrine lantern` baked `require(assetId)` — needs the live instance re-fixed + published, OR the baked Script neutralized |
| Core loop Gather→Cook→Serve→Reward works single-player | ✅ | Harvest fixed tonight; rest verified |
| Guests render as characters | ✅ | Live-confirmed |
| Companion: mesh/upright/human-sized/textured | ⚠️ **texture render pending** | Wiring correct; awaiting Roblox moderation |
| PeaWheel + 8 slices + hotkeys single-toggle | ✅ | All callbacks verify live |
| No tofu/empty-box glyphs | ✅ (prior sweeps) | Spot-recheck recommended |
| Progression panel has new-UI equivalent | 🔴 **open** | `UpdateScript` still skips — last UI-parity gap (task #12) |
| Multi-player + production DataStore rejoin | ⛔ **untestable in Studio** | Needs a published session |
| Clean tree; Rojo build + focused Selene/StyLua | ⚠️ | Tree clean; repo-wide StyLua still drifts (inherited) |

**Phase 3 is ~85% closed.** The genuine blockers are: (a) Progression panel, (b) shrine-lantern baked crash, (c) production-rejoin test (external). Everything else is done or cosmetic.

---

## 5. Phase 3 → Phase 4 boundary

- **Phase 3 = "it works and ships clean."** Core loop solid, zero errors, publishable.
- **Phase 4 = "it's fun and keeps you playing."** Content depth (Ollama quests), ASMR audio overhaul, NPC life/interactivity, dopamine/reward tuning, replayability, cosmetic polish.

Do not cross fully into Phase 4 until the three Phase 3 blockers above are closed. The Progression panel (b3) and shrine-lantern (a) are both finishable in-session; the rejoin test needs the user to publish and rejoin.
