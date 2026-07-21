-- [[Script] BuildingManager (ref: RBX8D1C699D642B43A195BB0660459E24CA)]]
-- BuildingManager: Handles building entry/exit mechanics
-- Manages door clicks and interior teleportation with fade animations

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BuildingConfig = require(game.ReplicatedStorage.ConfigurationFiles.BuildingConfig)

-- Configuration
local FADE_DURATION = 0.25
local DOOR_SWING_DURATION = 0.3
local INTERIOR_SPAWN_OFFSET = Vector3.new(0, 3, -8)

-- Build BUILDINGS table from config
local BUILDINGS = {}
for buildingName, buildingData in pairs(BuildingConfig) do
    for _, doorData in pairs(buildingData.doors) do
        BUILDINGS[doorData.name] = {
            interiorFolder = buildingData.interiorFolder,
            interiorSpawnPos = doorData.interiorSpawnPos,
            exteriorReturnPos = doorData.exteriorReturnPos,
            doorParts = {doorData.name},  -- Can expand to include glass parts
            buildingName = buildingName,
            displayName = buildingData.name,
        }
    end
end

-- Store player states
local playerStates = {}

-- Function to fade player in/out
local function fadePlayer(humanoidRootPart, fadeOut)
    local targetTransparency = fadeOut and 1 or 0
    local tweenInfo = TweenInfo.new(
        FADE_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    
    -- Tween character parts
    for _, part in pairs(humanoidRootPart.Parent:GetDescendants()) do
        if part:IsA("BasePart") then
            local tween = TweenService:Create(part, tweenInfo, {Transparency = targetTransparency})
            tween:Play()
        end
    end
end

-- Function to animate door swinging
local function animateDoor(doorPart, isOpening)
    if not doorPart then return end
    
    local targetRotation = isOpening and math.rad(90) or 0
    local tweenInfo = TweenInfo.new(
        DOOR_SWING_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    
    -- Get current CFrame and rotate around Y-axis (hinge)
    local currentCFrame = doorPart.CFrame
    local targetCFrame = currentCFrame * CFrame.Angles(0, targetRotation, 0)
    
    local tween = TweenService:Create(doorPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
end

-- Function to teleport player to interior or exterior
local function teleportPlayer(player, doorName, isEntering)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local buildingData = BUILDINGS[doorName]
    if not buildingData then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    
    -- Start door opening animation
    for _, doorPartName in pairs(buildingData.doorParts) do
        local doorPart = workspace:FindFirstChild(doorPartName, true)
        if doorPart then
            animateDoor(doorPart, true)
        end
    end
    
    -- Fade out player
    fadePlayer(humanoidRootPart, true)
    
    -- Wait for fade
    task.wait(FADE_DURATION)
    
    -- Teleport player
    if isEntering then
        local interiorFolder = game.Workspace.BuildingInteriors:FindFirstChild(buildingData.interiorFolder)
        if interiorFolder then
            -- Hide exterior building
            playerStates[player.UserId] = {
                isInInterior = true,
                buildingName = doorName,
                exteriorPosition = humanoidRootPart.Position
            }
            
            -- Teleport to interior
            humanoidRootPart.CFrame = CFrame.new(buildingData.interiorSpawnPos + Vector3.new(0, 3, 0))
        end
    else
        -- Return to exterior
        local returnPos = buildingData.exteriorReturnPos
        humanoidRootPart.CFrame = CFrame.new(returnPos + Vector3.new(0, 3, 0))
        playerStates[player.UserId] = {isInInterior = false}
    end
    
    -- Wait for teleport to process
    task.wait(0.1)
    
    -- Fade in player
    fadePlayer(humanoidRootPart, false)
    
    -- Close door after fade completes
    task.wait(FADE_DURATION)
    for _, doorPartName in pairs(buildingData.doorParts) do
        local doorPart = workspace:FindFirstChild(doorPartName, true)
        if doorPart then
            animateDoor(doorPart, false)
        end
    end
end

-- Setup door click detectors
local function setupDoorClickDetector(doorName)
    local doorPart = workspace:FindFirstChild(doorName, true)
    if not doorPart then
        print("⚠ Door not found: " .. doorName)
        return
    end
    
    -- Create or get ClickDetector
    local clickDetector = doorPart:FindFirstChild("ClickDetector")
    if not clickDetector then
        clickDetector = Instance.new("ClickDetector")
        clickDetector.Parent = doorPart
    end
    
    clickDetector.MaxActivationDistance = 30
    
    -- Connect click event
    clickDetector.MouseClick:Connect(function(player)
        local isInInterior = playerStates[player.UserId] and playerStates[player.UserId].isInInterior
        teleportPlayer(player, doorName, not isInInterior)
    end)
    
    print("✓ Setup door: " .. doorName)
end

-- Initialize all doors
for doorName, _ in pairs(BUILDINGS) do
    setupDoorClickDetector(doorName)
end

print("✓ BuildingManager initialized")

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
    playerStates[player.UserId] = nil
end)