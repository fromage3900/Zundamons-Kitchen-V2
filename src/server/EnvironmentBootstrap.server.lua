--!strict
-- [[Script] EnvironmentBootstrap (ref: NEW)]]
-- Initializes environment systems on game start.
-- Wires ScatterService to region volumes, sets up initial biomes.

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Get ScatterService from Services folder (preferred)
local ScatterService
local servicesFolder = ServerScriptService:FindFirstChild("Services")
if servicesFolder then
	local scatterModule = servicesFolder:FindFirstChild("ScatterService")
	if scatterModule then
		ScatterService = require(scatterModule)
	end
end
-- Fallback: use a stub if ScatterService is unavailable
if not ScatterService then
	local configFolder = ReplicatedStorage:FindFirstChild("ConfigurationFiles")
	if configFolder then
		local sc = configFolder:FindFirstChild("ScatterConfig")
		if sc then
			ScatterService = require(sc)
		end
	end
	if not ScatterService then
		ScatterService = { scatterBiome = function() end, clearBiome = function() end, clearAll = function() end }
		warn("[EnvironmentBootstrap] ScatterService unavailable — using stub")
	end
end

-- Tag regions in Studio with "ScatterRegion" and a "Biome" attribute
-- to auto-scatter them on game load.

local function bootstrapEnvironment()
	print("[EnvironmentBootstrap] Scattering environment biomes...")

	-- Auto-scatter tagged regions
	for _, region in ipairs(CollectionService:GetTagged("ScatterRegion")) do
		local biomeName = region:GetAttribute("Biome") or "zunda_forest"
		task.spawn(function()
			task.wait(0.5)
			if ScatterService and ScatterService.scatterBiome then
				ScatterService.scatterBiome(biomeName, region)
			end
		end)
	end

	-- If no ScatterRegion tags exist, scatter default biomes in gameplay area
	local gameplayArea = Workspace:FindFirstChild("GameplayLoopArea")
	if gameplayArea and #CollectionService:GetTagged("ScatterRegion") == 0 then
		task.delay(2, function()
			if ScatterService and ScatterService.scatterBiome then
				ScatterService.scatterBiome("zunda_forest", gameplayArea)
			end
		end)
	end

	-- Connect to CollectionService for new regions added at runtime
	CollectionService:GetInstanceAddedSignal("ScatterRegion"):Connect(function(region)
		task.wait(0.5)
		local biomeName = region:GetAttribute("Biome") or "zunda_forest"
		if ScatterService and ScatterService.scatterBiome then
			ScatterService.scatterBiome(biomeName, region)
		end
	end)

	print("[EnvironmentBootstrap] Environment scattered")
end

local function bootstrapNPC()
	print("[EnvironmentBootstrap] Initializing NPC systems...")
	-- GuestManager auto-starts as standalone script in ServerScriptService.
	-- ZoneAssets/GuestTemplate folder created by ensureWorkspaceStructure above.
	-- GuestManager uses WaitForChild so ordering is safe regardless.
	print("[EnvironmentBootstrap] NPC systems ready")
end

-- Ensure workspace folders exist
local function ensureWorkspaceStructure()
	local requiredFolders = {
		"GameplayLoopArea",
		"Guests",
		"ZoneAssets",
		"Zones",
		"BuildingInteriors",
		"TeleporterPads",
		"Houses",
		"Constellations",
		"LocalSounds",
		"LootFolder",
	}

	for _, folderName in ipairs(requiredFolders) do
		if not Workspace:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = Workspace
		end
	end

	-- Ensure GatheringNodes subfolder
	local loopArea = Workspace:FindFirstChild("GameplayLoopArea")
	if loopArea and not loopArea:FindFirstChild("GatheringNodes") then
		local gatherFolder = Instance.new("Folder")
		gatherFolder.Name = "GatheringNodes"
		gatherFolder.Parent = loopArea
	end
end

ensureWorkspaceStructure()
-- DISABLED: bootstrapEnvironment() — manual scatter only
-- DISABLED: landscape spawner auto-run
bootstrapNPC()

return ScatterService
