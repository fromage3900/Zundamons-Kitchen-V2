--!strict
-- [[Script] ToolManager (ref: RBXF13773EEB02243D3A8E4B844862B0E21)]]
-- Handles tool equipping, inventory sync, and hotbar ObjectValues (AGENTS.md Rule 4 compliant).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPack = game:GetService("StarterPack")

local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")
local equipTool = RF:FindFirstChild("EquipTool")
if not equipTool then
	equipTool = Instance.new("RemoteFunction")
	equipTool.Name = "EquipTool"
	equipTool.Parent = RF
end

local configFiles = ReplicatedStorage:WaitForChild("ConfigurationFiles")
local toolsConfig = require(configFiles:WaitForChild("ToolsConfig"))
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local function initializePlayerData(player: Player)
	local data = PlayerDataService.getOrCreate(player)
	if not data.tools then
		data.tools = {
			Axe = { Tier = "Tier1", Equipped = false },
			PickAxe = { Tier = "Tier1", Equipped = false },
			Sickle = { Tier = "Tier1", Equipped = false },
		}
	end
end

local function isAllowedToolName(toolName: any): boolean
	return typeof(toolName) == "string" and toolsConfig.tools[toolName] ~= nil
end

local function handleEquipTool(player: Player, toolName: string): boolean
	if not isAllowedToolName(toolName) then
		return false
	end

	initializePlayerData(player)
	local data = PlayerDataService.get(player)
	if not data or not data.tools or not data.tools[toolName] then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)

	-- Move currently equipped tool back to Backpack cleanly without destroying it
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			if backpack then
				child.Parent = backpack
			end
		end
	end

	for _, toolData in pairs(data.tools) do
		toolData.Equipped = false
	end

	-- Check if player already has this tool in character or backpack
	local existingTool: Tool? = nil
	if character then
		local charTool = character:FindFirstChild(toolName)
		if charTool and charTool:IsA("Tool") then
			existingTool = charTool
		end
	end
	if not existingTool and backpack then
		local bpTool = backpack:FindFirstChild(toolName)
		if bpTool and bpTool:IsA("Tool") then
			existingTool = bpTool
		else
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and (item:GetAttribute("Type") == toolName or item.Name == toolName) then
					existingTool = item
					break
				end
			end
		end
	end

	if existingTool then
		existingTool.Parent = character
		data.tools[toolName].Equipped = true

		local equippedVal = player:FindFirstChild("Equipped")
		if equippedVal and equippedVal:IsA("ObjectValue") then
			equippedVal.Value = existingTool
		end
		return true
	end

	-- If tool not found in Backpack, clone from StarterPack or ReplicatedStorage
	local toolToClone: Tool? = nil
	for _, item in ipairs(StarterPack:GetChildren()) do
		if item:IsA("Tool") and (item.Name == toolName or item:GetAttribute("Type") == toolName) then
			toolToClone = item
			break
		end
	end
	if not toolToClone then
		local models = ReplicatedStorage:FindFirstChild("Models")
		if models then
			local item = models:FindFirstChild(toolName)
			if item and item:IsA("Tool") then
				toolToClone = item
			end
		end
	end

	if toolToClone then
		local clonedTool = toolToClone:Clone()
		for _, tag in ipairs(CollectionService:GetTags(toolToClone)) do
			CollectionService:AddTag(clonedTool, tag)
		end
		clonedTool.Parent = character
		data.tools[toolName].Equipped = true

		local equippedVal = player:FindFirstChild("Equipped")
		if equippedVal and equippedVal:IsA("ObjectValue") then
			equippedVal.Value = clonedTool
		end
		return true
	end

	return false
end

equipTool.OnServerInvoke = handleEquipTool

local function createDefaultTool(toolName: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool:SetAttribute("Type", toolName)
	tool:SetAttribute("Tier", "Tier1")
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.8, 3, 0.8)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(150, 100, 50)
	handle.Parent = tool

	CollectionService:AddTag(tool, "Tool")
	CollectionService:AddTag(tool, toolName)
	return tool
end

local function giveStarterTools(player: Player, character: Model)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return end

	local defaultTools = { "Axe", "PickAxe", "Sickle" }
	for _, toolName in ipairs(defaultTools) do
		local existing = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
		if not existing then
			local newTool = createDefaultTool(toolName)
			newTool.Parent = backpack
			print(string.format("[ToolManager] Granted starter tool '%s' to %s", toolName, player.Name))
		end
	end
end

local function onPlayerJoined(player: Player)
	initializePlayerData(player)
	if player.Character then
		giveStarterTools(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		giveStarterTools(player, char)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerJoined(player)
end

Players.PlayerAdded:Connect(onPlayerJoined)

print("[ToolManager] Loaded - tool equipping, auto-granting starter tools & inventory sync active")
