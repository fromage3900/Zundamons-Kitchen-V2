local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

if workspace:FindFirstChild("ZundaMagicCircle") then
	return
end

local kitchenCenter = Vector3.new(0, 10, 0)

local circlePart = Instance.new("Part")
circlePart.Name = "ZundaMagicCircle"
circlePart.Size = Vector3.new(16, 0.1, 16)
circlePart.Position = kitchenCenter + Vector3.new(0, -0.5, 0)
circlePart.Anchored = true
circlePart.CanCollide = false
circlePart.CanQuery = false
circlePart.CanTouch = false
circlePart.Transparency = 0.5
circlePart.Material = Enum.Material.ForceField
circlePart.Color = Color3.fromRGB(200, 180, 255)
circlePart.Parent = workspace

local decal = Instance.new("Decal")
decal.Name = "CircleDecal"
decal.Texture = "rbxassetid://139274033388444"
decal.Face = Enum.NormalId.Top
decal.Transparency = 0.3
decal.Color3 = Color3.fromRGB(220, 200, 255)
decal.Parent = circlePart

local glow = Instance.new("Part")
glow.Name = "MagicCircleGlow"
glow.Size = Vector3.new(20, 0.1, 20)
glow.Position = kitchenCenter + Vector3.new(0, -0.6, 0)
glow.Anchored = true
glow.CanCollide = false
glow.CanQuery = false
glow.CanTouch = false
glow.Transparency = 0.8
glow.Material = Enum.Material.Neon
glow.Color = Color3.fromRGB(180, 160, 255)
glow.Parent = workspace

local onWeatherChanged
onWeatherChanged = function(weatherKey)
	local isNight = Lighting:GetAttribute("CurrentHour") and (Lighting:GetAttribute("CurrentHour") < 5.5 or Lighting:GetAttribute("CurrentHour") > 19)
	local showCircle = (weatherKey == "clear" or weatherKey == "cherry_blossom" or weatherKey == "aurora")
	circlePart.Transparency = showCircle and 0.5 or 1
	glow.Transparency = showCircle and 0.8 or 1
	decal.Transparency = showCircle and 0.3 or 1
	if showCircle then
		if weatherKey == "aurora" then
			decal.Color3 = Color3.fromRGB(180, 150, 255)
			glow.Color = Color3.fromRGB(150, 130, 255)
		elseif isNight then
			decal.Color3 = Color3.fromRGB(150, 180, 255)
			glow.Color = Color3.fromRGB(120, 150, 255)
		else
			decal.Color3 = Color3.fromRGB(220, 200, 255)
			glow.Color = Color3.fromRGB(180, 160, 255)
		end
	end
end

local weatherRE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function(wk)
		onWeatherChanged(wk)
	end)
end
Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	onWeatherChanged(weather)
end)

task.spawn(function()
	while circlePart.Parent do
		circlePart.CFrame = circlePart.CFrame * CFrame.Angles(0, math.rad(0.3), 0)
		local breath = math.sin(os.clock() * 0.5) * 0.05
		if circlePart.Transparency < 1 then
			circlePart.Transparency = 0.5 + breath * 0.5
			glow.Transparency = 0.8 + breath * 0.3
			local pulse = 0.3 + math.sin(os.clock() * 0.5) * 0.1
			decal.Transparency = pulse
		end
		task.wait(0.05)
	end
end)

task.wait(2)
local initialWeather = workspace:GetAttribute("CurrentWeather") or "clear"
onWeatherChanged(initialWeather)

print("[MagicCircle] Rotating filigree halo active at kitchen center")

return true
