-- [[LocalScript] HudBootstrap]]
-- Creates the main ZundaHUD with all action buttons
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- Share one persistent root with HudScript regardless of LocalScript start order.
local existingHud = playerGui:FindFirstChild("ZundaHUD")
local hud = if existingHud and existingHud:IsA("ScreenGui") then existingHud else Instance.new("ScreenGui")
hud.Name = "ZundaHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.DisplayOrder = 10
hud.Parent = playerGui

print("[HudBootstrap] ZundaHUD created")

-- Create HudButtons container
local existingButtons = hud:FindFirstChild("HudButtons")
local hudButtons = if existingButtons and existingButtons:IsA("Frame") then existingButtons else Instance.new("Frame")
hudButtons.Name = "HudButtons"
hudButtons.Size = UDim2.new(0, 400, 0, 60)
hudButtons.Position = UDim2.new(1, -420, 1, -80)
hudButtons.BackgroundColor3 = UIConfig.COLORS.Surface
hudButtons.BackgroundTransparency = 0.2
hudButtons.BorderSizePixel = 0
hudButtons.Parent = hud
Instance.new("UICorner", hudButtons).CornerRadius = UDim.new(0, 12)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = hudButtons

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingLeft = UDim.new(0, 8)
uiPadding.PaddingRight = UDim.new(0, 8)
uiPadding.PaddingTop = UDim.new(0, 8)
uiPadding.PaddingBottom = UDim.new(0, 8)
uiPadding.Parent = hudButtons

local RS = game:GetService("ReplicatedStorage")
local UIHelper = require(RS.Shared.Modules.UIHelper)

print("[HudBootstrap] HudButtons container created")

-- Create action buttons
local BUTTONS = {
	{ name = "HudBtn_inventory", text = "🎒", tooltip = "Inventory (I)", order = 1 },
	{ name = "HudBtn_crafting", text = "🍳", tooltip = "Crafting (K)", order = 2 },
	{ name = "HudBtn_quests", text = "📋", tooltip = "Quests (J)", order = 3 },
	{ name = "HudBtn_compendium", text = "📚", tooltip = "Compendium (C)", order = 4 },
	{ name = "HudBtn_materials", text = "🧪", tooltip = "Materials (M)", order = 5 },
	{ name = "HudBtn_settings", text = "⚙️", tooltip = "Settings", order = 6 },
	{ name = "HudBtn_shop", text = "🛒", tooltip = "Shop", order = 7 },
}

for _, btnDef in ipairs(BUTTONS) do
	local btn = Instance.new("TextButton")
	btn.Name = btnDef.name
	btn.Size = UDim2.new(0, 44, 0, 44)
	btn.BackgroundColor3 = UIConfig.COLORS.SurfaceLight
	btn.Text = btnDef.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 24
	btn.TextColor3 = UIConfig.COLORS.TextPrimary
	btn.BorderSizePixel = 0
	btn.LayoutOrder = btnDef.order
	btn.Parent = hudButtons

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	-- Add hover effect
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = UIConfig.COLORS.Primary
		btn.TextColor3 = UIConfig.COLORS.TextOnPrimary
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = UIConfig.COLORS.SurfaceLight
		btn.TextColor3 = UIConfig.COLORS.TextPrimary
	end)

	-- Cute sparkle on every HUD button click
	btn.MouseButton1Click:Connect(function()
		local pos = btn.AbsolutePosition
		UIHelper.spawnSparkles(btn, pos.X + btn.AbsoluteSize.X/2, pos.Y + btn.AbsoluteSize.Y/2, UIConfig.COLORS.Primary, 6)
	end)

	print("[HudBootstrap] Created button:", btnDef.name)
end

-- Create StatBar (for XP, level, etc.)
local existingStatBar = hud:FindFirstChild("StatBar")
local statBar = if existingStatBar and existingStatBar:IsA("Frame") then existingStatBar else Instance.new("Frame")
statBar.Name = "StatBar"
statBar.Size = UDim2.new(0, 300, 0, 40)
statBar.Position = UDim2.new(0, 20, 1, -60)
statBar.BackgroundColor3 = UIConfig.COLORS.Surface
statBar.BackgroundTransparency = 0.2
statBar.BorderSizePixel = 0
statBar.Parent = hud
Instance.new("UICorner", statBar).CornerRadius = UDim.new(0, 10)

print("[HudBootstrap] StatBar created")

print("[HudBootstrap] ZundaHUD fully initialized with", #BUTTONS, "buttons")
