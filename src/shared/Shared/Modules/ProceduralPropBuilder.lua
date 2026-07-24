--!strict
-- Procedural fallback geometry for the landscape spawner's 7 recurring props
-- (MarketHall, BakeryStall, StreetLamp, Bench, ZundaFlower, BerryBush,
-- ZundaMushroom). ArchitectureVariants (auto-generated from the Kenney kit)
-- only ever got 1 real mesh entry ("Lantern") checked in -- every other
-- asset name/category combo the biome planner requests resolves to nothing,
-- which is why every "[LandscapeSpawner] Spawned X/Y" log has always read
-- 0/Y. Rather than chase more fragile external asset ids (this project has
-- hit that permission wall constantly), these are built entirely from Parts
-- so they always render, need no upload/import step, and are themed to the
-- game's pastel palette so they read as authored set-dressing rather than
-- placeholder blocks.

local ProceduralPropBuilder = {}

local PALETTE = {
	mint = Color3.fromRGB(145, 215, 195),
	gold = Color3.fromRGB(255, 200, 80),
	pink = Color3.fromRGB(255, 150, 200),
	green = Color3.fromRGB(160, 210, 150),
	cream = Color3.fromRGB(255, 248, 235),
	wood = Color3.fromRGB(196, 154, 108),
	roof = Color3.fromRGB(220, 120, 110),
	stone = Color3.fromRGB(214, 206, 196),
}

