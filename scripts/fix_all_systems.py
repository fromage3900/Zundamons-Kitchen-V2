#!/usr/bin/env python3
"""Fix all systems: companion rig, sound IDs, NPC roaming, loading screen, sound preload."""

import os

# ============================================================
# 1. Update CompanionManager - zundapal rig + Humanoid follow
# ============================================================
fp = "src/server/CompanionManager.server.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

# Update zundapal mesh ID to the new rig
c = c.replace(
    'zundapal   = "rbxassetid://81331860128238"',
    'zundapal   = "rbxassetid://71161704530283"'
)

# Update the in-world model check to also look for zundapalupdate4
c = c.replace(
    'local worldModel = workspace:FindFirstChild("zundapalupdate2")',
    'local worldModel = workspace:FindFirstChild("zundapalupdate2") or workspace:FindFirstChild("zundapalupdate4")'
)

# Replace the velocity-based follow with Humanoid-based animated follow
old_follow = """-- Smooth follow loop
    task.spawn(function()
        print(\"[CompanionManager.follow] Starting follow loop for\", player.Name)
        local t = 0
        while body and body.Parent and companionModel.Parent do
            t = t + 0.05
            local char2 = player.Character
            local hrp2  = char2 and char2:FindFirstChild(\"HumanoidRootPart\")
            if hrp2 then
                local floatY  = math.sin(t * 1.1) * 0.7 + 1.8
                local sideOff = hrp2.CFrame.RightVector * (3.5 + math.sin(t * 0.3) * 0.4)
                local target  = hrp2.Position + sideOff + Vector3.new(0, floatY, 0)
                local dist    = (body.Position - target).Magnitude
                if dist > 0.3 then
                    body.AssemblyLinearVelocity = (target - body.Position).Unit * math.min(dist * 5, 35)
                end
            end
            task.wait(0.05)
        end
        print(\"[CompanionManager.follow] Follow loop ended for\", player.Name)
    end)"""

new_follow = """-- Animated follow loop (Humanoid-based for rigged models, velocity fallback for simple meshes)
    task.spawn(function()
        print(\"[CompanionManager.follow] Starting follow loop for\", player.Name)
        local t = 0
        local humanoid = companionModel:FindFirstChildWhichIsA(\"Humanoid\")
        local isRigged = humanoid ~= nil
        if isRigged then
            print(\"[CompanionManager.follow] Using Humanoid-based animated follow for\", player.Name)
            humanoid.AutoRotate = true
            humanoid.PlatformStand = false
        end
        while body and body.Parent and companionModel.Parent do
            t = t + 0.05
            local char2 = player.Character
            local hrp2  = char2 and char2:FindFirstChild(\"HumanoidRootPart\")
            if hrp2 then
                local floatY  = math.sin(t * 1.1) * 0.7 + 1.8
                local sideOff = hrp2.CFrame.RightVector * (3.5 + math.sin(t * 0.3) * 0.4)
                local target  = hrp2.Position + sideOff + Vector3.new(0, floatY, 0)
                local dist    = (body.Position - target).Magnitude
                if dist > 0.3 then
                    if isRigged and humanoid and humanoid.Parent then
                        -- Animated walking for rigged models
                        humanoid:MoveTo(target)
                        humanoid.MoveToFinished:Wait(0.1)
                    else
                        -- Velocity-based floating for simple meshes
                        body.AssemblyLinearVelocity = (target - body.Position).Unit * math.min(dist * 5, 35)
                    end
                elseif isRigged and humanoid and humanoid.Parent then
                    humanoid:MoveTo(body.Position) -- Stop moving
                end
            end
            task.wait(0.05)
        end
        print(\"[CompanionManager.follow] Follow loop ended for\", player.Name)
    end)"""

c = c.replace(old_follow, new_follow, 1)

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[CompanionManager] Updated zundapal rig ID, added Humanoid-based animated follow")

# ============================================================
# 2. Update SoundConfig with known IDs
# ============================================================
fp = "src/shared/ConfigurationFiles/SoundConfig.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

