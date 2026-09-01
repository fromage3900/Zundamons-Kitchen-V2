--!strict
-- CookingResultCard: Rich cooking minigame result summary popup.
-- Displays letter grade (S/A/B/C/F), accuracy %, max combo, total score,
-- dish quantity, gold bonus, style points, chef stat XP, and note judgment breakdown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)

local PALETTE = {
	BG_DARK = Color3.fromRGB(22, 18, 32),
	PANEL_BORDER = Color3.fromRGB(255, 220, 160),
	TEXT_LIGHT = Color3.fromRGB(250, 248, 255),
	TEXT_MUTED = Color3.fromRGB(190, 185, 210),
	GRADE_S = Color3.fromRGB(255, 215, 80),
	GRADE_A = Color3.fromRGB(140, 235, 150),
	GRADE_B = Color3.fromRGB(130, 200, 255),
	GRADE_C = Color3.fromRGB(255, 180, 130),
	GRADE_F = Color3.fromRGB(255, 110, 130),
	GOLD_ACCENT = Color3.fromRGB(255, 200, 80),
	ZUNDA_GREEN = Color3.fromRGB(160, 210, 150),
	PINK_ACCENT = Color3.fromRGB(255, 150, 200),
	MINT_ACCENT = Color3.fromRGB(145, 215, 195),
}

local GRADE_COLORS: { [string]: Color3 } = {
	S = PALETTE.GRADE_S,
	A = PALETTE.GRADE_A,
	B = PALETTE.GRADE_B,
	C = PALETTE.GRADE_C,
	F = PALETTE.GRADE_F,
}

local gui = ClientGuiBootstrap.createScreenGui(player, "CookingResultCardGui", 96)
gui.ResetOnSpawn = false
gui.DisplayOrder = 96
gui.Enabled = false

-- Backdrop Dimmer
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(5, 4, 10)
backdrop.BackgroundTransparency = 0.55
backdrop.Text = ""
backdrop.BorderSizePixel = 0
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.Parent = gui

-- Centered Result Card Frame
local card = Instance.new("Frame")
card.Name = "ResultCard"
card.Size = UDim2.fromOffset(460, 380)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.new(0.5, 0, 0.5, 0)
card.BackgroundColor3 = PALETTE.BG_DARK
card.BackgroundTransparency = 0.1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 20)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = PALETTE.PANEL_BORDER
cardStroke.Thickness = 3
cardStroke.Transparency = 0.2
cardStroke.Parent = card

-- Dynamic UIScale for cross-platform responsiveness
local cardScale = Instance.new("UIScale")
cardScale.Name = "CardScale"
cardScale.Scale = 1
cardScale.Parent = card

local function updateResultScale()
	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local viewW = viewportSize.X
	local viewH = viewportSize.Y
	if viewW <= 0 or viewH <= 0 then
		return
	end
	local scaleH = (viewH * 0.90) / 380
	local scaleW = (viewW * 0.90) / 460
	local fitScale = math.min(scaleH, scaleW)
	cardScale.Scale = math.clamp(fitScale, 0.55, 1.25)
end

updateResultScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResultScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResultScale)
		updateResultScale()
	end
end)

-- Header: Dish Name & Quality Banner
local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "HeaderLabel"
headerLabel.Size = UDim2.new(1, -30, 0, 28)
headerLabel.Position = UDim2.new(0, 15, 0, 14)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "🍳 Dish Cooking Summary"
headerLabel.TextColor3 = PALETTE.TEXT_LIGHT
headerLabel.Font = Enum.Font.GothamBlack
headerLabel.TextSize = 20
headerLabel.TextXAlignment = Enum.TextXAlignment.Center
headerLabel.Parent = card

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(1, -30, 0, 20)
subtitleLabel.Position = UDim2.new(0, 15, 0, 42)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "✨ PERFECT COOK!! ✨"
subtitleLabel.TextColor3 = PALETTE.GRADE_S
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextSize = 14
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.Parent = card