local function part(name, size, color, cframe, parent, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = shape ~= "nocollide"
	p.CanQuery = true
	p.Material = Enum.Material.SmoothPlastic
	if shape == "ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Parent = parent
	return p
end

local function buildStreetLamp(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "StreetLamp"
	local pole = part("Pole", Vector3.new(0.5, 9, 0.5), PALETTE.stone, CFrame.new(pos + Vector3.new(0, 4.5, 0)), model)
	local head = part("LampHead", Vector3.new(1.4, 1.4, 1.4), PALETTE.gold, CFrame.new(pos + Vector3.new(0, 9.2, 0)), model, "ball")
	head.Material = Enum.Material.Neon
	head.Transparency = 0.15
	local light = Instance.new("PointLight")
	light.Color = PALETTE.gold
	light.Brightness = 1.4
	light.Range = 16
	light.Parent = head
	local cap = part("Cap", Vector3.new(0.3, 0.6, 0.3), PALETTE.stone, CFrame.new(pos + Vector3.new(0, 9.8, 0)), model)
	model.PrimaryPart = pole
	return model
end

local function buildBench(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Bench"
	local seat = part("Seat", Vector3.new(4, 0.3, 1.4), PALETTE.wood, CFrame.new(pos + Vector3.new(0, 1.2, 0)), model)
	local back = part("Back", Vector3.new(4, 1.2, 0.25), PALETTE.wood, CFrame.new(pos + Vector3.new(0, 1.95, -0.6)), model)
	for _, dx in ipairs({-1.7, 1.7}) do
		part("Leg" .. dx, Vector3.new(0.3, 1.2, 1.2), PALETTE.stone, CFrame.new(pos + Vector3.new(dx, 0.55, 0)), model)
	end
	model.PrimaryPart = seat
	return model
end

local function buildZundaFlower(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "ZundaFlower"
	local stem = part("Stem", Vector3.new(0.15, 1.6, 0.15), PALETTE.green, CFrame.new(pos + Vector3.new(0, 0.8, 0)), model, "nocollide")
	local colors = {PALETTE.pink, PALETTE.gold, Color3.fromRGB(255, 255, 255)}
	local bloom = part("Bloom", Vector3.new(0.9, 0.9, 0.9), colors[math.random(1, #colors)], CFrame.new(pos + Vector3.new(0, 1.7, 0)), model, "ball")
	bloom.CanCollide = false
	local center = part("Center", Vector3.new(0.35, 0.35, 0.35), PALETTE.gold, CFrame.new(pos + Vector3.new(0, 1.7, 0)), model, "ball")
	center.CanCollide = false
	model.PrimaryPart = stem
	return model
end

local function buildBerryBush(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "BerryBush"
	local base = part("Base", Vector3.new(2.6, 1.6, 2.6), PALETTE.green, CFrame.new(pos + Vector3.new(0, 0.8, 0)), model, "ball")
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local berryPos = pos + Vector3.new(math.cos(angle) * 1.0, 1.0 + math.sin(i) * 0.3, math.sin(angle) * 1.0)
		local berry = part("Berry" .. i, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(200, 60, 90), CFrame.new(berryPos), model, "ball")
		berry.CanCollide = false
		berry.Material = Enum.Material.Neon
	end
	model.PrimaryPart = base
	return model
end

local function buildZundaMushroom(pos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "ZundaMushroom"
	local stem = part("Stem", Vector3.new(0.6, 1.1, 0.6), PALETTE.cream, CFrame.new(pos + Vector3.new(0, 0.55, 0)), model, "cylinder")
	stem.Orientation = Vector3.new(0, 0, 90)
	local cap = part("Cap", Vector3.new(1.6, 0.9, 1.6), Color3.fromRGB(230, 90, 90), CFrame.new(pos + Vector3.new(0, 1.25, 0)), model, "ball")
	cap.CanCollide = false
	for i = 1, 3 do
		local dotPos = pos + Vector3.new(math.random(-5, 5) / 10, 1.55, math.random(-5, 5) / 10)
		local dot = part("Dot" .. i, Vector3.new(0.25, 0.1, 0.25), PALETTE.cream, CFrame.new(dotPos), model, "ball")
		dot.CanCollide = false
	end
	model.PrimaryPart = stem
	return model
end

local function buildStall(pos: Vector3, roofColor: Color3, name: string): Model
	-- Shared shape for BakeryStall/MarketHall -- small market kiosk with an
	-- awning roof, counter, and two support posts. Distinguished by roof
	-- color/size so they read as different buildings from a distance.
	local model = Instance.new("Model")
	model.Name = name
	local isHall = name == "MarketHall"
	local width = isHall and 10 or 6
	local depth = isHall and 8 or 5
	local height = isHall and 5 or 3.5

	local counter = part("Counter", Vector3.new(width, height * 0.55, depth), PALETTE.cream, CFrame.new(pos + Vector3.new(0, height * 0.275, 0)), model)
	local roof = part("Roof", Vector3.new(width + 1.4, 0.5, depth + 1.4), roofColor, CFrame.new(pos + Vector3.new(0, height * 0.55 + 0.6, 0)), model, "nocollide")
	roof.Material = Enum.Material.Fabric
	for _, corner in ipairs({Vector3.new(1, 1), Vector3.new(1, -1), Vector3.new(-1, 1), Vector3.new(-1, -1)}) do
		local postPos = pos + Vector3.new(corner.X * (width / 2 - 0.3), height * 0.275, corner.Y * (depth / 2 - 0.3))
		part("Post", Vector3.new(0.35, height * 0.55, 0.35), PALETTE.wood, CFrame.new(postPos), model)
	end
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(width * 0.55, 1, 0.15)
	sign.Color = PALETTE.gold
	sign.Anchored = true
	sign.CanCollide = false
	sign.CFrame = CFrame.new(pos + Vector3.new(0, height * 0.55 + 0.05, depth / 2 + 0.1))
	sign.Parent = model
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = isHall and "🏪" or "🥐"
	label.TextScaled = true
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = sign
	label.Parent = billboard

	model.PrimaryPart = counter
	return model
end

local BUILDERS: { [string]: (Vector3) -> Model } = {
	StreetLamp = buildStreetLamp,
	Bench = buildBench,
	ZundaFlower = buildZundaFlower,
	BerryBush = buildBerryBush,
	ZundaMushroom = buildZundaMushroom,
	BakeryStall = function(pos) return buildStall(pos, PALETTE.roof, "BakeryStall") end,
	MarketHall = function(pos) return buildStall(pos, PALETTE.mint, "MarketHall") end,
}

-- Returns a freshly-built Model for the given asset name at pos, or nil if no
-- procedural builder exists for that name (caller should skip placement).
function ProceduralPropBuilder.build(assetName: string, pos: Vector3): Model?
	local builder = BUILDERS[assetName]
	if not builder then
		return nil
	end
	local ok, model = pcall(builder, pos)
	if not ok then
		warn("[ProceduralPropBuilder] Failed to build " .. assetName .. ": " .. tostring(model))
		return nil
	end
	return model
end

return ProceduralPropBuilder
