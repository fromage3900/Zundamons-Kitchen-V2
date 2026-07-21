-- [[LocalScript] HUDScript (ref: RBX0DDB0C73D6D143E9BCA492F09680DD0F)]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local gui = script.Parent
local pill = gui:WaitForChild("ChefPill")
local badge = pill:WaitForChild("Badge")
local tierLabel = pill:WaitForChild("TierLabel")
local xpFill = pill:WaitForChild("XPBar"):WaitForChild("Fill")
local combo = gui:WaitForChild("ComboMeter")
local cCount = combo:WaitForChild("Count")
local cMult = combo:WaitForChild("Mult")
local popupRoot = gui:WaitForChild("PopupRoot")

local rewardEvents = RS:WaitForChild("RewardEvents")
local PopupEvent       = rewardEvents:WaitForChild("PopupEvent")
local ChefLevelUpdate  = rewardEvents:WaitForChild("ChefLevelUpdate")
local ComboUpdate      = rewardEvents:WaitForChild("ComboUpdate")
local LevelUpEvent     = rewardEvents:WaitForChild("LevelUpEvent")
local RequestRewardSync= rewardEvents:WaitForChild("RequestRewardSync")

local function spawnPopup(kind, text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 200, 0, 40)
    lbl.Position = UDim2.new(0, math.random(-30, 30), 0, math.random(150, 250))
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = (kind == "bonus") and Enum.Font.GothamBlack or Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextColor3 = color or UIConfig.GAME_COLORS.HUDText
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = popupRoot

    if kind == "bonus" then
        lbl.Size = UDim2.new(0, 240, 0, 48)
    end

    local upTween = TweenService:Create(lbl, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = lbl.Position - UDim2.new(0, 0, 0, 90),
    })
    local fadeTween = TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    upTween:Play()
    task.delay(0.4, function() fadeTween:Play() end)
    task.delay(1.3, function() lbl:Destroy() end)
end

PopupEvent.OnClientEvent:Connect(spawnPopup)

ChefLevelUpdate.OnClientEvent:Connect(function(level, xp, xpNeeded, tierName, tierColor, tierBadge)
    badge.Text = tierBadge or "🌱"
    tierLabel.Text = (tierName or "Chef") .. " · Lv " .. level
    local frac = (xpNeeded > 0) and math.clamp(xp / xpNeeded, 0, 1) or 0
    TweenService:Create(xpFill, TweenInfo.new(0.4), { Size = UDim2.new(frac, 0, 1, 0) }):Play()
    if tierColor then
        xpFill.BackgroundColor3 = tierColor
        pill:FindFirstChildOfClass("UIStroke").Color = tierColor
    end
end)

local comboHideThread
ComboUpdate.OnClientEvent:Connect(function(count, multiplier)
    if count <= 0 then
        TweenService:Create(combo, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -110, 0, 60), BackgroundTransparency = 1 }):Play()
        for _, d in pairs(combo:GetDescendants()) do
            if d:IsA("TextLabel") then
                TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            end
        end
        task.delay(0.4, function() combo.Visible = false end)
        return
    end
    combo.Visible = true
    combo.BackgroundTransparency = 0
    combo.Position = UDim2.new(0.5, -110, 0, 80)
    for _, d in pairs(combo:GetDescendants()) do
        if d:IsA("TextLabel") then d.TextTransparency = 0 end
    end
    cCount.Text = count .. " COMBO"
    cMult.Text = "x" .. string.format("%.1f", multiplier)
    -- pulse on update
    local origSize = UDim2.new(0, 220, 0, 70)
    combo.Size = UDim2.new(0, 240, 0, 78)
    TweenService:Create(combo, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = origSize }):Play()
    if multiplier >= 3 then
        cMult.TextColor3 = UIConfig.GAME_COLORS.ComboFire
    elseif multiplier >= 2 then
        cMult.TextColor3 = UIConfig.GAME_COLORS.ComboWarm
    else
        cMult.TextColor3 = UIConfig.GAME_COLORS.CookingPerfect
    end
end)

