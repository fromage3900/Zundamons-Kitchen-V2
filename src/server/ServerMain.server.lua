--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Matter = require(ReplicatedStorage.Packages.Matter)
local FishingService = require(ServerScriptService.Services.FishingService)
local CookingService = require(ServerScriptService.Services.CookingService)
local LootModule = require(ReplicatedStorage.ConfigurationFiles.LootModule)

local systemsFolder = ServerScriptService:WaitForChild("systems")
local cookingSystems = systemsFolder:WaitForChild("cooking")

-- Explicit ordering prevents utility modules and unfinished proof-of-concept systems
-- from being scheduled merely because they exist under the systems folder.
local rawSystems = {
	require(cookingSystems:WaitForChild("CookingValidationSystem")),
	require(systemsFolder:WaitForChild("FishingSystem")),
}

-- Error isolation: a single failing system must never kill the whole Matter
-- heartbeat (which would freeze every ECS-driven session on the server).
local function guarded(system)
	return function(world, ...)
		local ok, err = pcall(system, world, ...)
		if not ok then
			warn(string.format("[ServerMain] Matter system error: %s", tostring(err)))
		end
	end
end

local systems = {}
for _, system in ipairs(rawSystems) do
	table.insert(systems, guarded(system))
end

local world = Matter.World.new()
FishingService.attachWorld(world)
CookingService.attachWorld(world)
local loop = Matter.Loop.new(world)
loop:scheduleSystems(systems)
loop:begin({
	default = RunService.Heartbeat,
})

print(string.format("[ServerMain] Matter ECS initialized with %d registered system(s).", #systems))
