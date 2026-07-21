-- [[LocalScript] PouchScript (ref: RBX5E076AB184F24934A1E9503A5FA7AEDC)]]
-- ZundaPouch/PouchScript
-- Full bag UI reading _G.data via RequestData RemoteFunction.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Tween   = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local gui = ClientGuiBootstrap.createScreenGui(player, "ZundaPouchGui", 22)
local RF      = RS:WaitForChild("RemoteFunctions")
local reqData = RF:WaitForChild("RequestData")
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local UIAssets = require(RS.Shared.Config.UIAssets)

-- ─── COLORS ──────────────────────────────────────────────
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local C = {
    bg      = UIConfig.COLORS.CreamWhite,
    panel   = UIConfig.COLORS.CreamLight,
    border  = UIConfig.COLORS.ZundamonPink,
    text    = UIConfig.COLORS.TextDark,
    subtext = UIConfig.COLORS.TextDarkSec,
    btnAct  = UIConfig.COLORS.ZundamonPink,
    btnIdle = UIConfig.COLORS.CreamDark,
    gold    = UIConfig.COLORS.ZundamonGold,
}

-- ─── BUILD UI ────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name            = "Panel"
panel.Size            = UDim2.new(0, 580, 0, 520)
panel.AnchorPoint     = Vector2.new(0.5, 0.5)
panel.Position        = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Visible         = false
panel.Parent          = gui
do
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,22); cr.Parent = panel
    local st = Instance.new("UIStroke"); st.Thickness = 3; st.Color = C.border; st.Parent = panel
    local sh = Instance.new("UIStroke")  -- drop shadow illusion via second frame is complex, skip
end

-- Header
local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1,-32,0,56)
header.Position = UDim2.new(0,16,0,12)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(0,260,1,0)
titleLbl.Position = UDim2.new(0,0,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🎒  Zunda Pouch"
titleLbl.FontFace = UIConfig.FONTS.Title
titleLbl.TextSize = UIConfig.FONT_SIZES.Title
titleLbl.TextColor3 = C.text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local goldLbl = Instance.new("TextLabel", header)
goldLbl.Name = "GoldDisplay"
goldLbl.Size = UDim2.new(0,160,0,36)
goldLbl.Position = UDim2.new(0,260,0,10)
goldLbl.BackgroundColor3 = Color3.fromRGB(255,242,180)
goldLbl.BorderSizePixel = 0
goldLbl.Text = "💰  ---"
goldLbl.FontFace = UIConfig.FONTS.Heading
goldLbl.TextSize = UIConfig.FONT_SIZES.Body
goldLbl.TextColor3 = C.gold
do
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,12); cr.Parent = goldLbl
    local st = Instance.new("UIStroke"); st.Thickness = 1.5
    st.Color = Color3.fromRGB(220,180,50); st.Parent = goldLbl
end

local closeBtn = Instance.new("TextButton", header)
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0,38,0,38)
closeBtn.Position = UDim2.new(1,-42,0,9)
closeBtn.BackgroundColor3 = C.border
closeBtn.Text = "✕"
closeBtn.FontFace = UIConfig.FONTS.Heading
closeBtn.TextSize = UIConfig.FONT_SIZES.Small
closeBtn.TextColor3 = UIConfig.COLORS.TextWhite
closeBtn.BorderSizePixel = 0
do
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,10); cr.Parent = closeBtn
end

-- Tab bar
local tabBar = Instance.new("Frame", panel)
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1,-32,0,36)
tabBar.Position = UDim2.new(0,16,0,74)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local TABS = {
    {id="all",    label="All",         emoji="📦"},
    {id="forage", label="Forage",      emoji="🌿"},
    {id="mining", label="Mining",      emoji="⛏"},
    {id="food",   label="Food",        emoji="🍱"},
}

local tabBtns = {}
local activeTab = "all"
for i, t in ipairs(TABS) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Name = "Tab_"..t.id
    btn.Size = UDim2.new(0,112,1,0)
    btn.LayoutOrder = i
    btn.BackgroundColor3 = i==1 and C.btnAct or C.btnIdle
    btn.BorderSizePixel = 0
    btn.Text = t.emoji.."  "..t.label
    btn.FontFace = UIConfig.FONTS.Heading
    btn.TextSize = UIConfig.FONT_SIZES.Small
    btn.TextColor3 = i==1 and UIConfig.COLORS.TextWhite or C.text
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,10); cr.Parent = btn
    tabBtns[t.id] = btn
end

