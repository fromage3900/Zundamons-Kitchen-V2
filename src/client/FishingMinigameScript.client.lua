--!strict
-- Fishing presentation only. Server FishingService owns simulation and outcome.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)
local remotes = ReplicatedStorage:WaitForChild("ToolRemotes")
local fishingState = remotes:WaitForChild("FishingState") :: RemoteEvent
local fishingResult = remotes:WaitForChild("FishingResult") :: RemoteEvent
local player = Players.LocalPlayer
local gui = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap).createScreenGui(player, "FishingGui", 100)

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(720, 460)
panel.Position = UDim2.new(0.5, -360, 0.5, -230)
panel.BackgroundColor3 = UIConfig.COLORS.PanelBg
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 26)

local function label(text: string, y: number, height: number, size: number): TextLabel
	local item = Instance.new("TextLabel")
	item.Size = UDim2.new(1, -40, 0, height)
	item.Position = UDim2.fromOffset(20, y)
	item.BackgroundTransparency = 1
	item.Text = text
	item.Font = Enum.Font.GothamBold
	item.TextSize = size
	item.TextColor3 = UIConfig.COLORS.TextDark
	item.Parent = panel
	return item
end

local fishLabel = label("Fish on the line!", 18, 54, 36)
local hint = label("Hold SPACE or press REEL. Keep tension below the limit!", 74, 28, 16)
hint.Font = Enum.Font.Gotham
hint.TextColor3 = UIConfig.COLORS.TextDarkSec
local tensionLabel = label("TENSION", 112, 22, 14)
tensionLabel.TextXAlignment = Enum.TextXAlignment.Left
local progressLabel = label("REEL PROGRESS", 180, 22, 14)
progressLabel.TextXAlignment = Enum.TextXAlignment.Left

local function bar(y: number, background: Color3, fillColor: Color3): Frame
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -40, 0, 28)
	track.Position = UDim2.fromOffset(20, y)
	track.BackgroundColor3 = background
	track.BorderSizePixel = 0
	track.Parent = panel
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	return fill
end

local tensionFill = bar(136, Color3.fromRGB(255, 240, 240), UIConfig.COLORS.Danger)
local progressFill = bar(204, Color3.fromRGB(240, 255, 240), UIConfig.GAME_COLORS.HUDAccent)

local reelButton = Instance.new("TextButton")
reelButton.Size = UDim2.fromOffset(360, 92)
reelButton.Position = UDim2.new(0.5, -180, 0, 266)
reelButton.BackgroundColor3 = UIConfig.COLORS.Primary
reelButton.Text = "REEL"
reelButton.Font = Enum.Font.GothamBold
reelButton.TextSize = 44
reelButton.TextColor3 = UIConfig.GAME_COLORS.HUDText
reelButton.AutoButtonColor = false
reelButton.Parent = panel
Instance.new("UICorner", reelButton).CornerRadius = UDim.new(0, 22)
local resultLabel = label("", 382, 42, 24)

local active = false
local activeSessionId: string? = nil
local reeling = false
local inputCallback: ((boolean) -> ())? = nil

local function setReeling(value: boolean)
	if not active or reeling == value then
		return
	end
	reeling = value
	if inputCallback then
		inputCallback(value)
	end
end

local function stop()
	if reeling and inputCallback then
		inputCallback(false)
	end
	reeling = false
	active = false
end

local function finish(outcome: string, payload: any?)
	if not active then
		return
	end
	stop()
	if outcome == "caught" then
		resultLabel.Text = "Caught " .. tostring(payload and payload.name or "a fish") .. "!"
		resultLabel.TextColor3 = UIConfig.COLORS.Success
		if _G.ZundaSoundController then
			_G.ZundaSoundController.play("Bubbles")
		end
	elseif outcome == "settlement_failed" then
		resultLabel.Text = "Catch could not be saved. Please try again."
		resultLabel.TextColor3 = UIConfig.COLORS.Danger
	elseif outcome == "timeout" then
		resultLabel.Text = "The fish got away..."
		resultLabel.TextColor3 = UIConfig.COLORS.Danger
	else
		resultLabel.Text = "The line went slack."
		resultLabel.TextColor3 = UIConfig.COLORS.Danger
	end
	task.delay(2, function()
		panel.Visible = false
		backdrop.Visible = false
		activeSessionId = nil
		inputCallback = nil
	end)
end

reelButton.MouseButton1Down:Connect(function()
	setReeling(true)
end)
reelButton.MouseButton1Up:Connect(function()
	setReeling(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Space then
		setReeling(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		setReeling(false)
	end
end)

fishingState.OnClientEvent:Connect(function(state)
	if not active or type(state) ~= "table" or state.sessionId ~= activeSessionId then
		return
	end
	local tension = math.clamp(tonumber(state.tension) or 0, 0, 1)
	local progress = math.clamp(tonumber(state.progress) or 0, 0, 1)
	tensionFill.Size = UDim2.fromScale(tension, 1)
	progressFill.Size = UDim2.fromScale(progress, 1)
	tensionFill.BackgroundColor3 = Color3.fromRGB(
		math.floor(120 + tension * 100),
		math.floor(200 - tension * 130),
		math.floor(120 - tension * 100)
	)
end)

fishingResult.OnClientEvent:Connect(function(result)
	if type(result) ~= "table" or result.sessionId ~= activeSessionId then
		return
	end
	finish(result.outcome, result.payload)
end)

local function start(sessionId: string, fish: any, onInput: (boolean) -> ())
	if active or type(sessionId) ~= "string" or type(fish) ~= "table" then
		return
	end
	active = true
	activeSessionId = sessionId
	inputCallback = onInput
	reeling = false
	fishLabel.Text = "Something is biting! (rarity " .. tostring(fish.rarity) .. ")"
	fishLabel.TextColor3 = fish.color or UIConfig.COLORS.TextDark
	resultLabel.Text = ""
	tensionFill.Size = UDim2.fromScale(0.2, 1)
	progressFill.Size = UDim2.fromScale(0, 1)
	backdrop.Visible = true
	panel.Visible = true
	panel.Size = UDim2.fromOffset(680, 440)
	TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(720, 460) }):Play()
end

_G.FishingMinigame = { start = start, stop = stop }
print("[FishingMinigame] Server-authoritative presentation ready")
