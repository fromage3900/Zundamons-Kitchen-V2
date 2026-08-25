--!strict
-- CompanionCreatorService: register player-created / AI-generated companions.
--
-- A "dynamic" companion is stored per-player in PlayerData.custom_companions[id]
-- and rendered by CompanionManager.buildCompanion from its spec, reusing the
-- shared base body (zundapalupdate4) recolored per the spec — no new mesh needed.
--
-- Two entry points:
--   CompanionCreatorService.create(player, spec)  — register a validated spec
--   CompanionCreatorService.generate(player, theme, voice) — AI seam: produce a
--     spec from a theme prompt + optionally a voicevox voice id. The actual LLM
--     / TTS call lives in CompanionAIGenerator (wired later); this stays a clean
--     seam so the creator works fully without it.

local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local HttpService = game:GetService("HttpService")

local CompanionCreatorService = {}

-- ── Whitelists (a client can never inject arbitrary values) ────────────
-- Reuse the catalog's valid buff stats so a custom companion's buff is always
-- a real, functioning buff (not a fabricated one).
local ALLOWED_BUFF_STATS = {
	gold = true,
	perfect_window = true,
	extra_drop = true,
	xp = true,
	speed = true,
	style_multiplier = true,
	guest_patience = true,
	combo_retention = true,
	rare_ingredient_rate = true,
	tip_multiplier = true,
	stat_growth_rate = true,
	overcook_protection = true,
	chain_reaction = true,
	gather_vision_range = true,
	rng_variance = true,
	night_shift_surge = true,
	fermentation_perfection = true,
}

-- Curated emoji pool — fits the "zunda spirit" vibe and is safe to render.
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

local MAX_NAME_LEN = 24
local MAX_COMPANIONS = 24

local function sanitizeString(value: any, maxLen: number): string?
	if type(value) ~= "string" then
		return nil
	end
	local v = string.sub(value, 1, maxLen)
	-- strip control chars
	v = (v:gsub("[\r\n\t]", " ")):gsub("%s+", " ")
	return #v > 0 and v or nil
end

local function sanitizeColor(value: any): Color3?
	if typeof(value) == "Color3" then
		return value
	end
	if
		type(value) == "table"
		and type(value.R) == "number"
		and type(value.G) == "number"
		and type(value.B) == "number"
	then
		return Color3.new(math.clamp(value.R, 0, 1), math.clamp(value.G, 0, 1), math.clamp(value.B, 0, 1))
	end
	-- JSON / LLM output often comes as a positional [r, g, b] array.
	if
		type(value) == "table"
		and type(value[1]) == "number"
		and type(value[2]) == "number"
		and type(value[3]) == "number"
	then
		return Color3.new(math.clamp(value[1], 0, 1), math.clamp(value[2], 0, 1), math.clamp(value[3], 0, 1))
	end
	return nil
end

