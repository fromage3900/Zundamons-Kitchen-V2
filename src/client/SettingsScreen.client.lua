local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "SettingsScreenGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 200
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("TextButton", gui)
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.Text = ""
backdrop.BorderSizePixel = 0
backdrop.AutoButtonColor = false
backdrop.Visible = false

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 320, 0, 200)
panel.Position = UDim2.new(0.5, -160, 0.5, -100)
panel.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
panel.BorderSizePixel = 0
panel.BackgroundTransparency = 1
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(180, 150, 110)
pStroke.Thickness = 3
pStroke.Transparency = 1

local titleLbl = Instance.new("TextLabel", panel)
titleLbl.Size = UDim2.new(1, -20, 0, 30)
titleLbl.Position = UDim2.new(0, 10, 0, 10)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "⚙ Settings"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 20
titleLbl.TextColor3 = Color3.fromRGB(80, 40, 30)

local volLbl = Instance.new("TextLabel", panel)
volLbl.Size = UDim2.new(0, 100, 0, 24)
volLbl.Position = UDim2.new(0, 16, 0, 52)
volLbl.BackgroundTransparency = 1
volLbl.Text = "Volume"
volLbl.Font = Enum.Font.Gotham
volLbl.TextSize = 16
volLbl.TextColor3 = Color3.fromRGB(80, 40, 30)
volLbl.TextXAlignment = Enum.TextXAlignment.Left

local volVal = Instance.new("TextLabel", panel)
volVal.Name = "VolValue"
volVal.Size = UDim2.new(0, 40, 0, 24)
volVal.Position = UDim2.new(1, -50, 0, 52)
volVal.BackgroundTransparency = 1
volVal.Text = "100%"
volVal.Font = Enum.Font.Gotham
volVal.TextSize = 14
volVal.TextColor3 = Color3.fromRGB(120, 80, 60)

local sliderBg = Instance.new("Frame", panel)
sliderBg.Size = UDim2.new(0, 200, 0, 6)
sliderBg.Position = UDim2.new(0, 16, 0, 84)
sliderBg.BackgroundColor3 = Color3.fromRGB(180, 160, 140)
sliderBg.BorderSizePixel = 0
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderBg)
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(1, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(120, 200, 120)
sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderBtn = Instance.new("TextButton", sliderBg)
sliderBtn.Name = "SliderBtn"
sliderBtn.Size = UDim2.new(0, 18, 0, 18)
sliderBtn.Position = UDim2.new(1, -9, 0.5, -9)
sliderBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
sliderBtn.BorderSizePixel = 0
sliderBtn.Text = ""
Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(1, 0)

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 80, 0, 28)
closeBtn.Position = UDim2.new(0.5, -40, 1, -40)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 200, 120)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.TextTransparency = 1
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local function setVolume(val)
	local clamped = math.clamp(val, 0, 1)
	local soundService = game:GetService("SoundService")
	soundService.Volume = clamped
	volVal.Text = math.floor(clamped * 100) .. "%"
	sliderFill.Size = UDim2.new(clamped, 0, 1, 0)
	sliderBtn.Position = UDim2.new(clamped, -9, 0.5, -9)
	local attrVal = math.floor(clamped * 100)
	player:SetAttribute("VolumeLevel", attrVal)
end

local RS = game:GetService("ReplicatedStorage")
local function loadVolume()
	local attr = player:GetAttribute("VolumeLevel")
	if attr then
		setVolume(attr / 100)
	else
		setVolume(1)
	end
end

local dragging = false
sliderBtn.MouseButton1Down:Connect(function()
	dragging = true
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local absPos = sliderBg.AbsolutePosition
		local absSize = sliderBg.AbsoluteSize
		local ratio = (input.Position.X - absPos.X) / absSize.X
		setVolume(ratio)
	end
end)

local function show()
	gui.Enabled = true
	backdrop.Visible = true; panel.Visible = true
	panel.BackgroundTransparency = 1; pStroke.Transparency = 1
	closeBtn.BackgroundTransparency = 1; closeBtn.TextTransparency = 1
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 200), Position = UDim2.new(0.5, -160, 0.5, -100)
	}):Play()
	task.wait(0.15)
	panel.BackgroundTransparency = 0; pStroke.Transparency = 0
	closeBtn.BackgroundTransparency = 0; closeBtn.TextTransparency = 0
	loadVolume()
end

local function hide()
	gui.Enabled = false
	backdrop.Visible = false; panel.Visible = false
end

closeBtn.MouseButton1Click:Connect(hide)
backdrop.MouseButton1Click:Connect(hide)

local RS_gui = RS:WaitForChild("RemoteEvents")
local toggleEv = RS_gui:FindFirstChild("ToggleSettingsUI")
if not toggleEv then
	toggleEv = Instance.new("RemoteEvent")
	toggleEv.Name = "ToggleSettingsUI"
	toggleEv.Parent = RS_gui
end
toggleEv.OnClientEvent:Connect(function()
	if gui.Enabled then hide() else show() end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.L then
		if gui.Enabled then hide() else show() end
	end
end)

loadVolume()
