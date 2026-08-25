-- [[LocalScript] PhotoModeUI]
-- Infinity Nikki-style photo mode: freeze player, hide HUD, frame overlay, and camera controls.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local FONTS = UIConfig.FONTS

local gui = ClientGuiBootstrap.createScreenGui(player, "PhotoModeGui", 90)

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0.12, 0)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
topBar.BackgroundTransparency = 0.2
topBar.Parent = frame

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, 0, 0.12, 0)
bottomBar.Position = UDim2.new(0, 0, 0.88, 0)
bottomBar.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
bottomBar.BackgroundTransparency = 0.2
bottomBar.Parent = frame

local sideLeft = Instance.new("Frame")
sideLeft.Name = "SideLeft"
sideLeft.Size = UDim2.new(0.06, 0, 0.76, 0)
sideLeft.Position = UDim2.new(0, 0, 0.12, 0)
sideLeft.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
sideLeft.BackgroundTransparency = 0.2
sideLeft.Parent = frame

local sideRight = Instance.new("Frame")
sideRight.Name = "SideRight"
sideRight.Size = UDim2.new(0.06, 0, 0.76, 0)
sideRight.Position = UDim2.new(0.94, 0, 0.12, 0)
sideRight.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
sideRight.BackgroundTransparency = 0.2
sideRight.Parent = frame

local sticker = Instance.new("TextLabel")
sticker.Name = "Sticker"
sticker.Size = UDim2.new(0, 80, 0, 80)
sticker.Position = UDim2.new(0.85, 0, 0.72, 0)
sticker.BackgroundTransparency = 1
sticker.Text = "🌱"
sticker.FontFace = FONTS.Title
sticker.TextSize = 60
sticker.TextTransparency = 0.2
sticker.Rotation = -12
sticker.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "📸  Zunda Photo Mode"
title.FontFace = FONTS.Heading
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(80, 55, 35)
title.Parent = topBar

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.Size = UDim2.new(0, 400, 0, 44)
controls.Position = UDim2.new(0.5, -200, 0.5, -22)
controls.BackgroundTransparency = 1
controls.Parent = bottomBar

local function makeBtn(text: string, x: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 120, 0, 40)
	btn.Position = UDim2.new(0, x, 0, 2)
	btn.BackgroundColor3 = Color3.fromRGB(160, 210, 150)
	btn.Text = text
	btn.FontFace = FONTS.Heading
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.Parent = controls
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = btn
	return btn
end

local rotateLeftBtn = makeBtn("⬅ Rotate", 0)
local takeBtn = makeBtn("📸 Snap!", 130)
local rotateRightBtn = makeBtn("Rotate ➡", 260)
local exitBtn = makeBtn("✕ Exit", 340)
exitBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 200)

local isPhotoMode = false
local originalCameraCFrame = nil
local originalCameraType = nil
local originalWalkSpeed = nil
local inputHandler = nil
local rotation = 0
local savedHudStates: { [ScreenGui]: boolean } = {}

local function setHudVisible(visible: boolean)
	local pg = player:WaitForChild("PlayerGui")
	for _, sg in ipairs(pg:GetChildren()) do
		if sg:IsA("ScreenGui") and sg ~= gui then
			if visible then
				if savedHudStates[sg] ~= nil then
					sg.Enabled = savedHudStates[sg]
				end
			else
				savedHudStates[sg] = sg.Enabled
				sg.Enabled = false
			end
		end
	end
end

local function updateCamera()
	if not isPhotoMode then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local angle = math.rad(rotation)
	local offset = Vector3.new(math.sin(angle) * 7, 2, math.cos(angle) * 7)
	camera.CFrame = CFrame.lookAt(hrp.Position + offset, hrp.Position + Vector3.new(0, 1.5, 0))
end

local heartbeatConn = nil

local function enterPhotoMode()
	if isPhotoMode then
		return
	end
	isPhotoMode = true
	originalCameraCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			originalWalkSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = 0
		end
	end

	setHudVisible(false)
	frame.Visible = true
	rotation = 35
	updateCamera()

	-- Swap to the Zunda "move" grab cursor while in photo mode.
	local zc = _G.ZundaCursors
	if zc then
		zc.setCursor("move")
	end

	heartbeatConn = RunService.Heartbeat:Connect(updateCamera)

	inputHandler = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			exitPhotoMode()
		end
	end)
end

function exitPhotoMode()
	if not isPhotoMode then
		return
	end
	isPhotoMode = false
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if inputHandler then
		inputHandler:Disconnect()
		inputHandler = nil
	end

	camera.CameraType = originalCameraType or Enum.CameraType.Custom
	if originalCameraCFrame then
		camera.CFrame = originalCameraCFrame
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and originalWalkSpeed then
			humanoid.WalkSpeed = originalWalkSpeed
		end
	end

	setHudVisible(true)
	frame.Visible = false

	-- Restore the cursor that was active before Photo Mode opened.
	local zc = _G.ZundaCursors
	if zc then
		zc.pop()
	end
end
_G.exitPhotoMode = exitPhotoMode

rotateLeftBtn.MouseButton1Click:Connect(function()
	rotation -= 30
	updateCamera()
end)

rotateRightBtn.MouseButton1Click:Connect(function()
	rotation += 30
	updateCamera()
end)

takeBtn.MouseButton1Click:Connect(function()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0
	flash.ZIndex = 100
	flash.Parent = gui
	TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	print("[PhotoMode] SNAP! Screenshot captured (simulated).")
	task.delay(0.3, function()
		flash:Destroy()
	end)
end)

exitBtn.MouseButton1Click:Connect(exitPhotoMode)

local ActionRegistry =
	require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

local function toggle()
	if isPhotoMode then
		exitPhotoMode()
	else
		enterPhotoMode()
	end
end

ActionRegistry.registerCallback("photomode", toggle)

print("[PhotoModeUI] Ready")
