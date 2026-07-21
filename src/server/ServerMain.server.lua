local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Matter = require(ReplicatedStorage.Packages.Matter)
local DataManager = require(ServerScriptService.Server.Services.DataManager)

-- 1. Initialize the World
local world = Matter.World.new()
local loop = Matter.Loop.new(world)

-- 2. Load all Server Systems
local systems = {}
for _, child in ipairs(ServerScriptService.Server.Systems:GetDescendants()) do
	if child:IsA("ModuleScript") then
		table.insert(systems, require(child))
	end
end

loop:scheduleSystems(systems)

-- 3. Start the Heartbeat Loop
loop:begin({
	default = RunService.Heartbeat,
})

print("[ServerMain] Matter ECS and DataManager initialized successfully.")
