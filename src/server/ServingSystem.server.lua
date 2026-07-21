--!strict
-- Sole network adapter for guest serving. Client quality is intentionally not
-- accepted; ServingService selects the server-owned dish quality.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local serveGuest = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("ServeGuest") :: RemoteFunction
local ServingService = require(ServerScriptService.Services.ServingService)

serveGuest.OnServerInvoke = function(player, guest, dishName)
	return ServingService.serve(player, guest, dishName)
end

print("[ServingSystem] Authoritative serving adapter online")
