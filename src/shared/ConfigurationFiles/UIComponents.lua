--!strict
-- [[ModuleScript] UIComponents]]
-- Shared reusable UI component factory.
-- All UI elements should be created through this module for visual consistency.

local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local UIComponents = {}

-- Apply a UICorner to an instance
local function applyCorner(instance: GuiObject, radius: UDim?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UIConfig.CORNER_RADIUS.Medium
	corner.Parent = instance
	return corner
end

-- Apply a UIStroke to an instance
local function applyStroke(instance: GuiObject, color: Color3?, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or UIConfig.COLORS.Border
	stroke.Thickness = thickness or UIConfig.STROKE.Normal
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

-- Apply a UIPadding to an instance
local function applyPadding(instance: GuiObject, padding: number?): UIPadding
	local pad = Instance.new("UIPadding")
	local offset = UDim.new(0, padding or UIConfig.SPACING.MD)
	pad.PaddingTop = offset
	pad.PaddingBottom = offset
	pad.PaddingLeft = offset
	pad.PaddingRight = offset
	pad.Parent = instance
	return pad
end

-- Create a panel (rounded, bordered container)
function UIComponents.createPanel(props: {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Color: Color3?,
	Transparency: number?,
	Parent: Instance?,
}?): Frame
	local p = props or {}
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = p.Size or UDim2.fromOffset(UIConfig.SIZES.PanelMinWidth, 200)
	panel.Position = p.Position or UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = p.AnchorPoint or Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = p.Color or UIConfig.COLORS.Surface
	panel.BackgroundTransparency = p.Transparency or UIConfig.TRANSPARENCY.Panel
	panel.BorderSizePixel = 0

	applyCorner(panel, UIConfig.CORNER_RADIUS.Large)
	applyStroke(panel, UIConfig.COLORS.Border, UIConfig.STROKE.Normal)
	applyPadding(panel)

	if p.Parent then
		panel.Parent = p.Parent
	end
	return panel
end

-- Create a text button
function UIComponents.createButton(props: {
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Color: Color3?,
	TextColor: Color3?,
	Parent: Instance?,
}?): TextButton
	local p = props or {}
	local btn = Instance.new("TextButton")
	btn.Name = "Button"
	btn.Text = p.Text or "Button"
	btn.Size = p.Size or UDim2.fromOffset(UIConfig.SIZES.ButtonMinWidth, UIConfig.SIZES.ButtonHeight)
	btn.Position = p.Position or UDim2.fromScale(0.5, 0.5)
	btn.AnchorPoint = p.AnchorPoint or Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = p.Color or UIConfig.COLORS.Primary
	btn.TextColor3 = p.TextColor or UIConfig.COLORS.TextOnPrimary
	btn.FontFace = UIConfig.FONTS.Heading
	btn.TextSize = UIConfig.FONT_SIZES.Button
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true

	applyCorner(btn, UIConfig.CORNER_RADIUS.Medium)
	applyStroke(btn, UIConfig.COLORS.PrimaryDark, UIConfig.STROKE.Thin)

	if p.Parent then
		btn.Parent = p.Parent
	end
	return btn
end

-- Create a text label
function UIComponents.createLabel(props: {
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	FontFace: Font?,
	TextSize: number?,
	TextColor: Color3?,
	TextXAlignment: Enum.TextXAlignment?,
	Parent: Instance?,
}?): TextLabel
	local p = props or {}
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Text = p.Text or ""
	label.Size = p.Size or UDim2.new(1, 0, 0, UIConfig.FONT_SIZES.Body + UIConfig.SPACING.SM)
	label.Position = p.Position or UDim2.new()
	label.BackgroundTransparency = 1
	label.FontFace = p.FontFace or UIConfig.FONTS.Body
	label.TextSize = p.TextSize or UIConfig.FONT_SIZES.Body
	label.TextColor3 = p.TextColor or UIConfig.COLORS.TextPrimary
	label.TextXAlignment = p.TextXAlignment or Enum.TextXAlignment.Left
	label.BorderSizePixel = 0

	if p.Parent then
		label.Parent = p.Parent
	end
	return label
end

-- Create a progress bar
function UIComponents.createProgressBar(props: {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	FillColor: Color3?,
	BackgroundColor: Color3?,
	Parent: Instance?,
}?): { Frame: Frame, Fill: Frame, setProgress: (number) -> () }
	local p = props or {}

	local bg = Instance.new("Frame")
	bg.Name = "ProgressBar"
	bg.Size = p.Size or UDim2.fromOffset(UIConfig.SIZES.ProgressBarWidth, UIConfig.SIZES.ProgressBarHeight)
	bg.Position = p.Position or UDim2.fromScale(0.5, 0.5)
	bg.AnchorPoint = p.AnchorPoint or Vector2.new(0.5, 0.5)
	bg.BackgroundColor3 = p.BackgroundColor or UIConfig.COLORS.Background
	bg.BorderSizePixel = 0

	applyCorner(bg, UIConfig.CORNER_RADIUS.Small)
	applyStroke(bg, UIConfig.COLORS.Border, UIConfig.STROKE.Thin)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = p.FillColor or UIConfig.COLORS.Primary
	fill.BorderSizePixel = 0
	fill.Parent = bg

	applyCorner(fill, UIConfig.CORNER_RADIUS.Small)

	if p.Parent then
		bg.Parent = p.Parent
	end

	local function setProgress(fraction: number)
		local clamped = math.clamp(fraction, 0, 1)
		fill:TweenSize(
			UDim2.new(clamped, 0, 1, 0),
			Enum.EasingDirection.Out,
			UIConfig.EASING.Default,
			UIConfig.ANIMATION.Fast,
			true
		)
	end

	return { Frame = bg, Fill = fill, setProgress = setProgress }
end

-- Create an item slot (square container for inventory items)
function UIComponents.createItemSlot(props: {
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance?,
}?): Frame
	local p = props or {}
	local size = UIConfig.SIZES.ItemSlot

	local slot = Instance.new("Frame")
	slot.Name = "ItemSlot"
	slot.Size = p.Size or UDim2.fromOffset(size, size)
	slot.Position = p.Position or UDim2.new()
	slot.BackgroundColor3 = UIConfig.COLORS.SurfaceLight
	slot.BorderSizePixel = 0

	applyCorner(slot, UIConfig.CORNER_RADIUS.Medium)
	applyStroke(slot, UIConfig.COLORS.BorderDim, UIConfig.STROKE.Thin)

	if p.Parent then
		slot.Parent = p.Parent
	end
	return slot
end

-- Create a tooltip frame
function UIComponents.createTooltip(props: {
	Text: string?,
	Parent: Instance?,
}?): Frame
	local p = props or {}

	local tip = Instance.new("Frame")
	tip.Name = "Tooltip"
	tip.Size = UDim2.fromOffset(UIConfig.SIZES.TooltipMaxWidth, 0)
	tip.AutomaticSize = Enum.AutomaticSize.Y
	tip.BackgroundColor3 = UIConfig.COLORS.Background
	tip.BackgroundTransparency = UIConfig.TRANSPARENCY.Panel
	tip.BorderSizePixel = 0

	applyCorner(tip, UIConfig.CORNER_RADIUS.Small)
	applyStroke(tip, UIConfig.COLORS.BorderDim, UIConfig.STROKE.Thin)
	applyPadding(tip, UIConfig.SPACING.SM)

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.FontFace = UIConfig.FONTS.Caption
	label.TextSize = UIConfig.FONT_SIZES.Tooltip
	label.TextColor3 = UIConfig.COLORS.TextSecondary
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = p.Text or ""
	label.Parent = tip

	if p.Parent then
		tip.Parent = p.Parent
	end
	return tip
end

-- Animate a GuiObject in (fade + slide from bottom)
function UIComponents.animateIn(instance: GuiObject)
	local targetPos = instance.Position
	instance.Position = targetPos + UDim2.fromOffset(0, 20)
	instance.BackgroundTransparency = 1

	instance:TweenPosition(
		targetPos,
		Enum.EasingDirection.Out,
		UIConfig.EASING.Default,
		UIConfig.ANIMATION.SlideIn,
		true
	)

	local tweenService = game:GetService("TweenService")
	tweenService:Create(instance, TweenInfo.new(
		UIConfig.ANIMATION.FadeIn,
		UIConfig.EASING.Smooth,
		Enum.EasingDirection.Out
	), { BackgroundTransparency = 0 }):Play()
end

-- Animate a GuiObject out (fade + slide down), then destroy
function UIComponents.animateOut(instance: GuiObject, callback: (() -> ())?)
	local tweenService = game:GetService("TweenService")

	instance:TweenPosition(
		instance.Position + UDim2.fromOffset(0, 20),
		Enum.EasingDirection.In,
		UIConfig.EASING.Default,
		UIConfig.ANIMATION.FadeOut,
		true
	)

	local tween = tweenService:Create(instance, TweenInfo.new(
		UIConfig.ANIMATION.FadeOut,
		UIConfig.EASING.Smooth,
		Enum.EasingDirection.In
	), { BackgroundTransparency = 1 })

	tween.Completed:Connect(function()
		instance:Destroy()
		if callback then
			callback()
		end
	end)
	tween:Play()
end

return UIComponents
