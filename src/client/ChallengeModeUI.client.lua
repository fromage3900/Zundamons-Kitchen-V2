--!strict
-- ChallengeModeUI: Full client UI for Challenge Mode + Daily Challenges.
-- Listens to ChallengeModeStatus and DailyChallengeStatus remotes.
-- Complies with AGENTS.md Rule 2 (ClientGuiBootstrap, PlayerGui, ResetOnSpawn = false, panel.Visible = false on startup).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- ── Remote setup ────────────────────────────────────────────────────────────
local remotes = RS:WaitForChild("RemoteEvents")
local challengeStatus = remotes:WaitForChild("ChallengeModeStatus")
local dailyStatus = remotes:WaitForChild("DailyChallengeStatus")

local remoteFunctions = RS:WaitForChild("RemoteFunctions")
local challengeStartRF = remoteFunctions:WaitForChild("ChallengeStart")
local challengeAbandonRF = remoteFunctions:WaitForChild("ChallengeAbandon")
local challengeCompleteWaveRF = remoteFunctions:WaitForChild("ChallengeCompleteWave")
local dailyClaimRF = remoteFunctions:WaitForChild("DailyClaimReward")
local dailyClaimWeeklyRF = remoteFunctions:WaitForChild("DailyClaimWeekly")

-- ── State ───────────────────────────────────────────────────────────────────
local challengeState = {
	active = false,
	wave = 1,
	score = 0,
	tier = "Bronze",
	tierIcon = "🥉",
	combo = 0,
	maxCombo = 0,
	recipes = {},
	locked = false,
	lockReason = "",
}
local dailyState = {
	challenges = {},
	progress = {},
	claimed = {},
	streak = 0,
	weeklyBoss = nil,
	weeklyProgress = 0,
	weeklyClaimed = false,
}

-- ── UI ─────────────────────────────────────────────────────────────────────
local gui = ClientGuiBootstrap.createScreenGui(player, "ChallengeModeGui", 90)
gui.Enabled = true

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 460, 0, 600)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
panel.BorderSizePixel = 0
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(220, 160, 230)
panelStroke.Thickness = 2.5

-- Header
local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)
header.ClipsDescendants = true

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.Text = "🌱 Challenge Mode"
title.Font = Enum.Font.FredokaOne
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 220, 245)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- Scroll container
local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "Content"
scroll.Size = UDim2.new(1, -32, 1, -80)
scroll.Position = UDim2.new(0, 16, 0, 68)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 160, 230)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- ── Helper: build a card ────────────────────────────────────────────────────
local function makeCard(parent, titleText, subtitleText, color)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(1, 0, 0, 90)
	card.BackgroundColor3 = Color3.fromRGB(40, 32, 55)
	card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local cardStroke = Instance.new("UIStroke", card)
	cardStroke.Color = color or Color3.fromRGB(160, 120, 200)
	cardStroke.Thickness = 1.5

	local t = Instance.new("TextLabel", card)
	t.Size = UDim2.new(1, -20, 0, 24)
	t.Position = UDim2.new(0, 10, 0, 8)
	t.BackgroundTransparency = 1
	t.Text = titleText
	t.Font = Enum.Font.GothamBold
	t.TextSize = 18
	t.TextColor3 = Color3.fromRGB(255, 240, 255)
	t.TextXAlignment = Enum.TextXAlignment.Left

	local s = Instance.new("TextLabel", card)
	s.Size = UDim2.new(1, -20, 0, 20)
	s.Position = UDim2.new(0, 10, 0, 36)
	s.BackgroundTransparency = 1
	s.Text = subtitleText
	s.Font = Enum.Font.Gotham
	s.TextSize = 13
	s.TextColor3 = Color3.fromRGB(200, 180, 220)
	s.TextXAlignment = Enum.TextXAlignment.Left
	s.TextWrapped = true

	return card, t, s
end

