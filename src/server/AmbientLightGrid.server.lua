local Lighting = game:GetService("Lighting")

local kitchenCenter = Vector3.new(0, 10, 0)

local zones = {
	{
		name = "CookingCounter",
		pos = kitchenCenter + Vector3.new(8, 8, 5),
		color = Color3.fromRGB(255, 235, 210),
		brightness = 2.5, angle = 60, range = 30,
	},
	{
		name = "Fireplace",
		pos = kitchenCenter + Vector3.new(-14, 6, 10),
		color = Color3.fromRGB(255, 180, 120),
		brightness = 3.0, angle = 70, range = 25,
	},
	{
		name = "GardenPath",
		pos = kitchenCenter + Vector3.new(30, 10, 25),
		color = Color3.fromRGB(200, 210, 255),
		brightness = 1.5, angle = 50, range = 40,
	},
	{
		name = "PondWater",
		pos = kitchenCenter + Vector3.new(18, 8, -25),
		color = Color3.fromRGB(180, 220, 240),
		brightness = 1.8, angle = 55, range = 35,
	},
	{
		name = "Entrance",
		pos = kitchenCenter + Vector3.new(-25, 10, -15),
		color = Color3.fromRGB(255, 220, 170),
		brightness = 2.0, angle = 65, range = 30,
	},
	{
		name = "DiningArea",
		pos = kitchenCenter + Vector3.new(0, 7, 20),
		color = Color3.fromRGB(255, 225, 200),
		brightness = 2.2, angle = 70, range = 28,
	},
}

local gridFolder = Instance.new("Folder")
gridFolder.Name = "AmbientLightGrid"
gridFolder.Parent = workspace

for _, z in ipairs(zones) do
	local part = Instance.new("Part")
	part.Name = z.name .. "Light"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = z.pos
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Parent = gridFolder

	local light = Instance.new("SpotLight")
	light.Brightness = z.brightness
	light.Color = z.color
	light.Angle = z.angle
	light.Range = z.range
	light.Shadows = true
	light.Face = Enum.NormalId.Bottom
	light.Parent = part
end

local function onWeatherChanged(weatherKey)
	for _, child in ipairs(gridFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local light = child:FindFirstChildOfClass("SpotLight")
			if light then
				if weatherKey == "rain" or weatherKey == "storm" then
					light.Brightness = light.Brightness * 0.3
					light.Shadows = false
				elseif weatherKey == "fog" or weatherKey == "snow" then
					light.Brightness = light.Brightness * 0.6
					light.Shadows = true
				else
					light.Shadows = true
				end
			end
		end
	end
end

workspace:GetAttributeChangedSignal("CurrentWeather"):Connect(function()
	onWeatherChanged(workspace:GetAttribute("CurrentWeather") or "clear")
end)

task.wait(2)
onWeatherChanged(workspace:GetAttribute("CurrentWeather") or "clear")

print("[AmbientLightGrid] 6 shadow-casting SpotLights active")
