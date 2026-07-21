--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Matter = require(ReplicatedStorage.Packages.Matter)

local systemsFolder = ServerScriptService:WaitForChild("systems")
local cookingSystems = systemsFolder:WaitForChild("cooking")

-- Explicit ordering prevents utility modules and unfinished proof-of-concept systems
-- from being scheduled merely because they exist under the systems folder.
local systems = {
	require(cookingSystems:WaitForChild("CookingValidationSystem")),
}

local world = Matter.World.new()
local loop = Matter.Loop.new(world)
loop:scheduleSystems(systems)
loop:begin({
	default = RunService.Heartbeat,
})

print(string.format("[ServerMain] Matter ECS initialized with %d registered system(s).", #systems))
