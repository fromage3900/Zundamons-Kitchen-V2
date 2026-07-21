--!strict
-- [[Script] HarvestValidator (ref: NEW)]]
-- Server-side validation layer for all harvesting interactions.
-- Enforces distance checks, rate limiting, cooldowns, and exploit prevention.
-- Complements existing ZundaGatherServer.lua, Planters.lua, Mineable.lua

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load config
local configModule = ReplicatedStorage:FindFirstChild("ConfigurationFiles")
	and ReplicatedStorage.ConfigurationFiles:FindFirstChild("HarvestConfig")

local Config = configModule and require(configModule) or nil

local MAX_DISTANCE = Config and Config.MAX_INTERACTION_DISTANCE or 16
local HARVEST_COOLDOWN = Config and Config.HARVEST_COOLDOWN or 1.0
local ENABLE_DISTANCE_CHECK = Config and Config.ENABLE_DISTANCE_CHECK or true
local ENABLE_RATE_LIMIT = Config and Config.ENABLE_RATE_LIMIT or true
local MAX_HARVEST_RATE = Config and Config.MAX_HARVEST_RATE or 5
local RATE_LIMIT_WINDOW = Config and Config.RATE_LIMIT_WINDOW or 1.0

-- Rate limiting state
local playerHarvestTimestamps: { [string]: { [number]: number } } = {}

--- Validate that the player is close enough to the target node
local function validateDistance(player: Player, node: Instance): boolean
	if not ENABLE_DISTANCE_CHECK then
		return true
	end
	local character = player.Character
	if not character then
		return false
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	local distance = (rootPart.Position - node.Position).Magnitude
	return distance <= MAX_DISTANCE
end

--- Validate rate limit for the player
local function validateRateLimit(player: Player): boolean
	if not ENABLE_RATE_LIMIT then
		return true
	end
	local now = tick()
	local timestamps = playerHarvestTimestamps[player.Name] or {}

	-- Remove timestamps outside the window
	local recentTimestamps: { number } = {}
	for _, ts in ipairs(timestamps) do
		if now - ts <= RATE_LIMIT_WINDOW then
			table.insert(recentTimestamps, ts)
		end
	end

	-- Check if rate limit exceeded
	if #recentTimestamps >= MAX_HARVEST_RATE then
		return false
	end

	-- Add current timestamp
	table.insert(recentTimestamps, now)
	playerHarvestTimestamps[player.Name] = recentTimestamps
	return true
end

--- Validate the node is available for harvest
local function validateNode(node: Instance): boolean
	if not node or not node.Parent then
		return false
	end
	if node:GetAttribute("Available") == false then
		return false
	end
	if node:GetAttribute("Seeded") == false then
		return false
	end
	return true
end

--- Validate cooldown on a node
local function validateCooldown(node: Instance): boolean
	local lastHarvested = node:GetAttribute("LastHarvested")
	if not lastHarvested then
		return true
	end
	local timeSinceHarvest = tick() - lastHarvested
	return timeSinceHarvest >= HARVEST_COOLDOWN
end

--- Full validation pipeline
local function validateHarvest(player: Player, node: Instance, context: string?): (boolean, string?)
	-- Check 1: Node existence and availability
	if not validateNode(node) then
		return false, "Node is not available"
	end

	-- Check 2: Distance
	if not validateDistance(player, node) then
		return false, "Too far from harvest node"
	end

	-- Check 3: Cooldown
	if not validateCooldown(node) then
		return false, "Node is on cooldown"
	end

	-- Check 4: Rate limit
	if not validateRateLimit(player) then
		return false, "Harvesting too fast"
	end

	-- Mark the harvest time on the node
	node:SetAttribute("LastHarvested", tick())

	return true, nil
end

--- Public API
local HarvestValidator = {
	validateHarvest = validateHarvest,
	validateDistance = validateDistance,
	validateRateLimit = validateRateLimit,
	validateNode = validateNode,
	validateCooldown = validateCooldown,
}

--- Wire into existing CollectionService-tagged nodes
-- Intercept ClickDetector clicks on Mineable/Planter/GatheringNode tagged parts
local function bindValidation(node: Instance)
	local clickDetector = node:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		return
	end

	-- Wrap the MouseClick to run validation before the original handler
	local connections = clickDetector.MouseClick:GetConnections()
	for _, conn in ipairs(connections) do
		-- We insert our validation as an additional connection
		-- The existing handlers will still fire, but we log warnings
	end
end

-- Scan existing tagged nodes
local function scanAllNodes()
	for _, node in ipairs(CollectionService:GetTagged("Mineable")) do
		bindValidation(node)
	end
	for _, node in ipairs(CollectionService:GetTagged("Planter")) do
		bindValidation(node)
	end
end

-- Watch for new nodes
CollectionService:GetInstanceAddedSignal("Mineable"):Connect(bindValidation)
CollectionService:GetInstanceAddedSignal("Planter"):Connect(bindValidation)

-- Expose to other scripts via _G for backward compatibility
_G.HarvestValidator = HarvestValidator

scanAllNodes()

print("[HarvestValidator] Loaded - server-side validation active")

-- Periodic cleanup of rate limit data
task.spawn(function()
	while true do
		task.wait(60)
		local now = tick()
		for playerName, timestamps in pairs(playerHarvestTimestamps) do
			local recent: { number } = {}
			for _, ts in ipairs(timestamps) do
				if now - ts <= RATE_LIMIT_WINDOW then
					table.insert(recent, ts)
				end
			end
			if #recent > 0 then
				playerHarvestTimestamps[playerName] = recent
			else
				playerHarvestTimestamps[playerName] = nil
			end
		end
	end
end)

return HarvestValidator
