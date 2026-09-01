--!strict
-- CookingController: Client-side rhythm cooking minigame controller.
-- Features:
--   - Decoupled UI creation using ClientGuiBootstrap (DisplayOrder = 100, ResetOnSpawn = false, mainPanel.Visible = false on startup).
--   - Glassmorphic multi-lane rhythm UI supporting 4 culinary action lanes: CHOP 🔪 (#A0D296), STIR 🥣 (#FFC850), SIMMER 🔥 (#FF96C8), SEASON 🧂 (#91D7C3).
--   - Frame-independent note animation using workspace:GetServerTimeNow() moving downward across lanes towards glowing judgment receptors.
--   - Animated judgment banners ("PERFECT!! ✨", "GREAT! 🍡", "GOOD! 🌸", "MISS... 💧") styled with Infinity Nikki pastel palette and bounce tweens.
--   - Note-hit burst particle effects (sparkles ✦, ✨, ❀, 🌱, ♡ and expanding ripple rings).
--   - Dynamic combo streak tracker with pulsing animations, color shifts, and fire/sparkle auras at high combos (10x, 20x).
--   - Dynamic audio cue triggering via ZundaSoundController (SFX CookingPerfect/Bubbles/CookingMiss and Zundamon VOICEVOX cues with single-channel barge-in and cooldown protection).
--   - Backward-compatible _G.TimedCooking and _G.CookingController interface.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)
local RhythmBeatmapConfig = require(ReplicatedStorage.ConfigurationFiles.RhythmBeatmapConfig)
local RhythmEngine = require(ReplicatedStorage.Rhythm.RhythmEngine)

-- Ensure RemoteEvents folder & CookingHit RemoteEvent exist
local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "RemoteEvents"
	remotes.Parent = ReplicatedStorage
end

local cookingHitEvent = remotes:FindFirstChild("CookingHit") :: RemoteEvent?
if not cookingHitEvent then
	local newEv = Instance.new("RemoteEvent")
	newEv.Name = "CookingHit"
	newEv.Parent = remotes
	cookingHitEvent = newEv
end

-- ── Visual & Timing Constants ────────────────────────────────────────────────
local FALL_DURATION = 1.8 -- Time in seconds for a note to fall from top to target line
local TARGET_Y_RATIO = 0.82 -- Fractional position of hit line within track frame (0..1)

local PALETTE = {
	ZUNDA_GREEN = Color3.fromRGB(160, 210, 150), -- #A0D296 (Chop)
	GOLD = Color3.fromRGB(255, 200, 80), -- #FFC850 (Stir)
	PINK = Color3.fromRGB(255, 150, 200), -- #FF96C8 (Simmer)
	MINT = Color3.fromRGB(145, 215, 195), -- #91D7C3 (Season)
	BG_DARK = Color3.fromRGB(22, 18, 32), -- Glassmorphic dark purple-gray
	BG_TRACK = Color3.fromRGB(14, 12, 22), -- Deep track background
	PANEL_BORDER = Color3.fromRGB(255, 220, 160), -- Soft warm pastel gold
	TEXT_LIGHT = Color3.fromRGB(250, 248, 255),
	TEXT_MUTED = Color3.fromRGB(190, 185, 210),
	PERFECT = Color3.fromRGB(255, 225, 90),
	GREAT = Color3.fromRGB(140, 235, 150),
	GOOD = Color3.fromRGB(255, 160, 210),
	MISS = Color3.fromRGB(255, 100, 120),
}

local LANE_DATA = {
	[1] = {
		id = 1,
		name = "CHOP",
		icon = "🔪",
		key = "D",
		keyCode = Enum.KeyCode.D,
		color = PALETTE.ZUNDA_GREEN,
		glow = Color3.fromRGB(190, 240, 180),
	},
	[2] = {
		id = 2,
		name = "STIR",
		icon = "🥣",
		key = "F",
		keyCode = Enum.KeyCode.F,
		color = PALETTE.GOLD,
		glow = Color3.fromRGB(255, 225, 130),
	},
	[3] = {
		id = 3,
		name = "SIMMER",
		icon = "🔥",
		key = "J",
		keyCode = Enum.KeyCode.J,
		color = PALETTE.PINK,
		glow = Color3.fromRGB(255, 185, 225),
	},
	[4] = {
		id = 4,
		name = "SEASON",
		icon = "🧂",
		key = "K",
		keyCode = Enum.KeyCode.K,
		color = PALETTE.MINT,
		glow = Color3.fromRGB(180, 245, 230),
	},
}

local BURST_PARTICLES = { "✦", "✨", "❀", "🌱", "♡", "🍡", "🌸", "⭐" }

-- ── Types ────────────────────────────────────────────────────────────────────
type ActiveNote = {
	noteIndex: number,
	laneId: number,
	targetTime: number,
	spawnTime: number,
	action: string,
	icon: string,
	hit: boolean,
	missed: boolean,
	instance: Frame?,
}

type CookingScoreState = {
	perfect: number,
	great: number,
	good: number,
	miss: number,
	totalScore: number,
}

-- ── Controller State ─────────────────────────────────────────────────────────
local CookingController = {}
local activeSession = false
local currentSessionId: string? = nil
local currentRecipeName = "Dish"
local activeNotes: { ActiveNote } = {}
local scoreState: CookingScoreState = { perfect = 0, great = 0, good = 0, miss = 0, totalScore = 0 }
local comboCount = 0
local maxComboCount = 0

local currentWindows = {
	hitWindow = RhythmEngine.BASE_WINDOWS.PERFECT,
	greatWindow = RhythmEngine.BASE_WINDOWS.GREAT,
	okWindow = RhythmEngine.BASE_WINDOWS.GOOD,
}

