--!strict
-- [[ModuleScript] HarvestValidator (ref: NEW)]]
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
local playerHarvestTimestamps: { [string]: { number } } = {}

--- Safe position helper for both BasePart and Model instances
local function getNodePosition(node: Instance): Vector3
	if not node then
		return Vector3.zero
	end
	return if node:IsA("BasePart")
		then node.Position
		else (
			if node:IsA("Model")
				then (node.PrimaryPart and node.PrimaryPart.Position or node:GetPivot().Position)
				else Vector3.zero
		)
end

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
	local nodePos = getNodePosition(node)
	local distance = (rootPart.Position - nodePos).Magnitude
	return distance <= MAX_DISTANCE
end

--- Validate rate limit for the player
local function validateRateLimit(player: Player): boolean
	if not ENABLE_RATE_LIMIT then
		return true
	end
	local now = os.clock()
	local timestamps = playerHarvestTimestamps[tostring(player.UserId)] or {}

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
	playerHarvestTimestamps[tostring(player.UserId)] = recentTimestamps
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
	-- Only check "Seeded" if the attribute exists (planters use this; wild gathering nodes don't have it)
	local seeded = node:GetAttribute("Seeded")
	if seeded ~= nil and seeded == false then
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
	local timeSinceHarvest = os.clock() - (lastHarvested :: number)
	return timeSinceHarvest >= HARVEST_COOLDOWN
end

--- Validation for co-op node breaking (does not update node LastHarvested or check single-player rate limits)
local function validateNodeBreakHarvest(player: Player, node: Instance): (boolean, string?)
	if not node or not node.Parent then
		return false, "Node is not available"
	end

	if not validateDistance(player, node) then
		return false, "Too far from harvest node"
	end

	return true, nil
end

--- Full validation pipeline
local function validateHarvest(player: Player, node: Instance, context: string?): (boolean, string?)
	-- Node-break context check (or node is already marked as Mined)
	if context == "node_break" or context == "nodeBreak" or (node and node:GetAttribute("Mined") == true) then
		return validateNodeBreakHarvest(player, node)
	end

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
	node:SetAttribute("LastHarvested", os.clock())

	return true, nil
end

--- Public API
local HarvestValidator = {
	getNodePosition = getNodePosition,
	validateHarvest = validateHarvest,
	validateNodeBreakHarvest = validateNodeBreakHarvest,
	validateDistance = validateDistance,
	validateRateLimit = validateRateLimit,
	validateNode = validateNode,
	validateCooldown = validateCooldown,
}

-- Expose to other scripts via _G for backward compatibility
_G.HarvestValidator = HarvestValidator

print("[HarvestValidator] Loaded - server-side validation active")

-- Periodic cleanup of rate limit data
task.spawn(function()
	while true do
		task.wait(60)
		local now = os.clock()
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