# Replace the empty strings with known IDs
c = c.replace(
    'PanelOpen = "",        -- e.g. "rbxassetid://1234567890"',
    'PanelOpen = "rbxassetid://88676882150135",  -- First SFX'
)
c = c.replace(
    'PanelClose = "",',
    'PanelClose = "rbxassetid://88676882150135",  -- Reuse first SFX for close'
)
c = c.replace(
    'ButtonClick = "",',
    'ButtonClick = "rbxassetid://88676882150135",  -- Reuse first SFX for click'
)
c = c.replace(
    'WheelOpen = "",',
    'WheelOpen = "rbxassetid://88676882150135",  -- Reuse first SFX for wheel'
)
c = c.replace(
    'WheelSelect = "",',
    'WheelSelect = "rbxassetid://88676882150135",  -- Reuse first SFX for select'
)
c = c.replace(
    'Notification = "",',
    'Notification = "rbxassetid://88676882150135",  -- Reuse first SFX for notification'
)
c = c.replace(
    'Sparkle = "",',
    'Sparkle = "rbxassetid://88676882150135",  -- Reuse first SFX for sparkle'
)
c = c.replace(
    'LevelUp = "",',
    'LevelUp = "rbxassetid://88676882150135",  -- Reuse first SFX for level up'
)
c = c.replace(
    'QuestComplete = "",',
    'QuestComplete = "rbxassetid://88676882150135",  -- Reuse first SFX for quest'
)
c = c.replace(
    'CoinEarn = "",',
    'CoinEarn = "rbxassetid://88676882150135",  -- Reuse first SFX for coin'
)

# Add ambient loop
c = c.replace(
    "-- Custom sound IDs (replace with uploaded Roblox asset IDs when available)",
    '-- Ambient loop (background music)\n\tAmbientLoop = "rbxassetid://87341474417325",\n\n\t-- Custom sound IDs (replace with uploaded Roblox asset IDs when available)'
)

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[SoundConfig] Updated with known asset IDs")

# ============================================================
# 3. Wire NPCPatrolSystem into GuestManager for roaming
# ============================================================
fp = "src/server/GuestManager.server.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

old_guest_create_end = """\t-- Parent to Guests folder
\tguest.Parent = GUEST_SPAWN_FOLDER

\tprint(\"[GuestManager] Spawned guest \" .. guest.Name .. \" for \" .. player.Name .. \" wanting \" .. recipe)

\treturn guest
end"""

new_guest_create_end = """\t-- Assign personality type for roaming behavior
\tlocal personalityTypes = {\"stationary\", \"roamer\", \"patrol\"}
\tlocal personalityWeights = {0.4, 0.35, 0.25} -- 40% stationary, 35% roamer, 25% patrol
\tlocal roll = math.random()
\tlocal cumulative = 0
\tlocal personality = \"stationary\"
\tfor i, pType in ipairs(personalityTypes) do
\t\tcumulative = cumulative + personalityWeights[i]
\t\tif roll <= cumulative then
\t\t\tpersonality = pType
\t\t\tbreak
\t\tend
\tend
\tguest:SetAttribute(\"Personality\", personality)

\t-- If roamer or patrol, start roaming behavior
\tif personality ~= \"stationary\" then
\t\ttask.spawn(function()
\t\t\tlocal NPCPatrolSystem = require(game:GetService(\"ServerScriptService\").NPCPatrolSystem)
\t\t\tif NPCPatrolSystem and NPCPatrolSystem.startGuestRoaming then
\t\t\t\tNPCPatrolSystem.startGuestRoaming(guest, personality)
\t\t\tend
\t\tend)
\tend

\t-- Parent to Guests folder
\tguest.Parent = GUEST_SPAWN_FOLDER

\tprint(\"[GuestManager] Spawned guest \" .. guest.Name .. \" for \" .. player.Name .. \" wanting \" .. recipe .. \" (personality: \" .. personality .. \")\")

\treturn guest
end"""

c = c.replace(old_guest_create_end, new_guest_create_end, 1)

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[GuestManager] Added personality-based roaming")

# ============================================================
# 4. Update NPCPatrolSystem with guest roaming support
# ============================================================
fp = "src/server/NPCPatrolSystem.server.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

old_spawn = "local function spawnPatrolNPCs()"

