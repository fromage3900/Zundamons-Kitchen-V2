local kitchenCenter = Vector3.new(0, 10, 0)

local zones = {
	{
		name = "Kitchen",
		position = kitchenCenter,
		size = Vector3.new(24, 8, 18),
		preset = "SmallRoom",
	},
	{
		name = "Garden",
		position = kitchenCenter + Vector3.new(40, 5, 20),
		size = Vector3.new(30, 10, 30),
		preset = "Valley",
	},
	{
		name = "Pond",
		position = kitchenCenter + Vector3.new(15, 5, -30),
		size = Vector3.new(20, 8, 20),
		preset = "LargeRoom",
	},
}

for _, z in ipairs(zones) do
	local part = Instance.new("Part")
	part.Name = "ReverbZone_" .. z.name
	part.Size = z.size
	part.Position = z.position
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = true
	part.Transparency = 1
	part.Parent = workspace
	part:SetAttribute("ReverbPreset", z.preset)
end

print("[ReverbZones] Reverb zone triggers placed — Kitchen/Garden/Pond")
