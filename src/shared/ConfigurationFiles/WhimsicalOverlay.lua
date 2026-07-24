local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local reducedMotion = GuiService.ReducedMotionEnabled
local function checkReducedMotion()
	if GuiService.ReducedMotionEnabled then
		reducedMotion = true
		return true
	end
	return false
end
if GuiService.ReducedMotionEnabled ~= nil then
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		checkReducedMotion()
	end)
end

if playerGui:FindFirstChild("ZundaWhimsicalOverlay") then
	return true
end

local SkyConfig = require(RS.ConfigurationFiles.SkyConfig)

-- ============================================================
-- ScreenGui (survives respawn per AGENTS.md Rule 2)
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ZundaWhimsicalOverlay"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- Scene-FX layer: sits BEHIND all interactive UI (panels 15+, PeaWheel 1000).
gui.DisplayOrder = 2
gui.IgnoreGuiInset = true
gui.Enabled = true
gui.Parent = playerGui

-- ============================================================
-- GRADIENT WASH (painted watercolour filter over viewport)
-- Full-screen vertical gradient that shifts color with time/weather
-- ============================================================
local gradientFrame = Instance.new("Frame")
gradientFrame.Name = "SkyGradient"
gradientFrame.Size = UDim2.new(1, 0, 1, 0)
gradientFrame.BackgroundTransparency = 1
gradientFrame.ZIndex = 200
gradientFrame.Parent = gui

local gradientUI = Instance.new("UIGradient")
gradientUI.Name = "Gradient"
gradientUI.Rotation = 0
gradientUI.Parent = gradientFrame

-- ============================================================
-- LENS FLARE (iridescent sun glow)
-- Multi-layer chromatic flare with iridescent overlay
-- ============================================================
local flare = Instance.new("ImageLabel")
flare.Name = "LensFlare"
flare.Size = UDim2.new(0, 80, 0, 80)
flare.BackgroundTransparency = 1
flare.Image = "rbxassetid://111378866841838"
flare.ImageColor3 = Color3.fromRGB(255, 235, 200)
flare.ImageTransparency = 0.88
flare.ZIndex = 300
flare.Visible = false
flare.Parent = gui

local flareGlow = Instance.new("ImageLabel")
flareGlow.Name = "FlareGlow"
flareGlow.Size = UDim2.new(0, 160, 0, 160)
flareGlow.BackgroundTransparency = 1
flareGlow.Image = "rbxassetid://101237232079937"
flareGlow.ImageColor3 = Color3.fromRGB(255, 220, 180)
flareGlow.ImageTransparency = 0.95
flareGlow.ZIndex = 299
flareGlow.Visible = false
flareGlow.Parent = gui

local flareIri = Instance.new("ImageLabel")
flareIri.Name = "FlareIridescent"
flareIri.Size = UDim2.new(0, 120, 0, 120)
flareIri.BackgroundTransparency = 1
flareIri.Image = "rbxassetid://111378866841838"
flareIri.ImageColor3 = Color3.fromRGB(255, 255, 255)
flareIri.ImageTransparency = 0.96
flareIri.ZIndex = 298
flareIri.Visible = false
flareIri.Parent = gui

