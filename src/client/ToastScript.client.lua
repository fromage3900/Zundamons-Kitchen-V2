-- [[LocalScript] ToastScript (ref: RBXD3A7EEDAAA72415CBB0A4314BAFF1667)]]
-- ToastScript: Shows pop-up notification toasts for purchases, unlocks, etc.
-- Listens to NotifyPlayer RemoteEvent and animates a floating message

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player            = Players.LocalPlayer

local RE       = ReplicatedStorage:WaitForChild("RemoteEvents")
local notifyRE = RE:FindFirstChild("NotifyPlayer") or Instance.new("RemoteEvent")
notifyRE.Name = "NotifyPlayer"
notifyRE.Parent = RE

-- Create the toast container in PlayerGui
local gui = script.Parent

local function showToast(eventType, message)
    -- Color by event type
    local bgColor = Color3.fromRGB(40, 160, 80)  -- green = success
    if eventType == "error" then
        bgColor = Color3.fromRGB(180, 50, 50)
    elseif eventType == "unlock" then
        bgColor = Color3.fromRGB(200, 150, 0)
    elseif eventType == "info" then
        bgColor = Color3.fromRGB(60, 120, 200)
    end

    local toast = Instance.new("Frame", gui)
    toast.Size = UDim2.new(0, 280, 0, 52)
    toast.Position = UDim2.new(0.5, -140, 0, -60)  -- starts above screen
    toast.BackgroundColor3 = bgColor
    toast.BorderSizePixel = 0
    toast.ZIndex = 100
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)

    -- Drop shadow
    local shadow = Instance.new("Frame", toast)
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, 3)
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = 99
    shadow.BorderSizePixel = 0
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

    local label = Instance.new("TextLabel", toast)
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextWrapped = true
    label.ZIndex = 101

    -- Animate: slide down from top, pause, slide back up
    local slideIn = TweenService:Create(toast,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -140, 0, 16)})
    slideIn:Play()

    task.wait(2.5)

    local slideOut = TweenService:Create(toast,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -140, 0, -60)})
    slideOut:Play()
    slideOut.Completed:Wait()
    toast:Destroy()
end

-- Listen for notifications from server
notifyRE.OnClientEvent:Connect(function(eventType, message)
    task.spawn(showToast, eventType, message)
end)

print("[ToastScript] Notification system ready")
