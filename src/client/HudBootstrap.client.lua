-- [[LocalScript] HudBootstrap]]
-- Creates the main ZundaHUD with all action buttons
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- Create ZundaHUD ScreenGui
local hud = Instance.new("ScreenGui")
hud.Name = "ZundaHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.DisplayOrder = 10
hud.Parent = playerGui

print("[HudBootstrap] ZundaHUD created")

-- Create HudButtons container
local hudButtons = Instance.new("Frame")
hudButtons.Name = "HudButtons"
hudButtons.Size = UDim2.new(0, 400, 0, 60)
hudButtons.Position = UDim2.new(1, -420, 1, -80)
hudButtons.BackgroundColor3 = UIConfig.COLORS.Surface
hudButtons.BackgroundTransparency = 0.2
hudButtons.BorderSizePixel = 0
hudButtons.Parent = hud
Instance.new("UICorner", hudButtons).CornerRadius = UDim.new(0, 12)

local layout = Instance.new("UIListLayout", hudButtons)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local uiPadding = Instance.new("UIPadding", hudButtons)
uiPadding.PaddingLeft = UDim.new(0, 8)
uiPadding.PaddingRight = UDim.new(0, 8)
uiPadding.PaddingTop = UDim.new(0, 8)
uiPadding.PaddingBottom = UDim.new(0, 8)

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
    btn.Name = btnDef.Name
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
    
    print("[HudBootstrap] Created button:", btnDef.Name)
end

-- Create StatBar (for XP, level, etc.)
local statBar = Instance.new("Frame")
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
