--!strict
-- CookingController: Unified client-side rhythm minigame controller.
-- Complies with AGENTS.md Rule 2 (ClientGuiBootstrap, PlayerGui, ResetOnSpawn = false, panel.Visible = false on startup).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
-- Cooking notes sent as intent-only; server derives quality.
-- No craftConfig dependency needed on client.

-- Ensure RemoteEvents folder & CookingHit RemoteEvent exist
local remotes = RS:FindFirstChild("RemoteEvents")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "RemoteEvents"
	remotes.Parent = RS
end

local cookingHitEvent = remotes:FindFirstChild("CookingHit")
if not cookingHitEvent then
	cookingHitEvent = Instance.new("RemoteEvent")
	cookingHitEvent.Name = "CookingHit"
	cookingHitEvent.Parent = remotes
end

local PEA_CONFIG = {
	fallDuration = 2.0,
	hitWindow = 0.15, -- Perfect <= 0.15s
	greatWindow = 0.35, -- Great <= 0.35s
	okWindow = 0.60, -- OK <= 0.60s
	totalNotes = 10, -- Server default total note count
}

local CookingController = {}
local activeSession = false
local currentPeas = {}
local currentScore = { perfect = 0, great = 0, ok = 0, miss = 0 }
local comboCount = 0
local maxComboCount = 0
local currentSessionId: string? = nil

-- UI Elements
local screenGui: ScreenGui? = nil
local mainPanel: Frame? = nil
local trackFrame: Frame? = nil
local comboLabel: TextLabel? = nil
local recipeLabel: TextLabel? = nil
local tapButton: TextButton? = nil

local function getHitQuality(timeDiff: number): string
	local absDiff = math.abs(timeDiff)
	if absDiff <= PEA_CONFIG.hitWindow then
		return "perfect"
	elseif absDiff <= PEA_CONFIG.greatWindow then
		return "great"
	elseif absDiff <= PEA_CONFIG.okWindow then
		return "ok"
	end
	return "miss"
end

local function spawnFloatingRating(text: string, color: Color3, parent: Instance)
	local ratingLabel = Instance.new("TextLabel")
	ratingLabel.Size = UDim2.new(0, 180, 0, 40)
	ratingLabel.Position = UDim2.new(0.5, -90, 0.4, -20)
	ratingLabel.BackgroundTransparency = 1
	ratingLabel.Text = text
	ratingLabel.TextColor3 = color
	ratingLabel.Font = Enum.Font.GothamBlack
	ratingLabel.TextSize = 28
	ratingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	ratingLabel.TextStrokeTransparency = 0.3
	ratingLabel.ZIndex = 20
	ratingLabel.Parent = parent

	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local goal = {
		Position = UDim2.new(0.5, -90, 0.25, -20),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}
	local tween = TweenService:Create(ratingLabel, tweenInfo, goal)
	tween:Play()
	tween.Completed:Connect(function()
		ratingLabel:Destroy()
	end)
end

local function buildUI()
	if screenGui and screenGui.Parent then
		return screenGui, mainPanel, trackFrame, comboLabel, recipeLabel, tapButton
	end

	screenGui = ClientGuiBootstrap.createScreenGui(player, "CookingControllerGui", 100)

	-- Main Panel Frame (Center Bottom) - STARTS VISIBLE = FALSE
	mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 420, 0, 220)
	mainPanel.Position = UDim2.new(0.5, -210, 0.85, -110)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mainPanel.BackgroundTransparency = 0.15
	mainPanel.Visible = false -- Strictly adheres to AGENTS.md Rule 2d
	mainPanel.Parent = screenGui
	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 16)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = mainPanel

	recipeLabel = Instance.new("TextLabel")
	recipeLabel.Name = "RecipeLabel"
	recipeLabel.Size = UDim2.new(1, 0, 0, 30)
	recipeLabel.Position = UDim2.new(0, 0, 0, 8)
	recipeLabel.BackgroundTransparency = 1
	recipeLabel.Text = "Cooking Minigame"
	recipeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	recipeLabel.Font = Enum.Font.GothamBold
	recipeLabel.TextSize = 20
	recipeLabel.Parent = mainPanel

	comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboLabel"
	comboLabel.Size = UDim2.new(1, 0, 0, 24)
	comboLabel.Position = UDim2.new(0, 0, 0, 36)
	comboLabel.BackgroundTransparency = 1
	comboLabel.Text = "Combo: 0 | Max: 0"
	comboLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	comboLabel.Font = Enum.Font.GothamMedium
	comboLabel.TextSize = 15
	comboLabel.Parent = mainPanel

	trackFrame = Instance.new("Frame")
	trackFrame.Name = "TrackFrame"
	trackFrame.Size = UDim2.new(1, -30, 0, 100)
	trackFrame.Position = UDim2.new(0, 15, 0, 64)
	trackFrame.BackgroundColor3 = Color3.fromRGB(35, 30, 45)
	trackFrame.BackgroundTransparency = 0.3
	trackFrame.ClipsDescendants = true
	trackFrame.Parent = mainPanel
	Instance.new("UICorner", trackFrame).CornerRadius = UDim.new(0, 10)

	-- Hit Zone Line (Horizontal Target Zone)
	local hitZone = Instance.new("Frame")
	hitZone.Name = "HitZone"
	hitZone.Size = UDim2.new(1, 0, 0, 6)
	hitZone.Position = UDim2.new(0, 0, 1, -12)
	hitZone.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	hitZone.BackgroundTransparency = 0.2
	hitZone.Parent = trackFrame
	Instance.new("UICorner", hitZone).CornerRadius = UDim.new(1, 0)

	-- Mobile Touch / On-Screen Tap Button
	tapButton = Instance.new("TextButton")
	tapButton.Name = "TapButton"
	tapButton.Size = UDim2.new(1, -30, 0, 36)
	tapButton.Position = UDim2.new(0, 15, 1, -44)
	tapButton.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	tapButton.Text = "TAP / SPACE / [A]"
	tapButton.TextColor3 = Color3.fromRGB(30, 20, 10)
	tapButton.Font = Enum.Font.GothamBlack
	tapButton.TextSize = 16
	tapButton.Parent = mainPanel
	Instance.new("UICorner", tapButton).CornerRadius = UDim.new(0, 8)

	return screenGui, mainPanel, trackFrame, comboLabel, recipeLabel, tapButton