-- Validate + normalize an incoming spec into a safe, complete companion record.
local function normalizeSpec(spec: any): { [string]: any }?
	if type(spec) ~= "table" then
		return nil
	end

	local name = sanitizeString(spec.name, MAX_NAME_LEN) or "Mystery Zundamon"
	local emoji = spec.emoji
	if type(emoji) ~= "string" or not ALLOWED_EMOJI[emoji] then
		emoji = "🌱"
	end
	local displayName = sanitizeString(spec.displayName, MAX_NAME_LEN) or name
	local flavor = sanitizeString(spec.flavor, 200) or "A companion you created."
	local persona = sanitizeString(spec.persona, 500)
		or ("You are " .. name .. ", a companion who walks beside the player.")

	local glow = sanitizeColor(spec.glow) or Color3.fromRGB(180, 200, 255)
	local sparkleColors = {}
	local sc = spec.sparkleColors
	if type(sc) == "table" then
		for _, c in ipairs(sc) do
			local cc = sanitizeColor(c)
			if cc then
				table.insert(sparkleColors, cc)
			end
			if #sparkleColors >= 3 then
				break
			end
		end
	end
	if #sparkleColors == 0 then
		sparkleColors = { glow, glow:Lerp(Color3.new(1, 1, 1), 0.4), glow:Lerp(Color3.new(1, 1, 1), 0.6) }
	end

	local buff = nil
	local b = spec.buff
	if
		type(b) == "table"
		and type(b.stat) == "string"
		and ALLOWED_BUFF_STATS[b.stat]
		and type(b.magnitude) == "number"
	then
		buff = {
			stat = b.stat,
			magnitude = math.clamp(b.magnitude, 0.05, 1.5),
			description = sanitizeString(b.description, 120) or ("+" .. math.floor(b.magnitude * 100) .. "% effect"),
		}
	end

	local signature_recipes = {}
	if type(spec.signature_recipes) == "table" then
		for _, r in ipairs(spec.signature_recipes) do
			if type(r) == "string" and r ~= "" and #signature_recipes < 3 then
				table.insert(signature_recipes, string.sub(r, 1, 60))
			end
		end
	end

	return {
		name = name,
		emoji = emoji,
		displayName = displayName,
		flavor = flavor,
		persona = persona,
		glow = glow,
		sparkleColors = sparkleColors,
		buff = buff,
		signature_recipes = signature_recipes,
		synergy_gold = type(spec.synergy_gold) == "number" and math.clamp(math.floor(spec.synergy_gold), 0, 20) or 5,
	}
end

-- Register a dynamic companion for a player. Returns (true, id) or (false, reason).
function CompanionCreatorService.create(player: Player, spec: any): (boolean, string?)
	if not player then
		return false, "no_player"
	end
	local norm = normalizeSpec(spec)
	if not norm then
		return false, "invalid_spec"
	end

	local data = PlayerDataService.getOrCreate(player)
	if not data then
		return false, "data_unavailable"
	end

	local ok = PlayerDataService.mutate(player, "create_companion", function(d)
		local cc = d.custom_companions or {}
		if next(cc) ~= nil and #cc >= MAX_COMPANIONS then
			return false, "max_companions"
		end
		local id = "cc_" .. HttpService:GenerateGUID(false)
		cc[id] = norm
		d.custom_companions = cc
		d.companions_set = d.companions_set or {}
		d.companions_set[id] = true
		-- Make the newly created companion the active one immediately.
		d.active_companion = id
		return true, id
	end)
	return ok, ok and "created" or "failed"
end

function CompanionCreatorService.list(player: Player): { [string]: any }
	local data = PlayerDataService.get(player)
	if not data then
		return {}
	end
	return data.custom_companions or {}
end

-- AI seam: generate a spec for a player from a theme prompt + optional voice.
-- Without CompanionAIGenerator wired, returns a deterministic themed fallback
-- so the creator UI still works. Wire CompanionAIGenerator.generate for the
-- live LLM + voicevox path.
function CompanionCreatorService.generate(player: Player, theme: string?, voice: string?): { [string]: any }
	local prompt = sanitizeString(theme, 120) or "a cozy forest friend"
	local okGen, gen = pcall(function()
		local AI = require(game:GetService("ServerScriptService").Services.CompanionAIGenerator)
		return AI.generate(prompt, voice)
	end)
	if okGen and gen and type(gen) == "table" then
		return gen
	end
	-- Deterministic fallback so creation always works even with AI offline.
	return normalizeSpec({
		name = "Mystery Zundamon",
		displayName = "Mystery Zundamon",
		flavor = "A quiet little spirit summoned from '" .. prompt .. "'.",
		persona = "You are a gentle companion born from '"
			.. prompt
			.. "'. You keep the player company while they cook.",
		emoji = ALLOWED_EMOJI[math.random(1, #ALLOWED_EMOJI)],
		glow = Color3.fromHSV(math.random(), 0.5, 0.9),
		buff = { stat = "gold", magnitude = 0.05, description = "+5% gold from serving guests" },
	}) or {}
end

return CompanionCreatorService
