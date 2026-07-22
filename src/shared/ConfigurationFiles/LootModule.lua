--!strict
-- Server-owned physical-drop claims. Visuals remain client-local, but every
-- claim is bound to one player, item, origin, expiry, and exactly-once token.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RunService = game:GetService("RunService")

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctions then
	remoteFunctions = Instance.new("Folder")
	remoteFunctions.Name = "RemoteFunctions"
	remoteFunctions.Parent = ReplicatedStorage
end

local lootFolder = ReplicatedStorage:WaitForChild("Loot")

local makeLoot = remoteEvents:FindFirstChild("MakeLootEvent") :: RemoteEvent?
if not makeLoot then
	if RunService:IsServer() then
		local newEv = Instance.new("RemoteEvent")
		newEv.Name = "MakeLootEvent"
		newEv.Parent = remoteEvents
		makeLoot = newEv
	else
		makeLoot = remoteEvents:WaitForChild("MakeLootEvent") :: RemoteEvent
	end
end

local removeCode = remoteEvents:FindFirstChild("RemoveCode") :: RemoteEvent?
if not removeCode then
	if RunService:IsServer() then
		local newEv = Instance.new("RemoteEvent")
		newEv.Name = "RemoveCode"
		newEv.Parent = remoteEvents
		removeCode = newEv
	else
		removeCode = remoteEvents:WaitForChild("RemoveCode") :: RemoteEvent
	end
end

local giveLoot = remoteFunctions:FindFirstChild("GiveLoot") :: RemoteFunction?
if not giveLoot then
	if RunService:IsServer() then
		local newRF = Instance.new("RemoteFunction")
		newRF.Name = "GiveLoot"
		newRF.Parent = remoteFunctions
		giveLoot = newRF
	else
		giveLoot = remoteFunctions:WaitForChild("GiveLoot") :: RemoteFunction
	end
end

local sellLoot = remoteFunctions:FindFirstChild("sellLoot") :: RemoteFunction?
if not sellLoot then
	if RunService:IsServer() then
		local newRF = Instance.new("RemoteFunction")
		newRF.Name = "sellLoot"
		newRF.Parent = remoteFunctions
		sellLoot = newRF
	else
		sellLoot = remoteFunctions:WaitForChild("sellLoot") :: RemoteFunction
	end
end

local MineableConfig = require(ReplicatedStorage.ConfigurationFiles.MineableConfig)
local ChefLevelConfig = require(ReplicatedStorage.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)

local CLAIM_DISTANCE = 22
local CLAIM_LIFETIME = 60
local MAX_CLAIMS_PER_SECOND = 10
local MAX_SELLS_PER_SECOND = 5

local LootModule = {}
local claims: { [string]: { ownerId: number, item: string, position: Vector3, expiresAt: number } } = {}
local playerClaims: { [number]: { [string]: boolean } } = {}
local claimTimes: { [number]: { number } } = {}
local sellTimes: { [number]: { number } } = {}

local function withinRateLimit(bucket: { [number]: { number } }, userId: number, maximum: number): boolean
	local now = os.clock()
	local recent = {}
	for _, timestamp in ipairs(bucket[userId] or {}) do
		if now - timestamp <= 1 then
			table.insert(recent, timestamp)
		end
	end
	if #recent >= maximum then
		bucket[userId] = recent
		return false
	end
	table.insert(recent, now)
	bucket[userId] = recent
	return true
end

local function removeClaim(token: string)
	local claim = claims[token]
	if not claim then
		return
	end
	claims[token] = nil
	local owned = playerClaims[claim.ownerId]
	if owned then
		owned[token] = nil
		if next(owned) == nil then
			playerClaims[claim.ownerId] = nil
		end
	end
end

