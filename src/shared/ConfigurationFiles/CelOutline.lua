local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ZundaCelOutline") then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZundaCelOutline"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = playerGui

-- Layer 1: Hitline grid (thin ink lines)
local hitline = Instance.new("ImageLabel")
hitline.Name = "InkOutline"
hitline.Size = UDim2.new(1.5, 0, 1.5, 0)
hitline.Position = UDim2.new(-0.25, 0, -0.25, 0)
hitline.BackgroundTransparency = 1
hitline.Image = "rbxassetid://118798592641142"
hitline.ImageColor3 = Color3.fromRGB(40, 35, 55)
hitline.ImageTransparency = 0.94
hitline.ScaleType = Enum.ScaleType.Tile
hitline.TileSize = UDim2.new(0, 4, 0, 4)
hitline.ZIndex = 500
hitline.Parent = gui

-- Layer 2: Soft hitline (wider, softer ink wash lines)
local softLine = Instance.new("ImageLabel")
softLine.Name = "SoftInkEdge"
softLine.Size = UDim2.new(1.5, 0, 1.5, 0)
softLine.Position = UDim2.new(-0.25, 0, -0.25, 0)
softLine.BackgroundTransparency = 1
softLine.Image = "rbxassetid://77214598764406"
softLine.ImageColor3 = Color3.fromRGB(50, 45, 65)
softLine.ImageTransparency = 0.96
softLine.ScaleType = Enum.ScaleType.Tile
softLine.TileSize = UDim2.new(0, 6, 0, 6)
softLine.ZIndex = 499
softLine.Parent = gui

-- Layer 3: Ink wash edge (organic ink pooling at bottom)
local inkWash = Instance.new("ImageLabel")
inkWash.Name = "InkWash"
inkWash.Size = UDim2.new(1.5, 0, 1, 0)
inkWash.Position = UDim2.new(-0.25, 0, 0, 0)
inkWash.BackgroundTransparency = 1
inkWash.Image = "rbxassetid://110438655179074"
inkWash.ImageColor3 = Color3.fromRGB(35, 30, 50)
inkWash.ImageTransparency = 0.97
inkWash.ScaleType = Enum.ScaleType.Tile
inkWash.TileSize = UDim2.new(0, 8, 0, 8)
inkWash.ZIndex = 498
inkWash.Parent = gui

-- Layer 4: Shadow ramp (style transfer — darkens lower third)
local shadowRamp = Instance.new("ImageLabel")
shadowRamp.Name = "ShadowRamp"
shadowRamp.Size = UDim2.new(1, 0, 0, 0)
shadowRamp.Size = UDim2.new(1, 0, 0.35, 0)
shadowRamp.Position = UDim2.new(0, 0, 0.65, 0)
shadowRamp.BackgroundTransparency = 1
shadowRamp.Image = "rbxassetid://120123008178828"
shadowRamp.ImageColor3 = Color3.fromRGB(50, 45, 65)
shadowRamp.ImageTransparency = 0.95
shadowRamp.ScaleType = Enum.ScaleType.Fit
shadowRamp.ZIndex = 497
shadowRamp.Parent = gui

-- Layer 5: Hatch overlay (activates on dark/storm weather)
local hatchCross = Instance.new("ImageLabel")
hatchCross.Name = "HatchCross"
hatchCross.Size = UDim2.new(1.5, 0, 1.5, 0)
hatchCross.Position = UDim2.new(-0.25, 0, -0.25, 0)
hatchCross.BackgroundTransparency = 1
hatchCross.Image = "rbxassetid://75023519943348"
hatchCross.ImageColor3 = Color3.fromRGB(40, 35, 55)
hatchCross.ImageTransparency = 0.98
hatchCross.ScaleType = Enum.ScaleType.Tile
hatchCross.TileSize = UDim2.new(0, 3, 0, 3)
hatchCross.ZIndex = 496
hatchCross.Visible = false
hatchCross.Parent = gui

local hatchDiag = Instance.new("ImageLabel")
hatchDiag.Name = "HatchDiagonal"
hatchDiag.Size = UDim2.new(1.5, 0, 1.5, 0)
hatchDiag.Position = UDim2.new(-0.25, 0, -0.25, 0)
hatchDiag.BackgroundTransparency = 1
hatchDiag.Image = "rbxassetid://137995862970712"
hatchDiag.ImageColor3 = Color3.fromRGB(40, 35, 55)
hatchDiag.ImageTransparency = 0.98
hatchDiag.ScaleType = Enum.ScaleType.Tile
hatchDiag.TileSize = UDim2.new(0, 3, 0, 3)
hatchDiag.ZIndex = 495
hatchDiag.Visible = false
hatchDiag.Parent = gui

