local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RS = game:GetService("ReplicatedStorage")
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local RF = RS:FindFirstChild("RemoteFunctions") or RS:WaitForChild("RemoteFunctions", 10)
local executeCmd = RF:FindFirstChild("ExecuteAdminCommand")
if not executeCmd then
	executeCmd = Instance.new("RemoteFunction")
	executeCmd.Name = "ExecuteAdminCommand"
	executeCmd.Parent = RF
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminConsole"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundTransparency = 0.6
bg.BackgroundColor3 = UIConfig.COLORS.Background
bg.BorderSizePixel = 0
bg.Parent = screenGui

local output = Instance.new("ScrollingFrame")
output.Size = UDim2.new(1, -20, 1, -60)
output.Position = UDim2.new(0, 10, 0, 10)
output.BackgroundTransparency = 1
output.BorderSizePixel = 0
output.ScrollBarThickness = 4
output.CanvasSize = UDim2.new(0, 0, 0, 0)
output.AutomaticCanvasSize = Enum.AutomaticSize.Y
output.Parent = bg

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -20, 0, 30)
inputBox.Position = UDim2.new(0, 10, 1, -40)
inputBox.BackgroundColor3 = UIConfig.COLORS.SurfaceLight
inputBox.TextColor3 = UIConfig.COLORS.TextSecondary
inputBox.FontFace = UIConfig.FONTS.Mono
inputBox.TextSize = UIConfig.FONT_SIZES.Caption + 2
inputBox.PlaceholderText = "Type /help for commands..."
inputBox.ClearTextOnFocus = false
inputBox.BorderSizePixel = 0
inputBox.Parent = bg

local function addOutput(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text = tostring(text)
	label.TextColor3 = color or UIConfig.COLORS.TextSecondary
	label.FontFace = UIConfig.FONTS.Mono
	label.TextSize = UIConfig.FONT_SIZES.Caption + 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.RichText = true
	label.Parent = output
	task.wait()
	output.CanvasPosition = Vector2.new(0, output.CanvasSize.Y.Offset)
end

local function processCommand(input)
	if not input or input == "" then return end
	addOutput("> " .. input, UIConfig.COLORS.Warning)
	local ok, result = pcall(function()
		return executeCmd:InvokeServer(input)
	end)
	if ok and result then
		addOutput(result, UIConfig.COLORS.Success)
	elseif not ok then
		addOutput("Error: " .. tostring(result), UIConfig.COLORS.Danger)
	end
end

inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		processCommand(inputBox.Text)
		inputBox.Text = ""
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F2 or (input.KeyCode == Enum.KeyCode.Backquote and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) then
		screenGui.Enabled = not screenGui.Enabled
		if screenGui.Enabled then
			inputBox:CaptureFocus()
		end
	end
end)

addOutput("=== Admin Console ===", UIConfig.COLORS.Secondary)
addOutput("Press F2 or ~ to toggle", UIConfig.COLORS.TextSecondary)
addOutput("Type /help for commands", UIConfig.COLORS.TextSecondary)

print("[AdminConsole] Ready — press F2 to open")
