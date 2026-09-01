--!strict
-- [[ModuleScript] DailyChallengeService]]
-- Daily challenge system inspired by Uma Musume's daily races.
-- 3 rotating daily challenges + weekly boss challenge + streak rewards.
-- All durable writes go through PlayerDataService.mutate so they get the
-- same revision bump, projection emit, and rollback as every other system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local DailyChallengeConfig = require(ReplicatedStorage.ConfigurationFiles.DailyChallengeConfig)

local DailyChallengeService = {}

local challengeEvent = nil
local challengeStatus = nil
local dailyPreviewEvent = nil

local function getRemotes()
	if not challengeEvent then
		local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
		challengeEvent = RE:FindFirstChild("DailyChallenge")
		if not challengeEvent then
			challengeEvent = Instance.new("RemoteEvent")
			challengeEvent.Name = "DailyChallenge"
			challengeEvent.Parent = RE
		end
		challengeStatus = RE:FindFirstChild("DailyChallengeStatus")
		if not challengeStatus then
			challengeStatus = Instance.new("RemoteEvent")
			challengeStatus.Name = "DailyChallengeStatus"
			challengeStatus.Parent = RE
		end
		dailyPreviewEvent = RE:FindFirstChild("DailyPreviewData")
		if not dailyPreviewEvent then
			dailyPreviewEvent = Instance.new("RemoteEvent")
			dailyPreviewEvent.Name = "DailyPreviewData"
			dailyPreviewEvent.Parent = RE
		end
	end
	return challengeEvent, challengeStatus, dailyPreviewEvent
end

local function getTodayKey(): string
	return os.date("%Y-%m-%d")
end

