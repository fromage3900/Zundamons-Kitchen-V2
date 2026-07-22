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
    brightness               = 2.10,
    env_diffuse_scale        = 0.70,
    env_specular_scale        = 0.40,
    geographic_latitude      = 35,
    exposure_compensation    = 0.06,
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
    decay   = Color3.fromRGB(95, 70, 155),
    glare   = 0.15,
    haze    = 4.0,
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
    -- Midnight: deep indigo-purple, dream depth
    {0,
     Color3.fromRGB(25, 18, 55),   Color3.fromRGB(14, 10, 35),
     Color3.fromRGB(40, 28, 80),   Color3.fromRGB(22, 16, 48),
     Color3.fromRGB(28, 20, 55),   75, 550,  0.48, Color3.fromRGB(65, 45, 130),   -0.50,  -4},
    {2,
     Color3.fromRGB(28, 20, 62),   Color3.fromRGB(16, 12, 40),
     Color3.fromRGB(45, 32, 90),   Color3.fromRGB(25, 18, 55),
     Color3.fromRGB(32, 22, 62),   80, 600,  0.46, Color3.fromRGB(75, 52, 145),   -0.46,  -3},
    {4.5,
     Color3.fromRGB(52, 34, 92),   Color3.fromRGB(38, 26, 72),
     Color3.fromRGB(100, 55, 142), Color3.fromRGB(65, 38, 108),
     Color3.fromRGB(95, 65, 155),  90, 680,  0.42, Color3.fromRGB(130, 75, 178),  -0.34,  -2},
    {6, -- Dawn: purple-pink sunrise
     Color3.fromRGB(180, 110, 142),Color3.fromRGB(232, 150, 160),
     Color3.fromRGB(252, 175, 168),Color3.fromRGB(175, 155, 210),
     Color3.fromRGB(248, 185, 182),110, 750,  0.36, Color3.fromRGB(248, 170, 172),  0.04,  2},
    {7,
     Color3.fromRGB(195, 132, 148),Color3.fromRGB(248, 195, 192),
     Color3.fromRGB(250, 212, 192),Color3.fromRGB(185, 180, 225),
     Color3.fromRGB(250, 208, 202),115, 800,  0.34, Color3.fromRGB(250, 202, 192),  0.06,  3},
    {9,
     Color3.fromRGB(170, 160, 200),Color3.fromRGB(242, 234, 248),
     Color3.fromRGB(242, 234, 232),Color3.fromRGB(200, 200, 238),
     Color3.fromRGB(222, 220, 242),150, 1100, 0.30, Color3.fromRGB(205, 210, 242),  0.08,  6},
    {11,
     Color3.fromRGB(175, 168, 205),Color3.fromRGB(248, 242, 250),
     Color3.fromRGB(240, 235, 235),Color3.fromRGB(205, 208, 238),
     Color3.fromRGB(228, 226, 245),180, 1300, 0.28, Color3.fromRGB(195, 208, 242),  0.10,  8},
    {12,
     Color3.fromRGB(180, 174, 210),Color3.fromRGB(250, 246, 250),
     Color3.fromRGB(242, 238, 238),Color3.fromRGB(210, 212, 240),
     Color3.fromRGB(230, 230, 250),200, 1400, 0.26, Color3.fromRGB(190, 208, 242),  0.12,  9},
    {15,
     Color3.fromRGB(182, 164, 182),Color3.fromRGB(250, 234, 240),
     Color3.fromRGB(250, 232, 222),Color3.fromRGB(202, 205, 235),
     Color3.fromRGB(242, 225, 228),180, 1250, 0.30, Color3.fromRGB(218, 212, 240),  0.10,  6},
    {17, -- Dusk: warm pink-purple
     Color3.fromRGB(205, 135, 145),Color3.fromRGB(250, 192, 180),
     Color3.fromRGB(250, 192, 168),Color3.fromRGB(190, 165, 208),
     Color3.fromRGB(250, 192, 188),145, 1000, 0.36, Color3.fromRGB(250, 178, 172),  0.06,  4},
    {18.5,
     Color3.fromRGB(165, 95, 115), Color3.fromRGB(235, 150, 152),
     Color3.fromRGB(250, 155, 142),Color3.fromRGB(155, 125, 175),
     Color3.fromRGB(248, 155, 152),120, 820,  0.40, Color3.fromRGB(248, 152, 148),  0.02,  2},
    {20,
     Color3.fromRGB(92, 60, 115),  Color3.fromRGB(112, 90, 148),
     Color3.fromRGB(175, 125, 175),Color3.fromRGB(102, 82, 148),
     Color3.fromRGB(150, 112, 178),110, 780,  0.44, Color3.fromRGB(165, 118, 188), -0.14,  -1},
    {22,
     Color3.fromRGB(35, 28, 78),   Color3.fromRGB(20, 16, 50),
     Color3.fromRGB(55, 45, 115),  Color3.fromRGB(35, 28, 72),
     Color3.fromRGB(42, 32, 82),   88, 660,  0.46, Color3.fromRGB(88, 70, 165),  -0.36,  -3},
    {24,
     Color3.fromRGB(25, 18, 55),   Color3.fromRGB(14, 10, 35),
     Color3.fromRGB(40, 28, 80),   Color3.fromRGB(22, 16, 48),
     Color3.fromRGB(28, 20, 55),   75, 550,  0.48, Color3.fromRGB(65, 45, 130),   -0.50,  -4},
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
        atmosphere_haze=1.8, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(0,0,0),
        color_correction={brightness=0.04, contrast=0.02, saturation=0.30, tint=Color3.fromRGB(238,230,250)},
    },
    cloudy = {
        display_name="Cloudy", emoji="☁️",
        particle_enabled=false,
        atmosphere_haze=3.0, atmosphere_density_mult=1.5, fog_mult=0.75,
        wind=Vector3.new(0.3,0,0.15),
        fog_tint=Color3.fromRGB(195, 198, 230),
        color_correction={brightness=0.02, contrast=0.04, saturation=0.26, tint=Color3.fromRGB(228,226,248)},
    },
    cherry_blossom = {
        display_name="Sakura Petals", emoji="🌸",
        particle_enabled=true,
        particle_texture="rbxassetid://105132795948660",
        particle_color=Color3.fromRGB(255,182,200),
        particle_color2=Color3.fromRGB(255,220,230),
        particle_size=1.2, particle_rate=35, particle_lifetime=5, particle_speed=8,
        atmosphere_haze=2.0, atmosphere_density_mult=1.0, fog_mult=1.0,
        wind=Vector3.new(2,0,0.5),
        fog_tint=Color3.fromRGB(255, 200, 218),
        color_correction={brightness=0.06, contrast=0.01, saturation=0.32, tint=Color3.fromRGB(245,228,240)},
    },
    rain = {
        display_name="Rain", emoji="🌧️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(175,195,235),
        particle_color2=Color3.fromRGB(135,165,225),
        particle_size=0.5, particle_rate=220, particle_lifetime=1.4, particle_speed=80,
        atmosphere_haze=2.8, atmosphere_density_mult=1.8, fog_mult=0.55,
        wind=Vector3.new(3,0,1),
        fog_tint=Color3.fromRGB(155, 168, 210),
        color_correction={brightness=0.00, contrast=0.06, saturation=0.22, tint=Color3.fromRGB(215,218,242)},
    },
    snow = {
        display_name="Snow", emoji="❄️",
        particle_enabled=true,
        particle_texture="rbxassetid://76943668289584",
        particle_color=Color3.fromRGB(245,245,255),
        particle_color2=Color3.fromRGB(215,225,245),
        particle_size=0.8, particle_rate=80, particle_lifetime=6, particle_speed=12,
        atmosphere_haze=2.4, atmosphere_density_mult=1.4, fog_mult=0.60,
        wind=Vector3.new(1.5,0,0.8),
        fog_tint=Color3.fromRGB(195, 205, 238),
        color_correction={brightness=0.08, contrast=0.03, saturation=0.28, tint=Color3.fromRGB(235,238,250)},
    },
    aurora = {
        display_name="Aurora", emoji="🌌",
        particle_enabled=false,
        atmosphere_haze=1.6, atmosphere_density_mult=0.80, fog_mult=1.0,
        wind=Vector3.new(0.2,0,0.1),
        aurora_glow=true,
        fog_tint=Color3.fromRGB(125, 145, 200),
        color_correction={brightness=0.03, contrast=0.05, saturation=0.25, tint=Color3.fromRGB(215,210,250)},
    },
    storm = {
        display_name="Thunderstorm", emoji="⛈️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(135,155,205),
        particle_color2=Color3.fromRGB(95,125,185),
        particle_size=0.55, particle_rate=320, particle_lifetime=1.2, particle_speed=110,
        atmosphere_haze=3.2, atmosphere_density_mult=2.0, fog_mult=0.40,
        wind=Vector3.new(5,0,2),
        fog_tint=Color3.fromRGB(85, 95, 140),
        color_correction={brightness=-0.02, contrast=0.10, saturation=0.18, tint=Color3.fromRGB(182,188,222)},
    },
    fog = {
        display_name="Mist", emoji="🌫️",
        particle_enabled=true,
        particle_texture="rbxassetid://101237232079937",
        particle_color=Color3.fromRGB(215,218,235),
        particle_color2=Color3.fromRGB(195,200,225),
        particle_size=8, particle_rate=15, particle_lifetime=12, particle_speed=2,
        atmosphere_haze=4.0, atmosphere_density_mult=2.8, fog_mult=0.35,
        wind=Vector3.new(0.5,0,0.2),
        fog_tint=Color3.fromRGB(172, 180, 215),
        color_correction={brightness=0.01, contrast=0.02, saturation=0.18, tint=Color3.fromRGB(226,224,242)},
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
