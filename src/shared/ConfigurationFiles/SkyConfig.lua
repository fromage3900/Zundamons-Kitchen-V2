-- [[ModuleScript] SkyConfig (ref: RBX0B367381DE914C068E52F496AA2CCC00)]]
-- SkyConfig: All tunable parameters for the realtime sky + weather system
-- Live-edit any value here and rerun DayNightSky/WeatherSystem to apply.

local SkyConfig = {}

-- ============================================================
-- CYCLE
-- ============================================================
SkyConfig.cycle = {
    minutes_per_day = 12,
    start_hour      = 7,
    step_interval   = 0.5,  -- slightly faster for smoother transitions
}

-- ============================================================
-- GLOBAL LIGHTING
-- ============================================================
SkyConfig.lighting = {
    global_shadows           = true,
    shadow_softness          = 0.40,
    brightness               = 2.30,
    env_diffuse_scale        = 0.60,
    env_specular_scale        = 0.50,
    geographic_latitude      = 35,
    exposure_compensation    = 0.15,
}

-- ============================================================
-- SKY
-- ============================================================
SkyConfig.sky = {
    sun_angular_size   = 24,
    moon_angular_size  = 16,
    star_count         = 5500,
    skybox_bk = "rbxassetid://84226376723302",
    skybox_dn = "rbxassetid://84226376723302",
    skybox_ft = "rbxassetid://84226376723302",
    skybox_lf = "rbxassetid://84226376723302",
    skybox_rt = "rbxassetid://84226376723302",
    skybox_up = "rbxassetid://84226376723302",
    sun_texture  = "rbxassetid://123736711329002",
    moon_texture = "rbxassetid://85079237605725",
}

-- ============================================================
-- ATMOSPHERE BASE
-- ============================================================
SkyConfig.atmosphere = {
    decay   = Color3.fromRGB(106, 112, 125),
    glare   = 0.22,
    haze    = 1.3,
}

-- ============================================================
-- TIME-OF-DAY KEYFRAMES  (14 keyframes for richer transitions)
-- Row: { hour, ambient, outdoorAmbient, colorShiftTop, colorShiftBottom,
--        fogColor, fogStart, fogEnd, atmosphereDensity, atmosphereColor,
--        exposure }   ← 11th value = ExposureCompensation override
-- ============================================================
SkyConfig.keyframes = {
    -- Midnight: deep blue, stars bright
    {0,
     Color3.fromRGB(18, 22, 52),   Color3.fromRGB(8,  12, 32),
     Color3.fromRGB(30, 45, 90),   Color3.fromRGB(20, 28, 58),
     Color3.fromRGB(22, 28, 52),   100, 800,  0.42, Color3.fromRGB(60, 80, 130),   -0.35},
    -- 2am: slightly lighter, deep indigo
    {2,
     Color3.fromRGB(22, 25, 58),   Color3.fromRGB(10, 14, 38),
     Color3.fromRGB(35, 50, 100),  Color3.fromRGB(22, 32, 65),
     Color3.fromRGB(28, 32, 62),   100, 820,  0.41, Color3.fromRGB(70, 88, 145),   -0.32},
    -- Pre-dawn 4:30am: first hint of navy to purple
    {4.5,
     Color3.fromRGB(38, 32, 75),   Color3.fromRGB(25, 22, 55),
     Color3.fromRGB(80, 60, 130),  Color3.fromRGB(55, 45, 100),
     Color3.fromRGB(88, 72, 140),  115, 850,  0.38, Color3.fromRGB(110, 90, 165),  -0.22},
    -- Dawn 6am: rose and amber blush
    {6,
     Color3.fromRGB(165, 105, 95), Color3.fromRGB(220, 155, 130),
     Color3.fromRGB(255, 160, 110),Color3.fromRGB(250, 130, 100),
     Color3.fromRGB(255, 190, 165),145, 900,  0.32, Color3.fromRGB(255, 185, 160),  0.05},
    -- Golden hour 7am: warm orange-gold
    {7,
     Color3.fromRGB(180, 135, 110),Color3.fromRGB(245, 205, 165),
     Color3.fromRGB(255, 210, 150),Color3.fromRGB(255, 190, 140),
     Color3.fromRGB(255, 218, 190),150, 1000, 0.30, Color3.fromRGB(255, 215, 185),  0.10},
    -- Morning 9am: clear bright
    {9,
     Color3.fromRGB(162, 162, 168),Color3.fromRGB(248, 248, 238),
     Color3.fromRGB(248, 238, 228),Color3.fromRGB(232, 228, 222),
     Color3.fromRGB(232, 238, 245),210, 1550, 0.28, Color3.fromRGB(222, 232, 245),  0.14},
    -- Late morning 11am
    {11,
     Color3.fromRGB(168, 168, 175),Color3.fromRGB(252, 252, 248),
     Color3.fromRGB(252, 248, 238),Color3.fromRGB(238, 238, 232),
     Color3.fromRGB(238, 242, 250),260, 1700, 0.26, Color3.fromRGB(210, 225, 248),  0.16},
    -- Noon: peak brightness, slight cyan
    {12,
     Color3.fromRGB(172, 172, 178),Color3.fromRGB(255, 255, 252),
     Color3.fromRGB(255, 252, 242),Color3.fromRGB(242, 242, 238),
     Color3.fromRGB(242, 248, 255),305, 1850, 0.25, Color3.fromRGB(202, 222, 248),  0.18},
    -- Afternoon 15:00: warm drift
    {15,
     Color3.fromRGB(168, 162, 152),Color3.fromRGB(252, 242, 228),
     Color3.fromRGB(255, 238, 202),Color3.fromRGB(248, 228, 202),
     Color3.fromRGB(248, 228, 215),258, 1650, 0.28, Color3.fromRGB(228, 228, 242),  0.15},
    -- Golden hour eve 17:00: amber-rose
    {17,
     Color3.fromRGB(195, 135, 110),Color3.fromRGB(252, 195, 155),
     Color3.fromRGB(255, 185, 120),Color3.fromRGB(252, 158, 110),
     Color3.fromRGB(252, 192, 162),205, 1350, 0.32, Color3.fromRGB(255, 185, 152),  0.10},
    -- Sunset 18:30: deep orange-crimson
    {18.5,
     Color3.fromRGB(148, 88, 78),  Color3.fromRGB(235, 148, 118),
     Color3.fromRGB(255, 125, 85), Color3.fromRGB(240, 100, 80),
     Color3.fromRGB(248, 148, 125),175, 1100, 0.36, Color3.fromRGB(255, 148, 125),  0.04},
    -- Dusk 20:00: purple twilight
    {20,
     Color3.fromRGB(78, 65, 92),   Color3.fromRGB(98, 98, 132),
     Color3.fromRGB(158, 118, 152),Color3.fromRGB(108, 88, 132),
     Color3.fromRGB(138, 118, 162),155, 1050, 0.40, Color3.fromRGB(158, 128, 172), -0.08},
    -- Night 22:00
    {22,
     Color3.fromRGB(28, 32, 68),   Color3.fromRGB(15, 20, 48),
     Color3.fromRGB(48, 62, 108),  Color3.fromRGB(32, 40, 72),
     Color3.fromRGB(38, 44, 75),   115, 880,  0.41, Color3.fromRGB(88, 108, 158),  -0.28},
    -- Back to midnight (loop)
    {24,
     Color3.fromRGB(18, 22, 52),   Color3.fromRGB(8,  12, 32),
     Color3.fromRGB(30, 45, 90),   Color3.fromRGB(20, 28, 58),
     Color3.fromRGB(22, 28, 52),   100, 800,  0.42, Color3.fromRGB(60, 80, 130),   -0.35},
}

