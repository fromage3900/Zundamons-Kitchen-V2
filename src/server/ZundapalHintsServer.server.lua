-- ZundapalHintsServer: proactive Zundapal tips wired to RewardCore NotifyAction.

local RS = game:GetService("ReplicatedStorage")
local RE = RS:WaitForChild("RemoteEvents")
local RewardEvents = RS:WaitForChild("RewardEvents")

local Config = require(RS.ConfigurationFiles.ZundapalLLMConfig)
local ContextBuilder = require(RS.ConfigurationFiles.ZundapalContextBuilder)
local ZundapalLLMService = require(script.Parent.Services.ZundapalLLMService)

local NotifyAction = RewardEvents:WaitForChild("NotifyAction")
local notifyPlayer = RE:WaitForChild("NotifyPlayer")

local lastHintAt: { [number]: number } = {}

local function canSendHint(userId: number): boolean
	if not Config.proactiveHintsEnabled then
		return false
	end
	local now = os.clock()
	local last = lastHintAt[userId]
	if last and (now - last) < Config.proactiveHintCooldownSeconds then
		return false
	end
	lastHintAt[userId] = now
	return true
end

local function normalizeAction(action: string, payload: { [string]: any }?): (string, { [string]: any }?)
	if action == "craft" and payload and payload.quality == "perfect" then
		return "perfect", payload
	end
	return action, payload
end

local function shouldReact(action: string): boolean
	return action == "craft" or action == "serve" or action == "gather" or action == "login" or action == "perfect"
end

NotifyAction.Event:Connect(function(player: Player, action: string, payload: any)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end

	local normalizedAction, normalizedPayload = normalizeAction(action, payload)
	if not shouldReact(normalizedAction) then
		return
	end

	ZundapalLLMService.recordGameplayEvent(player.UserId, normalizedAction, normalizedPayload)

	if not canSendHint(player.UserId) then
		return
	end

	local snapshot = ZundapalLLMService.buildSnapshotForPlayer(player)
	local hint = ContextBuilder.suggestProactiveHint(normalizedAction, normalizedPayload, snapshot)
	if not hint then
		return
	end

	notifyPlayer:FireClient(player, "zundapal", "🍡 Zundapal: " .. hint)
end)

print("[ZundapalHintsServer] Proactive hints wired to RewardCore NotifyAction")
