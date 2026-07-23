--!strict
-- [[ModuleScript] CompanionConfig]]
-- Canonical companion catalog for shop, buffs, follow mesh, and LLM context.

local CompanionConfig = {}

-- Speakers that count toward npc_chat quests when VN dialogue plays
CompanionConfig.npcSpeakers = {
	elder = "Elder",
	ruins = "AncientRuins",
	chef = "Head Chef",
}

CompanionConfig.companions = {
	zundapal = {
		emoji = "🫛",
		glow = Color3.fromRGB(180, 200, 255),
		glowRange = 18,
		sparkleColors = {
			Color3.fromRGB(200, 220, 255),
			Color3.fromRGB(180, 180, 255),
			Color3.fromRGB(230, 200, 255),
		},
		buff = nil,
		free = true,
		price = 0,
		displayName = "Zundapal",
		flavor = "Your Zundamon spirit companion.",
		llmPersona = "You appear as the Zundamon mesh companion.",
	},
	dog = {
		emoji = "🐕",
		glow = Color3.fromRGB(255, 200, 150),
		glowRange = 16,
		sparkleColors = {
			Color3.fromRGB(255, 220, 180),
			Color3.fromRGB(255, 190, 130),
			Color3.fromRGB(255, 240, 200),
		},
		buff = nil,
		free = true,
		price = 0,
		displayName = "Dog",
		flavor = "A faithful furry friend.",
		llmPersona = "You are a loyal dog companion beside the player.",
	},
	parrot = {
		emoji = "🦜",
		glow = Color3.fromRGB(255, 180, 100),
		glowRange = 14,
		sparkleColors = {
			Color3.fromRGB(255, 220, 150),
			Color3.fromRGB(255, 170, 80),
			Color3.fromRGB(255, 240, 200),
		},
		buff = nil,
		free = true,
		price = 0,
		displayName = "Parrot",
		flavor = "A colourful chatterbox.",
		llmPersona = "You are a chatty parrot companion beside the player.",
	},
	cat = {
		emoji = "🐱",
		glow = Color3.fromRGB(255, 200, 200),
		glowRange = 14,
		sparkleColors = {
			Color3.fromRGB(255, 220, 220),
			Color3.fromRGB(255, 180, 180),
			Color3.fromRGB(255, 240, 230),
		},
		buff = nil,
		free = true,
		price = 0,
		displayName = "Cat",
		flavor = "A purring little menace.",
		llmPersona = "You are a cat companion beside the player.",
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
		free = true,
		price = 0,
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
		price = 1000,
		robux = 1000,
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
		price = 1000,
		robux = 1000,
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
		price = 1000,
		robux = 1000,
		displayName = "Sakuradamon",
		flavor = "A blossom spirit. Carries good lessons on the breeze.",
		llmPersona = "Your Sakuradamon form grants bonus chef XP.",
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
		buff = { stat = "speed", magnitude = 0.20, description = "+20% move speed & cook speed" },
		free = false,
		price = 1000,
		robux = 1000,
		displayName = "Tantanmon",
		flavor = "Spicy little firework.",
		llmPersona = "You are in your spicy tan companion form.",
	},
}

function CompanionConfig.getCompanion(compType: string)
	return CompanionConfig.companions[compType] or CompanionConfig.companions.zundapal
end

shared.ZundaCompanionCatalog = CompanionConfig.companions
return CompanionConfig
