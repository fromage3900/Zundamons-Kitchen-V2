--!strict
-- ZundaMaterialAuthoring — Studio plugin for the Infinity Nikki pastel palette.
-- Entry point: Script saved as Local Plugin in Roblox Studio (see src/Plugins).
-- Build: rojo build "src/Plugins/material-plugin.project.json" -o build/ZundaMaterialAuthoring.rbxm
--
-- Features:
--   * Palette browser (Zunda Green/Gold/Pink/Mint, Mochi Cream, Edamame Deep)
--   * Paint selection (direct material+color or persistent MaterialVariant)
--   * Optional suggested attributes (Reflectance etc.)
--   * Export Lua config snippets for the shared palette hub
--   * Settings persisted per-user via plugin:SetSetting

local plugin = script:FindFirstAncestorWhichIsA("Plugin")
if not plugin then
	error("[ZundaMaterialAuthoring] This script must be saved as a Local Plugin in Roblox Studio")
end

-- ============================================================
-- MODULE LOADER
-- ============================================================
local Modules = {}
local function req(name: string)
	if not Modules[name] then
		local child = script:FindFirstChild(name)
		if not child then
			error("[ZundaMaterialAuthoring] Module not found: " .. name)
		end
		Modules[name] = require(child)
	end
	return Modules[name]
end

local ZundaPalette = req("ZundaPalette")
local ZundaMaterialUtils = req("ZundaMaterialUtils")

-- ============================================================
-- PLUGIN STATE + PERSISTENCE
-- ============================================================
local PLUGIN_ID = "ZundaMaterialAuthoring_v1"
local state = {
	selectedName = nil,
	createVariant = true,
	applyAttributes = true,
}

local function loadSettings()
	local saved = plugin:GetSetting("lastMaterial")
	if saved then
		state.selectedName = saved
	end
	local cv = plugin:GetSetting("createVariant")
	if cv ~= nil then
		state.createVariant = cv
	end
	local aa = plugin:GetSetting("applyAttributes")
	if aa ~= nil then
		state.applyAttributes = aa
	end
	if not state.selectedName or not ZundaPalette.getMaterial(state.selectedName) then
		state.selectedName = ZundaPalette.getAllNames()[1]
	end
end

local function saveSettings()
	plugin:SetSetting("lastMaterial", state.selectedName)
	plugin:SetSetting("createVariant", state.createVariant)
	plugin:SetSetting("applyAttributes", state.applyAttributes)
end

-- ============================================================
-- TOOLBAR + WIDGET
-- ============================================================
local toolbar = plugin:CreateToolbar("Zunda Material")

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 360, 560, 320, 460)

local widget = plugin:CreateDockWidgetPluginGuiAsync(PLUGIN_ID .. "_MainWidget", widgetInfo)
widget.Title = "🌸 Zunda Material Authoring"
widget:BindToClose(function()
	widget.Enabled = false
end)

-- ============================================================
-- UI CONSTRUCTION
-- ============================================================
local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(245, 240, 230)
root.BorderSizePixel = 0
root.Parent = widget

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.07)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Zunda Material Authoring"
title.TextColor3 = Color3.fromRGB(70, 110, 70)
title.TextScaled = true
title.Parent = root

local paletteLabel = Instance.new("TextLabel")
paletteLabel.Size = UDim2.fromScale(1, 0.04)
paletteLabel.Position = UDim2.fromScale(0, 0.07)
paletteLabel.BackgroundTransparency = 1
paletteLabel.Font = Enum.Font.GothamMedium
paletteLabel.Text = "PALETTE"
paletteLabel.TextColor3 = Color3.fromRGB(120, 120, 110)
paletteLabel.TextXAlignment = Enum.TextXAlignment.Left
paletteLabel.Parent = root

