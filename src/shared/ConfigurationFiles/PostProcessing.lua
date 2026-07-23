local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local bloomAtmo = Lighting:FindFirstChild("ZundaBloomAtmo")
if not bloomAtmo then
	bloomAtmo = Instance.new("BloomEffect")
	bloomAtmo.Name = "ZundaBloomAtmo"
	bloomAtmo.Parent = Lighting
end
bloomAtmo.Intensity = 0.22
bloomAtmo.Size = 42
bloomAtmo.Threshold = 0.45

local bloomSun = Lighting:FindFirstChild("ZundaBloomSun")
if not bloomSun then
	bloomSun = Instance.new("BloomEffect")
	bloomSun.Name = "ZundaBloomSun"
	bloomSun.Parent = Lighting
end
bloomSun.Intensity = 0.12
bloomSun.Size = 36
bloomSun.Threshold = 0.38

local sunRays = Lighting:FindFirstChild("ZundaSunRays")
if not sunRays then
	sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "ZundaSunRays"
	sunRays.Parent = Lighting
end
sunRays.Intensity = 0.14
sunRays.Spread = 0.85

local colorCorrection = Lighting:FindFirstChild("ZundaColorCorrection")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ZundaColorCorrection"
	colorCorrection.Parent = Lighting
end
colorCorrection.Brightness = 0.05
colorCorrection.Contrast = 0.03
colorCorrection.Saturation = 0.28
colorCorrection.TintColor = Color3.fromRGB(248, 236, 252)

pcall(function()
	Lighting.Ambient = Color3.fromRGB(160, 145, 185)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 160, 210)
	Lighting.EnvironmentDiffuseScale = 1.0
	Lighting.EnvironmentSpecularScale = 0.85
	Lighting.ExposureCompensation = 0.15

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Name = "DreamyAtmosphere"
		atmo.Parent = Lighting
	end
	atmo.Density = 0.25
	atmo.Haze = 1.8
	atmo.Glare = 0.45
	atmo.Color = Color3.fromRGB(235, 210, 245)
	atmo.Decay = Color3.fromRGB(180, 140, 200)
end)

local function setupDoF(cam)
	if not cam then return end
	local existing = cam:FindFirstChild("ZundaDepthOfField")
	if existing then existing:Destroy() end

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "ZundaDepthOfField"
	dof.InFocusRadius = 24
	dof.FocusDistance = 38
	dof.FarIntensity = 0.45
	dof.NearIntensity = 0.15
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

local BloomAtmoBase = 0.22
local BloomSunBase = 0.12
task.spawn(function()
	while true do
		local breath = math.sin(os.clock() * 0.4) * 0.025
		bloomAtmo.Intensity = BloomAtmoBase + breath
		bloomSun.Intensity = BloomSunBase + breath * 0.5
		task.wait(0.05)
	end
end)

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
	task.wait(2)
	local initial = workspace:GetAttribute("CurrentWeather") or "clear"
	applyWeatherCC(initial)
end)

print("[PostProcessing] Infinity Nikki Dreamy Post-Processing active")
return {}
