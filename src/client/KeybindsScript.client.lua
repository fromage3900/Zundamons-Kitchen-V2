-- [[LocalScript] KeybindsScript (ref: RBX35B755E6EBDC4288BBE186D33EB3BFCD)]]
-- KeybindsPanel: settings/keybinds. F1 to toggle. Click any binding to rebind.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent

local DEFAULTS = {
    { action = "inventory",  cat = "Inventory",    key = Enum.KeyCode.Backquote, desc = "Open Inventory",     icon = "🎒" },
    { action = "compendium", cat = "Reference",    key = Enum.KeyCode.C,         desc = "Toggle Compendium",  icon = "📖" },
    { action = "map",        cat = "Exploration",  key = Enum.KeyCode.M,         desc = "Toggle Map",         icon = "🗺️" },
    { action = "quests",     cat = "Exploration",  key = Enum.KeyCode.J,         desc = "Toggle Quests",      icon = "📜" },
    { action = "shop",       cat = "Shopping",     key = Enum.KeyCode.B,         desc = "Premium Shop",       icon = "💎" },
    { action = "progress",   cat = "Progression",  key = Enum.KeyCode.P,         desc = "Open Progress Panel",icon = "🏆" },
    { action = "advance_vn", cat = "Visual Novel", key = Enum.KeyCode.Space,     desc = "Advance Dialogue",   icon = "💬" },
    { action = "keybinds",   cat = "Help",         key = Enum.KeyCode.F1,        desc = "Toggle Keybinds",    icon = "⌨", readOnly = true },
}

local binds = {}
for _, d in ipairs(DEFAULTS) do binds[d.action] = d.key end

local function keyName(kc)
    if kc == nil then return "—" end
    local s = tostring(kc):gsub("Enum.KeyCode.", "")
    if s == "Backquote" then return "`" end
    return s
end

-- ── Build UI ─────────────────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 480, 0, 540)
panel.Position = UDim2.new(0.5, -240, 0.5, -270)
panel.BackgroundColor3 = Color3.fromRGB(28, 20, 44)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 50
panel.Parent = gui
local pCorner = Instance.new("UICorner", panel); pCorner.CornerRadius = UDim.new(0, 18)
local pStroke = Instance.new("UIStroke", panel); pStroke.Color = Color3.fromRGB(180, 130, 220); pStroke.Thickness = 2

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -20, 0, 48)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "⌨  Settings & Keybinds"
title.Font = Enum.Font.FredokaOne
title.TextSize = 26
title.TextColor3 = Color3.fromRGB(240, 220, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 51

local hint = Instance.new("TextLabel", panel)
hint.Size = UDim2.new(1, -20, 0, 22)
hint.Position = UDim2.new(0, 10, 0, 58)
hint.BackgroundTransparency = 1
hint.Text = "Click any key to rebind • F1 to toggle • Esc to cancel"
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(170, 150, 200)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.ZIndex = 51

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 28
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 52
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Size = UDim2.new(1, -20, 1, -140)
scroll.Position = UDim2.new(0, 10, 0, 92)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(170, 130, 220)
scroll.ZIndex = 51
scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)

local resetBtn = Instance.new("TextButton", panel)
resetBtn.Size = UDim2.new(0, 180, 0, 36)
resetBtn.Position = UDim2.new(0, 12, 1, -44)
resetBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 100)
resetBtn.Text = "↺  Reset Defaults"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 14
resetBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
resetBtn.BorderSizePixel = 0
resetBtn.ZIndex = 52
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

local statusLbl = Instance.new("TextLabel", panel)
statusLbl.Size = UDim2.new(1, -208, 0, 36)
statusLbl.Position = UDim2.new(0, 200, 1, -44)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 13
statusLbl.TextColor3 = Color3.fromRGB(180, 200, 255)
statusLbl.TextXAlignment = Enum.TextXAlignment.Right
statusLbl.ZIndex = 52