local paletteList = Instance.new("ScrollingFrame")
paletteList.Size = UDim2.new(1, -12, 0, 260)
paletteList.Position = UDim2.fromScale(0.015, 0.12)
paletteList.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
paletteList.BorderSizePixel = 1
paletteList.BorderColor3 = Color3.fromRGB(200, 190, 170)
paletteList.ScrollBarThickness = 6
paletteList.CanvasSize = UDim2.fromScale(0, 0)
paletteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
paletteList.Parent = root

local buttons: { [string]: TextButton } = {}
local function highlightSelection()
	for name, btn in pairs(buttons) do
		btn.BackgroundColor3 = if name == state.selectedName
			then Color3.fromRGB(160, 210, 150)
			else Color3.fromRGB(255, 253, 248)
	end
end

for _, name in ipairs(ZundaPalette.getAllNames()) do
	local spec = ZundaPalette.getMaterial(name)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 44)
	row.BackgroundTransparency = 1
	row.LayoutOrder = #buttons
	row.Parent = paletteList

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(26, 26)
	swatch.Position = UDim2.fromOffset(6, 9)
	swatch.BackgroundColor3 = spec.color
	swatch.BorderSizePixel = 1
	swatch.BorderColor3 = Color3.fromRGB(160, 160, 140)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = swatch
	swatch.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.fromOffset(40, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = spec.displayName .. "  ·  " .. tostring(spec.color)
	label.TextColor3 = Color3.fromRGB(60, 60, 50)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row
	btn.MouseButton1Click:Connect(function()
		state.selectedName = name
		saveSettings()
		highlightSelection()
	end)
	buttons[name] = btn
end
highlightSelection()

local optsFrame = Instance.new("Frame")
optsFrame.Size = UDim2.new(1, -12, 0, 40)
optsFrame.Position = UDim2.new(0.015, 0, 0, 384)
optsFrame.BackgroundTransparency = 1
optsFrame.Parent = root

local createVariantBtn = Instance.new("TextButton")
createVariantBtn.Size = UDim2.fromScale(0.5, 0.9)
createVariantBtn.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
createVariantBtn.BorderSizePixel = 1
createVariantBtn.BorderColor3 = Color3.fromRGB(200, 190, 170)
createVariantBtn.Font = Enum.Font.GothamMedium
createVariantBtn.Text = "MaterialVariant"
createVariantBtn.Parent = optsFrame
createVariantBtn.MouseButton1Click:Connect(function()
	state.createVariant = not state.createVariant
	createVariantBtn.BackgroundColor3 = if state.createVariant
		then Color3.fromRGB(160, 210, 150)
		else Color3.fromRGB(255, 253, 248)
	saveSettings()
end)
createVariantBtn.BackgroundColor3 = if state.createVariant
	then Color3.fromRGB(160, 210, 150)
	else Color3.fromRGB(255, 253, 248)

local attrsBtn = Instance.new("TextButton")
attrsBtn.Size = UDim2.fromScale(0.5, 0.9)
attrsBtn.Position = UDim2.fromScale(0.5, 0)
attrsBtn.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
attrsBtn.BorderSizePixel = 1
attrsBtn.BorderColor3 = Color3.fromRGB(200, 190, 170)
attrsBtn.Font = Enum.Font.GothamMedium
attrsBtn.Text = "Suggested attributes"
attrsBtn.Parent = optsFrame
attrsBtn.MouseButton1Click:Connect(function()
	state.applyAttributes = not state.applyAttributes
	attrsBtn.BackgroundColor3 = if state.applyAttributes
		then Color3.fromRGB(160, 210, 150)
		else Color3.fromRGB(255, 253, 248)
	saveSettings()
end)
attrsBtn.BackgroundColor3 = if state.applyAttributes
	then Color3.fromRGB(160, 210, 150)
	else Color3.fromRGB(255, 253, 248)

local actionRow = Instance.new("Frame")
actionRow.Size = UDim2.new(1, -12, 0, 44)
actionRow.Position = UDim2.new(0.015, 0, 0, 428)
actionRow.BackgroundTransparency = 1
actionRow.Parent = root

local function makeActionButton(label: string, x: number, w: number)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(w, -6, 1, 0)
	btn.Position = UDim2.new(x, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(70, 110, 70)
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = label
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = actionRow
	return btn
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -12, 0, 30)
statusLabel.Position = UDim2.new(0.015, 0, 0, 476)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(90, 150, 90)
statusLabel.TextWrapped = true
statusLabel.TextScaled = true
statusLabel.Parent = root

local applyBtn = makeActionButton("Apply to Selection", 0, 0.5)
applyBtn.MouseButton1Click:Connect(function()
	local spec = ZundaPalette.getMaterial(state.selectedName)
	if not spec then
		statusLabel.Text = "Select a palette entry first."
		return
	end
	local selection = game:GetService("Selection"):Get()
	if #selection == 0 then
		statusLabel.Text = "Select parts or models in the viewport first."
		return
	end
	local ok, result = pcall(function()
		return ZundaMaterialUtils.applyToSelection(selection, spec, state.createVariant, state.applyAttributes)
	end)
	if not ok then
		statusLabel.Text = "Error: " .. tostring(result)
		return
	end
	if state.createVariant then
		local variant = ZundaPalette.findOrCreateVariant(spec.name, spec)
		statusLabel.Text = string.format(
			"Painted %d part(s) with %s (MaterialVariant) 🌸",
			result,
			ZundaMaterialUtils.describeVariant(variant) or spec.name
		)
	else
		statusLabel.Text = string.format("Painted %d part(s) with %s (direct material) 🌸", result, spec.displayName)
	end
end)

local exportBtn = makeActionButton("Export Config", 0.5, 0.5)

local outputLabel = Instance.new("TextLabel")
outputLabel.Size = UDim2.fromScale(1, 0.04)
outputLabel.Position = UDim2.fromScale(0, 0.72)
outputLabel.BackgroundTransparency = 1
outputLabel.Font = Enum.Font.GothamMedium
outputLabel.Text = "EXPORTED CONFIG (Rojo-owned module)"
outputLabel.TextColor3 = Color3.fromRGB(120, 120, 110)
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.Parent = root

local outputBox = Instance.new("TextBox")
outputBox.Size = UDim2.new(1, -12, 0, 100)
outputBox.Position = UDim2.new(0.015, 0, 0.77, 0)
outputBox.BackgroundColor3 = Color3.fromRGB(40, 42, 38)
outputBox.BorderSizePixel = 1
outputBox.BorderColor3 = Color3.fromRGB(200, 190, 170)
outputBox.ClearTextOnFocus = false
outputBox.Font = Enum.Font.Code
outputBox.Text = ""
outputBox.TextColor3 = Color3.fromRGB(210, 230, 200)
outputBox.TextWrapped = true
outputBox.TextXAlignment = Enum.TextXAlignment.Left
outputBox.TextYAlignment = Enum.TextYAlignment.Top
outputBox.MultiLine = true
outputBox.Parent = root

exportBtn.MouseButton1Click:Connect(function()
	local spec = ZundaPalette.getMaterial(state.selectedName)
	if not spec then
		statusLabel.Text = "Select a palette entry first."
		return
	end
	outputBox.Text = ZundaMaterialUtils.generateConfigSnippet(spec)
	statusLabel.Text = "Config snippet copied to the output box — paste into ZundaPalette.lua / shared config."
end)

-- ============================================================
-- TOOLBAR BUTTON
-- ============================================================
local toggleBtn =
	toolbar:CreateButton("Zunda Material", "Open/Close Zunda Material Authoring", "rbxassetid://123736711329002")
toggleBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================
local function init()
	loadSettings()
	local registered = ZundaPalette.registerAll()
	print(string.format("[ZundaMaterialAuthoring] Registered %d MaterialVariant(s) in MaterialService", registered))
	highlightSelection()
	saveSettings()
end

task.spawn(init)

plugin.Unloading:Connect(function()
	widget:Destroy()
end)

return {
	name = "ZundaMaterialAuthoring",
	version = "1.0.0",
	plugin = plugin,
	state = state,
}