-- ── Challenge Mode section ──────────────────────────────────────────────────
local function buildChallengeSection()
	-- Clear existing challenge cards
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name == "ChallengeCard" then
			child:Destroy()
		end
	end

	local card, t, s = makeCard(scroll, "", "", Color3.fromRGB(160, 210, 150))
	card.Name = "ChallengeCard"
	card.Size = UDim2.new(1, 0, 0, 140)

	if challengeState.locked then
		t.Text = "🔒 Challenge Mode Locked"
		s.Text = challengeState.lockReason
		s.Size = UDim2.new(1, -20, 0, 40)
		s.Position = UDim2.new(0, 10, 0, 40)
	elseif challengeState.active then
		t.Text = challengeState.tierIcon .. " Wave " .. challengeState.wave .. " — " .. challengeState.tier
		s.Text = "Score: "
			.. challengeState.score
			.. " | Combo: "
			.. challengeState.combo
			.. " (max "
			.. challengeState.maxCombo
			.. ")"
		s.Size = UDim2.new(1, -20, 0, 20)
		s.Position = UDim2.new(0, 10, 0, 40)

		-- Recipes for this wave
		local recipeText = "Recipes: " .. table.concat(challengeState.recipes, ", ")
		local rLabel = Instance.new("TextLabel", card)
		rLabel.Size = UDim2.new(1, -20, 0, 20)
		rLabel.Position = UDim2.new(0, 10, 0, 64)
		rLabel.BackgroundTransparency = 1
		rLabel.Text = recipeText
		rLabel.Font = Enum.Font.Gotham
		rLabel.TextSize = 12
		rLabel.TextColor3 = Color3.fromRGB(180, 220, 170)
		rLabel.TextXAlignment = Enum.TextXAlignment.Left
		rLabel.TextWrapped = true

		-- Abandon button
		local abandonBtn = Instance.new("TextButton", card)
		abandonBtn.Size = UDim2.new(0, 120, 0, 32)
		abandonBtn.Position = UDim2.new(1, -130, 1, -40)
		abandonBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
		abandonBtn.Text = "Abandon"
		abandonBtn.Font = Enum.Font.GothamBold
		abandonBtn.TextSize = 14
		abandonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		abandonBtn.BorderSizePixel = 0
		Instance.new("UICorner", abandonBtn).CornerRadius = UDim.new(0, 8)
		abandonBtn.MouseButton1Click:Connect(function()
			challengeAbandonRF:InvokeServer()
		end)
	else
		t.Text = "🏆 Start Challenge Mode"
		s.Text = "Endless waves of guests. Serve them all to climb the tiers!"
		s.Size = UDim2.new(1, -20, 0, 40)
		s.Position = UDim2.new(0, 10, 0, 40)

		local startBtn = Instance.new("TextButton", card)
		startBtn.Size = UDim2.new(0, 140, 0, 36)
		startBtn.Position = UDim2.new(1, -150, 1, -44)
		startBtn.BackgroundColor3 = Color3.fromRGB(160, 210, 150)
		startBtn.Text = "Start 🌱"
		startBtn.Font = Enum.Font.GothamBold
		startBtn.TextSize = 15
		startBtn.TextColor3 = Color3.fromRGB(30, 50, 30)
		startBtn.BorderSizePixel = 0
		Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)
		startBtn.MouseButton1Click:Connect(function()
			challengeStartRF:InvokeServer()
		end)
	end
end