-- ============================================================
-- GRADIENT UPDATE (time-of-day + weather)
-- ============================================================
local function updateGradient(hour, weatherKey)
	local isDay = hour > 6 and hour < 18
	local isDawn = hour >= 5 and hour <= 7
	local isDusk = hour >= 17 and hour <= 19.5
	local isNight = hour <= 5 or hour >= 19.5

	local topColor, bottomColor
	-- AAA polish: reduced purple wash that was tinting characters blue.
	-- Colors are now warmer and more neutral at the center of the screen.
	if isDawn then
		topColor = Color3.fromRGB(255, 210, 215)
		bottomColor = Color3.fromRGB(255, 225, 230)
	elseif isDusk then
		topColor = Color3.fromRGB(255, 185, 195)
		bottomColor = Color3.fromRGB(230, 170, 200)
	elseif isNight then
		topColor = Color3.fromRGB(80, 65, 120)
		bottomColor = Color3.fromRGB(50, 40, 80)
	else
		topColor = Color3.fromRGB(235, 232, 248)
		bottomColor = Color3.fromRGB(248, 244, 250)
	end

	if weatherKey == "cherry_blossom" then
		topColor = Color3.fromRGB(255, 215, 228)
		bottomColor = Color3.fromRGB(255, 232, 242)
	elseif weatherKey == "rain" or weatherKey == "storm" then
		topColor = Color3.fromRGB(165, 168, 200)
		bottomColor = Color3.fromRGB(140, 145, 180)
	elseif weatherKey == "fog" then
		topColor = Color3.fromRGB(190, 192, 215)
		bottomColor = Color3.fromRGB(205, 205, 225)
	elseif weatherKey == "snow" then
		topColor = Color3.fromRGB(225, 228, 245)
		bottomColor = Color3.fromRGB(238, 240, 250)
	elseif weatherKey == "aurora" then
		topColor = Color3.fromRGB(150, 120, 200)
		bottomColor = Color3.fromRGB(90, 70, 140)
	end

	-- Reduced alpha so the gradient doesn't overpower characters
	local alpha = isNight and 0.28 or 0.18
	local dawnBoost = (isDawn or isDusk) and 1.2 or 1.0
	gradientUI.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(0.5, bottomColor),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	gradientUI.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, alpha * dawnBoost),
		NumberSequenceKeypoint.new(1, 1),
	})

	local flareVis = isDay and (weatherKey == "clear" or weatherKey == "cherry_blossom" or weatherKey == "cloudy")
	flare.Visible = flareVis
	flareGlow.Visible = flareVis
	flareIri.Visible = flareVis
	if flareVis then
		local sunAngle = (hour - 6) / 12 * math.pi
		local xOff = math.sin(sunAngle) * 0.35
		local yOff = -math.cos(sunAngle) * 0.25 + 0.15
		local pos = UDim2.new(0.5 + xOff, 0, 0.5 + yOff, 0)
		flare.Position = pos
		flareGlow.Position = pos
		flareIri.Position = pos
		if not reducedMotion then
			local pulse = math.sin(os.clock() * 0.3) * 0.04
			local iriShift = math.sin(os.clock() * 0.15) * 0.5 + 0.5
			flare.ImageTransparency = 0.82 + pulse
			flareGlow.ImageTransparency = 0.93 + pulse * 0.5
			flareIri.ImageTransparency = 0.94 + pulse * 0.3
			flareIri.Rotation = iriShift * 360
		else
			flare.ImageTransparency = 0.86
			flareGlow.ImageTransparency = 0.95
			flareIri.ImageTransparency = 0.96
			flareIri.Rotation = 0
		end
	end
end

-- ============================================================
-- VIGNETTE BREATHING
-- Find existing vignette frames and add breathing + color shift
-- ============================================================
local function enhanceVignette()
	for _, sg in ipairs(playerGui:GetChildren()) do
		if not sg:IsA("ScreenGui") then continue end
		local vignette = sg:FindFirstChild("Vignette")
		if not vignette then continue end
		for _, f in ipairs(vignette:GetChildren()) do
			if not f:IsA("Frame") then continue end
			local g = f:FindFirstChildOfClass("UIGradient")
			if not g then continue end
	task.spawn(function()
		while f.Parent do
			local breath = math.sin(os.clock() * 0.2) * 0.05
			local weather = workspace:GetAttribute("CurrentWeather") or "clear"
			local isDark = (weather == "rain" or weather == "storm" or weather == "fog")
			local base = isDark and 0.28 or 0.45
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, base + breath),
				NumberSequenceKeypoint.new(0.8, 0.75 + breath * 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			task.wait(0.15)
		end
	end)
			break
		end
		break
	end
end

enhanceVignette()

-- ============================================================
-- LISTENERS
-- ============================================================
local function onTimeOrWeatherChange()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	updateGradient(hour, weather)
end

Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(onTimeOrWeatherChange)
workspace:GetAttributeChangedSignal("CurrentWeather"):Connect(onTimeOrWeatherChange)

local weatherRE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function()
		task.wait(0.5)
		onTimeOrWeatherChange()
	end)
end

task.wait(1.2)
onTimeOrWeatherChange()

-- Ground-level wash: extra dark gradient at bottom for depth
local groundFrame = Instance.new("Frame")
groundFrame.Name = "GroundWash"
groundFrame.Size = UDim2.new(1, 0, 0, 0)
groundFrame.Position = UDim2.new(0, 0, 0.7, 0)
groundFrame.Size = UDim2.new(1, 0, 0.3, 0)
groundFrame.BackgroundTransparency = 1
groundFrame.ZIndex = 201
groundFrame.Parent = gui

local groundGradient = Instance.new("UIGradient")
groundGradient.Name = "GroundGradient"
groundGradient.Rotation = 90
groundGradient.Parent = groundFrame

local function updateGroundWash(weatherKey)
	local isDark = (weatherKey == "rain" or weatherKey == "storm" or weatherKey == "fog" or weatherKey == "snow")
	local c = isDark and Color3.fromRGB(35, 22, 55) or Color3.fromRGB(55, 42, 72)
	groundGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, c),
	})
	local a = isDark and 0.35 or 0.25
	groundGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 1 - a * 0.5),
		NumberSequenceKeypoint.new(1, 1 - a),
	})
