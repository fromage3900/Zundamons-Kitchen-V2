-- [[Script] CloudController (ref: RBX7FC1AA149916460BA1B5815BC3901CC7)]]
-- CloudController: Dynamically adjusts volumetric cloud coverage
-- based on weather type and time of day (denser at dawn/dusk).
local terrain  = workspace:WaitForChild("Terrain")
local Lighting = game:GetService("Lighting")
local Tween    = game:GetService("TweenService")

local function getCloudTarget()
    local weather = workspace:GetAttribute("CurrentWeather") or "clear"
    local hour    = Lighting:GetAttribute("CurrentHour") or 12

    -- Base coverage per weather (increased for richer dream depth)
    local coverMap = {
        clear          = 0.38,
        cloudy         = 0.80,
        cherry_blossom = 0.50,
        rain           = 0.90,
        snow           = 0.85,
        aurora         = 0.25,
        fog            = 0.70,
        storm          = 0.95,
    }
    local densMap = {
        clear          = 0.28,
        cloudy         = 0.55,
        cherry_blossom = 0.35,
        rain           = 0.70,
        snow           = 0.65,
        aurora         = 0.18,
        fog            = 0.50,
        storm          = 0.80,
    }
    local colorMap = {
        clear          = Color3.fromRGB(225, 212, 255),
        cloudy         = Color3.fromRGB(172, 172, 202),
        cherry_blossom = Color3.fromRGB(255, 200, 228),
        rain           = Color3.fromRGB(152, 158, 188),
        snow           = Color3.fromRGB(235, 238, 255),
        aurora         = Color3.fromRGB(172, 225, 218),
        fog            = Color3.fromRGB(195, 198, 220),
        storm          = Color3.fromRGB(120, 130, 165),
    }

    local cover = coverMap[weather] or 0.38
    local density = densMap[weather] or 0.28
    local color = colorMap[weather] or Color3.fromRGB(225, 212, 255)

    -- Dawn/dusk boost (hours 5-9, 16-20 for wider golden windows)
    local isDawnDusk = (hour >= 5 and hour <= 9) or (hour >= 16 and hour <= 20)
    if isDawnDusk then
        cover   = math.min(cover * 1.30, 0.92)
        density = math.min(density * 1.25, 0.75)
    end

    -- Night: keep some cloud depth for mood, thin less aggressively
    if hour < 5 or hour > 21 then
        cover   = cover * 0.82
        density = density * 0.85
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
