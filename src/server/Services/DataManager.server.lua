local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)
local ReplicaService = require(ReplicatedStorage.Packages.ReplicaService)
local DataSchema = require(ReplicatedStorage.Shared.DataSchema)

-- The #1 Secret to Safe Team Collaboration: Mocking DataStores in Studio
local LiveProfileStore = ProfileService.GetProfileStore(
	"PlayerData_V1",
	DataSchema
)

local ProfileStore = LiveProfileStore
if RunService:IsStudio() then
	ProfileStore = LiveProfileStore.Mock
	print("[DataManager] Studio Mode detected. Using Mock DataStore to prevent team lockouts.")
end

-- Setup Replica class for real-time UI streaming
local PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")

local DataManager = {
	Profiles = {}
}

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		
		profile:ListenToRelease(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data was loaded on another server. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) then
			DataManager.Profiles[player] = profile
			
			-- Create Replica to stream state directly to React UI
			local replica = ReplicaService.NewReplica({
				ClassToken = PlayerProfileClassToken,
				Tags = {Player = player},
				Data = profile.Data,
				Replication = player,
			})
			
			-- Tie Replica lifespan to Profile
			profile.Replica = replica
		else
			profile:Release()
		end
	else
		player:Kick("Failed to load data. Please rejoin.")
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if profile ~= nil then
		profile:Release()
		if profile.Replica then
			profile.Replica:Destroy()
		end
	end
end)

return DataManager
