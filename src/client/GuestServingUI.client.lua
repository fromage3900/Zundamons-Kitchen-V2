local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local serveGuestRF = RS.RemoteFunctions:WaitForChild("ServeGuest")
local requestData = RS.RemoteFunctions:WaitForChild("RequestData")

local gui = Instance.new("ScreenGui")
gui.Name = "GuestServingUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 85
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("TextButton", gui)
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundTransparency = 0.6
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.Text = ""
backdrop.BorderSizePixel = 0
backdrop.AutoButtonColor = false
backdrop.Visible = false

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 380, 0, 320)
panel.Position = UDim2.new(0.5, -190, 0.5, -160)
panel.BackgroundColor3 = UIConfig.COLORS.PanelBg
panel.BorderSizePixel = 0
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UIConfig.CORNER_RADIUS.Large
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = UIConfig.COLORS.PanelBorder
pStroke.Thickness = UIConfig.STROKE.Thickest

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = ""
title.FontFace = UIConfig.FONTS.Heading
title.TextSize = UIConfig.FONT_SIZES.Heading
title.TextColor3 = UIConfig.COLORS.TextDark

local guestLabel = Instance.new("TextLabel", panel)
guestLabel.Name = "GuestLabel"
guestLabel.Size = UDim2.new(1, -20, 0, 20)
guestLabel.Position = UDim2.new(0, 10, 0, 40)
guestLabel.BackgroundTransparency = 1
guestLabel.Text = ""
guestLabel.FontFace = UIConfig.FONTS.Body
guestLabel.TextSize = UIConfig.FONT_SIZES.Body
guestLabel.TextColor3 = UIConfig.COLORS.TextDarkSec
guestLabel.TextXAlignment = Enum.TextXAlignment.Left

local payLabel = Instance.new("TextLabel", panel)
payLabel.Name = "PayLabel"
payLabel.Size = UDim2.new(1, -20, 0, 20)
payLabel.Position = UDim2.new(0, 10, 0, 60)
payLabel.BackgroundTransparency = 1
payLabel.Text = ""
payLabel.FontFace = UIConfig.FONTS.Body
payLabel.TextSize = UIConfig.FONT_SIZES.Body
payLabel.TextColor3 = UIConfig.COLORS.SecondaryDark
payLabel.TextXAlignment = Enum.TextXAlignment.Left

local serveButton = Instance.new("TextButton", panel)
serveButton.Name = "ServeButton"
serveButton.Size = UDim2.new(0, 120, 0, 36)
serveButton.Position = UDim2.new(0.5, -60, 1, -44)
serveButton.BackgroundColor3 = UIConfig.COLORS.Primary
serveButton.Text = "Serve"
serveButton.FontFace = UIConfig.FONTS.Heading
serveButton.TextSize = UIConfig.FONT_SIZES.Button
serveButton.TextColor3 = UIConfig.COLORS.TextOnPrimary
serveButton.BorderSizePixel = 0
serveButton.AutoButtonColor = true
serveButton.Visible = false
Instance.new("UICorner", serveButton).CornerRadius = UIConfig.CORNER_RADIUS.Medium
local sStroke = Instance.new("UIStroke", serveButton)
sStroke.Color = UIConfig.COLORS.PrimaryDark
sStroke.Thickness = UIConfig.STROKE.Thin

local cancelButton = Instance.new("TextButton", panel)
cancelButton.Name = "CancelButton"
cancelButton.Size = UDim2.new(0, 100, 0, 36)
cancelButton.Position = UDim2.new(0.5, 60, 1, -44)
cancelButton.BackgroundColor3 = UIConfig.COLORS.Danger
cancelButton.Text = "Cancel"
cancelButton.FontFace = UIConfig.FONTS.Heading
cancelButton.TextSize = UIConfig.FONT_SIZES.Button
cancelButton.TextColor3 = UIConfig.COLORS.TextOnPrimary
cancelButton.BorderSizePixel = 0
cancelButton.AutoButtonColor = true
Instance.new("UICorner", cancelButton).CornerRadius = UIConfig.CORNER_RADIUS.Medium

