-- [[ModuleScript] LootModule (ref: RBX4573179EFA054EED872412F08A8A6EF4)]]
local loot_module = {}
local RS = game.ReplicatedStorage
local RE = RS:WaitForChild("RemoteEvents", 10)
local RF = RS:WaitForChild("RemoteFunctions", 10)
local loot = RS:WaitForChild("Loot", 10)
if not RE or not RF or not loot then
	warn("[LootModule] Core folders not found — loot disabled")
	return { GiveLoot = function() return false end, generateLoot = function() end, lootMaker = function() return {} end }
end
local give_loot = RF:WaitForChild("GiveLoot", 10)
local removeCode = RE:WaitForChild("RemoveCode", 10)
local MakeLootEvent = RE:WaitForChild("MakeLootEvent", 10)
local finalLoots = loot:GetChildren()
local sellLoot = RF:WaitForChild("sellLoot", 10)
local configFiles = RS:WaitForChild("ConfigurationFiles", 10)
local mineableConfig = configFiles and require(configFiles:WaitForChild("MineableConfig", 10))
local priceLists = mineableConfig and mineableConfig.priceLists or {}

local PlayerDataService = require(game.ServerScriptService.Services.PlayerDataService)

local RewardCore = require(game.ReplicatedStorage.ConfigurationFiles.RewardCore)
local ChefLevelConfig = configFiles and require(configFiles:WaitForChild("ChefLevelConfig", 10))

local codes: { [string]: { { string } } } = {}
local sellTimestamps: { [string]: { number } } = {}
local MAX_SELLS_PER_SECOND = 5

local function validateRateLimit(player: Player): boolean
	local now = tick()
	local timestamps = sellTimestamps[player.Name] or {}
	local recent = {}
	for _, ts in ipairs(timestamps) do
		if now - ts <= 1 then
			table.insert(recent, ts)
		end
	end
	if #recent >= MAX_SELLS_PER_SECOND then
		return false
	end
	table.insert(recent, now)
	sellTimestamps[player.Name] = recent
	return true
end

function handleOreSell(player, item)
	if typeof(item) ~= "string" or not priceLists[item] then
		return false
	end
	if not validateRateLimit(player) then
		return false
	end

	local data = PlayerDataService.get(player)
	if not data or not data[item] then
		return false
	end

	local total = priceLists[item] * data[item]
	data[item] = nil
	total = RewardCore.addGold(player, total, "sell")
	return data.gold or 0
end

function loot_module.eraseData(player)
	codes[player.Name] = nil
	sellTimestamps[player.Name] = nil
end

function searchforCode(player, genCode, name, isRemoving)
	local list = codes[player.Name]
	if list then
		for i = 1, #list do
			if genCode == list[i][1] and name == list[i][2] then
				if isRemoving then
					table.remove(list, i)
					break
				end
				return true
			end
		end
	end
	return false
end

function assignLoot(player, lootname, myloot)
	local value = myloot:GetAttribute("Value")
	local data = PlayerDataService.getOrCreate(player)
	if not data[lootname] then
		data[lootname] = value
	else
		data[lootname] = data[lootname] + value
	end
	RewardCore.addXP(player, ChefLevelConfig.xpRewards.gather, "gather")
	local popupEvt = game.ReplicatedStorage:FindFirstChild("RewardEvents")
		and game.ReplicatedStorage.RewardEvents:FindFirstChild("PopupEvent")
	if popupEvt then
		popupEvt:FireClient(player, "item", "+" .. value .. " " .. lootname, Color3.fromRGB(160, 240, 170))
	end
	local extraChance = RewardCore.companionBuff and RewardCore.companionBuff(player, "extra_drop") or 0
	if extraChance > 0 and math.random() < extraChance then
		data[lootname] = (data[lootname] or 0) + value
		if popupEvt then
			popupEvt:FireClient(player, "bonus", "✨ " .. lootname .. " ×2 (Antimon!)", Color3.fromRGB(180, 240, 200))
		end
	end
	RewardCore.notify(player, "gather", { item = lootname, count = value })
	return true
end

function loot_module.GiveLoot(player, lootname, genCode)
	if typeof(lootname) ~= "string" or typeof(genCode) ~= "string" then
		return false
	end
	if genCode and player and lootname then
		local myloot = loot:FindFirstChild(lootname)
		local exists = searchforCode(player, genCode, lootname, false)
		if exists and myloot then
			return assignLoot(player, lootname, myloot)
		end
	end
	return false
end

function StoreCode(player, mycode, name)
	local playerName = player.Name
	if codes[playerName] then
		table.insert(codes[playerName], { mycode, name })
	else
		codes[playerName] = { { mycode, name } }
	end
end

function loot_module.lootMaker(totalLoot)
	local selLoot = {}
	for i = 1, totalLoot do
		local obj = finalLoots[math.random(1, #finalLoots)]
		table.insert(selLoot, obj.Name)
	end
	return selLoot
end

function loot_module.generateLoot(player, loottable, position, quality)
	-- quality: optional string ("perfect", "great", "ok") for crafted food
	for i = 1, #loottable do
		local generatedCode = tick() .. "" .. math.random(600, 10000000)
		local obj = loottable[i]
		StoreCode(player, generatedCode, obj)
		MakeLootEvent:FireClient(player, obj, position, generatedCode, quality)
	end
end

removeCode.OnServerEvent:Connect(function(player, genCode, name, isRemoving)
	searchforCode(player, genCode, name, isRemoving == true)
end)

give_loot.OnServerInvoke = loot_module.GiveLoot
sellLoot.OnServerInvoke = handleOreSell

return loot_module
