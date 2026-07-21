local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Matter = require(ReplicatedStorage.Packages.Matter)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local CookingHUD = require(script.Parent.ui.cooking.components.CookingHUD)
local InventoryHUD = require(script.Parent.ui.inventory.components.InventoryHUD)
local CookingSession = require(ReplicatedStorage.Shared.Components.Cooking.CookingSession)
local CookingScore = require(ReplicatedStorage.Shared.Components.Cooking.CookingScore)
local ItemDrop = require(ReplicatedStorage.Shared.Components.ItemDrop)

local LocalPlayer = Players.LocalPlayer

-- 1. Initialize the World
local world = Matter.World.new()
local loop = Matter.Loop.new(world)

-- 2. Load all Client Systems
local systems = {}
if script.Parent:FindFirstChild("systems") then
	for _, child in ipairs(script.Parent.systems:GetDescendants()) do
		if child:IsA("ModuleScript") then
			table.insert(systems, require(child))
		end
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
root:render(React.createElement(React.Fragment, nil, {
	CookingHUD = React.createElement(CookingHUD, {
		recipeName = "Zunda Apple Pie",
		duration = 15,
		timeElapsed = 0,
		visible = false,
	}),
	InventoryHUD = React.createElement(InventoryHUD)
}))

print("[ClientMain] Matter ECS and React UI initialized successfully.")

-- 6. PoC Trigger: Fake an item drop collection after 5 seconds!
task.delay(5, function()
	print("Triggering ItemDrop PoC!")
	world:spawn(
		ItemDrop({
			targetPlayerId = LocalPlayer.UserId,
			itemName = "Zunda Berry",
			quantity = 10,
		})
	)
end)
