-- [[LocalScript] ZundaFrameAnim (ref: RBXE8A45ABE5F6C48F285FDA5A0B99C4A0A)]]
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local gui = script.Parent
local borderStroke = gui:FindFirstChild("BorderAccent") and gui.BorderAccent:FindFirstChildOfClass("UIStroke")

local corners = {}
for _, c in pairs(gui:GetChildren()) do
    if c.Name:sub(1, 7) == "Corner_" then
        table.insert(corners, c)
    end
end

-- Animate each corner: primary breathes (scale + rotation drift), accents orbit
local function animateCorner(corner, index)
    local primary = corner:FindFirstChild("Primary")
    local origRot = primary and primary.Rotation or 0
    local origSize = UDim2.new(0, 56, 0, 56)
    local phase = index * (math.pi / 2)

    local accents = {}
    for i = 1, 2 do
        local a = corner:FindFirstChild("Accent" .. i)
        if a then table.insert(accents, a) end
    end

    task.spawn(function()
        while corner.Parent do
            local t = tick() * 0.6 + phase

            -- Primary breathes 0.95x ↔ 1.05x with subtle rotation drift
            if primary then
                local sc = 1 + math.sin(t) * 0.05
                primary.Size = UDim2.new(0, 56 * sc, 0, 56 * sc)
                primary.Rotation = origRot + math.sin(t * 0.5) * 8
            end

            -- Each accent orbits at different radius/speed
            for i, a in ipairs(accents) do
                local speed = 0.4 + i * 0.15
                local radius = 28 + i * 6
                local angle = t * speed + (i - 1) * (math.pi * 2 / #accents)
                local ox = math.cos(angle) * radius
                local oy = math.sin(angle) * radius
                a.Position = UDim2.new(0.5, ox - 11, 0.5, oy - 11)
                a.Rotation = math.deg(angle) + 30
                a.TextTransparency = 0.2 + math.sin(t * 1.3 + i) * 0.1
            end

            task.wait(1/30)
        end
    end)
end

for i, c in ipairs(corners) do
    animateCorner(c, i)
end

-- Border accent: subtle pulse
if borderStroke then
    task.spawn(function()
        while borderStroke.Parent do
            local t = tick() * 0.4
            borderStroke.Transparency = 0.7 + math.sin(t) * 0.12
            borderStroke.Color = Color3.fromHSV(
                (math.sin(t * 0.3) * 0.04 + 0.93) % 1,  -- hue drifts in pink/lavender range
                0.25,
                1.0
            )
            task.wait(1/30)
        end
    end)
end
