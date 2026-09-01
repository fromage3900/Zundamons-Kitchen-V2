# LLM Pipeline — Zundamon's Kitchen V2

> **Quick status**: The pipeline is fully wired but ships with `LLMConfig.enabled = false` by default.  
> Follow this guide to activate live AI companion chat.

---

## Overview

The LLM pipeline connects Roblox (via HttpService) to a locally-running Ollama inference server through a lightweight Python bridge:

```
Roblox Studio / Game Client
        │  HttpService:PostAsync
        ▼
scripts/companion_ai_server.py   (port 8742)
        │  ollama_client.py
        ▼
Ollama server  (port 11434)
        │
        ▼
gemma4:12b  (or any supported model)
```

The bridge handles:
- Character-voice-appropriate chat replies (`/companion-chat`)
- Custom companion spec generation (`/generate-companion`)
- Graceful offline fallback — Roblox **never** sees a 500 error

---

## Setup (5 steps)

### Step 1 — Install Ollama

Download from [https://ollama.com](https://ollama.com) and install for your OS.

### Step 2 — Pull the required model

```bash
ollama pull gemma4:12b
```

Lighter alternative (lower quality):
```bash
ollama pull llama3.1:8b
```

Confirm Ollama is running:
```bash
curl http://localhost:11434/api/tags
```

### Step 3 — Start the bridge

```bash
# From the project root:
python scripts/companion_ai_server.py
```

You should see:
```
[INFO] Companion AI Bridge — Zundamon's Kitchen V2
[INFO]   Listening on http://127.0.0.1:8742
[INFO]   Ollama client:  loaded
[INFO]   Personas:       21 companions
```

Test it:
```bash
curl http://localhost:8742/health
# → {"status": "ok", "ollama_available": true, "companions_loaded": 21, ...}
```

### Step 4 — Enable in game config

Edit [`src/shared/ConfigurationFiles/LLMConfig.lua`](../src/shared/ConfigurationFiles/LLMConfig.lua):

```lua
LLMConfig.enabled = true  -- was false
```

Then Rojo sync to Studio.

### Step 5 — Verify in Studio

In the Roblox Studio test console:
```lua
local LLMConfig = require(game.ReplicatedStorage.ConfigurationFiles.LLMConfig)
print(LLMConfig.enabled, LLMConfig.bridge_url)
-- → true  http://localhost:8742
```

---

## Endpoints

### `GET /health`

Returns bridge and Ollama status. Always responds with 200.

```json
{
  "status": "ok",
  "ollama_available": true,
  "companions_loaded": 21,
  "timestamp": 1724570400
}
```

### `POST /companion-chat`

Generates a character-voice chat reply for a companion.

**Request:**
```json
{
  "companion_key": "sumimon",
  "player_name": "Fromage",
  "context": "Player just cooked a perfect soba dish. Current time: evening.",
  "message": "Did I do well?"
}
```

**Response:**
```json
{
  "reply": "... the brushstroke holds. You did well. Do not ruin it by asking again."
}
```

**Fallback** (Ollama offline):
```json
{
  "reply": "( ... the brush is still. I will return when the ink is ready. )"
}
```

### `POST /generate-companion`

Generates a full companion spec from a theme prompt. Used by `CompanionAIGenerator.lua`.

**Request:**
```json
{
  "theme": "a sleepy moon fox who loves mochi",
  "voice": "sweet"
}
```

**Response:**
```json
{
  "name": "tsukigitsunemon",
  "displayName": "Tsukigitsune·mon",
  "flavor": "A fox spirit who slumbers by moonlight and wakes only for the smell of fresh mochi.",
  "persona": "You are Tsukigitsune·mon, a drowsy celestial fox who guards midnight kitchens.",
  "emoji": "🦊",
  "glow": [210, 200, 255],
  "sparkleColors": [[230, 220, 255], [190, 180, 240], [255, 255, 255]],
  "buff": {"stat": "night_shift_surge", "magnitude": 0.20, "description": "+20% earnings at night"},
  "signature_recipes": ["Tsukimi Mochi", "Fox Fire Soup"],
  "_offline": false
}
```

---

## Data Flow (Roblox → Ollama)

```
1. Player opens companion chat UI
2. Client fires remote → CompanionChatService (server)
3. Server reads companion's llmPersona from CompanionConfig
4. Server checks LLMConfig.enabled and cooldown
5. If enabled: HttpService:PostAsync → bridge /companion-chat
6. Bridge constructs Ollama prompt with persona + context + message
7. Ollama generates reply (gemma4:12b, ~1–3s)
8. Bridge returns reply JSON
9. Server fires remote → Client displays reply in VN dialogue panel
```

If any step from 5 onward fails (bridge down, Ollama slow, timeout):
- Bridge returns the companion's offline fallback string
- Roblox never sees an error — UI shows a themed "far away" message

---

## Adding a New Companion Persona

1. Add the companion to `CompanionConfig.lua` with a `llmPersona` field
2. Add an entry to `scripts/companion_personas.json` (optional — the bridge falls back to the config field)
3. The persona string should be 1–3 sentences in second person: "You are X, who does Y..."
4. Test with: `curl -X POST http://localhost:8742/companion-chat -d '{"companion_key":"yourkey","player_name":"Test","context":"","message":"Hello!"}'`

---

## Cooldown / Rate Limiting

- **Per-companion chat cooldown**: 8 seconds (set in `LLMConfig.chat_cooldowns.companion_chat`)
- **Custom generation cooldown**: 60 seconds (expensive; prevents spam)
- **Max concurrent Ollama requests**: 3 (semaphore in bridge)
- **HTTP timeout**: 15 seconds (Roblox side)

High-frequency interactions (serve, cook) should NOT trigger chat — only explicit player-initiated chat should. This is enforced by the server-side cooldown table in `CompanionChatService`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Bridge won't start | Port 8742 in use | `netstat -aon \| findstr 8742`, kill the PID |
| `ollama_available: false` | Ollama not running | `ollama serve` |
| Replies are fallback strings | Model not pulled | `ollama pull gemma4:12b` |
| Roblox HttpService error | `enabled = false` or bridge not running | Check LLMConfig.enabled, check bridge |
| Slow replies (> 5s) | Model too large for hardware | Switch to `llama3.1:8b` in MODEL_PRESETS |
| OOM crash | Model too large | Use `qwen2.5-coder:1.5b-base` for fast mode |

---

## Model Recommendations

| Use case | Model | Quality | Speed |
|---|---|---|---|
| Companion chat (recommended) | `gemma4:12b` | High | ~2–3s |
| Companion chat (fast) | `llama3.1:8b` | Good | ~1–2s |
| Custom companion gen | `gemma4:12b` | High | ~3–5s |
| Dev / testing | `qwen2.5-coder:1.5b-base` | Low | < 1s |

Model selection is configured per endpoint in `LLMConfig.models`.

---

## Attribution

- Bridge code: `scripts/companion_ai_server.py` — stdlib only, no Flask/FastAPI dependencies
- Ollama client: `scripts/ollama_client.py`
- Game config: `src/shared/ConfigurationFiles/LLMConfig.lua`
- Roblox seam: `src/server/Services/CompanionAIGenerator.lua`
