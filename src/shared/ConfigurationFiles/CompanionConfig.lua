-- [[ModuleScript] CompanionConfig]]
-- Canonical companion catalog for shop, buffs, follow mesh, and LLM context.

local CompanionConfig = {}

-- Default Studio mesh path (sphere fallback if missing)
CompanionConfig.defaultMeshPath = {
	"GameplayLoopArea",
	"GatheringNodes",
	"Loop_AppleTree_1",
	"mesh",
	"zundapal",
}

-- Speakers that count toward npc_chat quests when VN dialogue plays
CompanionConfig.npcSpeakers = {
	elder = "Elder",
	ruins = "AncientRuins",
	chef = "Head Chef",
}

CompanionConfig.companions = {
	zundamon = {
		emoji = "🍡",
		glow = Color3.fromRGB(140, 255, 160),
		glowRange = 16,
		sparkleColors = {
			Color3.fromRGB(180, 255, 180),
			Color3.fromRGB(255, 220, 100),
			Color3.fromRGB(200, 240, 255),
		},
		buff = nil,
		free = true,
		displayName = "Zundamon",
		flavor = "The original. A loyal pea spirit.",
		llmPersona = "You appear as Zundamon's pea-spirit form beside the player.",
	},
	zundacat = {
		emoji = "🐱",
		glow = Color3.fromRGB(255, 200, 140),
		glowRange = 14,
		sparkleColors = {
			Color3.fromRGB(255, 210, 180),
			Color3.fromRGB(255, 180, 120),
			Color3.fromRGB(255, 240, 200),
		},
		buff = nil,
		free = true,
		displayName = "Zundacat",
		flavor = "A curious cat-shaped friend.",
		llmPersona = "You are in your playful cat companion form.",
	},
	zundabunny = {
		emoji = "🐰",
		glow = Color3.fromRGB(220, 180, 255),
		glowRange = 14,
		sparkleColors = {
			Color3.fromRGB(240, 210, 255),
			Color3.fromRGB(200, 160, 255),
			Color3.fromRGB(255, 220, 255),
		},
		buff = nil,
		free = true,
		displayName = "Zundabunny",
		flavor = "Hops alongside with twinkling ears.",
		llmPersona = "You are in your bunny companion form with extra cheer.",
	},
	tantanmon = {
		emoji = "🌶️",
		glow = Color3.fromRGB(255, 100, 60),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(255, 140, 100),
			Color3.fromRGB(255, 60, 40),
			Color3.fromRGB(255, 200, 100),
		},
		buff = nil,
		free = true,
		displayName = "Tantanmon",
		flavor = "Spicy little firework.",
		llmPersona = "You are in your spicy tan companion form.",
	},
	ankomon = {
		emoji = "🫘",
		glow = Color3.fromRGB(220, 90, 90),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(240, 120, 120),
			Color3.fromRGB(220, 80, 80),
			Color3.fromRGB(255, 200, 200),
		},
		buff = { stat = "gold", magnitude = 0.15, description = "+15% gold from serving guests" },
		free = false,
		price = 500,
		displayName = "Ankomon",
		flavor = "A red bean spirit. Sweetens every payday.",
		llmPersona = "Your Ankomon form grants the player bonus gold when serving guests.",
	},
	cardamon = {
		emoji = "🍋",
		glow = Color3.fromRGB(240, 200, 80),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(255, 230, 140),
			Color3.fromRGB(240, 200, 80),
			Color3.fromRGB(255, 250, 200),
		},
		buff = { stat = "perfect_window", magnitude = 0.30, description = "+30% wider perfect cooking window" },
		free = false,
		price = 500,
		displayName = "Cardamon",
		flavor = "A cardamom seedling. Steadies your hands.",
		llmPersona = "Your Cardamon form helps the player land perfect cooks.",
	},
	antimon = {
		emoji = "🌿",
		glow = Color3.fromRGB(120, 220, 200),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(160, 240, 220),
			Color3.fromRGB(120, 220, 200),
			Color3.fromRGB(220, 255, 250),
		},
		buff = { stat = "extra_drop", magnitude = 0.20, description = "+20% chance of extra drop on gather" },
		free = false,
		price = 500,
		displayName = "Antimon",
		flavor = "A minty wisp. Whispers where to dig.",
		llmPersona = "Your Antimon form helps the player find extra gather drops.",
	},
	sakuradamon = {
		emoji = "🌸",
		glow = Color3.fromRGB(255, 180, 220),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(255, 200, 230),
			Color3.fromRGB(255, 160, 210),
			Color3.fromRGB(255, 230, 250),
		},
		buff = { stat = "xp", magnitude = 0.25, description = "+25% XP from crafting & serving" },
		free = false,
		price = 500,
		displayName = "Sakuradamon",
		flavor = "A blossom spirit. Carries good lessons on the breeze.",
		llmPersona = "Your Sakuradamon form grants bonus chef XP.",
	},
}

function CompanionConfig.getCompanion(compType: string)
	return CompanionConfig.companions[compType] or CompanionConfig.companions.zundamon
end

function CompanionConfig.resolveMeshPath(compType: string): { string }
	local def = CompanionConfig.getCompanion(compType)
	if def.meshPath then
		return def.meshPath
	end
	return CompanionConfig.defaultMeshPath
end

-- Backward compatibility for scripts still reading shared catalog
shared.ZundaCompanionCatalog = CompanionConfig.companions

return CompanionConfig
