-- [[LocalScript] HudBootstrap]]
-- Creates the main ZundaHUD with all action buttons
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- ZundaSoundController populates _G.ZundaSoundController in its own module body,
-- but nothing required it anywhere, so panel-open/close/hover/click sounds were
-- always silently no-op'd. This is the "wire everything up" entry point.
require(player:WaitForChild("PlayerScripts"):WaitForChild("Controllers"):WaitForChild("ZundaSoundController"))

-- Share one persistent root with HudScript regardless of LocalScript start order.
local existingHud = playerGui:FindFirstChild("ZundaHUD")
local hud = if existingHud and existingHud:IsA("ScreenGui") then existingHud else Instance.new("ScreenGui")
hud.Name = "ZundaHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.DisplayOrder = 10
hud.Parent = playerGui

print("[HudBootstrap] ZundaHUD created")

-- The bottom-right 8-icon button row (HudButtons) was deleted: the Pea Wheel
-- (same corner) now covers every one of these actions, so the row was pure
-- redundant clutter right next to it. Daily Planner (the one action that had
-- no other entry point) got a real keybind ("daily" in UIActionRegistry)
-- instead. Any leftover HudButtons frame from a previous session is destroyed
-- so it doesn't linger after this update.
local existingButtons = hud:FindFirstChild("HudButtons")
if existingButtons then
	existingButtons:Destroy()
end

-- Create StatBar (for XP, level, etc.)
local existingStatBar = hud:FindFirstChild("StatBar")
local statBar = if existingStatBar and existingStatBar:IsA("Frame") then existingStatBar else Instance.new("Frame")
statBar.Name = "StatBar"
-- AutomaticSize: content (gold/guests pills + weather chip) exceeds any fixed
-- width; a fixed 300px frame with centered layout pushed "Gold" off-screen left.
statBar.Size = UDim2.new(0, 0, 0, 40)
statBar.AutomaticSize = Enum.AutomaticSize.X
statBar.Position = UDim2.new(0, 20, 1, -60)
-- FIX: Use brighter background so StatBar is visible
statBar.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
statBar.BackgroundTransparency = 0.15
statBar.BorderSizePixel = 0
statBar.Parent = hud
Instance.new("UICorner", statBar).CornerRadius = UDim.new(0, 10)

print("[HudBootstrap] StatBar created")

print("[HudBootstrap] ZundaHUD fully initialized (button row retired — use Pea Wheel)")
