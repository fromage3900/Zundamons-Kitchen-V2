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
    brightness               = 2.60,
    env_diffuse_scale        = 0.85,
    env_specular_scale        = 0.55,
    geographic_latitude      = 35,
    exposure_compensation    = 0.10,
    lighting_style           = "Soft",
}

-- ============================================================
-- SKY
-- ============================================================
SkyConfig.sky = {
    sun_angular_size   = 24,
    moon_angular_size  = 16,
    star_count         = 5500,
    skybox_bk = "rbxassetid://80738444881201",
    skybox_dn = "rbxassetid://110993843013989",
    skybox_ft = "rbxassetid://80738444881201",
    skybox_lf = "rbxassetid://122925638895073",
    skybox_rt = "rbxassetid://78822905803072",
    skybox_up = "rbxassetid://80738444881201",
    sun_texture  = "rbxassetid://123736711329002",
    moon_texture = "rbxassetid://85079237605725",
}

-- ============================================================
-- ATMOSPHERE BASE
-- ============================================================
SkyConfig.atmosphere = {
    decay   = Color3.fromRGB(95, 85, 140),
    glare   = 0.25,
    haze    = 3.0,
}

-- ============================================================
-- TIME-OF-DAY KEYFRAMES  (14 keyframes for richer transitions)
-- Row: { hour, ambient, outdoorAmbient, colorShiftTop, colorShiftBottom,
--        fogColor, fogStart, fogEnd, atmosphereDensity, atmosphereColor,
--        exposure, atmosphereOffset }
--        11th = ExposureCompensation override
--        12th = Atmosphere.Offset (horizon silhouette; -2..12 range)
-- ============================================================
SkyConfig.keyframes = {
    -- Midnight: deep indigo-purple, stars bright, painted horizon
    {0,
     Color3.fromRGB(28, 25, 55),   Color3.fromRGB(15, 12, 35),
     Color3.fromRGB(40, 35, 80),   Color3.fromRGB(25, 20, 50),
     Color3.fromRGB(30, 28, 55),   90, 750,  0.40, Color3.fromRGB(70, 60, 125),   -0.40,  -2},
    {2,
     Color3.fromRGB(30, 28, 62),   Color3.fromRGB(18, 16, 42),
     Color3.fromRGB(48, 42, 95),   Color3.fromRGB(28, 25, 58),
     Color3.fromRGB(35, 32, 65),   90, 780,  0.39, Color3.fromRGB(80, 70, 140),   -0.38,  -2},
    {4.5,
     Color3.fromRGB(55, 42, 95),   Color3.fromRGB(40, 32, 72),
     Color3.fromRGB(110, 70, 150), Color3.fromRGB(70, 48, 110),
     Color3.fromRGB(105, 80, 155), 100, 820,  0.37, Color3.fromRGB(135, 90, 175),  -0.25,  0},
    {6,
     Color3.fromRGB(190, 130, 140),Color3.fromRGB(240, 175, 165),
     Color3.fromRGB(255, 200, 175),Color3.fromRGB(185, 175, 210),
     Color3.fromRGB(255, 210, 195),125, 880,  0.32, Color3.fromRGB(255, 195, 182),  0.08,  4},
    {7,
     Color3.fromRGB(205, 155, 150),Color3.fromRGB(255, 220, 200),
     Color3.fromRGB(255, 235, 200),Color3.fromRGB(195, 200, 230),
     Color3.fromRGB(255, 230, 215),130, 950,  0.30, Color3.fromRGB(255, 225, 202),  0.12,  5},
    {9,
     Color3.fromRGB(185, 180, 200),Color3.fromRGB(252, 248, 250),
     Color3.fromRGB(252, 248, 238),Color3.fromRGB(215, 218, 240),
     Color3.fromRGB(235, 238, 248),180, 1400, 0.28, Color3.fromRGB(220, 228, 248),  0.14,  9},
    {11,
     Color3.fromRGB(190, 188, 205),Color3.fromRGB(255, 252, 252),
     Color3.fromRGB(250, 248, 240),Color3.fromRGB(220, 225, 242),
     Color3.fromRGB(240, 242, 252),220, 1600, 0.26, Color3.fromRGB(210, 225, 250),  0.16,  11},
    {12,
     Color3.fromRGB(195, 192, 210),Color3.fromRGB(255, 255, 255),
     Color3.fromRGB(252, 250, 242),Color3.fromRGB(225, 228, 245),
     Color3.fromRGB(242, 246, 255),260, 1750, 0.24, Color3.fromRGB(205, 225, 250),  0.18,  12},
    {15,
     Color3.fromRGB(195, 180, 180),Color3.fromRGB(255, 248, 240),
     Color3.fromRGB(255, 245, 225),Color3.fromRGB(215, 220, 238),
     Color3.fromRGB(250, 238, 230),220, 1550, 0.27, Color3.fromRGB(230, 228, 245),  0.15,  9},
    {17,
     Color3.fromRGB(215, 155, 145),Color3.fromRGB(255, 215, 185),
     Color3.fromRGB(255, 215, 175),Color3.fromRGB(200, 185, 210),
     Color3.fromRGB(255, 215, 195),170, 1250, 0.31, Color3.fromRGB(255, 200, 178),  0.10,  6},
    {18.5,
     Color3.fromRGB(175, 110, 115),Color3.fromRGB(245, 175, 155),
     Color3.fromRGB(255, 178, 148),Color3.fromRGB(165, 140, 175),
     Color3.fromRGB(255, 178, 160),145, 1000, 0.35, Color3.fromRGB(255, 175, 155),  0.06,  4},
    {20,
     Color3.fromRGB(100, 75, 115), Color3.fromRGB(120, 108, 148),
     Color3.fromRGB(185, 145, 180),Color3.fromRGB(110, 100, 148),
     Color3.fromRGB(158, 130, 178),135, 1000, 0.39, Color3.fromRGB(172, 138, 188), -0.06,  1},
    {22,
     Color3.fromRGB(38, 35, 75),   Color3.fromRGB(22, 20, 52),
     Color3.fromRGB(58, 55, 115),  Color3.fromRGB(38, 35, 72),
     Color3.fromRGB(45, 42, 82),   105, 850,  0.40, Color3.fromRGB(95, 88, 162),  -0.28,  -1},
    {24,
     Color3.fromRGB(28, 25, 55),   Color3.fromRGB(15, 12, 35),
     Color3.fromRGB(40, 35, 80),   Color3.fromRGB(25, 20, 50),
     Color3.fromRGB(30, 28, 55),   90, 750,  0.40, Color3.fromRGB(70, 60, 125),   -0.40,  -2},
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
        atmosphere_haze=1.2, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(0,0,0),
        color_correction={brightness=0.08, contrast=0.01, saturation=0.65, tint=Color3.fromRGB(255,242,235)},
    },
    cloudy = {
        display_name="Cloudy", emoji="☁️",
        particle_enabled=false,
        atmosphere_haze=2.6, atmosphere_density_mult=1.4, fog_mult=0.85,
        wind=Vector3.new(0.2,0,0.1),
        fog_tint=Color3.fromRGB(200, 208, 225),
        color_correction={brightness=0.05, contrast=0.03, saturation=0.58, tint=Color3.fromRGB(240,240,252)},
    },
    cherry_blossom = {
        display_name="Sakura Petals", emoji="🌸",
        particle_enabled=true,
        particle_texture="rbxassetid://105132795948660",
        particle_color=Color3.fromRGB(255,182,200),
        particle_color2=Color3.fromRGB(255,220,230),
        particle_size=1.2, particle_rate=35, particle_lifetime=5, particle_speed=8,
        atmosphere_haze=1.6, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(2,0,0.5),
        fog_tint=Color3.fromRGB(255, 210, 220),
        color_correction={brightness=0.10, contrast=0.00, saturation=0.62, tint=Color3.fromRGB(255,236,238)},
    },
    rain = {
        display_name="Rain", emoji="🌧️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(180,200,230),
        particle_color2=Color3.fromRGB(140,170,220),
        particle_size=0.5, particle_rate=220, particle_lifetime=1.4, particle_speed=80,
        atmosphere_haze=2.2, atmosphere_density_mult=1.6, fog_mult=0.65,
        wind=Vector3.new(3,0,1),
        fog_tint=Color3.fromRGB(160, 178, 205),
        color_correction={brightness=0.02, contrast=0.05, saturation=0.48, tint=Color3.fromRGB(228,230,245)},
    },
    snow = {
        display_name="Snow", emoji="❄️",
        particle_enabled=true,
        particle_texture="rbxassetid://76943668289584",
        particle_color=Color3.fromRGB(250,250,255),
        particle_color2=Color3.fromRGB(220,230,240),
        particle_size=0.8, particle_rate=80, particle_lifetime=6, particle_speed=12,
        atmosphere_haze=2.0, atmosphere_density_mult=1.35, fog_mult=0.70,
        wind=Vector3.new(1.5,0,0.8),
        fog_tint=Color3.fromRGB(200, 212, 235),
        color_correction={brightness=0.12, contrast=0.02, saturation=0.60, tint=Color3.fromRGB(242,246,252)},
    },
    aurora = {
        display_name="Aurora", emoji="🌌",
        particle_enabled=false,
        atmosphere_haze=1.4, atmosphere_density_mult=0.85, fog_mult=1.0,
        wind=Vector3.new(0.2,0,0.1),
        aurora_glow=true,
        fog_tint=Color3.fromRGB(130, 152, 195),
        color_correction={brightness=0.06, contrast=0.04, saturation=0.55, tint=Color3.fromRGB(228,222,252)},
    },
    storm = {
        display_name="Thunderstorm", emoji="⛈️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(140,160,200),
        particle_color2=Color3.fromRGB(100,130,180),
        particle_size=0.55, particle_rate=320, particle_lifetime=1.2, particle_speed=110,
        atmosphere_haze=2.8, atmosphere_density_mult=1.8, fog_mult=0.50,
        wind=Vector3.new(5,0,2),
        fog_tint=Color3.fromRGB(90, 102, 135),
        color_correction={brightness=0.00, contrast=0.08, saturation=0.40, tint=Color3.fromRGB(195,200,225)},
    },
    fog = {
        display_name="Mist", emoji="🌫️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(220,225,230),
        particle_color2=Color3.fromRGB(200,210,220),
        particle_size=8, particle_rate=12, particle_lifetime=10, particle_speed=2,
        atmosphere_haze=3.5, atmosphere_density_mult=2.5, fog_mult=0.45,
        wind=Vector3.new(0.5,0,0.2),
        fog_tint=Color3.fromRGB(178, 190, 208),
        color_correction={brightness=0.03, contrast=0.00, saturation=0.42, tint=Color3.fromRGB(238,238,242)},
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
