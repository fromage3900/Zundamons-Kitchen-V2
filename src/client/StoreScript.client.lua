local Players=game:GetService("Players"); local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService"); local UIS=game:GetService("UserInputService")
local MPS=game:GetService("MarketplaceService")
local player=Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local MarketplaceConfig = require(RS.ConfigurationFiles.MarketplaceConfig)
local gui = ClientGuiBootstrap.createScreenGui(player, "ZundaShopGui", 26)

local UIHelper = require(RS.Shared.Modules.UIHelper)
local RF=RS:WaitForChild("RemoteFunctions"); local RE=RS:WaitForChild("RemoteEvents")
local promptRF=RF:WaitForChild("PromptRobuxPurchase",10)
local purchaseEv=RE:WaitForChild("PurchaseResult",10)
local compEv=RE:WaitForChild("SetCompanion",10)

local PRODUCTS = {
    companions = {
        { id=1111111101, name="ZundaCat",      emoji="🐱", desc="A playful feline companion", robux=80,  key="zundacat"     },
        { id=1111111102, name="ZundaBunny",    emoji="🐰", desc="Fluffy bunny bestie",         robux=80,  key="zundabunny"   },
        { id=1111111103, name="TantanMon",     emoji="🌶️", desc="Spicy & spirited companion",  robux=100, key="tantanmon"    },
        { id=1111111110, name="Ankomon",       emoji="🫘", desc="+15% gold from serving",      robux=500, key="ankomon"      },
        { id=1111111111, name="Cardamon",      emoji="🍋", desc="+30% perfect cooking window",  robux=500, key="cardamon"     },
        { id=1111111112, name="Antimon",       emoji="🌿", desc="+20% extra drop on gather",    robux=500, key="antimon"      },
        { id=1111111113, name="Sakuradamon",   emoji="🌸", desc="+25% XP from crafting",        robux=500, key="sakuradamon"  },
    },
    recipes = {
        { id=1111111104, name="Premium Ramen", emoji="🍜", desc="Exclusive ramen recipe",       robux=60  },
        { id=1111111105, name="Party Cake",    emoji="🎂", desc="Fancy celebration cake",       robux=60  },
        { id=1111111106, name="Truffle Soup",  emoji="🍲", desc="Ultra-rare truffle recipe",    robux=80  },
    },
    accessories = {
        { id=1111111107, name="Gold Crown",    emoji="👑", desc="Wear royalty on your head",    robux=40  },
        { id=1111111108, name="Pink Bow",      emoji="🎀", desc="Cute bow accessory",           robux=40  },
        { id=1111111109, name="Chef Hat",      emoji="🍽️", desc="Professional chef headwear",   robux=50  },
    },
}

local CAT_COLORS = {
    companions = Color3.fromRGB(200, 240, 200),
    recipes    = Color3.fromRGB(255, 230, 180),
    accessories = Color3.fromRGB(220, 200, 255),
}

local C={
    bg=Color3.fromRGB(252,248,240), border=Color3.fromRGB(255,180,80),
    text=Color3.fromRGB(68,52,78), sub=Color3.fromRGB(140,120,140),
    tabAct=Color3.fromRGB(255,160,60), tabIdle=Color3.fromRGB(245,235,215),
    robux=Color3.fromRGB(0,162,255), card=Color3.fromRGB(255,250,240)
}

local panel=Instance.new("Frame",gui); panel.Name="Panel"
panel.Size=UDim2.new(0,580,0,560); panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.new(0.5,0,0.5,0); panel.BackgroundColor3=C.bg
panel.BorderSizePixel=0; panel.Visible=false
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,22)
local bst=Instance.new("UIStroke",panel); bst.Thickness=3; bst.Color=C.border

