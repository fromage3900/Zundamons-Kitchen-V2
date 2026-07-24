--!strict
-- MainWidget: Dockable UI for ZundaWorldDecorator
-- Infinity Nikki aesthetic: pastel palette, style identity display, sparkle density
local MainWidget = {}

local ZUNDA_GREEN = Color3.fromRGB(160, 210, 150)
local GOLD = Color3.fromRGB(255, 200, 80)
local PINK = Color3.fromRGB(255, 150, 200)
local MINT = Color3.fromRGB(145, 215, 195)
local TEXT_DARK = Color3.fromRGB(52, 67, 49)

function MainWidget.new(widget, plugin, config)
	local self = setmetatable({}, { __index = MainWidget })
	self.widget = widget
	self.plugin = plugin
	self.state = config.state
	self.zones = config.zones
	self.decorations = config.decorations
	self._config = config
	self._root = nil
	self._status = nil
	self._densityLabel = nil
	self._styleLabel = nil
	self:_buildUI()
	return self
end

function MainWidget:_buildUI()
	local root = Instance.new("ScrollingFrame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = ZUNDA_GREEN
	root.BorderSizePixel = 0
	root.CanvasSize = UDim2.fromOffset(0, 0)
	root.AutomaticCanvasSize = Enum.AutomaticSize.Y
	root.ScrollBarThickness = 6
	root.Parent = self.widget

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = root

	self._root = root

	self:_addLabel("🌸 Zunda World Decorator", 32, true)
	self:_addLabel("Style your world like an outfit!", 18)

	self:_addLabel("Zone", 16, true)
	self._zoneDropdown = self:_addDropdown(self.zones, self.state.selectedZone, function(zone)
		self.state.selectedZone = zone
		local ZoneProfiles = require(self.widget:FindFirstAncestorWhichIsA("ModuleScript"):FindFirstChild("ZoneProfiles"))
		local identity = ZoneProfiles.getStyleIdentity(zone)
		self._styleLabel.Text = "Style Identity: " .. identity
	end)

	self._styleLabel = self:_addLabel("Style Identity: —", 14, false, MINT)

	self:_addLabel("Decoration Selection", 16, true)
	self._decoDropdown = self:_addDropdown(self.decorations, self.state.selectedDecorations[1], nil)

	self:_addLabel("Density: " .. string.format("%.2f", self.state.density), 14, true)
	self._densityLabel = self:_addLabel("Density: " .. string.format("%.2f", self.state.density), 14)
	self._densitySlider = self:_addSlider(self.state.density, function(value)
		self.state.density = value
		self._densityLabel.Text = "Density: " .. string.format("%.2f", value)
	end)

	self:_addLabel("Options", 16, true)
	self:_addCheckbox("Apply Materials", self.state.applyMaterials, function(value)
		self.state.applyMaterials = value
	end)
	self:_addCheckbox("Apply Vistas", self.state.applyVistas, function(value)
		self.state.applyVistas = value
	end)
	self:_addCheckbox("Dry Run (preview only)", self.state.dryRun, function(value)
		self.state.dryRun = value
	end)

	self:_addButton("✨ Decorate Zone", GOLD, function()
		local zoneName = self.state.selectedZone
		if not zoneName then
			self:_report("Select a zone first!", "error")
			return
		end
		local deco = self._decoDropdown.Text
		if not deco or deco == "" then
			self:_report("Select a decoration!", "error")
			return
		end
		self._config.onDecorate(zoneName, {
			density = self.state.density,
			selectedDecorations = {deco},
			applyMaterials = self.state.applyMaterials,
			applyVistas = self.state.applyVistas,
			dryRun = self.state.dryRun,
		})
	end)

	self:_addButton("↩ Undo Zone", PINK, function()
		if self.state.selectedZone then
			self._config.onUndo(self.state.selectedZone)
		end
	end)

	self:_addButton("🗑 Clear All", PINK, function()
		self._config.onClearAll()
	end)

	self._status = self:_addLabel("Ready to style! 🌸", 14, false, MINT)
	self._status.BackgroundTransparency = 0
	self._status.BackgroundColor3 = Color3.fromRGB(230, 241, 225)
end

function MainWidget:_addLabel(text, height, bold, color)
	local item = Instance.new("TextLabel")
	item.Size = UDim2.new(1, 0, 0, height or 24)
	item.BackgroundTransparency = 1
	item.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	item.TextSize = 13
	item.TextColor3 = color or TEXT_DARK
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Text = text
	item.Parent = self._root
	return item
end

function MainWidget:_addDropdown(options, initialValue, callback)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 32)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.BorderColor3 = ZUNDA_GREEN
	box.Font = Enum.Font.Code
	box.TextSize = 13
	box.TextColor3 = TEXT_DARK
	box.PlaceholderText = "Select..."
	box.ClearTextOnFocus = false
	box.Text = initialValue or ""
	box.Parent = self._root

	box.FocusLost:Connect(function()
		if callback then
			callback(box.Text)
		end
	end)

	return box
