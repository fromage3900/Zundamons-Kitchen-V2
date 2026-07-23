--!strict
-- [[LocalScript] PeaWheelController]]
-- Input state machine and action dispatch for the Pea Wheel radial menu.
-- Features centered 360° radial menu overlay with bottom-right quick trigger button.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)
local playerScripts = player:WaitForChild("PlayerScripts")
local ActionRegistry = require(playerScripts:WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))
local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)

local PeaWheelController = {}

local wheelGui: ScreenGui? = nil
local backdropFrame: Frame? = nil
local wheelFrame: Frame? = nil
local hubButton: TextButton? = nil
local centerHub: Frame? = nil
local sliceButtons: { [number]: TextButton } = {}
local tooltipLabel: TextLabel? = nil

local isOpen = false
local selectedIndex = 1
-- ReducedMotionEnabled lives on GuiService, not UserInputService. Reading it off
-- UserInputService threw and crashed the whole module load, so the wheel never built.
local reducedMotion = GuiService.ReducedMotionEnabled

local wheelScale: UIScale? = nil
local currentTargetScale = 1.0

local function updateWheelScale()
	if not wheelFrame then return end
	if not wheelScale then
		wheelScale = wheelFrame:FindFirstChildOfClass("UIScale")
	end
	if not wheelScale then return end

	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local viewW = viewportSize.X
	local viewH = viewportSize.Y

	if viewW <= 0 or viewH <= 0 then return end

	-- Wheel total footprint: 386px vertical height, 332px horizontal width.
	-- Scale factor ensures wheel bounds never clip off screen edges (88% viewport margin factor).
	local scaleH = (viewH * 0.88) / 386
	local scaleW = (viewW * 0.88) / 332
	local fitScale = math.min(scaleH, scaleW)
	currentTargetScale = math.clamp(fitScale, 0.55, 1.20)

	if isOpen then
		wheelScale.Scale = currentTargetScale
	end
end

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

	-- DisplayOrder must sit ABOVE full-screen overlays (UIPolishGui sparkles and
	-- TutorialGui both use 999) or the wheel opens behind them and looks like the
	-- hub click did nothing. The radial menu is top-level when open.
	wheelGui = ClientGuiBootstrap.createScreenGui(player, "PeaWheelGui", 1000)
	wheelGui.ResetOnSpawn = false
	wheelGui.IgnoreGuiInset = true

	-- Backdrop
	backdropFrame = Instance.new("Frame")
	backdropFrame.Name = "Backdrop"
	backdropFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	backdropFrame.Position = UDim2.fromScale(0.5, 0.5)
	backdropFrame.Size = UDim2.fromScale(1, 1)
	backdropFrame.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
	backdropFrame.BackgroundTransparency = 0.55
	backdropFrame.Visible = false
	backdropFrame.Parent = wheelGui

	-- Centered Wheel Container
	wheelFrame = Instance.new("Frame")
	wheelFrame.Name = "WheelFrame"
	wheelFrame.Size = UDim2.fromOffset(340, 340)
	wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelFrame.Position = UDim2.fromScale(0.5, 0.5)
	wheelFrame.BackgroundTransparency = 1
	wheelFrame.Visible = false
	wheelFrame.Parent = wheelGui

	-- Dynamic UIScale to prevent edge clipping on small/mobile viewports
	wheelScale = Instance.new("UIScale")
	wheelScale.Name = "WheelScale"
	wheelScale.Scale = 1
	wheelScale.Parent = wheelFrame

	updateWheelScale()

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateWheelScale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateWheelScale)
			updateWheelScale()
		end
	end)

	-- Center Hub Core
	centerHub = Instance.new("Frame")
	centerHub.Name = "CenterHub"
	centerHub.Size = UDim2.fromOffset(88, 88)
	centerHub.AnchorPoint = Vector2.new(0.5, 0.5)
	centerHub.Position = UDim2.fromScale(0.5, 0.5)
	centerHub.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
	centerHub.Parent = wheelFrame
	Instance.new("UICorner", centerHub).CornerRadius = UDim.new(0.5, 0)
	local centerStroke = Instance.new("UIStroke", centerHub)
	centerStroke.Color = Color3.fromRGB(255, 183, 197)
	centerStroke.Thickness = 3

	local hubIcon = Instance.new("TextLabel")
	hubIcon.Name = "HubIcon"
	hubIcon.Size = UDim2.fromScale(1, 1)
	hubIcon.BackgroundTransparency = 1
	hubIcon.Text = "🌱"
	hubIcon.TextScaled = true
	hubIcon.Font = Enum.Font.FredokaOne
	hubIcon.Parent = centerHub

	-- Bottom-Right Quick Trigger Button
	hubButton = Instance.new("TextButton")
	hubButton.Name = "HubButton"
	hubButton.Size = UDim2.fromOffset(64, 64)
	hubButton.AnchorPoint = Vector2.new(1, 1)
	hubButton.Position = UDim2.fromScale(1, 1) - UDim2.fromOffset(24, 24)
	hubButton.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
	-- 🌱 (pea pod, Unicode 14) is not in Roblox's emoji set and renders as a tofu box.
	-- 🌱 is supported and on-theme.
	hubButton.Text = "🌱"
	hubButton.TextScaled = true
	hubButton.Font = Enum.Font.FredokaOne
	hubButton.TextColor3 = Color3.fromRGB(255, 250, 245)
	hubButton.Parent = wheelGui
	Instance.new("UICorner", hubButton).CornerRadius = UDim.new(0.5, 0)
	local hubStroke = Instance.new("UIStroke", hubButton)
	hubStroke.Color = Color3.fromRGB(255, 183, 197)
	hubStroke.Thickness = 2

	hubButton.MouseButton1Click:Connect(function()
		if RunService:IsStudio() and RunService:IsEdit() then return end
		if _G.TimedCooking and _G.TimedCooking.isCooking and _G.TimedCooking.isCooking() then return end
		PeaWheelController.toggle()
	end)

	-- Tooltip Label
	tooltipLabel = Instance.new("TextLabel")
	tooltipLabel.Name = "Tooltip"
	tooltipLabel.Size = UDim2.fromOffset(220, 36)
	tooltipLabel.AnchorPoint = Vector2.new(0.5, 0)
	tooltipLabel.Position = UDim2.new(0.5, 0, 1, 14)
	tooltipLabel.BackgroundTransparency = 1
	tooltipLabel.Text = ""
	tooltipLabel.Font = Enum.Font.FredokaOne
	tooltipLabel.TextSize = 18
	tooltipLabel.TextColor3 = Color3.fromRGB(255, 245, 250)
	tooltipLabel.TextStrokeTransparency = 0.2
	tooltipLabel.Visible = false
	tooltipLabel.Parent = wheelFrame

	-- Build 8 Radial Slices centered around wheelFrame
	sliceButtons = {}
	local sliceList = ActionRegistry.getOrderedSliceList()
	local radius = 125

	for i, actionId in ipairs(sliceList) do
		local def = ActionRegistry.getAction(actionId)
		if not def then continue end

		local btn = Instance.new("TextButton")
		btn.Name = "Slice_" .. actionId
		btn.Size = UDim2.fromOffset(68, 68)
		btn.AnchorPoint = Vector2.new(0.5, 0.5)

		local pastel = NIKKI_PASTELS[i] or Color3.fromRGB(255, 182, 193)
		btn.BackgroundColor3 = pastel
		btn.Text = def.icon
		btn.TextScaled = true
		btn.Font = Enum.Font.FredokaOne
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = wheelFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 0)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 2.5
		stroke.Transparency = 0.2

		-- Position evenly at 45° intervals starting from top (-90°)
		local angle = math.rad(-90 + (i - 1) * 45)
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius
		btn.Position = UDim2.new(0.5, x, 0.5, y)

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
	if not wheelFrame or not tooltipLabel then return end
	local sliceList = ActionRegistry.getOrderedSliceList()
	local actionId = sliceList[selectedIndex]
	local def = ActionRegistry.getAction(actionId)

	for i, btn in ipairs(sliceButtons) do
		local isSel = (i == selectedIndex)
		local targetSize = isSel and 82 or 68
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(targetSize, targetSize),
		}):Play()
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = isSel and 4 or 2.5
			stroke.Transparency = isSel and 0 or 0.2
		end
	end

	if def then
		tooltipLabel.Text = def.icon .. "  " .. def.label
		tooltipLabel.Visible = true
	end
