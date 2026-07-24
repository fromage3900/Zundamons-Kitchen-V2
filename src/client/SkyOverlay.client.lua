local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local ClientGuiBootstrap = require(game.ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)
local reducedMotion = GuiService.ReducedMotionEnabled
local function checkReducedMotion()
	if GuiService.ReducedMotionEnabled then
		reducedMotion = true
		return true
	end
	return false
end
if GuiService.ReducedMotionEnabled ~= nil then
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(function()
		checkReducedMotion()
	end)
end

local TX = {
	crystalEmit1 = "rbxassetid://93110600603968",
	crystalEmit3 = "rbxassetid://93401796932139",
	crystal1 = "rbxassetid://101468581497208",
	crystal2 = "rbxassetid://75779969994353",
	starry1 = "rbxassetid://120163827175455",
	starry2 = "rbxassetid://92421810392866",
	hearts = "rbxassetid://130646978831400",
	sheetMusic = "rbxassetid://99143630128781",
	radialPattern = "rbxassetid://117600264767976",
	purpleNebula = "rbxassetid://129075140128878",
	blueNebula = "rbxassetid://119372168213953",
}

local gui = ClientGuiBootstrap.createScreenGui(player, "SkyOverlayGui", 1)
gui.IgnoreGuiInset = true

local function makeLayer(name, image, zidx, opts)
	opts = opts or {}
	local l = Instance.new("ImageLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = opts.size or UDim2.new(1.2, 0, 1.2, 0)
	l.Position = opts.pos or UDim2.new(-0.1, 0, -0.1, 0)
	l.Image = image
	l.ScaleType = opts.scale or Enum.ScaleType.Tile
	l.TileSize = opts.tile or UDim2.new(0, 256, 0, 256)
	l.ImageColor3 = opts.color or Color3.fromRGB(255, 240, 255)
	l.ImageTransparency = opts.alpha or 0.92
	l.ZIndex = zidx
	l.Parent = gui
	return l
end

-- Crystal/starry Tile-mode layers removed 2026-07-24: these asset ids render as
-- plain white diamond squares (not the intended crystal/star glow), tiled across
-- the ENTIRE screen -- this was silently masked for a while because the whole
-- module was crashing on load (GuiService:GetEngineFeature doesn't exist as an
-- API); once that crash was fixed, the layers actually ran for the first time
-- and the broken tiling became visible ("squares in the sky"). Confirmed live
-- via screenshot. Only the radial glow (a Fit-scaled single image, not tiled)
-- looked fine and is kept.
local glowLayer = makeLayer("RadialGlow", TX.radialPattern, 1, {scale=Enum.ScaleType.Fit, size=UDim2.new(1,0,1,0), pos=UDim2.new(0,0,0,0), alpha=0.93})

if not reducedMotion then
	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		glowLayer.ImageTransparency = 0.92 + math.sin(t*0.2)*0.03
	end)
else
	glowLayer.ImageTransparency = 0.93
end

print("[SkyOverlay] Multi-layer sky overlay active")