-- UI references
local screenGui: ScreenGui? = nil
local mainPanel: Frame? = nil
local trackFrame: Frame? = nil
local laneColumns: { [number]: Frame } = {}
local laneReceptors: { [number]: Frame } = {}
local comboLabel: TextLabel? = nil
local comboMultiplierLabel: TextLabel? = nil
local comboAuraLabel: TextLabel? = nil
local recipeLabel: TextLabel? = nil
local scoreLabel: TextLabel? = nil
local accuracyLabel: TextLabel? = nil
local progressBarFill: Frame? = nil
local judgmentContainer: Frame? = nil
local effectsContainer: Frame? = nil
local mobileTapButtons: { [number]: TextButton } = {}
local panelScale: UIScale? = nil
local currentTargetScale = 1.0
local handleLaneHit: (targetLaneId: number?) -> ()

-- ── UI Helper: Viewport Scale Calculation ────────────────────────────────────
local function updateCookingScale()
	if not mainPanel then
		return
	end
	if not panelScale then
		panelScale = mainPanel:FindFirstChildOfClass("UIScale")
		if not panelScale then
			panelScale = Instance.new("UIScale")
			panelScale.Name = "CookingScale"
			panelScale.Parent = mainPanel
		end
	end

	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local viewW = viewportSize.X
	local viewH = viewportSize.Y

	if viewW <= 0 or viewH <= 0 then
		return
	end

	-- Minigame panel footprint: 480 x 360 px
	-- Ensures panel never overflows viewport margins across mobile, tablet, and desktop
	local scaleH = (viewH * 0.85) / 360
	local scaleW = (viewW * 0.90) / 480
	local fitScale = math.min(scaleH, scaleW)
	currentTargetScale = math.clamp(fitScale, 0.55, 1.30)

	if panelScale and (not activeSession or panelScale.Scale > 0.3) then
		panelScale.Scale = currentTargetScale
	end
end

-- ── UI Helper: Spawn Particle Burst ──────────────────────────────────────────
local function spawnHitBurst(laneId: number, hitColor: Color3, parent: Instance)
	local laneCol = laneColumns[laneId]
	if not laneCol or not parent then
		return
	end

	local colAbsPos = laneCol.AbsolutePosition
	local colAbsSize = laneCol.AbsoluteSize
	local parentAbsPos = (parent :: GuiObject).AbsolutePosition

	local centerX = (colAbsPos.X - parentAbsPos.X) + (colAbsSize.X * 0.5)
	local centerY = (colAbsPos.Y - parentAbsPos.Y) + (colAbsSize.Y * TARGET_Y_RATIO)

	-- 1. Expanding Ripple Ring
	local ripple = Instance.new("Frame")
	ripple.Name = "RippleRing"
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.fromOffset(centerX, centerY)
	ripple.Size = UDim2.fromOffset(24, 24)
	ripple.BackgroundColor3 = hitColor
	ripple.BackgroundTransparency = 0.25
	ripple.BorderSizePixel = 0
	ripple.ZIndex = 25
	ripple.Parent = parent

	local rippleCorner = Instance.new("UICorner")
	rippleCorner.CornerRadius = UDim.new(1, 0)
	rippleCorner.Parent = ripple

	local rippleStroke = Instance.new("UIStroke")
	rippleStroke.Color = Color3.fromRGB(255, 255, 255)
	rippleStroke.Thickness = 3
	rippleStroke.Transparency = 0.2
	rippleStroke.Parent = ripple

	local rippleTween = TweenService:Create(
		ripple,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(90, 90), BackgroundTransparency = 1 }
	)
	local strokeTween = TweenService:Create(
		rippleStroke,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1, Thickness = 0.5 }
	)
	rippleTween:Play()
	strokeTween:Play()
	rippleTween.Completed:Connect(function()
		ripple:Destroy()
	end)

	-- 2. Floating Star/Sparkle Particles (✦, ✨, ❀, 🌱, ♡)
	local particleCount = math.random(5, 7)
	for i = 1, particleCount do
		local glyph = BURST_PARTICLES[math.random(1, #BURST_PARTICLES)]
		local pLabel = Instance.new("TextLabel")
		pLabel.Name = "BurstParticle"
		pLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		pLabel.Position = UDim2.fromOffset(centerX, centerY)
		pLabel.Size = UDim2.fromOffset(24, 24)
		pLabel.BackgroundTransparency = 1
		pLabel.Text = glyph
		pLabel.TextColor3 = hitColor
		pLabel.Font = Enum.Font.GothamBlack
		pLabel.TextSize = math.random(16, 24)
		pLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		pLabel.TextStrokeTransparency = 0.4
		pLabel.ZIndex = 26
		pLabel.Rotation = math.random(-30, 30)
		pLabel.Parent = parent

		local angle = (i / particleCount) * (math.pi * 2) + math.rad(math.random(-25, 25))
		local dist = math.random(32, 60)
		local targetX = centerX + math.cos(angle) * dist
		local targetY = centerY + math.sin(angle) * dist

		local pTween =
			TweenService:Create(pLabel, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(targetX, targetY),
				Rotation = pLabel.Rotation + math.random(-90, 90),
				TextTransparency = 1,
				TextStrokeTransparency = 1,
				Size = UDim2.fromOffset(30, 30),
			})
		pTween:Play()
		pTween.Completed:Connect(function()
			pLabel:Destroy()
		end)
	end

	-- 3. Receptor Glow Flash
	local receptor = laneReceptors[laneId]
	if receptor then
		local origSize = UDim2.fromOffset(48, 48)
		receptor.Size = UDim2.fromOffset(58, 58)
		receptor.BackgroundColor3 = hitColor
		local flashTween = TweenService:Create(
			receptor,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = origSize, BackgroundColor3 = PALETTE.BG_DARK }
		)
		flashTween:Play()
	end