LevelUpEvent.OnClientEvent:Connect(function(level, tierName, tierColor, tierBadge)
    -- Big level-up banner
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(0, 460, 0, 120)
    banner.Position = UDim2.new(0.5, -230, 0.3, -60)
    banner.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
    banner.BorderSizePixel = 0
    banner.Parent = gui
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
    local bs = Instance.new("UIStroke"); bs.Color = tierColor or UIConfig.GAME_COLORS.SparkleGold; bs.Thickness = 3; bs.Parent = banner

    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.45, 0)
    t1.Position = UDim2.new(0, 0, 0, 8)
    t1.BackgroundTransparency = 1
    t1.Text = "LEVEL UP!"
    t1.Font = Enum.Font.GothamBlack
    t1.TextScaled = true
    t1.TextColor3 = UIConfig.GAME_COLORS.SparkleGold
    t1.Parent = banner

    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.45, 0)
    t2.Position = UDim2.new(0, 0, 0.5, 0)
    t2.BackgroundTransparency = 1
    t2.Text = (tierBadge or "") .. " " .. (tierName or "Chef") .. " · Lv " .. level
    t2.Font = Enum.Font.GothamBold
    t2.TextScaled = true
    t2.TextColor3 = UIConfig.GAME_COLORS.HUDText
    t2.Parent = banner

    UIHelper.spawnSparkles(gui, banner.AbsolutePosition.X + 230, banner.AbsolutePosition.Y + 60,
        tierColor or UIConfig.GAME_COLORS.SparkleGold, 15)
    banner.Size = UDim2.new(0, 0, 0, 120)
    TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(0, 460, 0, 120) }):Play()
    task.delay(2.5, function()
        TweenService:Create(banner, TweenInfo.new(0.4), { Size = UDim2.new(0, 460, 0, 0) }):Play()
        task.wait(0.5)
        banner:Destroy()
    end)
end)

-- Initial sync
task.spawn(function()
    task.wait(1)
    local data = RequestRewardSync:InvokeServer()
    if data then
        badge.Text = data.tierBadge or "🌱"
        tierLabel.Text = (data.tierName or "Apprentice") .. " · Lv " .. data.level
        local frac = (data.xpNeeded > 0) and math.clamp(data.xp / data.xpNeeded, 0, 1) or 0
        xpFill.Size = UDim2.new(frac, 0, 1, 0)
        if data.tierColor then
            xpFill.BackgroundColor3 = data.tierColor
            pill:FindFirstChildOfClass("UIStroke").Color = data.tierColor
        end
    end
end)

-- ===== Extended handlers =====
local UserInputService = game:GetService("UserInputService")
local daily = gui:WaitForChild("DailyWidget")
local dTitle = daily:WaitForChild("Title")
local dDesc = daily:WaitForChild("Desc")
local dFill = daily:WaitForChild("Bar"):WaitForChild("Fill")

local DailyUpdate = rewardEvents:WaitForChild("DailyUpdate")
local LoginBonusEvent = rewardEvents:WaitForChild("LoginBonusEvent")
local AchievementUnlocked = rewardEvents:WaitForChild("AchievementUnlocked")
local PowerupUpdate = rewardEvents:WaitForChild("PowerupUpdate")
local UsePowerup = rewardEvents:WaitForChild("UsePowerup")
local UpgradeTool = rewardEvents:WaitForChild("UpgradeTool")
local GetCompendium = rewardEvents:WaitForChild("GetCompendium")

DailyUpdate.OnClientEvent:Connect(function(q, progress, claimed)
    if not q then return end
    dTitle.Text = "📋 " .. (claimed and "Daily ✓" or "Daily Quest")
    dDesc.Text = q.title .. "  " .. progress .. "/" .. q.goal
    local f = math.clamp(progress / q.goal, 0, 1)
    TweenService:Create(dFill, TweenInfo.new(0.3), { Size = UDim2.new(f, 0, 1, 0) }):Play()
    if claimed then
        dFill.BackgroundColor3 = UIConfig.COLORS.Success
    end
end)

