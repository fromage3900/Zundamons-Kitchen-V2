-- [[LocalScript] MinimapScript (ref: RBX5F237BA2E7C942F7B4D645A763BB1484)]]
local Players  = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunSvc   = game:GetService("RunService")
local player   = Players.LocalPlayer
local gui      = script.Parent

-- ── CONFIG ─────────────────────────────────────────────────────────────────
-- World bounds (from terrain survey)
local WORLD = { minX=-60, maxX=210, minZ=-260, maxZ=160 }
local function worldToMM(wx, wz)
    local u = (wx - WORLD.minX) / (WORLD.maxX - WORLD.minX)
    local v = (wz - WORLD.minZ) / (WORLD.maxZ - WORLD.minZ)
    return math.clamp(u,0.03,0.97), math.clamp(v,0.03,0.97)
end

-- ── OUTER FRAME ────────────────────────────────────────────────────────────
local outer = Instance.new("Frame", gui)
outer.Name        = "MinimapOuter"
outer.Size        = UDim2.new(0, 170, 0, 170)
outer.Position    = UDim2.new(1, -184, 0, 14)
outer.AnchorPoint = Vector2.new(0, 0)
outer.BackgroundColor3 = Color3.fromRGB(22, 18, 30)
outer.BackgroundTransparency = 0.15
outer.BorderSizePixel = 0
Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 16)
local ost = Instance.new("UIStroke", outer)
ost.Thickness = 2; ost.Color = Color3.fromRGB(180, 150, 220); ost.Transparency = 0.2

-- Title bar inside
local titleBar = Instance.new("TextLabel", outer)
titleBar.Size = UDim2.new(1,-8,0,20); titleBar.Position = UDim2.new(0,4,0,3)
titleBar.BackgroundTransparency = 1; titleBar.Text = "🗺  Map"
titleBar.Font = Enum.Font.FredokaOne; titleBar.TextSize = 14
titleBar.TextColor3 = Color3.fromRGB(220,210,240)
titleBar.TextXAlignment = Enum.TextXAlignment.Left

-- Map canvas
local canvas = Instance.new("Frame", outer)
canvas.Name = "Canvas"
canvas.Size = UDim2.new(1,-8,1,-28); canvas.Position = UDim2.new(0,4,0,24)
canvas.BackgroundColor3 = Color3.fromRGB(148, 190, 145)  -- terrain green
canvas.BorderSizePixel = 0
Instance.new("UICorner", canvas).CornerRadius = UDim.new(0,10)

-- ── ZONE TILES ON MINIMAP ──────────────────────────────────────────────────
local ZONES = {
    { label="Village",  wx=47,  wz=-74,  color=Color3.fromRGB(245,200,210), tw=0.14,th=0.14 },
    { label="Kitchen",  wx=9,   wz=-41,  color=Color3.fromRGB(195,240,165), tw=0.14,th=0.14 },
    { label="E.Peaks",  wx=130, wz=73,   color=Color3.fromRGB(175,205,255), tw=0.12,th=0.12 },
    { label="Mystic",   wx=149, wz=-195, color=Color3.fromRGB(215,175,255), tw=0.12,th=0.12 },
}
for _, z in ipairs(ZONES) do
    local u, v = worldToMM(z.wx, z.wz)
    local tile = Instance.new("Frame", canvas)
    tile.AnchorPoint = Vector2.new(0.5,0.5)
    tile.Position = UDim2.new(u,0,v,0)
    tile.Size = UDim2.new(z.tw,0,z.th,0)
    tile.BackgroundColor3 = z.color; tile.BorderSizePixel = 0
    Instance.new("UICorner",tile).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel",tile)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text=z.label; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=8
    lbl.TextColor3=Color3.fromRGB(50,40,60)
end

-- Teleporter pad dots
local TP_ZONES = {
    {emoji="🏘",wx=47,wz=-74},{emoji="🍳",wx=9,wz=-41},
    {emoji="🗻",wx=130,wz=73},{emoji="✨",wx=149,wz=-195},
}
for _, t in ipairs(TP_ZONES) do
    local u,v = worldToMM(t.wx, t.wz)
    local dot=Instance.new("Frame",canvas)
    dot.Size=UDim2.new(0,8,0,8); dot.AnchorPoint=Vector2.new(0.5,0.5)
    dot.Position=UDim2.new(u,0,v,0)
    dot.BackgroundColor3=Color3.fromRGB(100,80,180); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(0.5,0)
end

