--!strict
-- [[LocalScript] PeaWheelController]]
-- Input state machine and action dispatch for the Pea Wheel radial menu.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)
local ActionRegistry = require(script.Parent.Parent.ConfigurationFiles.UIActionRegistry)
local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)

local PeaWheelController = {}

local wheelGui = nil
local hubButton = nil
local sliceButtons = {}
local tooltipLabel = nil
local gamepadConn = nil
local gamepadReleaseConn = nil

local isOpen = false
local selectedIndex = 1
local isHolding = false
local HOLD_THRESHOLD = 0.18
local reducedMotion = UserInputService.ReducedMotionEnabled

local PEA_WHEEL = UIConfig.PEA_WHEEL or {}

-- Infinity Nikki soft-pastel palette for slices
local NIKKI_PASTELS = {
	Color3.fromRGB(255, 182, 193), -- pastel pink
	Color3.fromRGB(173, 216, 230), -- pastel blue
	Color3.fromRGB(255, 218, 185), -- pastel peach
	Color3.fromRGB(221, 160, 221), -- pastel lavender
	Color3.fromRGB(152, 251, 152), -- pastel mint
	Color3.fromRGB(255, 255, 224), -- pastel lemon
	Color3.fromRGB(176, 224, 230), -- pastel sky
	Color3.fromRGB(230, 190, 255), -- pastel lilac
}

-- ── Public state helpers ─────────────────────────────────────
function PeaWheelController.isOpen()
	return isOpen
end

function PeaWheelController.getSelectedAction()
	local list = ActionRegistry.getOrderedSliceList()
	return list[selectedIndex] or nil
end

-- ── UI Construction ──────────────────────────────────────────
local function buildWheelGui()
	if wheelGui and wheelGui.Parent then
		return wheelGui
	end

	wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 80)
	wheelGui.ResetOnSpawn = false
	
	-- Respect reduced motion preference
	if reducedMotion then
		wheelGui.DisplayOrder = 80
	end

	-- Hub button (bottom-right)
	hubButton = Instance.new("TextButton")
	hubButton.Name = "HubButton"
	hubButton.Size = UDim2.fromOffset(PEA_WHEEL.HubSize or 88, PEA_WHEEL.HubSize or 88)
	hubButton.AnchorPoint = Vector2.new(1, 1)
	hubButton.Position = UDim2.fromScale(1, 1) - UDim2.fromOffset(24, 24)
	hubButton.BackgroundColor3 = PEA_WHEEL.Colors and PEA_WHEEL.Colors.Center or Color3.fromRGB(30, 25, 20)
	hubButton.Text = "🫛"
	hubButton.TextScaled = true
	hubButton.Font = Enum.Font.GothamBold
	hubButton.TextColor3 = PEA_WHEEL.Colors and PEA_WHEEL.Colors.CenterText or Color3.fromRGB(255, 250, 245)
	hubButton.Parent = wheelGui
	Instance.new("UICorner", hubButton).CornerRadius = UDim.new(0.5, 0)
	local hubStroke = Instance.new("UIStroke", hubButton)
	hubStroke.Color = PEA_WHEEL.Colors and PEA_WHEEL.Colors.Stroke or Color3.fromRGB(200, 160, 240)
	hubStroke.Thickness = 2
	hubStroke.Transparency = 0.2

	-- Tooltip
	tooltipLabel = Instance.new("TextLabel")
	tooltipLabel.Name = "Tooltip"
	tooltipLabel.Size = UDim2.fromOffset(180, 32)
	tooltipLabel.AnchorPoint = Vector2.new(0.5, 1)
	tooltipLabel.Position = UDim2.new(0.5, 0, 0, -16)
	tooltipLabel.BackgroundTransparency = 1
	tooltipLabel.Text = ""
	tooltipLabel.Font = Enum.Font.Gotham
	tooltipLabel.TextSize = 14
	tooltipLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
	tooltipLabel.TextStrokeTransparency = 0.3
	tooltipLabel.Visible = false
	tooltipLabel.Parent = hubButton

	-- Slice buttons (initially hidden)
	sliceButtons = {}
	local sliceList = ActionRegistry.getOrderedSliceList()
	for i, actionId in ipairs(sliceList) do
		local def = ActionRegistry.getAction(actionId)
		if not def then continue end

		local btn = Instance.new("TextButton")
		btn.Name = "Slice_" .. actionId
		btn.Size = UDim2.fromOffset(PEA_WHEEL.SliceSize or 72, PEA_WHEEL.SliceSize or 72)
		-- Infinity Nikki pastel tint per slice
		local pastel = NIKKI_PASTELS[i] or PEA_WHEEL.Colors and PEA_WHEEL.Colors.Slice or Color3.fromRGB(60, 50, 70)
		btn.BackgroundColor3 = pastel
		btn.Text = def.icon
		btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Visible = false
		btn.Parent = hubButton
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 0)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = PEA_WHEEL.Colors and PEA_WHEEL.Colors.Stroke or Color3.fromRGB(200, 160, 240)
		stroke.Thickness = 2
		stroke.Transparency = 0.3

		-- Position at 45 degree intervals
		local angle = math.rad(-90 + (i - 1) * 45)
		local radius = (PEA_WHEEL.HubSize or 88) / 2 + (PEA_WHEEL.SliceSize or 72) / 2 + 12
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius
		btn.Position = UDim2.new(0.5, x - (PEA_WHEEL.SliceSize or 72) / 2, 0.5, y - (PEA_WHEEL.SliceSize or 72) / 2)
		btn.AnchorPoint = Vector2.new(0.5, 0.5)

		btn.MouseButton1Click:Connect(function()
			if isOpen then
				PeaWheelController.select(actionId)
			end
		end)

		btn.MouseEnter:Connect(function()
			if isOpen then
				selectedIndex = i
				PeaWheelController.updateSelectionVisual()
			end
		end)

		sliceButtons[i] = btn
	end

	return wheelGui
