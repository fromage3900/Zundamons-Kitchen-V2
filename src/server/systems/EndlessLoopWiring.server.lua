--!strict
-- [[Script] EndlessLoopWiring]]
-- Wires together the new endless gameplay loop systems:
-- ChallengeModeService, DailyChallengeService, ChefStatsConfig
-- Connects them to existing GuestManager, CookingService, ServingService.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Initialize services
local ChallengeModeService = require(ServerScriptService.Services.ChallengeModeService)
local DailyChallengeService = require(ServerScriptService.Services.DailyChallengeService)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local ChefStatsConfig = require(ReplicatedStorage.ConfigurationFiles.ChefStatsConfig)

-- Get existing services for integration
local CookingService = require(ServerScriptService.Services.CookingService)
local ServingService = require(ServerScriptService.Services.ServingService)

-- ─── RemoteEvent Setup ───────────────────────────────────────────────────────
-- Ensure all RemoteEvents exist for client communication
local function ensureRemote(name: string): RemoteEvent
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "RemoteEvents"
		remotes.Parent = ReplicatedStorage
	end

	local event = remotes:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	return event :: RemoteEvent
end

-- Pre-create all required RemoteEvents
ensureRemote("ShowVNDialogue")
local chefStatsRE = ensureRemote("ChefStatsUpdate")
local stylePointsRE = ensureRemote("StylePointsUpdate")
local outfitUnlockRE = ensureRemote("OutfitUnlock")
ensureRemote("ChallengeMode")
ensureRemote("ChallengeModeStatus")
ensureRemote("DailyChallenge")
ensureRemote("DailyChallengeStatus")

-- ─── Client-invokable RemoteFunctions ───────────────────────────────────────
-- The client UI needs a way to start/abandon challenge mode and claim daily
-- rewards. These are the only entry points; all state changes go through the
-- services (which route writes through PlayerDataService.mutate).
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctions then
	remoteFunctions = Instance.new("Folder")
	remoteFunctions.Name = "RemoteFunctions"
	remoteFunctions.Parent = ReplicatedStorage
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local rf = remoteFunctions:FindFirstChild(name)
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = remoteFunctions
	end
	return rf :: RemoteFunction
end

local challengeStartRF = ensureRemoteFunction("ChallengeStart")
local challengeAbandonRF = ensureRemoteFunction("ChallengeAbandon")
local challengeCompleteWaveRF = ensureRemoteFunction("ChallengeCompleteWave")
local dailyClaimRF = ensureRemoteFunction("DailyClaimReward")
local dailyClaimWeeklyRF = ensureRemoteFunction("DailyClaimWeekly")

challengeStartRF.OnServerInvoke = function(player)
	return ChallengeModeService.startSession(player)
end

challengeAbandonRF.OnServerInvoke = function(player)
	ChallengeModeService.abandonSession(player)
	return true
end

challengeCompleteWaveRF.OnServerInvoke = function(player)
	ChallengeModeService.completeWave(player)
	return true
end

dailyClaimRF.OnServerInvoke = function(player, challengeIndex)
	if type(challengeIndex) ~= "number" then
		return false
	end
	return DailyChallengeService.claimReward(player, challengeIndex)
end

dailyClaimWeeklyRF.OnServerInvoke = function(player)
	return DailyChallengeService.claimWeeklyReward(player)
end

