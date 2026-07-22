--!strict
-- OutfitWardrobeGui.client.lua
-- Wardrobe Fitting Room & Chef Style UI inspired by Infinity Nikki.
-- Allows players to view chef stats (Speed, Precision, Charisma, Stamina), style points,
-- style tiers, and equip fashion items / outfit variants.

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
local ChefStatsConfig = require(ConfigurationFiles:WaitForChild("ChefStatsConfig"))

-- Create ScreenGui via ClientGuiBootstrap (Rule 2)
local screenGui = ClientGuiBootstrap.createScreenGui(LocalPlayer, "OutfitWardrobeGui", 15)

-- Main Background Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 480)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
mainFrame.BackgroundColor3 = UIConfig.COLORS.MochiCream
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- Hidden on start (Rule 2)
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UIConfig.CORNER_RADIUS.Large
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = UIConfig.COLORS.PeaGreen
stroke.Thickness = UIConfig.STROKE.Thick
stroke.Parent = mainFrame

-- Title Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = UIConfig.COLORS.MintCanvas
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = UIConfig.FONTS.Decorative
titleLabel.TextSize = 24
titleLabel.TextColor3 = UIConfig.COLORS.ZundaDark
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "👗 ZUNDA WARDROBE & STYLE GALLERY ✨"
titleLabel.Parent = header

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = UIConfig.COLORS.ZundamonPink
closeBtn.Font = UIConfig.FONTS.Title
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UIConfig.CORNER_RADIUS.Circle
closeCorner.Parent = closeBtn

-- Stats Panel (Left Column)
local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.new(0, 240, 1, -75)
statsPanel.Position = UDim2.new(0, 15, 0, 65)
statsPanel.BackgroundColor3 = Color3.new(1, 1, 1)
statsPanel.BorderSizePixel = 0
statsPanel.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UIConfig.CORNER_RADIUS.Medium
statsCorner.Parent = statsPanel

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, 0, 0, 30)
statsTitle.BackgroundTransparency = 1
statsTitle.Font = UIConfig.FONTS.Heading
statsTitle.TextSize = 16
statsTitle.TextColor3 = UIConfig.COLORS.ZundaDark
statsTitle.Text = "📊 Chef Attributes"
statsTitle.Parent = statsPanel

-- Stats Container
local statsList = Instance.new("Frame")
statsList.Size = UDim2.new(1, -20, 1, -40)
statsList.Position = UDim2.new(0, 10, 0, 35)
statsList.BackgroundTransparency = 1
statsList.Parent = statsPanel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = statsList

-- Function to create attribute stat card
local function createStatCard(key: string, data: any, order: number)
	local card = Instance.new("Frame")
	card.Name = key
	card.Size = UDim2.new(1, 0, 0, 50)
	card.BackgroundColor3 = UIConfig.COLORS.MintCanvas
	card.LayoutOrder = order
	card.Parent = statsList

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UIConfig.CORNER_RADIUS.Small
	cardCorner.Parent = card

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 30, 1, 0)
	iconLabel.Position = UDim2.new(0, 5, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.TextSize = 20
	iconLabel.Text = data.emoji
	iconLabel.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -40, 0, 20)
	nameLabel.Position = UDim2.new(0, 35, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = UIConfig.FONTS.Body
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = UIConfig.COLORS.TextDark
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = data.name
	nameLabel.Parent = card

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = "ValueLabel"
	valLabel.Size = UDim2.new(1, -40, 0, 20)
	valLabel.Position = UDim2.new(0, 35, 0, 25)
	valLabel.BackgroundTransparency = 1
	valLabel.Font = UIConfig.FONTS.Mono
	valLabel.TextSize = 13
	valLabel.TextColor3 = data.color
	valLabel.TextXAlignment = Enum.TextXAlignment.Left
	valLabel.Text = "Level 1 (Bonus: 1.0x)"
	valLabel.Parent = card
end

local statValueLabels: { [string]: TextLabel } = {}
local orderIdx = 1
for key, data in pairs(ChefStatsConfig.stats) do
	createStatCard(key, data, orderIdx)
	local card = statsList:FindFirstChild(key)
	if card then
		local valLbl = card:FindFirstChild("ValueLabel") :: TextLabel?
		if valLbl then
			statValueLabels[key] = valLbl
		end
	end
	orderIdx += 1
end

-- Outfits & Fashion Gallery (Right Column)
local galleryPanel = Instance.new("Frame")
galleryPanel.Name = "GalleryPanel"
galleryPanel.Size = UDim2.new(1, -285, 1, -75)
galleryPanel.Position = UDim2.new(0, 270, 0, 65)
galleryPanel.BackgroundColor3 = Color3.new(1, 1, 1)
galleryPanel.BorderSizePixel = 0
galleryPanel.Parent = mainFrame

local galleryCorner = Instance.new("UICorner")
galleryCorner.CornerRadius = UIConfig.CORNER_RADIUS.Medium
galleryCorner.Parent = galleryPanel

local galleryTitle = Instance.new("TextLabel")
galleryTitle.Size = UDim2.new(1, 0, 0, 30)
galleryTitle.BackgroundTransparency = 1
galleryTitle.Font = UIConfig.FONTS.Heading
galleryTitle.TextSize = 16
galleryTitle.TextColor3 = UIConfig.COLORS.ZundaDark
galleryTitle.Text = "🎀 Fashion Collection & Accessories"
galleryTitle.Parent = galleryPanel

-- Scrolling Frame for Outfits
local outfitScroll = Instance.new("ScrollingFrame")
outfitScroll.Size = UDim2.new(1, -20, 1, -40)
outfitScroll.Position = UDim2.new(0, 10, 0, 35)
outfitScroll.BackgroundTransparency = 1
outfitScroll.ScrollBarThickness = 6
outfitScroll.ScrollBarImageColor3 = UIConfig.COLORS.PeaGreen
outfitScroll.Parent = galleryPanel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 120, 0, 130)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.Parent = outfitScroll

