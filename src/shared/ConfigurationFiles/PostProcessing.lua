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
bloomAtmo.Intensity = 0.08
bloomAtmo.Size = 30
bloomAtmo.Threshold = 0.55

local bloomSun = Lighting:FindFirstChild("ZundaBloomSun")
if not bloomSun then
	bloomSun = Instance.new("BloomEffect")
	bloomSun.Name = "ZundaBloomSun"
	bloomSun.Parent = Lighting
end
bloomSun.Intensity = 0.04
bloomSun.Size = 24
bloomSun.Threshold = 0.55

local sunRays = Lighting:FindFirstChild("ZundaSunRays")
if not sunRays then
	sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ZundaSunRays"
	sunRays.Parent = Lighting
end
sunRays.Intensity = 0.05
sunRays.Spread = 0.90

local colorCorrection = Lighting:FindFirstChild("ZundaColorCorrection")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ZundaColorCorrection"
	colorCorrection.Parent = Lighting
end
colorCorrection.Brightness = 0.02
colorCorrection.Contrast = 0.04
colorCorrection.Saturation = 0.10
colorCorrection.TintColor = Color3.fromRGB(248, 242, 252)  -- barely-there warm tint

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
	if not cam then return end
	local existing = cam:FindFirstChild("ZundaDepthOfField")
	if existing then existing:Destroy() end
	local existing2 = cam:FindFirstChild("ZundaTiltShift")
	if existing2 then existing2:Destroy() end

	-- AAA cinematic DoF: very subtle, focused on character distance (~20 studs).
	-- The old TiltShift (NearIntensity=0.30) was blurring nearby characters badly.
	-- Removed entirely — AAA games don't use fake tilt-shift overlays.
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "ZundaDepthOfField"
	dof.InFocusRadius = 25        -- wider focus zone so characters stay sharp
	dof.FocusDistance = 22         -- character interaction distance
	dof.FarIntensity = 0.08        -- very subtle background blur
	dof.NearIntensity = 0.02       -- barely-there foreground blur
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
local BloomSunBase = 0.04
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
	if activeTween then activeTween:Cancel() end
	local wDef = SkyConfig.weather_types[weatherKey]
	if not wDef or not wDef.color_correction then return end
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
