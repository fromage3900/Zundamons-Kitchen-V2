--!strict
-- Grants the FTUE starter-pack gold shown in WelcomeStarterPackGui.client.lua.
-- The claim button previously only closed the panel client-side -- no server
-- grant existed, so "500 Zunda Gold" was purely cosmetic. Server-validated,
-- one-time-per-player via a persisted flag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)

local STARTER_GOLD = 500

local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local claimEvent = RE:FindFirstChild("ClaimStarterGift")
if not claimEvent then
	claimEvent = Instance.new("RemoteEvent")
	claimEvent.Name = "ClaimStarterGift"
	claimEvent.Parent = RE
end

claimEvent.OnServerEvent:Connect(function(player)
	local data = PlayerDataService.getOrCreate(player)
	if data.starter_gift_claimed then
		return
	end
	RewardCore.settle(player, {
		gold = STARTER_GOLD,
		xp = 0,
		reason = "starter_gift",
		popupItem = "Chef Starter Gift",
	}, function(d)
		if d.starter_gift_claimed then
			return false, "already_claimed"
		end
		d.starter_gift_claimed = true
		return true
	end)
end)

print("[StarterGiftServer] Ready — one-time starter gold grant wired")
