# Phase 4 Gameplay Direction — "Infinity Nikki x Uma Musume" Lens

Date: 2026-07-24
Scope: gameplay-systems direction only. For shop/cosmetics/currency economy, see `docs/PHASE4_MONETIZATION_PLAN.md` (not re-derived here). For session history, see `docs/PHASE3_HANDOFF.md`.

This is not a redesign. The existing loop stays exactly as-is: **harvest ingredients → cook recipes → serve guests for gold/XP → complete quests → level up chef rank**, with fishing, rhythm cooking, companions, exploration zones, and now roaming animal-mesh guests. The goal here is to name what already reads as "Nikki" (cozy exploration/aesthetic collection) or "Uma" (character bonding/personality-driven companions) coded, find the single highest-leverage gap, and give concrete, low-effort wiring into what already ships.

---

## 1. What's already Nikki/Uma-coded

**Uma-coded (character collection, distinct personalities):**
- 9 named companions with distinct flavor text, `llmPersona`, and per-companion stat buffs — `src/shared/ConfigurationFiles/CompanionConfig.lua:14-163` (zundamon, dog, parrot, cat free; ankomon +15% gold, cardamon +30% perfect window, antimon +20% extra drop, sakuradamon +25% XP, tantanmon +20% speed).
- Per-companion dialogue pools split by time-of-day, `src/shared/ConfigurationFiles/VNDialogueData.lua:31-257`, with three **level-gated dialogue tiers already built**: `level1_10`, `level11_20`, `level21_50` (`:237-256`), selected by `getCompanionDialogue(compType, timeOfDay, level)` (`:286-303`).
- Real idle/walk Animator support just shipped this session, `src/server/CompanionManager.server.lua:189-214, 377-398, 400-456` — companions now have a state machine (idle↔walk blend) instead of being static followers.
- `companion_chat` and `set_companion` quest types already exist and are populated: `src/shared/ConfigurationFiles/QuestConfig.lua:382-391` ("Best Friends," target=5 chats), `:806-853` (4 "meet the companion" quests, one per premium companion).
- `PlayerDataService` already tracks `companion_affection` and `companion_chats` as first-class numeric keys (`src/server/Services/PlayerDataService.lua:26-43`) — **currently unused by any bond system**, but the column exists.

**Nikki-coded (cozy exploration, whimsical aesthetic):**
- `src/client/PostProcessing.lua`, `WhimsicalOverlay.lua`, `MagicCircle.lua`, `AmbientParticles.lua`, `CelOutline.lua` (all `src/shared/ConfigurationFiles/`, wired only through `src/client/FXController.client.lua`) — genuinely active toon/dreamy visual language, not dead code.
- 10 named biomes with distinct descriptions/flavor and procedural generation, `src/shared/Shared/Config/LandscapeConfig.lua:6-307` (GardenVillage, ZundaMarket, Promenade, Forest, BerryOrchard, MeadowPlaza, SunsetGrove, WheatField, WheatCrystalGarden, MoonlitGarden).
- `visit_zone` / `visit_zones_unique` quest types already exist and are populated, e.g. `quest_visit_all_zones` "World Tour" (`QuestConfig.lua:370-379`).
- Roaming animal-mesh guests with spawn/timeout VN lines just wired this session (`src/server/GuestManager.server.lua:240-372, 528-606`; `VNDialogueData.lua:318-365`) — the world now has ambient wandering life, not just static shop-stall guests.
- `ChefStatsConfig.lua:66-95` style-points/tier system (Fresh→Legendary) with `outfitUnlocks` per tier — an aesthetic-collection reward ladder already exists on paper.

**Overselling risk — be honest about what's a stub:**
- Outfit unlocks in `ChefStatsConfig.lua:89-94` are bare name strings with no asset IDs; `OutfitWardrobeGui.client.lua:212-219` is a hardcoded fake array with **no equip click-handler wired at all** (confirmed: no `.MouseButton1Click:Connect` on the equip buttons). Dress-up currently does nothing.
- Biome distinctiveness is descriptive only — all 10 draw from the same shared asset pool with different weights (`LandscapeConfig.lua`), no exclusive gather nodes or guest types per biome yet.
- `companion_affection`/`companion_chats` counters exist in the data schema but nothing increments or reads them today.

---

## 2. The highest-leverage gap: no per-companion bond/affinity system

