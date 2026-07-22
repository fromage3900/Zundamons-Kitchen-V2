local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- CrystalFX: Applies Glass+Neon+ForceField stack to tagged crystal parts
-- Tag any part with "Crystal" in Studio to get:
--   - SurfaceAppearance with crystal emission glow
--   - Inner neon core for fake refraction
--   - Slow hue-cycling iridescence

local function findCrystalParts()
	local results = {}
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsA("Terrain") then
			if CollectionService:HasTag(part, "Crystal") then
				table.insert(results, part)
			end
		end
	end
	return results
end

local function enhanceCrystal(part)
	if part:FindFirstChild("ZundaCrystalFX") then
		return
	end

	local fx = Instance.new("Folder")
	fx.Name = "ZundaCrystalFX"
	fx.Parent = part

	-- SurfaceAppearance with emission
	local sa = Instance.new("SurfaceAppearance")
	sa.Name = "CrystalGlow"
	sa.ColorMap = Instance.new("NumberSequence")
	sa.RoughnessMap = Instance.new("NumberSequence")
	sa.MetalnessMap = Instance.new("NumberSequence")
	sa.EmissiveMap = "rbxassetid://121883683025787"
	sa.EmissiveScale = 2.0
	sa.Parent = fx

	-- Inner glow neon core (slightly smaller, inside)
	local inner = Instance.new("Part")
	inner.Name = "CrystalCore"
	inner.Size = part.Size * 0.75
	inner.Position = part.Position
	inner.Anchored = true
	inner.CanCollide = false
	inner.CanQuery = false
	inner.CanTouch = false
	inner.CastShadow = false
	inner.Material = Enum.Material.ForceField
	inner.Color = Color3.fromRGB(180, 200, 255)
	inner.Transparency = 0.5
	inner.Parent = part

	-- PointLight for glow
	local pl = Instance.new("PointLight")
	pl.Brightness = 2
	pl.Range = 12
	pl.Color = Color3.fromRGB(180, 200, 255)
	pl.Parent = part
end

-- Apply to all current crystal parts
for _, p in ipairs(findCrystalParts()) do
	enhanceCrystal(p)
end

-- Watch for new tagged parts
CollectionService:GetInstanceAddedSignal("Crystal"):Connect(enhanceCrystal)

-- Hue-cycling iridescence on inner cores
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, part in ipairs(findCrystalParts()) do
		local fxFolder = part:FindFirstChild("ZundaCrystalFX")
		if fxFolder then
			local core = part:FindFirstChild("CrystalCore")
			if core then
				local hue = (t * 0.02 + part.Position.X * 0.001) % 1
				core.Color = Color3.fromHSV(hue, 0.5, 0.9 + 0.1 * math.sin(t * 0.5 + part.Position.Z))
				core.Transparency = 0.45 + 0.15 * math.sin(t * 0.3 + part.Position.X)
			end
			local pl = part:FindFirstChildOfClass("PointLight")
			if pl then
				local plHue = (t * 0.015 + part.Position.Y * 0.001) % 1
				pl.Color = Color3.fromHSV(plHue, 0.4, 0.8)
				pl.Brightness = 1.5 + math.sin(t * 0.4 + part.Position.Z) * 0.8
			end
		end
	end
end)

print("[CrystalFX] Crystal refraction system active — tag parts with 'Crystal' in Studio")
