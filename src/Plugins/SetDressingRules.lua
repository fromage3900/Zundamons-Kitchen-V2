--!strict
-- SetDressingRules: Distant vistas and weather-reactive decorations
-- Infinity Nikki aesthetic: dreamy backgrounds and weather-appropriate styling
local SetDressingRules = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

SetDressingRules.vistaTemplates = {
	rolling_hills = {
		name = "Rolling Hills",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_RollingHills"
			for i = 1, 12 do
				local hill = Instance.new("Part")
				hill.Size = Vector3.new(30, 8, 30)
				hill.CFrame = CFrame.new(position.X + i * 20 - 120, position.Y + math.sin(i * 0.5) * 3, position.Z + distance)
				hill.Color = Color3.fromRGB(160, 210, 150)
				hill.Anchored = true
				hill.CanCollide = false
				hill.Material = Enum.Material.SmoothPlastic
				hill.Transparency = 0.3
				hill.Name = "Hill_" .. i
				hill.Parent = model
			end
			return model
		end,
	},
	pagoda_silhouette = {
		name = "Pagoda Silhouette",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_Pagoda"
			for i = 1, 5 do
				local tier = Instance.new("Part")
				tier.Size = Vector3.new(15 - i * 2, 2, 15 - i * 2)
				tier.CFrame = CFrame.new(position.X, position.Y + i * 3, position.Z + distance)
				tier.Color = Color3.fromRGB(255, 240, 245)
				tier.Anchored = true
				tier.CanCollide = false
				tier.Name = "Tier_" .. i
				tier.Parent = model
			end
			return model
		end,
	},
	floating_crystals = {
		name = "Floating Crystals",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_FloatingCrystals"
			for i = 1, 8 do
				local crystal = Instance.new("Wedge")
				crystal.Size = Vector3.new(1, 3, 1)
				crystal.CFrame = CFrame.new(position.X + (i - 4) * 5, position.Y + math.sin(i * 0.7) * 4, position.Z + distance)
				crystal.Color = Color3.fromRGB(200, 182, 255)
				crystal.Anchored = true
				crystal.CanCollide = false
				crystal.Transparency = 0.15
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(200, 182, 255)
				light.Range = 12
				light.Brightness = 1.0
				light.Parent = crystal
				crystal.Parent = model
			end
			return model
		end,
	},
	snow_capped_peaks = {
		name = "Snow Capped Peaks",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_SnowPeaks"
			for i = 1, 6 do
				local peak = Instance.new("Wedge")
				peak.Size = Vector3.new(2, 20, 2)
				peak.CFrame = CFrame.new(position.X + (i - 3) * 15, position.Y + 10, position.Z + distance)
				peak.Color = Color3.fromRGB(255, 255, 255)
				peak.Anchored = true
				peak.CanCollide = false
				peak.Name = "Peak_" .. i
				peak.Parent = model
			end
			return model
		end,
	},
	ruin_silhouette = {
		name = "Ruin Silhouette",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_Ruins"
			for i = 1, 4 do
				local column = Instance.new("Cylinder")
				column.Size = Vector3.new(2, 15, 2)
				column.CFrame = CFrame.new(position.X + (i - 2) * 8, position.Y + 7.5, position.Z + distance)
				column.Color = Color3.fromRGB(200, 200, 200)
				column.Anchored = true
				column.CanCollide = false
				column.Name = "Column_" .. i
				column.Parent = model
			end
			return model
		end,
	},
	kitchen_garden = {
		name = "Kitchen Garden",
		parts = function(position, distance)
			local model = Instance.new("Model")
			model.Name = "Vista_KitchenGarden"
			for i = 1, 6 do
				local plant = Instance.new("Cylinder")
				plant.Size = Vector3.new(0.5, 1.5, 0.5)
				plant.CFrame = CFrame.new(position.X + (i - 3) * 3, position.Y + 0.75, position.Z + distance)
				plant.Color = Color3.fromRGB(255, 150, 200)
				plant.Anchored = true
				plant.CanCollide = false
				plant.Name = "Plant_" .. i
				plant.Parent = model
			end
			return model
		end,
	},
}

function SetDressingRules.generateVista(vistaConfig)
	if not vistaConfig or not vistaConfig.type then
		warn("[SetDressingRules] No vista config provided")
		return nil
	end

	local template = SetDressingRules.vistaTemplates[vistaConfig.type]
	if not template then
		warn("[SetDressingRules] Unknown vista type: " .. tostring(vistaConfig.type))
		return nil
	end

	local position = Vector3.new(0, 0, 0)
	local distance = vistaConfig.distance or 200
	local model = template.parts(position, distance)
	model.Parent = Workspace

	print("[SetDressingRules] Generated vista: " .. vistaConfig.type)
	return model
end

function SetDressingRules.applyWeatherReactions(zoneName, reactions)
	if not reactions or next(reactions) == nil then
		return
	end

	local ZoneProfiles = require(script:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("ZoneProfiles"))
	local zone = ZoneProfiles.getZone(zoneName)
	if not zone then return end

	for weatherType, decorationTypes in pairs(reactions) do
		print("[SetDressingRules] Weather reaction for " .. weatherType .. " in " .. zoneName)
		for _, decoType in ipairs(decorationTypes) do
			print("  - Would enhance " .. decoType .. " for " .. weatherType)
		end
	end
end

function SetDressingRules.generateWeatherReactors(zoneName, decorationInstances)
	for _, inst in ipairs(decorationInstances or {}) do
		if inst and inst:IsA("Model") then
			inst:SetAttribute("WeatherReactors", true)
			local lights = inst:GetDescendants()
			for _, obj in ipairs(lights) do
				if obj:IsA("PointLight") then
					obj.Brightness = obj.Brightness * 1.5
				end
			end
		end
	end
end

return SetDressingRules
