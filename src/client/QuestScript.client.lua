-- [[LocalScript] QuestScript (ref: RBX6E7F43188E8A49A4BC4376C52E72FD93)]]
local Players=game:GetService("Players"); local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService"); local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer; local gui=script.Parent
local UIHelper = require(RS.Shared.Modules.UIHelper)
local RE=RS:WaitForChild("RemoteEvents"); local ev=RE:WaitForChild("UpdateQuests",15)
local C={bg=Color3.fromRGB(252,248,240),border=Color3.fromRGB(130,195,120),
         text=Color3.fromRGB(68,52,78),sub=Color3.fromRGB(140,120,140),
         done=Color3.fromRGB(100,185,100),bar=Color3.fromRGB(230,225,220),
         fill=Color3.fromRGB(130,195,120)}

local panel=Instance.new("Frame",gui); panel.Name="Panel"
panel.Size=UDim2.new(0,420,0,520); panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.new(0.5,0,0.5,0); panel.BackgroundColor3=C.bg
panel.BorderSizePixel=0; panel.Visible=false
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,22)
local bst=Instance.new("UIStroke",panel); bst.Thickness=3; bst.Color=C.border

local hdr=Instance.new("TextLabel",panel); hdr.Size=UDim2.new(1,-70,0,52)
hdr.Position=UDim2.new(0,18,0,12); hdr.BackgroundTransparency=1; hdr.Text="📋  Quests"
hdr.Font=Enum.Font.FredokaOne; hdr.TextSize=28; hdr.TextColor3=C.text
hdr.TextXAlignment=Enum.TextXAlignment.Left

local sub=Instance.new("TextLabel",panel); sub.Size=UDim2.new(1,-36,0,18)
sub.Position=UDim2.new(0,18,0,58); sub.BackgroundTransparency=1
sub.Text="Complete quests to earn Gold 💰"; sub.Font=Enum.Font.Gotham; sub.TextSize=13
sub.TextColor3=C.sub; sub.TextXAlignment=Enum.TextXAlignment.Left

local closeBtn=Instance.new("TextButton",panel); closeBtn.Size=UDim2.new(0,38,0,38)
closeBtn.Position=UDim2.new(1,-52,0,14); closeBtn.BackgroundColor3=C.border; closeBtn.Text="✕"
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16; closeBtn.TextColor3=Color3.new(1,1,1)
closeBtn.BorderSizePixel=0; Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,10)

local scroll=Instance.new("ScrollingFrame",panel); scroll.Name="QuestList"
scroll.Size=UDim2.new(1,-32,0,428); scroll.Position=UDim2.new(0,16,0,82)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=4
scroll.ScrollBarImageColor3=C.border; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0)
local ll=Instance.new("UIListLayout",scroll); ll.Padding=UDim.new(0,10)

