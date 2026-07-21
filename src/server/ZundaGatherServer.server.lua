-- [[Script] ZundaGatherServer (ref: RBX382D14910F4C466898CDB20D388810EF)]]
-- ZundaGatherServer: Click-to-gather for Zunda forest plants and mystery loot
-- Lives at ServerScriptService.Garden.ZundaGatherServer

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenS = game:GetService("TweenService")

local lootMod = require(game.ReplicatedStorage.ConfigurationFiles.LootModule)
if not lootMod then
	warn("[ZundaGatherServer] LootModule not found — gather disabled")
	return {}
end

local GrowthStageConfig = require(game.ReplicatedStorage.ConfigurationFiles.GrowthStageConfig)

-- HarvestValidator for server-side validation (distance, rate limit, cooldown)
local HarvestValidator = SSS:FindFirstChild("Validation") and SSS.Validation:FindFirstChild("HarvestValidator")
local validateHarvest = HarvestValidator and require(HarvestValidator).validateHarvest

local RE_notify = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("NotifyPlayer")
local RE_SideDlg = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("TriggerSideDialogue")

-- Respawn timing (seconds)
local RESPAWN_FLOWER = 25
local RESPAWN_BOUQUET = 45
local RESPAWN_PEA = 35
local RESPAWN_MUSHROOM = 25
local RESPAWN_BERRY = 20
local RESPAWN_ROOT = 22
local RESPAWN_MYSTERY = 90

-- Mystery loot table
local MYSTERY_LOOT = {
	"Zunda Flower",
	"Zunda Flower",
	"Zunda Pea",
	"Zunda Pea",
	"Gold Ore",
	"Marble Rock",
	"Apple",
	"Wheat",
}

-- Grant items to player using LootModule
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local function grantItems(player, items)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	-- generateLoot signature: (player, lootTable, position)
	pcall(function()
		lootMod.generateLoot(player, items, hrp.Position)
	end)
	-- Track unique gathered items for quest system
	PlayerDataService.update(player, function(d)
		if not d.gathered_items then d.gathered_items = {} end
		for _, item in ipairs(items) do
			d.gathered_items[item] = true
		end
	end)
end

-- Pop notification
local function notify(player, message)
	if RE_notify then
		RE_notify:FireClient(player, "gather_success", message)
	end
end

-- Update node mesh based on growth stage
local function updateNodeMesh(node, stageIndex)
	local rtype = node:GetAttribute("ResourceType")
	if rtype ~= "CarrotPlot" then return end -- Only for CarrotPlot nodes
	
	local stages = GrowthStageConfig.getStages("CarrotPlot")
	if not stages or not stages[stageIndex] then return end
	
	local stage = stages[stageIndex]
	local meshId = GrowthStageConfig.getMeshId(stage)
	
	if meshId ~= "" and node:IsA("MeshPart") then
		node.MeshId = meshId
		node.Size = Vector3.new(2, 2, 2) * stage.scale
		node:SetAttribute("GrowthStage", stageIndex)
		node:SetAttribute("GrowthStageName", stage.name)
	end
end

-- Hide the node visually + re-enable after respawn
local function consumeNode(node, respawnSec)
	node:SetAttribute("Available", false)
	local cd = node:FindFirstChildOfClass("ClickDetector")
	if cd then
		cd.MaxActivationDistance = 0
	end
	-- Fade out
	local origTransparency = node.Transparency
	local tween = TweenS:Create(node, TweenInfo.new(0.4), { Transparency = 1, Size = node.Size * 0.4 })
	tween:Play()
	-- Schedule respawn
	task.delay(respawnSec, function()
		if not node.Parent then
			return
		end
		node:SetAttribute("Available", true)
		node.Size = node:GetAttribute("_origSize") or node.Size
		local back = TweenS:Create(node, TweenInfo.new(0.4), { Transparency = origTransparency })
		back:Play()
		if cd then
			cd.MaxActivationDistance = 16
		end
	end)
end