local hBand=Instance.new("Frame",panel); hBand.Size=UDim2.new(1,0,0,68)
hBand.Position=UDim2.new(0,0,0,0); hBand.BackgroundColor3=Color3.fromRGB(255,200,80)
hBand.BorderSizePixel=0
local hBandCr=Instance.new("UICorner",hBand); hBandCr.CornerRadius=UDim.new(0,22)
local hFix=Instance.new("Frame",hBand); hFix.Size=UDim2.new(1,0,0.5,0)
hFix.Position=UDim2.new(0,0,0.5,0); hFix.BackgroundColor3=Color3.fromRGB(255,200,80)
hFix.BorderSizePixel=0

local title=Instance.new("TextLabel",hBand)
title.Size=UDim2.new(1,-80,1,0); title.Position=UDim2.new(0,18,0,0)
title.BackgroundTransparency=1; title.Text="✨  Zunda Shop"
title.Font=Enum.Font.FredokaOne; title.TextSize=30
title.TextColor3=Color3.fromRGB(80,52,20); title.TextXAlignment=Enum.TextXAlignment.Left

local subTitle=Instance.new("TextLabel",hBand)
subTitle.Size=UDim2.new(1,-80,0,18); subTitle.Position=UDim2.new(0,20,1,-20)
subTitle.BackgroundTransparency=1; subTitle.Text="Companions • Recipes • Accessories"
local ok=pcall(function() subTitle.FontFace=Font.new("rbxasset://fonts/families/Merriweather.json",Enum.FontWeight.Regular) end)
if not ok then subTitle.Font=Enum.Font.Gotham end
subTitle.TextSize=12; subTitle.TextColor3=Color3.fromRGB(120,82,30)
subTitle.TextXAlignment=Enum.TextXAlignment.Left

local closeBtn=Instance.new("TextButton",hBand)
closeBtn.Size=UDim2.new(0,38,0,38); closeBtn.Position=UDim2.new(1,-50,0,15)
closeBtn.BackgroundColor3=Color3.fromRGB(200,120,20); closeBtn.Text="✕"
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16
closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.BorderSizePixel=0
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,10)

local tabBar=Instance.new("Frame",panel); tabBar.Size=UDim2.new(1,-32,0,38)
tabBar.Position=UDim2.new(0,16,0,74); tabBar.BackgroundTransparency=1; tabBar.BorderSizePixel=0
local tbl=Instance.new("UIListLayout",tabBar)
tbl.FillDirection=Enum.FillDirection.Horizontal; tbl.Padding=UDim.new(0,8)

local function mkTab(name,lbl,order)
    local b=Instance.new("TextButton",tabBar); b.Name="Tab_"..name
    b.Size=UDim2.new(0,152,1,0); b.LayoutOrder=order
    b.BackgroundColor3=order==1 and C.tabAct or C.tabIdle
    b.Text=lbl; b.Font=Enum.Font.GothamBold; b.TextSize=14
    b.TextColor3=order==1 and Color3.fromRGB(255,255,255) or C.text; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10); return b
end
local tabComp=mkTab("companions","🐱  Companions",1)
local tabRec =mkTab("recipes",   "🍳  Recipes",   2)
local tabAcc =mkTab("accessories","👑  Accessories",3)

local scroll=Instance.new("ScrollingFrame",panel); scroll.Name="Cards"
scroll.Size=UDim2.new(1,-32,0,408); scroll.Position=UDim2.new(0,16,0,118)
scroll.BackgroundColor3=Color3.fromRGB(248,243,232); scroll.BorderSizePixel=0
scroll.ScrollBarThickness=5; scroll.ScrollBarImageColor3=C.border
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,14)
local ll=Instance.new("UIListLayout",scroll); ll.Padding=UDim.new(0,10)
local sp=Instance.new("UIPadding",scroll)
sp.PaddingTop=UDim.new(0,10); sp.PaddingLeft=UDim.new(0,12)
sp.PaddingRight=UDim.new(0,12); sp.PaddingBottom=UDim.new(0,10)

