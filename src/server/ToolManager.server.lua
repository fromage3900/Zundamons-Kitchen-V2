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

	-- Handle (primary part, all other parts weld to this)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 2.5, 0.4)
	handle.Material = Enum.Material.Wood
	handle.Color = Color3.fromRGB(139, 90, 43)
	handle.Parent = tool

	-- Tool-specific parts, each welded to the Handle
	if toolName == "Axe" then
		local head = Instance.new("Part")
		head.Name = "AxeHead"
		head.Size = Vector3.new(1.2, 0.8, 0.3)
		head.Material = Enum.Material.Metal
		head.Color = Color3.fromRGB(180, 180, 190)
		head.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = head
		weld.Parent = head

		head.CFrame = handle.CFrame * CFrame.new(0, 1.4, 0)
	elseif toolName == "PickAxe" then
		local head = Instance.new("Part")
		head.Name = "PickHead"
		head.Size = Vector3.new(1.6, 0.5, 0.3)
		head.Material = Enum.Material.Metal
		head.Color = Color3.fromRGB(180, 180, 190)
		head.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = head
		weld.Parent = head

		head.CFrame = handle.CFrame * CFrame.new(0, 1.4, 0)

		local prongL = Instance.new("Part")
		prongL.Name = "PickProngL"
		prongL.Size = Vector3.new(0.15, 0.6, 0.15)
		prongL.Material = Enum.Material.Metal
		prongL.Color = Color3.fromRGB(160, 160, 170)
		prongL.Parent = tool

		local weldL = Instance.new("WeldConstraint")
		weldL.Part0 = head
		weldL.Part1 = prongL
		weldL.Parent = prongL
		prongL.CFrame = head.CFrame * CFrame.new(-0.6, 0, 0)

		local prongR = Instance.new("Part")
		prongR.Name = "PickProngR"
		prongR.Size = Vector3.new(0.15, 0.6, 0.15)
		prongR.Material = Enum.Material.Metal
		prongR.Color = Color3.fromRGB(160, 160, 170)
		prongR.Parent = tool

		local weldR = Instance.new("WeldConstraint")
		weldR.Part0 = head
		weldR.Part1 = prongR
		weldR.Parent = prongR
		prongR.CFrame = head.CFrame * CFrame.new(0.6, 0, 0)
	elseif toolName == "Sickle" then
		local blade = Instance.new("Part")
		blade.Name = "SickleBlade"
		blade.Size = Vector3.new(0.8, 0.15, 1.0)
		blade.Material = Enum.Material.Metal
		blade.Color = Color3.fromRGB(200, 200, 210)
		blade.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = blade
		weld.Parent = blade

		blade.CFrame = handle.CFrame * CFrame.new(0, 1.5, 0.3) * CFrame.Angles(0, 0, math.rad(30))

		local grip = Instance.new("Part")
		grip.Name = "Grip"
		grip.Size = Vector3.new(0.45, 0.6, 0.45)
		grip.Material = Enum.Material.Fabric
		grip.Color = Color3.fromRGB(100, 60, 30)
		grip.Parent = tool

		local weldG = Instance.new("WeldConstraint")
		weldG.Part0 = handle
		weldG.Part1 = grip
		weldG.Parent = grip
		grip.CFrame = handle.CFrame * CFrame.new(0, -0.8, 0)
	elseif toolName == "FishingRod" then
		local rod = Instance.new("Part")
		rod.Name = "Rod"
		rod.Size = Vector3.new(0.2, 3.5, 0.2)
		rod.Material = Enum.Material.Wood
		rod.Color = Color3.fromRGB(160, 120, 70)
		rod.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = rod
		weld.Parent = rod

		rod.CFrame = handle.CFrame * CFrame.new(0, 2.8, 0)

		local reel = Instance.new("Part")
		reel.Name = "Reel"
		reel.Size = Vector3.new(0.3, 0.3, 0.3)
		reel.Material = Enum.Material.Metal
		reel.Color = Color3.fromRGB(150, 150, 160)
		reel.Parent = tool

		local weldR = Instance.new("WeldConstraint")
		weldR.Part0 = handle
		weldR.Part1 = reel
		weldR.Parent = reel
		reel.CFrame = handle.CFrame * CFrame.new(0.3, -0.3, 0)

		local line = Instance.new("Part")
		line.Name = "Line"
		line.Size = Vector3.new(0.02, 2.0, 0.02)
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(255, 255, 255)
		line.Transparency = 0.3
		line.Parent = tool

		local weldL = Instance.new("WeldConstraint")
		weldL.Part0 = rod
		weldL.Part1 = line
		weldL.Parent = line
		line.CFrame = rod.CFrame * CFrame.new(0, 2.5, 0)
	end

	CollectionService:AddTag(tool, "Tool")
	CollectionService:AddTag(tool, toolName)
	return tool
