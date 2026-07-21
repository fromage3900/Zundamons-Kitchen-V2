-- [[LocalScript] FishingRodClient (ref: RBX58EB7B19047740BDA82070D53BAE6511)]]
local player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local FishingCast = RS:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")

local function bindFishingRod(tool)
    if tool.Name ~= "FishingRod" then return end

    local cooldown = 0
    tool.Activated:Connect(function()
        local now = os.clock()
        if now - cooldown < 3 then return end  -- can't recast for 3s
        cooldown = now
        -- Ask server to start a bite
        local resp = FishingCast:InvokeServer("begin")
        if not resp or not resp.ok then return end
        -- Open the fishing minigame UI on the client
        if _G.FishingMinigame and _G.FishingMinigame.start then
            _G.FishingMinigame.start(resp.fish, resp.difficulty, function(success)
                FishingCast:InvokeServer("result", { success = success })
            end)
        end
    end)
end

-- Bind existing
if player.Character then
    for _, child in ipairs(player.Character:GetChildren()) do
        if child:IsA("Tool") then bindFishingRod(child) end
    end
end
local backpack = player:WaitForChild("Backpack")
for _, child in ipairs(backpack:GetChildren()) do
    if child:IsA("Tool") then bindFishingRod(child) end
end

-- Bind future
player.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then bindFishingRod(child) end
    end)
end)
backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then bindFishingRod(child) end
end)
