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
-- LightingStyle: Soft for diffused painted shadows (July 2025+ Unified Lighting)
pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Soft end)
-- Extend light range to 120 studs for better global illumination reach
pcall(function() Lighting.ExtendLightRangeTo120 = Enum.RolloutState.On end)

-- ── ATMOSPHERE + SKY ──────────────────────────────────────
for _, c in ipairs(Lighting:GetChildren()) do
    if c:IsA("Atmosphere") or c:IsA("Sky") or c:IsA("BlurEffect") then c:Destroy() end
end

local atmo = Instance.new("Atmosphere")
atmo.Name  = "ZundaAtmosphere"
atmo.Decay = CONFIG.atmosphere.decay
atmo.Glare = CONFIG.atmosphere.glare
atmo.Haze  = CONFIG.atmosphere.haze
atmo.Parent = Lighting

-- Dream blur: subtle full-screen blur for fog/rain transitions
local dreamBlur = Instance.new("BlurEffect")
dreamBlur.Name = "ZundaDreamBlur"
dreamBlur.Size = 0
dreamBlur.Parent = Lighting

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

local kitchenCenter = Vector3.new(0, 10, 0)

-- ── GOD-RAY LIGHT SHAFTS ─────────────────────────────────
-- Subtle particle beams that angle toward the sun on clear days
local godRayFolder = workspace:FindFirstChild("GodRays")
if godRayFolder then godRayFolder:Destroy() end
godRayFolder = Instance.new("Folder")
godRayFolder.Name = "GodRays"
godRayFolder.Parent = workspace

local function makeGodRay(pos)
    local p = Instance.new("Part")
    p.Name = "GodRayBeam"
    p.Size = Vector3.new(1, 1, 1)
    p.Position = pos
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Transparency = 1
    p.Parent = godRayFolder
    local e = Instance.new("ParticleEmitter")
    e.Texture = "rbxassetid://101237232079937"
    e.Rate = 1
    e.Lifetime = NumberRange.new(5, 10)
    e.Speed = NumberRange.new(6, 18)
    e.SpreadAngle = Vector2.new(8, 8)
    e.Acceleration = Vector3.new(0, -3, 0)
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(0.3, 0.90),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(1, 3),
    })
    e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 220))
    e.LightEmission = 0.25
    e.LightInfluence = 0.3
    e.ZOffset = 2
    e.Rotation = NumberRange.new(0, 360)
    e.RotSpeed = NumberRange.new(-5, 5)
    e.VelocityInheritance = 0
    e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
    e.Enabled = false
    e.Parent = p
end

local rayPositions = {
    kitchenCenter + Vector3.new(10, 4, 5),
    kitchenCenter + Vector3.new(-8, 4, 8),
    kitchenCenter + Vector3.new(15, 3, -10),
    kitchenCenter + Vector3.new(-12, 5, -6),
    kitchenCenter + Vector3.new(5, 4, 15),
    kitchenCenter + Vector3.new(-5, 3, -12),
}
for _, pos in ipairs(rayPositions) do
    makeGodRay(pos)
end

-- ── AURORA EFFECT ─────────────────────────────────────────
-- Animated neon curtains high in the sky for aurora weather
local auroraFolder = workspace:FindFirstChild("AuroraFX")
if auroraFolder then auroraFolder:Destroy() end
auroraFolder = Instance.new("Folder")
auroraFolder.Name = "AuroraFX"
auroraFolder.Parent = workspace

