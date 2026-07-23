local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

-- Only init once
if workspace:FindFirstChild("ZundaAmbientFX") then
	return true
end

local FX = Instance.new("Folder")
FX.Name = "ZundaAmbientFX"
FX.Parent = workspace

local function makeDustEmitter(pos)
	local p = Instance.new("Part")
	p.Name = "DustMotes"
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
	e.Rate = 10
	e.Lifetime = NumberRange.new(10, 22)
	e.Speed = NumberRange.new(0.3, 1.8)
	e.SpreadAngle = Vector2.new(360, 360)
	e.Acceleration = Vector3.new(0, 0.25, 0)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.88), NumberSequenceKeypoint.new(1, 1)})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.5)})
	e.LightEmission = 0.12
	e.LightInfluence = 0.3
	e.ZOffset = 2
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-15, 15)
	e.VelocityInheritance = 0
	e.Parent = p
end

local function makeFireflyEmitter(pos)
	local p = Instance.new("Part")
	p.Name = "Fireflies"
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
	e.Rate = 5
	e.Lifetime = NumberRange.new(5, 10)
	e.Speed = NumberRange.new(0.2, 1.2)
	e.SpreadAngle = Vector2.new(360, 360)
	e.Acceleration = Vector3.new(0, 0.1, 0)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.4, 0.15),
		NumberSequenceKeypoint.new(1, 0.92),
	})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2)})
	e.Color = ColorSequence.new(Color3.fromRGB(255, 242, 190), Color3.fromRGB(255, 200, 110))
	e.LightEmission = 0.2
	e.LightInfluence = 0.3
	e.ZOffset = 1
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-15, 15)
	e.VelocityInheritance = 0
	e.Enabled = false
	e.Parent = p
end

local function makeSakuraEmitter(pos)
	local p = Instance.new("Part")
	p.Name = "SakuraPetals"
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = FX
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxassetid://73381643930763"
	e.Rate = 25
	e.Lifetime = NumberRange.new(7, 16)
	e.Speed = NumberRange.new(1.5, 5)
	e.SpreadAngle = Vector2.new(25, 45)
	e.Acceleration = Vector3.new(1.5, -2, 0.5)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.6)})
	e.Color = ColorSequence.new(Color3.fromRGB(255, 178, 198), Color3.fromRGB(255, 218, 228))
	e.LightEmission = 0.15
	e.LightInfluence = 0.4
	e.ZOffset = 1
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-45, 45)
	e.Drag = 2
	e.VelocityInheritance = 0
	e.Enabled = false
	e.Parent = p
end

local function makeBubbleMoteEmitter(pos)
	local p = Instance.new("Part")
	p.Name = "BubbleMotes"
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = FX
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxassetid://75925932500392"
	e.Rate = 3
	e.Lifetime = NumberRange.new(4, 10)
	e.Speed = NumberRange.new(0.1, 0.5)
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.1)})
	e.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 255, 255))
	e.LightEmission = 0.2
	e.LightInfluence = 0.3
	e.ZOffset = 1
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-20, 20)
	e.VelocityInheritance = 0
	e.Parent = p
end

local function makeMagicSparkleEmitter(pos)
	local p = Instance.new("Part")
	p.Name = "MagicSparkles"
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = FX
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxassetid://123808802176536"
	e.Rate = 2
	e.Lifetime = NumberRange.new(2, 5)
	e.Speed = NumberRange.new(0.2, 0.8)
	e.SpreadAngle = Vector2.new(360, 360)
	e.Acceleration = Vector3.new(0, -0.1, 0)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(1, 0.95),
	})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1)})
	e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 200), Color3.fromRGB(200, 220, 255))
	e.LightEmission = 0.25
	e.LightInfluence = 0.3
	e.ZOffset = 1
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-30, 30)
	e.VelocityInheritance = 0
	e.Enabled = false
	e.Parent = p
end

local kitchenCenter = Vector3.new(0, 10, 0)

-- Dust motes spread across the playable area
local dustPositions = {
	kitchenCenter + Vector3.new(40, 16, 30),
	kitchenCenter + Vector3.new(-30, 14, 25),
	kitchenCenter + Vector3.new(20, 18, -20),
	kitchenCenter + Vector3.new(-10, 12, -35),
	kitchenCenter + Vector3.new(50, 20, -10),
	kitchenCenter + Vector3.new(-45, 15, 10),
	kitchenCenter + Vector3.new(0, 22, 40),
	kitchenCenter + Vector3.new(30, 10, -45),
	kitchenCenter + Vector3.new(60, 18, 0),
	kitchenCenter + Vector3.new(-55, 16, -5),
	kitchenCenter + Vector3.new(10, 20, 50),
	kitchenCenter + Vector3.new(-20, 14, -40),
}
for _, pos in ipairs(dustPositions) do
	makeDustEmitter(pos)