end

-- ── UI Helper: Spawn Judgment Banner ─────────────────────────────────────────
local function spawnJudgmentBanner(judgment: string, laneId: number?, parent: Instance)
	if not parent then
		return
	end

	local text = "PERFECT!! ✨"
	local textColor = PALETTE.PERFECT
	local strokeColor = Color3.fromRGB(180, 140, 20)

	if judgment == "great" then
		text = "GREAT! 🍡"
		textColor = PALETTE.GREAT
		strokeColor = Color3.fromRGB(30, 120, 50)
	elseif judgment == "good" or judgment == "ok" then
		text = "GOOD! 🌸"
		textColor = PALETTE.GOOD
		strokeColor = Color3.fromRGB(160, 40, 90)
	elseif judgment == "miss" then
		text = "MISS... 💧"
		textColor = PALETTE.MISS
		strokeColor = Color3.fromRGB(140, 20, 30)
	end

	local banner = Instance.new("TextLabel")
	banner.Name = "JudgmentBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Center horizontally across parent or over specific lane
	if laneId and laneColumns[laneId] then
		local col = laneColumns[laneId]
		local colPos = col.AbsolutePosition
		local parentPos = (parent :: GuiObject).AbsolutePosition
		local posX = (colPos.X - parentPos.X) + (col.AbsoluteSize.X * 0.5)
		banner.Position = UDim2.new(0, posX, 0.52, 0)
	else
		banner.Position = UDim2.new(0.5, 0, 0.52, 0)
	end

	banner.Size = UDim2.fromOffset(220, 42)
	banner.BackgroundTransparency = 1
	banner.Text = text
	banner.TextColor3 = textColor
	banner.Font = Enum.Font.GothamBlack
	banner.TextSize = 28
	banner.TextStrokeColor3 = strokeColor
	banner.TextStrokeTransparency = 0.2
	banner.ZIndex = 30
	banner.Rotation = math.random(-4, 4)
	banner.Parent = parent

	-- Scale bounce in then float up and fade
	banner.Size = UDim2.fromOffset(120, 24)
	banner.TextTransparency = 0.3

	local popIn = TweenService:Create(
		banner,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(230, 44), TextTransparency = 0 }
	)
	popIn:Play()

	task.delay(0.2, function()
		if banner and banner.Parent then
			local fadeOut =
				TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(
						banner.Position.X.Scale,
						banner.Position.X.Offset,
						banner.Position.Y.Scale - 0.12,
						0
					),
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				banner:Destroy()
			end)
		end
	end)
end

-- ── UI Helper: Update Combo Tracker & Aura ───────────────────────────────────
local function updateComboUI()
	if not comboLabel or not comboMultiplierLabel or not comboAuraLabel then
		return
	end

	local mult = RhythmEngine.getComboMultiplier(comboCount)
	comboLabel.Text = string.format("%d COMBO!", comboCount)
	comboMultiplierLabel.Text = string.format("%.1fx", mult)

	-- Pulse animation on combo increment
	comboLabel.Size = UDim2.fromOffset(160, 36)
	local pulse = TweenService:Create(
		comboLabel,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(140, 30) }
	)
	pulse:Play()

	-- Combo Tiers & Aura Aesthetics
	if comboCount >= 20 then
		comboLabel.TextColor3 = PALETTE.PINK
		comboMultiplierLabel.TextColor3 = PALETTE.PINK
		comboAuraLabel.Text = "🔥 FEVER 3.0x 🔥"
		comboAuraLabel.TextColor3 = PALETTE.PINK
		comboAuraLabel.Visible = true
	elseif comboCount >= 10 then
		comboLabel.TextColor3 = PALETTE.GOLD
		comboMultiplierLabel.TextColor3 = PALETTE.GOLD
		comboAuraLabel.Text = "✨ STREAK 2.0x ✨"
		comboAuraLabel.TextColor3 = PALETTE.GOLD
		comboAuraLabel.Visible = true
	elseif comboCount >= 5 then
		comboLabel.TextColor3 = PALETTE.ZUNDA_GREEN
		comboMultiplierLabel.TextColor3 = PALETTE.ZUNDA_GREEN
		comboAuraLabel.Text = "🍡 GOOD FLOW 🍡"
		comboAuraLabel.TextColor3 = PALETTE.ZUNDA_GREEN
		comboAuraLabel.Visible = true
	else
		comboLabel.TextColor3 = PALETTE.TEXT_LIGHT
		comboMultiplierLabel.TextColor3 = PALETTE.TEXT_MUTED
		comboAuraLabel.Visible = false
	end

	-- Score & Accuracy
	if scoreLabel and accuracyLabel then
		scoreLabel.Text = string.format("Score: %d", scoreState.totalScore)
		local totalHits = scoreState.perfect + scoreState.great + scoreState.good + scoreState.miss
		local accuracy = 100
		if totalHits > 0 then
			local weighted = (scoreState.perfect * 1.0) + (scoreState.great * 0.6) + (scoreState.good * 0.3)
			accuracy = math.round((weighted / totalHits) * 1000) / 10
		end
		local grade = RhythmEngine.getGrade(accuracy)
		accuracyLabel.Text = string.format("%.1f%% [%s]", accuracy, grade)
	end
end

