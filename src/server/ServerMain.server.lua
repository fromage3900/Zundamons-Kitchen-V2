--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Matter = require(ReplicatedStorage.Packages.Matter)
local FishingService = require(ServerScriptService.Services.FishingService)
local CookingService = require(ServerScriptService.Services.CookingService)

local systemsFolder = ServerScriptService:WaitForChild("systems")
local cookingSystems = systemsFolder:WaitForChild("cooking")

-- Explicit ordering prevents utility modules and unfinished proof-of-concept systems
-- from being scheduled merely because they exist under the systems folder.
local systems = {
	require(cookingSystems:WaitForChild("CookingValidationSystem")),
	require(systemsFolder:WaitForChild("FishingSystem")),
}

local world = Matter.World.new()
FishingService.attachWorld(world)
CookingService.attachWorld(world)
local loop = Matter.Loop.new(world)
loop:scheduleSystems(systems)
loop:begin({
	default = RunService.Heartbeat,
})

print(string.format("[ServerMain] Matter ECS initialized with %d registered system(s).", #systems))