-- ── PLAYER PIN ────────────────────────────────────────────────────────────
local pin = Instance.new("Frame", canvas)
pin.Name="PlayerPin"; pin.Size=UDim2.new(0,10,0,10); pin.AnchorPoint=Vector2.new(0.5,0.5)
pin.BackgroundColor3=Color3.fromRGB(255,80,80); pin.BorderSizePixel=0; pin.ZIndex=4
Instance.new("UICorner",pin).CornerRadius=UDim.new(0.5,0)
-- White ring around player pin
local pinRing=Instance.new("Frame",pin)
pinRing.Size=UDim2.new(1,4,1,4); pinRing.AnchorPoint=Vector2.new(0.5,0.5)
pinRing.Position=UDim2.new(0.5,0,0.5,0); pinRing.BackgroundTransparency=1; pinRing.BorderSizePixel=0
local ringStroke=Instance.new("UIStroke",pinRing); ringStroke.Thickness=1.5; ringStroke.Color=Color3.new(1,1,1)
Instance.new("UICorner",pinRing).CornerRadius=UDim.new(0.5,0)

-- Direction arrow (tiny triangle pointing where player faces)
local arrow=Instance.new("Frame",canvas)
arrow.Name="Arrow"; arrow.Size=UDim2.new(0,6,0,6); arrow.AnchorPoint=Vector2.new(0.5,0.5)
arrow.BackgroundColor3=Color3.fromRGB(255,200,80); arrow.BorderSizePixel=0; arrow.ZIndex=5

-- ── COMPANION DOT ─────────────────────────────────────────────────────────
local compDot=Instance.new("Frame",canvas)
compDot.Name="CompanionDot"; compDot.Size=UDim2.new(0,7,0,7); compDot.AnchorPoint=Vector2.new(0.5,0.5)
compDot.BackgroundColor3=Color3.fromRGB(100,220,180); compDot.BorderSizePixel=0; compDot.ZIndex=4
compDot.Visible=false
Instance.new("UICorner",compDot).CornerRadius=UDim.new(0.5,0)

-- ── TIME + WEATHER STRIP ──────────────────────────────────────────────────
local timeStrip = Instance.new("Frame", outer)
timeStrip.Size=UDim2.new(1,-8,0,18); timeStrip.Position=UDim2.new(0,4,1,-20)
timeStrip.BackgroundTransparency=1
local timeLbl=Instance.new("TextLabel",timeStrip)
timeLbl.Name="TimeLbl"; timeLbl.Size=UDim2.new(0.5,0,1,0); timeLbl.BackgroundTransparency=1
timeLbl.Text="--:--"; timeLbl.Font=Enum.Font.GothamBold; timeLbl.TextSize=11
timeLbl.TextColor3=Color3.fromRGB(200,195,220); timeLbl.TextXAlignment=Enum.TextXAlignment.Left
local weatherLbl=Instance.new("TextLabel",timeStrip)
weatherLbl.Name="WeatherLbl"; weatherLbl.Size=UDim2.new(0.5,0,1,0); weatherLbl.Position=UDim2.new(0.5,0,0,0)
weatherLbl.BackgroundTransparency=1; weatherLbl.Text="☀"
weatherLbl.Font=Enum.Font.GothamBold; weatherLbl.TextSize=11
weatherLbl.TextColor3=Color3.fromRGB(200,195,220); weatherLbl.TextXAlignment=Enum.TextXAlignment.Right

-- ── UPDATE LOOP ──────────────────────────────────────────────────────────
local function fmtH(h)
    local hr=math.floor(h); local mn=math.floor((h-hr)*60)
    return string.format("%02d:%02d",hr,mn)
end

RunSvc.Heartbeat:Connect(function()
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local u,v = worldToMM(hrp.Position.X, hrp.Position.Z)
        pin.Position = UDim2.new(u,0,v,0)
        arrow.Position = UDim2.new(u,0,v,0)
        -- Rotate arrow toward look direction (approximated)
        local lookAngle = math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z)
        arrow.Rotation = math.deg(lookAngle)
    end

    -- Companion position
    local compModel = workspace:FindFirstChild("ZundaCompanion_"..player.Name)
    if compModel then
        local cbp = compModel:FindFirstChildOfClass("BasePart")
        if cbp then
            compDot.Visible = true
            local cu,cv = worldToMM(cbp.Position.X, cbp.Position.Z)
            compDot.Position = UDim2.new(cu,0,cv,0)
        end
    else
        compDot.Visible = false
    end
end)

-- Time + weather (low frequency)
task.spawn(function()
    local Lighting = game:GetService("Lighting")
    while true do
        local h = Lighting.ClockTime
        timeLbl.Text = fmtH(h)
        local w = workspace:GetAttribute("CurrentWeather") or "clear"
        local icons={clear="☀",cloudy="☁",rain="🌧",snow="❄",cherry_blossom="🌸",aurora="🌌"}
        weatherLbl.Text = (icons[w] or "☀")
        task.wait(3)
    end
end)

print("[Minimap] Active — top-right corner")
