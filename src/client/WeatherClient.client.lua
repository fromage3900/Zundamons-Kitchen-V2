-- [[LocalScript] WeatherClient (ref: RBX7A8A7582C4624D43B158D538B49B59A2)]]
-- WeatherClient: spawns weather particles in a follow-the-camera emitter.
-- Receives WeatherChanged from the server and updates emitter properties.

local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Tween      = game:GetService("TweenService")

local player = Players.LocalPlayer
local cam    = workspace.CurrentCamera

local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local WeatherRE = RS:WaitForChild("RemoteEvents"):WaitForChild("WeatherChanged")

-- ============================================================
-- Build an invisible "emitter rig" that follows the camera.
-- The emitter spawns particles above the player so they fall through.
-- ============================================================
local rig = Instance.new("Part")
rig.Name = "WeatherEmitterRig"
rig.Size = Vector3.new(60, 1, 60)   -- wide spawn area
rig.Transparency = 1
rig.Anchored = true
rig.CanCollide = false
rig.CanQuery = false
rig.CanTouch = false
rig.Massless = true
rig.Parent = workspace

local emitter = Instance.new("ParticleEmitter")
emitter.Name = "WeatherParticles"
emitter.Enabled = false
emitter.Rate = 0
emitter.Speed = NumberRange.new(8)
emitter.Lifetime = NumberRange.new(4)
emitter.Texture = "rbxasset://textures/particles/leaf.png"
emitter.LightEmission = 0.1
emitter.Acceleration = Vector3.new(0, -5, 0)
emitter.Rotation = NumberRange.new(0, 360)
emitter.RotSpeed = NumberRange.new(-90, 90)
emitter.SpreadAngle = Vector2.new(20, 20)
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Parent = rig

-- Per-weather ambient sound (rain / wind etc.)
local UIAssets = require(RS.Shared.Config.UIAssets)
local function resolveWeatherSound(key)
    local id = UIAssets.sounds[key]
    if id and not UIAssets.isPlaceholder(id) then return id end
    return UIAssets.sounds.harvest_start
end
local WEATHER_SOUNDS = {
    rain         = resolveWeatherSound("rain"),
    storm        = resolveWeatherSound("storm"),
    snow         = resolveWeatherSound("snow"),
    cherry_blossom = resolveWeatherSound("cherry_blossom"),
    aurora       = resolveWeatherSound("aurora"),
    fog          = resolveWeatherSound("fog"),
}
local ambient = Instance.new("Sound")
ambient.Name = "WeatherSound"
ambient.Looped = true
ambient.Volume = 0
ambient.Parent = rig

-- Aurora frame (full-screen colored overlay, used for aurora weather only)
local sg = player:WaitForChild("PlayerGui")
local auroraGui = Instance.new("ScreenGui")
auroraGui.Name = "AuroraOverlay"
auroraGui.IgnoreGuiInset = true
auroraGui.DisplayOrder = -10
auroraGui.ResetOnSpawn = false
auroraGui.Parent = sg

-- Lightning flash overlay (used during rain/storm at random)
local lightningFrame = Instance.new("Frame", auroraGui)
lightningFrame.Name = "LightningFlash"
lightningFrame.Size = UDim2.new(1, 0, 1, 0)
lightningFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
lightningFrame.BackgroundTransparency = 1
lightningFrame.BorderSizePixel = 0
lightningFrame.ZIndex = -8
lightningFrame.Visible = true

local auroraFrame = Instance.new("Frame", auroraGui)
auroraFrame.Size = UDim2.new(1, 0, 0.45, 0)
auroraFrame.Position = UDim2.new(0, 0, 0, 0)
auroraFrame.BackgroundColor3 = Color3.fromRGB(120, 220, 180)
auroraFrame.BackgroundTransparency = 1
auroraFrame.BorderSizePixel = 0
auroraFrame.ZIndex = -10
local auroraGrad = Instance.new("UIGradient", auroraFrame)
auroraGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 200, 180)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 130, 230)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 140, 200)),
})
auroraGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.5),
    NumberSequenceKeypoint.new(1, 1),
})
auroraGrad.Rotation = 0

-- ============================================================
-- Camera follow loop — keep rig above the camera so particles "fall" onto the player
-- ============================================================
RunService.RenderStepped:Connect(function()
    if cam then
        local p = cam.CFrame.Position
        rig.CFrame = CFrame.new(p.X, p.Y + 35, p.Z)
    end
end)

-- Cam can change (e.g. CharacterAdded) so reassign
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    cam = workspace.CurrentCamera
end)

