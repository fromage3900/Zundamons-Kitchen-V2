local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local serveGuestRF = RS.RemoteFunctions:WaitForChild("ServeGuest")

-- Reactive player data: subscribe to the projection remote so the dish list
-- is always current (cooking a dish after opening the UI now shows it).
local playerStateChanged = RS.RemoteEvents:WaitForChild("PlayerStateChanged")
local latestData = {}

local gui = ClientGuiBootstrap.createScreenGui(player, "GuestServingUI", 85)
gui.Enabled = false

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

-- Filter to only the dish the guest wants, using the reactive projection.
local function buildDishList(guest, playerData)
	for _, child in ipairs(listFrame:GetChildren()) do
		child:Destroy()
	end
	local dish = guest:GetAttribute("PreferredRecipe") or ""
	title.Text = "Serve: " .. dish
	payLabel.Text = "Pay: " .. (guest:GetAttribute("PayAmount") or 10) .. " Gold"
	guestLabel.Text = "Guest: " .. (guest:GetAttribute("GuestName") or "Customer")

	-- The projection has cookedDishes keyed by recipe -> quality -> count.
	-- Show the total count of the requested dish across all qualities.
	local cooked = playerData and playerData.cookedDishes and playerData.cookedDishes[dish]
	local total = 0
	if type(cooked) == "table" then
		for _, count in pairs(cooked) do
			if type(count) == "number" then
				total += count
			end
		end
	end

	if total > 0 then
		local btn = Instance.new("TextButton", listFrame)
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = UIConfig.COLORS.Success
		btn.Text = dish .. " x" .. tostring(total)
		btn.FontFace = UIConfig.FONTS.Body
		btn.TextSize = UIConfig.FONT_SIZES.Body
		btn.TextColor3 = UIConfig.COLORS.TextOnPrimary
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		Instance.new("UICorner", btn).CornerRadius = UIConfig.CORNER_RADIUS.Small
		btn.MouseButton1Click:Connect(function()
			serveButton.Visible = true
			serveButton.Text = "Serve " .. dish
		end)
	else
		local lbl = Instance.new("TextLabel", listFrame)
		lbl.Size = UDim2.new(1, 0, 0, 40)
		lbl.BackgroundTransparency = 1
		lbl.Text = "No " .. dish .. " in inventory — cook it first!"
		lbl.FontFace = UIConfig.FONTS.Body
		lbl.TextSize = UIConfig.FONT_SIZES.Body
		lbl.TextColor3 = UIConfig.COLORS.TextDisabled
		lbl.TextWrapped = true
	end
end

local function show()
	if not currentGuest then
		return
	end
	backdrop.Visible = true
	panel.Visible = true
	gui.Enabled = true
	buildDishList(currentGuest, latestData)
end

local function hide()
	gui.Enabled = false
	backdrop.Visible = false
	panel.Visible = false
	serveButton.Visible = false
	currentGuest = nil
end

_G.ZundaShowServeUI = function(guest, _data)
	currentGuest = guest
	-- Prefer the reactive projection; fall back to whatever was passed.
	if _data and next(_data) then
		latestData = _data
	end
	show()
end

cancelButton.MouseButton1Click:Connect(hide)

serveButton.MouseButton1Click:Connect(function()
	if not currentGuest then
		return
	end
	local dish = currentGuest:GetAttribute("PreferredRecipe") or ""
	local ok, result = pcall(function()
		return serveGuestRF:InvokeServer(currentGuest, dish)
	end)
	-- Always close the UI, even if the serve fails, so the black
	-- backdrop never gets stuck on screen.
	hide()
end)

-- Keep the dish list fresh while the panel is open.
playerStateChanged.OnClientEvent:Connect(function(projection)
	latestData = projection
	if panel.Visible and currentGuest then
		buildDishList(currentGuest, latestData)
	end
end)

print("[GuestServingUI] Ready (reactive)")