local AURORA_COLORS = {
    Color3.fromRGB(60, 220, 190),
    Color3.fromRGB(100, 195, 255),
    Color3.fromRGB(180, 140, 255),
    Color3.fromRGB(80, 240, 170),
    Color3.fromRGB(220, 160, 255),
}
for i = 1, 12 do
    local band = Instance.new("Part")
    band.Name = "AuroraBand"..i
    band.Size = Vector3.new(200, 2, 10)
    band.Position = Vector3.new(-400 + i*70, 380 + (i%3)*15, -350 + (i%4)*30)
    band.Anchored = true
    band.CanCollide = false
    band.CanQuery = false
    band.CanTouch = false
    band.CastShadow = false
    band.Material = Enum.Material.Neon
    band.Color = AURORA_COLORS[((i-1)%#AURORA_COLORS)+1]
    band.Transparency = 1
    band.Parent = auroraFolder
end

-- ── DYNAMIC CLOUDS (painted watercolour volume) ────────────
local terrain = workspace:FindFirstChild("Terrain")
local clouds
if terrain then
    for _, c in ipairs(terrain:GetChildren()) do
        if c:IsA("Clouds") then c:Destroy() end
    end
    clouds = Instance.new("Clouds")
    clouds.Name = "ZundaClouds"
    clouds.Parent = terrain
end

local function updateClouds(hour, weather)
    if not clouds then return end
    local isDay = hour > 6 and hour < 18
    local isDawn = hour >= 5 and hour <= 7
    local isDusk = hour >= 17 and hour <= 19.5
    local isNight = hour <= 5 or hour >= 19.5

    local baseCover = 0.2
    if weather == "clear" then baseCover = 0.12
    elseif weather == "cloudy" then baseCover = 0.6
    elseif weather == "cherry_blossom" then baseCover = 0.3
    elseif weather == "rain" then baseCover = 0.75
    elseif weather == "storm" then baseCover = 0.9
    elseif weather == "snow" then baseCover = 0.65
    elseif weather == "fog" then baseCover = 1.0
    elseif weather == "aurora" then baseCover = 0.06
    end
    if isNight and (weather == "clear" or weather == "cherry_blossom") then baseCover = 0.06 end
    clouds.Cover = baseCover

    local dens = 0.18
    if weather == "fog" then dens = 0.55
    elseif weather == "storm" then dens = 0.40
    elseif weather == "rain" then dens = 0.32
    elseif weather == "cloudy" then dens = 0.22
    elseif weather == "snow" then dens = 0.20
    end
    clouds.Density = dens

    if isDawn then
        clouds.Color = Color3.fromRGB(255, 215, 205)
    elseif isDusk then
        clouds.Color = Color3.fromRGB(255, 205, 195)
    elseif isNight then
        clouds.Color = Color3.fromRGB(115, 125, 175)
    else
        clouds.Color = Color3.fromRGB(232, 232, 248)
    end
    if weather == "rain" or weather == "storm" then
        clouds.Color = Color3.fromRGB(155, 165, 185)
    elseif weather == "cherry_blossom" then
        clouds.Color = Color3.fromRGB(255, 215, 222)
    elseif weather == "fog" then
        clouds.Color = Color3.fromRGB(205, 210, 222)
    elseif weather == "aurora" then
        clouds.Color = Color3.fromRGB(150, 170, 210)
    end
end

-- ── CYCLE ─────────────────────────────────────────────────
local CYCLE      = CONFIG.cycle.minutes_per_day * 60
local START      = CONFIG.cycle.start_hour
local STEP       = CONFIG.cycle.step_interval
local startTick  = os.clock()
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
    local fogColor = lerpColor(a[6], b[6], t)
    -- Weather fog tint overlay (painted gradient for each mood)
    local weather = workspace:GetAttribute("CurrentWeather") or "clear"
    local wDef = CONFIG.weather_types[weather]
    if wDef and wDef.fog_tint then
        fogColor = fogColor:Lerp(wDef.fog_tint, 0.55)
    end
    Lighting.FogColor = fogColor

    local fogMult = workspace:GetAttribute("WeatherFogMult") or 1
    Lighting.FogStart = lerp(a[7], b[7], t) * fogMult
    Lighting.FogEnd   = lerp(a[8], b[8], t) * fogMult

    local densMult = workspace:GetAttribute("WeatherDensityMult") or 1
    atmo.Density = lerp(a[9], b[9], t) * densMult
    atmo.Color   = lerpColor(a[10], b[10], t)
    if a[12] ~= nil and b[12] ~= nil then
        atmo.Offset = lerp(a[12], b[12], t)
    end

    local hazeOv = workspace:GetAttribute("WeatherHaze")
    atmo.Haze = hazeOv or CONFIG.atmosphere.haze

    -- Dynamic sun rays per weather (reduced for softer look)
    local sr = workspace:FindFirstChild("ZundaSunRays")
    if sr and sr:IsA("SunRaysEffect") then
        if weather == "clear" or weather == "cherry_blossom" then
            sr.Intensity = 0.08
            sr.Spread = 0.85
        elseif weather == "cloudy" then
            sr.Intensity = 0.05
            sr.Spread = 0.78
        elseif weather == "fog" or weather == "rain" or weather == "storm" then
            sr.Intensity = 0.02
            sr.Spread = 0.60
        else
            sr.Intensity = 0.05
            sr.Spread = 0.85
        end
    end

    -- Dynamic exposure from keyframe[11]
    if a[11] ~= nil and b[11] ~= nil then
        local targetExp = lerp(a[11], b[11], t)
        -- Smooth out via tiny tween to avoid harsh jumps
        if math.abs(targetExp - lastExposure) > 0.005 then
            lastExposure = targetExp
            Lighting.ExposureCompensation = targetExp
        end
    end

    -- Constellation fade with per-star twinkle
    local vis = constellationVisibility(hour)
    local starTime = os.clock()
    for _, model in ipairs(constFolder:GetChildren()) do
        for _, star in ipairs(model:GetChildren()) do
            if star:IsA("BasePart") then
                star.Transparency = 1 - vis * 0.88
                local pl = star:FindFirstChildOfClass("PointLight")
                if pl then
                    local phase = (star.Position.X * 7.3 + star.Position.Z * 11.7) % 6.28
                    local twinkle = 0.7 + 0.3 * math.sin(starTime * 3 + phase)
                    pl.Brightness = vis * 2.8 * twinkle
                end
            end
        end
    end

    -- Clouds: painted volume driven by time + weather
    updateClouds(hour, weather)

    -- Dream blur: subtle full-screen blur during fog/rain for painted depth
    if weather == "fog" then
        dreamBlur.Size = 8
    elseif weather == "rain" or weather == "storm" then
        dreamBlur.Size = 4
    elseif weather == "snow" or weather == "cloudy" then
        dreamBlur.Size = 2
    else
        dreamBlur.Size = 0
    end

    -- God rays: subtle light shafts on clear daytime
    local isDaytime = hour > 7 and hour < 17
    local godRayOn = isDaytime and (weather == "clear" or weather == "cherry_blossom")
    for _, child in ipairs(godRayFolder:GetChildren()) do
        if child:IsA("BasePart") then
            for _, e in ipairs(child:GetChildren()) do
                if e:IsA("ParticleEmitter") then
                    e.Enabled = godRayOn
                    e.Rate = godRayOn and 2 + (weather == "clear" and 1 or 0) or 0
                end
            end
        end
    end

    -- Aurora: animated color-cycling neon curtains
    local isNight  = hour < 5.5 or hour > 19.8
    local auroraOn = (weather == "aurora") and isNight
    local colors = AURORA_COLORS
    local aClock = os.clock()
    for i, band in ipairs(auroraFolder:GetChildren()) do
        if band:IsA("BasePart") then
            local phase = band.Position.X * 0.05 + band.Position.Z * 0.03
            if auroraOn then
                if not band:GetAttribute("BaseY") then
                    band:SetAttribute("BaseY", band.Position.Y)
                end
                local baseY = band:GetAttribute("BaseY")
                local yBob = math.sin(aClock * 0.3 + phase * 1.5) * 4
                band.Position = Vector3.new(band.Position.X, baseY + yBob, band.Position.Z)
                local ci = ((i - 1) % #colors) + 1
                local nextCI = ci % #colors + 1
                local blend = (math.sin(aClock * 0.2 + phase) + 1) * 0.5
                band.Color = colors[ci]:Lerp(colors[nextCI], blend)
                band.Transparency = 0.12 + math.sin(aClock * 0.4 + phase) * 0.2
            else
                band.Transparency = 1
            end
        end
    end
end

shared.ZundaSky = { apply = applyHour, config = CONFIG }
applyHour(START)
Lighting:SetAttribute("CurrentHour", START)

-- ── MAIN LOOP ─────────────────────────────────────────────
task.spawn(function()
    while true do
        local elapsed = os.clock() - startTick
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