-- Helper to sync stats, style points, and outfit unlocks to client UI
local function syncPlayerWardrobe(player: Player, styleGain: number?, statGains: { [string]: number }?)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	-- All durable writes go through PlayerDataService.mutate so they get the
	-- same revision bump, projection emit, and rollback as every other system.
	-- Firing remotes happens after the mutation succeeds.
	local newlyUnlocked = {}
	local ok = PlayerDataService.mutate(player, "wardrobe_sync", function(d)
		if styleGain and styleGain > 0 then
			d.style_points = (d.style_points or 0) + styleGain
		end

		d.chef_stats = d.chef_stats or {
			speed = 0,
			precision = 0,
			charisma = 0,
			stamina = 0,
		}

		if statGains then
			for statKey, amount in pairs(statGains) do
				if d.chef_stats[statKey] ~= nil then
					d.chef_stats[statKey] += amount
				end
			end
		end

		d.unlocked_outfits = d.unlocked_outfits or {}
		local currentPoints = d.style_points or 0
		for _, unlockCategory in ipairs(ChefStatsConfig.stylePoints.outfitUnlocks) do
			local reqMinPoints = 0
			for _, tData in ipairs(ChefStatsConfig.stylePoints.tiers) do
				if tData.name == unlockCategory.tier then
					reqMinPoints = tData.minPoints
					break
				end
			end
			if currentPoints >= reqMinPoints then
				for _, outfitName in ipairs(unlockCategory.outfits) do
					if not d.unlocked_outfits[outfitName] then
						d.unlocked_outfits[outfitName] = true
						table.insert(newlyUnlocked, outfitName)
					end
				end
			end
		end
		return true
	end)
	if not ok then
		return
	end

	local currentPoints = data.style_points or 0
	local tier = ChefStatsConfig.getStyleTier(currentPoints)

	stylePointsRE:FireClient(player, currentPoints, tier.name)

	local statsPayload = {}
	for statKey, points in pairs(data.chef_stats or {}) do
		local bonusMult = ChefStatsConfig.getStatBonus(statKey, points)
		statsPayload[statKey] = {
			level = math.floor(points / 10) + 1,
			multiplier = bonusMult,
			points = points,
		}
	end
	chefStatsRE:FireClient(player, statsPayload)

	for _, outfitName in ipairs(newlyUnlocked) do
		outfitUnlockRE:FireClient(player, outfitName)
	end
end

-- ─── Connect CookingService to ChallengeMode ───────────────────────────────
-- When a dish is cooked with quality, notify the challenge mode and update stats
if CookingService and CookingService.CookCompleted then
	CookingService.CookCompleted.Event:Connect(function(player, recipeName, quality, metrics)
		ChallengeModeService.onCookComplete(player, quality)
		-- Update daily challenge progress
		DailyChallengeService.updateProgress(player, "cook", 1)

		local styleGain = 0
		local statGains = {}

		if metrics and type(metrics) == "table" then
			styleGain = metrics.stylePoints or 0
			statGains = metrics.statXP or {}
			if quality == "perfect" or (metrics.grade and metrics.grade == "S") then
				DailyChallengeService.updateProgress(player, "perfect", 1)
			end
		else
			if quality == "perfect" then
				DailyChallengeService.updateProgress(player, "perfect", 1)
				styleGain = ChefStatsConfig.stylePoints.sources.perfect_cook or 10
				statGains.precision = 2
				statGains.speed = 1
			elseif quality == "great" then
				styleGain = ChefStatsConfig.stylePoints.sources.great_cook or 5
				statGains.precision = 1
			end
		end

		syncPlayerWardrobe(player, styleGain, statGains)
	end)
end

-- ─── Connect ServingService to ChallengeMode & Daily Challenges ─────────────
if ServingService and ServingService.GuestServed then
	ServingService.GuestServed.Event:Connect(function(player, guestType, recipe, quality)
		if ChallengeModeService.isInChallenge(player) then
			ChallengeModeService.onGuestServed(player, quality)
		end
		DailyChallengeService.updateProgress(player, "serve", 1)

		local styleGain = ChefStatsConfig.stylePoints.sources.serving_flawless or 8
		local statGains = { charisma = 2, stamina = 1 }
		if quality == "perfect" then
			DailyChallengeService.updateProgress(player, "perfect", 1)
			styleGain += 5
			statGains.charisma += 1
		end

		syncPlayerWardrobe(player, styleGain, statGains)
	end)
end

if ServingService and ServingService.GuestTimedOut then
	ServingService.GuestTimedOut.Event:Connect(function(player)
		if ChallengeModeService.isInChallenge(player) then
			ChallengeModeService.onGuestTimeout(player)
		end
	end)
end

-- ─── Initialize Player Data for New Systems ──────────────────────────────────
-- Ensure new data fields exist when player joins and sync wardrobe remotes.
-- Daily challenge initialization (initializeDay / spawnDailyVisitor /
-- spawnDailyResources) is owned by DailyChallengeService.PlayerAdded alone —
-- duplicating it here caused double-grant windows and doubly-fired updates.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Initialize challenge mode data
		local data = PlayerDataService.get(player)
		if data then
			data.challenge_best_score = data.challenge_best_score or 0
			data.challenge_best_wave = data.challenge_best_wave or 0
			data.challenge_total_played = data.challenge_total_played or 0
			syncPlayerWardrobe(player, 0, nil)
		end
	end)

	syncPlayerWardrobe(player, 0, nil)
end)