end

local function createPea(track: Frame, spawnTime: number, noteIndex: number)
	local pea = Instance.new("Frame")
	pea.Size = UDim2.new(0, 28, 0, 28)
	pea.Position = UDim2.new(0.5, -14, 0, 0)
	pea.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
	pea.BackgroundTransparency = 0.1
	pea.ZIndex = 5
	pea.Parent = track
	Instance.new("UICorner", pea).CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🌱"
	icon.TextSize = 18
	icon.Parent = pea

	return {
		instance = pea,
		spawnTime = spawnTime,
		hit = false,
		missed = false,
		noteIndex = noteIndex,
	}
end

local function handleHitInput()
	if not activeSession or not mainPanel or not mainPanel.Visible then
		return
	end

	local now = os.clock()
	local bestPea = nil
	local bestDiff = math.huge

	for _, pea in ipairs(currentPeas) do
		if not pea.hit and not pea.missed then
			local elapsed = now - pea.spawnTime
			local diff = math.abs(elapsed - PEA_CONFIG.fallDuration)
			if diff < bestDiff and diff <= PEA_CONFIG.okWindow then
				bestDiff = diff
				bestPea = pea
			end
		end
	end

	if bestPea then
		bestPea.hit = true
		local quality = getHitQuality(bestDiff)
		currentScore[quality] = (currentScore[quality] or 0) + 1
		comboCount = comboCount + 1
		if comboCount > maxComboCount then
			maxComboCount = comboCount
		end

		local ratingText = quality:upper() .. "!"
		local ratingColor = Color3.fromRGB(255, 215, 0)
		if quality == "great" then
			ratingColor = Color3.fromRGB(100, 255, 100)
		elseif quality == "ok" then
			ratingColor = Color3.fromRGB(120, 220, 255)
		end

		bestPea.instance.BackgroundColor3 = ratingColor
		spawnFloatingRating(ratingText, ratingColor, mainPanel)

		-- Quality is presentation-only; server derives it from this note intent.
		cookingHitEvent:FireServer(currentSessionId, bestPea.noteIndex)

		local shrinkTween = TweenService:Create(
			bestPea.instance,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, Size = UDim2.new(0, 42, 0, 42) }
		)
		shrinkTween:Play()
		shrinkTween.Completed:Connect(function()
			bestPea.instance:Destroy()
		end)
	else
		-- Mistap (Active Miss)
		comboCount = 0
		currentScore.miss = (currentScore.miss or 0) + 1
		spawnFloatingRating("MISS!", Color3.fromRGB(255, 80, 80), mainPanel)
		-- Mistaps do not create an authoritative hit. The server records absent
		-- notes as misses when their timing window expires.
	end

	if comboLabel then
		comboLabel.Text = string.format("Combo: %d | Max: %d", comboCount, maxComboCount)
	end
