-- [[LocalScript] FishingRodClient (ref: RBX58EB7B19047740BDA82070D53BAE6511)]]
local tool = script.Parent
local RS = game:GetService("ReplicatedStorage")
local FishingCast = RS:WaitForChild("ToolRemotes"):WaitForChild("FishingCast")
local cooldown = 0
tool.Activated:Connect(function()
    local now = tick()
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