-- Main Performance Section: Grade Badge + Metrics Grid
local performanceFrame = Instance.new("Frame")
performanceFrame.Name = "PerformanceFrame"
performanceFrame.Size = UDim2.new(1, -30, 0, 96)
performanceFrame.Position = UDim2.new(0, 15, 0, 68)
performanceFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 44)
performanceFrame.BackgroundTransparency = 0.5
performanceFrame.BorderSizePixel = 0
performanceFrame.Parent = card

local perfCorner = Instance.new("UICorner")
perfCorner.CornerRadius = UDim.new(0, 12)
perfCorner.Parent = performanceFrame

-- Letter Grade Badge (Left)
local gradeBadge = Instance.new("Frame")
gradeBadge.Name = "GradeBadge"
gradeBadge.Size = UDim2.fromOffset(80, 80)
gradeBadge.Position = UDim2.new(0, 10, 0.5, -40)
gradeBadge.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
gradeBadge.BorderSizePixel = 0
gradeBadge.Parent = performanceFrame

local gbCorner = Instance.new("UICorner")
gbCorner.CornerRadius = UDim.new(1, 0)
gbCorner.Parent = gradeBadge

local gbStroke = Instance.new("UIStroke")
gbStroke.Color = PALETTE.GRADE_S
gbStroke.Thickness = 3.5
gbStroke.Parent = gradeBadge

local gradeText = Instance.new("TextLabel")
gradeText.Name = "GradeText"
gradeText.Size = UDim2.new(1, 0, 1, 0)
gradeText.BackgroundTransparency = 1
gradeText.Text = "S"
gradeText.TextColor3 = PALETTE.GRADE_S
gradeText.Font = Enum.Font.FredokaOne
gradeText.TextSize = 44
gradeText.Parent = gradeBadge

-- Performance Metrics (Right)
local metricsFrame = Instance.new("Frame")
metricsFrame.Name = "MetricsFrame"
metricsFrame.Size = UDim2.new(1, -110, 1, -12)
metricsFrame.Position = UDim2.new(0, 100, 0, 6)
metricsFrame.BackgroundTransparency = 1
metricsFrame.Parent = performanceFrame

local accuracyText = Instance.new("TextLabel")
accuracyText.Name = "AccuracyText"
accuracyText.Size = UDim2.new(1, 0, 0, 26)
accuracyText.Position = UDim2.new(0, 0, 0, 2)
accuracyText.BackgroundTransparency = 1
accuracyText.Text = "Accuracy: 100.0%"
accuracyText.TextColor3 = PALETTE.TEXT_LIGHT
accuracyText.Font = Enum.Font.GothamBold
accuracyText.TextSize = 16
accuracyText.TextXAlignment = Enum.TextXAlignment.Left
accuracyText.Parent = metricsFrame

local comboText = Instance.new("TextLabel")
comboText.Name = "ComboText"
comboText.Size = UDim2.new(1, 0, 0, 24)
comboText.Position = UDim2.new(0, 0, 0, 28)
comboText.BackgroundTransparency = 1
comboText.Text = "Max Combo: 10x"
comboText.TextColor3 = PALETTE.GOLD_ACCENT
comboText.Font = Enum.Font.GothamMedium
comboText.TextSize = 14
comboText.TextXAlignment = Enum.TextXAlignment.Left
comboText.Parent = metricsFrame

local scoreText = Instance.new("TextLabel")
scoreText.Name = "ScoreText"
scoreText.Size = UDim2.new(1, 0, 0, 24)
scoreText.Position = UDim2.new(0, 0, 0, 52)
scoreText.BackgroundTransparency = 1
scoreText.Text = "Total Score: 12,000 pts"
scoreText.TextColor3 = PALETTE.MINT_ACCENT
scoreText.Font = Enum.Font.GothamMedium
scoreText.TextSize = 14
scoreText.TextXAlignment = Enum.TextXAlignment.Left
scoreText.Parent = metricsFrame

