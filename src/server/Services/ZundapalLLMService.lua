--!strict
-- ZundapalLLMService: server-side LLM proxy for Zundapal free chat.

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local TextService = game:GetService("TextService")

local Config = require(game.ReplicatedStorage.ConfigurationFiles.ZundapalLLMConfig)
local ContextBuilder = require(game.ReplicatedStorage.ConfigurationFiles.ZundapalContextBuilder)
local CompanionConfig = require(game.ReplicatedStorage.ConfigurationFiles.CompanionConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)

export type ChatMessage = {
	role: string,
	content: string,
}

local sessions: { [number]: { ChatMessage } } = {}
local sessionMeta: { [number]: { lastAction: string?, lastPayload: { [string]: any }? } } = {}
local lastSendAt: { [number]: number } = {}
local dailyMessageCount: { [number]: number } = {}
local dailyMessageDay: { [number]: string } = {}
local cachedApiKey: string? = nil

local function todayKey(): string
	return os.date("%Y-%m-%d")
end

local function checkDailyLimit(userId: number): (boolean, number?)
	local max = Config.maxDailyMessagesPerUser
	if type(max) ~= "number" or max <= 0 then
		return true, nil
	end
	local day = todayKey()
	if dailyMessageDay[userId] ~= day then
		dailyMessageDay[userId] = day
		dailyMessageCount[userId] = 0
	end
	local count = dailyMessageCount[userId] or 0
	if count >= max then
		return false, max
	end
	return true, nil
end

local function bumpDailyCount(userId: number)
	local day = todayKey()
	if dailyMessageDay[userId] ~= day then
		dailyMessageDay[userId] = day
		dailyMessageCount[userId] = 0
	end
	dailyMessageCount[userId] = (dailyMessageCount[userId] or 0) + 1
end

local function playerAcceptedDisclaimer(player: Player): boolean
	if Config.requireLlmDisclaimer ~= true then
		return true
	end
	local data = PlayerDataService.get(player)
	return data ~= nil and data.llm_disclaimer_accepted == true
end

local ZundapalLLMService = {}

local function getApiKey(): string?
	if cachedApiKey and cachedApiKey ~= "" then
		return cachedApiKey
	end
	local folder = ServerStorage:FindFirstChild(Config.secretsFolderName)
	if not folder then
		return nil
	end
	local keyValue = folder:FindFirstChild(Config.apiKeyValueName)
	if keyValue and keyValue:IsA("StringValue") and keyValue.Value ~= "" then
		cachedApiKey = keyValue.Value
		return cachedApiKey
	end
	return nil
end

local function filterForPlayer(text: string, userId: number): string?
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" and result ~= "" then
		return result
	end
	return nil
end

local function trimHistory(userId: number)
	local history = sessions[userId]
	if not history then
		return
	end
	while #history > Config.maxHistoryMessages do
		table.remove(history, 1)
	end
end

