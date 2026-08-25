# 100+ Hour Playable Content Scope Plan — Zundamon's Kitchen V2

**Status:** PROPOSED · grounded in current live content (not inflated)
**Date:** 2026-08-25
**Companion doc:** `docs/PHASE4_GAMEPLAY_DIRECTION.md` (design pillars)

---

## 1. Current content baseline (measured from disk this session)

| Pillar | Current | Source |
|---|---|---|
| Recipes | ~74 | `CraftConfig.lua` |
| Quests | ~99 | `QuestConfig.lua` |
| Progression milestones | 10 tiers | `ProgressionConfig.lua` |
| Named companions | 9 (+ dynamic AI companions) | `CompanionConfig.lua` + `custom_companions` |
| Biomes / zones | 10 | `LandscapeConfig.lua` |
| Guests | 24 animal meshes + Kenney humans | `GuestManager` |
| Dialogue tiers | 3 per companion (level1_10/11_20/21_50) | `VNDialogueData.lua` |

**Honest throughput reality:** a cozy-game hour is not a tight 1:1 content-to-time
mapping. A single loop iteration (harvest → cook → serve → quest → level) is ~2-4
minutes of engaged play. 100 hours = ~1,500-2,500 loop iterations. That is **not**
1,500 recipes — it's a *density + variety + gating* problem. The plan below targets
the levers that actually create playtime, not raw item counts.

---

## 2. The three pillars (from PHASE4_GAMEPLAY_DIRECTION)

1. **Nikki** — cozy exploration + aesthetic collection (biomes as destinations, outfits).
2. **Uma** — character bonding / personality-driven companions (per-companion bond).
3. **Core loop** — harvest → cook → serve → quest → rank, with rhythm + companions layered on.

A 100h game needs all three to *compound*. Grinding recipes alone burns out fast; the
bond + exploration layers give the "one more thing" hook.

---

## 3. Content generation pipeline (the "send out updated content" engine)

The repo has an **LLM content pipeline** (`scripts/ollama_*_worker.py`) that generates
Lua content via the local model and writes to `scripts/ollama_output/`. This is the
scalable engine for the plan. Overnight run this session:
- `ollama_recipe_worker.py --count 30` → `generated_recipes_100h.lua`
- `ollama_quest_worker.py --count 25` → `generated_quests_100h.lua`
- `ollama_dialogue_worker.py --count 40` → `generated_dialogue_100h.lua`

**Process:** LLM generates → `ollama_output/` → reviewed → merged into configs →
gates (Selene/StyLua/rojo build) → committed. Never auto-merged: every batch is
reviewed (LLM output is not trusted raw; recipe/quest parsers + format validation).

---

## 4. Content targets to reach 100+ hours (phased)

### Phase A — Core loop density (0-25h): recipes + quests + difficulty
Goal: enough variety that the first 25h never repeats a "wall."
- **Recipes: 74 → 250** (~175 new). Recipe = the core reward. 250 recipes across
  10 biomes + companion signature dishes. Generate in batches of 30-50 via worker.
- **Quests: 99 → 300** (~200 new). Mix of one-shot (serve/cook/gather), chains
  (chain_id/chain_step), and tier-gated. Progression milestones 10 → 25 tiers.
- **Ingredients: expand the harvest pool** (currently ~16) to ~35 with biome-exclusive
  gather nodes — makes recipes require *travel*, not just grinding one biome.
