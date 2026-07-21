-- [[Script] DayNightSky (ref: RBX5AB97AB422564F3999B46F0548D33AA1)]]
-- DayNightSky: Realtime sky driven by SkyConfig.
-- 14 keyframes, smooth interpolation, dynamic exposure + volumetric cloud sync.

local Lighting = game:GetService("Lighting")
local Tween    = game:GetService("TweenService")
local CONFIG   = require(game.ReplicatedStorage.ConfigurationFiles.SkyConfig)

local function lerp(a, b, t) return a + (b - a) * t end
local function lerpColor(c1, c2, t)
    return Color3.new(lerp(c1.R,c2.R,t), lerp(c1.G,c2.G,t), lerp(c1.B,c2.B,t))
end

-- ──────────────────────────────────────────────────────────
-- Easing: smooth step for more painterly sky transitions
local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

local function getKeyframes(hour)
    local kf = CONFIG.keyframes
    for i = 1, #kf - 1 do
        local a, b = kf[i], kf[i+1]
        if hour >= a[1] and hour <= b[1] then
            local raw = (hour - a[1]) / (b[1] - a[1])
            return a, b, smoothstep(raw)
        end
    end
    return kf[#kf], kf[#kf], 0
end

-- ── STATIC LIGHTING CONFIG ────────────────────────────────
local L = CONFIG.lighting
Lighting.GlobalShadows            = L.global_shadows
Lighting.ShadowSoftness           = L.shadow_softness
Lighting.Brightness               = L.brightness
Lighting.EnvironmentDiffuseScale  = L.env_diffuse_scale
Lighting.EnvironmentSpecularScale = L.env_specular_scale
Lighting.GeographicLatitude       = L.geographic_latitude
Lighting.ExposureCompensation     = L.exposure_compensation

-- ── ATMOSPHERE + SKY ──────────────────────────────────────
for _, c in ipairs(Lighting:GetChildren()) do
    if c:IsA("Atmosphere") or c:IsA("Sky") then c:Destroy() end
end

local atmo = Instance.new("Atmosphere")
atmo.Name  = "ZundaAtmosphere"
atmo.Decay = CONFIG.atmosphere.decay
atmo.Glare = CONFIG.atmosphere.glare
atmo.Haze  = CONFIG.atmosphere.haze
atmo.Parent = Lighting

local sky = Instance.new("Sky")
sky.Name  = "ZundaSky"
sky.CelestialBodiesShown = true
sky.SunAngularSize  = CONFIG.sky.sun_angular_size
sky.MoonAngularSize = CONFIG.sky.moon_angular_size
sky.StarCount       = CONFIG.sky.star_count
sky.Parent = Lighting

-- ── CONSTELLATIONS ────────────────────────────────────────
local constFolder = workspace:FindFirstChild("Constellations")
if constFolder then constFolder:Destroy() end
constFolder = Instance.new("Folder")
constFolder.Name = "Constellations"
constFolder.Parent = workspace

for _, c in ipairs(CONFIG.constellations) do
    local model = Instance.new("Model")
    model.Name = "Const_" .. c.name
    model.Parent = constFolder
    local sm = c.size_multiplier or 1
    for i, p in ipairs(c.points) do
        local star = Instance.new("Part")
        star.Name = "Star_"..i
        star.Shape = Enum.PartType.Ball
        local s = 4 * sm
        star.Size = Vector3.new(s,s,s)
        star.Position = c.center + Vector3.new(p[1]*c.scale,p[2]*c.scale,p[3]*c.scale)
        star.Anchored = true
        star.CanCollide = false
        star.CanQuery = false
        star.CanTouch = false
        star.CastShadow = false
        star.Material = Enum.Material.Neon
        star.Color = c.color
        star.Transparency = 1
        local pl = Instance.new("PointLight", star)
        pl.Brightness = 0; pl.Range = 24; pl.Color = c.color
        star.Parent = model
    end
end

-- ── AURORA EFFECT ─────────────────────────────────────────
-- Animated neon curtains high in the sky for aurora weather
local auroraFolder = workspace:FindFirstChild("AuroraFX")
if auroraFolder then auroraFolder:Destroy() end
auroraFolder = Instance.new("Folder")
auroraFolder.Name = "AuroraFX"
auroraFolder.Parent = workspace

local AURORA_COLORS = {
    Color3.fromRGB(80, 220, 180),
    Color3.fromRGB(120, 200, 255),
    Color3.fromRGB(180, 130, 255),
    Color3.fromRGB(100, 240, 160),
}
for i = 1, 8 do
    local band = Instance.new("Part")
    band.Name = "AuroraBand"..i
    band.Size = Vector3.new(180, 2, 8)
    band.Position = Vector3.new(-300 + i*80, 400, -300 + (i%3)*40)
    band.Anchored = true
    band.CanCollide = false
    band.CanQuery = false
    band.CanTouch = false
    band.CastShadow = false
    band.Material = Enum.Material.Neon
    band.Color = AURORA_COLORS[((i-1)%4)+1]
    band.Transparency = 1  -- start hidden
    band.Parent = auroraFolder
end

-- ── CYCLE ─────────────────────────────────────────────────
local CYCLE      = CONFIG.cycle.minutes_per_day * 60
local START      = CONFIG.cycle.start_hour
local STEP       = CONFIG.cycle.step_interval
local startTick  = tick()
local lastExposure = L.exposure_compensation

local function constellationVisibility(hour)
    local s = CONFIG.constellation_night_start
    local e = CONFIG.constellation_night_end
    local night = s > e and ((hour >= s) or (hour <= e))
                        or ((hour >= s) and (hour <= e))
    if not night then return 0 end
    if s > e then
        if hour >= s then return math.clamp((hour-s)/0.5, 0, 1) end
        return math.clamp((e-hour)/0.5, 0, 1)
    else
        return math.clamp(math.min(hour-s, e-hour)/0.5, 0, 1)
    end
end

local function applyHour(hour)
    local a, b, t = getKeyframes(hour)
    Lighting.ClockTime         = hour
    Lighting.Ambient           = lerpColor(a[2], b[2], t)
    Lighting.OutdoorAmbient    = lerpColor(a[3], b[3], t)
    Lighting.ColorShift_Top    = lerpColor(a[4], b[4], t)
    Lighting.ColorShift_Bottom = lerpColor(a[5], b[5], t)
    Lighting.FogColor          = lerpColor(a[6], b[6], t)

    local fogMult = workspace:GetAttribute("WeatherFogMult") or 1
    Lighting.FogStart = lerp(a[7], b[7], t) * fogMult
    Lighting.FogEnd   = lerp(a[8], b[8], t) * fogMult

    local densMult = workspace:GetAttribute("WeatherDensityMult") or 1
    atmo.Density = lerp(a[9], b[9], t) * densMult
    atmo.Color   = lerpColor(a[10], b[10], t)

    local hazeOv = workspace:GetAttribute("WeatherHaze")
    atmo.Haze = hazeOv or CONFIG.atmosphere.haze

    -- Dynamic exposure from keyframe[11]
    if a[11] ~= nil and b[11] ~= nil then
        local targetExp = lerp(a[11], b[11], t)
        -- Smooth out via tiny tween to avoid harsh jumps
        if math.abs(targetExp - lastExposure) > 0.005 then
            lastExposure = targetExp
            Lighting.ExposureCompensation = targetExp
        end
    end

    -- Constellation fade
    local vis = constellationVisibility(hour)
    for _, model in ipairs(constFolder:GetChildren()) do
        for _, star in ipairs(model:GetChildren()) do
            if star:IsA("BasePart") then
                star.Transparency = 1 - vis * 0.88
                local pl = star:FindFirstChildOfClass("PointLight")
                if pl then pl.Brightness = vis * 2.8 end
            end
        end
    end

    -- Aurora: only show during aurora weather at night
    local isNight  = hour < 5.5 or hour > 19.8
    local weather  = workspace:GetAttribute("CurrentWeather") or "clear"
    local auroraOn = (weather == "aurora") and isNight
    for _, band in ipairs(auroraFolder:GetChildren()) do
        if band:IsA("BasePart") then
            band.Transparency = auroraOn and (0.15 + math.sin(tick()*0.4 + band.Position.X*0.05)*0.25) or 1
        end
    end
end

shared.ZundaSky = { apply = applyHour, config = CONFIG }
applyHour(START)
Lighting:SetAttribute("CurrentHour", START)

-- ── MAIN LOOP ─────────────────────────────────────────────
task.spawn(function()
    while true do
        local elapsed = tick() - startTick
        local frac    = (elapsed % CYCLE) / CYCLE
        local hour    = (START + frac * 24) % 24
        applyHour(hour)
        Lighting:SetAttribute("CurrentHour", math.round(hour * 100) / 100)
        task.wait(STEP)
    end
end)

print("[DayNightSky] " .. CONFIG.cycle.minutes_per_day .. "min cycle, " ..
      #CONFIG.keyframes .. " keyframes, " ..
      #CONFIG.constellations .. " constellations, aurora bands=" ..
      #auroraFolder:GetChildren())