end

-- Fireflies near vegetation zones
local fireflyPositions = {
	kitchenCenter + Vector3.new(60, 6, 40),
	kitchenCenter + Vector3.new(-50, 5, 50),
	kitchenCenter + Vector3.new(70, 7, -30),
	kitchenCenter + Vector3.new(-60, 6, -20),
	kitchenCenter + Vector3.new(30, 5, 60),
	kitchenCenter + Vector3.new(-30, 5, -50),
}
for _, pos in ipairs(fireflyPositions) do
	makeFireflyEmitter(pos)
end

-- Sakura petal zones (active in cherry_blossom weather or year-round garden)
local sakuraPositions = {
	kitchenCenter + Vector3.new(40, 14, 20),
	kitchenCenter + Vector3.new(-35, 12, 30),
	kitchenCenter + Vector3.new(0, 16, -30),
	kitchenCenter + Vector3.new(60, 10, -10),
	kitchenCenter + Vector3.new(-55, 13, -25),
}
for _, pos in ipairs(sakuraPositions) do
	makeSakuraEmitter(pos)
end

-- Bubble motes: heat-shimmer-like spheres rising near kitchen + water zones
local bubblePositions = {
	kitchenCenter + Vector3.new(0, 2, 0),
	kitchenCenter + Vector3.new(15, 3, 10),
	kitchenCenter + Vector3.new(-12, 2, 8),
	kitchenCenter + Vector3.new(25, 2, -15),
	kitchenCenter + Vector3.new(-20, 3, -10),
}
for _, pos in ipairs(bubblePositions) do
	makeBubbleMoteEmitter(pos)
end

-- Magic sparkles: subtle twinkling motes around the kitchen center (clear/aurora nights)
local sparklePositions = {
	kitchenCenter + Vector3.new(0, 8, 0),
	kitchenCenter + Vector3.new(10, 6, 8),
	kitchenCenter + Vector3.new(-8, 7, -6),
	kitchenCenter + Vector3.new(6, 9, -10),
	kitchenCenter + Vector3.new(-12, 5, 5),
}
for _, pos in ipairs(sparklePositions) do
	makeMagicSparkleEmitter(pos)
end

-- Listen to weather changes to adjust visibility
local function onWeatherChanged(weatherKey)
	local isNight = Lighting:GetAttribute("CurrentHour") and (Lighting:GetAttribute("CurrentHour") < 5.5 or Lighting:GetAttribute("CurrentHour") > 19)
	for _, child in ipairs(FX:GetChildren()) do
		if not child:IsA("BasePart") then continue end
		for _, e in ipairs(child:GetChildren()) do
			if not e:IsA("ParticleEmitter") then continue end
			if child.Name == "Fireflies" then
				e.Enabled = isNight and (weatherKey ~= "rain" and weatherKey ~= "storm")
				if e.Enabled then
					e.Rate = 4 + (weatherKey == "aurora" and 3 or 0)
				end
			elseif child.Name == "SakuraPetals" then
				e.Enabled = (weatherKey == "cherry_blossom") or (weatherKey == "clear" and math.random() < 0.15)
				e.Rate = weatherKey == "cherry_blossom" and 35 or 8
			elseif child.Name == "DustMotes" then
				local rate = 8
				if weatherKey == "rain" or weatherKey == "storm" then rate = 1
				elseif weatherKey == "fog" then rate = 4
				elseif weatherKey == "snow" then rate = 2
				elseif weatherKey == "cherry_blossom" then rate = 10
				end
				e.Rate = rate
			elseif child.Name == "BubbleMotes" then
				e.Enabled = (weatherKey ~= "storm" and weatherKey ~= "snow")
				e.Rate = (weatherKey == "rain" or weatherKey == "fog") and 5 or 3
			elseif child.Name == "MagicSparkles" then
				e.Enabled = (weatherKey == "clear" or weatherKey == "cherry_blossom" or weatherKey == "aurora")
				e.Rate = (weatherKey == "aurora") and 4 or 2
			end
		end
	end
end

local weatherRE = RS:FindFirstChild("RemoteEvents") and RS.RemoteEvents:FindFirstChild("WeatherChanged")
if weatherRE then
	weatherRE.OnClientEvent:Connect(function(weatherKey)
		onWeatherChanged(weatherKey)
	end)
end
-- Listen for hour changes via Lighting attribute
Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	onWeatherChanged(weather)
end)

-- Initial state
task.wait(2)
local initialWeather = workspace:GetAttribute("CurrentWeather") or "clear"
onWeatherChanged(initialWeather)

print("[AmbientParticles] Dust motes, fireflies, sakura petals active")

return true