local function updateInkWeight(weatherKey, hour)
	local isDay = hour > 6 and hour < 18
	local isNight = hour <= 5 or hour >= 19.5

	local baseWeight = 1.0
	if weatherKey == "storm" then baseWeight = 3.0
	elseif weatherKey == "rain" then baseWeight = 2.0
	elseif weatherKey == "fog" then baseWeight = 1.8
	elseif weatherKey == "snow" then baseWeight = 1.5
	elseif weatherKey == "cloudy" then baseWeight = 1.2
	elseif weatherKey == "cherry_blossom" then baseWeight = 0.8
	elseif weatherKey == "aurora" then baseWeight = 1.4
	end

	local nightBoost = isNight and 1.3 or 1.0
	local weight = baseWeight * nightBoost

	local hitTrans = math.clamp(0.94 - (weight - 1) * 0.06, 0.80, 0.96)
	local softTrans = math.clamp(0.96 - (weight - 1) * 0.04, 0.85, 0.97)
	local washTrans = math.clamp(0.97 - (weight - 1) * 0.03, 0.88, 0.98)
	local rampTrans = math.clamp(0.95 - (weight - 1) * 0.04, 0.82, 0.97)

	hitline.ImageTransparency = hitTrans
	softLine.ImageTransparency = softTrans
	inkWash.ImageTransparency = washTrans
	shadowRamp.ImageTransparency = rampTrans

	-- Hatch on heavy weather only
	local showHatch = (weatherKey == "storm" or weatherKey == "rain" or weatherKey == "fog" or (weatherKey == "snow" and isNight))
	hatchCross.Visible = showHatch
	hatchDiag.Visible = showHatch
	if showHatch then
		hatchCross.ImageTransparency = math.clamp(0.96 - (weight - 2) * 0.04, 0.88, 0.97)
		hatchDiag.ImageTransparency = math.clamp(0.96 - (weight - 2) * 0.04, 0.88, 0.97)
	end

	-- Ink wash color shifts with weather mood
	if weatherKey == "storm" then
		inkWash.ImageColor3 = Color3.fromRGB(60, 55, 80)
	elseif weatherKey == "rain" then
		inkWash.ImageColor3 = Color3.fromRGB(55, 55, 75)
	elseif weatherKey == "cherry_blossom" then
		inkWash.ImageColor3 = Color3.fromRGB(80, 55, 70)
	elseif weatherKey == "aurora" then
		inkWash.ImageColor3 = Color3.fromRGB(55, 50, 90)
	elseif isNight then
		inkWash.ImageColor3 = Color3.fromRGB(45, 40, 75)
	else
		inkWash.ImageColor3 = Color3.fromRGB(35, 30, 50)
	end
end

-- Temporal animation: breath + micro-drift on line positions
local t = 0
RunService.RenderStepped:Connect(function(dt)
	t = t + dt

	local breath = 0.5 + 0.5 * math.sin(t * 0.4)
	local driftX = math.sin(t * 0.15) * 0.005
	local driftY = math.sin(t * 0.12 + 1.3) * 0.005

	local baseTrans = hitline.ImageTransparency
	if baseTrans < 0.99 then
		local pulse = math.sin(t * 0.3) * 0.015
		hitline.ImageTransparency = math.clamp(baseTrans + pulse, 0.80, 0.97)
	end

	-- Slow drift on ink wash for organic feel
	local wBase = inkWash.ImageTransparency
	if wBase < 0.99 then
		inkWash.Position = UDim2.new(-0.25 + driftX, 0, driftY, 0)
	end
end)

Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	updateInkWeight(weather, hour)
end)
workspace:GetAttributeChangedSignal("CurrentWeather"):Connect(function()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	updateInkWeight(weather, hour)
end)

local weatherRE = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents") and game.ReplicatedStorage.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function(wk)
		task.wait(0.5)
		local hour = Lighting:GetAttribute("CurrentHour") or 12
		updateInkWeight(wk, hour)
	end)
end

task.wait(2)
local startWeather = workspace:GetAttribute("CurrentWeather") or "clear"
local startHour = Lighting:GetAttribute("CurrentHour") or 12
updateInkWeight(startWeather, startHour)

print("[CelOutline] Ink overlay active — layers: hitline, soft-edge, ink-wash, shadow-ramp, hatch")
