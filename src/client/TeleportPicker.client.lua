-- Teleport destination picker. Shown when clicking a teleporter pad.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TeleporterConfig = require(RS.ConfigurationFiles.TeleporterConfig)

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportPicker"
gui.ResetOnSpawn = false
gui.DisplayOrder = 85
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("TextButton", gui)
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundTransparency = 0.6
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.Text = ""
backdrop.BorderSizePixel = 0
backdrop.AutoButtonColor = false
backdrop.MouseButton1Click:Connect(function() gui.Enabled = false end)

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 280)
panel.Position = UDim2.new(0.5, -160, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(180, 150, 110)
pStroke.Thickness = 3

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🌐 Where to?"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(80, 40, 30)

local currentPadLbl = Instance.new("TextLabel", panel)
currentPadLbl.Name = "PadName"
currentPadLbl.Size = UDim2.new(1, -20, 0, 18)
currentPadLbl.Position = UDim2.new(0, 10, 0, 44)
currentPadLbl.BackgroundTransparency = 1
currentPadLbl.Text = ""
currentPadLbl.Font = Enum.Font.Gotham
currentPadLbl.TextSize = 13
currentPadLbl.TextColor3 = Color3.fromRGB(140, 100, 80)

local destList = Instance.new("ScrollingFrame", panel)
destList.Name = "Destinations"
destList.Size = UDim2.new(1, -20, 1, -110)
destList.Position = UDim2.new(0, 10, 0, 65)
destList.BackgroundTransparency = 1
destList.BorderSizePixel = 0
destList.ScrollBarThickness = 6
destList.CanvasSize = UDim2.new(0, 0, 0, 0)

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 100, 0, 30)
closeBtn.Position = UDim2.new(0.5, -50, 1, -38)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 110)
closeBtn.Text = "Stay here"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

local currentPadName = ""
local RE = RS:WaitForChild("RemoteEvents")

local function showPicker(data)
	if not data or not data.destinations then return end
	currentPadName = data.padName or ""
	currentPadLbl.Text = "📍 " .. (data.displayName or "Teleporter")
	-- Clear old entries
	for _, c in ipairs(destList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local y = 0
	for _, zoneKey in ipairs(data.destinations) do
		local zoneDef = TeleporterConfig.zones[zoneKey]
		local emoji = zoneDef and zoneDef.emoji or "📍"
		local zoneName = zoneDef and zoneDef.name or zoneKey
		local desc = zoneDef and zoneDef.description or ""
		local btn = Instance.new("TextButton", destList)
		btn.Size = UDim2.new(1, -6, 0, 52)
		btn.Position = UDim2.new(0, 0, 0, y)
		btn.BackgroundColor3 = Color3.fromRGB(235, 225, 210)
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		local icon = Instance.new("TextLabel", btn)
		icon.Size = UDim2.new(0, 40, 1, 0)
		icon.Position = UDim2.new(0, 6, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = emoji
		icon.TextSize = 26
		local nLbl = Instance.new("TextLabel", btn)
		nLbl.Size = UDim2.new(1, -58, 0, 24)
		nLbl.Position = UDim2.new(0, 52, 0, 4)
		nLbl.BackgroundTransparency = 1
		nLbl.Text = zoneName
		nLbl.Font = Enum.Font.GothamBold
		nLbl.TextSize = 16
		nLbl.TextColor3 = Color3.fromRGB(80, 40, 30)
		nLbl.TextXAlignment = Enum.TextXAlignment.Left
		local dLbl = Instance.new("TextLabel", btn)
		dLbl.Size = UDim2.new(1, -58, 0, 18)
		dLbl.Position = UDim2.new(0, 52, 0, 28)
		dLbl.BackgroundTransparency = 1
		dLbl.Text = desc
		dLbl.Font = Enum.Font.Gotham
		dLbl.TextSize = 11
		dLbl.TextColor3 = Color3.fromRGB(140, 100, 80)
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		btn.MouseButton1Click:Connect(function()
			local teleportRE = RE:FindFirstChild("RequestTeleport")
			if teleportRE and currentPadName ~= "" then
				teleportRE:FireServer(currentPadName, zoneKey)
			end
			gui.Enabled = false
		end)
		y = y + 58
	end
	destList.CanvasSize = UDim2.new(0, 0, 0, y)
	gui.Enabled = true
end

local showEv = RE:FindFirstChild("ShowTeleportPicker")
if showEv then
	showEv.OnClientEvent:Connect(showPicker)
end

print("[TeleportPicker] Ready")
