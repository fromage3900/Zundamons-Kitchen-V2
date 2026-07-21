--!strict
-- Spawns procedural landscape meshes in Workspace at game start.
-- Uses ArchitectureVariants mesh IDs for reliable spawning.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProceduralLandscape = require(ReplicatedStorage.Shared.Modules.ProceduralLandscape)
local ArchitectureVariants = require(ReplicatedStorage.Shared.Config.ArchitectureVariants)
local LandscapeConfig = require(ReplicatedStorage.Shared.Config.LandscapeConfig)

local function spawnMesh(placement, zoneCenter)
	local category = placement.category or "street_props"
	local assetName = placement.asset or "Bench"
	local variantData = ArchitectureVariants[category] and ArchitectureVariants[category][assetName]
	if not variantData or not variantData.meshes then
		return nil
	end
	local meshId = nil
	for _, id in pairs(variantData.meshes) do
		meshId = id
		break
	end
	if not meshId or meshId == "" then
		return nil
	end
	local numericId = tonumber(string.match(tostring(meshId), "%d+"))
	if not numericId then
		return nil
	end
	local mesh = Instance.new("MeshPart")
	mesh.Name = string.format("%s_%d_%d", placement.asset, placement.x, placement.z)
	mesh.MeshId = "rbxassetid://" .. numericId
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.Size = Vector3.new(2, 2, 2)
	mesh.Position = Vector3.new(placement.x, 0, placement.z)
	mesh.Parent = Workspace:FindFirstChild("GameplayLoopArea") or Workspace
	mesh:SetAttribute("Category", category)
	mesh:SetAttribute("AssetName", assetName)
	return mesh
end

local function spawnBiome(biomeName)
	local plan = ProceduralLandscape.generateBiomePlan(biomeName)
	local spawned = 0
	for _, placement in ipairs(plan.placements) do
		local mesh = spawnMesh(placement)
		if mesh then
			spawned = spawned + 1
		end
	end
	print(string.format("[LandscapeSpawner] Spawned %d/%d meshes for biome '%s'", spawned, #plan.placements, biomeName))
	return spawned
end

local function spawnAllBiomes()
	local gameArea = Workspace:FindFirstChild("GameplayLoopArea")
	for biomeName in pairs(LandscapeConfig.biomes) do
		task.spawn(function()
			spawnBiome(biomeName)
		end)
		task.wait(0.1)
	end
	print("[LandscapeSpawner] All biomes spawned")
end

spawnAllBiomes()