end

local function giveStarterTools(player: Player, character: Model)
	print(string.format("[ToolManager] === giveStarterTools START for %s ===", player.Name))

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 5)
	end
	if not backpack then
		warn(string.format("[ToolManager] Could not find Backpack for %s", player.Name))
		return
	end

	print(string.format("[ToolManager] Backpack found. Current children:", player.Name))
	for _, child in ipairs(backpack:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
	end

	local allowedTools = { Axe = true, PickAxe = true, Sickle = true, FishingRod = true }

	-- Destroy ALL tools in backpack/character that aren't the 4 custom ones
	for _, existing in ipairs(backpack:GetChildren()) do
		if existing:IsA("Tool") and not allowedTools[existing.Name] then
			print(string.format("[ToolManager] Destroying non-custom tool: %s", existing.Name))
			existing:Destroy()
		end
	end
	if character then
		for _, existing in ipairs(character:GetChildren()) do
			if existing:IsA("Tool") and not allowedTools[existing.Name] then
				existing:Destroy()
			end
		end
	end

	-- Now ensure exactly one of each custom tool exists
	local defaultTools = { "Axe", "PickAxe", "Sickle", "FishingRod" }
	for _, toolName in ipairs(defaultTools) do
		local hasTool = false
		for _, existing in ipairs(backpack:GetChildren()) do
			if existing:IsA("Tool") and existing.Name == toolName then
				hasTool = true
				break
			end
		end
		if not hasTool and character then
			for _, existing in ipairs(character:GetChildren()) do
				if existing:IsA("Tool") and existing.Name == toolName then
					hasTool = true
					break
				end
			end
		end
		if not hasTool then
			print(string.format("[ToolManager] Creating tool: %s", toolName))
			local newTool = createDefaultTool(toolName)
			if newTool then
				newTool.Parent = backpack
				print(string.format("[ToolManager] Tool '%s' parented to backpack", toolName))
			end
		else
			print(string.format("[ToolManager] Tool '%s' already exists, skipping", toolName))
		end
	end

	print(string.format("[ToolManager] Final backpack children:", player.Name))
	for _, child in ipairs(backpack:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
	end

	-- Assign tools to hotbar slots so they appear in the player's toolbar.
	local function assignToHotbar()
		local hotbar = player:FindFirstChild("Hotbar")
		if not hotbar then
			return false
		end
		local slotIndex = 1
		for _, toolName in ipairs(defaultTools) do
			local tool = backpack:FindFirstChild(toolName)
			if tool and slotIndex <= 9 then
				local slot = hotbar:FindFirstChild(tostring(slotIndex))
				if slot and slot:IsA("ObjectValue") then
					slot.Value = tool
					print(string.format("[ToolManager] Assigned %s to hotbar slot %d", toolName, slotIndex))
				end
				slotIndex = slotIndex + 1
			end
		end
		return true
	end

	if not assignToHotbar() then
		task.spawn(function()
			for i = 1, 10 do
				task.wait(0.5)
				if assignToHotbar() then
					break
				end
			end
		end)
	end

	print(string.format("[ToolManager] === giveStarterTools END for %s ===", player.Name))
end

local function onPlayerJoined(player: Player)
	initializePlayerData(player)

	-- Helper to grant tools when character is ready
	local function grantTools()
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return
		end
		giveStarterTools(player, char)
	end

	-- Grant tools on initial spawn (if character already exists)
	if player.Character then
		task.spawn(grantTools)
	end

	-- Grant tools on every respawn
	player.CharacterAdded:Connect(function(char)
		task.spawn(grantTools)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerJoined(player)
end

Players.PlayerAdded:Connect(onPlayerJoined)

print("[ToolManager] Loaded - tool equipping, auto-granting starter tools & inventory sync active")