-- Note Breakdown Pill
local breakdownPill = Instance.new("Frame")
breakdownPill.Name = "BreakdownPill"
breakdownPill.Size = UDim2.new(1, -30, 0, 30)
breakdownPill.Position = UDim2.new(0, 15, 0, 172)
breakdownPill.BackgroundColor3 = Color3.fromRGB(26, 22, 38)
breakdownPill.BorderSizePixel = 0
breakdownPill.Parent = card

local bpCorner = Instance.new("UICorner")
bpCorner.CornerRadius = UDim.new(0, 8)
bpCorner.Parent = breakdownPill

local breakdownText = Instance.new("TextLabel")
breakdownText.Name = "BreakdownText"
breakdownText.Size = UDim2.new(1, -12, 1, 0)
breakdownText.Position = UDim2.new(0, 6, 0, 0)
breakdownText.BackgroundTransparency = 1
breakdownText.Text = "✦ Perfect: 8  |  ❀ Great: 2  |  🌱 Good: 0  |  💧 Miss: 0"
breakdownText.TextColor3 = PALETTE.TEXT_MUTED
breakdownText.Font = Enum.Font.GothamMedium
breakdownText.TextSize = 12
breakdownText.TextXAlignment = Enum.TextXAlignment.Center
breakdownText.Parent = breakdownPill

-- Rewards & Progression Section
local rewardsFrame = Instance.new("Frame")
rewardsFrame.Name = "RewardsFrame"
rewardsFrame.Size = UDim2.new(1, -30, 0, 84)
rewardsFrame.Position = UDim2.new(0, 15, 0, 210)
rewardsFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 44)
rewardsFrame.BackgroundTransparency = 0.5
rewardsFrame.BorderSizePixel = 0
rewardsFrame.Parent = card

local rewCorner = Instance.new("UICorner")
rewCorner.CornerRadius = UDim.new(0, 12)
rewCorner.Parent = rewardsFrame

local dishRewardText = Instance.new("TextLabel")
dishRewardText.Name = "DishRewardText"
dishRewardText.Size = UDim2.new(0.5, -10, 0, 24)
dishRewardText.Position = UDim2.new(0, 12, 0, 8)
dishRewardText.BackgroundTransparency = 1
dishRewardText.Text = "🍲 Dish: +1x Zunda Mochi"
dishRewardText.TextColor3 = PALETTE.ZUNDA_GREEN
dishRewardText.Font = Enum.Font.GothamBold
dishRewardText.TextSize = 13
dishRewardText.TextXAlignment = Enum.TextXAlignment.Left
dishRewardText.Parent = rewardsFrame

local goldRewardText = Instance.new("TextLabel")
goldRewardText.Name = "GoldRewardText"
goldRewardText.Size = UDim2.new(0.5, -10, 0, 24)
goldRewardText.Position = UDim2.new(0.5, 5, 0, 8)
goldRewardText.BackgroundTransparency = 1
goldRewardText.Text = "💰 Gold: +25 Gold"
goldRewardText.TextColor3 = PALETTE.GOLD_ACCENT
goldRewardText.Font = Enum.Font.GothamBold
goldRewardText.TextSize = 13
goldRewardText.TextXAlignment = Enum.TextXAlignment.Left
goldRewardText.Parent = rewardsFrame

local styleRewardText = Instance.new("TextLabel")
styleRewardText.Name = "StyleRewardText"
styleRewardText.Size = UDim2.new(0.5, -10, 0, 24)
styleRewardText.Position = UDim2.new(0, 12, 0, 32)
styleRewardText.BackgroundTransparency = 1
styleRewardText.Text = "✨ Style: +100 Style Pts"
styleRewardText.TextColor3 = PALETTE.PINK_ACCENT
styleRewardText.Font = Enum.Font.GothamBold
styleRewardText.TextSize = 13
styleRewardText.TextXAlignment = Enum.TextXAlignment.Left
styleRewardText.Parent = rewardsFrame

