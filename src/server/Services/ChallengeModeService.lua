--!strict
-- [[ModuleScript] ChallengeModeService]]
-- Endless wave-based challenge mode inspired by Uma Musume's racing meets.
-- Players face increasingly difficult guest waves, earning score and rewards.
-- Each wave adds more guests, less patience, and harder recipes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local ChefStatsConfig = require(ReplicatedStorage.ConfigurationFiles.ChefStatsConfig)
local ProgressionConfig = require(ReplicatedStorage.ConfigurationFiles.ProgressionConfig)
local CraftConfig = require(ReplicatedStorage.ConfigurationFiles.CraftConfig)

local ChallengeModeService = {}

-- ── Challenge Tiers ─────────────────────────────────────────────────────────
-- Like Uma Musume's race grades: C → B → A → S → Zunda
ChallengeModeService.tiers = {
	{ name = "Bronze",  minScore = 0,     color = Color3.fromRGB(205, 127, 50),  icon = "🥉", requiredWave = 5  },
	{ name = "Silver",  minScore = 500,   color = Color3.fromRGB(192, 192, 192),  icon = "🥈", requiredWave = 10 },
	{ name = "Gold",    minScore = 2000,  color = Color3.fromRGB(255, 215, 0),    icon = "🥇", requiredWave = 20 },
	{ name = "Platinum", minScore = 8000, color = Color3.fromRGB(140, 200, 255),  icon = "💎", requiredWave = 35 },
	{ name = "Zunda",   minScore = 30000, color = Color3.fromRGB(160, 210, 150), icon = "🫛", requiredWave = 50 },
}

-- ── Wave Configuration ──────────────────────────────────────────────────────
-- Each wave increases difficulty
ChallengeModeService.waveConfig = {
	-- wave = { guestCount, patienceMultiplier, recipeDifficulty, goldMultiplier }
	[1]  = { guests = 2, patience = 1.0,  minTier = 1, goldMult = 1.0 },
	[2]  = { guests = 2, patience = 0.95, minTier = 1, goldMult = 1.1 },
	[3]  = { guests = 3, patience = 0.90, minTier = 1, goldMult = 1.2 },
	[4]  = { guests = 3, patience = 0.85, minTier = 2, goldMult = 1.3 },
	[5]  = { guests = 3, patience = 0.80, minTier = 2, goldMult = 1.5 },
	[6]  = { guests = 4, patience = 0.75, minTier = 2, goldMult = 1.7 },
	[7]  = { guests = 4, patience = 0.70, minTier = 3, goldMult = 2.0 },
	[8]  = { guests = 4, patience = 0.65, minTier = 3, goldMult = 2.2 },
	[9]  = { guests = 5, patience = 0.60, minTier = 3, goldMult = 2.5 },
	[10] = { guests = 5, patience = 0.55, minTier = 4, goldMult = 3.0 },
	-- Beyond 10: scales procedurally
}

-- ── Score Calculation ───────────────────────────────────────────────────────
ChallengeModeService.scoreValues = {
	guest_served = 20,
	perfect_cook = 50,
	great_cook = 25,
	combo_5 = 30,
	combo_10 = 60,
	wave_complete = 100,
	all_perfect_wave = 200,
}

-- ── Session State ───────────────────────────────────────────────────────────
local sessions: { [number]: {
	wave: number,
	score: number,
	goldEarned: number,
	guestsServed: number,
	perfectCooks: number,
	currentCombo: number,
	maxCombo: number,
	startTime: number,
	activeGuests: { any },
	tier: string,
} } = {}

-- RemoteEvents
local challengeEvent = nil
local challengeStatus = nil

local function getRemotes()
	if not challengeEvent then
		local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
		challengeEvent = RE:FindFirstChild("ChallengeMode")
		if not challengeEvent then
			challengeEvent = Instance.new("RemoteEvent")
			challengeEvent.Name = "ChallengeMode"
			challengeEvent.Parent = RE
		end
		challengeStatus = RE:FindFirstChild("ChallengeModeStatus")
		if not challengeStatus then
			challengeStatus = Instance.new("RemoteEvent")
			challengeStatus.Name = "ChallengeModeStatus"
			challengeStatus.Parent = RE
		end
	end
	return challengeEvent, challengeStatus
end

-- ── Wave Configuration Helpers ──────────────────────────────────────────────