-- ── Daily Challenges section ────────────────────────────────────────────────
local function buildDailySection()
	-- Clear existing daily cards
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name == "DailyCard" then
			child:Destroy()
		end
	end

	-- Streak header
	local streakCard, streakT, streakS = makeCard(scroll, "", "", Color3.fromRGB(255, 200, 80))
	streakCard.Name = "DailyCard"
	streakCard.Size = UDim2.new(1, 0, 0, 60)
	streakT.Text = "🔥 Daily Streak: " .. dailyState.streak
	streakS.Text = "Complete all 3 daily challenges to grow your streak!"

	-- Daily challenges
	for i, challenge in ipairs(dailyState.challenges) do
		local progress = dailyState.progress[i] or 0
		local claimed = dailyState.claimed[i] or false
		local done = progress >= challenge.goal

		local card, t, s =
			makeCard(scroll, "", "", done and Color3.fromRGB(160, 210, 150) or Color3.fromRGB(200, 180, 220))
		card.Name = "DailyCard"
		card.Size = UDim2.new(1, 0, 0, 100)

		t.Text = challenge.icon .. " " .. challenge.title .. (done and " ✓" or "")
		s.Text = challenge.description .. " (" .. progress .. "/" .. challenge.goal .. ")"
		s.Size = UDim2.new(1, -20, 0, 20)
		s.Position = UDim2.new(0, 10, 0, 40)

		local rewardText = "Reward: " .. (challenge.reward.gold or 0) .. "g, " .. (challenge.reward.xp or 0) .. "xp"
		local rLabel = Instance.new("TextLabel", card)
		rLabel.Size = UDim2.new(1, -20, 0, 20)
		rLabel.Position = UDim2.new(0, 10, 0, 64)
		rLabel.BackgroundTransparency = 1
		rLabel.Text = rewardText
		rLabel.Font = Enum.Font.Gotham
		rLabel.TextSize = 12
		rLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
		rLabel.TextXAlignment = Enum.TextXAlignment.Left

		if done and not claimed then
			local claimBtn = Instance.new("TextButton", card)
			claimBtn.Size = UDim2.new(0, 100, 0, 30)
			claimBtn.Position = UDim2.new(1, -110, 1, -38)
			claimBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
			claimBtn.Text = "Claim ✨"
			claimBtn.Font = Enum.Font.GothamBold
			claimBtn.TextSize = 13
			claimBtn.TextColor3 = Color3.fromRGB(60, 40, 10)
			claimBtn.BorderSizePixel = 0
			Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)
			claimBtn.MouseButton1Click:Connect(function()
				dailyClaimRF:InvokeServer(i)
			end)
		elseif claimed then
			local claimedLabel = Instance.new("TextLabel", card)
			claimedLabel.Size = UDim2.new(0, 100, 0, 30)
			claimedLabel.Position = UDim2.new(1, -110, 1, -38)
			claimedLabel.BackgroundTransparency = 1
			claimedLabel.Text = "Claimed ✓"
			claimedLabel.Font = Enum.Font.GothamBold
			claimedLabel.TextSize = 13
			claimedLabel.TextColor3 = Color3.fromRGB(160, 210, 150)
		end
	end

	-- Weekly boss
	if dailyState.weeklyBoss then
		local boss = dailyState.weeklyBoss
		local done = dailyState.weeklyProgress >= boss.goal
		local card, t, s =
			makeCard(scroll, "", "", done and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(200, 120, 200))
		card.Name = "DailyCard"
		card.Size = UDim2.new(1, 0, 0, 100)

		t.Text = boss.icon .. " Weekly Boss: " .. boss.title .. (done and " ✓" or "")
		s.Text = boss.description .. " (" .. dailyState.weeklyProgress .. "/" .. boss.goal .. ")"
		s.Size = UDim2.new(1, -20, 0, 20)
		s.Position = UDim2.new(0, 10, 0, 40)

		local rewardText = "Reward: " .. (boss.reward.gold or 0) .. "g, " .. (boss.reward.xp or 0) .. "xp"
		local rLabel = Instance.new("TextLabel", card)
		rLabel.Size = UDim2.new(1, -20, 0, 20)
		rLabel.Position = UDim2.new(0, 10, 0, 64)
		rLabel.BackgroundTransparency = 1
		rLabel.Text = rewardText
		rLabel.Font = Enum.Font.Gotham
		rLabel.TextSize = 12
		rLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
		rLabel.TextXAlignment = Enum.TextXAlignment.Left

		if done and not dailyState.weeklyClaimed then
			local claimBtn = Instance.new("TextButton", card)
			claimBtn.Size = UDim2.new(0, 100, 0, 30)
			claimBtn.Position = UDim2.new(1, -110, 1, -38)
			claimBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
			claimBtn.Text = "Claim 👑"
			claimBtn.Font = Enum.Font.GothamBold
			claimBtn.TextSize = 13
			claimBtn.TextColor3 = Color3.fromRGB(60, 40, 10)
			claimBtn.BorderSizePixel = 0
			Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)
			claimBtn.MouseButton1Click:Connect(function()
				dailyClaimWeeklyRF:InvokeServer()
			end)
		elseif dailyState.weeklyClaimed then
			local claimedLabel = Instance.new("TextLabel", card)
			claimedLabel.Size = UDim2.new(0, 100, 0, 30)
			claimedLabel.Position = UDim2.new(1, -110, 1, -38)
			claimedLabel.BackgroundTransparency = 1
			claimedLabel.Text = "Claimed ✓"
			claimedLabel.Font = Enum.Font.GothamBold
			claimedLabel.TextSize = 13
			claimedLabel.TextColor3 = Color3.fromRGB(160, 210, 150)
		end
	end
