local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Track the created adornments directly so the per-frame update never has to
-- scan the whole workspace (that scan was a major source of frame-time cost).
local adorns = {}

local function applyWireframe(part)
	if part:FindFirstChildOfClass("WireframeHandleAdornment") then return end

	local adorn = Instance.new("WireframeHandleAdornment")
	adorn.Color3 = Color3.fromRGB(40, 35, 55)
	adorn.Transparency = 0.88
	adorn.Thickness = 0.3
	adorn.AlwaysOnTop = false
	adorn.ZIndex = 1
	adorn.Adornee = part
	adorn.Parent = part
	adorns[adorn] = true
	adorn.AncestryChanged:Connect(function(_, parent)
		if not parent then
			adorns[adorn] = nil
		end
	end)
end

for _, part in ipairs(workspace:GetDescendants()) do
	if part:IsA("BasePart") and not part:IsA("Terrain") then
		if CollectionService:HasTag(part, "CelOutline") then
			applyWireframe(part)
		end
	end
end

CollectionService:GetInstanceAddedSignal("CelOutline"):Connect(applyWireframe)

-- The look tracks weather/time, which change slowly; updating at ~15 Hz over the
-- cached adornment set is visually identical and far cheaper than a per-frame
-- full-workspace descendant scan.
local UPDATE_INTERVAL = 1 / 15
local accum = UPDATE_INTERVAL
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t = t + dt
	accum += dt
	if accum < UPDATE_INTERVAL then return end
	accum = 0

	local weather = workspace:GetAttribute("CurrentWeather") or "clear"
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local isNight = hour <= 5 or hour >= 19.5

	local weight = 1
	if weather == "storm" then weight = 3
	elseif weather == "rain" then weight = 2.5
	elseif weather == "fog" then weight = 2
	elseif weather == "snow" then weight = 1.8
	elseif weather == "cloudy" then weight = 1.3
	elseif weather == "aurora" then weight = 1.6
	elseif weather == "cherry_blossom" then weight = 0.7
	end
	if isNight then weight = weight * 1.2 end

	local breath = 0.85 + 0.05 * math.sin(t * 0.3)
	local trans = math.clamp(breath - (weight - 1) * 0.04, 0.75, 0.95)
	local thick = 0.2 + weight * 0.15

	local color
	if weather == "rain" or weather == "storm" then
		color = Color3.fromRGB(60, 55, 80)
	elseif weather == "aurora" then
		color = Color3.fromRGB(55, 50, 90)
	else
		color = Color3.fromRGB(40, 35, 55)
	end

	for adorn in pairs(adorns) do
		adorn.Transparency = trans
		adorn.Thickness = thick
		adorn.Color3 = color
	end
end)

print("[WireframeOutline] Wireframe cel outlines active — tag parts with 'CelOutline' in Studio")
