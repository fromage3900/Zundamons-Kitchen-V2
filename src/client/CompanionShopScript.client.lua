-- [[LocalScript] CompanionShopScript (ref: RBX3085D4033F0D4209A678B495F57C5C48)]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

-- Premium companion receipts: MarketplaceService.ProcessReceipt (RobuxStoreServer init).

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)

local gui = ClientGuiBootstrap.createScreenGui(player, "CompanionShopGui", 28)

local RE = RS:WaitForChild("RemoteEvents")
print("[CompanionShop] RemoteEvents found")
local RF = RS:WaitForChild("RemoteFunctions")
print("[CompanionShop] RemoteFunctions found")
local PurchaseCompanion = RE:WaitForChild("PurchaseCompanion")
print("[CompanionShop] PurchaseCompanion found")
local SetCompanion = RE:WaitForChild("SetCompanion")
print("[CompanionShop] SetCompanion found")
local CompanionOwnedSync = RE:WaitForChild("CompanionOwnedSync")
print("[CompanionShop] CompanionOwnedSync found")
local GetCompanionCatalog = RF:WaitForChild("GetCompanionCatalog")
print("[CompanionShop] GetCompanionCatalog found")
local GetOwnedCompanions = RF:WaitForChild("GetOwnedCompanions")
print("[CompanionShop] GetOwnedCompanions found")

-- ── Backdrop
local backdrop = Instance.new("Frame", gui)
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
backdrop.BackgroundTransparency = 0.4
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.ZIndex = 1

-- ── Panel
local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 820, 0, 540)
panel.Position = UDim2.new(0.5, -410, 0.5, -270)
panel.BackgroundColor3 = Color3.fromRGB(36, 26, 52)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 22)
local pStroke = Instance.new("UIStroke", panel); pStroke.Color = Color3.fromRGB(220, 160, 230); pStroke.Thickness = 3

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -100, 0, 56)
title.Position = UDim2.new(0, 24, 0, 14)
title.BackgroundTransparency = 1
title.Text = "✨  Companion Shop  ✨"
title.Font = Enum.Font.FredokaOne
title.TextSize = 32
title.TextColor3 = Color3.fromRGB(255, 220, 245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -52, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 30
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 4
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- ── Tab strip
local tabBar = Instance.new("Frame", panel)
tabBar.Name = "Tabs"
tabBar.Size = UDim2.new(1, -40, 0, 60)
tabBar.Position = UDim2.new(0, 20, 0, 80)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 3
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ── Detail panel (right side, big portrait + buff text + buy button)
local detail = Instance.new("Frame", panel)
detail.Name = "Detail"
detail.Size = UDim2.new(1, -40, 1, -170)
detail.Position = UDim2.new(0, 20, 0, 150)
detail.BackgroundColor3 = Color3.fromRGB(50, 36, 70)
detail.BorderSizePixel = 0
detail.ZIndex = 3
Instance.new("UICorner", detail).CornerRadius = UDim.new(0, 16)
local dStroke = Instance.new("UIStroke", detail); dStroke.Color = Color3.fromRGB(150, 110, 180); dStroke.Thickness = 2

-- Big portrait emoji
local portrait = Instance.new("TextLabel", detail)
portrait.Size = UDim2.new(0, 200, 0, 200)
portrait.Position = UDim2.new(0, 30, 0.5, -100)
portrait.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
portrait.Text = "🍡"
portrait.Font = Enum.Font.GothamBold
portrait.TextScaled = true
portrait.TextColor3 = Color3.fromRGB(255,255,255)
portrait.BorderSizePixel = 0
portrait.ZIndex = 4
Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 20)
local portraitStroke = Instance.new("UIStroke", portrait); portraitStroke.Color = Color3.fromRGB(255,220,200); portraitStroke.Thickness = 3

-- Name + flavor + buff text
local detailRight = Instance.new("Frame", detail)
detailRight.Size = UDim2.new(1, -260, 1, -40)
detailRight.Position = UDim2.new(0, 250, 0, 20)
detailRight.BackgroundTransparency = 1
detailRight.ZIndex = 4

