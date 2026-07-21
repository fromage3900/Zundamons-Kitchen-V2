-- [[LocalScript] UIFrillsScript (ref: RBXDC4909655A8448DEA1D4C3F4FB28313E)]]
-- UIFrills: Adds decorative frills and borders to UI panels
-- Makes the UI feel more polished and Zunda-themed

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Decorative colors
local COLORS = {
    pink = Color3.fromRGB(255, 182, 200),
    green = Color3.fromRGB(130, 200, 100),
    cream = Color3.fromRGB(252, 248, 240),
    border = Color3.fromRGB(232, 152, 168),
    gold = Color3.fromRGB(255, 200, 100),
}

-- Function to add frilly corners to a frame
local function addFrillyCorners(frame, size)
    size = size or 22
    
    -- Main corner
    local corner = frame:FindFirstChild("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Parent = frame
    end
    corner.CornerRadius = UDim.new(0, size)
    
    -- Decorative border
    local stroke = frame:FindFirstChild("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = frame
    end
    stroke.Thickness = 3
    stroke.Color = COLORS.border
end

-- Function to add a decorative header ribbon
local function addHeaderRibbon(frame, text)
    local ribbon = Instance.new("Frame")
    ribbon.Name = "HeaderRibbon"
    ribbon.Size = UDim2.new(1, 0, 0, 8)
    ribbon.Position = UDim2.new(0, 0, 0, 0)
    ribbon.BackgroundColor3 = COLORS.pink
    ribbon.BorderSizePixel = 0
    ribbon.ZIndex = frame.ZIndex + 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = ribbon
    
    -- Cover bottom corners
    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(1, 0, 0.5, 0)
    cover.Position = UDim2.new(0, 0, 0.5, 0)
    cover.BackgroundColor3 = COLORS.pink
    cover.BorderSizePixel = 0
    cover.ZIndex = ribbon.ZIndex
    cover.Parent = ribbon
    
    ribbon.Parent = frame
    return ribbon
end

-- Function to add floating decorative elements
local function addFloatingDecorations(frame)
    -- Add small decorative dots in corners
    local positions = {
        UDim2.new(0, 8, 0, 8),
        UDim2.new(1, -16, 0, 8),
        UDim2.new(0, 8, 1, -16),
        UDim2.new(1, -16, 1, -16),
    }
    
    for i, pos in ipairs(positions) do
        local dot = Instance.new("Frame")
        dot.Name = "DecoDot" .. i
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = pos
        dot.BackgroundColor3 = COLORS.green
        dot.BorderSizePixel = 0
        dot.ZIndex = frame.ZIndex + 2
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = dot
        
        dot.Parent = frame
    end
end

-- Function to add a subtle gradient background
local function addGradientBackground(frame, color1, color2)
    color1 = color1 or Color3.fromRGB(255, 250, 245)
    color2 = color2 or Color3.fromRGB(245, 240, 230)
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = 45
    gradient.Parent = frame
end

-- Apply frills to existing UI panels
task.spawn(function()
    task.wait(2) -- Wait for UI to load
    
    -- Apply to ZundaPouch panel (Rojo or legacy name)
    local pouchGui = playerGui:FindFirstChild("ZundaPouchGui") or playerGui:FindFirstChild("ZundaPouch")
    if pouchGui then
        local panel = pouchGui:FindFirstChild("Panel")
        if panel then
            addGradientBackground(panel)
            addFloatingDecorations(panel)
        end
    end
    
    -- Apply to QuestPanel (Rojo or legacy name)
    local questGui = playerGui:FindFirstChild("QuestPanelGui") or playerGui:FindFirstChild("QuestPanel")
    if questGui then
        local panel = questGui:FindFirstChild("Panel")
        if panel then
            addGradientBackground(panel, Color3.fromRGB(252, 250, 245), Color3.fromRGB(245, 248, 240))
            addFloatingDecorations(panel)
        end
    end
    
    -- Apply to CraftingPanel
    local craftGui = playerGui:FindFirstChild("CraftingPanel")
    if craftGui then
        local panel = craftGui:FindFirstChild("Panel")
        if panel then
            addGradientBackground(panel, Color3.fromRGB(255, 250, 240), Color3.fromRGB(250, 245, 235))
            addFloatingDecorations(panel)
        end
    end
    
    -- Apply to ZundaHUD StatBar
    local hud = playerGui:FindFirstChild("ZundaHUD")
    if hud then
        local statBar = hud:FindFirstChild("StatBar")
        if statBar then
            local goldPill = statBar:FindFirstChild("GoldPill")
            if goldPill then
                addGradientBackground(goldPill, Color3.fromRGB(255, 245, 200), Color3.fromRGB(255, 240, 180))
            end
        end
    end
    
    print("[UIFrills] Decorative frills applied to UI panels")
end)

print("[UIFrills] Ready - UI decoration script loaded")