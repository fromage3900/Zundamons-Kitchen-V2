-- [[Script] SkySync (ref: RBXFB46CA2DA5074AAEBA729C4BD18F1812)]]
-- SkySync: Ties gameplay visuals to the realtime sky.
-- Flower PointLights brighten at night; planters tint when weather is wet.
-- Does not affect gather/serve/craft stats (see docs/atmosphere-gameplay-audit.md).

local Lighting = game:GetService("Lighting")
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SkyConfig = require(RS.ConfigurationFiles.SkyConfig)

-- Tracks PointLights on flower nodes (those have ResourceType attribute)
local trackedFlowers = {}

local function ensureFlowerLight(part)
	local light = part:FindFirstChildOfClass("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Brightness = 1.2
		light.Range = 6
		light.Color = part.Color
		light.Parent = part
	end
	return light
end

local function registerFlower(part)
	if not part:IsA("BasePart") then return end
	if not part:GetAttribute("ResourceType") then return end
	trackedFlowers[part] = true
	ensureFlowerLight(part)
end

local function scanForFlowers()
	local area = workspace:FindFirstChild("GameplayLoopArea")
	if not area then return end
	local g = area:FindFirstChild("GatheringNodes")
	if not g then return end
	for _, c in ipairs(g:GetChildren()) do registerFlower(c) end
	g.ChildAdded:Connect(function(c) task.wait(0.2) registerFlower(c) end)
end

-- Smooth ambient brightness pulse: brighter at night (3-10x)
local function getNightFactor(hour)
	local t = hour % 24
	-- 0 at noon, peaks at midnight
	local cos = math.cos(math.rad((t - 12) * 15))
	return math.max(0, -cos)  -- 0..1
end

local function updateFlowers()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local night = getNightFactor(hour)
	local weather = workspace:GetAttribute("WeatherFogMult") or 1.0
	local targetBrightness = 1.0 + night * 4 * weather
	local targetRange = 5 + night * 5
	for part, _ in pairs(trackedFlowers) do
		if part.Parent then
			local light = ensureFlowerLight(part)
			TweenService:Create(light, TweenInfo.new(0.6), {
				Brightness = targetBrightness,
				Range = targetRange,
			}):Play()
		else
			trackedFlowers[part] = nil
		end
	end
end

-- Planters react to weather (darker when rainy)
local function updatePlanters()
	local weather = workspace:GetAttribute("WeatherFogMult") or 1.0
	local wet = SkyConfig.weatherWetness(weather)
	for _, p in ipairs(CS:GetTagged("Planter")) do
		if p:IsA("BasePart") then
			local base = Color3.fromRGB(101, 67, 33)
			local wetCol = Color3.fromRGB(60, 40, 25)
			p.Color = base:Lerp(wetCol, wet)
		end
	end
end

-- WelcomeSign greeting changes by time of day
local function updateSigns()
	local area = workspace:FindFirstChild("GameplayLoopArea")
	if not area then return end
	local signs = area:FindFirstChild("InfoSigns")
	if not signs then return end
	local welcome = signs:FindFirstChild("WelcomeSign")
	if not welcome then return end
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local greeting = SkyConfig.welcomeGreeting(hour)
	for _, sg in ipairs(welcome:GetChildren()) do
		if sg:IsA("SurfaceGui") then
			local lbl = sg:FindFirstChildOfClass("TextLabel")
			if lbl then
				lbl.Text = greeting .. "\nZundymon's Kitchen\n\n1) Gather (N)\n2) Plant (E)\n3) Cook [K]\n4) Serve (S)\n5) Buy Plot (W)"
			end
		end
	end
end

-- Update everything on hour change
Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(function()
	updateFlowers()
	updateSigns()
end)
workspace:GetAttributeChangedSignal("WeatherFogMult"):Connect(function()
	updateFlowers()
	updatePlanters()
end)

-- Initial setup
task.wait(2)  -- Let SceneSetup build the area first
scanForFlowers()
updateFlowers()
updatePlanters()
updateSigns()

print("[SkySync] Ready - flowers and planters react to sky and weather")
