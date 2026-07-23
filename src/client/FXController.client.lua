-- [[LocalScript] FXController (ref: RBX4DE9ECE90898420FA39A91FFB6DCFE64)]]
-- ZundaFX/FXController: Animates watercolour corner bleed blobs
local rs = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Lighting-based post-processing (Bloom x2, SunRays, ColorCorrection, DepthOfField)
require(game.ReplicatedStorage.ConfigurationFiles.PostProcessing)
-- Ambient world particles (dust motes, fireflies, sakura petals)
require(game.ReplicatedStorage.ConfigurationFiles.AmbientParticles)
-- Watercolour gradient wash, lens flare, vignette breath
require(game.ReplicatedStorage.ConfigurationFiles.WhimsicalOverlay)
-- Low-lying ground mist patches (weather-responsive)
require(game.ReplicatedStorage.ConfigurationFiles.GroundMist)
-- Rotating magic circle filigree halo at kitchen center
require(game.ReplicatedStorage.ConfigurationFiles.MagicCircle)
-- Cel-shaded ink outline overlay (hitline, ink wash, shadow ramp, hatch)
require(game.ReplicatedStorage.ConfigurationFiles.CelOutline)
-- Crystal refraction + iridescence (tag parts with "Crystal" in Studio)
require(game.ReplicatedStorage.ConfigurationFiles.CrystalFX)
-- Dreamy water refraction, caustics, fresnel glow
require(game.ReplicatedStorage.ConfigurationFiles.WaterFX)

local gui, bleed
for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") then
		local found = g:FindFirstChild("WatercolourBleed", true)
		if found then gui = g; bleed = found; break end
	end
end
if not bleed then
	print("[FXController] WatercolourBleed not found — skipping watercolour FX")
	return
end

-- Subtle breathing wash: gently animate the edge-wash gradients' transparency for life
local edges = bleed:GetChildren()
for i, edge in ipairs(edges) do
    if edge:IsA("Frame") then
        local g = edge:FindFirstChildOfClass("UIGradient")
        if g then
            local phase = i * (math.pi / 2)
            task.spawn(function()
                while edge.Parent do
                    local t = os.clock() * 0.18 + phase
                    local breathe = math.sin(t) * 0.04
                    local baseT = (i == 1 or i == 2) and 0.85 or 0.87
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,   baseT + breathe),
                        NumberSequenceKeypoint.new(0.7, baseT + 0.15 + breathe),
                        NumberSequenceKeypoint.new(1,   1.0),
                    })
                    task.wait(0.2)
                end
            end)
        end
    end
end

-- Grain layer: convert to tiled noise + animated shimmer if not already done
local grain = gui:FindFirstChild("GrainLayer")
if grain then
    if not grain:FindFirstChild("NoiseImage") then
        local img = Instance.new("ImageLabel", grain)
        img.Name = "NoiseImage"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1.2, 0, 1.2, 0)
        img.Position = UDim2.new(-0.1, 0, -0.1, 0)
        img.Image = "rbxassetid://74702819388719"
        img.ScaleType = Enum.ScaleType.Tile
        img.TileSize = UDim2.new(0, 4, 0, 4)
        img.ImageColor3 = Color3.fromRGB(245, 235, 255)
        img.ImageTransparency = 0.88
        img.ZIndex = 12
    end
    local noise = grain:FindFirstChild("NoiseImage")
    grain.BackgroundTransparency = 1
    -- Add second grain layer for richer texture
    local grain2 = grain:FindFirstChild("NoiseLayer2")
    if not grain2 then
        local g2 = Instance.new("ImageLabel", grain)
        g2.Name = "NoiseLayer2"
        g2.BackgroundTransparency = 1
        g2.Size = UDim2.new(1.3, 0, 1.3, 0)
        g2.Position = UDim2.new(-0.15, 0, -0.15, 0)
        g2.Image = "rbxassetid://74702819388719"
        g2.ScaleType = Enum.ScaleType.Tile
        g2.TileSize = UDim2.new(0, 8, 0, 8)
        g2.ImageColor3 = Color3.fromRGB(235, 220, 250)
        g2.ImageTransparency = 0.94
        g2.ZIndex = 13
    end
    task.spawn(function()
        while true do
            if noise then
                noise.ImageRectOffset = Vector2.new(math.random(0, 512), math.random(0, 512))
                noise.ImageTransparency = 0.85 + math.sin(os.clock() * 0.5) * 0.03
                local g2 = grain:FindFirstChild("NoiseLayer2")
                if g2 then
                    g2.ImageRectOffset = Vector2.new(math.random(0, 512), math.random(0, 512))
                    g2.ImageTransparency = 0.92 + math.sin(os.clock() * 0.7 + 1) * 0.02
                end
            end
            task.wait(1/30)
        end
    end)
end

-- Vignette pulse on weather change
local weatherRE = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents") and game.ReplicatedStorage.RemoteEvents:FindFirstChild("WeatherChanged")
local vignette = gui:FindFirstChild("Vignette")
if weatherRE and vignette then
    weatherRE.OnClientEvent:Connect(function(weatherKey)
        local darker = (weatherKey == "rain" or weatherKey == "storm" or weatherKey == "fog")
        local target = darker and 0.32 or 0.5
        for _, f in pairs(vignette:GetChildren()) do
            if f:IsA("Frame") then
                local g = f:FindFirstChildOfClass("UIGradient")
                if g then
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, target),
                        NumberSequenceKeypoint.new(1, 1.0),
                    })
                end
            end
        end
    end)
end
print("[ZundaFX] Post-process overlay active")
