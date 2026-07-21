-- [[LocalScript] TimedCookingScript (ref: RBX71C0364C76F44E4D8593ABA83AC89F83)]]
-- Rhythm Cooking Minigame: pea notes scroll across a track. Hit each one in the
-- target zone. Score = ratio of Perfects to total notes.
--
-- Exposes _G.TimedCooking.start(recipeName, onComplete) where onComplete is
-- called with (greatOrBetter:boolean, perfect:boolean).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIAssets = require(RS.Shared.Config.UIAssets)
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local GetCompanionBuff = RS:WaitForChild("RemoteFunctions"):WaitForChild("GetActiveCompanionBuff")

local function getSoundId(assetKey, fallback)
	local id = UIAssets.sounds[assetKey]
	if typeof(id) == "string" and not id:match("FILL_") and not id:match("rbxassetid://0$") then
		return id
	end
	return fallback
end

-- Per-recipe difficulty comes from shared CraftConfig (server validates against it)
local CraftConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("CraftConfig"))
local RECIPES = CraftConfig.difficulty

-- ── ROOT GUI ────────────────────────────────────────────────────────────
local cookingGui = playerGui:FindFirstChild("CookingMinigame")
if cookingGui then cookingGui:Destroy() end
cookingGui = Instance.new("ScreenGui")
cookingGui.Name = "CookingMinigame"
cookingGui.ResetOnSpawn = false
cookingGui.IgnoreGuiInset = true
cookingGui.DisplayOrder = 90
cookingGui.Parent = playerGui

-- Dim backdrop
local backdrop = Instance.new("Frame", cookingGui)
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
backdrop.BackgroundTransparency = 0.55
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.ZIndex = 1

-- Panel (much bigger)
local panel = Instance.new("Frame", cookingGui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 760, 0, 480)
panel.Position = UDim2.new(0.5, -380, 0.5, -240)
panel.BackgroundColor3 = UIConfig.COLORS.PanelBg
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
local panelCorner = Instance.new("UICorner", panel); panelCorner.CornerRadius = UDim.new(0, 28)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Thickness = 4
panelStroke.Color = UIConfig.GAME_COLORS.HUDAccent

-- Subtle gradient backdrop
local gradient = Instance.new("UIGradient", panel)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 255, 240)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 250, 245)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 250, 220)),
})
gradient.Rotation = 30

-- Decorative pea sprinkles around the panel border
local function addPeaDecoration(panel, x, y, rotation, scale)
    local pea = Instance.new("TextLabel", panel)
    pea.Size = UDim2.new(0, 36 * scale, 0, 36 * scale)
    pea.Position = UDim2.new(x[1], x[2], y[1], y[2])
    pea.BackgroundTransparency = 1
    pea.Text = "🫛"
    pea.Font = Enum.Font.GothamBold
    pea.TextScaled = true
    pea.Rotation = rotation
    pea.TextTransparency = 0.4
    pea.ZIndex = 2
    return pea
end
addPeaDecoration(panel, {0, 14},  {0, 14},  -22, 1.2)
addPeaDecoration(panel, {1, -60}, {0, 16},   20, 1.0)
addPeaDecoration(panel, {0, 20},  {1, -56}, -10, 0.9)
addPeaDecoration(panel, {1, -56}, {1, -54},  35, 1.1)

-- Title
local recipeTitle = Instance.new("TextLabel", panel)
recipeTitle.Name = "RecipeTitle"
recipeTitle.Size = UDim2.new(1, -40, 0, 56)
recipeTitle.Position = UDim2.new(0, 20, 0, 18)
recipeTitle.BackgroundTransparency = 1
recipeTitle.Text = "🫛  Zunda Kitchen"
recipeTitle.Font = Enum.Font.FredokaOne
recipeTitle.TextSize = 36
recipeTitle.TextColor3 = UIConfig.COLORS.TextDark
recipeTitle.ZIndex = 3