local function buildProductCard(prod, idx, cat)
    local card=Instance.new("Frame",scroll); card.Name="P_"..idx
    card.Size=UDim2.new(1,0,0,96); card.LayoutOrder=idx
    card.BackgroundColor3=C.card; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
    local cs=Instance.new("UIStroke",card); cs.Thickness=1.5
    cs.Color=Color3.fromRGB(240,220,160)

    local em=Instance.new("TextLabel",card); em.Size=UDim2.new(0,62,0,62)
    em.Position=UDim2.new(0,10,0,17); em.BackgroundColor3=Color3.fromRGB(255,245,210)
    em.Text=prod.emoji; em.Font=Enum.Font.GothamBold; em.TextSize=36
    em.TextXAlignment=Enum.TextXAlignment.Center; em.BorderSizePixel=0
    Instance.new("UICorner",em).CornerRadius=UDim.new(0,12)

    local nm=Instance.new("TextLabel",card); nm.Size=UDim2.new(1,-220,0,26)
    nm.Position=UDim2.new(0,82,0,14); nm.BackgroundTransparency=1; nm.Text=prod.name
    nm.Font=Enum.Font.FredokaOne; nm.TextSize=18; nm.TextColor3=C.text
    nm.TextXAlignment=Enum.TextXAlignment.Left

    local desc=Instance.new("TextLabel",card); desc.Size=UDim2.new(1,-220,0,22)
    desc.Position=UDim2.new(0,82,0,40); desc.BackgroundTransparency=1; desc.Text=prod.desc
    desc.Font=Enum.Font.Gotham; desc.TextSize=12; desc.TextColor3=C.sub
    desc.TextXAlignment=Enum.TextXAlignment.Left

    local catBadge=Instance.new("Frame",card); catBadge.Size=UDim2.new(0,90,0,20)
    catBadge.Position=UDim2.new(0,82,0,66)
    catBadge.BackgroundColor3=(CAT_COLORS[cat] or C.card)
    catBadge.BorderSizePixel=0
    Instance.new("UICorner",catBadge).CornerRadius=UDim.new(0,8)
    local cl=Instance.new("TextLabel",catBadge); cl.Size=UDim2.new(1,0,1,0)
    cl.BackgroundTransparency=1; cl.Text=cat:sub(1,1):upper()..cat:sub(2)
    cl.Font=Enum.Font.GothamBold; cl.TextSize=11; cl.TextColor3=C.text

    local buyBtn=Instance.new("TextButton",card); buyBtn.Size=UDim2.new(0,110,0,40)
    buyBtn.Position=UDim2.new(1,-122,0,28); buyBtn.BackgroundColor3=C.robux
    buyBtn.Text="🌀 "..prod.robux.." R$"; buyBtn.Font=Enum.Font.GothamBold
    buyBtn.TextSize=14; buyBtn.TextColor3=Color3.new(1,1,1); buyBtn.BorderSizePixel=0
    Instance.new("UICorner",buyBtn).CornerRadius=UDim.new(0,10)

    buyBtn.MouseButton1Click:Connect(function()
        local pos = buyBtn.AbsolutePosition; local sz = buyBtn.AbsoluteSize
        UIHelper.spawnSparkles(buyBtn.Parent, pos.X + sz.X / 2, pos.Y + sz.Y / 2, C.robux, 6)
        if promptRF then
            local toast=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
            toast.Name="PurchaseToast"; toast.DisplayOrder=1000
            local f=Instance.new("Frame",toast)
            f.Size=UDim2.new(0,360,0,80); f.AnchorPoint=Vector2.new(0.5,0)
            f.Position=UDim2.new(0.5,0,0,80); f.BackgroundColor3=Color3.fromRGB(0,162,255)
            f.BorderSizePixel=0
            Instance.new("UICorner",f).CornerRadius=UDim.new(0,14)
            local tl=Instance.new("TextLabel",f); tl.Size=UDim2.new(1,-20,1,0)
            tl.Position=UDim2.new(0,10,0,0); tl.BackgroundTransparency=1
            tl.Text="🌀 Purchasing "..prod.name.."…\n(Replace product ID "..prod.id.." in RobuxStoreServer)"
            tl.Font=Enum.Font.GothamBold; tl.TextSize=13; tl.TextColor3=Color3.new(1,1,1)
            tl.TextWrapped=true; tl.TextXAlignment=Enum.TextXAlignment.Center
            Tween:Create(f,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Position=UDim2.new(0.5,0,0,100)}):Play()
            task.delay(2.8,function()
                Tween:Create(f,TweenInfo.new(0.2),{Position=UDim2.new(0.5,0,0,60)}):Play()
                task.delay(0.25,function() toast:Destroy() end)
            end)
            pcall(function() promptRF:InvokeServer(prod.id) end)
        end
    end)

    buyBtn.MouseEnter:Connect(function()
        Tween:Create(buyBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,130,220)}):Play()
    end)
    buyBtn.MouseLeave:Connect(function()
        Tween:Create(buyBtn,TweenInfo.new(0.1),{BackgroundColor3=C.robux}):Play()
    end)
