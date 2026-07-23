local MaterialService = game:GetService("MaterialService")

local kitchenCenter = Vector3.new(0, 10, 0)

local variantDefs = {
	{
		name = "Zunda_KitchenFloor",
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(240, 225, 235),
		roughness = 0.7, metalness = 0,
		zone = { center = kitchenCenter, radius = 16 },
	},
	{
		name = "Zunda_GardenSoil",
		base = Enum.Material.Grass,
		color = Color3.fromRGB(210, 230, 195),
		roughness = 0.85, metalness = 0,
		zone = { center = kitchenCenter + Vector3.new(40, 10, 20), radius = 24 },
	},
	{
		name = "Zunda_PondBank",
		base = Enum.Material.Mud,
		color = Color3.fromRGB(185, 175, 165),
		roughness = 0.9, metalness = 0,
		zone = { center = kitchenCenter + Vector3.new(15, 10, -30), radius = 18 },
	},
	{
		name = "Zunda_PathStone",
		base = Enum.Material.Slate,
		color = Color3.fromRGB(175, 170, 185),
		roughness = 0.6, metalness = 0.05,
		zone = { center = kitchenCenter + Vector3.new(5, 10, 0), radius = 8 },
	},
	{
		name = "Zunda_WallPaint",
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(235, 225, 240),
		roughness = 0.65, metalness = 0,
		zone = { center = kitchenCenter, radius = 20 },
	},
}

local variantMap = {}
for _, v in ipairs(variantDefs) do
	local existing = MaterialService:FindFirstChild(v.name)
	if existing then existing:Destroy() end

	local ok, mv = pcall(function()
		local m = Instance.new("MaterialVariant")
		m.Name = v.name
		m.BaseMaterial = v.base
		m.Color = v.color
		m.Roughness = v.roughness
		m.Metalness = v.metalness
		m.Parent = MaterialService
		return m
	end)
	if ok and mv then
		variantMap[v.name] = mv
	end
end

task.spawn(function()
	task.wait(5)
	local applied = 0
	for _, part in ipairs(workspace:GetDescendants()) do
		if not part:IsA("BasePart") or part:IsA("Terrain") then continue end
		if part.Material == Enum.Material.Water or part.Transparency > 0.9 then continue end

		local pos = part.Position
		for _, v in ipairs(variantDefs) do
			if (pos - v.zone.center).Magnitude < v.zone.radius then
				local mv = variantMap[v.name]
				if mv then
					pcall(function() part.MaterialVariant = mv.Name end)
				end
				applied = applied + 1
				break
			end
		end
		if applied >= 200 then break end
	end
end)

print("[TerrainPaint] MaterialVariant terrain painting active")
