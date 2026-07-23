local Lighting = game:GetService("Lighting")
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
if GuiService.ReducedMotionEnabled ~= nil then
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		checkReducedMotion()
	end)
end

if workspace:FindFirstChild("ZundaGroundMist") then
	return
end

local FX = Instance.new("Folder")
FX.Name = "ZundaGroundMist"
FX.Parent = workspace

local function makeMistPatch(pos, color)
	local p = Instance.new("Part")
	p.Name = "MistPatch"
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = FX
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxassetid://101237232079937"
	e.Rate = 6
	e.Lifetime = NumberRange.new(12, 24)
	e.Speed = NumberRange.new(0.2, 0.8)
	e.SpreadAngle = Vector2.new(360, 360)
	e.Acceleration = Vector3.new(0, 0.15, 0)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(1, 12),
	})
	e.Color = ColorSequence.new(color or Color3.fromRGB(210, 215, 225))
	e.LightEmission = 0.15
	e.LightInfluence = 0.3
	e.ZOffset = 1
	e.Drag = 3
	e.VelocityInheritance = 0
	e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	e.Parent = p
end

local kitchenCenter = Vector3.new(0, 10, 0)
local mistPositions = {
	kitchenCenter + Vector3.new(0, 0, 0),
	kitchenCenter + Vector3.new(30, 0, 20),
	kitchenCenter + Vector3.new(-25, 0, 25),
	kitchenCenter + Vector3.new(20, 0, -20),
	kitchenCenter + Vector3.new(-20, 0, -30),
	kitchenCenter + Vector3.new(50, 0, 10),
	kitchenCenter + Vector3.new(-45, 0, 0),
	kitchenCenter + Vector3.new(0, 0, 35),
	kitchenCenter + Vector3.new(40, 0, -35),
	kitchenCenter + Vector3.new(-35, 0, -15),
	kitchenCenter + Vector3.new(15, 0, 45),
	kitchenCenter + Vector3.new(-50, 0, 30),
}

if not reducedMotion then
	for _, pos in ipairs(mistPositions) do
		makeMistPatch(pos)
	end
end

local function onWeatherChanged(weatherKey)
	local wDef = require(RS.ConfigurationFiles.SkyConfig).weather_types[weatherKey]
	local mistColor = Color3.fromRGB(210, 215, 225)
	local isHeavy = false
	if wDef then
		if wDef.fog_tint then
			mistColor = wDef.fog_tint
		end
		isHeavy = (weatherKey == "fog" or weatherKey == "storm" or weatherKey == "rain")
	end
	for _, child in ipairs(FX:GetChildren()) do
		if not child:IsA("BasePart") then continue end
		for _, e in ipairs(child:GetChildren()) do
			if not e:IsA("ParticleEmitter") then continue end
			if weatherKey == "fog" then
				e.Rate = 14
				e.Lifetime = NumberRange.new(18, 30)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 6),
					NumberSequenceKeypoint.new(1, 18),
				})
			elseif weatherKey == "storm" then
				e.Rate = 10
				e.Lifetime = NumberRange.new(10, 20)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 5),
					NumberSequenceKeypoint.new(1, 14),
				})
			elseif weatherKey == "rain" or weatherKey == "snow" then
				e.Rate = 5
				e.Lifetime = NumberRange.new(10, 18)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 4),
					NumberSequenceKeypoint.new(1, 10),
				})
			elseif weatherKey == "cloudy" then
				e.Rate = 3
				e.Lifetime = NumberRange.new(10, 18)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 3),
					NumberSequenceKeypoint.new(1, 8),
				})
			elseif weatherKey == "aurora" then
				e.Rate = 1
			else
				e.Rate = 1
				e.Lifetime = NumberRange.new(8, 14)
				e.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 3),
					NumberSequenceKeypoint.new(1, 6),
				})
			end
			e.Color = ColorSequence.new(mistColor)
			e.Speed = isHeavy and NumberRange.new(0.3, 1.0) or NumberRange.new(0.2, 0.6)
		end
	end
end

local weatherRE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function(weatherKey)
		onWeatherChanged(weatherKey)
	end)
end

Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	onWeatherChanged(weather)
end)

task.wait(1.6)
local initialWeather = workspace:GetAttribute("CurrentWeather") or "clear"
onWeatherChanged(initialWeather)

print("[GroundMist] Low-lying mist patches active")

return true
