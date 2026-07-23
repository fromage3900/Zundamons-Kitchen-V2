local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local C_teal = Color3.fromRGB(110, 190, 215)
local C_tealLight = Color3.fromRGB(160, 220, 235)
local C_lavender = Color3.fromRGB(180, 160, 220)
local C_navy = Color3.fromRGB(50, 55, 100)
local C_peach = Color3.fromRGB(235, 200, 180)
local C_white = Color3.fromRGB(240, 245, 250)

local trackedWater = {}

local function findWaterParts()
	local parts = {}
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and (part.Material == Enum.Material.Water or part.Name:lower():match("water")) then
			table.insert(parts, part)
		end
	end
	return parts
end

local function getTimeColor()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	if hour >= 5 and hour < 8 then
		return C_lavender:Lerp(C_teal, (hour - 5) / 3)
	elseif hour >= 8 and hour < 17 then
		return C_teal
	elseif hour >= 17 and hour < 20 then
		return C_teal:Lerp(C_peach, (hour - 17) / 3)
	elseif hour >= 20 and hour < 22 then
		return C_peach:Lerp(C_navy, (hour - 20) / 2)
	else
		return C_navy:Lerp(C_lavender, math.sin(hour * math.pi / 6) * 0.5 + 0.5)
	end
end

local function applySurfaceAppearance(part)
	-- SurfaceAppearance can only be parented to MeshParts; water made of plain
	-- Parts keeps its material look instead of erroring out the module load.
	if not part:IsA("MeshPart") then return end
	if part:FindFirstChild("ZundaWaterSA") then return end
	local sa = Instance.new("SurfaceAppearance")
	sa.Name = "ZundaWaterSA"
	sa.Color = C_teal
	-- SurfaceAppearance has no scalar Roughness/Metalness properties (only
	-- RoughnessMap/MetalnessMap texture ids); assigning them threw and killed
	-- FXController's require chain.
	sa.Parent = part

	local glow = Instance.new("PointLight", part)
	glow.Name = "ZundaWaterGlow"
	glow.Brightness = 0.4
	glow.Range = 12
	glow.Color = C_tealLight
	glow.Enabled = true
end

local function createCaustics()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local existing = playerGui:FindFirstChild("ZundaCaustics")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ZundaCaustics"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 12
	gui.Parent = playerGui

	local 	caustic = Instance.new("ImageLabel", gui)
	caustic.Name = "CausticLayer"
	caustic.Size = UDim2.new(2, 0, 2, 0)
	caustic.Position = UDim2.new(-0.5, 0, -0.5, 0)
	caustic.BackgroundTransparency = 1
	caustic.Image = "rbxassetid://101468581497208"
	caustic.ImageTransparency = 0.90
	caustic.ImageColor3 = C_tealLight
	caustic.ScaleType = Enum.ScaleType.Tile
	caustic.TileSize = UDim2.new(0, 256, 0, 256)

	local caustic2 = caustic:Clone()
	caustic2.Name = "CausticLayer2"
	caustic2.Image = "rbxassetid://75779969994353"
	caustic2.ImageTransparency = 0.93
	caustic2.ImageColor3 = C_lavender
	caustic2.TileSize = UDim2.new(0, 320, 0, 320)
	caustic2.Parent = gui

	local caustic3 = caustic:Clone()
	caustic3.Name = "CausticLayer3"
	caustic3.Image = "rbxassetid://83963345255414"
	caustic3.ImageTransparency = 0.96
	caustic3.ImageColor3 = Color3.fromRGB(200, 230, 210)
	caustic3.TileSize = UDim2.new(0, 400, 0, 400)
	caustic3.Parent = gui

	local parallaxOffset = Vector2.new()
	local camRefPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.new()
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		local cam = workspace.CurrentCamera
		if cam then
			local camPos = cam.CFrame.Position
			local targetX = (camRefPos.X - camPos.X) * 0.0008
			local targetY = (camRefPos.Z - camPos.Z) * 0.0008
			parallaxOffset = parallaxOffset:Lerp(Vector2.new(targetX, targetY), 0.06)
		end
		local driftX = math.sin(t * 0.03) * 0.15 + parallaxOffset.X
		local driftY = math.cos(t * 0.025) * 0.12 + parallaxOffset.Y
		caustic.Position = UDim2.new(-0.5 + driftX, 0, -0.5 + driftY, 0)
		caustic2.Position = UDim2.new(-0.5 - driftX * 0.7, 0, -0.5 - driftY * 0.7, 0)
		caustic3.Position = UDim2.new(-0.5 + driftX * 1.3, 0, -0.5 + driftY * 1.3, 0)

		local hourColor = getTimeColor()
		caustic.ImageColor3 = hourColor
		caustic2.ImageColor3 = hourColor:Lerp(C_lavender, 0.5)
		caustic3.ImageColor3 = hourColor:Lerp(Color3.fromRGB(200, 230, 210), 0.6)
	end)
