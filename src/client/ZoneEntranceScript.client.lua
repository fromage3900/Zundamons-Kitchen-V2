-- [[LocalScript] ZoneEntranceScript (ref: RBX9156165AEACE4D11B3726ED023DF65D9)]]
-- ZoneEntranceScript: detects player proximity to zone entrance pads and
-- fires the ShowZoneVN BindableEvent for the unified VN controller.
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player     = Players.LocalPlayer
local character  = player.Character or player.CharacterAdded:Wait()

-- Wait for unified VN API
local deadline = tick() + 8
while not _G.ZundaVN and tick() < deadline do task.wait(0.15) end

-- Wait for ShowZoneVN BindableEvent in PlayerGui
local pg = player:WaitForChild("PlayerGui")
local showZoneVN = pg:WaitForChild("ShowZoneVN", 10)

-- Build a map of ClickDetectors → zone keys from the Zones folder
local function buildZoneMap()
    local map = {}
    local zonesFolder = workspace:WaitForChild("Zones", 15)
    if not zonesFolder then return map end
    for _, zoneModel in ipairs(zonesFolder:GetChildren()) do
        for _, desc in ipairs(zoneModel:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                map[desc] = zoneModel.Name
            end
        end
    end
    return map
end

local zoneMap = buildZoneMap()

-- Wire each ClickDetector
for cd, zoneName in pairs(zoneMap) do
    cd.MouseClick:Connect(function(clicker)
        if clicker ~= player then return end
        if showZoneVN then
            showZoneVN:Fire(zoneName)
        end
    end)
end

-- Also re-wire if Zones folder gets new children (zones loaded late)
local zonesFolder = workspace:FindFirstChild("Zones")
if zonesFolder then
    zonesFolder.DescendantAdded:Connect(function(desc)
        if desc:IsA("ClickDetector") then
            -- Find parent zone model
            local obj = desc
            while obj and obj.Parent ~= zonesFolder do obj = obj.Parent end
            if obj then
                zoneMap[desc] = obj.Name
                desc.MouseClick:Connect(function(clicker)
                    if clicker ~= player then return end
                    if showZoneVN then showZoneVN:Fire(obj.Name) end
                end)
            end
        end
    end)
end

print("[ZoneEntrance] Wired", (function() local n=0; for _ in pairs(zoneMap) do n=n+1 end return n end)(), "zone entrance ClickDetectors to ZundaVN")
