--!strict
-- [[ModuleScript] GameUIComponents]]
-- Game-specific UI components for Zundamon's Kitchen
-- Integrates with UIConfig for consistent styling

local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local TweenService = game:GetService("TweenService")

local GameUIComponents = {}

-- ============================================
-- RECIPE CARD COMPONENT
-- ============================================
function GameUIComponents.createRecipeCard(props: {
	RecipeName: string?,
	Description: string?,
	Rarity: string?,
	IsLocked: boolean?,
	IsSelected: boolean?,
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance?,
	onClick: (() -> ())?,
}): Frame
	local p = props or {}
	
	local card = Instance.new("Frame")
	card.Name = "RecipeCard"
	card.Size = p.Size or UDim2.fromOffset(200, 250)
	card.Position = p.Position or UDim2.new()
	card.BackgroundColor3 = UIConfig.COLORS.CreamWhite
	card.BorderSizePixel = 0
	
	-- Border styling
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIConfig.COLORS.WoodLight
	stroke.Thickness = 3
	stroke.Parent = card
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	
	-- Card image placeholder
	local image = Instance.new("Frame")
	image.Name = "CardImage"
	image.Size = UDim2.new(1, -16, 0, 120)
	image.Position = UDim2.new(0, 8, 0, 8)
	image.BackgroundColor3 = UIConfig.COLORS.CreamDark
	image.BorderSizePixel = 0
	image.Parent = card
	
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 12)
	imageCorner.Parent = image
	
	-- Card content
	local content = Instance.new("Frame")
	content.Name = "CardContent"
	content.Size = UDim2.new(1, -16, 1, -136)
	content.Position = UDim2.new(0, 8, 0, 132)
	content.BackgroundTransparency = 1
	content.Parent = card
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "RecipeName"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = p.RecipeName or "Recipe Name"
	nameLabel.Font = UIConfig.FONTS.Title
	nameLabel.TextSize = UIConfig.FONT_SIZES.Heading
	nameLabel.TextColor3 = UIConfig.COLORS.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = content
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, 0, 1, -24)
	descLabel.Position = UDim2.new(0, 0, 0, 24)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = p.Description or "Recipe description"
	descLabel.Font = UIConfig.FONTS.Body
	descLabel.TextSize = UIConfig.FONT_SIZES.Small
	descLabel.TextColor3 = UIConfig.COLORS.TextSecondary
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = content
	
	-- Rarity badge
	if p.Rarity then
		local rarityColor = UIConfig.COLORS["Rarity" .. p.Rarity] or UIConfig.COLORS.RarityCommon
		
		local badge = Instance.new("TextLabel")
		badge.Name = "RarityBadge"
		badge.Size = UDim2.new(0, 60, 0, 24)
		badge.Position = UDim2.new(1, -68, 0, 8)
		badge.BackgroundColor3 = rarityColor
		badge.Text = p.Rarity:upper():sub(1, 1)
		badge.Font = UIConfig.FONTS.Heading
		badge.TextSize = 12
		badge.TextColor3 = UIConfig.COLORS.TextWhite
		badge.Parent = card
		
		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 8)
		badgeCorner.Parent = badge
	end
	
	-- Locked state
	if p.IsLocked then
		card.BackgroundTransparency = 0.4
		local lockIcon = Instance.new("TextLabel")
		lockIcon.Name = "LockIcon"
		lockIcon.Size = UDim2.new(0, 48, 0, 48)
		lockIcon.Position = UDim2.new(0.5, -24, 0.5, -24)
		lockIcon.BackgroundColor3 = UIConfig.COLORS.TextPrimary
		lockIcon.Text = "🔒"
		lockIcon.Font = UIConfig.FONTS.Title
		lockIcon.TextSize = 24
		lockIcon.TextColor3 = UIConfig.COLORS.TextWhite
		lockIcon.TextScaled = true
		lockIcon.Parent = card
		
		local lockCorner = Instance.new("UICorner")
		lockCorner.CornerRadius = UDim.new(0, 12)
		lockCorner.Parent = lockIcon
	end
	
	-- Selected state
	if p.IsSelected then
		stroke.Color = UIConfig.COLORS.PrimaryGreen
		stroke.Thickness = 4
	end
	
	-- Click handler
	if p.onClick then
		local button = Instance.new("TextButton")
		button.Name = "ClickArea"
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Parent = card
		button.MouseButton1Click:Connect(p.onClick)
	end
	
	if p.Parent then
		card.Parent = p.Parent
	end
	
	return card
