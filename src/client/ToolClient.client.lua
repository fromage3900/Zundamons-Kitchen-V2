-- [[LocalScript] ToolClient (ref: RBX90F4027250BB4E6CBBBDE286ADDB17BF)]]
local tool = script.Parent
local RS = game:GetService("ReplicatedStorage")
local CF = RS:WaitForChild("ToolRemotes"):WaitForChild("ConnectFunction")
local cooldown = 0
tool.Activated:Connect(function()
    local now = tick()
    if now - cooldown < 0.55 then return end
    cooldown = now
    pcall(function() CF:InvokeServer(tool.Name) end)
end)
