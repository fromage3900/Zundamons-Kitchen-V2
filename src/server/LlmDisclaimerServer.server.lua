-- LlmDisclaimerServer: records player acceptance of AI chat disclosure.

local RS = game:GetService("ReplicatedStorage")
local RF = RS:WaitForChild("RemoteFunctions")

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local function ensureRemote(name: string)
	local ev = RF:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteFunction")
		ev.Name = name
		ev.Parent = RF
	end
	return ev
end

local getStatus = ensureRemote("GetLlmDisclaimerStatus")
local accept = ensureRemote("AcceptLlmDisclaimer")

getStatus.OnServerInvoke = function(player: Player)
	local data = PlayerDataService.get(player) or PlayerDataService.getOrCreate(player)
	return data.llm_disclaimer_accepted == true
end

accept.OnServerInvoke = function(player: Player, accepted: any)
	if accepted ~= true then
		return false
	end
	local data = PlayerDataService.getOrCreate(player)
	data.llm_disclaimer_accepted = true
	return true
end

print("[LlmDisclaimerServer] AI disclosure remotes ready")