-- Sample Outfit Items
local outfitItems = {
	{ name = "Mint Frill Apron", tier = "Stylish", icon = "👗", unlocked = true, desc = "+10% Precision" },
	{ name = "Golden Spatula Brooch", tier = "Chic", icon = "✨", unlocked = true, desc = "+15% Charisma" },
	{ name = "Zunda Ribbon Bow", tier = "Fresh", icon = "🎀", unlocked = true, desc = "+5% Speed" },
	{ name = "Royalty Crown", tier = "Legendary", icon = "👑", unlocked = false, desc = "+30% All Stats" },
	{ name = "Zundamon Shiny Coat", tier = "Gorgeous", icon = "🧥", unlocked = false, desc = "+20% Stamina" },
	{ name = "Cosmic Gourmet Aura", tier = "Legendary", icon = "🌸", unlocked = false, desc = "Sparks Glamour FX" },
}

for _, outfit in ipairs(outfitItems) do
	local card = Instance.new("Frame")
	card.Name = "OutfitCard_" .. outfit.name:gsub("%s+", "")
	card.BackgroundColor3 = outfit.unlocked and UIConfig.COLORS.MintCanvas or UIConfig.COLORS.CreamDark
	card.Parent = outfitScroll

	local c = Instance.new("UICorner")
	c.CornerRadius = UIConfig.CORNER_RADIUS.Small
	c.Parent = card

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 45)
	icon.Position = UDim2.new(0, 0, 0, 5)
	icon.BackgroundTransparency = 1
	icon.TextSize = 32
	icon.Text = outfit.icon
	icon.Parent = card

	local name = Instance.new("TextLabel")
	name.Name = "OutfitNameLabel"
	name.Size = UDim2.new(1, -8, 0, 30)
	name.Position = UDim2.new(0, 4, 0, 50)
	name.BackgroundTransparency = 1
	name.Font = UIConfig.FONTS.Body
	name.TextSize = 12
	name.TextColor3 = outfit.unlocked and UIConfig.COLORS.TextDark or UIConfig.COLORS.TextDisabled
	name.TextWrapped = true
	name.Text = outfit.name
	name.Parent = card

	local btn = Instance.new("TextButton")
	btn.Name = "EquipButton"
	btn.Size = UDim2.new(1, -12, 0, 24)
	btn.Position = UDim2.new(0, 6, 1, -30)
	btn.BackgroundColor3 = outfit.unlocked and UIConfig.COLORS.ZundamonGold or UIConfig.COLORS.BorderDim
	btn.Font = UIConfig.FONTS.Heading
	btn.TextSize = 11
	btn.TextColor3 = UIConfig.COLORS.TextOnPrimary
	btn.Text = outfit.unlocked and "Equip" or "Locked"
	btn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UIConfig.CORNER_RADIUS.Tiny
	btnCorner.Parent = btn
end

-- Wire RemoteEvents for dynamic updates from server
task.spawn(function()
	local remotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remotesFolder then return end

	local chefStatsRE = remotesFolder:WaitForChild("ChefStatsUpdate", 5) :: RemoteEvent?
	if chefStatsRE then
		chefStatsRE.OnClientEvent:Connect(function(arg1: any, arg2: any, arg3: any)
			if type(arg1) == "table" then
				for statKey, statData in pairs(arg1) do
					local label = statValueLabels[statKey]
					if label then
						local lvl = (type(statData) == "table" and statData.level) or statData or 1
						local mult = (type(statData) == "table" and statData.multiplier) or 1.0
						label.Text = string.format("Level %d (Bonus: %.1fx)", lvl, mult)
					end
				end
			elseif type(arg1) == "string" and statValueLabels[arg1] then
				local lvl = arg2 or 1
				local mult = arg3 or 1.0
				statValueLabels[arg1].Text = string.format("Level %d (Bonus: %.1fx)", lvl, mult)
			end
		end)
	end

	local stylePointsRE = remotesFolder:WaitForChild("StylePointsUpdate", 5) :: RemoteEvent?
	if stylePointsRE then
		stylePointsRE.OnClientEvent:Connect(function(points: number?, tier: string?)
			if galleryTitle then
				galleryTitle.Text = string.format("🎀 Fashion Collection (%d pts - %s)", points or 0, tier or "Fresh")
			end
		end)
	end

	local outfitUnlockRE = remotesFolder:WaitForChild("OutfitUnlock", 5) :: RemoteEvent?
	if outfitUnlockRE then
		outfitUnlockRE.OnClientEvent:Connect(function(outfitName: string)
			for _, item in ipairs(outfitScroll:GetChildren()) do
				if item:IsA("Frame") then
					local nameLabel = item:FindFirstChild("OutfitNameLabel") :: TextLabel?
					if nameLabel and nameLabel.Text == outfitName then
						item.BackgroundColor3 = UIConfig.COLORS.MintCanvas
						nameLabel.TextColor3 = UIConfig.COLORS.TextDark
						local btn = item:FindFirstChild("EquipButton") :: TextButton?
						if btn then
							btn.BackgroundColor3 = UIConfig.COLORS.ZundamonGold
							btn.Text = "Equip"
						end
					end
				end
			end
		end)
	end
end)

-- Close Button Connection
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Toggle Functionality
local OutfitWardrobe = {}
function OutfitWardrobe.toggle()
	mainFrame.Visible = not mainFrame.Visible
end

-- Hook into Keybinds
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.K then
		OutfitWardrobe.toggle()
	end
end)

return OutfitWardrobe
