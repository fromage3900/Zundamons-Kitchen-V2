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
-- FIX: Use brighter background so HUD is visible against dark Studio background
hudButtons.BackgroundColor3 = Color3.fromRGB(40, 35, 55) -- Brighter dark purple instead of muddy brown
hudButtons.BackgroundTransparency = 0.15
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

local UIHelper = require(RS.Shared.Modules.UIHelper)
local ActionRegistry = require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

print("[HudBootstrap] HudButtons container created")

-- FIX: Check if buttons already exist (prevents duplicates on respawn)
local existingButtonCount = 0
for _, child in ipairs(hudButtons:GetChildren()) do
	if child:IsA("TextButton") and child.Name:match("^HudBtn_") then
		existingButtonCount = existingButtonCount + 1
	end
end

-- Create action buttons (only if they don't already exist)
local BUTTONS = {
	{ name = "HudBtn_inventory", text = "🎒", tooltip = "Inventory [I]", order = 1 },
	{ name = "HudBtn_crafting", text = "🍳", tooltip = "Crafting", order = 2 },
	{ name = "HudBtn_quests", text = "📋", tooltip = "Quests [J]", order = 3 },
	{ name = "HudBtn_daily", text = "📅", tooltip = "Daily Planner", order = 4 },
	{ name = "HudBtn_compendium", text = "📚", tooltip = "Compendium [C]", order = 5 },
	{ name = "HudBtn_materials", text = "🧪", tooltip = "Materials", order = 6 },
	{ name = "HudBtn_settings", text = "⚙️", tooltip = "Settings [F1]", order = 7 },
	{ name = "HudBtn_shop", text = "🛒", tooltip = "Companions", order = 8 },
}

if existingButtonCount < #BUTTONS then
	for _, btnDef in ipairs(BUTTONS) do
		-- Skip if this button already exists
		if hudButtons:FindFirstChild(btnDef.name) then
			continue
		end
		
		local btn = Instance.new("TextButton")
		btn.Name = btnDef.name
		btn.Size = UDim2.new(0, 44, 0, 44)
		-- FIX: Use brighter button background so it's visible
		btn.BackgroundColor3 = Color3.fromRGB(60, 52, 75) -- Brighter than SurfaceLight
		btn.Text = btnDef.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 24
		btn.TextColor3 = UIConfig.COLORS.TextWhite
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
			btn.BackgroundColor3 = Color3.fromRGB(60, 52, 75)
			btn.TextColor3 = UIConfig.COLORS.TextWhite
		end)

		-- Cute sparkle on every HUD button click
		btn.MouseButton1Click:Connect(function()
			local pos = btn.AbsolutePosition
			UIHelper.spawnSparkles(btn, pos.X + btn.AbsoluteSize.X/2, pos.Y + btn.AbsoluteSize.Y/2, UIConfig.COLORS.Primary, 6)
			if btnDef.name == "HudBtn_daily" and _G.DailyChecklist then
				_G.DailyChecklist.toggle()
			else
				local actionMap = {
					HudBtn_inventory  = "inventory",
					HudBtn_crafting   = "cook",
					HudBtn_quests     = "quests",
					HudBtn_compendium = "compendium",
					HudBtn_materials  = "materials",
					HudBtn_settings   = "settings",
					HudBtn_shop       = "companions",
				}
				local targetAction = actionMap[btnDef.name]
				if targetAction and ActionRegistry then
					ActionRegistry.dispatch(targetAction)
				end
			end
		end)

		print("[HudBootstrap] Created button:", btnDef.name)
	end
else
	print("[HudBootstrap] Buttons already exist (" .. existingButtonCount .. "), skipping creation")
end

-- Create StatBar (for XP, level, etc.)
local existingStatBar = hud:FindFirstChild("StatBar")
local statBar = if existingStatBar and existingStatBar:IsA("Frame") then existingStatBar else Instance.new("Frame")
statBar.Name = "StatBar"
statBar.Size = UDim2.new(0, 300, 0, 40)
statBar.Position = UDim2.new(0, 20, 1, -60)
-- FIX: Use brighter background so StatBar is visible
statBar.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
statBar.BackgroundTransparency = 0.15
statBar.BorderSizePixel = 0
statBar.Parent = hud
Instance.new("UICorner", statBar).CornerRadius = UDim.new(0, 10)

print("[HudBootstrap] StatBar created")

print("[HudBootstrap] ZundaHUD fully initialized with", #BUTTONS, "buttons")