-- Subtitle: hint + score
local hint = Instance.new("TextLabel", panel)
hint.Name = "Hint"
hint.Size = UDim2.new(1, -40, 0, 26)
hint.Position = UDim2.new(0, 20, 0, 72)
hint.BackgroundTransparency = 1
hint.Text = "✨ Press SPACE or click COOK when each pea reaches the ring ✨"
hint.Font = Enum.Font.Gotham
hint.TextSize = 16
hint.TextColor3 = UIConfig.COLORS.TextDarkSec
hint.ZIndex = 3

-- Score label
local scoreLabel = Instance.new("TextLabel", panel)
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0, 200, 0, 32)
scoreLabel.Position = UDim2.new(1, -220, 0, 22)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = ""
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 22
scoreLabel.TextColor3 = UIConfig.GAME_COLORS.HUDAccent
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
scoreLabel.ZIndex = 3

local comboLabel = Instance.new("TextLabel", panel)
comboLabel.Name = "ComboLabel"
comboLabel.Size = UDim2.new(0, 160, 0, 28)
comboLabel.Position = UDim2.new(1, -180, 0, 56)
comboLabel.BackgroundTransparency = 1
comboLabel.Text = ""
comboLabel.Font = Enum.Font.FredokaOne
comboLabel.TextSize = 20
comboLabel.TextColor3 = UIConfig.GAME_COLORS.ComboWarm
comboLabel.TextXAlignment = Enum.TextXAlignment.Right
comboLabel.ZIndex = 3

-- ── TRACK ───────────────────────────────────────────────────────────────
local trackContainer = Instance.new("Frame", panel)
trackContainer.Name = "TrackContainer"
trackContainer.Size = UDim2.new(1, -80, 0, 130)
trackContainer.Position = UDim2.new(0, 40, 0, 130)
trackContainer.BackgroundColor3 = UIConfig.GAME_COLORS.CookingTrack
trackContainer.BorderSizePixel = 0
trackContainer.ZIndex = 3
local tcCorner = Instance.new("UICorner", trackContainer); tcCorner.CornerRadius = UDim.new(0, 22)
local tcStroke = Instance.new("UIStroke", trackContainer); tcStroke.Color = Color3.fromRGB(140, 210, 130); tcStroke.Thickness = 2; tcStroke.Transparency = 0.4

-- Decorative track line (where peas roll along)
local trackLine = Instance.new("Frame", trackContainer)
trackLine.Name = "TrackLine"
trackLine.Size = UDim2.new(1, -40, 0, 4)
trackLine.Position = UDim2.new(0, 20, 0.5, -2)
trackLine.BackgroundColor3 = Color3.fromRGB(160, 220, 150)
trackLine.BorderSizePixel = 0
trackLine.ZIndex = 4
local tlCorner = Instance.new("UICorner", trackLine); tlCorner.CornerRadius = UDim.new(1, 0)

-- Hit target ring (centered horizontally for clarity but actually at 70% right for left-to-right scroll)
local TARGET_X = 0.75   -- 75% across the track
local hitRing = Instance.new("Frame", trackContainer)
hitRing.Name = "HitRing"
hitRing.Size = UDim2.new(0, 80, 0, 80)
hitRing.Position = UDim2.new(TARGET_X, -40, 0.5, -40)
hitRing.BackgroundColor3 = UIConfig.GAME_COLORS.CookingTarget
hitRing.BackgroundTransparency = 0.5
hitRing.BorderSizePixel = 0
hitRing.ZIndex = 4
local hrCorner = Instance.new("UICorner", hitRing); hrCorner.CornerRadius = UDim.new(1, 0)
local hrStroke = Instance.new("UIStroke", hitRing); hrStroke.Color = Color3.fromRGB(100, 200, 110); hrStroke.Thickness = 4

-- Inner perfect ring
local perfectRing = Instance.new("Frame", hitRing)
perfectRing.Size = UDim2.new(0, 36, 0, 36)
perfectRing.Position = UDim2.new(0.5, -18, 0.5, -18)
perfectRing.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
perfectRing.BackgroundTransparency = 0.4
perfectRing.BorderSizePixel = 0
perfectRing.ZIndex = 5
local prCorner = Instance.new("UICorner", perfectRing); prCorner.CornerRadius = UDim.new(1, 0)
local prStroke = Instance.new("UIStroke", perfectRing); prStroke.Color = Color3.fromRGB(255, 200, 100); prStroke.Thickness = 3

