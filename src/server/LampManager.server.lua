local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LAMP_TAG = "LampManager_Active"

local function findOrCreateSpotLight(part)
	local existing = part:FindFirstChildOfClass("SpotLight")
	if existing then return existing end
	local light = Instance.new("SpotLight")
	light.Brightness = 1
	light.Face = Enum.NormalId.Bottom
	light.Range = 60
	light.Angle = 120
	light.Shadows = true
	light.Color = Color3.fromRGB(255, 237, 183)
	light.Enabled = false
	light.Parent = part
	return light
end

local function isNight(hour)
	return hour >= 17.5 or hour < 6
end

local function updateLamp(part, hour)
	local light = findOrCreateSpotLight(part)
	local night = isNight(hour)
	if night and not light.Enabled then
		light.Enabled = true
		light.Brightness = 1
	elseif not night and light.Enabled then
		light.Enabled = false
	end
end

local function scanForLamps()
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "LightPart" then
			local hour = Lighting:GetMinutesAfterMidnight() / 60
			updateLamp(part, hour)
		end
	end
end

local function onDescendantAdded(inst)
	task.delay(0.5, function()
		if inst:IsA("BasePart") and inst.Name == "LightPart" then
			local hour = Lighting:GetMinutesAfterMidnight() / 60
			updateLamp(inst, hour)
		end
	end)
end

workspace.DescendantAdded:Connect(onDescendantAdded)

Lighting.Changed:Connect(function(prop)
	if prop == "MinutesAfterMidnight" or prop == "ClockTime" then
		scanForLamps()
	end
end)

if RunService:IsServer() then
	task.spawn(function()
		while true do
			task.wait(60)
			local hour = Lighting:GetMinutesAfterMidnight() / 60
			scanForLamps()
		end
	end)
end

scanForLamps()
print("[LampManager] Active — managing LightPart spotlights across workspace")