Confirmed absence: `active_companion` is a single slot (`CompanionManager.server.lua:464-483`), buffs are static per companion regardless of history (`CompanionConfig.lua:79-162`), and the three dialogue tiers in `VNDialogueData.lua` are keyed to the **player's global chef level**, not to time-spent-with-that-companion (`VNDialogueData.lua:291-298`). This is exactly the piece Uma Musume's loop depends on and exactly the piece Nikki doesn't need — so it's the differentiator to build.

### Minimal design

**Data (no migration needed — extend, don't restructure):**
Add one new key to the per-player save, next to the existing `companions_set{}` and the already-present-but-unused `companion_affection`/`companion_chats` counters (`PlayerDataService.lua:26-43`):
```lua
data.companion_bond = data.companion_bond or {} -- { [compType] = { xp = 0, level = 1 } }
```
Because `PlayerDataService` already has `NON_INVENTORY_NUMBER_KEYS` as an explicit allowlist (`:26-43`) and a generic table for everything else, a per-companion nested table needs no schema migration — just a default-fill on load, same pattern as `companions_set`.

**How bond XP accrues (reuse existing hooks, don't add new UI):**
- Serving a guest while that companion is the `active_companion` → small bond XP (e.g. +2), piggybacking on the existing serve-completion path that already increments `d.guests_served` (referenced in `QuestManager.server.lua` quest checks).
- Each `companion_chat` interaction (the quest type already exists, `QuestConfig.lua:382-391`) → the same event that increments `companion_chats` should also add bond XP (e.g. +5) — this literally makes the currently-dead `companion_chats` counter do something.
- Optional stretch: +1 bond XP per cooking session completed with that companion active, tying into `CookingController.lua`'s rhythm loop without changing its mechanics.

**What it unlocks:**
- Re-key `getCompanionDialogue` (`VNDialogueData.lua:286-303`) to take `bondLevel` for that specific companion instead of (or in addition to) player level — the three tiers (`level1_10/11_20/21_50`) already exist structurally; this is a lookup-key swap, not new content authoring.
- Bond-milestone rewards using the reward pattern already used by quests (`RewardCore`, referenced in `QuestManager.server.lua:42`): e.g. bond level 5 → cosmetic tag/particle color unlock (glow color is already per-companion data, `CompanionConfig.lua` `sparkleColors`), bond level 10 → a unique VN scene, matching the "meet the companion" quests already in `QuestConfig.lua:806-853`.
- No new UI screen strictly required for v1 — a bond-level readout can piggyback on `CompanionShopScript.client.lua`'s existing detail panel (`:194-229`), which already renders per-companion state.

This is additive: existing `active_companion`/`companions_set` logic, the shop UI, and the dialogue system all stay as-is; bond level is just a new axis layered on top of a slot that already tracks which companion is out.

---

## 3. Cozy exploration layer: are biomes destinations or decoration?

Currently **decoration, not destinations** — `LandscapeConfig.lua:6-307` confirms all 10 biomes share one asset pool (`ZundaFlower, BerryBush, ZundaMushroom, Bench, StreetLamp, MarketHall, BakeryStall`) differentiated only by spawn weight/zone size/seed. `visit_zone`/`visit_zones_unique` quests (e.g. `quest_visit_all_zones`, `:370-379`) currently reward just for physically standing in each biome once — there's no reason to *return*.

**Lowest-effort fix that uses infrastructure already in place, in priority order:**
1. **Biome-exclusive guest spawn weighting** — `GuestManager.server.lua:240-265` already has weighted mesh-type selection logic for guest spawns (currently animal vs. Kenney-human ratio). Extend the same weighting function to take the biome the guest spawner is in and bias toward biome-flavored `meshType`s (e.g. more `parrot`/wildlife types in Forest, market-goer types in ZundaMarket). This reuses `VNDialogueData.GUEST_BY_TYPE` (`:318-365`) as-is — no new dialogue authoring needed, since `DEFAULT` already covers generic types.
2. **Biome-exclusive gather nodes** — the harvest step already exists elsewhere in the loop (referenced by `gather`/`gather_unique` quest types, `QuestConfig.lua`, e.g. `quest_zunda_hunt_4:480-493`). Tag a subset of `assetProfiles` entries per biome (`LandscapeConfig.lua`'s per-zone asset lists) as harvestable-only-here, and point 2-3 existing `gather_unique` quest chains at them — this is a data change to `LandscapeConfig.lua` plus quest `target_item` values, no new systems.
3. **`gather_unique` quest chains already model "keep coming back"** — the `chain_id`/`chain_step` fields (seen on `quest_zunda_hunt_4:480-493`) are a ready-made mechanism for "visit this biome again next chef-level tier for the next chain step." No new quest type needed, just more chain entries using biome-exclusive nodes from (2).

---

## 4. Wiring into the current loop (touch points, not new systems)

- **Serving a guest while your active companion is nearby should feel special.** Today buffs are just passive multipliers (`CompanionConfig.lua:79-128`, e.g. +15% gold) with no feedback. Cheapest win: fire the existing companion dialogue system (`VNDialogueData.lua` `COMPANION_DIALOGUE`) as a short reaction line on serve-complete when that companion is active, using the same "spawn floating text" pattern `CookingController.lua:67-80` already uses for hit-quality ratings. Also the trigger point for bond XP from §2.
- **Companions reacting to what recipe was just served.** `VNDialogueData.lua`'s per-companion pools are keyed by `timeOfDay` today (`:31-257`); adding a `recipeReaction` sub-key per companion (even just 1-2 generic lines to start) reuses the exact same lookup/render pipeline — no new dialogue system.
- **Biome-visit quest chains unlocking companion cosmetics.** `set_companion` quests (`QuestConfig.lua:806-853`) already reward `{gold, tier_points}` on "meeting" a companion; extending a `visit_zones_unique` chain's final step to also flip a `companion_owned_<type>`-style unlock flag (same flag CompanionManager already checks, `:485-499`) ties biome exploration directly to companion collection — Nikki's exploration feeding Uma's collection, using only fields that already exist.
- **UI attachment point for anything player-facing here:** `src/client/ConfigurationFiles/UIActionRegistry.lua` is the registry Pea Wheel actions come from (`:1-6, 40+`), and `PeaWheelController.lua` renders whatever's registered there. Any new bond-level readout, biome-progress tracker, or companion-reaction toast should register through this path rather than a bespoke GUI — it's already the documented attachment point per `PHASE4_MONETIZATION_PLAN.md`'s own shop-unification recommendation, and the same pattern applies here.

---

## 5. Prioritized next steps (effort : impact)

1. **(Lowest effort, highest impact) Wire `companion_chat` and serve-events into the new `data.companion_bond[compType]` table, and re-key `getCompanionDialogue` to bond level instead of player level.** Pure data/lookup change on top of `VNDialogueData.lua:286-303`, `PlayerDataService.lua`, and the quest type that already exists (`QuestConfig.lua:382-391`). This alone turns companions from static buff-sticks into things worth spending time with — the core Uma loop — without a single new asset.
2. **Add a serve-time reaction line from the active companion**, reusing this session's dialogue-lookup fix (`VNDialogueData.GUEST_BY_TYPE`, `GuestManager.server.lua:355-372`) as the template — same "look up by key, fall back to DEFAULT" pattern, applied to companions instead of guests.
3. **Bias guest mesh-type spawn weighting by biome** (extend `GuestManager.server.lua:240-265`'s existing weighted-selection function with a biome parameter) — makes wandering the 10 biomes (already built, already Nikki-flavored) produce visibly different guest mixes for near-zero new code.
4. **Extend 2-3 existing `gather_unique` chains (`QuestConfig.lua` `chain_id`/`chain_step` pattern) to point at biome-tagged nodes**, giving exploration a reason to repeat. Slightly more effort (requires tagging `LandscapeConfig.lua` asset profiles per biome) but still config-only.
5. **(Defer) Wardrobe/outfit equip wiring** — real impact for the "dress-up" half of Nikki, but per `PHASE4_MONETIZATION_PLAN.md`'s own finding, this needs actual outfit assets and a real equip pipeline (`OutfitWardrobeGui.client.lua` currently has zero click handlers), which is a bigger lift than anything above and already flagged as an open gap elsewhere — don't duplicate that work here, just note it's the natural "next tier" once bond and biome wiring above are in.

Everything in 1-4 builds directly on what shipped this session (animal guests + roaming + dialogue fix, procedural landscape, companion animation state machine) rather than opening new threads, and none require new art.
