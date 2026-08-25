--!strict
-- CompanionAIGenerator: AI seam for "create your own Zundamon" companions.
--
-- Turns a short theme prompt ("a sleepy moon fox who loves rice balls") into a
-- complete companion spec: a generated name, flavor, persona, color palette,
-- emoji, and buff. This is the LIVE hook for the AI side of companion creation.
--
-- Wiring (do when ready): point GENERATE_URL at an HTTP endpoint that accepts a
-- theme and returns a JSON spec {name, displayName, flavor, persona, emoji,
-- glow[3], sparkleColors[[3]x3], buff{stat,magnitude,description}}; and have that
-- endpoint shell out to scripts/voicevox_client.py to synthesize a greeting line.
--
-- Until wired, this module returns the deterministic fallback (via
-- CompanionCreatorService), so the creator UI works fully without any AI.

local HttpService = game:GetService("HttpService")

local CompanionAIGenerator = {}

-- Set to a reachable endpoint to enable live generation. Empty = offline mode.
-- Point at the local companion AI bridge:
--   python scripts/companion_ai_bridge.py --port 8700
-- (must be reachable from the server; add HttpService permission in Studio.)
CompanionAIGenerator.GENERATE_URL = "http://127.0.0.1:8700/generate"

local ALLOWED_EMOJI = {
	"🌱",
	"🌸",
	"🍡",
	"🍵",
	"🌙",
	"☀️",
	"🍄",
	"🦊",
	"🐸",
	"🐢",
	"🐻",
	"🦉",
	"⭐",
	"🌊",
	"🍂",
	"🪷",
	"🥟",
	"🍙",
	"🫧",
	"💫",
}

-- Theme-derived deterministic fallback so a prompt still yields a plausible
-- companion even with the AI endpoint offline. Uses the theme text to seed a
-- name and a palette hue (so it feels themed, not random).
local function fallback(prompt: string): { [string]: any }
	local hue = (math.floor(string.byte(prompt, 1) or 120) / 255) % 1
	local glow = Color3.fromHSV(hue, 0.55, 0.9)
	local word = prompt:match("([%a]+)") or "Mystery"
	local name = "Zunda-" .. word:sub(1, 1):upper() .. word:sub(2, 12)
	return {
		name = name,
		displayName = name,
		flavor = "A quiet little spirit summoned from '" .. prompt .. "'.",
		persona = "You are "
			.. name
			.. ", a companion born from '"
			.. prompt
			.. "'. You keep the player company while they cook, and you love their signature dishes.",
		emoji = ALLOWED_EMOJI[math.random(1, #ALLOWED_EMOJI)],
		glow = { glow.R, glow.G, glow.B },
		sparkleColors = {
			{ glow.R, glow.G, glow.B },
			{ math.min(1, glow.R + 0.2), math.min(1, glow.G + 0.2), 1 },
			{ 1, 1, 1 },
		},
		buff = { stat = "gold", magnitude = 0.05, description = "+5% gold from serving guests" },
		signature_recipes = { "Zunda Mochi", "Bread" },
	}
end

-- Returns a spec table for `prompt`, or the deterministic fallback if the AI
-- endpoint is unreachable. `voice` is accepted for future voicevox wiring.
function CompanionAIGenerator.generate(prompt: string, voice: string?): { [string]: any }
	if CompanionAIGenerator.GENERATE_URL == "" then
		return fallback(prompt)
	end

	local ok, result = pcall(function()
		local body = HttpService:JSONEncode({ theme = prompt, voice = voice or "normal" })
		local resp = HttpService:PostAsync(
			CompanionAIGenerator.GENERATE_URL,
			body,
			Enum.HttpContentType.ApplicationJson,
			false,
			15
		)
		return HttpService:JSONDecode(resp)
	end)
	if ok and type(result) == "table" and type(result.name) == "string" then
		return result
	end
	return fallback(prompt)
end

return CompanionAIGenerator
