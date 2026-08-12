# `scripts/` — Dev Tools & Content Workers

Quick map so one-off scratch doesn't get mistaken for maintained tooling.

## Maintained tools (CI-referenced or actively used)

| File | Purpose |
| --- | --- |
| `check_config_crossrefs.py` | **Runs in CI.** Verifies ScatterConfig ↔ ResourceVisualCatalog ↔ ResourceNodeRegistry ↔ MineableConfig ↔ AGENTS remote list stay in sync. |
| `ollama_client.py` | Shared Ollama API client (Zundamon persona, Lua formatter, JSON extraction). |
| `ollama_recipe_worker.py` | Generates recipes for `CraftConfig.lua` (`--count N --model M`). |
| `ollama_quest_worker.py` | Generates quests for `QuestConfig.lua`. |
| `ollama_dialogue_worker.py` | Generates dialogue for `VNDialogueData.lua`. |
| `map_mesh_to_harvest.lua` | Maps harvestable archetypes to mesh IDs (command-bar style). |
| `extract_asset_ids.py` | Extracts asset IDs from the repository/place. |
| `preflight_audit.py` | Repo pre-flight audit. |
| `verify_m1_remotes.py` | Verifies M1 remote declarations. |
| `upload_decal.py` | Decal upload helper. |
| `create_zundamon_glb.py` | Zundamon GLB build helper. |

## One-off fixes (historical, keep for reference only)

`final_polish.py`, `fix_all_systems.py`, `fix_panels.py`, `fix_peewheel.py`, `fix_sounds.py`, `phase3_verification_test.lua`

## Content / social workers (external pipeline)

`autonomous_social_publisher.py`, `generate_tiktok_video.py`, `marketing_content_worker.py`, `ollama_social_worker.py`, `zunda_social_worker.py`

> Rule: new one-off scratch goes under `scripts/` only if it earns a row above;
> otherwise keep it out of the repo or under `docs/archive/`.
> Output from content workers is ignored (`scripts/ollama_output/`).