-- COOK button (the big tactile press button)
local clickBtn = Instance.new("TextButton", panel)
clickBtn.Name = "CookButton"
clickBtn.Size = UDim2.new(0, 360, 0, 78)
clickBtn.Position = UDim2.new(0.5, -180, 0, 290)
clickBtn.BackgroundColor3 = UIConfig.COLORS.Success
clickBtn.Text = "🫛  COOK!  🫛"
clickBtn.Font = Enum.Font.FredokaOne
clickBtn.TextSize = 38
clickBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
clickBtn.BorderSizePixel = 0
clickBtn.AutoButtonColor = false
clickBtn.ZIndex = 4
local cbCorner = Instance.new("UICorner", clickBtn); cbCorner.CornerRadius = UDim.new(0, 22)
local cbStroke = Instance.new("UIStroke", clickBtn); cbStroke.Color = Color3.fromRGB(60, 155, 70); cbStroke.Thickness = 3

-- Result banner
local resultLabel = Instance.new("TextLabel", panel)
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.new(1, -40, 0, 42)
resultLabel.Position = UDim2.new(0, 20, 0, 388)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.Font = Enum.Font.FredokaOne
resultLabel.TextSize = 30
resultLabel.TextColor3 = UIConfig.COLORS.TextDark
resultLabel.ZIndex = 4

-- Progress dots row (one dot per note, lit as you go)
local progressRow = Instance.new("Frame", panel)
progressRow.Name = "ProgressRow"
progressRow.Size = UDim2.new(1, -40, 0, 20)
progressRow.Position = UDim2.new(0, 20, 0, 100)
progressRow.BackgroundTransparency = 1
progressRow.ZIndex = 3
local prLayout = Instance.new("UIListLayout", progressRow)
prLayout.FillDirection = Enum.FillDirection.Horizontal
prLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
prLayout.Padding = UDim.new(0, 10)

-- ── HELPERS ─────────────────────────────────────────────────────────────
local function spawnSparkles(parent, x, y, color, count)
    count = count or 12
    for i = 1, count do
        local s = Instance.new("TextLabel", parent)
        s.Size = UDim2.new(0, 18, 0, 18)
        s.Position = UDim2.new(0, x - 9, 0, y - 9)
        s.BackgroundTransparency = 1
        s.Text = ({"✨", "⭐", "💫", "🫛"})[math.random(1, 4)]
        s.Font = Enum.Font.GothamBold
        s.TextScaled = true
        s.TextColor3 = color
        s.ZIndex = 10
        local angle = math.random() * math.pi * 2
        local dist = math.random(40, 100)
        local tx = x + math.cos(angle) * dist - 9
        local ty = y + math.sin(angle) * dist - 9
        TweenService:Create(s, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, tx, 0, ty),
            TextTransparency = 1,
            Rotation = math.random(-180, 180),
        }):Play()
        game:GetService("Debris"):AddItem(s, 1)
    end
end

local function pulseRing()
    local origSize = hitRing.Size
    hitRing.Size = UDim2.new(0, 100, 0, 100)
    hitRing.Position = UDim2.new(TARGET_X, -50, 0.5, -50)
    TweenService:Create(hitRing, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = origSize,
        Position = UDim2.new(TARGET_X, -40, 0.5, -40),
    }):Play()
end

local function playSound(id, volume, pitch)
    local s = Instance.new("Sound", playerGui)
    s.SoundId = id
    s.Volume = volume or 0.5
    s.PlaybackSpeed = pitch or 1
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
end