end

local function setupWaterDebris()
	for _, part in ipairs(trackedWater) do
		if not part.Parent then continue end
		if part:FindFirstChild("ZundaWaterDebris") then continue end

		local fx = Instance.new("Folder")
		fx.Name = "ZundaWaterDebris"
		fx.Parent = part

		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxassetid://73381643930763"
		e.Rate = 0.8
		e.Lifetime = NumberRange.new(8, 18)
		e.Speed = NumberRange.new(0.05, 0.3)
		e.SpreadAngle = Vector2.new(360, 360)
		e.Acceleration = Vector3.new(0, 0.02, 0)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.3, 0.40),
			NumberSequenceKeypoint.new(0.7, 0.50),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0.8),
		})
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 220)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 225, 235)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 220, 240)),
		})
		e.LightEmission = 0.10
		e.LightInfluence = 0.2
		e.ZOffset = 1
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-10, 10)
		e.Drag = 5
		e.VelocityInheritance = 0
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.Enabled = true
		e.Parent = fx
	end
end

local function setupFresnelGlow()
	for _, part in ipairs(trackedWater) do
		if not part.Parent then continue end
		if part:FindFirstChild("ZundaFresnelGlow") then continue end

		local glow = Instance.new("Part")
		glow.Name = "ZundaFresnelGlow"
		glow.Size = part.Size + Vector3.new(2, 0.2, 2)
		glow.Position = part.Position + Vector3.new(0, 0.15, 0)
		glow.Anchored = true
		glow.CanCollide = false
		glow.Material = Enum.Material.Neon
		glow.Color = C_tealLight
		glow.Transparency = 0.85
		glow.Parent = part

		task.spawn(function()
			local fadeT = 0
			while glow and glow.Parent do
				fadeT = fadeT + 0.016
				local hourColor = getTimeColor()
				glow.Color = hourColor
				glow.Transparency = 0.85 + math.sin(fadeT * 0.4) * 0.08
				task.wait(0.016)
			end
		end)
	end
end

local function setupWaterSparkles()
	for _, part in ipairs(trackedWater) do
		if not part.Parent then continue end
		if part:FindFirstChild("ZundaWaterFX") then
			local fx = part:FindFirstChild("ZundaWaterFX")
			local e = fx and fx:FindFirstChildOfClass("ParticleEmitter")
			if e then e.Enabled = true end
			continue
		end

		local fx = Instance.new("Folder")
		fx.Name = "ZundaWaterFX"
		fx.Parent = part

		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxassetid://75925932500392"
		e.Rate = 3
		e.Lifetime = NumberRange.new(3, 8)
		e.Speed = NumberRange.new(0.2, 1.0)
		e.SpreadAngle = Vector2.new(30, 30)
		e.Acceleration = Vector3.new(0, 0.6, 0)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(0.3, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1.2),
		})
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C_tealLight),
			ColorSequenceKeypoint.new(1, C_white),
		})
		e.LightEmission = 0.4
		e.LightInfluence = 0
		e.Enabled = true
		e.Parent = fx
	end
end

local function onWaterChanged()
	trackedWater = findWaterParts()
	for _, part in ipairs(trackedWater) do
		applySurfaceAppearance(part)
	end
	setupFresnelGlow()
	setupWaterSparkles()
	setupWaterDebris()
end

workspace.DescendantAdded:Connect(function(desc)
	task.wait(0.3)
	if desc:IsA("BasePart") and desc.Material == Enum.Material.Water then
		table.insert(trackedWater, desc)
		applySurfaceAppearance(desc)
	end
end)

task.wait(2)
onWaterChanged()
createCaustics()

task.spawn(function()
	while true do
		local hourColor = getTimeColor()
		local hour = Lighting:GetAttribute("CurrentHour") or 12
		local night = math.max(0, -math.cos(math.rad((hour - 12) * 15)))
		for _, part in ipairs(trackedWater) do
			if not part.Parent then continue end
			local sa = part:FindFirstChild("ZundaWaterSA")
			if sa and sa:IsA("SurfaceAppearance") then
				sa.Color = hourColor
			end
			local glow = part:FindFirstChild("ZundaWaterGlow")
			if glow and glow:IsA("PointLight") then
				glow.Brightness = 0.2 + night * 0.6
				glow.Color = hourColor
			end
		end
		task.wait(0.3)
	end
end)

Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	setupFresnelGlow()
end)

print("[WaterFX] Reflective dreamy water active")
return {}