-- ============================================================
-- CONSTELLATIONS
-- ============================================================
SkyConfig.constellations = {
    {
        name = "Bunny",
        center = Vector3.new(-200, 250, -200), scale = 22,
        color  = Color3.fromRGB(255, 230, 240),
        points = {
            {-1.5, 4, 0}, {-1.2, 5.5, 0},
            { 0.5, 4, 0}, { 0.8, 5.5, 0},
            { 0, 2.5, 0}, {-1, 2, 0}, { 1, 2, 0},
            { 0, 0, 0}, {-1.5,-1, 0}, { 1.5,-1, 0},
        },
    },
    {
        name = "Cherry Blossom",
        center = Vector3.new(200, 280, -250), scale = 18,
        color  = Color3.fromRGB(255, 200, 220),
        points = {
            { 0, 0, 0}, { 2, 1.5, 0}, {-2, 1.5, 0},
            { 2,-1.5, 0}, {-2,-1.5, 0}, { 0, 2.4, 0}, { 0,-2.4, 0},
        },
    },
    {
        name = "Onigiri",
        center = Vector3.new(0, 320, -150), scale = 16,
        color  = Color3.fromRGB(255, 250, 220),
        points = {
            { 0, 2.5, 0}, {-2.5,-1.5, 0}, { 2.5,-1.5, 0}, { 0, 0, 0},
        },
    },
    {
        name = "Cat",
        center = Vector3.new(280, 230, -450), scale = 20,
        color  = Color3.fromRGB(230, 220, 255),
        points = {
            {-2, 3, 0}, { 2, 3, 0},
            {-3, 0, 0}, { 3, 0, 0}, { 0, 1, 0},
            {-1.5,-1.5, 0}, { 1.5,-1.5, 0},
        },
    },
    {
        name = "Big Star",
        center = Vector3.new(-100, 350, -400), scale = 8,
        color  = Color3.fromRGB(255, 250, 200),
        points = { {0,0,0} },
        size_multiplier = 2.5,
    },
}

SkyConfig.constellation_night_start = 19.8
SkyConfig.constellation_night_end   = 5.8