local function validRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function grantClaim(player: Player, itemName: string, token: string): boolean
	if not withinRateLimit(claimTimes, player.UserId, MAX_CLAIMS_PER_SECOND) then
		return false
	end
	local claim = claims[token]
	if not claim or claim.ownerId ~= player.UserId or claim.item ~= itemName or os.clock() > claim.expiresAt then
		return false
	end
	local root = validRoot(player)
	if not root or (root.Position - claim.position).Magnitude > CLAIM_DISTANCE then
		return false
	end
	local template = lootFolder:FindFirstChild(itemName)
	if not template then
		return false
	end
	-- Consume before settlement so concurrent/replayed requests cannot both win.
	removeClaim(token)
	local baseAmount = template:GetAttribute("Value") or 1
	if type(baseAmount) ~= "number" or baseAmount <= 0 then
		baseAmount = 1
	end
	local extraChance = RewardCore.companionBuff(player, "extra_drop")
	local totalAmount = math.floor(baseAmount) * ((extraChance > 0 and math.random() < extraChance) and 2 or 1)
	local result = RewardCore.settle(player, {
		xp = ChefLevelConfig.xpRewards.gather,
		reason = "gather",
		popupItem = string.format("%dx %s", totalAmount, itemName),
	}, function(data)
		data[itemName] = (data[itemName] or 0) + totalAmount
		if itemName == "Wood" or itemName == "Wood Log" then
			data.Wood = data[itemName]
			data["Wood Log"] = data[itemName]
		end
		data.gathered_items = data.gathered_items or {}
		data.gathered_items[itemName] = true
		return true, { item = itemName, count = totalAmount }
	end)
	if not result.ok then
		-- Mutation contention is safe to retry until the original expiry.
		claims[token] = claim
		playerClaims[player.UserId] = playerClaims[player.UserId] or {}
		playerClaims[player.UserId][token] = true
		return false
	end
	return true
end

function LootModule.generateLoot(player: Player, lootTable: { string }, position: Vector3, _quality: string?)
	if typeof(position) ~= "Vector3" or type(lootTable) ~= "table" then
		return
	end
	for _, itemName in ipairs(lootTable) do
		if type(itemName) == "string" and lootFolder:FindFirstChild(itemName) then
			local token = HttpService:GenerateGUID(false)
			claims[token] = {
				ownerId = player.UserId,
				item = itemName,
				position = position,
				expiresAt = os.clock() + CLAIM_LIFETIME,
			}
			playerClaims[player.UserId] = playerClaims[player.UserId] or {}
			playerClaims[player.UserId][token] = true
			makeLoot:FireClient(player, itemName, position, token)
		end
	end
end

function LootModule.GiveLoot(player: Player, itemName: any, token: any): boolean
	if type(itemName) ~= "string" or type(token) ~= "string" then
		return false
	end
	return grantClaim(player, itemName, token)
end

function LootModule.lootMaker(totalLoot: number): { string }
	local templates = lootFolder:GetChildren()
	local selected = {}
	if #templates == 0 then
		return selected
	end
	for _ = 1, math.max(0, math.floor(totalLoot)) do
		table.insert(selected, templates[math.random(1, #templates)].Name)
	end
	return selected
end

function LootModule.eraseData(player: Player)
	for token in pairs(playerClaims[player.UserId] or {}) do
		removeClaim(token)
	end
	claimTimes[player.UserId] = nil
	sellTimes[player.UserId] = nil
end

giveLoot.OnServerInvoke = LootModule.GiveLoot
removeCode.OnServerEvent:Connect(function(player, token, itemName)
	if type(token) ~= "string" or type(itemName) ~= "string" then
		return
	end
	local claim = claims[token]
	if claim and claim.ownerId == player.UserId and claim.item == itemName then
		removeClaim(token)
	end
end)

sellLoot.OnServerInvoke = function(player, itemName)
	if type(itemName) ~= "string" or not MineableConfig.priceLists[itemName] then
		return false
	end
	if not withinRateLimit(sellTimes, player.UserId, MAX_SELLS_PER_SECOND) then
		return false
	end
	local data = PlayerDataService.get(player)
	local quantity = data and data[itemName]
	if type(quantity) ~= "number" or quantity <= 0 then
		return false
	end
	local result = RewardCore.settle(player, {
		gold = MineableConfig.priceLists[itemName] * quantity,
		reason = "sell",
	}, function(current)
		if current[itemName] ~= quantity then
			return false, "inventory_changed"
		end
		current[itemName] = nil
		return true
	end)
	return result.ok and (PlayerDataService.get(player).gold or 0) or false
end

Players.PlayerRemoving:Connect(LootModule.eraseData)

task.spawn(function()
	while true do
		task.wait(10)
		local now = os.clock()
		for token, claim in pairs(claims) do
			if now > claim.expiresAt then
				removeClaim(token)
			end
		end
	end
end)

return LootModule