local nameLbl = Instance.new("TextLabel", detailRight)
nameLbl.Size = UDim2.new(1, 0, 0, 46)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "Zundamon"
nameLbl.Font = Enum.Font.FredokaOne
nameLbl.TextSize = 36
nameLbl.TextColor3 = Color3.fromRGB(255, 240, 255)
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.ZIndex = 5

local flavor = Instance.new("TextLabel", detailRight)
flavor.Size = UDim2.new(1, 0, 0, 48)
flavor.Position = UDim2.new(0, 0, 0, 50)
flavor.BackgroundTransparency = 1
flavor.Text = ""
flavor.Font = Enum.Font.Gotham
flavor.TextSize = 16
flavor.TextColor3 = Color3.fromRGB(220, 200, 240)
flavor.TextXAlignment = Enum.TextXAlignment.Left
flavor.TextWrapped = true
flavor.ZIndex = 5

local buffBadge = Instance.new("Frame", detailRight)
buffBadge.Size = UDim2.new(1, 0, 0, 78)
buffBadge.Position = UDim2.new(0, 0, 0, 110)
buffBadge.BackgroundColor3 = Color3.fromRGB(70, 100, 80)
buffBadge.BorderSizePixel = 0
buffBadge.ZIndex = 5
Instance.new("UICorner", buffBadge).CornerRadius = UDim.new(0, 12)
local bStroke = Instance.new("UIStroke", buffBadge); bStroke.Color = Color3.fromRGB(160, 240, 180); bStroke.Thickness = 2

local buffTitle = Instance.new("TextLabel", buffBadge)
buffTitle.Size = UDim2.new(1, -16, 0, 26)
buffTitle.Position = UDim2.new(0, 8, 0, 4)
buffTitle.BackgroundTransparency = 1
buffTitle.Text = "⚡ Passive Buff"
buffTitle.Font = Enum.Font.GothamBold
buffTitle.TextSize = 16
buffTitle.TextColor3 = Color3.fromRGB(180, 240, 200)
buffTitle.TextXAlignment = Enum.TextXAlignment.Left
buffTitle.ZIndex = 6

local buffDesc = Instance.new("TextLabel", buffBadge)
buffDesc.Size = UDim2.new(1, -16, 0, 46)
buffDesc.Position = UDim2.new(0, 8, 0, 28)
buffDesc.BackgroundTransparency = 1
buffDesc.Text = ""
buffDesc.Font = Enum.Font.Gotham
buffDesc.TextSize = 18
buffDesc.TextColor3 = Color3.fromRGB(240, 255, 240)
buffDesc.TextXAlignment = Enum.TextXAlignment.Left
buffDesc.TextWrapped = true
buffDesc.ZIndex = 6

local actionBtn = Instance.new("TextButton", detailRight)
actionBtn.Size = UDim2.new(1, 0, 0, 64)
actionBtn.Position = UDim2.new(0, 0, 1, -78)
actionBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
actionBtn.Text = "Buy 500 Robux"
actionBtn.Font = Enum.Font.FredokaOne
actionBtn.TextSize = 26
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.BorderSizePixel = 0
actionBtn.ZIndex = 5
Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 14)
local aStroke = Instance.new("UIStroke", actionBtn); aStroke.Color = Color3.fromRGB(220,180,255); aStroke.Thickness = 2

-- ── State
local catalog = {}
local owned = {}
local currentKey = "zundamon"

-- Stable tab order so Premium ones appear at the right
local TAB_ORDER = { "zundamon", "zundacat", "zundabunny", "tantanmon", "ankomon", "cardamon", "antimon", "sakuradamon" }

local tabBtns = {}

local function refreshDetail()
    local def = catalog[currentKey]
    if not def then return end
    portrait.Text = def.emoji
    nameLbl.Text = def.displayName or currentKey
    flavor.Text = def.flavor or ""
    if def.glow then
        portrait.BackgroundColor3 = def.glow
        portraitStroke.Color = def.glow
    end
    if def.buff then
        buffBadge.Visible = true
        buffDesc.Text = def.buff.description
    else
        buffBadge.Visible = false
    end
    local isOwned = owned[currentKey] == true
    local isActive = owned.__active == currentKey
    if def.free or isOwned then
        if isActive then
            actionBtn.Text = "✓ Equipped"
            actionBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 90)
        else
            actionBtn.Text = "Equip"
            actionBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
        end
    else
        actionBtn.Text = ("Buy %d Robux"):format(def.price or 500)
        actionBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 100)
    end
