-- Run in Studio command bar:
--   require(game.ServerScriptService.DevTools["PopulateWorld.dev"]).populate()
-- This creates colored cube gathering nodes + guest spawn points in the world.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RESOURCE_COLORS = {
	Wheat = Color3.fromRGB(180, 200, 80),
	ZundaFlower = Color3.fromRGB(100, 200, 100),
	ZundaPea = Color3.fromRGB(180, 220, 80),
	["Zunda Mushroom"] = Color3.fromRGB(200, 180, 150),
	["Zunda Berry"] = Color3.fromRGB(220, 120, 160),
	["Zunda Root"] = Color3.fromRGB(160, 120, 80),
	Rock = Color3.fromRGB(160, 160, 160),
	["Gold Ore"] = Color3.fromRGB(255, 215, 0),
	EdamamePod = Color3.fromRGB(140, 200, 80),
	ZundaLeaf = Color3.fromRGB(80, 180, 80),
	SweetPea = Color3.fromRGB(200, 180, 100),
	PeaFlower = Color3.fromRGB(200, 120, 180),
}

local function ensureFolder(path)
	local parent = Workspace
	for _, name in ipairs(path) do
		local child = parent:FindFirstChild(name)
		if not child then
			child = Instance.new("Folder")
			child.Name = name
			child.Parent = parent
		end
		parent = child
	end
	return parent
end

local function spawnNode(nodeType, variantId, position)
	local color = RESOURCE_COLORS[nodeType] or Color3.fromRGB(100, 200, 130)
	local part = Instance.new("Part")
	part.Name = nodeType .. "_" .. (variantId or "01")
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part:SetAttribute("ResourceType", nodeType)
	part:SetAttribute("Available", true)
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 16
	cd.Parent = part
	CollectionService:AddTag(part, "GatheringNode")
	return part
end

local function populate()
	print("[PopulateWorld] Starting world population...")

	local gatherFolder = ensureFolder({ "GameplayLoopArea", "GatheringNodes" })

	-- Scatter gathering nodes in a grid around origin
	local center = Vector3.new(200, -515, -410)
	local resourceTypes = {
		{ "ZundaFlower", 3 }, { "ZundaPea", 3 }, { "Zunda Mushroom", 2 },
		{ "Zunda Berry", 3 }, { "Zunda Root", 2 }, { "Wheat", 3 },
		{ "Rock", 2 }, { "Gold Ore", 1 }, { "EdamamePod", 2 },
		{ "ZundaLeaf", 3 }, { "SweetPea", 2 }, { "PeaFlower", 2 },
	}

	local total = 0
	for x = -4, 4 do
		for z = -4, 4 do
			if math.random() < 0.5 then
				local ri = math.random(1, #resourceTypes)
				local rType = resourceTypes[ri]
				local pos = center + Vector3.new(x * 10 + math.random(-3, 3), 0, z * 10 + math.random(-3, 3))
				local surfacePos = Vector3.new(pos.X, center.Y, pos.Z) -- flat ground
				local node = spawnNode(rType[1], rType[1] .. "_" .. string.format("%02d", math.random(1, rType[2])), surfacePos)
				node.Parent = gatherFolder
				total = total + 1
			end
		end
	end
	print(string.format("[PopulateWorld] Spawned %d gathering nodes", total))

	-- Create guest spawn points
	local guestSpawns = ensureFolder({ "Guests" })
	for i = 1, 4 do
		local sp = Instance.new("Part")
		sp.Name = "GuestSpawn_" .. i
		sp.Size = Vector3.new(2, 1, 2)
		sp.Position = center + Vector3.new(12 + (i - 1) * 8, 0, 20)
		sp.Anchored = true
		sp.CanCollide = false
		sp.Transparency = 0.8
		sp.Color = Color3.fromRGB(200, 200, 100)
		sp.Parent = guestSpawns
		CollectionService:AddTag(sp, "GuestSpawn")
	end
	print("[PopulateWorld] Created 4 guest spawn points")

	-- Create patrol waypoints
	for i = 1, 6 do
		local wp = Instance.new("Part")
		wp.Name = "PatrolPoint_" .. i
		wp.Size = Vector3.new(1, 1, 1)
		wp.Position = center + Vector3.new(math.cos(math.rad(i * 60)) * 30, 0, math.sin(math.rad(i * 60)) * 30)
		wp.Anchored = true
		wp.CanCollide = false
		wp.Transparency = 1
		wp.Parent = Workspace
		CollectionService:AddTag(wp, "PatrolPoint")
	end
	print("[PopulateWorld] Created 6 patrol waypoints")

	-- Create scatter region (for ScatterService)
	local region = Instance.new("Part")
	region.Name = "ScatterRegion_Test"
	region.Size = Vector3.new(80, 10, 80)
	region.Position = center + Vector3.new(0, -5, -30)
	region.Anchored = true
	region.CanCollide = false
	region.Transparency = 0.9
	region.Color = Color3.fromRGB(100, 200, 100)
	region.Parent = Workspace
	region:SetAttribute("Biome", "zunda_forest")
	CollectionService:AddTag(region, "ScatterRegion")

	-- Also scatter via ScatterService if available
	local ok, scatterSvc = pcall(function()
		return require(ServerScriptService.Services.ScatterService)
	end)
	if ok and scatterSvc and scatterSvc.scatterBiome then
		task.delay(1, function()
			scatterSvc.scatterBiome("zunda_forest", region)
			print("[PopulateWorld] ScatterService completed biome scatter")
		end)
	else
		print("[PopulateWorld] ScatterService not available — manual scatter only")
	end

	print("[PopulateWorld] World population complete!")
	print("  Open the game and look for colored cubes as gathering nodes")
	print("  Guests will spawn at the yellow GuestSpawn parts")
	print("  NPCs will patrol the PatrolPoint waypoints")
end

return { populate = populate }
