-- ZundapalChatServer: validates client chat and proxies to ZundapalLLMService.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local ZundapalLLMService = require(script.Parent.Services.ZundapalLLMService)
local CompanionStats = require(script.Parent.Services.CompanionStats)

local RE = RS:WaitForChild("RemoteEvents")

local function ensureEvent(name: string)
	local ev = RE:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = RE
	end
	return ev
end

local sendEv = ensureEvent("ZundapalChatSend")
local replyEv = ensureEvent("ZundapalChatReply")
local errorEv = ensureEvent("ZundapalChatError")
local statusEv = ensureEvent("ZundapalChatStatus")

local function bumpCompanionChats(player: Player)
	CompanionStats.recordCompanionChat(player)
end

sendEv.OnServerEvent:Connect(function(player: Player, message: any)
	if typeof(message) ~= "string" then
		errorEv:FireClient(player, "Invalid message.")
		return
	end

	statusEv:FireClient(player, "thinking")

	task.spawn(function()
		local ok, text, reason = ZundapalLLMService.chat(player, message)
		statusEv:FireClient(player, "ready")

		if ok then
			bumpCompanionChats(player)
			replyEv:FireClient(player, {
				text = text,
				speaker = "zundapal",
			})
		else
			if reason == "cooldown" or reason == "too_long" or reason == "empty" or reason == "filtered" then
				errorEv:FireClient(player, text)
			else
				replyEv:FireClient(player, {
					text = text,
					speaker = "zundapal",
					fallback = true,
				})
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	ZundapalLLMService.clearSession(player.UserId)
end)

print("[ZundapalChatServer] Ready — LLM free chat with live PlayerData/Quest context")