end

local FREE_COMPANIONS = {
    { key="zundamon",   emoji="🍡", name="Zundamon",   flavor="The original. A loyal pea spirit." },
    { key="zundacat",   emoji="🐱", name="ZundaCat",   flavor="A curious cat-shaped friend." },
    { key="zundabunny", emoji="🐰", name="ZundaBunny", flavor="Hops alongside with twinkling ears." },
    { key="tantanmon",  emoji="🌶️", name="TantanMon",  flavor="Spicy little firework." },
}

local function buildCompanionSelector()
    local sFrame=Instance.new("Frame",scroll); sFrame.Name="CompSelector"
    sFrame.Size=UDim2.new(1,0,0,86); sFrame.LayoutOrder=0
    sFrame.BackgroundColor3=Color3.fromRGB(235,255,235); sFrame.BorderSizePixel=0
    Instance.new("UICorner",sFrame).CornerRadius=UDim.new(0,14)
    local sst=Instance.new("UIStroke",sFrame); sst.Thickness=1.5; sst.Color=Color3.fromRGB(130,215,130)

    local sl=Instance.new("TextLabel",sFrame); sl.Size=UDim2.new(1,-20,0,20)
    sl.Position=UDim2.new(0,14,0,6); sl.BackgroundTransparency=1
    sl.Text="🎁 Free Companions"; sl.Font=Enum.Font.FredokaOne; sl.TextSize=15
    sl.TextColor3=C.text; sl.TextXAlignment=Enum.TextXAlignment.Left

    local freeList=Instance.new("Frame",sFrame); freeList.Size=UDim2.new(1,-16,0,48)
    freeList.Position=UDim2.new(0,8,0,30); freeList.BackgroundTransparency=1; freeList.BorderSizePixel=0
    local fll=Instance.new("UIListLayout",freeList); fll.FillDirection=Enum.FillDirection.Horizontal
    fll.Padding=UDim.new(0,8); fll.VerticalAlignment=Enum.VerticalAlignment.Center

    for _, fc in ipairs(FREE_COMPANIONS) do
        local card=Instance.new("Frame",freeList); card.Size=UDim2.new(0,130,0,44); card.BorderSizePixel=0
        card.BackgroundColor3=Color3.fromRGB(245,255,245)
        Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
        local cs=Instance.new("UIStroke",card); cs.Thickness=1; cs.Color=Color3.fromRGB(130,215,130)

        local em=Instance.new("TextLabel",card); em.Size=UDim2.new(0,28,1,0); em.Position=UDim2.new(0,6,0,0)
        em.BackgroundTransparency=1; em.Text=fc.emoji; em.Font=Enum.Font.GothamBold; em.TextSize=20

        local nm=Instance.new("TextLabel",card); nm.Size=UDim2.new(1,-36,0,18); nm.Position=UDim2.new(0,34,0,4)
        nm.BackgroundTransparency=1; nm.Text=fc.name; nm.Font=Enum.Font.FredokaOne; nm.TextSize=12
        nm.TextColor3=C.text; nm.TextXAlignment=Enum.TextXAlignment.Left

        local equipBtn=Instance.new("TextButton",card); equipBtn.Size=UDim2.new(0,54,0,20)
        equipBtn.Position=UDim2.new(1,-60,0,24); equipBtn.BackgroundColor3=Color3.fromRGB(130,200,100)
        equipBtn.Text="Equip"; equipBtn.Font=Enum.Font.GothamBold; equipBtn.TextSize=10
        equipBtn.TextColor3=Color3.new(1,1,1); equipBtn.BorderSizePixel=0
        Instance.new("UICorner",equipBtn).CornerRadius=UDim.new(0,6)
        equipBtn.MouseButton1Click:Connect(function()
            if compEv then compEv:FireServer(fc.key) end
        end)
    end