local xpRewardText = Instance.new("TextLabel")
xpRewardText.Name = "XpRewardText"
xpRewardText.Size = UDim2.new(0.5, -10, 0, 24)
xpRewardText.Position = UDim2.new(0.5, 5, 0, 32)
xpRewardText.BackgroundTransparency = 1
xpRewardText.Text = "🎓 Chef XP: +12 Prec / +8 Spd"
xpRewardText.TextColor3 = PALETTE.MINT_ACCENT
xpRewardText.Font = Enum.Font.GothamBold
xpRewardText.TextSize = 13
xpRewardText.TextXAlignment = Enum.TextXAlignment.Left
xpRewardText.Parent = rewardsFrame

local streakFooterText = Instance.new("TextLabel")
streakFooterText.Name = "StreakFooterText"
streakFooterText.Size = UDim2.new(1, -24, 0, 20)
streakFooterText.Position = UDim2.new(0, 12, 0, 58)
streakFooterText.BackgroundTransparency = 1
streakFooterText.Text = "🔥 Cooking Streak Active!"
streakFooterText.TextColor3 = PALETTE.GOLD_ACCENT
streakFooterText.Font = Enum.Font.GothamMedium
streakFooterText.TextSize = 12
streakFooterText.TextXAlignment = Enum.TextXAlignment.Center
streakFooterText.Parent = rewardsFrame

-- Dismiss Button
local dismissBtn = Instance.new("TextButton")
dismissBtn.Name = "DismissBtn"
dismissBtn.Size = UDim2.new(0, 180, 0, 42)
dismissBtn.Position = UDim2.new(0.5, -90, 1, -54)
dismissBtn.BackgroundColor3 = PALETTE.ZUNDA_GREEN
dismissBtn.Text = "✨ OK! ✨"
dismissBtn.TextColor3 = Color3.fromRGB(20, 15, 25)
dismissBtn.Font = Enum.Font.GothamBlack
dismissBtn.TextSize = 16
dismissBtn.BorderSizePixel = 0
dismissBtn.AutoButtonColor = true
dismissBtn.Parent = card

local dCorner = Instance.new("UICorner")
dCorner.CornerRadius = UDim.new(0, 12)
dCorner.Parent = dismissBtn

local dStroke = Instance.new("UIStroke")
dStroke.Color = Color3.fromRGB(255, 255, 255)
dStroke.Thickness = 2
dStroke.Transparency = 0.3
dStroke.Parent = dismissBtn

local function dismissCard()
	if _G.ZundaSoundController and _G.ZundaSoundController.play then
		_G.ZundaSoundController.play("Button_Click")
	end

	TweenService
		:Create(
			card,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)
		:Play()
	TweenService:Create(
		backdrop,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ BackgroundTransparency = 1 }
	):Play()

	task.delay(0.2, function()
		gui.Enabled = false
		card.Visible = false
		backdrop.Visible = false
	end)
end

dismissBtn.MouseButton1Click:Connect(dismissCard)
backdrop.MouseButton1Click:Connect(dismissCard)

-- Remote Event Listener for Server CookingResult
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local cookResultEv = remotes:WaitForChild("CookingResult") :: RemoteEvent

