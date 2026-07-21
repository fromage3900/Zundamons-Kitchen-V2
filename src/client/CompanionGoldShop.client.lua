-- [[LocalScript] CompanionGoldShop]]
-- UI for purchasing companions with in-game gold

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)
local NPCConfig = require(ReplicatedStorage.Shared.Config.NPCConfig)
local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")
local purchaseRF = RF:WaitForChild("PurchaseGoldCompanion")

-- Create shop UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CompanionShopGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.5, -200)
frame.BackgroundColor3 = UIConfig.COLORS.PanelBg
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Companion Shop"
title.TextColor3 = UIConfig.COLORS.TextDark
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = frame

-- Companions list
local scrolling = Instance.new("ScrollingFrame")
scrolling.Size = UDim2.new(1, -20, 1, -60)
scrolling.Position = UDim2.new(0, 10, 0, 50)
scrolling.BackgroundTransparency = 1
scrolling.Parent = frame

-- Build companion cards
local yPos = 0
for name, companion in pairs(NPCConfig.goldShopCompanions) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 80)
	card.Position = UDim2.new(0, 0, 0, yPos)
	card.BackgroundColor3 = Color3.fromRGB(225, 220, 240)
	card.Parent = scrolling
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = UIConfig.COLORS.TextDark
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0.5, -10, 0, 30)
	priceLabel.Position = UDim2.new(0.5, 0, 0, 5)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 " .. companion.price .. "g"
	priceLabel.TextColor3 = UIConfig.COLORS.Warning
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextScaled = true
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = card

	local buffLabel = Instance.new("TextLabel")
	buffLabel.Size = UDim2.new(1, -20, 0, 20)
	buffLabel.Position = UDim2.new(0, 10, 0, 35)
	buffLabel.BackgroundTransparency = 1
	if companion.buff and type(companion.buff) == "table" then
		buffLabel.Text = "Buff: " .. companion.buff.stat .. " | Level: " .. (companion.levelRequired or 1)
	else
		buffLabel.Text = "Buff: none | Level: " .. (companion.levelRequired or 1)
	end
	buffLabel.TextColor3 = UIConfig.COLORS.TextDarkSec
	buffLabel.Font = Enum.Font.Gotham
	buffLabel.TextScaled = true
	buffLabel.TextXAlignment = Enum.TextXAlignment.Left
	buffLabel.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 80, 0, 24)
	buyBtn.Position = UDim2.new(1, -90, 0, 50)
	buyBtn.BackgroundColor3 = UIConfig.COLORS.Success
	buyBtn.Text = "Buy"
	buyBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextScaled = true
	buyBtn.Parent = card
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 4)

	buyBtn.MouseButton1Click:Connect(function()
		local ok, msg = purchaseRF:InvokeServer(name)
		if ok then
			print("[CompanionGoldShop] Purchased " .. name .. "!")
			buyBtn.Text = "Owned!"
			buyBtn.BackgroundColor3 = UIConfig.COLORS.Success
		else
			print("[CompanionGoldShop] Purchase failed: " .. tostring(msg))
			buyBtn.Text = "Failed"
			buyBtn.BackgroundColor3 = UIConfig.COLORS.Danger
		end
	end)

	yPos = yPos + 90
end
scrolling.CanvasSize = UDim2.new(0, 0, 0, yPos)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = UIConfig.COLORS.Danger
closeBtn.Text = "X"
closeBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

print("[CompanionGoldShop] Loaded")