end

function MainWidget:_addSlider(initialValue, callback)
	local slider = Instance.new("Frame")
	slider.Size = UDim2.new(1, 0, 0, 32)
	slider.BackgroundTransparency = 1
	slider.Parent = self._root

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.new(0, 0, 0, 10)
	bar.BackgroundColor3 = MINT
	bar.BorderSizePixel = 0
	bar.Parent = slider

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(initialValue, 0, 1, 0)
	fill.BackgroundColor3 = ZUNDA_GREEN
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, 0, 0, 20)
	input.Position = UDim2.new(0, 0, 0, 12)
	input.BackgroundTransparency = 1
	input.Font = Enum.Font.Code
	input.TextSize = 12
	input.TextColor3 = TEXT_DARK
	input.Text = string.format("%.2f", initialValue)
	input.ClearTextOnFocus = false
	input.Parent = slider

	input.FocusLost:Connect(function()
		local val = tonumber(input.Text)
		if val then
			val = math.clamp(val, 0, 1)
			callback(val)
			fill.Size = UDim2.new(val, 0, 1, 0)
		end
	end)

	return slider
end

function MainWidget:_addCheckbox(label, initialValue, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 28)
	frame.BackgroundTransparency = 1
	frame.Parent = self._root

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 20, 0, 20)
	button.Position = UDim2.new(0, 0, 0, 4)
	button.BackgroundColor3 = if initialValue then ZUNDA_GREEN else Color3.fromRGB(220, 220, 220)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = TEXT_DARK
	button.Text = if initialValue then "✓" else ""
	button.Parent = frame

	local labelItem = Instance.new("TextLabel")
	labelItem.Size = UDim2.new(1, -30, 0, 20)
	labelItem.Position = UDim2.new(0, 28, 0, 4)
	labelItem.BackgroundTransparency = 1
	labelItem.Font = Enum.Font.Gotham
	labelItem.TextSize = 13
	labelItem.TextColor3 = TEXT_DARK
	labelItem.TextXAlignment = Enum.TextXAlignment.Left
	labelItem.Text = label
	labelItem.Parent = frame

	button.MouseButton1Click:Connect(function()
		initialValue = not initialValue
		button.BackgroundColor3 = if initialValue then ZUNDA_GREEN else Color3.fromRGB(220, 220, 220)
		button.Text = if initialValue then "✓" else ""
		if callback then
			callback(initialValue)
		end
	end)

	return frame
end

function MainWidget:_addButton(text, color, callback)
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1, 0, 0, 34)
	item.BackgroundColor3 = color or ZUNDA_GREEN
	item.BorderSizePixel = 0
	item.Font = Enum.Font.GothamBold
	item.TextSize = 13
	item.TextColor3 = TEXT_DARK
	item.Text = text
	item.Parent = self._root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = item

	item.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return item
end

function MainWidget:_report(message, level)
	if not self._status then return end
	self._status.Text = message
	if level == "error" then
		self._status.BackgroundColor3 = Color3.fromRGB(255, 190, 205)
	elseif level == "warning" then
		self._status.BackgroundColor3 = Color3.fromRGB(255, 225, 150)
	else
		self._status.BackgroundColor3 = Color3.fromRGB(230, 241, 225)
	end
end

function MainWidget:destroy()
	if self.widget then
		self.widget:Destroy()
	end
end

return MainWidget