-- Row factory
local rowMap = {}
local layoutOrder = 0
local seenCats = {}
for _, def in ipairs(DEFAULTS) do
    if not seenCats[def.cat] then
        seenCats[def.cat] = true
        layoutOrder = layoutOrder + 1
        local hdr = Instance.new("TextLabel", scroll)
        hdr.Size = UDim2.new(1, 0, 0, 26)
        hdr.BackgroundTransparency = 1
        hdr.Text = "— " .. string.upper(def.cat) .. " —"
        hdr.Font = Enum.Font.GothamBold
        hdr.TextSize = 11
        hdr.TextColor3 = Color3.fromRGB(150, 120, 200)
        hdr.TextXAlignment = Enum.TextXAlignment.Left
        hdr.LayoutOrder = layoutOrder
        hdr.ZIndex = 52
    end
    layoutOrder = layoutOrder + 1
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(40, 28, 60)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.ZIndex = 52
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local icon = Instance.new("TextLabel", row)
    icon.Size = UDim2.new(0, 34, 1, 0)
    icon.Position = UDim2.new(0, 8, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = def.icon
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 22
    icon.ZIndex = 53

    local desc = Instance.new("TextLabel", row)
    desc.Size = UDim2.new(1, -160, 1, 0)
    desc.Position = UDim2.new(0, 48, 0, 0)
    desc.BackgroundTransparency = 1
    desc.Text = def.desc
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = Color3.fromRGB(220, 210, 240)
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 53

    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0, 96, 0, 30)
    keyBtn.Position = UDim2.new(1, -104, 0.5, -15)
    keyBtn.Text = keyName(def.key)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 14
    keyBtn.BorderSizePixel = 0
    keyBtn.ZIndex = 54
    keyBtn.BackgroundColor3 = def.readOnly and Color3.fromRGB(50, 40, 70) or Color3.fromRGB(80, 55, 120)
    keyBtn.TextColor3 = def.readOnly and Color3.fromRGB(140, 120, 170) or Color3.fromRGB(240, 220, 255)
    keyBtn.AutoButtonColor = not def.readOnly
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 7)
    rowMap[def.action] = { btn = keyBtn, def = def }
end

-- Rebind logic
local listening = nil
local listenConn = nil
local function cancelListen()
    if listenConn then listenConn:Disconnect(); listenConn = nil end
    if listening then
        local r = rowMap[listening]
        if r then
            r.btn.BackgroundColor3 = Color3.fromRGB(80, 55, 120)
            r.btn.Text = keyName(binds[listening])
        end
    end
    listening = nil
    statusLbl.Text = ""
end
local function startListen(action)
    cancelListen()
    listening = action
    local r = rowMap[action]
    r.btn.BackgroundColor3 = Color3.fromRGB(200, 130, 50)
    r.btn.Text = "[ ? ]"
    statusLbl.Text = "Press a key…"
    listenConn = UIS.InputBegan:Connect(function(input, gpe)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Escape then cancelListen(); return end
        binds[action] = kc
        r.btn.BackgroundColor3 = Color3.fromRGB(80, 55, 120)
        r.btn.Text = keyName(kc)
        statusLbl.Text = "✓ Bound to " .. keyName(kc)
        listening = nil
        if listenConn then listenConn:Disconnect(); listenConn = nil end
        task.delay(1.5, function() if not listening then statusLbl.Text = "" end end)
    end)
end
for action, r in pairs(rowMap) do
    if not r.def.readOnly then
        r.btn.MouseButton1Click:Connect(function()
            if listening == action then cancelListen() else startListen(action) end
        end)
    end
end
resetBtn.MouseButton1Click:Connect(function()
    cancelListen()
    for _, d in ipairs(DEFAULTS) do binds[d.action] = d.key end
    for action, r in pairs(rowMap) do r.btn.Text = keyName(binds[action]) end
    statusLbl.Text = "↺ Reset to defaults"
    task.delay(1.5, function() statusLbl.Text = "" end)
end)

-- Show/hide
local isOpen = false
local function openPanel()
    isOpen = true
    panel.Visible = true
    panel.Size = UDim2.new(0, 440, 0, 500)
    TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 480, 0, 540) }):Play()
end
local function closePanel()
    cancelListen()
    isOpen = false
    local t = TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        { Size = UDim2.new(0, 440, 0, 500) })
    t.Completed:Connect(function() panel.Visible = false end)
    t:Play()
end
closeBtn.MouseButton1Click:Connect(closePanel)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        if isOpen then closePanel() else openPanel() end
    end
end)

-- API
_G.ZundaKeybindsPanel = {
    open = openPanel,
    close = closePanel,
    toggle = function() if isOpen then closePanel() else openPanel() end end,
}

print("[KeybindsPanel] Ready — F1 or settings button to toggle")
