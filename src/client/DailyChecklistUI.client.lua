local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local gui = ClientGuiBootstrap.createScreenGui(player, "DailyChecklistGui", 35)

local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local UIHelper = require(RS.Shared.Modules.UIHelper)

local RE = RS:WaitForChild("RemoteEvents")
local DailyDataEvent = RE:FindFirstChild("DailyDataEvent")
local ClaimDailyVisitor = RE:FindFirstChild("ClaimDailyVisitor")

local C = {
	bg = Color3.fromRGB(252, 244, 245),
	panel = Color3.fromRGB(255, 250, 248),
	border = Color3.fromRGB(210, 190, 220),
	title = Color3.fromRGB(90, 70, 110),
	text = Color3.fromRGB(68, 52, 78),
	sub = Color3.fromRGB(140, 120, 140),
	accent = Color3.fromRGB(180, 150, 220),
	pink = Color3.fromRGB(232, 152, 168),
	lavender = Color3.fromRGB(200, 180, 230),
	sky = Color3.fromRGB(180, 210, 240),
	done = Color3.fromRGB(160, 210, 170),
	barBg = Color3.fromRGB(235, 230, 240),
	barFill = Color3.fromRGB(180, 150, 220),
}

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 440, 0, 580)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = C.panel
panel.BorderSizePixel = 0
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 24)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Thickness = 3
panelStroke.Color = C.border

local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1, 0, 0, 80)
header.BackgroundColor3 = C.lavender
header.BackgroundTransparency = 0.5
header.BorderSizePixel = 0
local hdrCorner = Instance.new("UICorner", header)
hdrCorner.CornerRadius = UDim.new(0, 24)
header.ClipsDescendants = true

local titleIcon = Instance.new("TextLabel", header)
titleIcon.Size = UDim2.new(0, 48, 0, 48)
titleIcon.Position = UDim2.new(0, 18, 0, 16)
titleIcon.BackgroundTransparency = 1
titleIcon.Text = "✨"
titleIcon.Font = Enum.Font.GothamBold
titleIcon.TextSize = 32
titleIcon.TextColor3 = C.title

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -80, 0, 32)
titleLabel.Position = UDim2.new(0, 72, 0, 14)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Daily Planner"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 26
titleLabel.TextColor3 = C.title
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local subtitleLabel = Instance.new("TextLabel", header)
subtitleLabel.Size = UDim2.new(1, -80, 0, 20)
subtitleLabel.Position = UDim2.new(0, 72, 0, 48)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Cozy tasks for today ~"
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 14
subtitleLabel.TextColor3 = C.sub
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 22)
closeBtn.BackgroundColor3 = C.pink
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "ChecklistScroll"
scroll.Size = UDim2.new(1, -32, 1, -96)
scroll.Position = UDim2.new(0, 16, 0, 88)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.lavender
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeVisitorEntry(parent, visitorName, claimed)
	local color = claimed and C.done or C.lavender
	local entry = Instance.new("Frame", parent)
	entry.Size = UDim2.new(1, 0, 0, 76)
	entry.BackgroundColor3 = C.bg
	entry.BorderSizePixel = 0
	Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 14)
	local entryStroke = Instance.new("UIStroke", entry)
	entryStroke.Thickness = 1
	entryStroke.Color = color
	entryStroke.Transparency = 0.5

	local ico = Instance.new("TextLabel", entry)
	ico.Size = UDim2.new(0, 44, 0, 44)
	ico.Position = UDim2.new(0, 10, 0, 16)
	ico.BackgroundTransparency = 1
	ico.Text = "🧳"
	ico.Font = Enum.Font.GothamBold
	ico.TextSize = 28

	local label = Instance.new("TextLabel", entry)
	label.Size = UDim2.new(1, -130, 0, 22)
	label.Position = UDim2.new(0, 62, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = "Daily Visitor"
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.TextColor3 = C.text
	label.TextXAlignment = Enum.TextXAlignment.Left

	local subLabel = Instance.new("TextLabel", entry)
	subLabel.Size = UDim2.new(1, -130, 0, 18)
	subLabel.Position = UDim2.new(0, 62, 0, 36)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = claimed and "Already visited! ✨" or (visitorName or "Waiting for visitor...")
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextSize = 13
	subLabel.TextColor3 = claimed and C.done or C.sub
	subLabel.TextXAlignment = Enum.TextXAlignment.Left

	local actionBtn = Instance.new("TextButton", entry)
	actionBtn.Size = UDim2.new(0, 100, 0, 36)
	actionBtn.Position = UDim2.new(1, -110, 0, 20)
	actionBtn.BackgroundColor3 = claimed and C.done or C.lavender
	actionBtn.Text = claimed and "Claimed" or "Greet ✨"
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.TextSize = 14
	actionBtn.TextColor3 = claimed and Color3.new(1, 1, 1) or C.title
	actionBtn.BorderSizePixel = 0
	Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 10)
	if not claimed and ClaimDailyVisitor then
		actionBtn.MouseButton1Click:Connect(function()
			ClaimDailyVisitor:FireServer()
			actionBtn.Visible = false
			subLabel.Text = "Already visited! ✨"
			subLabel.TextColor3 = C.done
		end)
	else
		actionBtn.Visible = false
	end

	return entry
end

local function refreshPanel(data)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if data then
		local visitorEntry = makeVisitorEntry(scroll, data.visitorName, data.visitorClaimed)
		visitorEntry.LayoutOrder = 1

		local harvestLabel = Instance.new("TextLabel", scroll)
		harvestLabel.Size = UDim2.new(1, 0, 0, 30)
		harvestLabel.BackgroundTransparency = 1
		harvestLabel.Text = "🌱 Daily Resources: " .. (data.resourcesHarvested or 0) .. " / " .. (data.maxResources or 0) .. " gathered"
		harvestLabel.Font = Enum.Font.Gotham
		harvestLabel.TextSize = 14
		harvestLabel.TextColor3 = (data.resourcesHarvested or 0) >= (data.maxResources or 1) and C.done or C.sub
		harvestLabel.LayoutOrder = 99
	end
end

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

if DailyDataEvent then
	DailyDataEvent.OnClientEvent:Connect(function(data)
		refreshPanel(data)
	end)
end

_G.DailyChecklist = {
	isOpen = function() return panel.Visible end,
	open = function()
		panel.Visible = true
	end,
	close = function() panel.Visible = false end,
	toggle = function()
		if _G.DailyChecklist.isOpen() then
			_G.DailyChecklist.close()
		else
			_G.DailyChecklist.open()
		end
	end,
}

-- registerCallback() sometimes doesn't stick on the first attempt during the
-- heavy initial-load frame (root cause unconfirmed -- possibly a Rojo live-sync
-- module reload racing this call). Retry until getAction() actually reflects it
-- rather than trusting a single call.
task.spawn(function()
	local ActionRegistry = require(game:GetService("Players").LocalPlayer.PlayerScripts
		:WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))
	for _ = 1, 10 do
		ActionRegistry.registerCallback("daily", _G.DailyChecklist.toggle)
		local def = ActionRegistry.getAction("daily")
		if def and def.callback then break end
		task.wait(0.5)
	end
end)

print("[DailyChecklistUI] loaded")