end

local activeTab="companions"
local function switchTab(id)
    activeTab=id
    for _,btn in ipairs({tabComp,tabRec,tabAcc}) do
        local active=btn.Name=="Tab_"..id
        btn.BackgroundColor3=active and C.tabAct or C.tabIdle
        btn.TextColor3=active and Color3.new(1,1,1) or C.text
    end
    for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    scroll.CanvasPosition=Vector2.new(0,0)
    if id=="companions" then
        buildCompanionSelector()
        for i,p in ipairs(PRODUCTS.companions) do buildProductCard(p,i+1,"companions") end
    elseif id=="recipes" then
        for i,p in ipairs(PRODUCTS.recipes) do buildProductCard(p,i,"recipes") end
    elseif id=="accessories" then
        for i,p in ipairs(PRODUCTS.accessories) do buildProductCard(p,i,"accessories") end
    end
end
tabComp.MouseButton1Click:Connect(function() switchTab("companions") end)
tabRec.MouseButton1Click:Connect(function()  switchTab("recipes")    end)
tabAcc.MouseButton1Click:Connect(function()  switchTab("accessories") end)

if purchaseEv then
    purchaseEv.OnClientEvent:Connect(function(itemName, itemType)
        local toast=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
        toast.Name="SuccessToast"; toast.DisplayOrder=1001
        local f=Instance.new("Frame",toast)
        f.Size=UDim2.new(0,320,0,70); f.AnchorPoint=Vector2.new(0.5,0)
        f.Position=UDim2.new(0.5,0,0,80); f.BackgroundColor3=Color3.fromRGB(100,200,100)
        f.BorderSizePixel=0; Instance.new("UICorner",f).CornerRadius=UDim.new(0,14)
        local tl=Instance.new("TextLabel",f); tl.Size=UDim2.new(1,0,1,0)
        tl.BackgroundTransparency=1; tl.Text="✅  "..itemName.." unlocked!"
        tl.Font=Enum.Font.FredokaOne; tl.TextSize=18; tl.TextColor3=Color3.new(1,1,1)
        task.delay(2.5,function() toast:Destroy() end)
    end)
end

local open=false
local function toggle()
    open=not open; panel.Visible=open
    if open then
        if scroll:FindFirstChildOfClass("Frame")==nil then switchTab("companions") end
        panel.Size=UDim2.new(0,580,0,10)
        Tween:Create(panel,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,580,0,560)}):Play()
    end
end
closeBtn.MouseButton1Click:Connect(function() open=true; toggle() end)

task.spawn(function()
    local pg=player:WaitForChild("PlayerGui")
    local hud=pg:WaitForChild("ZundaHUD",15)
    if hud then
        local bar=hud:WaitForChild("HudButtons",8)
        if bar then
            local s=bar:FindFirstChild("HudBtn_settings")
            if s then s.MouseButton1Click:Connect(toggle) end
            local sh=bar:FindFirstChild("HudBtn_shop")
            if sh then sh.MouseButton1Click:Connect(toggle) end
        end
    end
end)
UIS.InputBegan:Connect(function(i,g) if g then return end if i.KeyCode==Enum.KeyCode.B then toggle() end end)
print("[RobuxStore] Ready — P key or settings/shop button")
