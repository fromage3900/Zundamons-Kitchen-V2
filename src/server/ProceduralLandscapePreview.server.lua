--!strict
-- Server-side preview spawner for the first procedural landscape layout.
-- This loads the imported Kenney-style models into Workspace to visualize the generated plan.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local ProceduralLandscape = require(ReplicatedStorage.Shared.Modules.ProceduralLandscape)

local function createMarker(name, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(2, 1, 2)
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = Workspace
	return part
end

local function spawnPreview()
	local plan = ProceduralLandscape.generateBiomePlan("ZundaMarket", { seed = 77 })
	local folder = Instance.new("Folder")
	folder.Name = "ProceduralLandscapePreview"
	folder.Parent = Workspace

	for index, placement in ipairs(plan.placements) do
		local targetPosition = Vector3.new(placement.x or 0, 0, placement.z or 0)
		local assetId = placement.assetId
		local numericId = assetId and tonumber(string.match(assetId, "%d+"))

		if numericId then
			local success, loadedAsset = pcall(function()
				return InsertService:LoadAsset(numericId)
			end)

			if success and loadedAsset then
				loadedAsset.Name = string.format("%s_%d", placement.asset, index)
				loadedAsset.Parent = folder
				loadedAsset:PivotTo(CFrame.new(targetPosition) * CFrame.Angles(0, math.rad(index * 15), 0))
				loadedAsset:SetAttribute("Category", placement.category or "unknown")
				loadedAsset:SetAttribute("AssetName", placement.asset or "")
				loadedAsset:SetAttribute("Score", placement.score or 0)
				continue
			end
		end

		local marker = createMarker(
			string.format("%s_%d", placement.asset, index),
			targetPosition + Vector3.new(0, 1.5, 0),
			placement.isPlaceholder and Color3.fromRGB(255, 180, 80) or Color3.fromRGB(90, 200, 120)
		)
		marker.Parent = folder
		marker:SetAttribute("Category", placement.category or "unknown")
		marker:SetAttribute("AssetName", placement.asset or "")
		marker:SetAttribute("Score", placement.score or 0)
	end

	print(string.format("Procedural landscape preview spawned with %d placements", #plan.placements))
end

spawnPreview()