-- ── UI Construction (Glassmorphic 4-Lane Layout) ─────────────────────────────
local function buildUI()
	if screenGui and screenGui.Parent then
		return screenGui, mainPanel, trackFrame
	end

	screenGui = ClientGuiBootstrap.createScreenGui(player, "CookingControllerGui", 100)
	screenGui.ResetOnSpawn = false

	-- Main Container (Centered Glassmorphic Panel) - VISIBLE = FALSE ON START
	mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainCookingPanel"
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.Position = UDim2.new(0.5, 0, 0.76, 0)
	mainPanel.Size = UDim2.new(0, 480, 0, 360)
	mainPanel.BackgroundColor3 = PALETTE.BG_DARK
	mainPanel.BackgroundTransparency = 0.15
	mainPanel.Visible = false -- Strictly adheres to AGENTS.md Rule 2
	mainPanel.Parent = screenGui

	-- Dynamic UIScale to ensure responsive presentation across Mobile, Tablet, and Desktop
	panelScale = Instance.new("UIScale")
	panelScale.Name = "CookingScale"
	panelScale.Scale = 1
	panelScale.Parent = mainPanel

	updateCookingScale()

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCookingScale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCookingScale)
			updateCookingScale()
		end
	end)

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 18)
	mainCorner.Parent = mainPanel

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = PALETTE.PANEL_BORDER
	mainStroke.Thickness = 2.5
	mainStroke.Transparency = 0.35
	mainStroke.Parent = mainPanel

	-- Top Header Bar (Title, Difficulty, Progress)
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "HeaderFrame"
	headerFrame.Size = UDim2.new(1, -24, 0, 36)
	headerFrame.Position = UDim2.new(0, 12, 0, 10)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = mainPanel

	recipeLabel = Instance.new("TextLabel")
	recipeLabel.Name = "RecipeLabel"
	recipeLabel.Size = UDim2.new(0.65, 0, 1, 0)
	recipeLabel.Position = UDim2.new(0, 0, 0, 0)
	recipeLabel.BackgroundTransparency = 1
	recipeLabel.Text = "🍳 Cooking: Zunda Mochi"
	recipeLabel.TextColor3 = PALETTE.GOLD
	recipeLabel.Font = Enum.Font.GothamBold
	recipeLabel.TextSize = 18
	recipeLabel.TextXAlignment = Enum.TextXAlignment.Left
	recipeLabel.Parent = headerFrame

	scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreLabel"
	scoreLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
	scoreLabel.Position = UDim2.new(0.65, 0, 0, 0)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "Score: 0"
	scoreLabel.TextColor3 = PALETTE.TEXT_LIGHT
	scoreLabel.Font = Enum.Font.GothamMedium
	scoreLabel.TextSize = 13
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
	scoreLabel.Parent = headerFrame

	accuracyLabel = Instance.new("TextLabel")
	accuracyLabel.Name = "AccuracyLabel"
	accuracyLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
	accuracyLabel.Position = UDim2.new(0.65, 0, 0.5, 0)
	accuracyLabel.BackgroundTransparency = 1
	accuracyLabel.Text = "100% [S]"
	accuracyLabel.TextColor3 = PALETTE.ZUNDA_GREEN
	accuracyLabel.Font = Enum.Font.GothamBold
	accuracyLabel.TextSize = 13
	accuracyLabel.TextXAlignment = Enum.TextXAlignment.Right
	accuracyLabel.Parent = headerFrame

	-- Progress Bar Container
	local progressBarBg = Instance.new("Frame")
	progressBarBg.Name = "ProgressBarBg"
	progressBarBg.Size = UDim2.new(1, -24, 0, 6)
	progressBarBg.Position = UDim2.new(0, 12, 0, 48)
	progressBarBg.BackgroundColor3 = Color3.fromRGB(35, 30, 48)
	progressBarBg.BorderSizePixel = 0
	progressBarBg.Parent = mainPanel

	local pbCorner = Instance.new("UICorner")
	pbCorner.CornerRadius = UDim.new(1, 0)
	pbCorner.Parent = progressBarBg

	progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	progressBarFill.BackgroundColor3 = PALETTE.ZUNDA_GREEN
	progressBarFill.BorderSizePixel = 0
	progressBarFill.Parent = progressBarBg

	local pbfCorner = Instance.new("UICorner")
	pbfCorner.CornerRadius = UDim.new(1, 0)
	pbfCorner.Parent = progressBarFill

	-- Combo Bar Row
	local comboRow = Instance.new("Frame")
	comboRow.Name = "ComboRow"
	comboRow.Size = UDim2.new(1, -24, 0, 24)
	comboRow.Position = UDim2.new(0, 12, 0, 58)
	comboRow.BackgroundTransparency = 1
	comboRow.Parent = mainPanel

	comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboLabel"
	comboLabel.Size = UDim2.fromOffset(140, 24)
	comboLabel.Position = UDim2.new(0, 0, 0, 0)
	comboLabel.BackgroundTransparency = 1
	comboLabel.Text = "0 COMBO!"
	comboLabel.TextColor3 = PALETTE.TEXT_LIGHT
	comboLabel.Font = Enum.Font.GothamBlack
	comboLabel.TextSize = 16
	comboLabel.TextXAlignment = Enum.TextXAlignment.Left
	comboLabel.Parent = comboRow

	comboMultiplierLabel = Instance.new("TextLabel")
	comboMultiplierLabel.Name = "ComboMultiplierLabel"
	comboMultiplierLabel.Size = UDim2.fromOffset(60, 24)
	comboMultiplierLabel.Position = UDim2.new(0, 130, 0, 0)
	comboMultiplierLabel.BackgroundTransparency = 1
	comboMultiplierLabel.Text = "1.0x"
	comboMultiplierLabel.TextColor3 = PALETTE.TEXT_MUTED
	comboMultiplierLabel.Font = Enum.Font.GothamBold
	comboMultiplierLabel.TextSize = 14
	comboMultiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
	comboMultiplierLabel.Parent = comboRow

	comboAuraLabel = Instance.new("TextLabel")
	comboAuraLabel.Name = "ComboAuraLabel"
	comboAuraLabel.Size = UDim2.new(1, -200, 1, 0)
	comboAuraLabel.Position = UDim2.new(0, 190, 0, 0)
	comboAuraLabel.BackgroundTransparency = 1
	comboAuraLabel.Text = "✨ STREAK 2.0x ✨"
	comboAuraLabel.TextColor3 = PALETTE.GOLD
	comboAuraLabel.Font = Enum.Font.GothamBold
	comboAuraLabel.TextSize = 13
	comboAuraLabel.TextXAlignment = Enum.TextXAlignment.Right
	comboAuraLabel.Visible = false
	comboAuraLabel.Parent = comboRow

	-- Track Container (Houses the 4 Lane Columns)
	trackFrame = Instance.new("Frame")
	trackFrame.Name = "TrackFrame"
	trackFrame.Size = UDim2.new(1, -24, 0, 200)
	trackFrame.Position = UDim2.new(0, 12, 0, 86)
	trackFrame.BackgroundColor3 = PALETTE.BG_TRACK
	trackFrame.BackgroundTransparency = 0.35
	trackFrame.ClipsDescendants = true
	trackFrame.Parent = mainPanel

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 12)
	trackCorner.Parent = trackFrame

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(80, 70, 105)
	trackStroke.Thickness = 1.5
	trackStroke.Transparency = 0.5
	trackStroke.Parent = trackFrame

	-- Horizontal Target Guide Line
	local targetLine = Instance.new("Frame")
	targetLine.Name = "TargetGuideLine"
	targetLine.AnchorPoint = Vector2.new(0, 0.5)
	targetLine.Position = UDim2.new(0, 0, TARGET_Y_RATIO, 0)
	targetLine.Size = UDim2.new(1, 0, 0, 3)
	targetLine.BackgroundColor3 = PALETTE.PANEL_BORDER
	targetLine.BackgroundTransparency = 0.3
	targetLine.BorderSizePixel = 0
	targetLine.ZIndex = 8
	targetLine.Parent = trackFrame

	-- Build 4 Vertical Lanes
	laneColumns = {}
	laneReceptors = {}
	local laneWidth = 0.25

	for i = 1, 4 do
		local laneDef = LANE_DATA[i]

		-- Lane Column Frame
		local col = Instance.new("Frame")
		col.Name = "Lane_" .. i
		col.Size = UDim2.new(laneWidth, 0, 1, 0)
		col.Position = UDim2.new((i - 1) * laneWidth, 0, 0, 0)
		col.BackgroundColor3 = laneDef.color
		col.BackgroundTransparency = 0.94
		col.BorderSizePixel = 0
		col.ZIndex = 2
		col.Active = true
		col.Parent = trackFrame
		laneColumns[i] = col

		-- Touch & Mouse Direct Click Handler on Lane Column
		col.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				handleLaneHit(i)
			end
		end)

		-- Subtle Column Divider Line
		if i < 4 then
			local divider = Instance.new("Frame")
			divider.Name = "Divider"
			divider.Size = UDim2.new(0, 1, 1, 0)
			divider.Position = UDim2.new(1, -1, 0, 0)
			divider.BackgroundColor3 = Color3.fromRGB(120, 110, 145)
			divider.BackgroundTransparency = 0.7
			divider.BorderSizePixel = 0
			divider.ZIndex = 3
			divider.Parent = col
		end

		-- Top Lane Header (Action Icon & Name)
		local laneHeader = Instance.new("Frame")
		laneHeader.Name = "LaneHeader"
		laneHeader.Size = UDim2.new(1, -6, 0, 28)
		laneHeader.Position = UDim2.new(0, 3, 0, 4)
		laneHeader.BackgroundColor3 = laneDef.color
		laneHeader.BackgroundTransparency = 0.8
		laneHeader.ZIndex = 4
		laneHeader.Parent = col

		local lhCorner = Instance.new("UICorner")
		lhCorner.CornerRadius = UDim.new(0, 6)
		lhCorner.Parent = laneHeader

		local lhLabel = Instance.new("TextLabel")
		lhLabel.Size = UDim2.new(1, 0, 1, 0)
		lhLabel.BackgroundTransparency = 1
		lhLabel.Text = string.format("%s %s", laneDef.icon, laneDef.name)
		lhLabel.TextColor3 = laneDef.color
		lhLabel.Font = Enum.Font.GothamBold
		lhLabel.TextSize = 11
		lhLabel.ZIndex = 5
		lhLabel.Parent = laneHeader

		-- Target Receptor at Bottom
		local receptor = Instance.new("Frame")
		receptor.Name = "Receptor"
		receptor.AnchorPoint = Vector2.new(0.5, 0.5)
		receptor.Position = UDim2.new(0.5, 0, TARGET_Y_RATIO, 0)
		receptor.Size = UDim2.fromOffset(48, 48)
		receptor.BackgroundColor3 = PALETTE.BG_DARK
		receptor.BackgroundTransparency = 0.2
		receptor.BorderSizePixel = 0
		receptor.ZIndex = 10
		receptor.Parent = col
		laneReceptors[i] = receptor

		local rCorner = Instance.new("UICorner")
		rCorner.CornerRadius = UDim.new(1, 0)
		rCorner.Parent = receptor

		local rStroke = Instance.new("UIStroke")
		rStroke.Color = laneDef.color
		rStroke.Thickness = 2.5
		rStroke.Transparency = 0.1
		rStroke.Parent = receptor

		local rKeyLabel = Instance.new("TextLabel")
		rKeyLabel.Size = UDim2.new(1, 0, 1, 0)
		rKeyLabel.BackgroundTransparency = 1
		rKeyLabel.Text = laneDef.key
		rKeyLabel.TextColor3 = laneDef.color
		rKeyLabel.Font = Enum.Font.GothamBlack
		rKeyLabel.TextSize = 18
		rKeyLabel.ZIndex = 11
		rKeyLabel.Parent = receptor
	end

	-- Effects & Judgment Layer (Overlays Track)
	effectsContainer = Instance.new("Frame")
	effectsContainer.Name = "EffectsContainer"
	effectsContainer.Size = UDim2.new(1, 0, 1, 0)
	effectsContainer.BackgroundTransparency = 1
	effectsContainer.ZIndex = 20
	effectsContainer.Parent = trackFrame

	judgmentContainer = Instance.new("Frame")
	judgmentContainer.Name = "JudgmentContainer"
	judgmentContainer.Size = UDim2.new(1, 0, 1, 0)
	judgmentContainer.BackgroundTransparency = 1
	judgmentContainer.ZIndex = 30
	judgmentContainer.Parent = mainPanel

	-- Bottom Multi-Zone Responsive Mobile Tap Row & Dual-Thumb Touch Pads
	local bottomControls = Instance.new("Frame")
	bottomControls.Name = "BottomControls"
	bottomControls.Size = UDim2.new(1, -24, 0, 44)
	bottomControls.Position = UDim2.new(0, 12, 1, -52)
	bottomControls.BackgroundTransparency = 1
	bottomControls.Parent = mainPanel

	mobileTapButtons = {}
	for i = 1, 4 do
		local laneDef = LANE_DATA[i]
		local tapBtn = Instance.new("TextButton")
		tapBtn.Name = "TapBtn_" .. i
		tapBtn.Size = UDim2.new(laneWidth, -6, 1, 0)
		tapBtn.Position = UDim2.new((i - 1) * laneWidth, 3, 0, 0)
		tapBtn.BackgroundColor3 = laneDef.color
		tapBtn.BackgroundTransparency = 0.30
		tapBtn.Text = string.format("%s %s [%s]", laneDef.icon, laneDef.name, laneDef.key)
		tapBtn.TextColor3 = Color3.fromRGB(20, 15, 25)
		tapBtn.Font = Enum.Font.GothamBlack
		tapBtn.TextSize = 12
		tapBtn.BorderSizePixel = 0
		tapBtn.AutoButtonColor = false
		tapBtn.Active = true
		tapBtn.Parent = bottomControls

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = tapBtn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(255, 255, 255)
		btnStroke.Thickness = 2
		btnStroke.Transparency = 0.4
		btnStroke.Parent = tapBtn

		mobileTapButtons[i] = tapBtn
	end

	return screenGui, mainPanel, trackFrame
