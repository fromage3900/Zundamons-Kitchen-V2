--!strict
-- [[ModuleScript] SocialReferralService]]
-- Server service handling SocialService game invite rewards and Roblox Group membership perks.

local SocialService = game:GetService("SocialService")
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")

local SocialReferralService = {}

local REWARD_TIERS = {
	[1]  = { name = "Pea Pal", gold = 500, gems = 50 },
	[3]  = { name = "Zunda Ambassador", gold = 1500, gems = 150, item = "Zunda Sparkle Apron" },
	[5]  = { name = "Zunda Legend", gold = 3000, gems = 300, item = "Golden Zunda Bow" },
}

local function grantReferralReward(player: Player, reward: { [string]: any })
	print(string.format("[SocialReferralService] Granting %s reward to %s", reward.name or "Tier", player.Name))
	local pd = _G.PlayerData and _G.PlayerData.get(player)
	if pd then
		pd.gold = (pd.gold or 0) + (reward.gold or 0)
		pd.gems = (pd.gems or 0) + (reward.gems or 0)
		if reward.item then
			pd.inventory = pd.inventory or {}
			pd.inventory[reward.item] = (pd.inventory[reward.item] or 0) + 1
		end
	end
end

function SocialReferralService.onPlayerInvited(player: Player, countInvited: number)
	local invitesSent = (player:GetAttribute("InvitesSent") or 0) + countInvited
	player:SetAttribute("InvitesSent", invitesSent)

	for reqCount, reward in pairs(REWARD_TIERS) do
		if invitesSent >= reqCount and not player:GetAttribute("ClaimedReferral_" .. reqCount) then
			player:SetAttribute("ClaimedReferral_" .. reqCount, true)
			grantReferralReward(player, reward)
		end
	end
end

-- Wire Roblox SocialService event
pcall(function()
	SocialService.GameInvitePromptClosed:Connect(function(player, recipientIds)
		if recipientIds and #recipientIds > 0 then
			SocialReferralService.onPlayerInvited(player, #recipientIds)
		end
	end)
end)

print("[SocialReferralService] Initialized ✓")
return SocialReferralService