end

-- ── Open / Close / Toggle ────────────────────────────────────
function PeaWheelController.open()
	if isOpen then return end
	if RunService:IsStudio() and RunService:IsEdit() then return end

	local gui = buildWheelGui()
	if not gui or not wheelFrame or not backdropFrame then return end

	isOpen = true
	selectedIndex = 1

	updateWheelScale()

	backdropFrame.Visible = true
	wheelFrame.Visible = true
	wheelFrame.Size = UDim2.fromOffset(340, 340)

	if wheelScale then
		if reducedMotion then
			wheelScale.Scale = currentTargetScale
		else
			wheelScale.Scale = currentTargetScale * 0.15
			TweenService:Create(wheelScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = currentTargetScale,
			}):Play()
		end
	end

	PeaWheelController.updateSelectionVisual()
end

function PeaWheelController.close()
	if not isOpen then return end
	isOpen = false

	if wheelFrame and backdropFrame then
		if wheelScale and not reducedMotion then
			TweenService:Create(wheelScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = currentTargetScale * 0.15,
			}):Play()
			task.delay(0.16, function()
				if wheelFrame then wheelFrame.Visible = false end
				if backdropFrame then backdropFrame.Visible = false end
				if wheelScale then wheelScale.Scale = currentTargetScale end
			end)
		else
			if wheelFrame then wheelFrame.Visible = false end
			if backdropFrame then backdropFrame.Visible = false end
			if wheelScale then wheelScale.Scale = currentTargetScale end
		end
	end

	if tooltipLabel then
		tooltipLabel.Visible = false
	end
end

function PeaWheelController.toggle()
	if isOpen then
		PeaWheelController.close()
	else
		PeaWheelController.open()
	end
end

function PeaWheelController.select(actionId: string)
	if not isOpen then return false end
	local ok = ActionRegistry.dispatch(actionId)
	PeaWheelController.close()
	return ok
end

-- ── Keyboard Input ───────────────────────────────────────────
local function onInputBegan(input, processed)
	-- Keybind: Tab or Q key to toggle radial wheel instantly when not typing in text box
	if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.Q then
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end
		PeaWheelController.toggle()
		return
	end

	if processed then return end

	-- Slice Navigation when Open
	if isOpen then
		local sliceList = ActionRegistry.getOrderedSliceList()
		local count = #sliceList
		if input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
			selectedIndex = (selectedIndex % count) + 1
			PeaWheelController.updateSelectionVisual()
		elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
			selectedIndex = ((selectedIndex - 2 + count) % count) + 1
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
	-- Retained for input end handling if required
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

buildWheelGui()

_G.PeaWheelController = PeaWheelController
_G.PeaWheel = PeaWheelController

print("[PeaWheelController] Ready — centered radial menu overlay initialized ✓")
return PeaWheelController
