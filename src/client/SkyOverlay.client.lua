local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local ClientGuiBootstrap = require(game.ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap)

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

local crystalA = makeLayer("CrystalA", TX.crystalEmit1, 2, {tile=UDim2.new(0,200,0,200), alpha=0.91})
local crystalB = makeLayer("CrystalB", TX.crystalEmit3, 3, {tile=UDim2.new(0,120,0,120), alpha=0.94, color=Color3.fromRGB(220,200,255)})
local crystalC = makeLayer("CrystalC", TX.crystal1, 3, {tile=UDim2.new(0,300,0,300), alpha=0.96, color=Color3.fromRGB(230,220,250)})
local starLayer = makeLayer("StarryNight", TX.starry1, 4, {tile=UDim2.new(0,400,0,400), alpha=0.88, color=Color3.fromRGB(200,200,255)})
local starLayer2 = makeLayer("StarryNight2", TX.starry2, 4, {tile=UDim2.new(0,300,0,300), alpha=0.93, color=Color3.fromRGB(180,190,255)})
local heartLayer = makeLayer("HeartAccent", TX.hearts, 5, {scale=Enum.ScaleType.Fit, size=UDim2.new(0.25,0,0.25,0), pos=UDim2.new(0.72,0,0.72,0), alpha=0.90, color=Color3.fromRGB(255,200,220)})
local musicLayer = makeLayer("MusicAccent", TX.sheetMusic, 5, {scale=Enum.ScaleType.Fit, size=UDim2.new(0.2,0,0.2,0), pos=UDim2.new(0.02,0,0.02,0), alpha=0.93, color=Color3.fromRGB(200,180,255)})
local glowLayer = makeLayer("RadialGlow", TX.radialPattern, 1, {scale=Enum.ScaleType.Fit, size=UDim2.new(1,0,1,0), pos=UDim2.new(0,0,0,0), alpha=0.93})

local off = {a=Vector2.new(0,0), b=Vector2.new(0,0), c=Vector2.new(0,0), s1=Vector2.new(0,0), s2=Vector2.new(0,0)}

RunService.RenderStepped:Connect(function(dt)
	local hour = Lighting.ClockTime
	local isNight = hour <= 6 or hour >= 19
	local t = os.clock()

	-- NOTE: ImageLabel has no TileOffset property; the old per-frame assignments
	-- to it threw an error every RenderStepped (log flood + wasted frame time).
	-- Removed. (Tiled textures can't be scroll-offset directly on an ImageLabel.)
	crystalA.ImageTransparency = 0.90 + math.sin(t*0.3)*0.03
	crystalB.ImageTransparency = 0.93 + math.sin(t*0.4+1)*0.02
	crystalC.ImageTransparency = 0.95 + math.sin(t*0.25+2)*0.02

	if isNight then
		starLayer.ImageTransparency = 0.75 + math.sin(t*0.2)*0.05
		starLayer2.ImageTransparency = 0.82 + math.sin(t*0.25+1)*0.04
	else
		starLayer.ImageTransparency = 0.93
		starLayer2.ImageTransparency = 0.95
	end

	heartLayer.Position = UDim2.new(0.72, math.sin(t*0.15)*8, 0.72, math.cos(t*0.2)*8)
	musicLayer.Position = UDim2.new(0.02, math.sin(t*0.1)*4, 0.02, math.cos(t*0.12)*4)

	glowLayer.ImageTransparency = 0.92 + math.sin(t*0.2)*0.03
end)

print("[SkyOverlay] Multi-layer sky overlay active")