-- ── CORE STATE ──────────────────────────────────────────────────────────
local isCooking = false
local activeNotes = {}      -- { note=Frame, hit=bool, scoreTag=string, spawnTime=number }
local scores = {}           -- list of { tag = "perfect"|"great"|"good"|"miss" }
local totalNotesPlanned = 0
local currentCombo = 0
local stepConn = nil
local currentRecipe = nil
local currentRecipeCfg = nil
local currentOnComplete = nil

local function stopRunning()
    if stepConn then stepConn:Disconnect(); stepConn = nil end
    isCooking = false
    for _, n in ipairs(activeNotes) do
        if n.note and n.note.Parent then n.note:Destroy() end
    end
    activeNotes = {}
end

local function makeNote()
    local container = trackContainer
    local note = Instance.new("TextLabel", container)
    note.Size = UDim2.new(0, 48, 0, 48)
    note.Position = UDim2.new(0, -50, 0.5, -24)
    note.BackgroundTransparency = 1
    note.Text = "🫛"
    note.Font = Enum.Font.GothamBold
    note.TextScaled = true
    note.ZIndex = 6
    note.TextColor3 = Color3.fromRGB(120, 200, 120)
    return note
end

local function noteX(noteFrame)
    return noteFrame.AbsolutePosition.X + noteFrame.AbsoluteSize.X / 2
end

local function ringX()
    return hitRing.AbsolutePosition.X + hitRing.AbsoluteSize.X / 2
end

local function judgeFirstUnhitNote()
    -- Find the first un-hit note nearest the ring
    local bestIdx = nil
    local bestDist = math.huge
    local target = ringX()
    for i, n in ipairs(activeNotes) do
        if not n.hit and n.note and n.note.Parent then
            local dist = math.abs(noteX(n.note) - target)
            if dist < bestDist then bestDist = dist; bestIdx = i end
        end
    end
    if not bestIdx then return end
    local n = activeNotes[bestIdx]
    n.hit = true
    -- Tier judgement based on pixel distance from ring center
    -- Cardamon companion: widens the perfect window
    local cardamonBoost = 0
    pcall(function() cardamonBoost = GetCompanionBuff:InvokeServer("perfect_window") or 0 end)
    local perfectThresh = 20 * (1 + cardamonBoost)
    local greatThresh   = 45 * (1 + cardamonBoost * 0.5)
    local tag, color
    if bestDist < perfectThresh then
        tag, color = "perfect", UIConfig.GAME_COLORS.CookingPerfect
    elseif bestDist < greatThresh then
        tag, color = "great", UIConfig.GAME_COLORS.CookingGreat
    elseif bestDist < 80 then
        tag, color = "good", UIConfig.GAME_COLORS.CookingGood
    else
        tag, color = "miss", UIConfig.GAME_COLORS.CookingMiss
    end
    n.scoreTag = tag
    table.insert(scores, { tag = tag })

    -- Mark progress dot
    local dot = progressRow:FindFirstChild("Dot" .. #scores)
    if dot then
        dot.BackgroundColor3 = color
        TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.new(0, 26, 0, 26) }):Play()
    end

    -- Burst feedback
    local lx, ly = n.note.AbsolutePosition.X - panel.AbsolutePosition.X + 24,
                   n.note.AbsolutePosition.Y - panel.AbsolutePosition.Y + 24
    spawnSparkles(panel, lx, ly, color, tag == "perfect" and 18 or 10)
    pulseRing()

    -- Float-up score popup
    local pop = Instance.new("TextLabel", panel)
    pop.Size = UDim2.new(0, 120, 0, 32)
    pop.Position = UDim2.new(0, lx - 60, 0, ly - 50)
    pop.BackgroundTransparency = 1
    pop.Text = string.upper(tag) .. "!"
    pop.Font = Enum.Font.FredokaOne
    pop.TextSize = 28
    pop.TextColor3 = color
    pop.TextStrokeTransparency = 0.6
    pop.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    pop.ZIndex = 11
    TweenService:Create(pop, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, lx - 60, 0, ly - 100),
        TextTransparency = 1,
    }):Play()
    game:GetService("Debris"):AddItem(pop, 0.8)

    -- Fade the pea
    TweenService:Create(n.note, TweenInfo.new(0.3), {
        TextTransparency = 1,
        Size = UDim2.new(0, 72, 0, 72),
        Position = n.note.Position - UDim2.new(0, 0, 0, 30),
    }):Play()
    task.delay(0.35, function() if n.note and n.note.Parent then n.note:Destroy() end end)

    if tag == "perfect" then
        playSound(getSoundId("craft_perfect", "rbxasset://sounds/electronicpingshort.wav"), 0.6, 1.4)
    elseif tag == "great" then
        playSound(getSoundId("craft_perfect", "rbxasset://sounds/electronicpingshort.wav"), 0.5, 1.2)
    elseif tag == "good" then
        playSound(getSoundId("ui_click", "rbxasset://sounds/button-09.mp3"), 0.5, 1.0)
    else
        playSound(getSoundId("gather_fail", "rbxasset://sounds/button-09.mp3"), 0.4, 0.7)
    end

    -- Update combo
    if tag == "perfect" or tag == "great" then
        currentCombo = currentCombo + 1
    else
        currentCombo = 0
    end
    if currentCombo >= 2 then
        comboLabel.Text = "🔥 " .. currentCombo .. "x combo"
        comboLabel.TextColor3 = currentCombo >= 5 and UIConfig.GAME_COLORS.ComboFire or UIConfig.GAME_COLORS.ComboWarm
    else
        comboLabel.Text = ""
    end

    -- Update score label
    local pCount = 0
    for _, s in ipairs(scores) do if s.tag == "perfect" then pCount = pCount + 1 end end
    scoreLabel.Text = ("Perfect %d/%d"):format(pCount, totalNotesPlanned)