-- ============================================================
-- WEATHER
-- ============================================================
SkyConfig.weather = {
    transition_check_interval = 90,
    transition_chance = 0.35,
    transition_seconds = 8,
    starting_weather = "clear",
}

SkyConfig.weather_types = {
    clear = {
        display_name="Clear Skies", emoji="☀️",
        particle_enabled=false,
        atmosphere_haze=1.0, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(0,0,0),
    },
    cloudy = {
        display_name="Cloudy", emoji="☁️",
        particle_enabled=false,
        atmosphere_haze=2.4, atmosphere_density_mult=1.35, fog_mult=0.85,
        wind=Vector3.new(0.2,0,0.1),
    },
    cherry_blossom = {
        display_name="Sakura Petals", emoji="🌸",
        particle_enabled=true,
        particle_texture="rbxasset://textures/particles/leaf.png",
        particle_color=Color3.fromRGB(255,182,200),
        particle_color2=Color3.fromRGB(255,220,230),
        particle_size=1.2, particle_rate=35, particle_lifetime=5, particle_speed=8,
        atmosphere_haze=1.4, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(2,0,0.5),
    },
    rain = {
        display_name="Rain", emoji="🌧️",
        particle_enabled=true,
        particle_texture="rbxasset://textures/particles/sparkles_main.dds",
        particle_color=Color3.fromRGB(180,200,230),
        particle_color2=Color3.fromRGB(140,170,220),
        particle_size=0.5, particle_rate=220, particle_lifetime=1.4, particle_speed=80,
        atmosphere_haze=2.0, atmosphere_density_mult=1.5, fog_mult=0.7,
        wind=Vector3.new(3,0,1),
    },
    snow = {
        display_name="Snow", emoji="❄️",
        particle_enabled=true,
        particle_texture="rbxasset://textures/particles/sparkles_main.dds",
        particle_color=Color3.fromRGB(250,250,255),
        particle_color2=Color3.fromRGB(220,230,240),
        particle_size=0.8, particle_rate=80, particle_lifetime=6, particle_speed=12,
        atmosphere_haze=1.8, atmosphere_density_mult=1.3, fog_mult=0.75,
        wind=Vector3.new(1.5,0,0.8),
    },
    aurora = {
        display_name="Aurora", emoji="🌌",
        particle_enabled=false,
        atmosphere_haze=1.2, atmosphere_density_mult=0.85, fog_mult=1.0,
        wind=Vector3.new(0.2,0,0.1),
        aurora_glow=true,
    },
    storm = {
        display_name="Thunderstorm", emoji="⛈️",
        particle_enabled=true,
        particle_texture="rbxasset://textures/particles/sparkles_main.dds",
        particle_color=Color3.fromRGB(140,160,200),
        particle_color2=Color3.fromRGB(100,130,180),
        particle_size=0.55, particle_rate=320, particle_lifetime=1.2, particle_speed=110,
        atmosphere_haze=2.6, atmosphere_density_mult=1.7, fog_mult=0.55,
        wind=Vector3.new(5,0,2),
    },
    fog = {
        display_name="Mist", emoji="🌫️",
        particle_enabled=true,
        particle_texture="rbxasset://textures/particles/smoke_main.dds",
        particle_color=Color3.fromRGB(220,225,230),
        particle_color2=Color3.fromRGB(200,210,220),
        particle_size=8, particle_rate=12, particle_lifetime=10, particle_speed=2,
        atmosphere_haze=3.0, atmosphere_density_mult=2.2, fog_mult=0.5,
        wind=Vector3.new(0.5,0,0.2),
    },
}

SkyConfig.weather_pool = {
    {weather="clear",          weight=38},
    {weather="cloudy",         weight=20},
    {weather="cherry_blossom", weight=16},
    {weather="rain",           weight=10},
    {weather="fog",            weight=6},
    {weather="snow",           weight=5},
    {weather="storm",          weight=3},
    {weather="aurora",         weight=2},
}

-- Shared time-of-day helpers (use across WeatherSystem, VNController, SkySync).
function SkyConfig.isNightHour(hour: number): boolean
	local t = hour % 24
	return t >= 19 or t <= 6
end

function SkyConfig.greetingSlot(hour: number): string
	local t = hour % 24
	if t >= 5 and t < 12 then
		return "morning"
	elseif t >= 12 and t < 18 then
		return "afternoon"
	elseif t >= 18 and t < 21 then
		return "evening"
	end
	return "night"
end

function SkyConfig.welcomeGreeting(hour: number): string
	local slot = SkyConfig.greetingSlot(hour)
	if slot == "morning" then
		return "Good morning!"
	elseif slot == "afternoon" then
		return "Good afternoon!"
	elseif slot == "evening" then
		return "Good evening!"
	end
	return "Goodnight!"
end

-- fog_mult is lower in rain/storm (see weather_types). Returns 0 (dry) .. 1 (wet).
function SkyConfig.weatherWetness(fogMult: number): number
	return math.clamp((1 - fogMult) / 0.5, 0, 1)
end

return SkyConfig
