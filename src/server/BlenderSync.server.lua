-- [[Script] BlenderSync (ref: RBXDC462DA887E940BB9EDA43B311156837)]]
-- BlenderSync: Roblox-side ingestion for greybox snapshots from Blender.
-- Exposes _G.applyBlenderSync(snapshot) which Claude calls via execute_luau.
--
-- snapshot format (Lua):
--   {
--     scale = 4,                       -- studs per Blender meter (default 4)
--     origin = {0, -519, -440},        -- Roblox world position of Blender (0,0,0)
--     objects = {
--         {name="Cube.001", shape="Block", pos={x,y,z}, rot={x,y,z}, size={x,y,z}, color={r,g,b}, material="SmoothPlastic"},
--         ...
--     },
--   }
--
-- Coordinates: Blender is Z-up, Roblox is Y-up.
-- Conversion: roblox_pos = origin + (bx*scale, bz*scale, -by*scale)
--             roblox_rot = (rx_deg, -rz_deg, ry_deg)

local DEFAULT_ORIGIN = Vector3.new(0, -519, -440)
local DEFAULT_SCALE  = 4

-- All synced parts live here so we can diff/cleanup orphans
local folder = workspace:FindFirstChild("BlenderSync")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "BlenderSync"
	folder.Parent = workspace
end

-- Map blender object name -> Roblox Part
local liveParts = {}
for _, p in ipairs(folder:GetChildren()) do
	if p:IsA("BasePart") then liveParts[p.Name] = p end
end

local function shapeFromString(s)
	if s == "Ball" or s == "Sphere" then return Enum.PartType.Ball
	elseif s == "Cylinder" then return Enum.PartType.Cylinder
	elseif s == "Wedge" then return Enum.PartType.Wedge
	else return Enum.PartType.Block end
end

local function materialFromString(s)
	if not s then return Enum.Material.SmoothPlastic end
	local ok, m = pcall(function() return Enum.Material[s] end)
	if ok and m then return m end
	return Enum.Material.SmoothPlastic
end

function _G.applyBlenderSync(snapshot)
	if type(snapshot) ~= "table" then return "snapshot not a table" end
	local scale = snapshot.scale or DEFAULT_SCALE
	local origin = snapshot.origin and Vector3.new(snapshot.origin[1], snapshot.origin[2], snapshot.origin[3]) or DEFAULT_ORIGIN
	local seen = {}
	local created, updated, removed = 0, 0, 0

	for _, obj in ipairs(snapshot.objects or {}) do
		local name = obj.name or "Unnamed"
		seen[name] = true
		local part = liveParts[name]
		if not part then
			part = Instance.new("Part")
			part.Name = name
			part.Anchored = true
			part.Parent = folder
			liveParts[name] = part
			created = created + 1
		else
			updated = updated + 1
		end

		part.Shape = shapeFromString(obj.shape or "Block")
		part.Material = materialFromString(obj.material)

		-- Position: Blender (x,y,z) Z-up  ->  Roblox (x*s, z*s, -y*s) plus origin
		local bx, by, bz = obj.pos[1] or 0, obj.pos[2] or 0, obj.pos[3] or 0
		local pos = origin + Vector3.new(bx * scale, bz * scale, -by * scale)

		-- Size: Blender dimensions in meters -> studs
		local sx = math.max(0.05, (obj.size[1] or 1) * scale)
		local sy = math.max(0.05, (obj.size[3] or 1) * scale)  -- height = blender Z
		local sz = math.max(0.05, (obj.size[2] or 1) * scale)  -- depth = blender Y
		part.Size = Vector3.new(sx, sy, sz)

		-- Rotation: Blender (rx,ry,rz) radians -> Roblox CFrame.Angles with axis remap
		local rx = obj.rot[1] or 0
		local ry = obj.rot[2] or 0
		local rz = obj.rot[3] or 0
		part.CFrame = CFrame.new(pos) * CFrame.fromEulerAnglesXYZ(rx, rz, -ry)

		if obj.color then
			part.Color = Color3.new(
				math.clamp(obj.color[1] or 0.5, 0, 1),
				math.clamp(obj.color[2] or 0.5, 0, 1),
				math.clamp(obj.color[3] or 0.5, 0, 1)
			)
		end
	end

	-- Remove orphans (parts that no longer exist in Blender)
	for name, part in pairs(liveParts) do
		if not seen[name] then
			part:Destroy()
			liveParts[name] = nil
			removed = removed + 1
		end
	end

	return string.format("BlenderSync: +%d new, ~%d updated, -%d removed (%d total)",
		created, updated, removed, #folder:GetChildren())
end

print("[BlenderSync] Ready - call _G.applyBlenderSync(snapshot)")