end

-- ── Note Creation Helper ─────────────────────────────────────────────────────
local function createNoteInstance(parentColumn: Frame, laneDef: any, noteIndex: number): Frame
	local noteFrame = Instance.new("Frame")
	noteFrame.Name = "Note_" .. noteIndex
	noteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	noteFrame.Size = UDim2.fromOffset(44, 44)
	noteFrame.Position = UDim2.new(0.5, 0, 0, 0)
	noteFrame.BackgroundColor3 = laneDef.color
	noteFrame.BackgroundTransparency = 0.05
	noteFrame.BorderSizePixel = 0
	noteFrame.ZIndex = 6
	noteFrame.Parent = parentColumn

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = noteFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = noteFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = laneDef.icon
	iconLabel.TextSize = 22
	iconLabel.ZIndex = 7
	iconLabel.Parent = noteFrame

	return noteFrame
end

-- ── Hit Evaluation & Input Handling ──────────────────────────────────────────
handleLaneHit = function(targetLaneId: number?)
	if not activeSession or not mainPanel or not mainPanel.Visible then
		return
	end

	local now = workspace:GetServerTimeNow()
	local bestNote: ActiveNote? = nil
	local bestDiff = math.huge

	-- If targetLaneId is provided, look for notes in that lane.
	-- If nil (universal Spacebar / universal tap), search across all lanes.
	for _, note in ipairs(activeNotes) do
		if not note.hit and not note.missed then
			if targetLaneId == nil or note.laneId == targetLaneId then
				local diff = math.abs(now - note.targetTime)
				if diff <= currentWindows.okWindow and diff < bestDiff then
					bestDiff = diff
					bestNote = note
				end
			end
		end
	end

	if bestNote then
		bestNote.hit = true
		local laneDef = LANE_DATA[bestNote.laneId]

		-- Determine quality from offset
		local quality = "ok"
		local basePoints = RhythmEngine.BASE_SCORES.GOOD
		if bestDiff <= currentWindows.hitWindow then
			quality = "perfect"
			basePoints = RhythmEngine.BASE_SCORES.PERFECT
		elseif bestDiff <= currentWindows.greatWindow then
			quality = "great"
			basePoints = RhythmEngine.BASE_SCORES.GREAT
		end

		-- Update score and combo
		scoreState[quality] = (scoreState[quality] or 0) + 1
		comboCount += 1
		if comboCount > maxComboCount then
			maxComboCount = comboCount
		end
		local mult = RhythmEngine.getComboMultiplier(comboCount)
		scoreState.totalScore += math.floor(basePoints * mult)

		-- Trigger visual burst & judgment banner
		if effectsContainer then
			spawnHitBurst(bestNote.laneId, laneDef.color, effectsContainer)
		end
		if judgmentContainer then
			spawnJudgmentBanner(quality, bestNote.laneId, judgmentContainer)
		end

		-- Trigger dynamic audio & VOICEVOX cheerleading cues
		if _G.ZundaSoundController then
			if quality == "perfect" then
				_G.ZundaSoundController.play("CookingPerfect")
				_G.ZundaSoundController.playVoiceDelayed("cook_perfect", 0.18)
			elseif quality == "great" then
				_G.ZundaSoundController.play("Bubbles")
				_G.ZundaSoundController.playVoiceDelayed("cook_good", 0.18)
			else
				_G.ZundaSoundController.play("Bubbles")
			end
		end

		-- Send authoritative hit intent to server (CookingService.hit)
		if cookingHitEvent and currentSessionId then
			cookingHitEvent:FireServer(currentSessionId, bestNote.noteIndex, bestNote.laneId)
		end

		-- Animate note destruction
		if bestNote.instance and bestNote.instance.Parent then
			local shrink = TweenService:Create(
				bestNote.instance,
				TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 1 }
			)
			shrink:Play()
			shrink.Completed:Connect(function()
				if bestNote and bestNote.instance then
					bestNote.instance:Destroy()
				end
			end)
		end
	else
		-- Mistap (Active Miss)
		comboCount = 0
		scoreState.miss = (scoreState.miss or 0) + 1

		if judgmentContainer then
			spawnJudgmentBanner("miss", targetLaneId, judgmentContainer)
		end

		if _G.ZundaSoundController then
			_G.ZundaSoundController.play("CookingMiss")
			_G.ZundaSoundController.playVoice("cook_miss")
		end
	end

	updateComboUI()