end

-- ── Visual Updates ───────────────────────────────────────────
function PeaWheelController.updateSelectionVisual()
	if not hubButton or not tooltipLabel then return end
	local sliceList = ActionRegistry.getOrderedSliceList()
	local actionId = sliceList[selectedIndex]
	local def = ActionRegistry.getAction(actionId)

	-- Reset all slices
	for _, btn in ipairs(sliceButtons) do
		btn.Size = UDim2.fromOffset(PEA_WHEEL.SliceSize or 72, PEA_WHEEL.SliceSize or 72)
		btn.BackgroundColor3 = PEA_WHEEL.Colors and PEA_WHEEL.Colors.Slice or Color3.fromRGB(60, 50, 70)
		local s = btn:FindFirstChildOfClass("UIStroke")
		if s then
			s.Transparency = 0.3
		end
	end

	-- Highlight selected
	local selectedBtn = sliceButtons[selectedIndex]
	if selectedBtn then
		local targetSize = (PEA_WHEEL.SliceSize or 72) * (PEA_WHEEL.SelectedScale or 1.12)
		TweenService:Create(selectedBtn, TweenInfo.new(PEA_WHEEL.AnimDuration or 0.18), {
			Size = UDim2.fromOffset(targetSize, targetSize),
			BackgroundColor3 = PEA_WHEEL.Colors and PEA_WHEEL.Colors.SliceHover or Color3.fromRGB(100, 200, 80),
		}):Play()
		local s = selectedBtn:FindFirstChildOfClass("UIStroke")
		if s then
			s.Transparency = 0.0
		end
		-- Cute sparkle frill on selection
		local UIHelper = require(ReplicatedStorage.Shared.Modules.UIHelper)
		if UIHelper and UIHelper.spawnSparkles then
			UIHelper.spawnSparkles(selectedBtn, selectedBtn.AbsoluteSize.X / 2, selectedBtn.AbsoluteSize.Y / 2, Color3.fromRGB(255, 255, 255), 6)
		end
	end

	-- Tooltip
	if def then
		tooltipLabel.Text = def.icon .. " " .. def.label
		tooltipLabel.Visible = true
	end
end