end

local function finishCooking()
    stopRunning()
    -- Compute quality
    local perfects, greats, hits = 0, 0, 0
    for _, s in ipairs(scores) do
        if s.tag == "perfect" then perfects = perfects + 1; hits = hits + 1
        elseif s.tag == "great" then greats = greats + 1; hits = hits + 1
        elseif s.tag == "good" then hits = hits + 1 end
    end
    local quality
    if perfects == totalNotesPlanned then
        quality = "perfect"
        resultLabel.Text = "✨ FLAWLESS! ALL PERFECTS! ✨"
        resultLabel.TextColor3 = UIConfig.GAME_COLORS.ComboWarm
        spawnSparkles(panel, panel.AbsoluteSize.X / 2, 280, UIConfig.GAME_COLORS.SparkleGold, 40)
    elseif perfects >= math.ceil(totalNotesPlanned * 0.6) then
        quality = "perfect"
        resultLabel.Text = "🌟 PERFECT DISH! 🌟"
        resultLabel.TextColor3 = UIConfig.GAME_COLORS.ComboWarm
        spawnSparkles(panel, panel.AbsoluteSize.X / 2, 280, UIConfig.GAME_COLORS.SparkleGold, 25)
    elseif hits >= math.ceil(totalNotesPlanned * 0.5) then
        quality = "great"
        resultLabel.Text = "👍 Great timing!"
        resultLabel.TextColor3 = UIConfig.COLORS.Success
    else
        quality = "ok"
        resultLabel.Text = "😅 A bit off… but it works!"
        resultLabel.TextColor3 = UIConfig.COLORS.TextSecondary
    end

    task.delay(2.2, function()
        panel.Visible = false
        backdrop.Visible = false
        if currentOnComplete then
            local cb = currentOnComplete; currentOnComplete = nil
            cb(quality, scores)
        end
    end)
end