LoginBonusEvent.OnClientEvent:Connect(function(streak, bonus, q)
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(0, 480, 0, 140)
    banner.Position = UDim2.new(0.5, -240, 0.3, -70)
    banner.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
    banner.BorderSizePixel = 0
    banner.Parent = gui
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
    local bs = Instance.new("UIStroke"); bs.Color = UIConfig.GAME_COLORS.SparkleGold; bs.Thickness = 3; bs.Parent = banner
    local lines = {
        ("🎁 Daily Login Bonus! +%d gold"):format(bonus),
        ("🔥 %d day streak"):format(streak),
        ("📋 Today's quest: %s"):format(q.title),
    }
    for i, txt in ipairs(lines) do
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -16, 0, 38)
        t.Position = UDim2.new(0, 8, 0, 6 + (i-1)*42)
        t.BackgroundTransparency = 1
        t.Text = txt
        t.Font = (i == 1) and Enum.Font.GothamBlack or Enum.Font.GothamBold
        t.TextScaled = true
        t.TextColor3 = (i == 1) and UIConfig.GAME_COLORS.SparkleGold or UIConfig.GAME_COLORS.HUDText
        t.Parent = banner
    end
    banner.Size = UDim2.new(0, 0, 0, 140)
    TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.new(0, 480, 0, 140) }):Play()
    task.delay(4.0, function()
        TweenService:Create(banner, TweenInfo.new(0.4), { Size = UDim2.new(0, 480, 0, 0) }):Play()
        task.wait(0.5); banner:Destroy()
    end)
end)

-- Achievement toast stack
local toastY = 0
AchievementUnlocked.OnClientEvent:Connect(function(name, desc, icon)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 340, 0, 70)
    toast.Position = UDim2.new(1, 360, 0, 200 + toastY)
    toast.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
    toast.BorderSizePixel = 0
    toast.Parent = gui
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 14); tc.Parent = toast
    local ts = Instance.new("UIStroke"); ts.Color = UIConfig.GAME_COLORS.SparkleGold; ts.Thickness = 2; ts.Parent = toast

    local ico = Instance.new("TextLabel")
    ico.Size = UDim2.new(0, 56, 0, 56); ico.Position = UDim2.new(0, 8, 0, 7); ico.BackgroundTransparency = 1
    ico.Text = icon or "🏆"; ico.Font = Enum.Font.GothamBlack; ico.TextScaled = true
    ico.TextColor3 = UIConfig.GAME_COLORS.SparkleGold; ico.Parent = toast

    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, -72, 0, 28); t1.Position = UDim2.new(0, 72, 0, 6); t1.BackgroundTransparency = 1
    t1.Text = "🏆 " .. name; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextXAlignment = Enum.TextXAlignment.Left; t1.TextColor3 = UIConfig.GAME_COLORS.SparkleGold; t1.Parent = toast

    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, -72, 0, 24); t2.Position = UDim2.new(0, 72, 0, 38); t2.BackgroundTransparency = 1
    t2.Text = desc; t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextXAlignment = Enum.TextXAlignment.Left; t2.TextColor3 = UIConfig.COLORS.TextDisabled; t2.Parent = toast

    local myOffset = toastY
    toastY = toastY + 80
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(1, -360, 0, 200 + myOffset) }):Play()
    task.delay(4.0, function()
        TweenService:Create(toast, TweenInfo.new(0.4), { Position = UDim2.new(1, 360, 0, 200 + myOffset) }):Play()
        task.wait(0.5); toast:Destroy(); toastY = math.max(0, toastY - 80)
    end)
end)

-- ===== Progress panel (press P) =====
local C = {
	bg = UIConfig.COLORS.PanelBg,
	text = UIConfig.COLORS.TextDark,
	sub = UIConfig.COLORS.TextDarkSec,
	accent = UIConfig.COLORS.PanelBorder,
	white = UIConfig.GAME_COLORS.HUDText,
	green = UIConfig.COLORS.Success,
	red = UIConfig.COLORS.Danger,
}

