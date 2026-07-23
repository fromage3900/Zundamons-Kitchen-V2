local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local DailyQuestConfig = require(RS.ConfigurationFiles.DailyQuestConfig)
local PlayerDataService = require(SSS.Services.PlayerDataService)
local RewardCore = require(SSS.Services.RewardCore)

local RE = RS:WaitForChild("RemoteEvents")
local DailyDataEvent = RE:FindFirstChild("DailyDataEvent") or Instance.new("RemoteEvent", RE)
DailyDataEvent.Name = "DailyDataEvent"
local ClaimDailyVisitor = RE:FindFirstChild("ClaimDailyVisitor") or Instance.new("RemoteEvent", RE)
ClaimDailyVisitor.Name = "ClaimDailyVisitor"

local function dayNumber()
	return math.floor(os.time() / 86400)
end

local function ensureDailyData(d)
	d.daily = d.daily or {}
	d.daily.visitorClaimed = d.daily.visitorClaimed or false
	d.daily.resourcesHarvested = d.daily.resourcesHarvested or 0
	d.daily.lastCheckDay = d.daily.lastCheckDay or 0
end

local function sendDailyData(player)
	local d = PlayerDataService.get(player)
	if not d then return end
	ensureDailyData(d)
	local today = dayNumber()
	if d.daily.lastCheckDay ~= today then
		d.daily.visitorClaimed = false
		d.daily.resourcesHarvested = 0
		d.daily.lastCheckDay = today
	end
	DailyDataEvent:FireClient(player, {
		visitorClaimed = d.daily.visitorClaimed,
		resourcesHarvested = d.daily.resourcesHarvested,
		maxResources = DailyQuestConfig.dailyResources and #DailyQuestConfig.dailyResources or 0,
		visitorName = DailyQuestConfig.dailyVisitor.npcName,
	})
end

local RequestDailyData = RE:FindFirstChild("RequestDailyData") or Instance.new("RemoteEvent", RE)
RequestDailyData.Name = "RequestDailyData"
RequestDailyData.OnServerEvent:Connect(function(player)
	sendDailyData(player)
end)

ClaimDailyVisitor.OnServerEvent:Connect(function(player)
	local d = PlayerDataService.get(player)
	if not d then return end
	ensureDailyData(d)
	if d.daily.visitorClaimed then return end
	local today = dayNumber()
	if d.daily.lastCheckDay ~= today then
		d.daily.visitorClaimed = false
		d.daily.resourcesHarvested = 0
		d.daily.lastCheckDay = today
	end
	d.daily.visitorClaimed = true
	local v = DailyQuestConfig.dailyVisitor
	RewardCore.addGold(player, v.reward.gold, "visitor")
	RewardCore.addXP(player, v.reward.xp, "visitor")
	if v.reward.item then
		local data = PlayerDataService.get(player)
		if data then
			data[v.reward.item] = (data[v.reward.item] or 0) + 1
		end
	end
	RewardCore.notify(player, "serve", { gold = v.reward.gold, guestName = v.npcName })
	sendDailyData(player)
end)

local function onCharacterAdded(player)
	task.wait(2)
	sendDailyData(player)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	coroutine.wrap(function()
		task.wait(3)
		sendDailyData(player)
	end)()
end

print("[DailyController] online")
