-- [[Script] ZundaGatherServer (ref: RBX382D14910F4C466898CDB20D388810EF)]]
-- ZundaGatherServer: Click-to-gather for Zunda forest plants and mystery loot
-- Lives at ServerScriptService.Garden.ZundaGatherServer

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenS = game:GetService("TweenService")

local lootMod = require(RS.ConfigurationFiles.LootModule)
if not lootMod then
	warn("[ZundaGatherServer] LootModule not found — gather disabled")
	return {}
end

local GrowthStageConfig = require(RS.ConfigurationFiles.GrowthStageConfig)
local GatherConfig = require(RS.ConfigurationFiles.GatherConfig)
local ResourceVisualService = require(SSS.Services.ResourceVisualService)

-- HarvestValidator for server-side validation (distance, rate limit, cooldown)
local validateHarvest
local ok, hvMod = pcall(require, SSS.Validation.HarvestValidator)
if ok and hvMod then
	validateHarvest = hvMod.validateHarvest
end

local RE_notify = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("NotifyPlayer")
local RE_SideDlg = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("TriggerSideDialogue")
local PlayerDataService = require(SSS.Services.PlayerDataService)
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)

-- Pop notification
local function notify(player, message)
	if RE_notify then
		RE_notify:FireClient(player, "gather_success", message)
	else
		local notifEvent = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("NotificationEvent")
		if notifEvent and notifEvent:IsA("RemoteEvent") then
			notifEvent:FireClient(player, message)
		end
	end
end

-- Companion extra_drop buff (Antimon): 20% chance for bonus item
local function applyExtraDropBuff(player, baseItems)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	local active = data.active_companion
	if not active then
		return
	end
	local def = CompanionConfig.companions[active]
	if not def or not def.buff then
		return
	end
	if def.buff.stat ~= "extra_drop" then
		return
	end
	if def.buff.magnitude <= 0 then
		return
	end
	if math.random() > def.buff.magnitude then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local bonus = { baseItems[math.random(#baseItems)] }
	lootMod.generateLoot(player, bonus, hrp.Position)
	notify(player, "🍀 Antimon found a bonus " .. bonus[1] .. "!")
end

-- Respawn timing (seconds) — Mystery + Carrot keep bespoke values; simple
-- click resources now read respawnSeconds straight from GatherConfig.
local RESPAWN_MYSTERY = 90

-- The live world was authored with a generic ResourceType="flower" on ~8
-- harvestable flower nodes, but GatherConfig/the grant handler speak canonical
-- names ("ZundaFlower" etc). Without this alias every flower click validated,
-- passed distance/availability checks, then fell through the grant branch and
-- granted nothing — the "flowers not pickable" bug. Map legacy generic tokens
-- to their canonical GatherConfig key here.
local RESOURCE_ALIASES = {
	flower = "ZundaFlower",
	pea = "ZundaPea",
	leaf = "ZundaLeaf",
}

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
end

-- Update node mesh based on growth stage
local function updateNodeMesh(node, stageIndex)
	local rtype = node:GetAttribute("ResourceType")
	if rtype ~= "CarrotPlot" then
		return
	end -- Only for CarrotPlot nodes

	local stages = GrowthStageConfig.getStages("CarrotPlot")
	if not stages or not stages[stageIndex] then
		return
	end

	local stage = stages[stageIndex]
	node:SetAttribute("VisualVariant", stage.name)
	node:SetAttribute("VisualScale", Vector3.new(stage.scale, stage.scale, stage.scale))
	ResourceVisualService.apply(node, GrowthStageConfig.getDescriptor(stage))
	node:SetAttribute("GrowthStage", stageIndex)
	node:SetAttribute("GrowthStageName", stage.name)
end

-- Hide the node visually + re-enable after respawn
local function consumeNode(node, respawnSec)
	if node:GetAttribute("Available") == false then
		return
	end
	node:SetAttribute("Available", false)
	ResourceVisualService.setVisible(node, false)
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
		ResourceVisualService.setVisible(node, true)
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
end

local RE_Harvest = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("HarvestNode")
if RE_Harvest then
	RE_Harvest.OnServerEvent:Connect(function(player, node)
		if typeof(node) ~= "Instance" or not node:IsA("BasePart") then
			return
		end
		if not node:GetAttribute("ResourceType") then
			return
		end

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
		local rawType = node:GetAttribute("ResourceType")
		local rtype = RESOURCE_ALIASES[rawType] or rawType

		-- Check first-time gather for side dialogue
		local d = PlayerDataService.get(player)
		local had_before = d and d.gathered_items or {}

		if rtype == "MysteryLoot" then
			local items = {}
			local n = math.random(2, 3)
			for i = 1, n do
				table.insert(items, GatherConfig.mysteryLoot[math.random(1, #GatherConfig.mysteryLoot)])
			end
			grantItems(player, items)
			applyExtraDropBuff(player, items)
			notify(player, "✨ Mystery loot found!")
			consumeNode(node, RESPAWN_MYSTERY)
		elseif GatherConfig.getClickResource(rtype) then
			-- Data-driven grant for every simple click resource (ZundaFlower,
			-- ZundaPea, PeaFlower, SweetPea, EdamamePod, ZundaLeaf, SaltedPeaBouquet…).
			local res = GatherConfig.getClickResource(rtype)
			local yield = node:GetAttribute("Yield") or res.defaultYield
			local items = {}
			for i = 1, yield do
				table.insert(items, res.itemName)
			end
			grantItems(player, items)
			applyExtraDropBuff(player, items)
			notify(player, res.notifyEmoji .. " +" .. yield .. " " .. res.itemName)
			if rtype == "ZundaFlower" and not had_before[res.itemName] and RE_SideDlg then
				pcall(function()
					RE_SideDlg:FireClient(player, "zunda_flower")
				end)
			end
			consumeNode(node, res.respawnSeconds)
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
				applyExtraDropBuff(player, items)
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

-- Bind every gathering node in the workspace. Nodes are NOT confined to one
-- folder — the live world has them scattered across `Loop.GameplayLoopArea`,
-- `Folder.house 2`, and elsewhere, while the (empty) top-level
-- `GameplayLoopArea.GatheringNodes` is what the old scan watched, so nothing
-- was ever bound (no _origSize for respawn, no CarrotPlot growth init). A
-- one-time workspace-wide scan is correct here since these are baked instances.
local function isGatherNode(inst)
	return inst:IsA("BasePart")
		and inst:GetAttribute("ResourceType") ~= nil
		and inst:FindFirstChildOfClass("ClickDetector") ~= nil
end

for _, node in ipairs(workspace:GetDescendants()) do
	if isGatherNode(node) then
		bindNode(node)
	end
end

-- Catch nodes added later (e.g. SceneSetup rebuilds). Cheap attribute guard,
-- early-returns on the vast majority of descendant additions.
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") then
		task.defer(function()
			if desc.Parent and isGatherNode(desc) then
				bindNode(desc)
			end
		end)
	end
end)

print("[ZundaGatherServer] Ready - click-to-gather active (with HarvestValidator)")