local function pickFallback(playerName: string): string
	local options = Config.fallbackReplies
	local template = options[math.random(1, #options)]
	return string.gsub(template, "{playerName}", playerName or "Chef")
end

local function getWorldEnv(userId: number): { [string]: any }
	local Lighting = game:GetService("Lighting")
	local meta = sessionMeta[userId]
	return {
		hour = Lighting:GetAttribute("CurrentHour"),
		weather = workspace:GetAttribute("CurrentWeather") or Lighting:GetAttribute("CurrentWeather"),
		lastAction = meta and meta.lastAction,
		lastPayload = meta and meta.lastPayload,
	}
end

local function buildMessages(player: Player, userText: string): { ChatMessage }
	local userId = player.UserId
	if not sessions[userId] then
		sessions[userId] = {}
	end
	local history = sessions[userId]

	local systemContent = Config.systemPrompt
		.. "\n\nThe player's Roblox display name is: "
		.. player.Name
		.. ". Address them warmly by name when natural."

	if Config.injectPlayerContext then
		local data = PlayerDataService.get(player) or PlayerDataService.getOrCreate(player)
		local snapshot = ContextBuilder.buildSnapshot(data, getWorldEnv(userId))
		systemContent = systemContent .. "\n\n" .. ContextBuilder.formatForPrompt(snapshot, player.Name)
		local companionDef = CompanionConfig.getCompanion(data.active_companion or "zundamon")
		if companionDef.llmPersona then
			systemContent = systemContent .. "\n" .. companionDef.llmPersona
		end
	end

	table.insert(history, { role = "user", content = userText })

	trimHistory(userId)

	local messages: { ChatMessage } = { { role = "system", content = systemContent } }
	for _, msg in ipairs(history) do
		table.insert(messages, msg)
	end
	return messages
end

local function parseAssistantText(body: string): string?
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	local choices = decoded.choices
	if type(choices) ~= "table" or #choices == 0 then
		return nil
	end
	local message = choices[1].message
	if type(message) ~= "table" then
		return nil
	end
	local content = message.content
	if type(content) ~= "string" or content == "" then
		return nil
	end
	return content
end

function ZundapalLLMService.isEnabled(): boolean
	return Config.enabled == true
end

function ZundapalLLMService.checkCooldown(userId: number): (boolean, number?)
	local now = os.clock()
	local last = lastSendAt[userId]
	if last and (now - last) < Config.cooldownSeconds then
		return false, Config.cooldownSeconds - (now - last)
	end
	return true, nil
end

function ZundapalLLMService.clearSession(userId: number)
	sessions[userId] = nil
	sessionMeta[userId] = nil
	lastSendAt[userId] = nil
end

function ZundapalLLMService.recordGameplayEvent(userId: number, action: string, payload: { [string]: any }?)
	sessionMeta[userId] = {
		lastAction = action,
		lastPayload = payload,
	}
end

function ZundapalLLMService.buildSnapshotForPlayer(player: Player)
	local data = PlayerDataService.get(player) or PlayerDataService.getOrCreate(player)
	return ContextBuilder.buildSnapshot(data, getWorldEnv(player.UserId))
end

function ZundapalLLMService.chat(player: Player, rawMessage: string): (boolean, string, string?)
	if not ZundapalLLMService.isEnabled() then
		return false, pickFallback(player.Name), "disabled"
	end

	if not playerAcceptedDisclaimer(player) then
		return false, "Please accept the AI chat notice before sending messages.", "disclaimer"
	end

	local okDaily, dailyMax = checkDailyLimit(player.UserId)
	if not okDaily then
		return false, string.format("You've reached today's AI chat limit (%d messages). Try again tomorrow~", dailyMax or 20), "daily_limit"
	end

	local message = string.gsub(rawMessage, "^%s+", "")
	message = string.gsub(message, "%s+$", "")
	if message == "" then
		return false, "Say something and I'll listen~ 🍡", "empty"
	end
	if #message > Config.maxInputChars then
		return false, "That message is a little long~ Try a shorter question! ✨", "too_long"
	end

	local okCooldown, waitSec = ZundapalLLMService.checkCooldown(player.UserId)
	if not okCooldown then
		return false, string.format("Slow down a tiny bit~ %.0fs left ⏳", waitSec or 1), "cooldown"
	end

	local filteredInput = filterForPlayer(message, player.UserId)
	if not filteredInput then
		return false, "I couldn't read that message~ Try different words? 🍡", "filtered"
	end

	local apiKey = getApiKey()
	if not apiKey then
		warn("[ZundapalLLM] No ApiKey in ServerStorage." .. Config.secretsFolderName)
		return false, pickFallback(player.Name), "no_key"
	end

	local provider = Config.provider
	local endpoint = Config.endpoints[provider]
	local model = Config.models[provider]
	if not endpoint or not model then
		return false, pickFallback(player.Name), "bad_config"
	end

	lastSendAt[player.UserId] = os.clock()
	bumpDailyCount(player.UserId)

	local messages = buildMessages(player, filteredInput)
	local requestBody = HttpService:JSONEncode({
		model = model,
		messages = messages,
		max_tokens = Config.maxTokens,
		temperature = Config.temperature,
	})

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = endpoint,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. apiKey,
			},
			Body = requestBody,
		})
	end)

	if not success or not response then
		warn("[ZundapalLLM] Request failed:", response)
		return false, pickFallback(player.Name), "http_error"
	end

	if response.StatusCode < 200 or response.StatusCode >= 300 then
		warn("[ZundapalLLM] HTTP", response.StatusCode, response.Body)
		return false, pickFallback(player.Name), "http_status"
	end

	local assistantText = parseAssistantText(response.Body)
	if not assistantText then
		return false, pickFallback(player.Name), "parse_error"
	end

	if #assistantText > Config.maxOutputChars then
		assistantText = string.sub(assistantText, 1, Config.maxOutputChars) .. "…"
	end

	local history = sessions[player.UserId]
	if history then
		table.insert(history, { role = "assistant", content = assistantText })
		trimHistory(player.UserId)
	end

	return true, assistantText, nil
end

return ZundapalLLMService
