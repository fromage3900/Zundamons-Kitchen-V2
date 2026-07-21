local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Matter = require(ReplicatedStorage.Packages.Matter)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local CookingHUD = require(StarterPlayer.StarterPlayerScripts.Client.UI.Cooking.Components.CookingHUD)
local CookingSession = require(ReplicatedStorage.Shared.Components.Cooking.CookingSession)
local CookingScore = require(ReplicatedStorage.Shared.Components.Cooking.CookingScore)

local LocalPlayer = Players.LocalPlayer

-- 1. Initialize the World
local world = Matter.World.new()
local loop = Matter.Loop.new(world)

-- 2. Load all Client Systems
local systems = {}
for _, child in ipairs(StarterPlayer.StarterPlayerScripts.Client.Systems:GetDescendants()) do
	if child:IsA("ModuleScript") then
		table.insert(systems, require(child))
	end
end

loop:scheduleSystems(systems)

-- 3. Start the Heartbeat Loop
loop:begin({
	default = RunService.RenderStepped,
})

-- 4. Mount the React UI Persistent HUD
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local root = ReactRoblox.createRoot(PlayerGui)

-- In a real scenario, this state would be driven by Reflex or a central UI Store
root:render(React.createElement(CookingHUD, {
	recipeName = "Zunda Apple Pie",
	duration = 15,
	timeElapsed = 0,
}))

print("[ClientMain] Matter ECS and React UI initialized successfully.")

-- 5. PoC Trigger: Fake a cooking session start after 3 seconds!
task.delay(3, function()
	print("Triggering Cooking Session PoC!")
	world:spawn(
		CookingSession({
			playerId = LocalPlayer.UserId,
			recipeId = "Zunda Apple Pie",
			startTime = os.clock(),
			duration = 15,
		}),
		CookingScore({
			perfectHits = 0,
			misses = 0,
			totalNotes = 0,
		})
	)
end)
