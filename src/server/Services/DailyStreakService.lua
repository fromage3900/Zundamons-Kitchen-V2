--!strict
-- [[ModuleScript] DailyStreakService]]
-- 7-Day Login Streak retention engine for Zundamon's Kitchen V2.
-- Escalates player rewards daily to drive D1/D7 player retention.

local Players = game:GetService("Players")

local DailyStreakService = {}

DailyStreakService.rewards = {
	[1] = { day = 1, name = "500 Gold", icon = "💰", gold = 500, gems = 10 },
	[2] = { day = 2, name = "1x Whim Ticket", icon = "🎟️", tickets = 1, gems = 20 },
	[3] = { day = 3, name = "1000 Gold + Spices", icon = "🧂", gold = 1000, gems = 30 },
	[4] = { day = 4, name = "2x Whim Tickets", icon = "🎟️", tickets = 2, gems = 40 },
	[5] = { day = 5, name = "Pastel Mint Bow", icon = "🎀", item = "Zunda Ribbon Bow", gems = 50 },
	[6] = { day = 6, name = "3x Whim Tickets", icon = "🎟️", tickets = 3, gems = 75 },
	[7] = { day = 7, name = "👑 Zunda Royalty Crown", icon = "👑", item = "Royal Gourmet Crown", gems = 200 },
}

local playerStreaks: { [number]: { currentStreak: number, lastClaimTime: number } } = {}

function DailyStreakService.getStreakInfo(player: Player)
	local userId = player.UserId
	if not playerStreaks[userId] then
		playerStreaks[userId] = { currentStreak = 1, lastClaimTime = 0 }
	end
	return playerStreaks[userId]
end

function DailyStreakService.claimDaily(player: Player): { success: boolean, reward: any, nextDay: number }
	local info = DailyStreakService.getStreakInfo(player)
	local dayIndex = math.min(info.currentStreak, 7)
	local reward = DailyStreakService.rewards[dayIndex]

	-- Increment streak for next day
	if info.currentStreak >= 7 then
		info.currentStreak = 1
	else
		info.currentStreak += 1
	end
	info.lastClaimTime = os.time()

	return {
		success = true,
		reward = reward,
		nextDay = info.currentStreak,
	}
end

Players.PlayerRemoving:Connect(function(player)
	playerStreaks[player.UserId] = nil
end)

return DailyStreakService