local listFrame = Instance.new("ScrollingFrame", panel)
listFrame.Name = "DishList"
listFrame.Size = UDim2.new(1, -20, 0, 160)
listFrame.Position = UDim2.new(0, 10, 0, 88)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local currentGuest = nil
local currentPlayer = nil

local function filterFoods(data)
	local foods = {}
	if not data then return foods end
	local exclude = { gold = true, Apple = true, Wheat = true, Wood = true, Rock = true, ["Iron Ore"] = true,
		guests_served = true, chef = true, total_gold_earned = true, tier = true, cooking_streak = true,
		max_cooking_streak = true, perfect_cooks = true, great_cooks = true, companion_chats = true,
		companion_affection = true, npc_chats = true, zones_visited = true, gathered_items = true,
		quests_completed = true, recipes_unlocked = true, cosmetics_unlocked = true,
		furniture_unlocked = true, locations_unlocked = true}
	for k, v in pairs(data) do
		if type(k) == "string" and type(v) == "number" and not exclude[k] and not k:match("_") then
			if k ~= "Gold" and k ~= "Marble Rock" and k ~= "Wood Log" and k ~= "Pine Cone" then
				table.insert(foods, k)
			end
		end
	end
	return foods
end

local function buildDishList(guest, playerData)
	for _, child in ipairs(listFrame:GetChildren()) do child:Destroy() end
	local dish = guest:GetAttribute("PreferredRecipe") or ""
	title.Text = "Serve: " .. dish
	payLabel.Text = "Pay: " .. (guest:GetAttribute("PayAmount") or 10) .. " Gold"
	local foods = filterFoods(playerData)
	local y = 0
	for _, foodName in ipairs(foods) do
		if foodName == dish then
			local btn = Instance.new("TextButton", listFrame)
			btn.Size = UDim2.new(1, 0, 0, 32)
			btn.Position = UDim2.new(0, 0, 0, y)
			btn.BackgroundColor3 = UIConfig.COLORS.Success
			btn.Text = foodName .. " x" .. tostring(playerData[dish])
			btn.FontFace = UIConfig.FONTS.Body
			btn.TextSize = UIConfig.FONT_SIZES.Body
			btn.TextColor3 = UIConfig.COLORS.TextOnPrimary
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = true
			Instance.new("UICorner", btn).CornerRadius = UIConfig.CORNER_RADIUS.Small
			btn.MouseButton1Click:Connect(function()
				serveButton.Visible = true
				serveButton.Text = "Serve " .. foodName
			end)
			y = y + 36
		end
	end
	if y == 0 then
		local lbl = Instance.new("TextLabel", listFrame)
		lbl.Size = UDim2.new(1, 0, 0, 40)
		lbl.BackgroundTransparency = 1
		lbl.Text = "No matching dishes in inventory"
		lbl.FontFace = UIConfig.FONTS.Body
		lbl.TextSize = UIConfig.FONT_SIZES.Body
		lbl.TextColor3 = UIConfig.COLORS.TextDisabled
		lbl.TextWrapped = true
	end
end

local function show(data)
	if not currentGuest then return end
	backdrop.Visible = true
	panel.Visible = true
	gui.Enabled = true
	buildDishList(currentGuest, data)
end

_G.ZundaShowServeUI = function(guest, data)
	currentGuest = guest
	show(data)
end

cancelButton.MouseButton1Click:Connect(function()
	gui.Enabled = false
	backdrop.Visible = false
	panel.Visible = false
	serveButton.Visible = false
end)

serveButton.MouseButton1Click:Connect(function()
	if not currentGuest then return end
	local dish = currentGuest:GetAttribute("PreferredRecipe") or ""
	local ok, result = pcall(function()
		return serveGuestRF:InvokeServer(currentGuest, dish, "ok")
	end)
	if ok and result then
		gui.Enabled = false
		backdrop.Visible = false
		panel.Visible = false
		serveButton.Visible = false
	end
end)

print("[GuestServingUI] Ready")