end

-- ============================================
-- INGREDIENT CARD COMPONENT
-- ============================================
function GameUIComponents.createIngredientCard(props: {
	IngredientName: string?,
	Quantity: number?,
	Icon: string?,
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance?,
	onClick: (() -> ())?,
}): Frame
	local p = props or {}
	
	local card = Instance.new("Frame")
	card.Name = "IngredientCard"
	card.Size = p.Size or UDim2.fromOffset(100, 120)
	card.Position = p.Position or UDim2.new()
	card.BackgroundColor3 = UIConfig.COLORS.CreamWhite
	card.BorderSizePixel = 0
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIConfig.COLORS.WoodLight
	stroke.Thickness = 2
	stroke.Parent = card
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 48, 0, 48)
	icon.Position = UDim2.new(0.5, -24, 0, 16)
	icon.BackgroundTransparency = 1
	icon.Text = p.Icon or "🫛"
	icon.Font = UIConfig.FONTS.Title
	icon.TextSize = 32
	icon.TextColor3 = UIConfig.COLORS.TextPrimary
	icon.Parent = card
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 0, 0, 72)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = p.IngredientName or "Ingredient"
	nameLabel.Font = UIConfig.FONTS.Title
	nameLabel.TextSize = UIConfig.FONT_SIZES.Small
	nameLabel.TextColor3 = UIConfig.COLORS.TextPrimary
	nameLabel.Parent = card
	
	-- Quantity
	if p.Quantity then
		local qtyLabel = Instance.new("TextLabel")
		qtyLabel.Name = "Quantity"
		qtyLabel.Size = UDim2.new(1, 0, 0, 16)
		qtyLabel.Position = UDim2.new(0, 0, 0, 92)
		qtyLabel.BackgroundTransparency = 1
		qtyLabel.Text = "x" .. p.Quantity
		qtyLabel.Font = UIConfig.FONTS.Body
		qtyLabel.TextSize = UIConfig.FONT_SIZES.Tiny
		qtyLabel.TextColor3 = UIConfig.COLORS.TextSecondary
		qtyLabel.Parent = card
	end
	
	-- Click handler
	if p.onClick then
		local button = Instance.new("TextButton")
		button.Name = "ClickArea"
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Parent = card
		button.MouseButton1Click:Connect(p.onClick)
	end
	
	if p.Parent then
		card.Parent = p.Parent
	end
	
	return card
end