- **Difficulty curve:** recipes gate by chef rank + biome unlock, so early content
  stays relevant (a Rank 1 chef can't just cook everything).

### Phase B — Exploration as destination (25-50h): biomes + gather + world
Goal: biomes stop being decoration and become places you return to.
- **10 biomes → each gets 2-3 exclusive gather nodes + 1-2 exclusive guest types.**
  Currently all 10 share one asset pool (`LandscapeConfig`). Tag exclusive assets
  per biome; point `gather_unique` chains at them (mechanism already exists).
- **Biome guest spawn weighting** — extend `GuestManager` weighted selection with a
  biome param (more wildlife in Forest, market-goers in ZundaMarket).
- **~60 zone-visit quests** rewarding return visits across chef-rank tiers.

### Phase C — Companion bonding (50-75h): the Uma loop
Goal: companions are worth investing in; bond drives replay.
- **Bond system** (already built this session): per-companion bond XP on serve +2,
  chat +1, click +1. Bond tiers 1/2/3 re-key dialogue pools.
- **Companion count: 9 → 20** (11 new, incl. AI-generated via the Summon feature).
- **Bond-milestone rewards:** bond Lv5 → cosmetic (glow/particle color), Lv10 → unique
  VN scene. ~60 bond-milestone quests across 20 companions.
- **Per-companion signature recipes:** each companion drives 3+ dishes → 60+ recipes.

### Phase D — Mastery + collection (75-100h): endgame
Goal: the "100% it" hook.
- **Reputation tiers** (Fresh → Legendary, exists in ChefStatsConfig) → 15 stages.
- **Style points + outfit collection** — dress-up ladder (flagged as needing real
  outfit assets + equip pipeline; the natural next tier after bond/biome).
- **Completion book:** compendium of all 250 recipes + 300 quests + 20 companions →
  a completion % chase.
- **Daily + Endless** (already built) provide the "keep coming back" daily hook.

---

## 5. Realistic content math (honest projection)

| Content type | Target total | New | Generated/batch | Approx. LLM batches |
|---|---|---|---|---|
| Recipes | 250 | 175 | 30-50 | 4-6 |
| Quests | 300 | 200 | 20-30 | 7-10 |
| Dialogue lines | ~600 | ~500 | 40 | 12 |
| Bond-milestone quests | 60 | 60 | 20 | 3 |
| Zone-visit quests | 60 | 60 | 20 | 3 |
| **Total batches** | | | | **~30-35 worker runs** |

At ~1-3 min per generation (warm model), 30 batches ≈ **1-2 hours of active
generation** (can be overnight). The *binding constraint is review + merge + gates*,
not generation.

**Why this reaches 100h:** not item count, but **density × variety × gating**.
- 250 recipes + 35 ingredients across 10 biomes = hundreds of distinct loop
  combinations; even at 2 min/loop, the *decision space* sustains 25h.
- 20 companions with bond progression = the Uma "raise your partner" loop, 25h.
- Biome-exclusive gather + zone chains = the Nikki exploration loop, 25h.
- Mastery/collection = the long-tail "one more" chase, 25h.
These layers **compound** (a recipe needs a biome ingredient needs a companion bond),
which is what stretches 250 recipes into 100h.

---

## 6. Automation & tooling (to scale generation)

1. **Batch runner:** `scripts/run_content_batch.py` — runs N recipe/quest/dialogue
   generations sequentially, dedupes against existing configs, writes versioned
   outputs to `ollama_output/batches/<timestamp>/`.
2. **Validation oracle** (pattern: `verify_m1_companions_oracle.py`): after generation,
   verify recipes use only known ingredients, quests use valid types, no duplicate IDs.
3. **Merge script:** applies reviewed batches to configs with a dry-run diff.
4. **CI gates:** Selene + StyLua + rojo build must pass on merged configs.

---

## 7. What "send out updated content" means operationally
On the CLI (this session) there is **no messaging gateway** — output is written to
files, not delivered as a message. "Send out" = generate → write to
`scripts/ollama_output/` + this plan → committed/reviewed for the next playtest.
If the user wants notifications, a cron job must target a gateway platform
(e.g. `deliver='telegram'`); otherwise results are file-local.

---

## 8. Immediate next steps (when you're back)
1. Review `scripts/ollama_output/generated_*_100h.lua` (recipes/quests/dialogue from
   the overnight run).
2. Run `verify_*` oracles on the generated content; fix any format/dupe issues.
3. Merge the first reviewed batch into configs (one concern per commit).
4. Continue batch generation to the Phase A targets (250 recipes, 300 quests).
