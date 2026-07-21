-- [[LocalScript] FishingMinigameScript (ref: RBXC33B2BA98CDA43F1AB4CA400B4914639)]]
-- Tension-bar fishing minigame.
-- A "tension" indicator moves chaotically left/right driven by the fish's tugs.
-- Player must HOLD SPACE (or click REEL) to reel; tension increases when reeling.
-- If tension hits max, line snaps (lose). If progress bar fills, fish caught.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RS = game:GetService("ReplicatedStorage")
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = script.Parent

-- Backdrop
local backdrop = Instance.new("Frame", gui)
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.ZIndex = 1

-- Panel
local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 720, 0, 460)
panel.Position = UDim2.new(0.5, -360, 0.5, -230)
panel.BackgroundColor3 = UIConfig.COLORS.PanelBg
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 26)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = UIConfig.COLORS.PanelBorder
pStroke.Thickness = 4

-- Decorative water ripple gradient
local grad = Instance.new("UIGradient", panel)
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 245)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 245, 252)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 235, 250)),
})
grad.Rotation = 70

-- Fish display
local fishLabel = Instance.new("TextLabel", panel)
fishLabel.Size = UDim2.new(1, -40, 0, 56)
fishLabel.Position = UDim2.new(0, 20, 0, 16)
fishLabel.BackgroundTransparency = 1
fishLabel.Text = "🎣 Fish on the line!"
fishLabel.Font = Enum.Font.FredokaOne
fishLabel.TextSize = 38
fishLabel.TextColor3 = UIConfig.COLORS.TextDark
fishLabel.ZIndex = 3

local hint = Instance.new("TextLabel", panel)
hint.Size = UDim2.new(1, -40, 0, 24)
hint.Position = UDim2.new(0, 20, 0, 74)
hint.BackgroundTransparency = 1
hint.Text = "Hold SPACE or click REEL — don't let TENSION peak!"
hint.Font = Enum.Font.Gotham
hint.TextSize = 16
hint.TextColor3 = UIConfig.COLORS.TextDarkSec
hint.ZIndex = 3

-- Tension bar (top)
local tensionLabel = Instance.new("TextLabel", panel)
tensionLabel.Size = UDim2.new(1, -40, 0, 22)
tensionLabel.Position = UDim2.new(0, 20, 0, 110)
tensionLabel.BackgroundTransparency = 1
tensionLabel.Text = "TENSION"
tensionLabel.Font = Enum.Font.GothamBold
tensionLabel.TextSize = 14
tensionLabel.TextColor3 = UIConfig.COLORS.Danger
tensionLabel.TextXAlignment = Enum.TextXAlignment.Left
tensionLabel.ZIndex = 3

local tensionTrack = Instance.new("Frame", panel)
tensionTrack.Size = UDim2.new(1, -40, 0, 28)
tensionTrack.Position = UDim2.new(0, 20, 0, 134)
tensionTrack.BackgroundColor3 = Color3.fromRGB(255, 240, 240)
tensionTrack.BorderSizePixel = 0
tensionTrack.ZIndex = 3
Instance.new("UICorner", tensionTrack).CornerRadius = UDim.new(1, 0)

local tensionFill = Instance.new("Frame", tensionTrack)
tensionFill.Size = UDim2.new(0.2, 0, 1, 0)
tensionFill.BackgroundColor3 = UIConfig.COLORS.Danger
tensionFill.BorderSizePixel = 0
tensionFill.ZIndex = 4
Instance.new("UICorner", tensionFill).CornerRadius = UDim.new(1, 0)

-- Progress bar (bottom)
local progressLabel = Instance.new("TextLabel", panel)
progressLabel.Size = UDim2.new(1, -40, 0, 22)
progressLabel.Position = UDim2.new(0, 20, 0, 178)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "REEL PROGRESS"
progressLabel.Font = Enum.Font.GothamBold
progressLabel.TextSize = 14
progressLabel.TextColor3 = UIConfig.COLORS.Success
progressLabel.TextXAlignment = Enum.TextXAlignment.Left
progressLabel.ZIndex = 3

local progressTrack = Instance.new("Frame", panel)
progressTrack.Size = UDim2.new(1, -40, 0, 28)
progressTrack.Position = UDim2.new(0, 20, 0, 202)
progressTrack.BackgroundColor3 = Color3.fromRGB(240, 255, 240)
progressTrack.BorderSizePixel = 0
progressTrack.ZIndex = 3
Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

local progressFill = Instance.new("Frame", progressTrack)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = UIConfig.GAME_COLORS.HUDAccent
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 4
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