end

-- ============================================================
-- IRIDESCENCE THIN-FILM OVERLAY
-- Slow hue-cycling rainbow overlay simulating thin-film interference
-- ============================================================
local thinFilm = Instance.new("ImageLabel")
thinFilm.Name = "ThinFilmIridescence"
thinFilm.Size = UDim2.new(1.5, 0, 1.5, 0)
thinFilm.Position = UDim2.new(-0.25, 0, -0.25, 0)
thinFilm.BackgroundTransparency = 1
thinFilm.Image = "rbxassetid://131954939744794"
thinFilm.ImageColor3 = Color3.fromRGB(255, 255, 255)
thinFilm.ImageTransparency = 0.97
thinFilm.ScaleType = Enum.ScaleType.Fit
thinFilm.ZIndex = 250
thinFilm.Parent = gui

-- ============================================================
-- SHEEN SWEEP (animated iridescent band across screen)
-- Uses the SheenSweep texture as a horizontal band that drifts
-- ============================================================
local sheen = Instance.new("ImageLabel")
sheen.Name = "SheenSweep"
sheen.Size = UDim2.new(2, 0, 0, 0)
sheen.Size = UDim2.new(2, 0, 0.15, 0)
sheen.Position = UDim2.new(-0.5, 0, -0.1, 0)
sheen.BackgroundTransparency = 1
sheen.Image = "rbxassetid://93614570475932"
sheen.ImageColor3 = Color3.fromRGB(255, 255, 255)
sheen.ImageTransparency = 0.96
sheen.ScaleType = Enum.ScaleType.Fit
sheen.ZIndex = 251
sheen.Parent = gui

if not reducedMotion then
	task.spawn(function()
		local t = 0
		while gui.Parent do
			local dt = task.wait(0.05)
			t = t + dt

			-- Thin-film hue cycling (0.02 Hz = 50s cycle)
			local tfHue = (t * 0.01) % 1
			local tfSat = 0.35 + math.sin(t * 0.08) * 0.15
			local tfVal = 0.85 + math.sin(t * 0.12) * 0.10
			thinFilm.ImageColor3 = Color3.fromHSV(tfHue, tfSat, tfVal)
			local tfBreath = 0.5 + 0.5 * math.sin(t * 0.2)
			thinFilm.ImageTransparency = 0.96 + tfBreath * 0.02

			-- Sheen sweep: moves from top to bottom over 25s
			local sweepY = (t * 0.04) % 1.2 - 0.1
			sheen.Position = UDim2.new(-0.5, 0, sweepY, 0)
			sheen.ImageColor3 = Color3.fromHSV((t * 0.005) % 1, 0.3, 1)
			local sheenVis = (sweepY > -0.1 and sweepY < 1.0)
			sheen.ImageTransparency = sheenVis and (0.95 + math.sin(t * 1.5) * 0.015) or 1
		end
	end)

	-- Consolidated breathing loop: gradient + ground wash in one tick
	task.spawn(function()
		while gui.Parent do
			local weather = workspace:GetAttribute("CurrentWeather") or "clear"
			local isDark = (weather == "rain" or weather == "storm" or weather == "fog" or weather == "snow")
			local breath = math.sin(os.clock() * 0.2) * 0.008
			gradientFrame.BackgroundTransparency = 0.98 + breath

			local base = isDark and 0.35 or 0.25
			local gBreath = math.sin(os.clock() * 0.15) * 0.04
			local a = base + gBreath
			groundGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 1 - a * 0.5),
				NumberSequenceKeypoint.new(1, 1 - a),
			})
			task.wait(0.1)
		end
	end)
else
	-- Static values when reduced motion is enabled
	thinFilm.ImageTransparency = 0.97
	sheen.ImageTransparency = 1
	gradientFrame.BackgroundTransparency = 0.98
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	local isDark = (weather == "rain" or weather == "storm" or weather == "fog" or weather == "snow")
	local base = isDark and 0.35 or 0.25
	groundGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 1 - base * 0.5),
		NumberSequenceKeypoint.new(1, 1 - base),
	})
	sheen.Visible = false
end

updateGroundWash("clear")
workspace:GetAttributeChangedSignal("CurrentWeather"):Connect(function()
	updateGroundWash(workspace:GetAttribute("CurrentWeather") or "clear")
end)
local weatherRE2 = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE2 then
	weatherRE2.OnClientEvent:Connect(function(wk)
		task.wait(0.5)
		updateGroundWash(wk)
	end)
end

print("[WhimsicalOverlay] Gradient wash + lens flare + vignette breath + ground wash active")

return true
