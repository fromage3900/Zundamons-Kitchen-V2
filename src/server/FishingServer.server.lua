--!strict
-- FishingServer is the sole owner of the FishingCast RemoteFunction.
-- Phase 2 fails closed while the authoritative RemoteFunction-to-ECS command adapter is rebuilt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingCast = ReplicatedStorage:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")

FishingCast.OnServerInvoke = function(_player, _action, _payload)
	return { ok = false, reason = "fishing migration unavailable" }
end

print("[FishingServer] Adapter online; fishing is disabled until the authoritative ECS handoff is restored")