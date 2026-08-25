# Session Handoff — 2026-08-25 (Zundamon's Kitchen V2)

## What shipped this session (committed)
3 feature commits on `main` (local, NOT pushed — 3 ahead of origin/main):

| Commit | Contents |
|---|---|
| `adc8953` | CompanionCreatorService, CompanionAIGenerator (AI seam), CompanionCreatorServer (RemoteFunction wiring) |
| `50b9f4d` | CompanionCreatorUI, ChefAura, companion_ai_bridge.py, test_companion_ai.py, SUMMON_A_COMPANION_FEATURE.md |
| `5135d44` | PlayerData custom_companions store; CompanionManager.resolveDef; CompanionBuffServer custom buffs |

### Feature: "Summon a Companion" (create-your-own / AI-generated Zundamon)
- Client UI → `SummonCompanion` RemoteFunction → `CompanionCreatorService` → `CompanionAIGenerator` → local AI bridge.
- LLM verified LIVE: bridge (`scripts/companion_ai_bridge.py`, port 8700) + Ollama (qwen2.5-coder:7b) generated 3 distinct valid companions ("Dreamy Moon Fox", "Gloomy Fungus", "Whirligig"). `python scripts/test_companion_ai.py` → **ALL PASS**.
- Also earlier: 3 bug-fix commits (af89e8c, 929dca0, 59ca988) from the live playtest echo capture (HUD popup Scale, Font→FontFace, LoadAnimation guards, gather PrimaryPart). Those are in history below the echo pipeline commit.

## Status / Triage
- **My work**: committed, gates green (Selene 0 errors on my files, StyLua clean, rojo build PASS).
- **Not pushed**: 3 commits ahead of origin/main. Left unpushed because the concurrent lane is actively working; push when the tree settles.
- **Concurrent lane (NOT mine)**: 67 uncommitted files — rhythm minigame tests (run_rhythm_tests.py, stress_test, test_m1_rhythm), M1 companion expansion (CompanionConfig/VisualConfig, verify_m1 oracle), Zundarooms, Damon evolution configs, VoiceConfig, LLMConfig, PhotoModeUI, etc. LEFT UNTOUCHED.
- **CompanionManager.server.lua is CO-AUTHORED** with the lane (their robustness/audit work — scale guards, animation spec, PBR fallback logging — lives in the same file as my resolveDef). Committed together in 5135d44; the lane should be aware.

## To resume the AI companion feature
1. Ollama + bridge were stopped at session end. Restart:
   - `ollama serve`
   - `python scripts/companion_ai_bridge.py --port 8700`
2. In Studio: File → Game Settings → Security → **Allow HTTP Requests** (required for the server to reach the bridge, else it silently falls back to offline mode).
3. Playtest → Summon a Companion → type a theme → Summon.
4. Docs: `docs/SUMMON_A_COMPANION_FEATURE.md` (architecture + testing guide).

## Key files (all committed)
- `src/server/Services/CompanionCreatorService.lua`, `CompanionAIGenerator.lua`
- `src/server/CompanionCreatorServer.server.lua`
- `src/client/CompanionCreatorUI.client.lua`, `ChefAura.client.lua`
- `scripts/companion_ai_bridge.py`, `scripts/test_companion_ai.py`
- `docs/SUMMON_A_COMPANION_FEATURE.md`