end

local function refreshTabs()
    for _, btn in pairs(tabBtns) do
        local key = btn:GetAttribute("CompKey")
        if owned.__active == key then
            btn.BackgroundColor3 = Color3.fromRGB(140, 100, 220)
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Color3.fromRGB(255, 240, 200); stroke.Thickness = 3 end
        elseif owned[key] then
            btn.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
        end
    end
end

local function buildTabs()
    for _, b in pairs(tabBar:GetChildren()) do
        if b:IsA("TextButton") then b:Destroy() end
    end
    tabBtns = {}
    for i, key in ipairs(TAB_ORDER) do
        local def = catalog[key]
        if def then
            local btn = Instance.new("TextButton", tabBar)
            btn.Size = UDim2.new(0, 88, 0, 56)
            btn.Text = def.emoji .. "\n" .. (def.displayName or key)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
            btn.TextColor3 = Color3.fromRGB(255, 240, 255)
            btn.BorderSizePixel = 0
            btn.LayoutOrder = i
            btn.AutoButtonColor = true
            btn.ZIndex = 4
            btn:SetAttribute("CompKey", key)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            local st = Instance.new("UIStroke", btn); st.Color = Color3.fromRGB(180,140,220); st.Thickness = 1; st.Transparency = 0.4
            -- Show "500 R$" tag if not free
            if not def.free then
                local price = Instance.new("TextLabel", btn)
                price.Size = UDim2.new(1, 0, 0, 14)
                price.Position = UDim2.new(0, 0, 1, -14)
                price.BackgroundTransparency = 1
                price.Text = "500 R$"
                price.Font = Enum.Font.GothamBold
                price.TextSize = 10
                price.TextColor3 = Color3.fromRGB(255, 220, 130)
                price.ZIndex = 5
            end
            btn.MouseButton1Click:Connect(function()
                currentKey = key
                refreshDetail()
            end)
            tabBtns[key] = btn
        end
    end
end

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    backdrop.Visible = false
end)

actionBtn.MouseButton1Click:Connect(function()
    local def = catalog[currentKey]
    if not def then return end
    if def.free or owned[currentKey] then
        -- Equip
        SetCompanion:FireServer(currentKey)
        owned.__active = currentKey
        refreshDetail()
        refreshTabs()
    else
        -- Purchase
        PurchaseCompanion:FireServer(currentKey)
    end
end)

CompanionOwnedSync.OnClientEvent:Connect(function(compType, isOwned)
    owned[compType] = isOwned
    if currentKey == compType then refreshDetail() end
    refreshTabs()
end)

-- Public API
local function open()
    print("[CompanionShop.open] Opening shop...")
    backdrop.Visible = true
    panel.Visible = true
    print("[CompanionShop.open] Fetching catalog...")
    local success1, catalogData = pcall(function()
        return GetCompanionCatalog:InvokeServer()
    end)
    print("[CompanionShop.open] Catalog success:", success1)
    catalog = catalogData or {}
    
    print("[CompanionShop.open] Fetching owned companions...")
    local success2, ownedData = pcall(function()
        return GetOwnedCompanions:InvokeServer()
    end)
    print("[CompanionShop.open] Owned success:", success2)
    owned = ownedData or {}
    
    if owned.__active then currentKey = owned.__active end
    print("[CompanionShop.open] Building UI...")
    buildTabs()
    refreshDetail()
    refreshTabs()
    panel.Size = UDim2.new(0, 780, 0, 510)
    TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 820, 0, 540) }):Play()
    print("[CompanionShop.open] Shop opened")
end

local function close()
    panel.Visible = false
    backdrop.Visible = false
end

_G.ZundaCompanionShop = { open = open, close = close, toggle = function()
    if panel.Visible then close() else open() end
end }

-- Hotkey: K
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        if panel.Visible then close() else open() end
    end
end)

print("[CompanionShop] Ready — press K to open")
