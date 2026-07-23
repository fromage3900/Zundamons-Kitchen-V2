local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChild("Terrain")
if not Terrain then return end

local C_day = Color3.fromRGB(110, 190, 215)
local C_dawn = Color3.fromRGB(160, 150, 215)
local C_dusk = Color3.fromRGB(175, 165, 195)
local C_night = Color3.fromRGB(55, 50, 95)

local function getWaterColor(hour)
	if hour >= 5 and hour < 8 then
		return C_day:Lerp(C_dawn, 1 - (hour - 5) / 3)
	elseif hour >= 8 and hour < 17 then
		return C_day
	elseif hour >= 17 and hour < 20 then
		return C_day:Lerp(C_dusk, (hour - 17) / 3)
	elseif hour >= 20 and hour < 22 then
		return C_dusk:Lerp(C_night, (hour - 20) / 2)
	else
		return C_night:Lerp(C_dawn, math.sin((hour - 22) / 7 * math.pi) * 0.4)
	end
end

local function applyWater(hour)
	local color = getWaterColor(hour)
	Terrain.WaterColor = color
	Terrain.WaterReflectance = 0.85
	Terrain.WaterTransparency = 0.20
	Terrain.WaterWaveSize = 0.35

	pcall(function()
		Terrain.MaterialColors[Enum.Material.Water] = color
		Terrain.MaterialColors[Enum.Material.DeepWater] = color:Lerp(Color3.fromRGB(40, 35, 80), 0.3)
	end)
end

local startHour = Lighting:GetAttribute("CurrentHour") or 12
applyWater(startHour)

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t = t + dt
	if not Terrain then return end

	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local wavePulse = 0.28 + math.sin(t * 0.12) * 0.12
	local transPulse = 0.18 + math.sin(t * 0.06) * 0.06
	local refPulse = 0.82 + math.sin(t * 0.09) * 0.06

	local color = getWaterColor(hour)
	Terrain.WaterColor = color
	Terrain.WaterReflectance = refPulse
	Terrain.WaterTransparency = transPulse
	Terrain.WaterWaveSize = wavePulse

	pcall(function()
		Terrain.MaterialColors[Enum.Material.Water] = color
	end)
end)

Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	applyWater(hour)
end)

print("[WaterConfig] Dreamy reflective water active")
