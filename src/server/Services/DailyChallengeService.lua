--!strict
-- [[ModuleScript] DailyChallengeService]]
-- Daily challenge system inspired by Uma Musume's daily races.
-- 3 rotating daily challenges + weekly boss challenge + streak rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local DailyChallengeConfig = require(ReplicatedStorage.ConfigurationFiles.DailyChallengeConfig)

local DailyChallengeService = {}

local challengeEvent = nil
local challengeStatus = nil

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
	end
	return challengeEvent, challengeStatus
end

local function getTodayKey(): string
	return os.date("%Y-%m-%d")
end

function DailyChallengeService.initializeDay(player: Player)
	local data = PlayerDataService.get(player)
	if not data then return end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then
		-- New day — generate fresh challenges
		local challenges = DailyChallengeConfig.selectDailyChallenges()
		data.daily_challenge_date = today
		data.daily_challenges = challenges
		data.daily_challenge_progress = {}
		data.daily_challenge_claimed = {}
		data.daily_streak = data.daily_streak or 0
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "daily_update",
		challenges = data.daily_challenges,
		progress = data.daily_challenge_progress,
		claimed = data.daily_challenge_claimed,
		streak = data.daily_streak,
		weeklyBoss = DailyChallengeConfig.getWeeklyBoss(),
	})
end

function DailyChallengeService.updateProgress(player: Player, metric: string, amount: number)
	local data = PlayerDataService.get(player)
	if not data or not data.daily_challenges then return end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then return end

	local progress = data.daily_challenge_progress or {}
	for i, challenge in ipairs(data.daily_challenges) do
		if challenge.metric == metric then
			local current = progress[i] or 0
			local newProgress = math.min(current + amount, challenge.goal)
			progress[i] = newProgress
			if newProgress >= challenge.goal and not data.daily_challenge_claimed or not data.daily_challenge_claimed[i] then
				-- Challenge complete!
				PlayerDataService.mutate(player, "daily_challenge_complete", function(d)
					local p = d.daily_challenge_progress or {}
					p[i] = newProgress
					d.daily_challenge_progress = p
					return true
				end)
			end
		end
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "progress_update",
		progress = progress,
	})
end

function DailyChallengeService.claimReward(player: Player, challengeIndex: number)
	local data = PlayerDataService.get(player)
	if not data or not data.daily_challenges then return false end

	local today = getTodayKey()
	if data.daily_challenge_date ~= today then return false end

	local challenge = data.daily_challenges[challengeIndex]
	if not challenge then return false end

	local progress = data.daily_challenge_progress or {}
	if (progress[challengeIndex] or 0) < challenge.goal then return false end

	local claimed = data.daily_challenge_claimed or {}
	if claimed[challengeIndex] then return false end

	claimed[challengeIndex] = true
	data.daily_challenge_claimed = claimed

	-- Grant rewards
	local reward = challenge.reward
	RewardCore.settle(player, {
		gold = reward.gold or 0,
		xp = reward.xp or 0,
		reason = "daily_challenge",
	}, function(d)
		d.style_points = (d.style_points or 0) + (reward.style or 0)
		for _, item in ipairs(reward.items or {}) do
			PlayerDataService.grantItem(player, item, 1)
		end
		return true
	end)

	-- Check if all 3 challenges are complete for streak bonus
	local allComplete = true
	for i = 1, 3 do
		if not claimed[i] then allComplete = false break end
	end

	if allComplete then
		data.daily_streak = (data.daily_streak or 0) + 1
		local streakReward = DailyChallengeConfig.getStreakReward(data.daily_streak)
		RewardCore.settle(player, {
			gold = streakReward.gold or 0,
			xp = streakReward.xp or 0,
			reason = "daily_streak",
		}, function(d)
			d.style_points = (d.style_points or 0) + (streakReward.style or 0)
			return true
		end)
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "reward_claimed",
		challengeIndex = challengeIndex,
		streak = data.daily_streak,
	})

	return true
end

function DailyChallengeService.spawnDailyVisitor(player: Player)
	local data = PlayerDataService.get(player)
	if not data then return end

	local today = getTodayKey()
	if data.daily_visitor_visited and data.daily_visitor_date == today then
		return false
	end

	data.daily_visitor_date = today
	data.daily_visitor_visited = true

	local visitor = DailyChallengeConfig.dailyVisitor
	RewardCore.settle(player, {
		gold = visitor.reward.gold or 100,
		xp = visitor.reward.xp or 80,
		reason = "daily_visitor",
	}, function(d)
		PlayerDataService.grantItem(player, visitor.reward.item or "Zunda Flower", 1)
		return true
	end)

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "visitor_spawned",
		visitor = visitor,
	})

	return true
end

function DailyChallengeService.spawnDailyResources(player: Player)
	local data = PlayerDataService.get(player)
	if not data then return end

	local today = getTodayKey()
	if data.daily_resources_spawned and data.daily_resources_date == today then
		return false
	end

	data.daily_resources_date = today
	data.daily_resources_spawned = true

	for _, resource in ipairs(DailyChallengeConfig.dailyResources) do
		PlayerDataService.grantItem(player, resource.resourceType, resource.count)
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "resources_spawned",
		resources = DailyChallengeConfig.dailyResources,
	})

	return true
end

function DailyChallengeService.checkAndUnlockWeeklyBoss(player: Player)
	local data = PlayerDataService.get(player)
	if not data then return false end

	local today = getTodayKey()
	local boss = DailyChallengeConfig.getWeeklyBoss()

	-- Check if weekly boss progress is tracked
	if not data.weekly_boss_id or data.weekly_boss_id ~= boss.id then
		data.weekly_boss_id = boss.id
		data.weekly_boss_progress = 0
		data.weekly_boss_claimed = false
	end

	return data.weekly_boss_progress or 0, boss
end

function DailyChallengeService.updateWeeklyProgress(player: Player, metric: string, amount: number)
	local data = PlayerDataService.get(player)
	if not data then return end

	local boss = DailyChallengeConfig.getWeeklyBoss()
	if data.weekly_boss_id ~= boss.id then
		data.weekly_boss_id = boss.id
		data.weekly_boss_progress = 0
		data.weekly_boss_claimed = false
	end

	if boss.metric == metric then
		local current = data.weekly_boss_progress or 0
		data.weekly_boss_progress = math.min(current + amount, boss.goal)
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "weekly_update",
		boss = boss,
		progress = data.weekly_boss_progress,
	})
end

function DailyChallengeService.claimWeeklyReward(player: Player)
	local data = PlayerDataService.get(player)
	if not data then return false end

	local boss = DailyChallengeConfig.getWeeklyBoss()
	if data.weekly_boss_id ~= boss.id then return false end
	if (data.weekly_boss_progress or 0) < boss.goal then return false end
	if data.weekly_boss_claimed then return false end

	data.weekly_boss_claimed = true

	local reward = boss.reward
	RewardCore.settle(player, {
		gold = reward.gold or 0,
		xp = reward.xp or 0,
		reason = "weekly_boss",
	}, function(d)
		d.style_points = (d.style_points or 0) + (reward.style or 0)
		for _, item in ipairs(reward.items or {}) do
			PlayerDataService.grantItem(player, item, 1)
		end
		return true
	end)

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "weekly_claimed",
		boss = boss,
	})

	return true
end

-- ── Player Join ─────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(3)
		DailyChallengeService.initializeDay(player)
		DailyChallengeService.spawnDailyVisitor(player)
		DailyChallengeService.spawnDailyResources(player)
	end)
end)

return DailyChallengeService
