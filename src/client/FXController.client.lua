-- [[LocalScript] FXController (ref: RBX4DE9ECE90898420FA39A91FFB6DCFE64)]]
-- ZundaFX/FXController: Animates watercolour corner bleed blobs
local rs = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local gui = script.Parent
local bleed = gui:FindFirstChild("WatercolourBleed")
if not bleed then return end

-- Subtle breathing wash: gently animate the edge-wash gradients' transparency for life
local edges = bleed:GetChildren()
for i, edge in ipairs(edges) do
    if edge:IsA("Frame") then
        local g = edge:FindFirstChildOfClass("UIGradient")
        if g then
            local phase = i * (math.pi / 2)
            task.spawn(function()
                while edge.Parent do
                    local t = tick() * 0.18 + phase
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
        img.Image = "rbxassetid://9446549339"  -- noise texture (falls back gracefully)
        img.ScaleType = Enum.ScaleType.Tile
        img.TileSize = UDim2.new(0, 4, 0, 4)
        img.ImageColor3 = Color3.fromRGB(255, 255, 255)
        img.ImageTransparency = 0.92
        img.ZIndex = 12
    end
    local noise = grain:FindFirstChild("NoiseImage")
    grain.BackgroundTransparency = 1  -- let the noise image carry the effect
    task.spawn(function()
        while true do
            local t = tick()
            if noise then
                noise.ImageRectOffset = Vector2.new(math.random(0, 512), math.random(0, 512))
                noise.ImageTransparency = 0.90 + math.sin(t * 0.6) * 0.025
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