-- ── Open / Close / Toggle ────────────────────────────────────
function PeaWheelController.open()
	if isOpen then return end
	if RunService:IsStudio() and RunService:IsEdit() then return end

	local gui = buildWheelGui()
	if not gui then return end

	-- Check cooking conflict
	local canOpen = true
	if _G.TimedCooking and _G.TimedCooking.isCooking then
		canOpen = not _G.TimedCooking.isCooking()
	end
	if not canOpen then return end

	isOpen = true
	selectedIndex = 1

	-- Animate hub
	hubButton.Size = UDim2.fromOffset(4, 4)
	TweenService:Create(hubButton, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(PEA_WHEEL.HubSize or 88, PEA_WHEEL.HubSize or 88),
	}):Play()

	-- Reveal slices staggered
	for i, btn in ipairs(sliceButtons) do
		btn.Visible = true
		if reducedMotion then
			btn.Size = UDim2.fromOffset(PEA_WHEEL.SliceSize or 72, PEA_WHEEL.SliceSize or 72)
		else
			btn.Size = UDim2.fromOffset(0, 0)
			TweenService:Create(btn, TweenInfo.new(0.18 + i * 0.03, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(PEA_WHEEL.SliceSize or 72, PEA_WHEEL.SliceSize or 72),
			}):Play()
		end
	end

	PeaWheelController.updateSelectionVisual()
end

function PeaWheelController.close()
	if not isOpen then return end
	isOpen = false

	if not hubButton or not tooltipLabel then return end

	-- Hide slices
	for _, btn in ipairs(sliceButtons) do
		TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(0, 0) }):Play()
		task.delay(0.14, function()
			if btn and btn.Parent then
				btn.Visible = false
			end
		end)
	end

	tooltipLabel.Visible = false

	-- Collapse hub
	TweenService:Create(hubButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(PEA_WHEEL.HubSize or 88, PEA_WHEEL.HubSize or 88),
	}):Play()
end

function PeaWheelController.toggle()
	if isOpen then
		PeaWheelController.close()
	else
		PeaWheelController.open()
	end
end

-- ── Selection & Dispatch ─────────────────────────────────────
function PeaWheelController.select(actionId)
	if not isOpen then return end
	local ok = ActionRegistry.dispatch(actionId)
	if ok then
		PeaWheelController.close()
	end
	return ok
end

-- ── Keyboard Input ───────────────────────────────────────────
local function onInputBegan(input, processed)
	if processed then return end

	-- Cooking conflict guard
	if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then
		return
	end

	-- Tab hold / release
	if input.KeyCode == Enum.KeyCode.Tab then
		if not isOpen then
			isHolding = true
			task.delay(HOLD_THRESHOLD, function()
				if isHolding and not isOpen then
					PeaWheelController.open()
				end
				isHolding = false
			end)
		else
			PeaWheelController.close()
			isHolding = false
		end
		return
	end

	-- Arrow keys / WASD navigate slices when open
	if isOpen then
		local sliceList = ActionRegistry.getOrderedSliceList()
		local count = #sliceList
		if input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
			selectedIndex = ((selectedIndex - 1) % count) + 1
			PeaWheelController.updateSelectionVisual()
		elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
			selectedIndex = ((selectedIndex - 2) % count) + 1
			PeaWheelController.updateSelectionVisual()
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			local actionId = sliceList[selectedIndex]
			if actionId then
				PeaWheelController.select(actionId)
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			PeaWheelController.close()
		end
	end
end

local function onInputEnded(input, processed)
	if input.KeyCode == Enum.KeyCode.Tab then
		isHolding = false
	end
end

-- ── Initialization ───────────────────────────────────────────
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- Hub button
if hubButton then
	hubButton.MouseButton1Click:Connect(function()
		if RunService:IsStudio() and RunService:IsEdit() then return end
		if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
		PeaWheelController.toggle()
		-- Cute sparkle frill on hub click
		if not reducedMotion then
			local UIHelper = require(ReplicatedStorage.Shared.Modules.UIHelper)
			if UIHelper and UIHelper.spawnSparkles then
				UIHelper.spawnSparkles(hubButton, hubButton.AbsoluteSize.X/2, hubButton.AbsoluteSize.Y/2, Color3.fromRGB(255,255,255), 8)
			end
		end
	end)
else
	-- Build on first require
	task.spawn(function()
		local gui = buildWheelGui()
		if gui and hubButton then
			hubButton.MouseButton1Click:Connect(function()
				if RunService:IsStudio() and RunService:IsEdit() then return end
				if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
				PeaWheelController.toggle()
			end)
		end
	end)
end

-- Expose Globals
_G.PeaWheelController = PeaWheelController
_G.PeaWheel = PeaWheelController

print("[PeaWheelController] Ready — hub at bottom-right, hold Tab to open")

return PeaWheelController
