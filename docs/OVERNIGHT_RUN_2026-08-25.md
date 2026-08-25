# Overnight Run — 2026-08-25 (Tests + Content Generation + 100h Scope)

**Status:** Tests PASS · Content generated · 100h scope plan written
**Companion docs:** `docs/CONTENT_100H_SCOPE_PLAN.md`, `docs/SUMMON_A_COMPANION_FEATURE.md`

---

## 1. Test results (all PASS)

| Suite | Result |
|---|---|
| `run_rhythm_tests.py` (E2E rhythm, Tiers 1-5) | **122/122 PASS** (T1:53, T2:51, T3:10, T4:5, T5:3) |
| `verify_m1_companions_oracle.py` (companion expansion) | **ALL PASS / VERDICT APPROVE** (36 quests, 12 recipes, 36 voicelines, creative quotas) |

Run:
```
python scripts/run_rhythm_tests.py
python scripts/verify_m1_companions_oracle.py
```

## 2. Content generation (via Ollama workers)

| Worker | Requested | Result | Output file |
|---|---|---|---|
| `ollama_recipe_worker.py` | 20 | **9 recipes** (valid Lua, companion-themed) | `scripts/ollama_output/generated_recipes_100h.lua` |
| `ollama_quest_worker.py` | 12 | **~12 quests** (valid Lua, chain-gated) | `scripts/ollama_output/generated_quests_100h.lua` |
| `ollama_dialogue_worker.py` | 40 | **60 dialogue lines** (6+ speakers × slots) | `scripts/ollama_output/generated_dialogue_100h.lua` |

### ⚠️ Model fix discovered (IMPORTANT for future runs)
The content workers' **default models are broken** on this machine:
- `ollama_recipe_worker` → `deepseek-coder:6.6b` default: generated nothing parseable.
- `ollama_quest_worker` / `ollama_dialogue_worker` → `llama3.1:8b` / `gemma4:12b`: **404** (not pulled).

**Working model: `qwen2.5-coder:7b`** (recipes ✅, dialogue ✅, quests ✅ after a worker fix).

**Fix:** always pass `--model qwen2.5-coder:7b` (or pull the intended models). Consider
updating the `MODEL_PRESETS` in `scripts/ollama_client.py` to models actually installed.

### ⚠️ Quest worker bug fixed
`scripts/ollama_quest_worker.py` crashed at format time with
`TypeError: %d format: a real number is required, not str` — the parser captured
`target` as a string, but `format_lua_output` did `%d`. Fixed: coerce `target` to int
in `parse_single_quest`. After the fix, quest generation succeeded (~12 quests).
(This is a fix to the worker tool; it's committed separately.)

### Review notes
- Recipes generated 9/20 (model under-filled count); **2 duplicate existing names**
  ("Ankomon's Protein Punch", "Zundamon's Banquet") — dedupe before merge.
- LLM output is NOT trusted raw: run the `verify_*` oracles before merging into configs.

## 3. 100+ hour content scope plan
`docs/CONTENT_100H_SCOPE_PLAN.md` — grounded in live content (74 recipes, 99 quests,
10 biomes, 9+ companions). Phased: A (core density: 250 recipes, 300 quests) → B
(biomes as destinations) → C (companion bonding) → D (mastery/collection). The key
insight: 100h comes from **density × variety × gating compounding**, not raw item
count. ~30-35 worker batches ≈ 1-2h of generation; review/merge/gates is the binding
constraint.

## 4. Deliverables / files
- `docs/CONTENT_100H_SCOPE_PLAN.md` — the scope plan.
- `scripts/ollama_output/generated_recipes_100h.lua` — 9 recipes.
- `scripts/ollama_output/generated_dialogue_100h.lua` — 60 dialogue lines.
- `scripts/ollama_output/generated_quests_100h.lua` — quests (if the run completes).
- This handoff: `docs/OVERNIGHT_RUN_2026-08-25.md`

## 5. Operational note
On the CLI there is no messaging gateway — "send out" = files written to the repo,
ready for review. Results are NOT auto-delivered as a message. If notification is
wanted on a future run, the cron job must target a gateway platform (e.g. `deliver='telegram'`).