end

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

	local _, panel, track, cLabel, rLabel, tButton = buildUI()
	if not panel or not track or not cLabel or not rLabel or not tButton then
		return
	end

	activeSession = true
	currentSessionId = session.sessionId
	currentPeas = {}
	currentScore = { perfect = 0, great = 0, ok = 0, miss = 0 }
	comboCount = 0
	maxComboCount = 0

	-- Configure total notes & difficulty for recipe
	local totalNotesToSpawn = tonumber(session.totalNotes) or PEA_CONFIG.totalNotes

	rLabel.Text = "Cooking: " .. (recipeName or "Dish")
	cLabel.Text = "Combo: 0 | Max: 0"
	panel.Visible = true

	local startTime = os.clock()
	local peaSpawnInterval = 1.0
	local totalSessionDuration = (totalNotesToSpawn * peaSpawnInterval) + PEA_CONFIG.fallDuration + 0.5
	local notesSpawned = 0
	local lastSpawnTime = 0
	local ended = false

	-- Connections
	local inputConn: RBXScriptConnection? = nil
	local tapConn: RBXScriptConnection? = nil
	local runConn: RBXScriptConnection? = nil

	local function cleanup()
		ended = true
		activeSession = false
		currentSessionId = nil
		if inputConn then
			inputConn:Disconnect()
			inputConn = nil
		end
		if tapConn then
			tapConn:Disconnect()
			tapConn = nil
		end
		if runConn then
			runConn:Disconnect()
			runConn = nil
		end

		for _, p in ipairs(currentPeas) do
			if p.instance and p.instance.Parent then
				p.instance:Destroy()
			end
		end
		currentPeas = {}

		if panel then
			panel.Visible = false
		end -- Hide panel on completion (AGENTS.md Rule 2)
	end

	-- Input Listener (Spacebar, Mobile Touch, Gamepad ButtonA/ButtonX)
	inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local isKeyboard = input.KeyCode == Enum.KeyCode.Space
		local isGamepad = input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.ButtonX
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		if isKeyboard or isGamepad or isTouch then
			handleHitInput()
		end
	end)

	-- On-Screen Tap Button Listener (Mobile / Mouse)
	tapConn = tButton.MouseButton1Click:Connect(function()
		handleHitInput()
	end)

	-- Heartbeat Loop for note animation & passive miss detection
	runConn = RunService.Heartbeat:Connect(function()
		if ended then
			return
		end
		local now = os.clock()
		local elapsed = now - startTime

		-- Spawn notes
		if notesSpawned < totalNotesToSpawn and (now - lastSpawnTime >= peaSpawnInterval or notesSpawned == 0) then
			notesSpawned = notesSpawned + 1
			lastSpawnTime = now
			table.insert(currentPeas, createPea(track, now, notesSpawned))
		end

		-- Move active notes & handle passive misses
		for i = #currentPeas, 1, -1 do
			local pea = currentPeas[i]
			if not pea.hit and not pea.missed then
				local peaElapsed = now - pea.spawnTime
				local progress = peaElapsed / PEA_CONFIG.fallDuration

				if progress >= 1.2 then
					-- Passive Miss: Note fell past hit zone without input
					pea.missed = true
					comboCount = 0
					currentScore.miss = (currentScore.miss or 0) + 1
					spawnFloatingRating("MISS!", Color3.fromRGB(255, 80, 80), panel)
					-- FIX: Send the actual note index number, not the string "miss".
					-- The server (CookingService.hit) expects (player, sessionId, noteIndex)
					-- where noteIndex is a number. A string causes server-side errors.
					-- Server will treat a note as missed if its timing window expires.
					-- Do NOT send a miss event — the server detects misses autonomously.
					-- Only send notes that the player actually interacted with.

					if pea.instance and pea.instance.Parent then
						pea.instance:Destroy()
					end
				else
					local yPos = progress * track.AbsoluteSize.Y
					pea.instance.Position = UDim2.new(0.5, -14, 0, yPos - 14)
				end
			end
		end

		if cLabel then
			cLabel.Text = string.format("Combo: %d | Max: %d", comboCount, maxComboCount)
		end

		-- Session Completion Check
		if
			elapsed >= totalSessionDuration
			or (
				notesSpawned >= totalNotesToSpawn
				and #currentPeas > 0
				and (now - currentPeas[#currentPeas].spawnTime >= PEA_CONFIG.fallDuration + 0.5)
			)
		then
			cleanup()

			-- Server derives authoritative quality from note timing.
			-- Client provides a rough display-quality for the callback UI.
			local displayQuality = "ok"
			local perfectRatio = (currentScore.perfect or 0) / math.max(totalNotesToSpawn, 1)
			if perfectRatio >= 0.8 then
				displayQuality = "perfect"
			elseif perfectRatio >= 0.5 then
				displayQuality = "great"
			end

			if onComplete then
				onComplete(displayQuality, currentScore, maxComboCount)
			end
		end
	end)
end

function CookingController.isCooking(): boolean
	return activeSession
end

-- Export for backward compatibility & global access
_G.TimedCooking = CookingController
_G.CookingController = CookingController

return CookingController
