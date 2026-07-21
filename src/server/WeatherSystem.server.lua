-- [[Script] WeatherSystem (ref: RBXB2E41768A86B421BA98446D56ABD27F0)]]
-- WeatherSystem (server): rolls weather, applies atmosphere overrides,
-- broadcasts WeatherChanged so clients can run particles.

local RS       = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Tween    = game:GetService("TweenService")
local Players  = game:GetService("Players")

local CONFIG    = require(RS.ConfigurationFiles.SkyConfig)
local WeatherRE = RS.RemoteEvents.WeatherChanged

-- ============================================================
-- State
-- ============================================================
local currentWeather = CONFIG.weather.starting_weather or "clear"
local _tweenObj  -- atmosphere tween reference

-- ============================================================
-- Pick a weather from the weighted pool, optionally filtered by time-of-day
-- ============================================================
local function rollWeather()
    local pool = CONFIG.weather_pool
    local total = 0
    local hour = Lighting:GetAttribute("CurrentHour") or 12
    local isNight = CONFIG.isNightHour(hour)

    -- Filter: aurora only triggers at night
    local filtered = {}
    for _, entry in ipairs(pool) do
        if entry.weather == "aurora" and not isNight then
            -- skip aurora during day
        else
            table.insert(filtered, entry)
            total = total + entry.weight
        end
    end
    local pick = math.random() * total
    local acc = 0
    for _, entry in ipairs(filtered) do
        acc = acc + entry.weight
        if pick <= acc then return entry.weather end
    end
    return "clear"
end

-- ============================================================
-- Apply weather: set workspace attributes (read by DayNightSky)
-- and broadcast to all clients
-- ============================================================
local function applyWeather(weatherKey, transitionSec)
    local w = CONFIG.weather_types[weatherKey]
    if not w then return end
    currentWeather = weatherKey

    transitionSec = transitionSec or CONFIG.weather.transition_seconds or 6

    -- Get current targets
    local targetHaze        = w.atmosphere_haze
    local targetDensityMult = w.atmosphere_density_mult or 1
    local targetFogMult     = w.fog_mult or 1

    -- Tween the workspace attributes that DayNightSky reads
    local startHaze    = workspace:GetAttribute("WeatherHaze")        or CONFIG.atmosphere.haze
    local startDensity = workspace:GetAttribute("WeatherDensityMult") or 1
    local startFog     = workspace:GetAttribute("WeatherFogMult")     or 1

    if _tweenObj then _tweenObj:Cancel() end

    -- Manual interpolation via task.spawn since attribute tweens aren't a thing
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < transitionSec do
            local p = math.clamp((tick() - t0) / transitionSec, 0, 1)
            workspace:SetAttribute("WeatherHaze",        startHaze    + (targetHaze    - startHaze)    * p)
            workspace:SetAttribute("WeatherDensityMult", startDensity + (targetDensityMult - startDensity) * p)
            workspace:SetAttribute("WeatherFogMult",     startFog     + (targetFogMult - startFog)     * p)
            task.wait(0.15)
        end
        workspace:SetAttribute("WeatherHaze",        targetHaze)
        workspace:SetAttribute("WeatherDensityMult", targetDensityMult)
        workspace:SetAttribute("WeatherFogMult",     targetFogMult)
    end)

    workspace:SetAttribute("CurrentWeather", weatherKey)
    -- Broadcast to clients so they can spawn / kill particles
    WeatherRE:FireAllClients(weatherKey, w, transitionSec)
    print(string.format("[WeatherSystem] %s %s (over %.1fs)", w.emoji, w.display_name, transitionSec))
end

-- ============================================================
-- Initial apply
-- ============================================================
task.wait(1)
applyWeather(currentWeather, 0.1)

-- Send current weather to new players on join
Players.PlayerAdded:Connect(function(plr)
    task.wait(2)
    local w = CONFIG.weather_types[currentWeather]
    if w then
        WeatherRE:FireClient(plr, currentWeather, w, 0.5)
    end
end)

-- ============================================================
-- Periodic weather changes
-- ============================================================
task.spawn(function()
    while true do
        task.wait(CONFIG.weather.transition_check_interval)
        if math.random() < CONFIG.weather.transition_chance then
            local newW = rollWeather()
            if newW ~= currentWeather then
                applyWeather(newW, CONFIG.weather.transition_seconds)
            end
        end
    end
end)

-- ============================================================
-- Public API: force a weather (callable from command bar / other scripts)
-- ============================================================
shared.ZundaWeather = {
    set = function(w, dur) applyWeather(w, dur or CONFIG.weather.transition_seconds) end,
    get = function() return currentWeather end,
    list = function()
        local out = {}
        for k in pairs(CONFIG.weather_types) do table.insert(out, k) end
        return out
    end,
}

print("[WeatherSystem] Ready - rolls every " .. CONFIG.weather.transition_check_interval .. "s")