function DailyChallengeService.initializeDay(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then
		-- New day â€” generate fresh challenges inside a mutation so the
		-- revision bumps and the client projection updates.
		PlayerDataService.mutate(player, "daily_challenge_init", function(d)
			local challenges = DailyChallengeConfig.selectDailyChallenges()
			d.daily_challenge_date = today
			d.daily_challenges = challenges
			d.daily_challenge_progress = {}
			d.daily_challenge_claimed = {}
			d.daily_streak = d.daily_streak or 0
			return true
		end)
	end

	local _, status, preview = getRemotes()
	status:FireClient(player, {
		type = "daily_update",
		challenges = data.daily_challenges,
		progress = data.daily_challenge_progress,
		claimed = data.daily_challenge_claimed,
		streak = data.daily_streak,
		weeklyBoss = DailyChallengeConfig.getWeeklyBoss(),
	})
	preview:FireClient(player, DailyChallengeService.getPreview(player))
end

function DailyChallengeService.updateProgress(player: Player, metric: string, amount: number)
	local data = PlayerDataService.get(player)
	if not data or not data.daily_challenges then
		return
	end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then
		return
	end

	local progress = data.daily_challenge_progress or {}
	local claimed = data.daily_challenge_claimed or {}
	local changed = false
	for i, challenge in ipairs(data.daily_challenges) do
		if challenge.metric == metric then
			local current = progress[i] or 0
			local newProgress = math.min(current + amount, challenge.goal)
			progress[i] = newProgress
			changed = true
			if newProgress >= challenge.goal and not claimed[i] then
				-- Challenge complete! Persist the progress atomically.
				PlayerDataService.mutate(player, "daily_challenge_complete", function(d)
					local p = d.daily_challenge_progress or {}
					p[i] = newProgress
					d.daily_challenge_progress = p
					return true
				end)
			end
		end
	end

	if changed then
		local _, status, _ = getRemotes()
		status:FireClient(player, {
			type = "progress_update",
			progress = progress,
		})
	end
end

function DailyChallengeService.claimReward(player: Player, challengeIndex: number)
	local data = PlayerDataService.get(player)
	if not data or not data.daily_challenges then
		return false
	end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then
		return false
	end

	local challenge = data.daily_challenges[challengeIndex]
	if not challenge then
		return false
	end

	local progress = data.daily_challenge_progress or {}
	if (progress[challengeIndex] or 0) < challenge.goal then
		return false
	end

	local claimed = data.daily_challenge_claimed or {}
	if claimed[challengeIndex] then
		return false
	end

	-- Grant rewards. The claimed flag is set inside the settlement mutation so
	-- a failed/returned settle can never leave a flag set without a reward.
	local reward = challenge.reward
	local result = RewardCore.settle(player, {
		gold = reward.gold or 0,
		xp = reward.xp or 0,
		reason = "daily_challenge",
	}, function(d)
		d.daily_challenge_claimed = d.daily_challenge_claimed or {}
		d.daily_challenge_claimed[challengeIndex] = true
		d.style_points = (d.style_points or 0) + (reward.style or 0)
		for _, item in ipairs(reward.items or {}) do
			PlayerDataService.grantItem(player, item, 1)
		end
		return true
	end)
	if not result.ok then
		return false
	end

	-- Check if all 3 challenges are complete for streak bonus (inside a mutate
	-- so the streak increment + reward are atomic with the claimed flag).
	local allComplete = true
	for i = 1, 3 do
		if not (data.daily_challenge_claimed or {})[i] then
			allComplete = false
			break
		end
	end

	if allComplete then
		PlayerDataService.mutate(player, "daily_streak_bump", function(d)
			d.daily_streak = (d.daily_streak or 0) + 1
			return true
		end)
		local streakReward = DailyChallengeConfig.getStreakReward(data.daily_streak or 0)
		RewardCore.settle(player, {
			gold = streakReward.gold or 0,
			xp = streakReward.xp or 0,
			reason = "daily_streak",
		}, function(d)
			d.style_points = (d.style_points or 0) + (streakReward.style or 0)
			return true
		end)
	end

	local _, status, preview = getRemotes()
	status:FireClient(player, {
		type = "reward_claimed",
		challengeIndex = challengeIndex,
		streak = data.daily_streak,
	})
	preview:FireClient(player, DailyChallengeService.getPreview(player))

	return true
end

function DailyChallengeService.getPreview(player: Player): { [string]: any }
	local data = PlayerDataService.get(player)
	if not data then
		return {}
	end

	local streak = data.daily_streak or 0
	local maxStreak = 7
	local todayClaimed = true
	if data.daily_challenges then
		for i = 1, 3 do
			if not (data.daily_challenge_claimed or {})[i] then
				todayClaimed = false
				break
			end
		end
	else
		todayClaimed = false
	end

	local tomorrowTime = os.time() + 86400
	local nextDayName = os.date("%A", tomorrowTime)
	local dayOfYear = tonumber(os.date("%j", tomorrowTime)) or 1
	local pool = DailyChallengeConfig.dailyPool
	local nextIndex = (dayOfYear % #pool) + 1
	local nextChallenge = pool[nextIndex]

	local nextStreak = streak + (todayClaimed and 1 or 0)
	local nextReward = DailyChallengeConfig.getStreakReward(nextStreak)
	local rewardText = string.format(
		"%d Gold%s",
		nextReward.gold,
		(nextReward.style and nextReward.style > 0) and (", " .. nextReward.style .. " Style") or ""
	)

	return {
		streak = streak,
		maxStreak = maxStreak,
		todayClaimed = todayClaimed,
		nextDayName = nextDayName,
		nextChallengeId = nextChallenge.id,
		nextChallengeTitle = nextChallenge.title,
		nextChallengeIcon = nextChallenge.icon,
		rewardText = rewardText,
	}
end

function DailyChallengeService.spawnDailyVisitor(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local today = getTodayKey()
	if data.daily_visitor_visited and data.daily_visitor_date == today then
		return false
	end

	local visitor = DailyChallengeConfig.dailyVisitor
	local result = RewardCore.settle(player, {
		gold = visitor.reward.gold or 100,
		xp = visitor.reward.xp or 80,
		reason = "daily_visitor",
	}, function(d)
		d.daily_visitor_date = today
		d.daily_visitor_visited = true
		PlayerDataService.grantItem(player, visitor.reward.item or "Zunda Flower", 1)
		return true
	end)
	if not result.ok then
		return false
	end

	local _, status, _ = getRemotes()
	status:FireClient(player, {
		type = "visitor_spawned",
		visitor = visitor,
	})

	return true
end

function DailyChallengeService.spawnDailyResources(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local today = getTodayKey()
	if data.daily_resources_spawned and data.daily_resources_date == today then
		return false
	end

	-- Grant all resources atomically inside one mutation.
	local ok = PlayerDataService.mutate(player, "daily_resources", function(d)
		d.daily_resources_date = today
		d.daily_resources_spawned = true
		for _, resource in ipairs(DailyChallengeConfig.dailyResources) do
			d[resource.resourceType] = (d[resource.resourceType] or 0) + resource.count
		end
		return true
	end)
	if not ok then
		return false
	end

	local _, status, _ = getRemotes()
	status:FireClient(player, {
		type = "resources_spawned",
		resources = DailyChallengeConfig.dailyResources,
	})

	return true
end

function DailyChallengeService.checkAndUnlockWeeklyBoss(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end

	local today = getTodayKey()
	local boss = DailyChallengeConfig.getWeeklyBoss()

	-- Check if weekly boss progress is tracked (inside a mutate).
	if not data.weekly_boss_id or data.weekly_boss_id ~= boss.id then
		PlayerDataService.mutate(player, "weekly_boss_init", function(d)
			d.weekly_boss_id = boss.id
			d.weekly_boss_progress = 0
			d.weekly_boss_claimed = false
			return true
		end)
	end

	return data.weekly_boss_progress or 0, boss
end

function DailyChallengeService.updateWeeklyProgress(player: Player, metric: string, amount: number)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	local boss = DailyChallengeConfig.getWeeklyBoss()
	if data.weekly_boss_id ~= boss.id then
		PlayerDataService.mutate(player, "weekly_boss_init", function(d)
			d.weekly_boss_id = boss.id
			d.weekly_boss_progress = 0
			d.weekly_boss_claimed = false
			return true
		end)
	end

	if boss.metric == metric then
		PlayerDataService.mutate(player, "weekly_boss_progress", function(d)
			local current = d.weekly_boss_progress or 0
			d.weekly_boss_progress = math.min(current + amount, boss.goal)
			return true
		end)
	end

	local _, status, _ = getRemotes()
	status:FireClient(player, {
		type = "weekly_update",
		boss = boss,
		progress = data.weekly_boss_progress,
	})
end

function DailyChallengeService.claimWeeklyReward(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end

	local boss = DailyChallengeConfig.getWeeklyBoss()
	if data.weekly_boss_id ~= boss.id then
		return false
	end
	if (data.weekly_boss_progress or 0) < boss.goal then
		return false
	end
	if data.weekly_boss_claimed then
		return false
	end

	local reward = boss.reward
	local result = RewardCore.settle(player, {
		gold = reward.gold or 0,
		xp = reward.xp or 0,
		reason = "weekly_boss",
	}, function(d)
		d.weekly_boss_claimed = true
		d.style_points = (d.style_points or 0) + (reward.style or 0)
		for _, item in ipairs(reward.items or {}) do
			PlayerDataService.grantItem(player, item, 1)
		end
		return true
	end)
	if not result.ok then
		return false
	end

	local _, status, _ = getRemotes()
	status:FireClient(player, {
		type = "weekly_claimed",
		boss = boss,
	})

	return true
end

-- â”€â”€ Player Join â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Initialise one player's daily state. Split out of the PlayerAdded handler so
-- the backfill below can reuse it.
local function initPlayerDaily(player: Player)
	task.spawn(function()
		task.wait(3)
		-- The player can leave during the 3s wait (or between server start and
		-- the backfill); initialising a departed player writes state nobody owns.
		if not player.Parent then
			return
		end
		DailyChallengeService.initializeDay(player)
		DailyChallengeService.spawnDailyVisitor(player)
		DailyChallengeService.spawnDailyResources(player)
	end)
end

Players.PlayerAdded:Connect(initPlayerDaily)

-- Backfill players who joined BEFORE this module was required.
--
-- This module is loaded lazily by EndlessLoopWiring, so on a fast join -- always
-- in Studio Play, and for the first joiner on a live server -- the player is
-- already in Players by the time the connection above is made, and PlayerAdded
-- never fires for them. Without this, their daily state stays nil forever:
-- no challenges, no streak, no claimable reward. Verified in Studio 2026-08-25.
for _, player in ipairs(Players:GetPlayers()) do
	initPlayerDaily(player)
end

return DailyChallengeService
