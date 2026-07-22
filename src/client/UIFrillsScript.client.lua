--!strict
-- Shared cozy polish for code-authored interfaces. This layer is decorative:
-- it never creates gameplay panels or changes their visibility/state.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
	cream = Color3.fromRGB(255, 250, 242),
	blush = Color3.fromRGB(244, 187, 202),
	mint = Color3.fromRGB(178, 222, 181),
	pea = Color3.fromRGB(112, 174, 116),
	ink = Color3.fromRGB(83, 63, 78),
}

local PANEL_NAMES = {
	Panel = true,
	VNPanel = true,
	MainPanel = true,
	Content = true,
}

local GUI_NAMES = {
	ZundaPouchGui = true,
	QuestGui = true,
	CraftingGui = true,
	CompanionShopGui = true,
	ZundaVNGui = true,
	MaterialsGui = true,
	CompendiumGui = true,
}

local function decoratePanel(frame: Frame)
	if frame:GetAttribute("CozyFrillsApplied") then
		return
	end
	frame:SetAttribute("CozyFrillsApplied", true)

	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = frame

	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Name = "CozyBorder"
	stroke.Color = COLORS.blush
	stroke.Thickness = 2
	stroke.Transparency = 0.16
	stroke.Parent = frame

	if not frame:FindFirstChild("CozyGradient") then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "CozyGradient"
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.cream),
			ColorSequenceKeypoint.new(0.58, Color3.fromRGB(252, 242, 238)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 248, 232)),
		})
		gradient.Rotation = 18
		gradient.Parent = frame
	end

	if not frame:FindFirstChild("CozyAccent") then
		local accent = Instance.new("Frame")
		accent.Name = "CozyAccent"
		accent.Size = UDim2.new(0, 72, 0, 5)
		accent.Position = UDim2.new(0, 18, 0, 9)
		accent.BackgroundColor3 = COLORS.mint
		accent.BorderSizePixel = 0
		accent.ZIndex = frame.ZIndex + 1
		accent.Parent = frame
		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent
	end
end

local function decorateButton(button: GuiButton)
	if button:GetAttribute("CozyButtonApplied") then
		return
	end
	button:SetAttribute("CozyButtonApplied", true)
	button.AutoButtonColor = false

	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = button

	local restingColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		restingColor = button.BackgroundColor3
		local hoverColor = restingColor:Lerp(COLORS.cream, 0.16)
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.035 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = hoverColor }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = restingColor }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.97 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.09, Enum.EasingStyle.Back), { Scale = 1.035 }):Play()
	end)
end

local function polish(instance: Instance)
	if instance:IsA("Frame") and PANEL_NAMES[instance.Name] then
		local screenGui = instance:FindFirstAncestorWhichIsA("ScreenGui")
		if screenGui and GUI_NAMES[screenGui.Name] then
			decoratePanel(instance)
		end
	elseif instance:IsA("TextButton") or instance:IsA("ImageButton") then
		decorateButton(instance)
	end
end

local function polishTree(root: Instance)
	polish(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		polish(descendant)
	end
end

polishTree(playerGui)
playerGui.DescendantAdded:Connect(function(instance)
	task.defer(polish, instance)
end)

print("[UIFrills] Cozy, idempotent UI polish active")