local function bindNode(node)
	local cd = node:FindFirstChildOfClass("ClickDetector")
	if not cd then
		return
	end
	-- Store original size for respawn
	node:SetAttribute("_origSize", node.Size)
	
	-- Initialize CarrotPlot growth stage
	if node:GetAttribute("ResourceType") == "CarrotPlot" then
		local currentStage = node:GetAttribute("GrowthStage") or 1
		updateNodeMesh(node, currentStage)
	end

	cd.MouseClick:Connect(function(player)
		-- Validate harvest (distance, rate limit, cooldown)
		if validateHarvest then
			local valid, err = validateHarvest(player, node)
			if not valid then
				return
			end
		end

		if not node:GetAttribute("Available") then
			return
		end
		local rtype = node:GetAttribute("ResourceType")

		-- Check first-time gather for side dialogue
		local d = PlayerDataService.get(player)
		local had_before = d and d.gathered_items or {}

		if rtype == "ZundaFlower" then
			local yield = node:GetAttribute("Yield") or 3
			local items = {}
			for i = 1, yield do
				table.insert(items, "Zunda Flower")
			end
			grantItems(player, items)
			notify(player, "🌼 +" .. yield .. " Zunda Flower")
			if not had_before["Zunda Flower"] and RE_SideDlg then
				pcall(function() RE_SideDlg:FireClient(player, "zunda_flower") end)
			end
			consumeNode(node, RESPAWN_FLOWER)
		elseif rtype == "ZundaPea" then
			local yield = node:GetAttribute("Yield") or 2
			local items = {}
			for i = 1, yield do
				table.insert(items, "Zunda Pea")
			end
			grantItems(player, items)
			notify(player, "🝒 +" .. yield .. " Zunda Pea")
			consumeNode(node, RESPAWN_PEA)
		elseif rtype == "Zunda Mushroom" then
			local yield = node:GetAttribute("Yield") or 3
			local items = {}
			for i = 1, yield do
				table.insert(items, "Zunda Mushroom")
			end
			grantItems(player, items)
			notify(player, "🝄 +" .. yield .. " Zunda Mushroom")
			if not had_before["Zunda Mushroom"] and RE_SideDlg then
				pcall(function() RE_SideDlg:FireClient(player, "zunda_mushroom") end)
			end
			consumeNode(node, RESPAWN_MUSHROOM)
		elseif rtype == "Zunda Berry" then
			local yield = node:GetAttribute("Yield") or 4
			local items = {}
			for i = 1, yield do
				table.insert(items, "Zunda Berry")
			end
			grantItems(player, items)
			notify(player, "🝓 +" .. yield .. " Zunda Berry")
			if not had_before["Zunda Berry"] and RE_SideDlg then
				pcall(function() RE_SideDlg:FireClient(player, "zunda_berry") end)
			end
			consumeNode(node, RESPAWN_BERRY)
		elseif rtype == "Zunda Root" then
			local yield = node:GetAttribute("Yield") or 3
			local items = {}
			for i = 1, yield do
				table.insert(items, "Zunda Root")
			end
			grantItems(player, items)
			notify(player, "🥜 +" .. yield .. " Zunda Root")
			if not had_before["Zunda Root"] and RE_SideDlg then
				pcall(function() RE_SideDlg:FireClient(player, "zunda_root") end)
			end
			consumeNode(node, RESPAWN_ROOT)
		elseif rtype == "MysteryLoot" then
			local items = {}
			local n = math.random(2, 3)
			for i = 1, n do
				table.insert(items, MYSTERY_LOOT[math.random(1, #MYSTERY_LOOT)])
			end
			grantItems(player, items)
			notify(player, "✨ Mystery loot found!")
			consumeNode(node, RESPAWN_MYSTERY)
		elseif rtype == "SaltedPeaBouquet" then
			local yield = node:GetAttribute("Yield") or 1
			local items = {}
			for i = 1, yield do
				table.insert(items, "Salted Pea Bouquet")
			end
			grantItems(player, items)
			notify(player, "💐 +" .. yield .. " Salted Pea Bouquet")
			consumeNode(node, RESPAWN_BOUQUET)
		elseif rtype == "CarrotPlot" then
			-- CarrotPlot uses growth stages
			local currentStage = node:GetAttribute("GrowthStage") or 1
			local stages = GrowthStageConfig.getStages("CarrotPlot")
			
			-- Check if harvestable (final stage)
			if stages[currentStage] and stages[currentStage].harvestable then
				local yield = node:GetAttribute("Yield") or 3
				local items = {}
				for i = 1, yield do
					table.insert(items, "Carrot")
				end
				grantItems(player, items)
				notify(player, "🥕 +" .. yield .. " Carrot")
				
				-- Reset to first stage instead of hiding
				updateNodeMesh(node, 1)
				node:SetAttribute("Available", true)
			else
				-- Grow to next stage
				local nextStage = currentStage + 1
				if stages[nextStage] then
					updateNodeMesh(node, nextStage)
					notify(player, "🌱 Carrot grew to " .. stages[nextStage].name .. " stage")
				end
			end
		end
	end)
end

-- Bind every gathering node in the GameplayLoopArea
local function scanFolder(folder)
	for _, node in ipairs(folder:GetDescendants()) do
		if
			node:IsA("BasePart")
			and node:GetAttribute("ResourceType")
			and node:FindFirstChildOfClass("ClickDetector")
		then
			bindNode(node)
		end
	end
end

local loopArea = workspace:WaitForChild("GameplayLoopArea", 10)
if loopArea then
	local loopGather = loopArea:WaitForChild("GatheringNodes", 5)
	if loopGather then
		scanFolder(loopGather)
		-- Bind new nodes that get added (e.g. SceneSetup rebuilds)
		loopGather.ChildAdded:Connect(function(child)
			task.wait(0.1)
			if
				child:IsA("BasePart")
				and child:GetAttribute("ResourceType")
				and child:FindFirstChildOfClass("ClickDetector")
			then
				bindNode(child)
			end
		end)
	end
end

print("[ZundaGatherServer] Ready - click-to-gather active (with HarvestValidator)")
