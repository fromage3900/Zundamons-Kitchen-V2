local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ZundaChromaticAberration") then return end

local gui = Instance.new("ScreenGui")
gui.Name = "ZundaChromaticAberration"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 15
gui.Parent = playerGui

local function makeChannel(offsetX, offsetY, tint, trans)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1.5, 0, 1.5, 0)
	img.Position = UDim2.new(-0.25 + offsetX, 0, -0.25 + offsetY, 0)
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://118798592641142"
	img.ImageColor3 = tint
	img.ImageTransparency = trans
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.new(0, 4, 0, 4)
	img.ZIndex = 1
	img.Parent = gui
	return img
end

local rLayer = makeChannel(0.002, 0, Color3.fromRGB(255, 60, 60), 0.97)
local gLayer = makeChannel(0, 0, Color3.fromRGB(60, 255, 60), 0.98)
local bLayer = makeChannel(-0.002, 0, Color3.fromRGB(60, 60, 255), 0.97)

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vel = cam.CFrame.Position - (cam:GetAttribute("PrevPos") or cam.CFrame.Position)
	local speed = vel.Magnitude
	cam:SetAttribute("PrevPos", cam.CFrame.Position)

	local amount = math.clamp(speed * 0.0003, 0, 0.006)
	rLayer.Position = UDim2.new(-0.25 + amount, 0, -0.25, 0)
	bLayer.Position = UDim2.new(-0.25 - amount, 0, -0.25, 0)
	local intensity = 0.97 + math.clamp(speed * 0.005, 0, 0.02)
	rLayer.ImageTransparency = intensity
	bLayer.ImageTransparency = intensity
end)

print("[ChromaticAberration] Subtle lens chromatic aberration active")