-- REEL button (huge, satisfying)
local reelBtn = Instance.new("TextButton", panel)
reelBtn.Size = UDim2.new(0, 360, 0, 92)
reelBtn.Position = UDim2.new(0.5, -180, 0, 264)
reelBtn.BackgroundColor3 = UIConfig.COLORS.Primary
reelBtn.Text = "🎣  REEL  🎣"
reelBtn.Font = Enum.Font.FredokaOne
reelBtn.TextSize = 44
reelBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
reelBtn.AutoButtonColor = false
reelBtn.BorderSizePixel = 0
reelBtn.ZIndex = 3
Instance.new("UICorner", reelBtn).CornerRadius = UDim.new(0, 22)
local rStroke = Instance.new("UIStroke", reelBtn); rStroke.Color = Color3.fromRGB(80, 130, 170); rStroke.Thickness = 3

-- Result label
local resultLabel = Instance.new("TextLabel", panel)
resultLabel.Size = UDim2.new(1, -40, 0, 36)
resultLabel.Position = UDim2.new(0, 20, 0, 380)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.Font = Enum.Font.FredokaOne
resultLabel.TextSize = 26
resultLabel.TextColor3 = Color3.fromRGB(60, 100, 150)
resultLabel.ZIndex = 3

-- ── State / loop ────────────────────────────────────────────────────────
local active = false
local tension = 0.2       -- 0..1
local progress = 0        -- 0..1
local reeling = false
local fishData, difficulty, callback
local stepConn

local function spawnSplash()
    for i = 1, 14 do
        local d = Instance.new("TextLabel", panel)
        d.Size = UDim2.new(0, 24, 0, 24)
        d.Position = UDim2.new(0.5, 0, 0.5, 0)
        d.BackgroundTransparency = 1
        d.Text = ({"💧", "✨", "🐟"})[math.random(1, 3)]
        d.Font = Enum.Font.GothamBold
        d.TextScaled = true
        d.ZIndex = 20
        local ang = math.random() * math.pi * 2
        local dist = math.random(80, 200)
        TweenService:Create(d, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, math.cos(ang) * dist, 0.5, math.sin(ang) * dist),
            TextTransparency = 1,
            Rotation = math.random(-180, 180),
        }):Play()
        game:GetService("Debris"):AddItem(d, 1)
    end
end

local function stop()
    active = false
    reeling = false
    if stepConn then stepConn:Disconnect(); stepConn = nil end
end

local function finish(success)
    if not active then return end
    stop()
    if success then
        resultLabel.Text = "🎉 Caught a " .. fishData.name .. "!"
        resultLabel.TextColor3 = UIConfig.COLORS.Success
        spawnSplash()
    else
        resultLabel.Text = "💔 The line snapped..."
        resultLabel.TextColor3 = UIConfig.COLORS.Danger
    end
    task.delay(2.0, function()
        panel.Visible = false
        backdrop.Visible = false
        if callback then local cb = callback; callback = nil; cb(success) end
    end)
end

reelBtn.MouseButton1Down:Connect(function() reeling = true end)
reelBtn.MouseButton1Up:Connect(function() reeling = false end)
UIS.InputBegan:Connect(function(input, processed)
    if processed or not active then return end
    if input.KeyCode == Enum.KeyCode.Space then reeling = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then reeling = false end
end)

local function start(fish, diff, cb)
    if active then return end
    active = true
    reeling = false
    tension = 0.2
    progress = 0
    fishData = fish
    difficulty = diff
    callback = cb
    fishLabel.Text = "🎣 Something's biting!  (rarity " .. fish.rarity .. ")"
    fishLabel.TextColor3 = fish.color or UIConfig.COLORS.TextDark
    resultLabel.Text = ""
    tensionFill.Size = UDim2.new(tension, 0, 1, 0)
    progressFill.Size = UDim2.new(progress, 0, 1, 0)
    backdrop.Visible = true
    panel.Visible = true
    panel.Size = UDim2.new(0, 680, 0, 440)
    TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 720, 0, 460) }):Play()

    local startTime = tick()
    stepConn = RunService.Heartbeat:Connect(function(dt)
        if not active then return end
        local elapsed = tick() - startTime
        -- Periodic tugs (fish struggles): random spikes
        if math.random() < diff.dodgeChance * dt then
            tension = math.min(1.0, tension + diff.tugMag)
        end
        if reeling then
            progress = math.min(1.0, progress + dt / diff.duration * 1.3)
            tension = math.min(1.0, tension + dt * 0.35)
        else
            -- Tension decays when not reeling
            tension = math.max(0.05, tension - dt * 0.5)
            progress = math.max(0, progress - dt * 0.05)  -- slight slip back
        end
        -- Visual: color shifts as tension rises
        local tcolor = Color3.fromRGB(
            math.floor(120 + tension * 100),
            math.floor(200 - tension * 130),
            math.floor(120 - tension * 100)
        )
        tensionFill.BackgroundColor3 = tcolor
        tensionFill.Size = UDim2.new(tension, 0, 1, 0)
        progressFill.Size = UDim2.new(progress, 0, 1, 0)

        if tension >= 1.0 then finish(false); return end
        if progress >= 1.0 then finish(true); return end
        if elapsed > diff.duration * 2.5 then finish(false); return end
    end)
end

_G.FishingMinigame = {
    start = start,
    stop = stop,
}
print("[FishingMinigame] Ready")
