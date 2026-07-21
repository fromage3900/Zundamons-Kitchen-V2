--!strict
-- [[LocalScript] ToolClient (ref: RBX90F4027250BB4E6CBBBDE286ADDB17BF)]]
-- Dynamic client tool listener synced to StarterPlayerScripts (AGENTS.md Rule 2 compliant).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local toolRemotes = ReplicatedStorage:WaitForChild("ToolRemotes", 10)
local connectFunction = toolRemotes and toolRemotes:WaitForChild("ConnectFunction", 10)

if not connectFunction then
	return
end

local boundTools: { [Tool]: boolean } = {}

local function setupTool(tool: Instance)
	if not tool:IsA("Tool") or boundTools[tool] then
		return
	end
	boundTools[tool] = true

	local cooldown = 0
	tool.Activated:Connect(function()
		local now = os.clock()
		if now - cooldown < 0.55 then
			return
		end
		cooldown = now
		pcall(function()
			(connectFunction :: RemoteFunction):InvokeServer(tool.Name)
		end)
	end)
end

local function onCharacterAdded(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			setupTool(child)
		end
	end)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			setupTool(child)
		end
	end
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

local backpack = localPlayer:WaitForChild("Backpack", 5)
if backpack then
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			setupTool(child)
		end
	end)
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then
			setupTool(child)
		end
	end
end