local function startCooking(recipeName, onComplete)
    if isCooking then return false end
    isCooking = true
    currentRecipe = recipeName
    currentRecipeCfg = RECIPES[recipeName] or { notes = 4, speed = 1.8 }
    currentOnComplete = onComplete
    scores = {}
    activeNotes = {}
    totalNotesPlanned = currentRecipeCfg.notes

    -- Clear track + progress dots
    for _, c in pairs(trackContainer:GetChildren()) do
        if c:IsA("TextLabel") and c.Text == "🫛" then c:Destroy() end
    end
    for _, c in pairs(progressRow:GetChildren()) do
        if c:IsA("Frame") and c.Name:find("Dot") then c:Destroy() end
    end

    -- Build progress dots
    for i = 1, totalNotesPlanned do
        local dot = Instance.new("Frame", progressRow)
        dot.Name = "Dot" .. i
        dot.Size = UDim2.new(0, 18, 0, 18)
        dot.BackgroundColor3 = Color3.fromRGB(230, 220, 230)
        dot.BorderSizePixel = 0
        dot.LayoutOrder = i
        dot.ZIndex = 4
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    end

    recipeTitle.Text = "🍳 Cooking: " .. recipeName
    resultLabel.Text = ""
    scoreLabel.Text = ("Perfect 0/%d"):format(totalNotesPlanned)
    currentCombo = 0
    comboLabel.Text = ""
    backdrop.Visible = true
    panel.Visible = true
    playSound(getSoundId("craft_start", "rbxasset://sounds/electronicpingshort.wav"), 0.4, 1.0)
    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(0, 740, 0, 460)
    TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 760, 0, 480),
        BackgroundTransparency = 0,
    }):Play()

    -- Schedule each note: spawn left, scroll right past the ring
    local startTime = tick()
    local interval = currentRecipeCfg.speed * 0.65   -- gap between spawns
    local notesSpawned = 0

    stepConn = RunService.Heartbeat:Connect(function()
        if not isCooking then return end
        local now = tick()

        -- Spawn next note?
        if notesSpawned < totalNotesPlanned then
            local nextSpawnAt = startTime + notesSpawned * interval
            if now >= nextSpawnAt then
                local note = makeNote()
                table.insert(activeNotes, { note = note, hit = false, spawnTime = now })
                notesSpawned = notesSpawned + 1
            end
        end

        -- Move active notes; auto-fail ones that pass off-screen
        for _, n in ipairs(activeNotes) do
            if not n.hit and n.note and n.note.Parent then
                local p = (now - n.spawnTime) / currentRecipeCfg.speed
                local x = -50 + p * (trackContainer.AbsoluteSize.X + 80)
                n.note.Position = UDim2.new(0, x, 0.5, -24)
                -- Color shift as it nears the ring
                local distToRing = math.abs(noteX(n.note) - ringX())
                if distToRing < 50 then
                    n.note.TextColor3 = Color3.fromRGB(140, 220, 100)
                elseif distToRing < 100 then
                    n.note.TextColor3 = Color3.fromRGB(120, 200, 120)
                end
                -- Auto-miss if past the ring with margin
                if (noteX(n.note) - ringX()) > 90 then
                    n.hit = true
                    n.scoreTag = "miss"
                    table.insert(scores, { tag = "miss" })
                    local dot = progressRow:FindFirstChild("Dot" .. #scores)
                    if dot then dot.BackgroundColor3 = Color3.fromRGB(220, 100, 110) end
                    TweenService:Create(n.note, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                end
            end
        end

        -- All scores in?
        if #scores >= totalNotesPlanned then
            finishCooking()
        end
    end)

    return true
end

-- ── INPUT ───────────────────────────────────────────────────────────────
clickBtn.MouseButton1Click:Connect(function()
    if isCooking then
        judgeFirstUnhitNote()
        local pos = clickBtn.AbsolutePosition
        local sz = clickBtn.AbsoluteSize
        UIHelper.spawnSparkles(clickBtn.Parent, pos.X + sz.X / 2, pos.Y + sz.Y / 2, Color3.fromRGB(120, 255, 140), 6)
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed or not isCooking then return end
    if input.KeyCode == Enum.KeyCode.Space then
        judgeFirstUnhitNote()
    end
end)

-- ── PUBLIC API (kept compatible with old _G.TimedCooking shape) ─────────
_G.TimedCooking = {
    start = startCooking,
    isCooking = function() return isCooking end,
    stop = stopRunning,
}

print("[RhythmCooking] Ready — pea-rhythm minigame loaded")
