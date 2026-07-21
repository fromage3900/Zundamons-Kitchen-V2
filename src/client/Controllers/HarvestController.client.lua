--!strict
-- [[LocalScript] HarvestController (ref: NEW)]]
-- Client-side harvest interaction: progress bar, cancel-on-move, animations, sounds, particles.
-- Works alongside existing ZundaGatherServer / Planters / Mineable systems.
-- Place in StarterPlayer > StarterPlayerScripts > Controllers

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load config
local configModule = ReplicatedStorage:FindFirstChild("ConfigurationFiles")
	and ReplicatedStorage.ConfigurationFiles:FindFirstChild("HarvestConfig")
local Config = configModule and require(configModule) or nil

-- Fallback defaults if config not found
local MAX_DISTANCE = Config and Config.MAX_INTERACTION_DISTANCE or 16
local HARVEST_DURATION = Config and Config.HARVEST_DURATION or 2.5
local MOVE_THRESHOLD = Config and Config.MOVE_CANCEL_THRESHOLD or 1.5
local ANIMATION_ID = Config and Config.HARVEST_ANIMATION_ID or ""
local SOUND_ID = Config and Config.HARVEST_SOUND_ID or ""
local SOUND_VOLUME = Config and Config.HARVEST_SOUND_VOLUME or 0.6
local PARTICLE_COLOR = Config and Config.HARVEST_PARTICLE_COLOR or Color3.fromRGB(180, 230, 120)
local PARTICLE_COUNT = Config and Config.HARVEST_PARTICLE_COUNT or 8
local PARTICLE_SPEED = Config and Config.HARVEST_PARTICLE_SPEED or 8
local PARTICLE_LIFETIME = Config and Config.HARVEST_PARTICLE_LIFETIME or 1.2

-- State
local isHarvesting = false
local harvestStartTime = 0
local harvestTargetNode = nil
local harvestStartPosition = nil
local currentTween = nil
local progressBar = nil
local progressFill = nil
local progressContainer = nil
local harvestAnimTrack = nil
local harvestSound = nil
local particleEmitter = nil

-- Create progress bar UI
local function createProgressBar()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HarvestProgressGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	progressContainer = Instance.new("Frame")
	progressContainer.Name = "HarvestProgressContainer"
	progressContainer.Size = UDim2.new(0, 200, 0, 24)
	progressContainer.Position = UDim2.new(0.5, -100, 0.5, 50)
	progressContainer.BackgroundColor3 = UIConfig.COLORS.Background
	progressContainer.BackgroundTransparency = 0.3
	progressContainer.BorderSizePixel = 0
	progressContainer.Visible = false
	progressContainer.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = progressContainer

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = UIConfig.COLORS.PanelBorder
	uiStroke.Thickness = 2
	uiStroke.Parent = progressContainer

	progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(0, 0, 1, -4)
	progressFill.Position = UDim2.new(0, 2, 0, 2)
	progressFill.BackgroundColor3 = UIConfig.COLORS.Success
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressContainer

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = progressFill

	local label = Instance.new("TextLabel")
	label.Name = "ActionLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Harvesting..."
	label.TextColor3 = UIConfig.GAME_COLORS.HUDText
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = progressContainer
end

-- Create particle emitter on a part
local function createHarvestParticles(position: Vector3)
	local part = Instance.new("Part")
	part.Name = "HarvestFX"
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = PARTICLE_COUNT
	emitter.Lifetime = NumberRange.new(PARTICLE_LIFETIME * 0.5, PARTICLE_LIFETIME)
	emitter.Speed = NumberRange.new(PARTICLE_SPEED * 0.5, PARTICLE_SPEED)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.Drag = 5
	emitter.Color = ColorSequence.new(PARTICLE_COLOR)
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Transparency = NumberSequence.new(0.3, 1)
	emitter.Texture = "rbxassetid://2846894023" -- Generic sparkle
	emitter.Enabled = true
	emitter.Parent = part

	task.delay(PARTICLE_LIFETIME + 0.5, function()
		emitter.Enabled = false
		task.delay(2, function()
			part:Destroy()
		end)
	end)

	return emitter
end

-- Play harvest sound
local function playHarvestSound(position: Vector3)
	local sound = Instance.new("Sound")
	sound.Name = "HarvestSFX"
	sound.SoundId = SOUND_ID
	sound.Volume = SOUND_VOLUME
	sound.Pitch = math.random(90, 110) / 100
	sound.Parent = workspace
	sound.Position = position
	sound:Play()

	task.delay(sound.TimeLength + 0.5, function()
		sound:Destroy()
	end)

	return sound
end

-- Play harvest animation on character
local function playHarvestAnimation()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = ANIMATION_ID

	local track = animator:LoadAnimation(anim)
	if track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		harvestAnimTrack = track
	end
end

-- Stop harvest animation
local function stopHarvestAnimation()
	if harvestAnimTrack then
		harvestAnimTrack:Stop()
		harvestAnimTrack:Destroy()
		harvestAnimTrack = nil
	end
end

-- Show progress bar
local function showProgressBar()
	if not progressContainer then createProgressBar() end
	progressContainer.Visible = true
	progressFill.Size = UDim2.new(0, 0, 1, -4)
end

-- Update progress bar
local function updateProgressBar(progress: number)
	if not progressFill then return end
	local clampedProgress = math.clamp(progress, 0, 1)
	local width = (progressContainer.AbsoluteSize.X - 4) * clampedProgress
	progressFill.Size = UDim2.new(0, width, 1, -4)
end

-- Hide progress bar
local function hideProgressBar()
	if progressContainer then
		progressContainer.Visible = false
	end
	progressFill.Size = UDim2.new(0, 0, 1, -4)