local cards={}
local function buildCard(q,idx)
    local card=Instance.new("Frame",scroll); card.Name="Card_"..q.id
    card.Size=UDim2.new(1,0,0,110); card.LayoutOrder=idx
    card.BackgroundColor3=Color3.fromRGB(248,244,238); card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
    local cs=Instance.new("UIStroke",card); cs.Thickness=1.5; cs.Color=C.bar

    local em=Instance.new("TextLabel",card); em.Size=UDim2.new(0,52,0,52)
    em.Position=UDim2.new(0,10,0,14); em.BackgroundColor3=Color3.fromRGB(240,235,228)
    em.Text=q.emoji; em.Font=Enum.Font.GothamBold; em.TextSize=28
    em.TextXAlignment=Enum.TextXAlignment.Center; em.BorderSizePixel=0
    Instance.new("UICorner",em).CornerRadius=UDim.new(0,10)

    local tt=Instance.new("TextLabel",card); tt.Size=UDim2.new(1,-160,0,24)
    tt.Position=UDim2.new(0,72,0,12); tt.BackgroundTransparency=1; tt.Text=q.title
    tt.Font=Enum.Font.GothamBold; tt.TextSize=15; tt.TextColor3=C.text
    tt.TextXAlignment=Enum.TextXAlignment.Left

    local dd=Instance.new("TextLabel",card); dd.Size=UDim2.new(1,-160,0,18)
    dd.Position=UDim2.new(0,72,0,36); dd.BackgroundTransparency=1; dd.Text=q.desc
    dd.Font=Enum.Font.Gotham; dd.TextSize=12; dd.TextColor3=C.sub
    dd.TextXAlignment=Enum.TextXAlignment.Left

    local bb=Instance.new("Frame",card); bb.Size=UDim2.new(1,-80,0,8)
    bb.Position=UDim2.new(0,72,0,62); bb.BackgroundColor3=C.bar; bb.BorderSizePixel=0
    Instance.new("UICorner",bb).CornerRadius=UDim.new(0.5,0)
    local bf=Instance.new("Frame",bb); bf.Name="Fill"; bf.Size=UDim2.new(0,0,1,0)
    bf.BackgroundColor3=C.fill; bf.BorderSizePixel=0
    Instance.new("UICorner",bf).CornerRadius=UDim.new(0.5,0)

    local pl=Instance.new("TextLabel",card); pl.Name="Prog"
    pl.Size=UDim2.new(1,-80,0,16); pl.Position=UDim2.new(0,72,0,74)
    pl.BackgroundTransparency=1; pl.Text="0 / ?"; pl.Font=Enum.Font.Gotham
    pl.TextSize=12; pl.TextColor3=C.sub; pl.TextXAlignment=Enum.TextXAlignment.Left

    local rb=Instance.new("Frame",card); rb.Size=UDim2.new(0,58,0,28)
    rb.Position=UDim2.new(1,-68,0,12); rb.BackgroundColor3=Color3.fromRGB(255,242,180)
    rb.BorderSizePixel=0; Instance.new("UICorner",rb).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",rb).Color=Color3.fromRGB(220,180,50)
    local rl=Instance.new("TextLabel",rb); rl.Size=UDim2.new(1,0,1,0)
    rl.BackgroundTransparency=1; rl.Text="💰 "..(q.reward_gold or q.reward or 0)
    rl.Font=Enum.Font.GothamBold; rl.TextSize=13; rl.TextColor3=Color3.fromRGB(160,120,30)

    -- Checkbox for completed quests (hidden by default)
    local checkBtn=Instance.new("TextButton",card); checkBtn.Name="CheckBtn"
    checkBtn.Size=UDim2.new(0,58,0,28); checkBtn.Position=UDim2.new(1,-68,0,74)
    checkBtn.BackgroundColor3=Color3.fromRGB(100,185,100); checkBtn.BorderSizePixel=0
    checkBtn.Text="✓"; checkBtn.Font=Enum.Font.GothamBold
    checkBtn.TextSize=16; checkBtn.TextColor3=Color3.new(1,1,1)
    checkBtn.Visible=false
    Instance.new("UICorner",checkBtn).CornerRadius=UDim.new(0,8)
    
    checkBtn.MouseButton1Click:Connect(function()
        -- Fade out and remove the card
        Tween:Create(card,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        for _,child in pairs(card:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("Frame") or child:IsA("TextButton") then
                child.Visible=false
            end
        end
        task.delay(0.35,function() card:Destroy() end)
    end)

    cards[q.id]={card=card,fill=bf,prog=pl,cs=cs,em=em,checkBtn=checkBtn}
end

local function updateCards(quests,progress)
    for _,q in ipairs(quests) do
        if not cards[q.id] then
            for i,qq in ipairs(quests) do if qq.id==q.id then buildCard(qq,i) break end end
        end
        local w=cards[q.id]; local p=progress and progress[q.id]
        if w and p then
            local frac=math.clamp(p.current/math.max(p.goal,1),0,1)
            Tween:Create(w.fill,TweenInfo.new(0.4),{Size=UDim2.new(frac,0,1,0)}):Play()
            w.prog.Text=p.current.." / "..p.goal
            if p.done then
                w.cs.Color=C.done; w.card.BackgroundColor3=Color3.fromRGB(235,250,235); w.em.Text="✅"
                w.checkBtn.Visible=true
            end
        end
    end
end
if ev then ev.OnClientEvent:Connect(updateCards) end

-- Handle batch quest completions
local qcBatch = RE:FindFirstChild("QuestCompletedBatch")
if qcBatch then
	qcBatch.OnClientEvent:Connect(function(completions)
		for _, q in ipairs(completions) do
			spawnPopup("quest_complete", q.title, Color3.fromRGB(160, 210, 150))
			UIHelper.spawnSparkles(panel, panel.AbsolutePosition.X + 200, panel.AbsolutePosition.Y + 60,
				Color3.fromRGB(180, 150, 110), 8)
		end
	end)
end

-- Popup helper (matches QuestScript's style)
local function spawnPopup(kind, text, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 300, 0, 40)
	lbl.Position = UDim2.new(0.5, -150, 0, math.random(100, 180))
	lbl.BackgroundTransparency = 0.1
	lbl.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
	lbl.Text = text
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 18
	lbl.TextColor3 = color or Color3.fromRGB(100, 185, 100)
	lbl.TextStrokeTransparency = 0.3
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.Parent = gui
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 12)
	local bs = Instance.new("UIStroke", lbl); bs.Color = Color3.fromRGB(180, 150, 110); bs.Thickness = 2

	local upTween = Tween:Create(lbl, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = lbl.Position - UDim2.new(0, 0, 0, 80),
	})
	local fadeTween = Tween:Create(lbl, TweenInfo.new(0.6), { BackgroundTransparency = 1, TextTransparency = 1 })
	upTween:Play()
	task.delay(0.8, function() fadeTween:Play() end)
	task.delay(1.6, function() lbl:Destroy() end)
end

local open=false
local function toggle()
    open=not open; panel.Visible=open
    if open then
        panel.Size=UDim2.new(0,420,0,10)
        Tween:Create(panel,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,420,0,520)}):Play()
    end
end
closeBtn.MouseButton1Click:Connect(function() open=true; toggle() end)
task.spawn(function()
    local pg=player:WaitForChild("PlayerGui")
    local h=pg:WaitForChild("ZundaHUD",15)
    if h then local b=h:WaitForChild("HudButtons",8)
        if b then local btn=b:FindFirstChild("HudBtn_quests")
            if btn then btn.MouseButton1Click:Connect(toggle) end end end
end)
UIS.InputBegan:Connect(function(i,g) if g then return end if i.KeyCode==Enum.KeyCode.J then toggle() end end)
print("[QuestPanel] Ready")