function ChallengeModeService.getWaveConfig(wave: number): { guests: number, patience: number, minTier: number, goldMult: number }
	local config = ChallengeModeService.waveConfig[wave]
	if config then
		return config
	end

	-- Procedural scaling beyond wave 10
	local baseWave = 10
	local extra = wave - baseWave
	local scale = 1 + (extra * 0.15)
	return {
		guests = math.min(3 + math.floor(extra / 2), 8),
		patience = math.max(0.55 * (1 / scale), 0.25),
		minTier = math.min(4 + math.floor(extra / 5), 5),
		goldMult = 3.0 * scale,
	}
end

function ChallengeModeService.getTierForScore(score: number): { name: string, color: Color3, icon: string }
	for i = #ChallengeModeService.tiers, 1, -1 do
		local tier = ChallengeModeService.tiers[i]
		if score >= tier.minScore then
			return tier
		end
	end
	return ChallengeModeService.tiers[1]
end

-- ── Recipe Selection ────────────────────────────────────────────────────────

function ChallengeModeService.selectChallengeRecipes(wave: number): { string }
	local config = ChallengeModeService.getWaveConfig(wave)
	local minTier = config.minTier

	-- Select recipes appropriate for the wave's difficulty tier
	local allRecipes = {}
	for name, ingredients in pairs(CraftConfig.recipes) do
		local difficulty = CraftConfig.difficulty[name]
		local notes = difficulty and difficulty.notes or CraftConfig.defaultDifficulty.notes
		local tier = 1
		if notes >= 7 then
			tier = 4
		elseif notes >= 5 then
			tier = 3
		elseif notes >= 4 then
			tier = 2
		end
		if tier >= minTier then
			table.insert(allRecipes, name)
		end
	end

	-- Return a weighted selection
	local selected = {}
	for i = 1, math.min(5, #allRecipes) do
		local recipe = allRecipes[math.random(1, #allRecipes)]
		if recipe and not table.find(selected, recipe) then
			table.insert(selected, recipe)
		end
	end
	return selected
end

-- ── Session Management ──────────────────────────────────────────────────────

function ChallengeModeService.startSession(player: Player): boolean
	local playerId = player.UserId

	if sessions[playerId] then
		return false
	end

	-- Check if player has unlocked challenge mode
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end

	-- Challenge mode unlocks at 10 guests served or tier 2
	if (data.guests_served or 0) < 10 and (data.tier or 1) < 2 then
		local _, status = getRemotes()
		status:FireClient(player, { type = "locked", reason = "Serve 10 guests to unlock!" })
		return false
	end

	sessions[playerId] = {
		wave = 1,
		score = 0,
		goldEarned = 0,
		guestsServed = 0,
		perfectCooks = 0,
		currentCombo = 0,
		maxCombo = 0,
		startTime = tick(),
		activeGuests = {},
		tier = "Bronze",
	}

	local event, status = getRemotes()
	status:FireClient(player, {
		type = "started",
		wave = 1,
		score = 0,
		tier = "Bronze",
		recipes = ChallengeModeService.selectChallengeRecipes(1),
	})

	return true
end

function ChallengeModeService.endSession(player: Player, abandoned: boolean?)
	local playerId = player.UserId
	local session = sessions[playerId]
	if not session then
		return
	end

	-- Calculate final rewards
	local waveBonus = session.wave * 50
	local scoreBonus = math.floor(session.score / 10)
	local perfectBonus = session.perfectCooks * 30
	local totalGold = waveBonus + scoreBonus + perfectBonus

	-- Apply stat bonuses
	local data = PlayerDataService.get(player)
	local speedPoints = (data and data.chef_stats and data.chef_stats.speed) or 0
	local charismaMult = ChefStatsConfig.getGoldMultiplier(speedPoints)
	totalGold = math.floor(totalGold * charismaMult)

	-- Grant rewards
	local tier = ChallengeModeService.getTierForScore(session.score)
	RewardCore.settle(player, {
		gold = totalGold,
		xp = session.wave * 20,
		reason = "challenge",
		combo = true,
	}, function(data)
		data.challenge_best_score = math.max(data.challenge_best_score or 0, session.score)
		data.challenge_best_wave = math.max(data.challenge_best_wave or 0, session.wave)
		data.challenge_total_played = (data.challenge_total_played or 0) + 1
		return true
	end)

	-- Grant style points
	local stylePoints = math.floor(session.score / 5)
	PlayerDataService.mutate(player, "challenge_style_points", function(data)
		data.style_points = (data.style_points or 0) + stylePoints
		return true
	end)

	-- Unlock tier if achieved
	if session.score >= ChallengeModeService.tiers[#ChallengeModeService.tiers].minScore then
		PlayerDataService.mutate(player, "challenge_legendary", function(data)
			data.challenge_legendary_unlocked = true
			return true
		end)
	end

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "completed",
		score = session.score,
		wave = session.wave,
		gold = totalGold,
		tier = tier.name,
		stylePoints = stylePoints,
	})

	sessions[playerId] = nil
end

-- ── Wave Progression ────────────────────────────────────────────────────────

function ChallengeModeService.completeWave(player: Player)
	local playerId = player.UserId
	local session = sessions[playerId]
	if not session then
		return
	end

	-- Wave completion bonus
	local waveBonus = ChallengeModeService.scoreValues.wave_complete * session.wave
	session.score = session.score + waveBonus

	-- Perfect wave bonus
	if session.perfectCooks >= session.guestsServed and session.guestsServed > 0 then
		session.score = session.score + ChallengeModeService.scoreValues.all_perfect_wave
	end

	-- Advance wave
	session.wave = session.wave + 1
	session.guestsServed = 0
	session.perfectCooks = 0
	session.currentCombo = 0

	-- Update tier
	local tier = ChallengeModeService.getTierForScore(session.score)
	session.tier = tier.name

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "wave_complete",
		wave = session.wave,
		score = session.score,
		tier = tier.name,
		tierIcon = tier.icon,
		recipes = ChallengeModeService.selectChallengeRecipes(session.wave),
		goldMult = ChallengeModeService.getWaveConfig(session.wave).goldMult,
	})
