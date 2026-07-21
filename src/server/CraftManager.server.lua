--!strict
-- Sole RemoteFunction adapter for authoritative cooking session creation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local craftFunction = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("CraftFunction") :: RemoteFunction
local CookingService = require(ServerScriptService.Services.CookingService)

craftFunction.OnServerInvoke = function(player, recipeName, requestedPosition)
	return CookingService.begin(player, recipeName, requestedPosition)
end

local cookingHit = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CookingHit") :: RemoteEvent
cookingHit.OnServerEvent:Connect(function(player, sessionId, noteIndex)
	CookingService.hit(player, sessionId, noteIndex)
end)

print("[CraftManager] Authoritative cooking adapter online")