new_spawn = """-- Guest roaming: move a guest NPC within a radius or between waypoints
local function guestRoamLoop(guest, personality)
\tlocal torso = guest:FindFirstChild(\"Torso\")
\tif not torso then return end
\tlocal spawnPos = torso.Position
\tlocal waypoints = getWaypoints()
\t
\twhile guest and guest.Parent and torso.Parent do
\t\tif personality == \"roamer\" then
\t\t\t-- Wander within a 12-stud radius of spawn
\t\t\tlocal angle = math.random() * 2 * math.pi
\t\t\tlocal radius = math.random(3, 12)
\t\t\tlocal target = spawnPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
\t\t\tmoveToWaypoint(guest, target, 3)
\t\t\ttask.wait(math.random(4, 10))
\t\telseif personality == \"patrol\" and #waypoints > 0 then
\t\t\t-- Follow patrol waypoints
\t\t\tlocal wp = waypoints[math.random(1, #waypoints)]
\t\t\tmoveToWaypoint(guest, wp, 4)
\t\t\ttask.wait(math.random(5, 12))
\t\tend
\t\ttask.wait(1)
\tend
end

-- Expose for GuestManager
local NPCPatrolSystem = {}
NPCPatrolSystem.startGuestRoaming = function(guest, personality)
\ttask.spawn(function()
\t\tguestRoamLoop(guest, personality)
\tend)
end

local function spawnPatrolNPCs()"""

c = c.replace(old_spawn, new_spawn, 1)

# Add return at end
c = c.rstrip() + "\n\nreturn NPCPatrolSystem\n"

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[NPCPatrolSystem] Added guest roaming support")

# ============================================================
# 5. Create loading screen script
# ============================================================
loading_screen = """-- [[LocalScript] LoadingScreen.client.lua]]
-- Shows Zundamon loading screen with the Zunda Zunda Night Fever image
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create loading screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Background
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
bg.BorderSizePixel = 0
bg.Parent = screenGui

-- Loading image (Zundamon art)
local image = Instance.new("ImageLabel")
image.Size = UDim2.new(0.8, 0, 0.6, 0)
image.Position = UDim2.new(0.1, 0, 0.1, 0)
image.BackgroundTransparency = 1
image.Image = "rbxassetid://85484093250844"
image.ScaleType = Enum.ScaleType.Fit
image.Parent = bg

-- Loading text
local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(1, 0, 0, 40)
loadingText.Position = UDim2.new(0, 0, 0.75, 0)
loadingText.BackgroundTransparency = 1
loadingText.Text = "Zunda Zunda Night Fever..."
loadingText.TextColor3 = Color3.fromRGB(200, 200, 255)
loadingText.TextSize = 24
loadingText.Font = Enum.Font.FredokaOne
loadingText.Parent = bg

-- Loading bar background
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.6, 0, 0, 8)
barBg.Position = UDim2.new(0.2, 0, 0.82, 0)
barBg.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
barBg.BorderSizePixel = 0
barBg.Parent = bg
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

-- Loading bar fill
local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(160, 210, 150)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- Animate loading bar
local tweenService = game:GetService("TweenService")
local tween = tweenService:Create(barFill, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(1, 0, 1, 0)
})
tween:Play()

-- Remove loading screen after characters load
local function onCharacterAdded(char)
    task.wait(1.5)
    tweenService:Create(screenGui, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.5)
    screenGui:Destroy()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

print("[LoadingScreen] Zunda Zunda Night Fever loading screen active")
"""

with open("src/client/LoadingScreen.client.lua", "w", encoding="utf-8") as f:
    f.write(loading_screen)
print("[LoadingScreen] Created")

# ============================================================
# 6. Wire sound preload into PeaWheelBootstrap
# ============================================================
fp = "src/client/PeaWheelBootstrap.client.lua"
with open(fp, "r", encoding="utf-8", errors="replace") as f:
    c = f.read()

old_end = 'print("[PeaWheelBootstrap] Pea Wheel UI ready")'
new_end = """-- Preload Zunda sound effects
local ZundaSoundController = require(RS.ConfigurationFiles.SoundConfig)
if _G.ZundaSoundController and _G.ZundaSoundController.preload then
    _G.ZundaSoundController.preload()
end

print("[PeaWheelBootstrap] Pea Wheel UI ready")"""

c = c.replace(old_end, new_end, 1)

with open(fp, "w", encoding="utf-8") as f:
    f.write(c)
print("[PeaWheelBootstrap] Added sound preload")

print("\n=== ALL SYSTEMS UPDATED SUCCESSFULLY ===")
print("\nRemaining: You need to provide the other 23 sound file asset IDs")
print("to fully populate SoundConfig.CustomSounds for each UI action.")