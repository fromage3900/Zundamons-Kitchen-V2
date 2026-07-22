local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

if Lighting:FindFirstChild("ZundaBloomAtmo") then
	return
end

local bloomAtmo = Instance.new("BloomEffect")
bloomAtmo.Name = "ZundaBloomAtmo"
bloomAtmo.Intensity = 0.10
bloomAtmo.Size = 24
bloomAtmo.Threshold = 0.55
bloomAtmo.Parent = Lighting

local bloomSun = Instance.new("BloomEffect")
bloomSun.Name = "ZundaBloomSun"
bloomSun.Intensity = 0.06
bloomSun.Size = 30
bloomSun.Threshold = 0.45
bloomSun.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "ZundaSunRays"
sunRays.Intensity = 0.05
sunRays.Spread = 0.75
sunRays.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "ZundaColorCorrection"
colorCorrection.Brightness = 0.04
colorCorrection.Contrast = 0.02
colorCorrection.Saturation = 0.30
colorCorrection.TintColor = Color3.fromRGB(238, 230, 250)
colorCorrection.Parent = Lighting

local function setupDoF(cam)
	if not cam then return end
	local existing = cam:FindFirstChild("ZundaDepthOfField")
	if existing then existing:Destroy() end
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "ZundaDepthOfField"
	dof.InFocusRadius = 35
	dof.FarIntensity = 0.95
	dof.FocusDistance = 55
	dof.NearIntensity = 0.40
	dof.Parent = cam
end

local cam = workspace.CurrentCamera
if cam then
	setupDoF(cam)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	cam = workspace.CurrentCamera
	setupDoF(cam)
end)

local BLoomAtmoBase = 0.10
local BLoomSunBase = 0.06
task.spawn(function()
	while true do
		local breath = math.sin(os.clock() * 0.3) * 0.015
		bloomAtmo.Intensity = BLoomAtmoBase + breath
		bloomSun.Intensity = BLoomSunBase + breath * 0.5
		task.wait(0.05)
	end
end)

local SkyConfig = require(RS.ConfigurationFiles.SkyConfig)
local activeTween

local function applyWeatherCC(weatherKey)
	if activeTween then activeTween:Cancel() end
	local wDef = SkyConfig.weather_types[weatherKey]
	if not wDef or not wDef.color_correction then return end
	local cc = wDef.color_correction
	local goals = {
		Brightness = cc.brightness,
		Contrast = cc.contrast,
		Saturation = cc.saturation,
		TintColor = cc.tint,
	}
	local tweenInfo = TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	task.wait(3)
	local initial = workspace:GetAttribute("CurrentWeather") or "clear"
	applyWeatherCC(initial)
end)

print("[PostProcessing] Whimsical bloom+blur+CC active, weather-responsive")
