--!strict
-- Sole network adapter for fishing. It validates the action shape and delegates
-- to the authoritative service; no ECS system owns remotes directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FishingCast = ReplicatedStorage:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")
local FishingService = require(ServerScriptService.Services.FishingService)

FishingCast.OnServerInvoke = function(player, action, payload)
	if type(action) ~= "string" then
		return { ok = false, reason = "invalid_action" }
	end
	if action == "begin" then
		return FishingService.begin(player)
	end
	if action == "input" then
		return FishingService.input(player, payload)
	end
	if action == "cancel" then
		return FishingService.cancel(player, payload)
	end
	return { ok = false, reason = "unsupported_action" }
end

print("[FishingServer] Authoritative fishing adapter online")
