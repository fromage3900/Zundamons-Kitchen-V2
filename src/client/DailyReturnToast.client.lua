-- [[LocalScript] DailyReturnToast]
-- Persistent top-left streak badge and "come back tomorrow" reminder.
-- Listens for DailyPreviewData from DailyChallengeService.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local FONTS = UIConfig.FONTS

local RE = RS:WaitForChild("RemoteEvents")
local previewEvent = RE:WaitForChild("DailyPreviewData")

local function getOrBuildZundaHUD()
	local existing = playerGui:FindFirstChild("ZundaHUD")
	if existing and existing:IsA("ScreenGui") then
		existing.ResetOnSpawn = false
		return existing
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "ZundaHUD"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 10
	sg.Parent = playerGui
	return sg
end

local gui = getOrBuildZundaHUD()

local toast = gui:FindFirstChild("DailyReturnToast")
if not toast then
	toast = Instance.new("Frame", gui)
	toast.Name = "DailyReturnToast"
	toast.Size = UDim2.new(0, 260, 0, 64)
	toast.Position = UDim2.new(0, 16, 0, 78)
	toast.BackgroundColor3 = Color3.fromRGB(40, 32, 60)
	toast.BackgroundTransparency = 0.05
	toast.BorderSizePixel = 0
	toast.Visible = false
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 16)

	local stroke = Instance.new("UIStroke", toast)
	stroke.Color = Color3.fromRGB(160, 210, 150)
	stroke.Thickness = 2

	local icon = Instance.new("TextLabel", toast)
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 36, 0, 36)
	icon.Position = UDim2.new(0, 10, 0, 14)
	icon.BackgroundTransparency = 1
	icon.Text = "🔥"
	icon.Font = FONTS.Body
	icon.TextSize = 26

	local streak = Instance.new("TextLabel", toast)
	streak.Name = "Streak"
	streak.Size = UDim2.new(1, -58, 0, 20)
	streak.Position = UDim2.new(0, 50, 0, 8)
	streak.BackgroundTransparency = 1
	streak.Text = "Streak: 0 / 7"
	streak.Font = FONTS.Heading
	streak.TextSize = 14
	streak.TextColor3 = Color3.fromRGB(255, 200, 80)
	streak.TextXAlignment = Enum.TextXAlignment.Left

	local nextLbl = Instance.new("TextLabel", toast)
	nextLbl.Name = "Next"
	nextLbl.Size = UDim2.new(1, -58, 0, 16)
	nextLbl.Position = UDim2.new(0, 50, 0, 28)
	nextLbl.BackgroundTransparency = 1
	nextLbl.Text = "Come back tomorrow!"
	nextLbl.Font = FONTS.Body
	nextLbl.TextSize = 12
	nextLbl.TextColor3 = Color3.fromRGB(220, 210, 255)
	nextLbl.TextXAlignment = Enum.TextXAlignment.Left

	local reward = Instance.new("TextLabel", toast)
	reward.Name = "Reward"
	reward.Size = UDim2.new(1, -58, 0, 14)
	reward.Position = UDim2.new(0, 50, 0, 44)
	reward.BackgroundTransparency = 1
	reward.Text = ""
	reward.Font = FONTS.Body
	reward.TextSize = 11
	reward.TextColor3 = Color3.fromRGB(160, 210, 150)
	reward.TextXAlignment = Enum.TextXAlignment.Left
end

local function showPreview(preview)
	if not preview or not preview.streak then
		return
	end

	local streakLabel = toast:FindFirstChild("Streak")
	local nextLabel = toast:FindFirstChild("Next")
	local rewardLabel = toast:FindFirstChild("Reward")
	local icon = toast:FindFirstChild("Icon")

	streakLabel.Text = string.format("Streak: %d / %d", preview.streak, preview.maxStreak or 7)
	nextLabel.Text =
		string.format("Next: %s · %s %s", preview.nextDayName, preview.nextChallengeIcon, preview.nextChallengeTitle)
	rewardLabel.Text = preview.todayClaimed and ("Day reward: " .. preview.rewardText)
		or "Finish today's challenges to keep it!"
	icon.Text = preview.todayClaimed and "✅" or "🔥"

	toast.Visible = true
	toast.Position = UDim2.new(0, 16, 0, 68)
	Tween:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 16, 0, 78),
	}):Play()

	-- Auto-hide after 10s, but keep visible if player hovers
	task.delay(10, function()
		if toast and toast.Visible then
			Tween:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			for _, child in ipairs(toast:GetDescendants()) do
				if child:IsA("TextLabel") then
					Tween:Create(child, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
				end
			end
			task.delay(0.25, function()
				if toast then
					toast.Visible = false
					toast.BackgroundTransparency = 0.05
					for _, child in ipairs(toast:GetDescendants()) do
						if child:IsA("TextLabel") then
							child.TextTransparency = 0
						end
					end
				end
			end)
		end
	end)
end

previewEvent.OnClientEvent:Connect(showPreview)

print("[DailyReturnToast] Ready")