cookResultEv.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	-- Advance tutorial past cook step
	local ta = ReplicatedStorage:FindFirstChild("TutorialAdvance")
	if ta then
		(ta :: any):Fire("cook")
	end

	local recipe = data.recipe or "Dish"
	local quality = data.quality or "ok"
	local grade = data.grade or "A"
	local accuracy = tonumber(data.accuracy) or 0
	local maxCombo = tonumber(data.maxCombo) or 0
	local score = tonumber(data.score) or 0
	local bonusGold = tonumber(data.bonusGold) or 0
	local dishCount = tonumber(data.dishCount) or 1
	local stylePoints = tonumber(data.stylePoints) or 0
	local counts = data.counts or {}
	local statXP = data.statXP or {}

	-- Format Header
	headerLabel.Text = string.format("🍳 %s", recipe)

	local gradeColor = GRADE_COLORS[string.upper(grade)] or PALETTE.GRADE_A
	gradeText.Text = string.upper(grade)
	gradeText.TextColor3 = gradeColor
	gbStroke.Color = gradeColor

	if quality == "perfect" then
		subtitleLabel.Text = "✨ PERFECT COOK!! JUST LIKE MAGIC! ✨"
		subtitleLabel.TextColor3 = PALETTE.GRADE_S
	elseif quality == "great" then
		subtitleLabel.Text = "🍡 GREAT COOK! TASTY & DELICIOUS! 🍡"
		subtitleLabel.TextColor3 = PALETTE.GRADE_A
	elseif quality == "failed" then
		subtitleLabel.Text = "💧 COOKING FAILED — TRY AGAIN! 💧"
		subtitleLabel.TextColor3 = PALETTE.GRADE_F
	else
		subtitleLabel.Text = "🌸 COOKING FINISHED! 🌸"
		subtitleLabel.TextColor3 = PALETTE.PINK_ACCENT
	end

	-- Format Metrics
	accuracyText.Text = string.format("Accuracy: %.1f%%", accuracy)
	comboText.Text = string.format("Max Combo: %dx COMBO", maxCombo)
	scoreText.Text = string.format(
		"Total Score: %s pts",
		string.format("%d", score):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	)

	-- Format Counts Breakdown
	local pHits = counts.perfect or counts.PERFECT or 0
	local grHits = counts.great or counts.GREAT or 0
	local gdHits = counts.good or counts.GOOD or counts.ok or counts.OK or 0
	local mHits = counts.miss or counts.MISS or 0
	breakdownText.Text = string.format(
		"✦ Perfect: %d  |  ❀ Great: %d  |  🌱 Good: %d  |  💧 Miss: %d",
		pHits,
		grHits,
		gdHits,
		mHits
	)

	-- Format Rewards
	dishRewardText.Text = string.format("🍲 Dish: +%dx %s", dishCount, recipe)
	goldRewardText.Text = string.format("💰 Gold: +%d Gold", bonusGold)
	styleRewardText.Text = string.format("✨ Style: +%d Style Pts", stylePoints)

	local precXP = statXP.precision or 0
	local spdXP = statXP.speed or 0
	if precXP > 0 or spdXP > 0 then
		xpRewardText.Text = string.format("🎓 Chef XP: +%d Prec / +%d Spd", precXP, spdXP)
	else
		xpRewardText.Text = string.format("🎓 Chef XP: +%d XP", quality == "perfect" and 30 or 15)
	end

	local streak = (_G.data and _G.data.cooking_streak) or 0
	if streak > 1 then
		streakFooterText.Text = string.format("🔥 %d Cooking Streak! Keep it going!", streak)
		streakFooterText.Visible = true
	else
		local served = (_G.data and _G.data.recipes_served_count and _G.data.recipes_served_count[recipe]) or 0
		local mastery = math.min(math.floor(served / 10 * 100), 100)
		streakFooterText.Text = string.format("🌟 Recipe Mastery: %d%%", mastery)
		streakFooterText.Visible = true
	end

	updateResultScale()

	-- Show Popup with Pop-In Tween
	gui.Enabled = true
	backdrop.Visible = true
	card.Visible = true
	backdrop.BackgroundTransparency = 1
	card.BackgroundTransparency = 1

	TweenService:Create(
		backdrop,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.55 }
	):Play()

	card.BackgroundTransparency = 0.1
	if cardScale then
		cardScale.Scale = 0.3
		TweenService
			:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 })
			:Play()
	end

	-- Audio celebration cue
	if _G.ZundaSoundController and _G.ZundaSoundController.play then
		if grade == "S" or quality == "perfect" then
			_G.ZundaSoundController.play("level_up")
			_G.ZundaSoundController.playVoice("cook_rank_s")
		elseif grade == "A" or quality == "great" then
			_G.ZundaSoundController.play("Bubbles")
		end
	end
end)

print("[CookingResultCard] Loaded — rich result summary popup ready ✓")
