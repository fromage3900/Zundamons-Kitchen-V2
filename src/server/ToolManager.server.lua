-- [[Script] ToolManager (ref: RBXF13773EEB02243D3A8E4B844862B0E21)]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local RF = RS:WaitForChild("RemoteFunctions")
local equipTool = RF:WaitForChild("EquipTool")

local configFiles = RS:WaitForChild("ConfigurationFiles")
local toolsConfig = require(configFiles:WaitForChild("ToolsConfig"))
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local function initializePlayerData(player)
	local data = PlayerDataService.getOrCreate(player)
	if not data.tools then
		data.tools = {
			Axe = { Tier = "Tier1", Equiped = false },
			PickAxe = { Tier = "Tier1", Equiped = false },
			Sickle = { Tier = "Tier1", Equiped = false },
		}
	end
end

local function isAllowedToolName(toolName: any): boolean
	return typeof(toolName) == "string" and toolsConfig.tools[toolName] ~= nil
end

local function handleEquipTool(player, toolName)
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

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	for _, toolData in pairs(data.tools) do
		toolData.Equiped = false
	end

	local toolToClone = nil
	for _, item in ipairs(game.StarterPack:GetChildren()) do
		if item:IsA("Tool") and item:GetAttribute("Type") == toolName then
			toolToClone = item
			break
		end
	end

	if toolToClone then
		local clonedTool = toolToClone:Clone()
		for _, tag in ipairs(CollectionService:GetTags(toolToClone)) do
			CollectionService:AddTag(clonedTool, tag)
		end
		clonedTool.Parent = character
		data.tools[toolName].Equiped = true
		return true
	end

	return false
end

equipTool.OnServerInvoke = handleEquipTool

for _, player in ipairs(Players:GetPlayers()) do
	initializePlayerData(player)
end

Players.PlayerAdded:Connect(initializePlayerData)
