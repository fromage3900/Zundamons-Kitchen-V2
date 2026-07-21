-- [[Script] CloudController (ref: RBX7FC1AA149916460BA1B5815BC3901CC7)]]
-- CloudController: Dynamically adjusts volumetric cloud coverage
-- based on weather type and time of day (denser at dawn/dusk).
local terrain  = workspace:WaitForChild("Terrain")
local Lighting = game:GetService("Lighting")
local Tween    = game:GetService("TweenService")

local function getCloudTarget()
    local weather = workspace:GetAttribute("CurrentWeather") or "clear"
    local hour    = Lighting:GetAttribute("CurrentHour") or 12

    -- Base coverage per weather
    local coverMap = {
        clear          = 0.32,
        cloudy         = 0.72,
        cherry_blossom = 0.44,
        rain           = 0.85,
        snow           = 0.78,
        aurora         = 0.20,
    }
    local densMap = {
        clear          = 0.22,
        cloudy         = 0.45,
        cherry_blossom = 0.30,
        rain           = 0.60,
        snow           = 0.55,
        aurora         = 0.15,
    }
    local colorMap = {
        clear          = Color3.fromRGB(232, 220, 255),
        cloudy         = Color3.fromRGB(180, 180, 195),
        cherry_blossom = Color3.fromRGB(255, 210, 225),
        rain           = Color3.fromRGB(160, 165, 180),
        snow           = Color3.fromRGB(240, 245, 255),
        aurora         = Color3.fromRGB(180, 230, 210),
    }

    local cover = coverMap[weather] or 0.32
    local density = densMap[weather] or 0.22
    local color = colorMap[weather] or Color3.fromRGB(232, 220, 255)

    -- Dawn/dusk boost (hours 6-8, 17-19)
    local isDawnDusk = (hour >= 6 and hour <= 8) or (hour >= 17 and hour <= 19)
    if isDawnDusk then
        cover   = math.min(cover * 1.25, 0.90)
        density = math.min(density * 1.20, 0.70)
    end

    -- Night: thin out clouds a bit so stars shine
    if hour < 5 or hour > 21 then
        cover   = cover * 0.75
        density = density * 0.80
    end

    return cover, density, color
end

local function applyClouds()
    local clouds = terrain:FindFirstChildOfClass("Clouds")
    if not clouds then return end

    local cover, density, color = getCloudTarget()
    local ti = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    Tween:Create(clouds, ti, {
        Cover   = cover,
        Density = density,
        Color   = color,
    }):Play()
end

-- React to weather changes
workspace:GetAttributeChangedSignal("CurrentWeather"):Connect(applyClouds)
-- React to hour changes (every ~2 min of real time in a 12-min day)
Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
    local h = Lighting:GetAttribute("CurrentHour") or 12
    -- Only re-check at key transitions (avoid every-tick calls)
    local rounded = math.floor(h)
    if rounded ~= (workspace:GetAttribute("_lastCloudHour") or -1) then
        workspace:SetAttribute("_lastCloudHour", rounded)
        applyClouds()
    end
end)

applyClouds()
print("[CloudController] Ready")
