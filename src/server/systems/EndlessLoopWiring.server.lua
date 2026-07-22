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
local CookingService = ServerScriptService.Services:FindFirstChild("CookingService")
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

-- Helper to sync stats, style points, and outfit unlocks to client UI
local function syncPlayerWardrobe(player: Player, styleGain: number?, statGains: { [string]: number }?)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end

	if styleGain and styleGain > 0 then
		data.style_points = (data.style_points or 0) + styleGain
	end

	data.chef_stats = data.chef_stats or {
		speed = 0,
		precision = 0,
		charisma = 0,
		stamina = 0,
	}

	if statGains then
		for statKey, amount in pairs(statGains) do
			if data.chef_stats[statKey] ~= nil then
				data.chef_stats[statKey] += amount
			end
		end
	end

	local currentPoints = data.style_points or 0
	local tier = ChefStatsConfig.getStyleTier(currentPoints)

	stylePointsRE:FireClient(player, currentPoints, tier.name)

	local statsPayload = {}
	for statKey, points in pairs(data.chef_stats) do
		local bonusMult = ChefStatsConfig.getStatBonus(statKey, points)
		statsPayload[statKey] = {
			level = math.floor(points / 10) + 1,
			multiplier = bonusMult,
			points = points,
		}
	end
	chefStatsRE:FireClient(player, statsPayload)

	data.unlocked_outfits = data.unlocked_outfits or {}
	for _, unlockCategory in ipairs(ChefStatsConfig.stylePoints.outfitUnlocks) do
		local reqTier = unlockCategory.tier
		local reqMinPoints = 0
		for _, tData in ipairs(ChefStatsConfig.stylePoints.tiers) do
			if tData.name == reqTier then
				reqMinPoints = tData.minPoints
				break
			end
		end
		if currentPoints >= reqMinPoints then
			for _, outfitName in ipairs(unlockCategory.outfits) do
				if not data.unlocked_outfits[outfitName] then
					data.unlocked_outfits[outfitName] = true
					outfitUnlockRE:FireClient(player, outfitName)
				end
			end
		end
	end
end

-- ─── Connect CookingService to ChallengeMode ───────────────────────────────
-- When a dish is cooked with quality, notify the challenge mode and update stats
if CookingService and CookingService.CookCompleted then
	CookingService.CookCompleted.Event:Connect(function(player, recipeName, quality)
		if ChallengeModeService.isInChallenge(player) then
			ChallengeModeService.onGuestServed(player, quality, recipeName)
		end
		-- Update daily challenge progress
		DailyChallengeService.updateProgress(player, "cook", 1)

		local styleGain = 0
		local statGains = {}
		if quality == "perfect" then
			DailyChallengeService.updateProgress(player, "perfect", 1)
			styleGain = ChefStatsConfig.stylePoints.sources.perfect_cook or 10
			statGains.precision = 2
			statGains.speed = 1
		elseif quality == "great" then
			styleGain = ChefStatsConfig.stylePoints.sources.great_cook or 5
			statGains.precision = 1
		end

		syncPlayerWardrobe(player, styleGain, statGains)
	end)
end

-- ─── Connect ServingService to ChallengeMode & Daily Challenges ─────────────
if ServingService and ServingService.GuestServed then
	ServingService.GuestServed.Event:Connect(function(player, guestType, recipe, quality)
		if ChallengeModeService.isInChallenge(player) then
			ChallengeModeService.onGuestServed(player, quality, guestType)
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

-- ─── Connect Gathering to Daily Challenges ───────────────────────────────────
-- Listen for ingredient collection events
local function setupGatheringListener()
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotes then
		return
	end

	local gatherEvent = remotes:FindFirstChild("IngredientGathered")
	if gatherEvent then
		gatherEvent.Event:Connect(function(player, itemName)
			DailyChallengeService.updateProgress(player, "gather", 1)
		end)
	end

	local goldEvent = remotes:FindFirstChild("GoldEarned")
	if goldEvent then
		goldEvent.Event:Connect(function(player, amount)
			DailyChallengeService.updateProgress(player, "earn_gold", amount)
		end)
	end
end

setupGatheringListener()

-- ─── Initialize Player Data for New Systems ──────────────────────────────────
-- Ensure new data fields exist when player joins and sync wardrobe remotes
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Initialize challenge mode data
		local data = PlayerDataService.get(player)
		if data then
			data.challenge_best_score = data.challenge_best_score or 0
			data.challenge_best_wave = data.challenge_best_wave or 0
			data.challenge_total_played = data.challenge_total_played or 0
			data.style_points = data.style_points or 0
			data.chef_stats = data.chef_stats or {
				speed = 0,
				precision = 0,
				charisma = 0,
				stamina = 0,
			}
			syncPlayerWardrobe(player, 0, nil)
		end
	end)

	-- Initialize daily challenges
	task.wait(3)
	DailyChallengeService.initializeDay(player)
	DailyChallengeService.spawnDailyVisitor(player)
	DailyChallengeService.spawnDailyResources(player)
	syncPlayerWardrobe(player, 0, nil)
end)

print("[EndlessLoopWiring] All systems connected!")
print("  - ChallengeModeService: Endless wave system")
print("  - DailyChallengeService: Daily challenge system")
print("  - ChefStatsConfig: Infinity Nikki style stats & wardrobe remotes")
print("  - VNDialogueData: Dialogue system")