end

-- ── Event Handlers ──────────────────────────────────────────────────────────

function ChallengeModeService.onGuestServed(player: Player, quality: string, recipe: string)
	local playerId = player.UserId
	local session = sessions[playerId]
	if not session then
		return
	end

	session.guestsServed = session.guestsServed + 1
	session.currentCombo = session.currentCombo + 1
	session.maxCombo = math.max(session.maxCombo, session.currentCombo)

	-- Score by quality
	if quality == "perfect" then
		session.score = session.score + ChallengeModeService.scoreValues.perfect_cook
		session.perfectCooks = session.perfectCooks + 1
	elseif quality == "great" then
		session.score = session.score + ChallengeModeService.scoreValues.great_cook
	else
		session.score = session.score + ChallengeModeService.scoreValues.guest_served
	end

	-- Combo bonuses
	if session.currentCombo >= 10 then
		session.score = session.score + ChallengeModeService.scoreValues.combo_10
	elseif session.currentCombo >= 5 then
		session.score = session.score + ChallengeModeService.scoreValues.combo_5
	end

	-- Style points
	local styleGain = quality == "perfect" and 10 or quality == "great" and 5 or 2
	PlayerDataService.mutate(player, "challenge_style_gain", function(data)
		data.style_points = (data.style_points or 0) + styleGain
		return true
	end)

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "guest_served",
		score = session.score,
		wave = session.wave,
		combo = session.currentCombo,
		maxCombo = session.maxCombo,
	})
end

function ChallengeModeService.onGuestTimeout(player: Player)
	local playerId = player.UserId
	local session = sessions[playerId]
	if not session then
		return
	end

	-- Break combo on timeout
	session.currentCombo = 0

	local _, status = getRemotes()
	status:FireClient(player, {
		type = "guest_timeout",
		score = session.score,
		wave = session.wave,
	})
end

function ChallengeModeService.abandonSession(player: Player)
	ChallengeModeService.endSession(player, true)
end

-- ── Public API ──────────────────────────────────────────────────────────────

function ChallengeModeService.getSession(player: Player)
	return sessions[player.UserId]
end

function ChallengeModeService.isInChallenge(player: Player): boolean
	return sessions[player.UserId] ~= nil
end

function ChallengeModeService.getBestScore(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	return data.challenge_best_score or 0
end

function ChallengeModeService.getBestWave(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	return data.challenge_best_wave or 0
end

-- ── Cleanup ─────────────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	sessions[player.UserId] = nil
end)

return ChallengeModeService