local progressPanel = Instance.new("Frame")
progressPanel.Name = "ProgressPanel"
progressPanel.Size = UDim2.new(0, 720, 0, 500)
progressPanel.Position = UDim2.new(0.5, -360, 0.5, -250)
progressPanel.BackgroundColor3 = C.bg
progressPanel.BorderSizePixel = 0
progressPanel.Visible = false
progressPanel.Parent = gui
local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0, 22); pCorner.Parent = progressPanel
local pStroke = Instance.new("UIStroke"); pStroke.Color = C.accent; pStroke.Thickness = 3; pStroke.Parent = progressPanel

local pTitle = Instance.new("TextLabel")
pTitle.Size = UDim2.new(1, 0, 0, 44); pTitle.BackgroundTransparency = 1
pTitle.Text = "📊  Chef Progress"; pTitle.Font = Enum.Font.FredokaOne; pTitle.TextSize = 28
pTitle.TextColor3 = C.text; pTitle.Parent = progressPanel

local pClose = Instance.new("TextButton")
pClose.Size = UDim2.new(0, 38, 0, 38); pClose.Position = UDim2.new(1, -46, 0, 6)
pClose.Text = "✕"; pClose.Font = Enum.Font.FredokaOne; pClose.TextSize = 16
pClose.BackgroundColor3 = C.red; pClose.TextColor3 = C.white
pClose.BorderSizePixel = 0; pClose.Parent = progressPanel
local pcCorner = Instance.new("UICorner"); pcCorner.CornerRadius = UDim.new(0, 10); pcCorner.Parent = pClose
pClose.MouseButton1Click:Connect(function() progressPanel.Visible = false end)

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -32, 0, 38); tabBar.Position = UDim2.new(0, 16, 0, 50)
tabBar.BackgroundTransparency = 1; tabBar.Parent = progressPanel
local tlay = Instance.new("UIListLayout"); tlay.FillDirection = Enum.FillDirection.Horizontal
tlay.Padding = UDim.new(0, 8); tlay.Parent = tabBar

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -32, 1, -110); content.Position = UDim2.new(0, 16, 0, 100)
content.BackgroundColor3 = C.bg; content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = C.accent; content.BorderSizePixel = 0
content.CanvasSize = UDim2.new(0, 0, 0, 800); content.Parent = progressPanel
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 14)
local clay = Instance.new("UIListLayout"); clay.SortOrder = Enum.SortOrder.LayoutOrder
clay.Padding = UDim.new(0, 6); clay.Parent = content

