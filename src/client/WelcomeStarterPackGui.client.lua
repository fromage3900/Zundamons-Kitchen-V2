--!strict
-- WelcomeStarterPackGui.client.lua
-- First-Time User Experience (FTUE) Starter Pack & Social Invite Rewards.
-- Boosts new player conversion, retention, and organic viral growth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end

local ConfigurationFiles = ReplicatedStorage:WaitForChild("ConfigurationFiles")
local ClientGuiBootstrap = require(ConfigurationFiles:WaitForChild("ClientGuiBootstrap"))
local UIConfig = require(ConfigurationFiles:WaitForChild("UIConfig"))

-- Create ScreenGui via ClientGuiBootstrap (Rule 2)
-- Panel layer (see docs/FX_UI_LAYERING_PLAN.md): must sit ABOVE the tutorial dim
-- (150) or the gift appears dimmed/"stuck" under the onboarding overlay.
local screenGui = ClientGuiBootstrap.createScreenGui(LocalPlayer, "WelcomeStarterPackGui", 210)

-- Main Modal Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 560, 0, 420)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
mainFrame.BackgroundColor3 = UIConfig.COLORS.CreamWhite
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- Controlled on startup (Rule 2)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UIConfig.CORNER_RADIUS.Large
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = UIConfig.COLORS.ZundamonGold
stroke.Thickness = UIConfig.STROKE.Thickest
stroke.Parent = mainFrame

-- Title Banner
local titleBanner = Instance.new("Frame")
titleBanner.Size = UDim2.new(1, 0, 0, 70)
titleBanner.BackgroundColor3 = UIConfig.COLORS.ZundamonGreen
titleBanner.BorderSizePixel = 0
titleBanner.Parent = mainFrame

local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 16)
bCorner.Parent = titleBanner

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.FontFace = UIConfig.FONTS.Decorative
titleText.TextSize = 26
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Text = "🎁 WELCOME CHEF STARTER GIFT! 🌸"
titleText.Parent = titleBanner

-- Content Container
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -160)
content.Position = UDim2.new(0, 20, 0, 85)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(1, 0, 0, 40)
subText.BackgroundTransparency = 1
subText.FontFace = UIConfig.FONTS.Heading
subText.TextSize = 16
subText.TextColor3 = UIConfig.COLORS.TextDark
subText.TextWrapped = true
subText.Text = "Welcome to Zundamon's Kitchen! Here are your exclusive starter gifts to begin your culinary fashion journey!"
subText.Parent = content

-- Reward Items Showcase
local rewardGrid = Instance.new("Frame")
rewardGrid.Size = UDim2.new(1, 0, 0, 100)
rewardGrid.Position = UDim2.new(0, 0, 0, 50)
rewardGrid.BackgroundTransparency = 1
rewardGrid.Parent = content

local gridLayout = Instance.new("UIListLayout")
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Padding = UDim.new(0, 20)
gridLayout.Parent = rewardGrid

local rewards = {
	{ icon = "🎟️", name = "5x Whim Tickets", desc = "Free Gacha Pulls" },
	{ icon = "💰", name = "500 Zunda Gold", desc = "Starter Coin" },
	{ icon = "👗", name = "Mint Frill Apron", desc = "Starter Outfit" },
}

for _, r in ipairs(rewards) do
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 140, 1, 0)
	box.BackgroundColor3 = UIConfig.COLORS.MintCanvas
	box.Parent = rewardGrid

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UIConfig.CORNER_RADIUS.Medium
	boxCorner.Parent = box

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 45)
	icon.Position = UDim2.new(0, 0, 0, 5)
	icon.BackgroundTransparency = 1
	icon.TextSize = 36
	icon.Text = r.icon
	icon.Parent = box

	local rName = Instance.new("TextLabel")
	rName.Size = UDim2.new(1, -8, 0, 20)
	rName.Position = UDim2.new(0, 4, 0, 52)
	rName.BackgroundTransparency = 1
	rName.FontFace = UIConfig.FONTS.Heading
	rName.TextSize = 12
	rName.TextColor3 = UIConfig.COLORS.ZundaDark
	rName.Text = r.name
	rName.Parent = box

	local rDesc = Instance.new("TextLabel")
	rDesc.Size = UDim2.new(1, -8, 0, 20)
	rDesc.Position = UDim2.new(0, 4, 0, 72)
	rDesc.BackgroundTransparency = 1
	rDesc.FontFace = UIConfig.FONTS.Caption
	rDesc.TextSize = 10
	rDesc.TextColor3 = UIConfig.COLORS.TextDarkSec
	rDesc.Text = r.desc
	rDesc.Parent = box
end

-- Claim Button
local claimBtn = Instance.new("TextButton")
claimBtn.Name = "ClaimButton"
claimBtn.Size = UDim2.new(0, 220, 0, 50)
claimBtn.Position = UDim2.new(0.5, -230, 1, -65)
claimBtn.BackgroundColor3 = UIConfig.COLORS.ZundamonGold
claimBtn.FontFace = UIConfig.FONTS.Title
claimBtn.TextSize = 18
claimBtn.TextColor3 = UIConfig.COLORS.TextOnPrimary
claimBtn.Text = "✨ CLAIM ALL GIFTS! ✨"
claimBtn.Parent = mainFrame

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UIConfig.CORNER_RADIUS.Pill
cCorner.Parent = claimBtn

-- Invite Friends Viral Button
local inviteBtn = Instance.new("TextButton")
inviteBtn.Name = "InviteButton"
inviteBtn.Size = UDim2.new(0, 220, 0, 50)
inviteBtn.Position = UDim2.new(0.5, 10, 1, -65)
inviteBtn.BackgroundColor3 = UIConfig.COLORS.ZundamonPink
inviteBtn.FontFace = UIConfig.FONTS.Title
inviteBtn.TextSize = 16
inviteBtn.TextColor3 = Color3.new(1, 1, 1)
inviteBtn.Text = "🤝 INVITE FRIENDS (+💎)"
inviteBtn.Parent = mainFrame

local iCorner = Instance.new("UICorner")
iCorner.CornerRadius = UIConfig.CORNER_RADIUS.Pill
iCorner.Parent = inviteBtn

-- Claim Click Handler
claimBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Invite Friends Social Prompt
inviteBtn.MouseButton1Click:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(LocalPlayer)
	end)
end)

-- Auto-show the FTUE starter pack only AFTER onboarding: wait for the tutorial
-- card to finish (or 90s timeout) so the gift never fights the tutorial overlay.
task.spawn(function()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local function tutorialCard()
		local tut = playerGui:FindFirstChild("TutorialGui")
		return tut and tut:FindFirstChild("TutorialCard")
	end
	-- Phase 1: give the tutorial up to 15s to appear (returning players may have
	-- it suppressed entirely; then we just show the gift).
	local appearDeadline = os.clock() + 15
	while os.clock() < appearDeadline do
		local card = tutorialCard()
		if card and card.Visible then break end
		task.wait(0.5)
	end
	-- Phase 2: if it appeared, hold the gift until onboarding finishes (90s cap).
	local finishDeadline = os.clock() + 90
	while os.clock() < finishDeadline do
		local card = tutorialCard()
		if not (card and card.Visible) then break end
		task.wait(0.5)
	end
	mainFrame.Visible = true
end)

return {}
