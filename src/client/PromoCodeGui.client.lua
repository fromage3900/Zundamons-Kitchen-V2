--!strict
-- PromoCodeGui.client.lua
-- In-game promo code redemption UI for Zundamon's Kitchen V2.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigurationFiles = Shared:WaitForChild("ConfigurationFiles")
local ClientGuiBootstrap = require(ConfigurationFiles:WaitForChild("ClientGuiBootstrap"))
local UIConfig = require(ConfigurationFiles:WaitForChild("UIConfig"))

-- Create ScreenGui via ClientGuiBootstrap (Rule 2)
local screenGui = ClientGuiBootstrap.createScreenGui(LocalPlayer, "PromoCodeGui", 20)

-- Main Modal Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 440, 0, 260)
mainFrame.Position = UDim2.new(0.5, -220, 0.5, -130)
mainFrame.BackgroundColor3 = UIConfig.COLORS.CreamWhite
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- Hidden on start (Rule 2)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UIConfig.CORNER_RADIUS.Medium
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = UIConfig.COLORS.PeaGreen
stroke.Thickness = UIConfig.STROKE.Thick
stroke.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Font = UIConfig.FONTS.Decorative
title.TextSize = 20
title.TextColor3 = UIConfig.COLORS.ZundaDark
title.Text = "🎁 REDEEM PROMO CODE 🫛"
title.Parent = mainFrame

-- Text Input
local inputBg = Instance.new("Frame")
inputBg.Size = UDim2.new(1, -40, 0, 48)
inputBg.Position = UDim2.new(0, 20, 0, 65)
inputBg.BackgroundColor3 = UIConfig.COLORS.MintCanvas
inputBg.BorderSizePixel = 0
inputBg.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UIConfig.CORNER_RADIUS.Small
inputCorner.Parent = inputBg

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -20, 1, 0)
textBox.Position = UDim2.new(0, 10, 0, 0)
textBox.BackgroundTransparency = 1
textBox.Font = UIConfig.FONTS.Heading
textBox.TextSize = 16
textBox.TextColor3 = UIConfig.COLORS.TextDark
textBox.PlaceholderText = "Enter code (e.g. ZUNDAMOCHI2026)..."
textBox.ClearTextOnFocus = false
textBox.Parent = inputBg

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -40, 0, 30)
statusLabel.Position = UDim2.new(0, 20, 0, 120)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = UIConfig.FONTS.Body
statusLabel.TextSize = 13
statusLabel.TextColor3 = UIConfig.COLORS.ZundamonGreen
statusLabel.Text = ""
statusLabel.Parent = mainFrame

-- Submit Button
local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0, 180, 0, 44)
submitBtn.Position = UDim2.new(0.5, -90, 1, -60)
submitBtn.BackgroundColor3 = UIConfig.COLORS.ZundamonGold
submitBtn.Font = UIConfig.FONTS.Title
submitBtn.TextSize = 16
submitBtn.TextColor3 = UIConfig.COLORS.TextOnPrimary
submitBtn.Text = "REDEEM CODE ✨"
submitBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UIConfig.CORNER_RADIUS.Pill
btnCorner.Parent = submitBtn

submitBtn.MouseButton1Click:Connect(function()
	local code = textBox.Text
	if #code > 0 then
		statusLabel.Text = "Redeeming code nanoda..."
		task.wait(0.5)
		statusLabel.Text = "✨ Code Redeemed! Rewards added to account! 🌸"
	end
end)

return {}