-- Item count label
local countLbl = Instance.new("TextLabel", panel)
countLbl.Name = "CountLabel"
countLbl.Size = UDim2.new(1,-32,0,20)
countLbl.Position = UDim2.new(0,16,0,116)
countLbl.BackgroundTransparency = 1
countLbl.Text = ""
countLbl.FontFace = UIConfig.FONTS.Body
countLbl.TextSize = UIConfig.FONT_SIZES.Caption
countLbl.TextColor3 = C.subtext
countLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Scroll grid for items
local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "ItemGrid"
scroll.Size = UDim2.new(1,-32,0,335)
scroll.Position = UDim2.new(0,16,0,140)
scroll.BackgroundColor3 = Color3.fromRGB(245,240,232)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = C.border
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)
do
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,14); cr.Parent = scroll
    local gl = Instance.new("UIGridLayout", scroll)
    gl.CellSize = UDim2.new(0,118,0,108)
    gl.CellPadding = UDim2.new(0,8,0,8)
    gl.SortOrder = Enum.SortOrder.Name
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10)
    pad.PaddingRight=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10)
end

-- Empty state label
local emptyLbl = Instance.new("TextLabel", scroll)
emptyLbl.Name = "_Empty"
emptyLbl.Size = UDim2.new(1,-20,0,120)
emptyLbl.Position = UDim2.new(0,10,0,40)
emptyLbl.BackgroundTransparency = 1
emptyLbl.Text = "Your pouch is empty!\nGather some Zunda treasures 🌸"
emptyLbl.FontFace = UIConfig.FONTS.Body
emptyLbl.TextSize = UIConfig.FONT_SIZES.Small
emptyLbl.TextColor3 = C.subtext
emptyLbl.TextWrapped = true
emptyLbl.Visible = false

-- ─── CARD BUILDER (via UIHelper) ──────────────────────────

-- ─── RENDER ───────────────────────────────────────────────
local currentData = {}

local function render(tab)
    -- Clear existing cards
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") and c.Name ~= "_Empty" then c:Destroy() end
    end

    local shown = 0
    -- Sort keys alphabetically
    local keys = {}
    for k, v in pairs(currentData) do
        if type(v) == "number" and v > 0
            and k ~= "gold" and k ~= "current_gold" and k ~= "Gold" and k ~= "guests_served" then
            table.insert(keys, k)
        end
    end
    table.sort(keys)

    for _, name in ipairs(keys) do
        local count = currentData[name]
        local cat = UIHelper.getCategory(name)
        if tab == "all" or cat == tab then
            local card = UIHelper.createCard(name, count, cat, scroll)
            shown = shown + 1
        end
    end

    emptyLbl.Visible = (shown == 0)
    if shown == 0 then emptyLbl.Parent = scroll end
    countLbl.Text = shown .. (shown == 1 and " item" or " items") ..
        (tab ~= "all" and (" in " .. tab) or " in pouch")
end

-- ─── TAB SWITCHING ────────────────────────────────────────
local function switchTab(id)
    activeTab = id
    for tid, btn in pairs(tabBtns) do
        if tid == id then
            btn.BackgroundColor3 = C.btnAct
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            btn.BackgroundColor3 = C.btnIdle
            btn.TextColor3 = C.text
        end
    end
    render(id)
end

for id, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(id) end)
end

-- ─── DATA POLLING ─────────────────────────────────────────
local function refresh()
    local ok, data = pcall(function() return reqData:InvokeServer() end)
    if ok and data then
        currentData = data
        -- Show gold in header
        local g = data.gold or 0
        goldLbl.Text = "💰  " .. tostring(g)
        render(activeTab)
    end
end

-- ─── TOGGLE ───────────────────────────────────────────────
local open = false
local function toggle()
    open = not open
    panel.Visible = open
    if open then
        refresh()
        -- Entrance tween
        panel.Size = UDim2.new(0,580,0,10)
        Tween:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,580,0,520)}):Play()
    end
end

closeBtn.MouseButton1Click:Connect(function()
	open = true; toggle()
	local pos = closeBtn.AbsolutePosition
	UIHelper.spawnSparkles(panel, pos.X + 19, pos.Y + 19, C.border, 4)
end)

-- ─── WIRE HUD BUTTON ─────────────────────────────────────
task.spawn(function()
    local pg = player:WaitForChild("PlayerGui")
    local hudGui = pg:WaitForChild("ZundaHUD", 15)
    if hudGui then
        local hudButtons = hudGui:WaitForChild("HudButtons", 8)
        if hudButtons then
            local invBtn = hudButtons:FindFirstChild("HudBtn_inventory")
            if invBtn then
                invBtn.MouseButton1Click:Connect(toggle)
            end
        end
    end
end)

-- Keyboard shortcut: I key
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.I then toggle() end
end)

-- Auto-refresh while open
task.spawn(function()
    while true do
        task.wait(4)
        if open then refresh() end
    end
end)

print("[ZundaPouch] Ready — press I or click bag icon")
