--!strict
-- Transactional guest serving domain. A successful request consumes one
-- server-quality dish and settles progression/rewards exactly once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPCConfig = require(ReplicatedStorage.Shared.Config.NPCConfig)
local ChefLevelConfig = require(ReplicatedStorage.ConfigurationFiles.ChefLevelConfig)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local GuestService = require(ServerScriptService.Services.GuestService)

local MAX_SERVE_DISTANCE = 20
local RATE_LIMIT = 0.25
local lastServeAt: { [number]: number } = {}
local ServingService = {}
ServingService.GuestServed = Instance.new("BindableEvent")
ServingService.GuestTimedOut = Instance.new("BindableEvent")

local function validGuest(player: Player, guest: any): (boolean, string?)
	if typeof(guest) ~= "Instance" or not guest:IsA("Model") or not guest.Parent then
		return false, "guest_not_found"
	end
	local folder = workspace:FindFirstChild("Guests")
	if not folder or not guest:IsDescendantOf(folder) then
		return false, "guest_not_found"
	end
	local ownerId = guest:GetAttribute("ServingUserId")
	local ownerName = guest:GetAttribute("ServingPlayer")
	if ownerId ~= nil then
		if ownerId ~= player.UserId then
			return false, "wrong_guest_owner"
		end
	elseif ownerName ~= player.Name then
		return false, "wrong_guest_owner"
	end
	if guest:GetAttribute("ServingState") == "settled" or guest:GetAttribute("SettlementLocked") then
		return false, "guest_already_settled"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local guestPart = guest:FindFirstChild("Torso") or guest:FindFirstChildWhichIsA("BasePart")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 or not guestPart then
		return false, "character_unavailable"
	end
	if (root.Position - guestPart.Position).Magnitude > MAX_SERVE_DISTANCE then
		return false, "too_far"
	end
	return true
end

local function selectQuality(data: any, recipe: string): string?
	local qualities = data.cooked_dishes and data.cooked_dishes[recipe]
	if type(qualities) == "table" then
		for _, quality in ipairs({ "perfect", "great", "ok" }) do
			if type(qualities[quality]) == "number" and qualities[quality] > 0 then
				return quality
			end
		end
	end
	-- Migration compatibility for dishes created before quality ownership.
	if type(data[recipe]) == "number" and data[recipe] > 0 then
		return "ok"
	end
	return nil
end

local function showDialogue(player: Player, guest: Instance, key: string, gold: number?)
	local meshType = guest:GetAttribute("MeshType")
	local dialogueData = require(ReplicatedStorage.ConfigurationFiles.VNDialogueData)
	local dialogue = dialogueData.GUEST_BY_TYPE[meshType]
	local text = dialogue and dialogue[key]
	local event = ReplicatedStorage.RemoteEvents:FindFirstChild("ShowVNDialogue")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "ShowVNDialogue"
		event.Parent = ReplicatedStorage.RemoteEvents
	end
	if type(text) == "string" and event and event:IsA("RemoteEvent") then
		if gold then
			text = text:gsub("{gold}", tostring(gold))
		end
		event:FireClient(player, "guest", text)
	end
end

function ServingService.serve(player: Player, guest: any, dishName: any): (boolean, string, any?)
	local now = os.clock()
	if now - (lastServeAt[player.UserId] or 0) < RATE_LIMIT then
		return false, "rate_limited"
	end
	lastServeAt[player.UserId] = now
	if type(dishName) ~= "string" or dishName == "" then
		return false, "invalid_dish"
	end
	local guestOk, guestReason = validGuest(player, guest)
	if not guestOk then
		return false, guestReason or "invalid_guest"
	end
	local recipe = guest:GetAttribute("PreferredRecipe")
	if type(recipe) ~= "string" or dishName ~= recipe then
		showDialogue(player, guest, "wrong_dish")
		return false, "wrong_dish"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "data_not_loaded"
	end
	local quality = selectQuality(data, recipe)
	if not quality then
		return false, "dish_not_owned"
	end

	guest:SetAttribute("SettlementLocked", true)
	local basePay = guest:GetAttribute("PayAmount")
	if type(basePay) ~= "number" or basePay <= 0 then
		basePay = 10
	end
	local qualityPay = math.floor(basePay * NPCConfig.getQualityMultiplier(quality))
	local challengeBonus = guest:GetAttribute("IsChallenge") and guest:GetAttribute("BonusGold") or 0
	if type(challengeBonus) ~= "number" or challengeBonus < 0 then
		challengeBonus = 0
	end
	local result = RewardCore.settle(player, {
		gold = qualityPay + challengeBonus,
		xp = ChefLevelConfig.xpRewards.serveGuest,
		reason = "serve",
		combo = true,
	}, function(current)
		local currentQuality = selectQuality(current, recipe)
		if currentQuality ~= quality then
			return false, "dish_changed"
		end
		if type(current[recipe]) ~= "number" or current[recipe] <= 0 then
			return false, "dish_not_owned"
		end
		current[recipe] -= 1
		if current[recipe] <= 0 then
			current[recipe] = nil
		end
		local qualities = current.cooked_dishes and current.cooked_dishes[recipe]
		if type(qualities) == "table" and type(qualities[quality]) == "number" and qualities[quality] > 0 then
			qualities[quality] -= 1
			if qualities[quality] <= 0 then
				qualities[quality] = nil
			end
			if next(qualities) == nil then
				current.cooked_dishes[recipe] = nil
			end
		end
		current.recipes_served_count = current.recipes_served_count or {}
		current.recipes_served_count[recipe] = (current.recipes_served_count[recipe] or 0) + 1
		current.guests_served = (current.guests_served or 0) + 1
		return true, { recipe = recipe, quality = quality }
	end)
	if not result.ok then
		guest:SetAttribute("SettlementLocked", nil)
		return false, result.reason or "settlement_failed"
	end

	guest:SetAttribute("ServingState", "settled")
	showDialogue(player, guest, "served", result.gold)
	PlayerDataService.checkAndUnlockTiers(player)
	local guestType = guest:GetAttribute("MeshType") or guest:GetAttribute("GuestType") or "normal"
	GuestService.removeGuestByInstance(guest, "served")
	ServingService.GuestServed:Fire(player, guestType, recipe, quality)
	return true, "served", { recipe = recipe, quality = quality, gold = result.gold, xp = result.xp }
end

function ServingService.onGuestTimeout(player: Player, guestType: string?)
	ServingService.GuestTimedOut:Fire(player, guestType or "default")
end

Players.PlayerRemoving:Connect(function(player)
	lastServeAt[player.UserId] = nil
end)

return ServingService
