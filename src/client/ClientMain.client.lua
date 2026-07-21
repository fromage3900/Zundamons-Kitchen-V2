--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.Packages.Matter)

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local systemsFolder = playerScripts:WaitForChild("systems")

-- Only production-safe systems are registered. ContentPreloader is a utility module,
-- and the cooking input proof of concept is intentionally not scheduled.
local systems = {
	require(systemsFolder:WaitForChild("CompanionFollowSystem")),
	require(systemsFolder:WaitForChild("StreamingSystem")),
}

local world = Matter.World.new()
local loop = Matter.Loop.new(world)
loop:scheduleSystems(systems)
loop:begin({
	default = RunService.RenderStepped,
})

print(string.format("[ClientMain] Matter ECS initialized with %d registered system(s).", #systems))
