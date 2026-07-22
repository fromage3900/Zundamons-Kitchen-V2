-- WaterConfig: deep anime watercolour with animated shimmer
local RunService = game:GetService("RunService")
local Terrain = workspace:FindFirstChild("Terrain")
if not Terrain then return end

-- Deep pastel teal with slight blue-purple tint for magic feel
Terrain.WaterColor = Color3.fromRGB(110, 190, 215)
Terrain.WaterTransparency = 0.25
Terrain.WaterReflectance = 0.75
Terrain.WaterWaveSize = 0.4

pcall(function()
	Terrain.MaterialColors[Enum.Material.Water] = Color3.fromRGB(110, 190, 215)
end)

-- Water shimmer particle system near kitchen
local function setupWaterShimmer()
	local waterParts = {}
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Material == Enum.Material.Water then
			table.insert(waterParts, part)
		end
	end
	if #waterParts == 0 then return end
	for _, wp in ipairs(waterParts) do
		if wp:FindFirstChild("ZundaWaterFX") then continue end
		local fx = Instance.new("Folder")
		fx.Name = "ZundaWaterFX"
		fx.Parent = wp
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxassetid://75925932500392"
		e.Rate = 0.5
		e.Lifetime = NumberRange.new(6, 12)
		e.Speed = NumberRange.new(0.2, 1)
		e.SpreadAngle = Vector2.new(45, 45)
		e.Acceleration = Vector3.new(0, 0.3, 0)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.95),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1.2),
		})
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 230, 245)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 240, 255)),
		})
		e.LightEmission = 0.6
		e.LightInfluence = 0
		e.Enabled = true
		e.Parent = fx
	end
end

setupWaterShimmer()

-- Animated water properties for breathing wave effect
local t = 0
RunService.Heartbeat:Connect(function(dt)
	if not Terrain then return end
	t = t + dt
	local wavePulse = 0.3 + math.sin(t * 0.15) * 0.12
	local transPulse = 0.22 + math.sin(t * 0.08) * 0.06
	Terrain.WaterWaveSize = wavePulse
	Terrain.WaterTransparency = transPulse
end)

print("[WaterConfig] Deep anime water + shimmer active")
