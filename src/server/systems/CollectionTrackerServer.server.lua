-- [[Script] CollectionTrackerServer]
-- Server-side wiring for the Collection Tracker panel.
-- Provides the initial snapshot on join and a RemoteFunction for on-demand refresh.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local CollectionConfig = require(ReplicatedStorage.ConfigurationFiles.CollectionConfig)

local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")

local CollectionSnapshot = RE:FindFirstChild("CollectionSnapshot")
if not CollectionSnapshot then
	CollectionSnapshot = Instance.new("RemoteEvent")
	CollectionSnapshot.Name = "CollectionSnapshot"
	CollectionSnapshot.Parent = RE
end

local GetCollectionSnapshot = RF:FindFirstChild("GetCollectionSnapshot")
if not GetCollectionSnapshot then
	GetCollectionSnapshot = Instance.new("RemoteFunction")
	GetCollectionSnapshot.Name = "GetCollectionSnapshot"
	GetCollectionSnapshot.Parent = RF
end

local function buildSnapshot(player: Player): { [string]: any }
	local counts = PlayerDataService.getCollectionSnapshot(player)
	local totals = CollectionConfig.getTotals()
	return {
		counts = counts,
		totals = totals,
	}
end

GetCollectionSnapshot.OnServerInvoke = function(player: Player)
	return buildSnapshot(player)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait()
	task.wait(1)
	if player:IsDescendantOf(Players) then
		CollectionSnapshot:FireClient(player, buildSnapshot(player))
	end
end)

print("[CollectionTrackerServer] Ready")
