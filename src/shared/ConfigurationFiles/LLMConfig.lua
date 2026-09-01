--!strict
-- [[ModuleScript] LLMConfig]]
-- Live LLM companion AI configuration for Zundamon's Kitchen V2.
--
-- The LLM bridge (scripts/companion_ai_server.py) runs locally on port 8742
-- and proxies companion chat requests to Ollama. This module is the single
-- place to toggle the bridge on/off and configure all AI behaviour.
--
-- QUICK START:
--   1. Install Ollama:     https://ollama.com
--   2. Pull the model:     ollama pull gemma4:12b
--   3. Start the bridge:   python scripts/companion_ai_server.py
--   4. Set enabled = true below, then Rojo sync.
--   See docs/LLM_PIPELINE.md for the complete guide.

local LLMConfig = {}

-- ── Feature Toggle ────────────────────────────────────────────────────────────
-- Set to true only after companion_ai_server.py is running.
-- When false, CompanionAIGenerator falls back to deterministic output.
LLMConfig.enabled = false

-- ── Bridge Endpoints ──────────────────────────────────────────────────────────
LLMConfig.bridge_url = "http://localhost:8742"
LLMConfig.generate_url = LLMConfig.bridge_url .. "/generate-companion"
LLMConfig.chat_url = LLMConfig.bridge_url .. "/companion-chat"
LLMConfig.health_url = LLMConfig.bridge_url .. "/health"

-- ── Request Settings ──────────────────────────────────────────────────────────
-- HTTP timeout in seconds (Roblox HttpService max is 30).
LLMConfig.timeout_seconds = 15

-- Per-companion chat cooldown — prevents VO/chat spam.
-- High-frequency interactions (serve, cook) get longer cooldowns.
LLMConfig.chat_cooldowns = {
	companion_chat = 8, -- general chat reply
	generate_custom = 60, -- custom companion generation (expensive)
}

-- ── Model Selection ───────────────────────────────────────────────────────────
-- These are passed to the bridge; the bridge selects the Ollama model.
-- Change "dialogue" to "quality" for slower but richer companion replies.
LLMConfig.models = {
	companion_chat = "dialogue", -- gemma4:12b recommended
	generate_companion = "dialogue", -- gemma4:12b recommended
}

-- ── Context Budget ────────────────────────────────────────────────────────────
-- Maximum characters of game context sent per chat request.
-- Smaller = faster; larger = more contextually aware.
LLMConfig.context_max_chars = 400

-- ── Fallback Behaviour ────────────────────────────────────────────────────────
-- When enabled = false OR bridge unreachable, these static lines are
-- returned so the chat UI never appears broken.
LLMConfig.offline_fallbacks = {
	companion_chat = "( ... I seem to be far away right now. Find me again soon! )",
	generate_custom = nil, -- nil = CompanionAIGenerator uses its own deterministic fallback
}

-- ── Rate Limiting ─────────────────────────────────────────────────────────────
-- Maximum concurrent in-flight LLM requests server-wide.
-- Prevents thundering-herd on a single Ollama instance.
LLMConfig.max_concurrent_requests = 3

return LLMConfig
