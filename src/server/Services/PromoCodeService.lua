--!strict
-- [[ModuleScript] PromoCodeService]]
-- Authoritative promo code redemption service for Zundamon's Kitchen V2.
-- Supports active codes, gift drops, and duplicate claim prevention.

local Players = game:GetService("Players")

local PromoCodeService = {}

-- Valid Active Codes Pool
PromoCodeService.activeCodes = {
	ZUNDAMOCHI2026 = { gold = 500, gems = 50, item = "10x Fresh Zunda Mochi" },
	SOUPSEASON     = { gold = 1000, gems = 100, item = "5x Wild Mushroom Pack" },
	KAWAIIZUNDA    = { gold = 750, gems = 75, item = "Sakura Chef Apron" },
	NIKKIFASHION   = { gold = 1500, gems = 150, item = "3x Whim Gacha Tickets" },
	HYBRIDECS      = { gold = 2000, gems = 200, item = "5x Whim Gacha Tickets" },
}

-- Per-player claimed codes tracker
local claimedCodes: { [number]: { [string]: boolean } } = {}

function PromoCodeService.redeemCode(player: Player, rawCode: string): { success: boolean, message: string, reward: any? }
	local code = string.upper(string.gsub(rawCode, "%s+", ""))
	local userId = player.UserId

	if not claimedCodes[userId] then
		claimedCodes[userId] = {}
	end

	if claimedCodes[userId][code] then
		return { success = false, message = "Code already redeemed nanoda! 🫛" }
	end

	local rewardData = PromoCodeService.activeCodes[code]
	if not rewardData then
		return { success = false, message = "Invalid or expired promo code nanoda! ❌" }
	end

	-- Mark code as claimed
	claimedCodes[userId][code] = true

	return {
		success = true,
		message = string.format("Code Redeemed! Received +%d Gold, +%d Gems, and %s! ✨", rewardData.gold, rewardData.gems, rewardData.item),
		reward = rewardData,
	}
end

Players.PlayerRemoving:Connect(function(player)
	claimedCodes[player.UserId] = nil
end)

return PromoCodeService
