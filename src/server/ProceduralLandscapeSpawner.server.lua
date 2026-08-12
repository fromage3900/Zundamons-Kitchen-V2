--!strict
-- Spawns procedural landscape meshes in Workspace at game start.
-- Uses ArchitectureVariants mesh IDs for reliable spawning.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProceduralLandscape = require(ReplicatedStorage.Shared.Modules.ProceduralLandscape)
local ArchitectureVariants = require(ReplicatedStorage.Shared.Config.ArchitectureVariants)
local LandscapeConfig = require(ReplicatedStorage.Shared.Config.LandscapeConfig)
local ProceduralPropBuilder = require(ReplicatedStorage.Shared.Modules.ProceduralPropBuilder)

-- Every biome's placement plan uses small LOCAL coordinates (roughly -12..12
-- on each axis, per zone `size` in LandscapeConfig) -- they were never offset
-- to an actual world position. spawnMesh accepted a `zoneCenter` parameter
-- for exactly this but no caller ever passed one, so all 10 biomes' props
-- landed on top of each other in a ~10x10 stud clump near world origin
-- (confirmed live: 50 procedural props all within a few studs of (0,0,0)).
-- Spread across the same general playable area AnimalWildlife.server.lua
-- already scatters its wildlife across (X -140..195, Z -112..98), spaced far
-- enough apart (biome zone sizes max out around 24 studs) that biomes don't
-- overlap.
local BIOME_WORLD_CENTERS: { [string]: Vector3 } = {
	GardenVillage = Vector3.new(20, 0, -70),
	ZundaMarket = Vector3.new(90, 0, 60),
	Promenade = Vector3.new(-60, 0, -10),
	Forest = Vector3.new(-100, 0, -90),
	BerryOrchard = Vector3.new(150, 0, -20),
	MeadowPlaza = Vector3.new(60, 0, -80),
	SunsetGrove = Vector3.new(-40, 0, 70),
	WheatField = Vector3.new(130, 0, 30),
	WheatCrystalGarden = Vector3.new(-110, 0, 20),
	MoonlitGarden = Vector3.new(10, 0, 90),
}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundY(x: number, z: number): number
	local result = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), raycastParams)
	return result and result.Position.Y or 0
end

local function spawnMesh(placement, zoneCenter: Vector3)
	local category = placement.category or "street_props"
	local assetName = placement.asset or "Bench"
	local variantData = ArchitectureVariants[category] and ArchitectureVariants[category][assetName]
	local meshId = nil
	if variantData and variantData.meshes then
		for _, id in pairs(variantData.meshes) do
			meshId = id
			break
		end
	end
	local numericId = meshId and meshId ~= "" and tonumber(string.match(tostring(meshId), "%d+")) or nil

	local worldX = zoneCenter.X + placement.x
	local worldZ = zoneCenter.Z + placement.z
	local pos = Vector3.new(worldX, groundY(worldX, worldZ), worldZ)
	local parentFolder = Workspace:FindFirstChild("GameplayLoopArea") or Workspace

	if numericId then
		local mesh = Instance.new("MeshPart")
		mesh.Name = string.format("%s_%d_%d", placement.asset, placement.x, placement.z)
		mesh.MeshId = "rbxassetid://" .. numericId
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.Size = Vector3.new(2, 2, 2)
		mesh.Position = pos
		mesh.Parent = parentFolder
		mesh:SetAttribute("Category", category)
		mesh:SetAttribute("AssetName", assetName)
		return mesh
	end

	-- No real mesh id available (ArchitectureVariants only ever got 1 real
	-- entry checked in from the Kenney auto-mapper -- see ProceduralPropBuilder
	-- comment). Build authored-looking Part geometry instead of silently
	-- skipping the placement.
	local procedural = ProceduralPropBuilder.build(assetName, pos)
	if procedural then
		procedural:SetAttribute("Category", category)
		procedural:SetAttribute("AssetName", assetName)
		procedural:SetAttribute("Procedural", true)
		procedural.Parent = parentFolder
		return procedural
	end
	return nil
end

local function spawnBiome(biomeName)
	local plan = ProceduralLandscape.generateBiomePlan(biomeName)
	local zoneCenter = BIOME_WORLD_CENTERS[biomeName] or Vector3.new(0, 0, 0)
	local spawned = 0
	for _, placement in ipairs(plan.placements) do
		local mesh = spawnMesh(placement, zoneCenter)
		if mesh then
			spawned = spawned + 1
		end
	end
	print(string.format("[LandscapeSpawner] Spawned %d/%d meshes for biome '%s'", spawned, #plan.placements, biomeName))
	return spawned
end

-- Set to true if procedural fallback props should spawn on startup.
-- Defaults to false to preserve hand-placed Studio level geometry.
local ENABLE_PROCEDURAL_LANDSCAPE_SPAWN = false

local function spawnAllBiomes()
	if not ENABLE_PROCEDURAL_LANDSCAPE_SPAWN and not Workspace:GetAttribute("EnableProceduralLandscapeSpawner") then
		print(
			"[LandscapeSpawner] Procedural landscape spawner disabled — preserving hand-placed Studio level geometry"
		)
		return
	end

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