local currentTab = "achievements"
local function renderTab(name)
    currentTab = name
    for _, c in pairs(content:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local data = GetCompendium:InvokeServer()
    if name == "achievements" then
        for i, ach in ipairs(data.achievements) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 50); row.LayoutOrder = i
            local unlocked = data.unlocked[ach.id]
            row.BackgroundColor3 = unlocked and Color3.fromRGB(235, 250, 235) or C.bg
            row.Parent = content; row.BorderSizePixel = 0
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 10); rc.Parent = row
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -16, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
            l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextSize = 16
            l.Text = (unlocked and "✅ " or "🔒 ") .. ach.icon .. " " .. ach.name .. " — " .. ach.desc
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextColor3 = unlocked and C.green or C.sub
            l.Parent = row
        end
    elseif name == "mastery" then
        local i = 0
        for recipe, m in pairs(data.mastery or {}) do
            i = i + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 44); row.LayoutOrder = i
            row.BackgroundColor3 = C.bg; row.BorderSizePixel = 0
            row.Parent = content
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 10); rc.Parent = row
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -16, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
            l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextSize = 16
            l.Text = "📖 " .. recipe .. "  · Mastery " .. (m.level or 1) .. " (" .. (m.xp or 0) .. " xp)"
            l.TextXAlignment = Enum.TextXAlignment.Left; l.TextColor3 = C.text
            l.Parent = row
        end
        if i == 0 then
            local row = Instance.new("Frame"); row.Size = UDim2.new(1, -8, 0, 40); row.BackgroundTransparency = 1; row.Parent = content
            local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1
            l.Text = "Cook a recipe to start earning mastery!"; l.Font = Enum.Font.Gotham
            l.TextSize = 14; l.TextColor3 = C.sub; l.Parent = row
        end
    elseif name == "tools" then
        for j, toolKey in ipairs({"Axe","PickAxe","Sickle"}) do
            local tier = (data.toolTiers and data.toolTiers[toolKey]) or 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 64); row.LayoutOrder = j
            row.BackgroundColor3 = C.bg; row.BorderSizePixel = 0
            row.Parent = content
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 10); rc.Parent = row
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(0.7, -8, 1, 0); l.Position = UDim2.new(0, 8, 0, 0)
            l.BackgroundTransparency = 1; l.Font = Enum.Font.FredokaOne; l.TextSize = 16
            l.Text = "🔨 " .. toolKey .. "  · Tier " .. tier
            l.TextXAlignment = Enum.TextXAlignment.Left; l.TextColor3 = C.text
            l.Parent = row
            if tier < 3 then
                local cost = tier == 1 and 300 or 900
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.28, -8, 0, 44); btn.Position = UDim2.new(0.72, 0, 0.5, -22)
                btn.Text = "Upgrade  " .. cost .. "g"; btn.Font = Enum.Font.FredokaOne; btn.TextSize = 14
                btn.BackgroundColor3 = C.accent; btn.TextColor3 = C.white; btn.BorderSizePixel = 0
                btn.Parent = row
                local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    local ok, msg = UpgradeTool:InvokeServer(toolKey)
                    if not ok then
                        spawnPopup("bonus", msg, UIConfig.COLORS.Danger)
                    end
                    renderTab(currentTab)
                end)
            end
        end
    elseif name == "powerups" then
        local j = 0
        for key, cfg in pairs(data.powerupConfig) do
            j = j + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 74); row.LayoutOrder = j
            row.BackgroundColor3 = C.bg; row.BorderSizePixel = 0
            row.Parent = content
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 10); rc.Parent = row
            local active = data.powerups[key] and data.powerups[key] > os.time()
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, -8, 1, 0); label.Position = UDim2.new(0, 8, 0, 0)
            label.BackgroundTransparency = 1; label.Font = Enum.Font.FredokaOne; label.TextSize = 14
            label.Text = cfg.icon .. " " .. cfg.name .. "  " .. (active and "(ACTIVE)" or "")
                .. "\n" .. cfg.desc
            label.TextXAlignment = Enum.TextXAlignment.Left; label.TextColor3 = active and C.green or C.text
            label.TextWrapped = true; label.Parent = row
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.28, -8, 0, 50); btn.Position = UDim2.new(0.72, 0, 0.5, -25)
            btn.Text = "Use  " .. (cfg.cost.gold or "?") .. "g"; btn.Font = Enum.Font.FredokaOne; btn.TextSize = 14
            btn.BackgroundColor3 = active and C.sub or C.accent
            btn.TextColor3 = C.white; btn.BorderSizePixel = 0; btn.Parent = row
            btn.AutoButtonColor = not active
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn
            if not active then
                btn.MouseButton1Click:Connect(function()
                    local ok, msg = UsePowerup:InvokeServer(key)
                    if not ok then
                        spawnPopup("bonus", tostring(msg), UIConfig.COLORS.Danger)
                    end
                    renderTab(currentTab)
                end)
            end
        end
    end
end

local function addTab(label, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 1, 0)
    btn.Text = label; btn.Font = Enum.Font.FredokaOne; btn.TextSize = 14
    btn.BackgroundColor3 = C.accent; btn.TextColor3 = C.white
    btn.BorderSizePixel = 0; btn.Parent = tabBar
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 10); bc.Parent = btn
    btn.MouseButton1Click:Connect(function() renderTab(key) end)
end
addTab("🏆 Achievements", "achievements")
addTab("📖 Mastery", "mastery")
addTab("🔨 Tools", "tools")
addTab("✨ Power-ups", "powerups")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        progressPanel.Visible = not progressPanel.Visible
        if progressPanel.Visible then renderTab(currentTab) end
    end
end)
