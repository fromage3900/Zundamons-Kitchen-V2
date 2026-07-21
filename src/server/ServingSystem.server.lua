-- [[Script] ServingSystem (ref: RBX443AAD921E174D02B4630B6A7D249A5C)]]
-- Handles click-to-serve interactions with guests.

local Players = game:GetService("Players")

local configFolder = game.ReplicatedStorage:FindFirstChild("ConfigurationFiles")
if not configFolder then configFolder = game.ReplicatedStorage:WaitForChild("ConfigurationFiles", 10) end
local CONFIG = configFolder and require(configFolder:WaitForChild("ProgressionConfig", 10))
if not CONFIG then warn("[ServingSystem] ProgressionConfig not found"); return {} end
local NPCConfig = require(game.ReplicatedStorage.Shared.Config.NPCConfig)
local RF = game.ReplicatedStorage:FindFirstChild("RemoteFunctions") or game.ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
local serveGuestRF = RF and RF:FindFirstChild("ServeGuest") or RF:WaitForChild("ServeGuest", 10)
local RewardCore = require(game.ReplicatedStorage.ConfigurationFiles.RewardCore)
local ChefLevelConfig = configFolder and require(configFolder:WaitForChild("ChefLevelConfig", 10))
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local GuestService = require(script.Parent.Services.GuestService)

local MAX_SERVE_DISTANCE = 20

local function isValidGuest(guestInstance)
	if not guestInstance or not guestInstance.Parent then
		return false
	end
	local guestsFolder = workspace:FindFirstChild("Guests")
	if not guestsFolder then
		return false
	end
	return guestInstance:IsDescendantOf(guestsFolder)
end

local function playerNearGuest(player, guestInstance)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local guestPart = guestInstance:FindFirstChild("Torso") or guestInstance:FindFirstChildWhichIsA("BasePart")
	if not root or not guestPart then
		return false
	end
	return (root.Position - guestPart.Position).Magnitude <= MAX_SERVE_DISTANCE
end

-- Rate limit
local lastServe = {}
local function rateLimited(player)
	local now = os.clock()
	if lastServe[player] and now - lastServe[player] < 0.2 then
		return true
	end
	lastServe[player] = now
	return false
end

local function lookupPayAmount(recipe, guestAttributePay)
	if typeof(guestAttributePay) == "number" and guestAttributePay > 0 then
		return guestAttributePay
	end
	return 10
end

local function handleServeGuest(player, guestInstance, foodItemName, quality)
	if rateLimited(player) then
		return false, "Too fast"
	end

	if typeof(foodItemName) ~= "string" then
		return false, "Invalid food item"
	end

	if not isValidGuest(guestInstance) then
		return false, "Guest not found"
	end

	if not playerNearGuest(player, guestInstance) then
		return false, "Too far from guest"
	end

	local playerData = PlayerDataService.get(player)
	if not playerData then
		return false, "Player data not found"
	end

	local recipe = guestInstance:GetAttribute("PreferredRecipe")
	local payAmount = lookupPayAmount(recipe, guestInstance:GetAttribute("PayAmount"))

	-- Apply quality multiplier to pay amount
	if quality then
		local qualityMultiplier = NPCConfig.getQualityMultiplier(quality)
		payAmount = math.floor(payAmount * qualityMultiplier)
	end

    if foodItemName ~= recipe then
        print("[ServingSystem] " .. player.Name .. " tried to serve " .. foodItemName .. " but guest wanted " .. tostring(recipe))
        
        -- Trigger VN dialogue for wrong dish
        local meshType = guestInstance:GetAttribute("MeshType")
        local VNDialogueData = require(game.ReplicatedStorage.ConfigurationFiles.VNDialogueData)
        local dialogue = VNDialogueData.GUEST_BY_TYPE[meshType]
        if dialogue then
            local VNEvent = game.ReplicatedStorage.RemoteEvents:FindFirstChild("ShowVNDialgue")
            if VNEvent then
                VNEvent:FireClient(player, "guest", dialogue.wrong_dish)
            end
        end
        
        return false, "Wrong food! Guest wants " .. tostring(recipe)
    end

	if not playerData[foodItemName] or playerData[foodItemName] <= 0 then
		return false, "You don't have " .. foodItemName
	end

	playerData[foodItemName] = playerData[foodItemName] - 1
	if playerData[foodItemName] == 0 then
		playerData[foodItemName] = nil
	end

	RewardCore.bumpCombo(player)
	local awarded = RewardCore.addGold(player, payAmount, "serve")
	payAmount = awarded
	local isChallenge = guestInstance:GetAttribute("IsChallenge") or false
	if isChallenge then
		local bonus = guestInstance:GetAttribute("BonusGold") or 0
		if bonus > 0 then
			RewardCore.addGold(player, bonus, "challenge_bonus")
			payAmount = payAmount + bonus
		end
	end
	RewardCore.addXP(player, ChefLevelConfig.xpRewards.serveGuest, "serve")
	RewardCore.notify(player, "serve", { recipe = recipe, guestName = guestInstance.Name, gold = awarded })

	if not playerData.recipes_served_count then
		playerData.recipes_served_count = {}
	end

	if not playerData.recipes_served_count[recipe] then
		playerData.recipes_served_count[recipe] = 1
	else
		playerData.recipes_served_count[recipe] = playerData.recipes_served_count[recipe] + 1
	end

	playerData.guests_served = (playerData.guests_served or 0) + 1
	playerData.total_gold_earned = (playerData.total_gold_earned or 0) + payAmount

    print(
        "[ServingSystem] " .. player.Name .. " served guest " .. recipe .. " (+" .. payAmount .. " gold, total guests: " .. playerData.guests_served .. ")"
    )

    -- Trigger VN dialogue for successful serve
    local meshType = guestInstance:GetAttribute("MeshType")
    local VNDialogueData = require(game.ReplicatedStorage.ConfigurationFiles.VNDialogueData)
    local dialogue = VNDialogueData.GUEST_BY_TYPE[meshType]
    if dialogue then
        local text = dialogue.served:gsub("{gold}", tostring(payAmount))
        local VNEvent = game.ReplicatedStorage.RemoteEvents:FindFirstChild("ShowVNDialgue")
        if VNEvent then
            VNEvent:FireClient(player, "guest", text)
        end
    end

    PlayerDataService.checkAndUnlockTiers(player)
    GuestService.removeGuestByInstance(guestInstance, "served")

	return true, "Served! +" .. payAmount .. " gold"
end

serveGuestRF.OnServerInvoke = handleServeGuest

print("[ServingSystem] Started")