end

-- ── Session Management (start, stop, isCooking) ──────────────────────────────
function CookingController.start(
	recipeName: string,
	session: any,
	onComplete: ((quality: string, score: any, maxCombo: number) -> ())?
)
	if activeSession then
		return
	end
	if type(session) ~= "table" or type(session.sessionId) ~= "string" then
		return
	end

	local _, panel, track = buildUI()
	if not panel or not track then
		return
	end

	activeSession = true
	currentSessionId = session.sessionId
	currentRecipeName = if type(recipeName) == "string" and recipeName ~= "" then recipeName else "Dish"
	activeNotes = {}
	scoreState = { perfect = 0, great = 0, good = 0, miss = 0, totalScore = 0 }
	comboCount = 0
	maxComboCount = 0

	-- Timing Windows from server payload (with fallback)
	currentWindows.hitWindow = tonumber(session.perfectWindow) or RhythmEngine.BASE_WINDOWS.PERFECT
	currentWindows.greatWindow = tonumber(session.greatWindow) or RhythmEngine.BASE_WINDOWS.GREAT
	currentWindows.okWindow = tonumber(session.okWindow) or RhythmEngine.BASE_WINDOWS.GOOD

	local totalNotesToSpawn = tonumber(session.totalNotes) or 8
	local firstTargetAt = tonumber(session.firstTargetAt) or (workspace:GetServerTimeNow() + 2.0)
	local noteInterval = tonumber(session.noteInterval) or 1.0

	-- Generate or retrieve beatmap pattern for this recipe
	local chart = RhythmBeatmapConfig.getChart(currentRecipeName, totalNotesToSpawn * noteInterval, "normal")

	-- Populate active notes
	for i = 1, totalNotesToSpawn do
		local targetTime = firstTargetAt + (i - 1) * noteInterval
		local laneId = 1
		if chart.notes and chart.notes[i] then
			laneId = chart.notes[i].laneId
		else
			laneId = ((i - 1) % 4) + 1
		end
		local laneDef = LANE_DATA[laneId] or LANE_DATA[1]

		table.insert(activeNotes, {
			noteIndex = i,
			laneId = laneId,
			targetTime = targetTime,
			spawnTime = targetTime - FALL_DURATION,
			action = laneDef.name,
			icon = laneDef.icon,
			hit = false,
			missed = false,
			instance = nil,
		})
	end

	-- Configure Header Labels
	if recipeLabel then
		recipeLabel.Text = "🍳 Cooking: " .. currentRecipeName
	end
	if progressBarFill then
		progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	end
	updateComboUI()

	-- Start session sound & voice cheer
	if _G.ZundaSoundController then
		_G.ZundaSoundController.playVoice("cook_start")
	end

	updateCookingScale()
	panel.Visible = true

	if panelScale then
		panelScale.Scale = currentTargetScale * 0.3
		TweenService:Create(
			panelScale,
			TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = currentTargetScale }
		):Play()
	end

	local sessionStartTime = workspace:GetServerTimeNow()
	local totalSessionDuration = (firstTargetAt - sessionStartTime) + (totalNotesToSpawn * noteInterval) + 1.0
	local ended = false

	-- Input Connections
	local inputConn: RBXScriptConnection? = nil
	local tapConns: { RBXScriptConnection } = {}
	local runConn: RBXScriptConnection? = nil

	local function cleanup()
		ended = true
		activeSession = false
		currentSessionId = nil

		if inputConn then
			inputConn:Disconnect()
			inputConn = nil
		end
		for _, conn in ipairs(tapConns) do
			conn:Disconnect()
		end
		tapConns = {}
		if runConn then
			runConn:Disconnect()
			runConn = nil
		end

		for _, note in ipairs(activeNotes) do
			if note.instance and note.instance.Parent then
				note.instance:Destroy()
			end
		end
		activeNotes = {}

		if panel then
			panel.Visible = false
		end
	end

	-- Keyboard & Gamepad Input Listener (Cross-Platform Desktop & Controller)
	inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local kc = input.KeyCode
		-- Lane 1 (CHOP): D, Left Arrow, 1, Keypad 1
		if
			kc == Enum.KeyCode.D
			or kc == Enum.KeyCode.Left
			or kc == Enum.KeyCode.One
			or kc == Enum.KeyCode.KeypadOne
		then
			handleLaneHit(1)
		-- Lane 2 (STIR): F, Down Arrow, 2, Keypad 2
		elseif
			kc == Enum.KeyCode.F
			or kc == Enum.KeyCode.Down
			or kc == Enum.KeyCode.Two
			or kc == Enum.KeyCode.KeypadTwo
		then
			handleLaneHit(2)
		-- Lane 3 (SIMMER): J, Up Arrow, 3, Keypad 3
		elseif
			kc == Enum.KeyCode.J
			or kc == Enum.KeyCode.Up
			or kc == Enum.KeyCode.Three
			or kc == Enum.KeyCode.KeypadThree
		then
			handleLaneHit(3)
		-- Lane 4 (SEASON): K, Right Arrow, 4, Keypad 4
		elseif
			kc == Enum.KeyCode.K
			or kc == Enum.KeyCode.Right
			or kc == Enum.KeyCode.Four
			or kc == Enum.KeyCode.KeypadFour
		then
			handleLaneHit(4)
		-- Universal Hit: Space, Return, Gamepad Buttons
		elseif
			kc == Enum.KeyCode.Space
			or kc == Enum.KeyCode.Return
			or kc == Enum.KeyCode.ButtonA
			or kc == Enum.KeyCode.ButtonX
			or kc == Enum.KeyCode.ButtonB
			or kc == Enum.KeyCode.ButtonY
			or kc == Enum.KeyCode.ButtonR1
			or kc == Enum.KeyCode.ButtonL1
			or kc == Enum.KeyCode.ButtonR2
			or kc == Enum.KeyCode.ButtonL2
		then
			-- Universal Tap: hits earliest upcoming unhit note across all lanes
			handleLaneHit(nil)
		end
	end)

	-- Mobile Dual-Thumb On-Screen Buttons Tap & Touch Listeners
	for laneIdx, btn in pairs(mobileTapButtons) do
		local function triggerBtnTap()
			local origSize = UDim2.new(0.25, -6, 1, 0)
			btn.Size = UDim2.new(0.25, -4, 1.12, 0)
			TweenService
				:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = origSize })
				:Play()
			handleLaneHit(laneIdx)
		end

		local cClick = btn.MouseButton1Click:Connect(triggerBtnTap)
		table.insert(tapConns, cClick)

		local cTouch = btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				triggerBtnTap()
			end
		end)
		table.insert(tapConns, cTouch)
	end

	-- Render Loop: Frame-independent note animation & passive miss detection
	runConn = RunService.RenderStepped:Connect(function(_dt)
		if ended then
			return
		end

		local now = workspace:GetServerTimeNow()
		local elapsedSession = now - sessionStartTime
		local sessionProgress = math.clamp(elapsedSession / totalSessionDuration, 0, 1)

		if progressBarFill then
			progressBarFill.Size = UDim2.new(sessionProgress, 0, 1, 0)
		end

		local trackHeight = if trackFrame then trackFrame.AbsoluteSize.Y else 200
		local hitZoneY = trackHeight * TARGET_Y_RATIO

		-- Iterate over notes
		for _, note in ipairs(activeNotes) do
			if not note.hit and not note.missed then
				local noteElapsed = now - note.spawnTime
				local progress = noteElapsed / FALL_DURATION

				-- Lazy spawn note visual when note starts falling
				if progress >= 0 and not note.instance then
					local col = laneColumns[note.laneId]
					local laneDef = LANE_DATA[note.laneId]
					if col and laneDef then
						note.instance = createNoteInstance(col, laneDef, note.noteIndex)
					end
				end

				-- Update note position
				if note.instance and note.instance.Parent then
					if progress >= 1.0 + (currentWindows.okWindow / FALL_DURATION) then
						-- Passive Miss: Note fell past hit zone without input
						note.missed = true
						comboCount = 0
						scoreState.miss = (scoreState.miss or 0) + 1

						if judgmentContainer then
							spawnJudgmentBanner("miss", note.laneId, judgmentContainer)
						end
						if _G.ZundaSoundController then
							_G.ZundaSoundController.play("CookingMiss")
							_G.ZundaSoundController.playVoice("cook_miss")
						end

						updateComboUI()

						local fade = TweenService:Create(
							note.instance,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ BackgroundTransparency = 1 }
						)
						fade:Play()
						fade.Completed:Connect(function()
							if note.instance then
								note.instance:Destroy()
							end
						end)
					else
						local yOffset = progress * hitZoneY
						note.instance.Position = UDim2.new(0.5, 0, 0, yOffset)
					end
				end
			end
		end

		-- Check for session end
		if
			elapsedSession >= totalSessionDuration
			or (#activeNotes > 0 and (now >= activeNotes[#activeNotes].targetTime + currentWindows.okWindow + 0.5))
		then
			cleanup()

			-- Calculate display quality for completion callback
			local totalHits = scoreState.perfect + scoreState.great + scoreState.good + scoreState.miss
			local displayQuality = "ok"
			local perfectRatio = scoreState.perfect / math.max(totalHits, 1)
			local accuracy = 100
			if totalHits > 0 then
				local weighted = (scoreState.perfect * 1.0) + (scoreState.great * 0.6) + (scoreState.good * 0.3)
				accuracy = math.round((weighted / totalHits) * 1000) / 10
			end

			if accuracy >= 95 or perfectRatio >= 0.7 then
				displayQuality = "perfect"
			elseif accuracy >= 70 or (scoreState.perfect + scoreState.great) / math.max(totalHits, 1) >= 0.5 then
				displayQuality = "great"
			end

			if onComplete then
				onComplete(displayQuality, scoreState, maxComboCount)
			end
		end
	end)
end

function CookingController.stop()
	activeSession = false
	if mainPanel then
		mainPanel.Visible = false
	end
end

function CookingController.isCooking(): boolean
	return activeSession
end

-- Export for backward compatibility & global access
_G.TimedCooking = CookingController
_G.CookingController = CookingController

return CookingController
