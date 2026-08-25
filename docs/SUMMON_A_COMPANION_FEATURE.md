# Summon a Companion — Create Your Own Zundamon (AI-Generated Companions)

**Status:** Implemented + LLM verified live. Testing guide below.

A player can summon a brand-new, unique companion by typing a theme ("a sleepy moon
fox who loves rice balls"). A local LLM generates the companion's identity, look,
and gameplay buff; it's registered to the player's persistent data and walks beside
them immediately. Optional VOICEVOX voice for a greeting line.

---

## Architecture

```
┌─ In-game ──────────────────────────────────────────────────────────────┐
│ CompanionCreatorUI (client LocalScript)                                 │
│   theme textbox + preset chips → "Summon Companion"                      │
│        │  SummonCompanion RemoteFunction                                 │
│        ▼                                                                 │
│ CompanionCreatorServer (server)                                          │
│   SummonCompanion.OnServerInvoke → CompanionCreatorService.generate+create│
│        │                                                                 │
│        ▼                                                                 │
│ CompanionCreatorService (server)                                         │
│   generate(player, theme)  → CompanionAIGenerator.generate               │
│   create(player, spec)     → validates + writes PlayerData.custom_companions│
│        │                                                                 │
│        ▼                                                                 │
│ CompanionAIGenerator (server seam)                                       │
│   GENERATE_URL = http://127.0.0.1:8700/generate                           │
└────────────────────────────────────────────────────────────────────────┘
        │  HTTP POST /generate {"theme": ...}
        ▼
┌─ Local AI bridge ─────────────────────────────────────────────────────┐
│ scripts/companion_ai_bridge.py  (python, port 8700)                     │
│   POST /generate → Ollama (qwen2.5-coder:7b) → JSON spec                 │
│   GET  /health   → llm + voicevox reachability                          │
└────────────────────────────────────────────────────────────────────────┘
```

Rendering: `CompanionManager.buildCompanion` resolves `cc_*` custom companions from
`PlayerData.custom_companions[id]` and reuses the shared base body (`zundapalupdate4`),
recolored per the spec — no new mesh needed. Buffs apply via
`CompanionBuffServer` (also custom-aware).

## Files

| File | Role |
|---|---|
| `src/client/CompanionCreatorUI.client.lua` | Creator panel (theme input, presets, summon) |
| `src/server/CompanionCreatorServer.server.lua` | RemoteFunction wiring (`SummonCompanion`, `CreateCompanion`, `CompanionCreated`) |
| `src/server/Services/CompanionCreatorService.lua` | Validation + persistence (`create`, `list`, `generate`), whitelists |
| `src/server/Services/CompanionAIGenerator.lua` | AI seam → `GENERATE_URL`; deterministic offline fallback |
| `scripts/companion_ai_bridge.py` | Local LLM(+voice) HTTP bridge (port 8700) |
| `scripts/test_companion_ai.py` | Automated test harness (below) |
| `src/server/CompanionManager.server.lua` | Render custom companions (resolveDef) |
| `src/server/CompanionBuffServer.server.lua` | Apply custom-companion buffs |
| `src/server/Services/PlayerDataService.lua` | `custom_companions` store (defaults + backfill) |

## Security / validation
A client can never inject arbitrary values. `CompanionCreatorService.normalizeSpec`
whitelists: buff stats, emoji, string lengths, and colors (now including positional
`[r,g,b]` arrays from LLM/JSON). Everything else is clamped or dropped.

---

# Testing Guide

## Prerequisites
1. **Ollama** running with a model (qwen2.5-coder:7b recommended):
   ```
   ollama serve
   ```
2. **Companion AI bridge** running:
   ```
   python scripts/companion_ai_bridge.py --port 8700
   ```
3. (Optional) **VOICEVOX** running (for voice): `python scripts/voicevox_client.py --serve`

## Automated test (LLM verification — no Studio needed)
```
python scripts/test_companion_ai.py
```
Checks: bridge health (llm + voicevox) · real LLM generation · spec passes a mirror
of the game's `normalizeSpec` (emoji/buff/color/recipe whitelists) · distinct themes →
distinct companions. Expect `RESULT: ALL PASS`.

## In-Studio manual test
1. Run the bridge + ollama (above).
2. In Studio, **enable HttpService access**: File → Game Settings → Security → Allow HTTP Requests.
3. Set `CompanionAIGenerator.GENERATE_URL` (already set to `http://127.0.0.1:8700/generate`).
4. Playtest. Open the creator: **Pea Wheel → Summon a Companion** (or `_G.ZundaCompanionCreator.open()`).
5. Type a theme or tap a preset chip → **Summon Companion**.
6. Verify:
   - A new companion appears beside you, named per the theme.
   - Its glow/sparkles match the generated palette (NOT default blue).
   - Its buff shows on the companion HUD / applies in play.
   - It's re-equipped on respawn (persisted).
7. Summon a second, different theme → a different companion (distinct name/color).

## What to look for / known notes
- **Reduced Motion**: UI is pure screen-space; no issue. Companion follow/aura respect it.
- **Offline fallback**: if the bridge is down, `CompanionAIGenerator` returns a
  deterministic themed companion so summoning still works (name derived from theme).
- **Model latency**: first call after `ollama serve` loads the model (~30s cold);
  subsequent calls are fast. Keep the model warm for snappy summons.
- **HttpService permission**: the server must be allowed HTTP requests, else
  `generate` silently falls back to the offline path (no error, but not AI-generated).

## Gates
- `npm run lint:selene` → 0 errors
- `npm run lint:stylua` → formatted
- `npm run rojo:build` → PASS (all modules in place)
