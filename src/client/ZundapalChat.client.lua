-- [[LocalScript] ZundapalChat]]
-- Wires LLM free-chat remotes to VNController UI.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")

local player = Players.LocalPlayer

while not _G.ZundaVN do
	task.wait(0.1)
end

local sendEv = RE:WaitForChild("ZundapalChatSend", 30)
local replyEv = RE:WaitForChild("ZundapalChatReply", 30)
local errorEv = RE:WaitForChild("ZundapalChatError", 30)
local statusEv = RE:WaitForChild("ZundapalChatStatus", 30)

if not sendEv or not replyEv then
	warn("[ZundapalChat] Remotes missing — LLM chat disabled")
	return
end

local function burstCompanionSparkles(boostRate: number?, duration: number?)
	local model = workspace:FindFirstChild("ZundaCompanion_" .. player.Name)
	if not model then
		return
	end
	local body = model:FindFirstChild("Body")
	if not body then
		return
	end
	local sparkle = body:FindFirstChild("CompanionSparkles")
	if not sparkle or not sparkle:IsA("ParticleEmitter") then
		return
	end
	local baseRate = sparkle.Rate
	sparkle.Rate = boostRate or 60
	task.delay(duration or 1.2, function()
		if sparkle.Parent then
			sparkle.Rate = baseRate > 0 and baseRate or 10
		end
	end)
end

local function onThinking()
	if _G.ZundaVN.setThinking then
		_G.ZundaVN.setThinking(true)
	end
	burstCompanionSparkles(60, 1.2)
end

_G.ZundaPalChat = {
	submit = function(text: string)
		if typeof(text) ~= "string" or text == "" then
			return
		end
		onThinking()
		sendEv:FireServer(text)
	end,
}

statusEv.OnClientEvent:Connect(function(status)
	if status == "thinking" then
		onThinking()
	end
end)

replyEv.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	local text = payload.text
	if typeof(text) ~= "string" or text == "" then
		return
	end
	if _G.ZundaVN.showCompanionLine then
		_G.ZundaVN.showCompanionLine(text)
	end
end)

errorEv.OnClientEvent:Connect(function(message)
	if typeof(message) ~= "string" then
		return
	end
	if _G.ZundaVN.showCompanionLine then
		_G.ZundaVN.showCompanionLine(message)
	end
end)

print("[ZundapalChat] LLM free chat ready")
