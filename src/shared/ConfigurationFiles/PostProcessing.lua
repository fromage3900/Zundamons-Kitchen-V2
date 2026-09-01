-- Infinity Nikki Dreamy Post-Processing
-- AAA cinematic: subtle bloom, warm atmosphere, clean focus on characters
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local reducedMotion = GuiService.ReducedMotionEnabled
local function checkReducedMotion()
	if GuiService.ReducedMotionEnabled then
		reducedMotion = true
		return true
	end
	return false
end

local bloomAtmo = Lighting:FindFirstChild("ZundaBloomAtmo")
if not bloomAtmo then
	bloomAtmo = Instance.new("BloomEffect")
	bloomAtmo.Name = "ZundaBloomAtmo"
	bloomAtmo.Parent = Lighting
end
-- AAA subtlety: Infinity Nikki coastal haze refs use bloom 0.06–0.09 (not 0.15+) and SunRays ~0.03–0.05
-- for a barely-there glow on pastel silk, not a blown highlight. Keep Atmo 0.08, Sun 0.03 (was 0.04)
-- and lift Threshold 0.55→0.60 so only specular peaks bloom, not whole sky. SunRays 0.05→0.035 for softer shafts.
bloomAtmo.Intensity = 0.08
bloomAtmo.Size = 28 -- was 30 — slightly tighter to avoid milky veil (Nikki ref: bloom size 24–28 for 1080p)
bloomAtmo.Threshold = 0.60 -- was 0.55 — lifts bloom off mid-tones, keeps character silk clean

local bloomSun = Lighting:FindFirstChild("ZundaBloomSun")
if not bloomSun then
	bloomSun = Instance.new("BloomEffect")
	bloomSun.Name = "ZundaBloomSun"
	bloomSun.Parent = Lighting
end
bloomSun.Intensity = 0.03 -- was 0.04 — AAA sun disk glow subtle; Nikki sun refs ~0.02–0.035
bloomSun.Size = 22 -- was 24
bloomSun.Threshold = 0.60

local sunRays = Lighting:FindFirstChild("ZundaSunRays")
if not sunRays then
	sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ZundaSunRays"
	sunRays.Parent = Lighting
end
sunRays.Intensity = 0.035 -- was 0.05 — Infinity Nikki shafts are whisper-thin; 0.05 read as god-ray beam, 0.03–0.04 reads as air
sunRays.Spread = 0.85 -- was 0.90 — tighter spread keeps shafts from flooding foreground

local colorCorrection = Lighting:FindFirstChild("ZundaColorCorrection")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ZundaColorCorrection"
	colorCorrection.Parent = Lighting
end
colorCorrection.Brightness = 0.02
colorCorrection.Contrast = 0.03 -- was 0.04 — Nikki grading: contrast 0.02–0.03 retains pastel fold detail vs 0.05 crush
colorCorrection.Saturation = 0.12 -- was 0.10 — nudge up to SkyConfig weather_cc range (0.13–0.16) without neon pop
colorCorrection.TintColor = Color3.fromRGB(248, 242, 252) -- barely-there warm tint (matches SkyConfig.weather clear tint blend)

pcall(function()
	Lighting.Ambient = Color3.fromRGB(175, 168, 195)
	Lighting.OutdoorAmbient = Color3.fromRGB(195, 185, 210)
	Lighting.EnvironmentDiffuseScale = 0.90
	Lighting.EnvironmentSpecularScale = 0.70
	Lighting.ExposureCompensation = 0.06

	-- Leave Atmosphere to DayNightSky's keyframe system for smooth transitions.
	-- Overriding here with static values caused a conflicting purple wash
	-- over characters. The SkyConfig keyframes handle density/color naturally.
end)

local function setupDoF(cam)
	if not cam then
		return
	end
	local existing = cam:FindFirstChild("ZundaDepthOfField")
	if existing then
		existing:Destroy()
	end
	local existing2 = cam:FindFirstChild("ZundaTiltShift")
	if existing2 then
		existing2:Destroy()
	end

	-- AAA cinematic DoF: very subtle, focused on character distance (~20 studs).
	-- The old TiltShift (NearIntensity=0.30) was blurring nearby characters badly.
	-- Removed entirely — AAA games don't use fake tilt-shift overlays.
	-- Infinity Nikki refs: far 0.04–0.06 for open-field bokeh, near ~0.01 to keep UI/pea-wheel crisp.
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "ZundaDepthOfField"
	dof.InFocusRadius = 28 -- was 25 — slightly wider so companion duo stays sharp at 3.5 stud offset
	dof.FocusDistance = 22 -- character interaction distance
	dof.FarIntensity = 0.05 -- was 0.08 — AAA subtlety: 0.08 blurred distant pagoda a touch too creamy; 0.05 keeps landmark read
	dof.NearIntensity = 0.015 -- was 0.02 — barely-there foreground (Nikki ref 0.01–0.015)
	dof.Parent = cam
end

local cam = workspace.CurrentCamera
if cam then
	setupDoF(cam)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCam = workspace.CurrentCamera
	if newCam then
		setupDoF(newCam)
	end
end)

local BloomAtmoBase = 0.08
local BloomSunBase = 0.03 -- matches revised bloomSun above (was 0.04)
if not reducedMotion then
	task.spawn(function()
		while true do
			local breath = math.sin(os.clock() * 0.4) * 0.005
			bloomAtmo.Intensity = BloomAtmoBase + breath
			bloomSun.Intensity = BloomSunBase + breath * 0.5
			task.wait(0.05)
		end
	end)
end
-- Watch for runtime reduced-motion toggle
if GuiService.ReducedMotionEnabled ~= nil then
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		checkReducedMotion()
	end)
end

local SkyConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("SkyConfig"))
local activeTween

local function applyWeatherCC(weatherKey)
	if activeTween then
		activeTween:Cancel()
	end
	local wDef = SkyConfig.weather_types[weatherKey]
	if not wDef or not wDef.color_correction then
		return
	end
	local cc = wDef.color_correction
	local goals = {
		Brightness = cc.brightness or 0.05,
		Contrast = cc.contrast or 0.03,
		Saturation = cc.saturation or 0.28,
		TintColor = cc.tint or Color3.fromRGB(248, 236, 252),
	}
	local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	activeTween = Tween:Create(colorCorrection, tweenInfo, goals)
	activeTween:Play()
end

local weatherRE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function(weatherKey)
		applyWeatherCC(weatherKey)
	end)
end

task.spawn(function()
	task.wait(0.5)
	local initial = workspace:GetAttribute("CurrentWeather") or "clear"
	applyWeatherCC(initial)
end)

print("[PostProcessing] Infinity Nikki Dreamy Post-Processing active")
return {}