end

-- ── Rebuild all ─────────────────────────────────────────────────────────────
local function rebuild()
	-- Clear all
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	buildChallengeSection()
	buildDailySection()
end

-- ── Remote listeners ────────────────────────────────────────────────────────
challengeStatus.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if data.type == "started" then
		challengeState.active = true
		challengeState.wave = data.wave or 1
		challengeState.score = data.score or 0
		challengeState.tier = data.tier or "Bronze"
		challengeState.recipes = data.recipes or {}
		challengeState.locked = false
	elseif data.type == "locked" then
		challengeState.locked = true
		challengeState.lockReason = data.reason or "Serve 10 guests to unlock!"
		challengeState.active = false
	elseif data.type == "wave_complete" then
		challengeState.wave = data.wave or challengeState.wave
		challengeState.score = data.score or challengeState.score
		challengeState.tier = data.tier or challengeState.tier
		challengeState.tierIcon = data.tierIcon or challengeState.tierIcon
		challengeState.recipes = data.recipes or {}
	elseif data.type == "guest_served" or data.type == "cook_scored" then
		challengeState.score = data.score or challengeState.score
		challengeState.wave = data.wave or challengeState.wave
		challengeState.combo = data.combo or challengeState.combo
		challengeState.maxCombo = data.maxCombo or challengeState.maxCombo
	elseif data.type == "guest_timeout" then
		challengeState.combo = 0
		challengeState.score = data.score or challengeState.score
	elseif data.type == "completed" then
		challengeState.active = false
		challengeState.score = 0
		challengeState.combo = 0
		challengeState.maxCombo = 0
	end
	if panel.Visible then
		rebuild()
	end
end)

dailyStatus.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if data.type == "daily_update" then
		dailyState.challenges = data.challenges or {}
		dailyState.progress = data.progress or {}
		dailyState.claimed = data.claimed or {}
		dailyState.streak = data.streak or 0
		dailyState.weeklyBoss = data.weeklyBoss
	elseif data.type == "progress_update" then
		dailyState.progress = data.progress or dailyState.progress
	elseif data.type == "reward_claimed" then
		dailyState.claimed[data.challengeIndex] = true
		dailyState.streak = data.streak or dailyState.streak
	elseif data.type == "weekly_update" then
		dailyState.weeklyBoss = data.boss or dailyState.weeklyBoss
		dailyState.weeklyProgress = data.progress or 0
	elseif data.type == "weekly_claimed" then
		dailyState.weeklyClaimed = true
	end
	if panel.Visible then
		rebuild()
	end
end)

-- ── Open/close ──────────────────────────────────────────────────────────────
local function open()
	panel.Visible = true
	rebuild()
end

local function close()
	panel.Visible = false
end

local function toggle()
	if panel.Visible then
		close()
	else
		open()
	end
end

closeBtn.MouseButton1Click:Connect(close)

-- Register with the central action registry so the Pea Wheel / HUD can open it.
local ActionRegistry =
	require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))
ActionRegistry.registerCallback("challenge", toggle)

-- Also expose globally for HUD buttons.
_G.ChallengeModeUI = {
	isOpen = function()
		return panel.Visible
	end,
	open = open,
	close = close,
	toggle = toggle,
}

print("[ChallengeModeUI] Ready")
