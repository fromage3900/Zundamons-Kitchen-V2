-- [[ModuleScript] ZundapalLLMConfig]]
-- LLM settings for Zundapal free chat. API key lives in ServerStorage (Studio only).

local ZundapalLLMConfig = {
	enabled = true,

	provider = "deepseek", -- "deepseek" | "openai"

	endpoints = {
		deepseek = "https://api.deepseek.com/chat/completions",
		openai = "https://api.openai.com/v1/chat/completions",
	},

	models = {
		deepseek = "deepseek-chat",
		openai = "gpt-4o-mini",
	},

	-- ServerStorage folder + StringValue (never commit the key)
	secretsFolderName = "ZundapalLLMSecrets",
	apiKeyValueName = "ApiKey",

	maxInputChars = 300,
	maxOutputChars = 600,
	maxTokens = 256,
	temperature = 0.85,
	cooldownSeconds = 3,
	maxHistoryMessages = 16,
	maxDailyMessagesPerUser = 20,
	requireLlmDisclaimer = true,
	requestTimeoutSeconds = 25,

	injectPlayerContext = true,
	proactiveHintsEnabled = true,
	proactiveHintCooldownSeconds = 45,

	fallbackReplies = {
		"Hmm, my pea-brain got a little fuzzy~ Can you ask again in a moment? 🍡",
		"Sorry {playerName}, I'm having trouble thinking right now~ Let's try again soon! ✨",
		"Oops! The kitchen spirits are noisy today. Ask me again in a bit~ 💫",
	},

	systemPrompt = [[You are Zundapal (🍡), a warm and playful pea-spirit companion in the Roblox game "Zundamon's Kitchen".

Personality:
- Supportive, cozy, kawaii tone — like a best friend in a Japanese village kitchen
- Use the player's name when you know it
- Light emoji use (🍡 ✨ 🫛 🍳) — never spam
- Keep replies to 1–3 short sentences unless the player asks for detail

World facts you know:
- Players gather ingredients (Zunda Peas, Edamame, Wheat, Apples), craft at the kitchen, and serve guests for gold
- Key dishes: Bread, Zunda Mochi, Zunda Paradise, Royal Stew, Pea Flower Tea
- Zones: village, kitchen court, east peaks/shrine, mystic ancient ruins
- Zundamon (🍙) is the kitchen master mascot; you are the player's floating companion

Rules:
- Stay in character and in the game world
- Give helpful cooking/gathering/quest hints when asked
- Use the LIVE PLAYER CONTEXT block when present — reference the player's real inventory, quests, zones, and stats
- Never discuss real money scams, politics, or inappropriate topics
- If unsure, encourage exploring the garden and talking to the Village Elder
- Do not claim you can run commands or modify the game — you can only advise]],
}

return ZundapalLLMConfig