-- ============================================================
-- Weather handler — switches emitter properties
-- ============================================================
local currentSpin
local function applyWeather(weatherKey, weatherData, transitionSec)
    transitionSec = transitionSec or 0.5

    -- Aurora special-case: animate the gradient at night
    if weatherKey == "aurora" then
        Tween:Create(auroraGrad, TweenInfo.new(transitionSec), {Rotation = 30}):Play()
        Tween:Create(auroraFrame, TweenInfo.new(transitionSec), {BackgroundTransparency = 0.3}):Play()
    else
        Tween:Create(auroraFrame, TweenInfo.new(transitionSec), {BackgroundTransparency = 1}):Play()
    end

    -- Update particle emitter
    if not weatherData.particle_enabled then
        -- Fade rate to 0 then disable
        Tween:Create(emitter, TweenInfo.new(transitionSec), {Rate = 0}):Play()
        task.delay(transitionSec, function()
            if not weatherData.particle_enabled then
                emitter.Enabled = false
            end
        end)
    else
        emitter.Texture        = weatherData.particle_texture
        emitter.Color          = ColorSequence.new({
            ColorSequenceKeypoint.new(0, weatherData.particle_color),
            ColorSequenceKeypoint.new(1, weatherData.particle_color2 or weatherData.particle_color),
        })
        emitter.Size           = NumberSequence.new(weatherData.particle_size or 1)
        emitter.Lifetime       = NumberRange.new(weatherData.particle_lifetime or 4)
        emitter.Speed          = NumberRange.new(weatherData.particle_speed or 8)
        -- Apply wind via Acceleration X/Z
        local wind = weatherData.wind or Vector3.new(0, 0, 0)
        emitter.Acceleration   = Vector3.new(wind.X, -math.max(5, weatherData.particle_speed or 8), wind.Z)
        emitter.Transparency   = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Enabled = true
        Tween:Create(emitter, TweenInfo.new(transitionSec), {Rate = weatherData.particle_rate}):Play()
    end
end

-- Lightning flash routine: fires a quick double-strobe during storm/rain only
local currentWeatherKey = "clear"
local thunderSound = Instance.new("Sound", rig)
thunderSound.SoundId = UIAssets.sounds.harvest_complete
thunderSound.Volume = 0.4

local function lightningStrobe()
    lightningFrame.BackgroundTransparency = 0.2
    task.wait(0.06)
    lightningFrame.BackgroundTransparency = 0.7
    task.wait(0.08)
    lightningFrame.BackgroundTransparency = 0.05
    task.wait(0.05)
    Tween:Create(lightningFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
    task.wait(math.random(2, 5) * 0.1)
    pcall(function() thunderSound:Play() end)
end

task.spawn(function()
    while true do
        task.wait(math.random(8, 25))
        if currentWeatherKey == "storm" then
            lightningStrobe()
        elseif currentWeatherKey == "rain" and math.random() < 0.25 then
            lightningStrobe()
        end
    end
end)

-- Storm = stronger rain + camera shake
local stormShakeConn
local function setStormShake(active)
    if stormShakeConn then stormShakeConn:Disconnect(); stormShakeConn = nil end
    if not active then return end
    local baseCFrame = cam and cam.CFrame
    if not baseCFrame then return end
    stormShakeConn = RunService.RenderStepped:Connect(function()
        if cam then
            local jitX = (math.random() - 0.5) * 0.06
            local jitY = (math.random() - 0.5) * 0.06
            cam.CFrame = baseCFrame * CFrame.new(jitX, jitY, 0)
        end
    end)
end

local originalApplyWeather = applyWeather
applyWeather = function(weatherKey, weatherData, transitionSec)
    currentWeatherKey = weatherKey
    originalApplyWeather(weatherKey, weatherData, transitionSec)
    -- Audio swap
    local newSound = WEATHER_SOUNDS[weatherKey]
    if newSound then
        if ambient.SoundId ~= newSound then
            ambient.SoundId = newSound
            ambient:Play()
        end
        Tween:Create(ambient, TweenInfo.new(transitionSec or 0.5), { Volume = (weatherKey == "storm") and 0.5 or 0.25 }):Play()
    else
        Tween:Create(ambient, TweenInfo.new(transitionSec or 0.5), { Volume = 0 }):Play()
    end
    -- Storm shake
    setStormShake(weatherKey == "storm")
end

WeatherRE.OnClientEvent:Connect(applyWeather)

-- ============================================================
-- Optional: weather indicator chip in top-right HUD
-- ============================================================
local hud = sg:WaitForChild("ZundaHUD", 10)
if hud then
    local statBar = hud:FindFirstChild("StatBar")
    if statBar then
        local existing = statBar:FindFirstChild("WeatherPill")
        if not existing then
            local pill = Instance.new("Frame", statBar)
            pill.Name = "WeatherPill"
            pill.Size = UDim2.new(0, 150, 0, 30)
            pill.Position = UDim2.new(0, 116, 0, 52)
            pill.BackgroundColor3 = Color3.fromRGB(245, 210, 215)
            pill.BorderSizePixel = 0
            local cr = Instance.new("UICorner", pill); cr.CornerRadius = UDim.new(0, 15)
            local st = Instance.new("UIStroke", pill); st.Thickness = 1.5
            st.Color = UIConfig.GAME_COLORS.HUDText; st.Transparency = 0.4
            local lbl = Instance.new("TextLabel", pill)
            lbl.Name = "WeatherText"
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "\u{2600}\u{FE0F} Clear"
            lbl.Font = Enum.Font.FredokaOne
            lbl.TextColor3 = UIConfig.COLORS.TextDark
            lbl.TextSize = 14

            -- Listen for weather changes and update label
            WeatherRE.OnClientEvent:Connect(function(_, wData)
                lbl.Text = (wData.emoji or "") .. " " .. (wData.display_name or "")
            end)
        end
    end
end

print("[WeatherClient] Ready - listening for weather updates")