end

-- Check if player moved too far from start position
local function hasMovedTooFar(): boolean
	if not harvestStartPosition then return false end
	local character = player.Character
	if not character then return true end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return true end
	local distance = (rootPart.Position - harvestStartPosition).Magnitude
	return distance > MOVE_THRESHOLD
end

-- Check distance to target node
local function isInRange(node: Instance): boolean
	local character = player.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local distance = (rootPart.Position - node.Position).Magnitude
	return distance <= MAX_DISTANCE
end

-- Cancel current harvest
local function cancelHarvest(reason: string?)
	if not isHarvesting then return end
	isHarvesting = false
	harvestTargetNode = nil
	harvestStartPosition = nil

	hideProgressBar()
	stopHarvestAnimation()

	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	if reason then
		warn("[HarvestController] Harvest cancelled: " .. reason)
	end
end

-- Complete harvest
local function completeHarvest()
	if not isHarvesting or not harvestTargetNode then return end
	isHarvesting = false

	hideProgressBar()
	stopHarvestAnimation()

	-- Play effects at node position
	createHarvestParticles(harvestTargetNode.Position)
	playHarvestSound(harvestTargetNode.Position)

	-- Fire the existing ClickDetector or RemoteEvent
	-- The existing ZundaGatherServer/Planters handle the actual loot via ClickDetector
	local clickDetector = harvestTargetNode:FindFirstChildOfClass("ClickDetector")
	if clickDetector then
		-- Simulate click to trigger existing server logic
		clickDetector:MouseClick(player)
	end

	harvestTargetNode = nil
	harvestStartPosition = nil
end

-- Start harvest on a node
local function startHarvest(node: Instance)
	if isHarvesting then
		cancelHarvest("New harvest started")
	end

	if not isInRange(node) then
		warn("[HarvestController] Node out of range")
		return
	end

	isHarvesting = true
	harvestTargetNode = node
	harvestStartPosition = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or nil

	showProgressBar()
	playHarvestAnimation()
	playHarvestSound(node.Position)
	createHarvestParticles(node.Position)

	-- Animate progress bar
	local startTime = tick()
	local duration = HARVEST_DURATION

	-- Use a heartbeat connection for smooth progress
	local heartbeatConn
	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not isHarvesting then
			if heartbeatConn then heartbeatConn:Disconnect() end
			return
		end

		-- Check if moved too far
		if hasMovedTooFar() then
			cancelHarvest("Player moved too far")
			if heartbeatConn then heartbeatConn:Disconnect() end
			return
		end

		-- Check if still in range
		if not isInRange(node) then
			cancelHarvest("Node out of range")
			if heartbeatConn then heartbeatConn:Disconnect() end
			return
		end

		-- Check if node is still available
		if node:GetAttribute("Available") == false then
			cancelHarvest("Node no longer available")
			if heartbeatConn then heartbeatConn:Disconnect() end
			return
		end

		-- Update progress
		local elapsed = tick() - startTime
		local progress = elapsed / duration
		updateProgressBar(progress)

		-- Complete
		if elapsed >= duration then
			completeHarvest()
			if heartbeatConn then heartbeatConn:Disconnect() end
		end
	end)
end

-- Wire up ClickDetectors to use the harvest controller
local function bindNode(node: Instance)
	local clickDetector = node:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then return end

	-- Override the click to use our harvest system
	-- We connect to MouseClick but intercept it
	local originalClick = clickDetector.MouseClick
	clickDetector.MouseClick:Connect(function(clickingPlayer)
		if clickingPlayer ~= player then return end
		if isHarvesting then
			cancelHarvest("Re-clicked")
			return
		end
		startHarvest(node)
	end)
end

-- Scan for harvestable nodes
local function scanForNodes()
	-- Look for gathering nodes in GameplayLoopArea
	local loopArea = workspace:FindFirstChild("GameplayLoopArea")
	if loopArea then
		local gatherFolder = loopArea:FindFirstChild("GatheringNodes")
		if gatherFolder then
			for _, node in ipairs(gatherFolder:GetDescendants()) do
				if node:IsA("BasePart") and node:GetAttribute("ResourceType") then
					bindNode(node)
				end
			end
			-- Watch for new nodes
			gatherFolder.DescendantAdded:Connect(function(desc)
				task.wait(0.1)
				if desc:IsA("BasePart") and desc:GetAttribute("ResourceType") then
					bindNode(desc)
				end
			end)
		end
	end

	-- Also scan for CollectionService-tagged planters
	local CollectionService = game:GetService("CollectionService")
	for _, planter in ipairs(CollectionService:GetTagged("Planter")) do
		bindNode(planter)
	end
	CollectionService:GetInstanceAddedSignal("Planter"):Connect(bindNode)
end

-- Initialize
createProgressBar()
scanForNodes()

-- Cancel harvest if character dies
player.CharacterAdded:Connect(function()
	cancelHarvest("Character changed")
	-- Re-scan after character loads
	task.wait(1)
	scanForNodes()
end)

-- Cancel on key press (movement keys)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isHarvesting then
		local moveKeys = {
			[Enum.KeyCode.W] = true,
			[Enum.KeyCode.A] = true,
			[Enum.KeyCode.S] = true,
			[Enum.KeyCode.D] = true,
			[Enum.KeyCode.Space] = true,
			[Enum.KeyCode.LeftShift] = true,
		}
		if moveKeys[input.KeyCode] then
			cancelHarvest("Movement key pressed")
		end
	end
end)

print("[HarvestController] Loaded - polished harvest interactions active")