-- ============================================
-- CHEF PILL (HUD LEVEL DISPLAY)
-- ============================================
function GameUIComponents.createChefPill(props: {
	Level: number?,
	TierName: string?,
	TierBadge: string?,
	XP: number?,
	XPNeeded: number?,
	TierColor: Color3?,
	Position: UDim2?,
	Parent: Instance?,
}): Frame
	local p = props or {}
	
	local pill = Instance.new("Frame")
	pill.Name = "ChefPill"
	pill.Size = UDim2.fromOffset(300, 40)
	pill.Position = p.Position or UDim2.new()
	pill.BackgroundColor3 = Color3.fromRGB(61, 42, 74)
	pill.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = pill
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = p.TierColor or UIConfig.COLORS.PrimaryGreen
	stroke.Thickness = 2
	stroke.Parent = pill
	
	-- Badge
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(32, 32)
	badge.Position = UDim2.new(0, 4, 0.5, -16)
	badge.BackgroundTransparency = 1
	badge.Text = p.TierBadge or "🌱"
	badge.Font = UIConfig.FONTS.Title
	badge.TextSize = 24
	badge.TextColor3 = UIConfig.COLORS.TextWhite
	badge.Parent = pill
	
	-- Tier label
	local tierLabel = Instance.new("TextLabel")
	tierLabel.Name = "TierLabel"
	tierLabel.Size = UDim2.new(1, -140, 1, 0)
	tierLabel.Position = UDim2.new(0, 40, 0, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = (p.TierName or "Chef") .. " · Lv " .. (p.Level or 1)
	tierLabel.Font = UIConfig.FONTS.Heading
	tierLabel.TextSize = 14
	tierLabel.TextColor3 = UIConfig.COLORS.TextWhite
	tierLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierLabel.Parent = pill
	
	-- XP bar
	local xpBar = Instance.new("Frame")
	xpBar.Name = "XPBar"
	xpBar.Size = UDim2.fromOffset(120, 8)
	xpBar.Position = UDim2.new(1, -124, 0.5, -4)
	xpBar.BackgroundColor3 = Color3.fromRGB(45, 42, 58)
	xpBar.BorderSizePixel = 0
	xpBar.Parent = pill
	
	local xpCorner = Instance.new("UICorner")
	xpCorner.CornerRadius = UDim.new(0, 4)
	xpCorner.Parent = xpBar
	
	local xpFill = Instance.new("Frame")
	xpFill.Name = "Fill"
	xpFill.Size = UDim2.new(0, 0, 1, 0)
	xpFill.BackgroundColor3 = p.TierColor or UIConfig.COLORS.PrimaryGreen
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = xpFill
	
	-- Set XP progress
	if p.XP and p.XPNeeded and p.XPNeeded > 0 then
		local fraction = math.clamp(p.XP / p.XPNeeded, 0, 1)
		xpFill.Size = UDim2.new(fraction, 0, 1, 0)
	end
	
	if p.Parent then
		pill.Parent = p.Parent
	end
	
	return pill
end

-- ============================================
-- COMBO METER
-- ============================================
function GameUIComponents.createComboMeter(props: {
	Count: number?,
	Multiplier: number?,
	Position: UDim2?,
	Parent: Instance?,
}): Frame
	local p = props or {}
	
	local combo = Instance.new("Frame")
	combo.Name = "ComboMeter"
	combo.Size = UDim2.fromOffset(220, 70)
	combo.Position = p.Position or UDim2.new()
	combo.BackgroundColor3 = Color3.fromRGB(74, 50, 90)
	combo.BorderSizePixel = 0
	combo.BackgroundTransparency = 1
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = combo
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIConfig.COLORS.Warning
	stroke.Thickness = 2
	stroke.Parent = combo
	
	-- Count label
	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(1, 0, 0, 28)
	countLabel.Position = UDim2.new(0, 0, 0, 8)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = (p.Count or 0) .. " COMBO"
	countLabel.Font = UIConfig.FONTS.Title
	countLabel.TextSize = 16
	countLabel.TextColor3 = UIConfig.COLORS.TextWhite
	countLabel.Parent = combo
	
	-- Multiplier label
	local multLabel = Instance.new("TextLabel")
	multLabel.Name = "Multiplier"
	multLabel.Size = UDim2.new(1, 0, 0, 24)
	multLabel.Position = UDim2.new(0, 0, 0, 36)
	multLabel.BackgroundTransparency = 1
	multLabel.Text = "x" .. string.format("%.1f", p.Multiplier or 1)
	multLabel.Font = UIConfig.FONTS.Title
	multLabel.TextSize = 18
	multLabel.TextColor3 = UIConfig.COLORS.Warning
	multLabel.Parent = combo
	
	if p.Parent then
		combo.Parent = p.Parent
	end
	
	return combo
end

-- ============================================
-- ACHIEVEMENT TOAST
-- ============================================
function GameUIComponents.createAchievementToast(props: {
	Name: string?,
	Description: string?,
	Icon: string?,
	Position: UDim2?,
	Parent: Instance?,
	onDismiss: (() -> ())?,
}): Frame
	local p = props or {}
	
	local toast = Instance.new("Frame")
	toast.Name = "AchievementToast"
	toast.Size = UDim2.fromOffset(340, 70)
	toast.Position = p.Position or UDim2.new(1, 360, 0, 200)
	toast.BackgroundColor3 = Color3.fromRGB(40, 32, 60)
	toast.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = toast
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIConfig.COLORS.Warning
	stroke.Thickness = 2
	stroke.Parent = toast
	
	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(56, 56)
	icon.Position = UDim2.new(0, 8, 0, 7)
	icon.BackgroundTransparency = 1
	icon.Text = p.Icon or "🏆"
	icon.Font = UIConfig.FONTS.Title
	icon.TextSize = 32
	icon.TextColor3 = UIConfig.COLORS.Warning
	icon.Parent = toast
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -72, 0, 28)
	titleLabel.Position = UDim2.new(0, 72, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🏆 " .. (p.Name or "Achievement")
	titleLabel.Font = UIConfig.FONTS.Heading
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = UIConfig.COLORS.Warning
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = toast
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -72, 0, 24)
	descLabel.Position = UDim2.new(0, 72, 0, 38)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = p.Description or "Achievement description"
	descLabel.Font = UIConfig.FONTS.Body
	descLabel.TextSize = 12
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = toast
	
	-- Animate in
	toast.Size = UDim2.fromOffset(0, 70)
	TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(340, 70),
		Position = UDim2.new(1, -360, 0, 200)
	}):Play()
	
	-- Auto dismiss
	task.delay(4, function()
		TweenService:Create(toast, TweenInfo.new(0.4), {
			Size = UDim2.fromOffset(340, 0),
			Position = UDim2.new(1, 360, 0, 200)
		}):Play()
		task.wait(0.5)
		toast:Destroy()
		if p.onDismiss then
			p.onDismiss()
		end
	end)
	
	if p.Parent then
		toast.Parent = p.Parent
	end
	
	return toast
