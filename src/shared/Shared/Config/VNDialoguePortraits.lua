-- VN portrait system. Portrait decal IDs reference rendered expressions
-- from the Zundamon Live2D model (ZUNKO PJ, https://zunko.jp/).
-- 18 expression presets available — see AI/VN_PERSONA_PLAN.md for mapping.
-- Guest character portraits planned from Kenney Mini Characters (CC0, kenney.nl).
-- See CREDITS.md for full attribution.
local VNDialoguePortraits = {}

-- Maps speaker keys to their portrait decal IDs and expressions
-- Expression variants: default, happy, thinking, surprised, blush, sad
VNDialoguePortraits.portraits = {
	zundamon = {
		full = "rbxassetid://130507312909235",
		face = "rbxassetid://126341676100056",
		body = "rbxassetid://72859793567376",
		expressions = {
			default = "rbxassetid://126341676100056",
			happy = "rbxassetid://126341676100056",
			thinking = "rbxassetid://137063720785842",
			surprised = "rbxassetid://137063720785842",
			blush = "rbxassetid://126341676100056",
			sad = "rbxassetid://137063720785842",
		},
		accent = Color3.fromRGB(140, 255, 160),
	},
	zundapal = {
		full = "rbxassetid://130507312909235",
		face = "rbxassetid://126341676100056",
		body = "rbxassetid://72859793567376",
		expressions = {
			default = "rbxassetid://126341676100056",
			happy = "rbxassetid://126341676100056",
			thinking = "rbxassetid://137063720785842",
			surprised = "rbxassetid://137063720785842",
		},
		accent = Color3.fromRGB(200, 255, 180),
	},
	narrator = {
		full = "",
		face = "",
		expressions = { default = "" },
		accent = Color3.fromRGB(220, 200, 170),
	},
	elder = {
		full = "rbxassetid://130507312909235",
		face = "rbxassetid://126341676100056",
		expressions = { default = "rbxassetid://126341676100056" },
		accent = Color3.fromRGB(220, 180, 130),
	},
	chef = {
		full = "rbxassetid://130507312909235",
		face = "rbxassetid://126341676100056",
		expressions = { default = "rbxassetid://126341676100056" },
		accent = Color3.fromRGB(255, 120, 80),
	},
	ankomon = {
		full = "",
		face = "",
		expressions = { default = "" },
		accent = Color3.fromRGB(200, 80, 80),
	},
	cardamon = {
		full = "",
		face = "",
		expressions = { default = "" },
		accent = Color3.fromRGB(240, 200, 80),
	},
	antimon = {
		full = "",
		face = "",
		expressions = { default = "" },
		accent = Color3.fromRGB(120, 220, 200),
	},
	sakuradamon = {
		full = "",
		face = "",
		expressions = { default = "" },
		accent = Color3.fromRGB(255, 180, 220),
	},
}

function VNDialoguePortraits.getPortrait(speakerKey, expression)
	local entry = VNDialoguePortraits.portraits[speakerKey]
	if not entry then return nil end
	local expr = entry.expressions[expression or "default"] or entry.expressions.default or ""
	return {
		full = entry.full or "",
		face = entry.face or (entry.expressions[expression or "default"] or ""),
		body = entry.body or "",
		accent = entry.accent,
	}
end

function VNDialoguePortraits.hasPortrait(speakerKey)
	local entry = VNDialoguePortraits.portraits[speakerKey]
	if not entry then return false end
	return entry.face ~= nil and entry.face ~= ""
end

return VNDialoguePortraits