end

-- ============================================
-- LEVEL UP BANNER
-- ============================================
function GameUIComponents.createLevelUpBanner(props: {
	Level: number?,
	TierName: string?,
	TierColor: Color3?,
	TierBadge: string?,
	Parent: Instance?,
	onDismiss: (() -> ())?,
}): Frame
	local p = props or {}
	
	local banner = Instance.new("Frame")
	banner.Name = "LevelUpBanner"
	banner.Size = UDim2.fromOffset(460, 120)
	banner.Position = UDim2.new(0.5, -230, 0.3, -60)
	banner.BackgroundColor3 = Color3.fromRGB(40, 32, 60)
	banner.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = banner
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = p.TierColor or UIConfig.COLORS.Warning
	stroke.Thickness = 3
	stroke.Parent = banner
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 45)
	titleLabel.Position = UDim2.new(0, 0, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "LEVEL UP!"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 32
	titleLabel.TextColor3 = UIConfig.COLORS.Warning
	titleLabel.Parent = banner
	
	-- Subtitle
	local subTitleLabel = Instance.new("TextLabel")
	subTitleLabel.Size = UDim2.new(1, 0, 0, 45)
	subTitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subTitleLabel.BackgroundTransparency = 1
	subTitleLabel.Text = (p.TierBadge or "") .. " " .. (p.TierName or "Chef") .. " · Lv " .. (p.Level or 1)
	subTitleLabel.Font = Enum.Font.GothamBold
	subTitleLabel.TextSize = 20
	subTitleLabel.TextColor3 = UIConfig.COLORS.TextWhite
	subTitleLabel.Parent = banner
	
	-- Animate in
	banner.Size = UDim2.fromOffset(0, 120)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
		Size = UDim2.fromOffset(460, 120)
	}):Play()
	
	-- Auto dismiss
	task.delay(2.5, function()
		TweenService:Create(banner, TweenInfo.new(0.4), {
			Size = UDim2.fromOffset(460, 0)
		}):Play()
		task.wait(0.5)
		banner:Destroy()
		if p.onDismiss then
			p.onDismiss()
		end
	end)
	
	if p.Parent then
		banner.Parent = p.Parent
	end
	
	return banner
end

return GameUIComponents
