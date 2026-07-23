-- [[LocalScript] MaterialsScript (ref: RBX860E7F775E52472195E1528E84F05BDA)]]
-- MaterialsScript: Materials inventory panel + pickup notifications + sky sync.
-- Listens to NotifyPlayer / loot pickups and updates the materials panel.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientGuiBootstrap = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("ClientGuiBootstrap"))

local gui
local panel
local toggleBtn
local closeBtn
local listFrame

for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") and g:FindFirstChild("MaterialsList", true) then
		gui = g
		gui.ResetOnSpawn = false
		panel = gui:FindFirstChild("Panel", true)
		toggleBtn = gui:FindFirstChild("ToggleButton", true)
		closeBtn = panel and (panel:FindFirstChild("CloseBtn", true) or panel:FindFirstChild("TextButton", true))
		listFrame = panel and panel:FindFirstChild("MaterialsList", true)
		break
	end
end

if not gui or not panel or not listFrame then
	gui = ClientGuiBootstrap.createScreenGui(player, "MaterialsGui", 24)

	panel = Instance.new("Frame", gui)
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 420, 0, 480)
	panel.Position = UDim2.new(0.5, -210, 0.5, -240)
	panel.BackgroundColor3 = Color3.fromRGB(24, 32, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(120, 200, 180)
	stroke.Thickness = 2

	local title = Instance.new("TextLabel", panel)
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 44)
	title.Position = UDim2.new(0, 16, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🎒  Materials Inventory 🎀"
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(200, 240, 230)
	title.TextXAlignment = Enum.TextXAlignment.Left

	closeBtn = Instance.new("TextButton", panel)
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	listFrame = Instance.new("ScrollingFrame", panel)
	listFrame.Name = "MaterialsList"
	listFrame.Size = UDim2.new(1, -28, 1, -72)
	listFrame.Position = UDim2.new(0, 14, 0, 60)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 200, 180)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	local layout = Instance.new("UIListLayout", listFrame)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
end

local toasts = gui:FindFirstChild("ToastContainer", true)
if not toasts then
	toasts = Instance.new("Frame", gui)
	toasts.Name = "ToastContainer"
	toasts.Size = UDim2.new(0, 280, 1, -40)
	toasts.Position = UDim2.new(1, -300, 0, 20)
	toasts.BackgroundTransparency = 1
end

local RE = RS:WaitForChild("RemoteEvents")
local notify = RE:FindFirstChild("NotifyPlayer")
local makeLoot = RE:FindFirstChild("MakeLootEvent")
local requestData = RS:WaitForChild("RemoteFunctions"):FindFirstChild("RequestData")
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local CozyModalShell = require(RS.ConfigurationFiles.CozyModalShell)
local UIRouter = require(RS.ConfigurationFiles.UIRouter)
local ActionRegistry = require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

local C = {
	bg = UIConfig.COLORS.MochiCream,
	border = UIConfig.COLORS.ZundaDark,
	text = UIConfig.COLORS.TextDark,
	sub = UIConfig.COLORS.TextDarkSec,
	btnAct = UIConfig.COLORS.ZundaPrimary,
	btnIdle = UIConfig.COLORS.PeaAccent,
}

local function styleFor(name)
	return { color = UIHelper.getItemColor(name), icon = nil }
end

-- ---- MATERIAL CARDS ----
local cards = {}
local function getOrCreateCard(name)
	if cards[name] then
		return cards[name]
	end
	local style = styleFor(name)
	local card = Instance.new("Frame")
	card.Name = "Mat_" .. name
	card.Size = UDim2.new(1, -10, 0, 40)
	card.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	card.BorderSizePixel = 0
	card.Parent = listFrame
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 32, 0, 32)
	swatch.Position = UDim2.new(0, 4, 0, 4)
	swatch.BackgroundColor3 = style.color
	swatch.BorderSizePixel = 0
	swatch.Parent = card
	Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)

	local icon = UIHelper.createItemIcon(name, UDim2.new(1, 0, 1, 0), swatch)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -90, 1, 0)
	nameLbl.Position = UDim2.new(0, 42, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = Color3.fromRGB(80, 50, 40)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamMedium
	nameLbl.Parent = card

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.new(0, 50, 1, 0)
	count.Position = UDim2.new(1, -54, 0, 0)
	count.BackgroundTransparency = 1
	count.Text = "0"
	count.TextColor3 = Color3.fromRGB(160, 80, 30)
	count.TextScaled = true
	count.Font = Enum.Font.GothamBold
	count.Parent = card

	cards[name] = card
	return card
end

local function setMaterialCount(name, count)
	local card = getOrCreateCard(name)
	card.Count.Text = tostring(count)
end

-- Refresh whole inventory from server
local function refresh()
	if not requestData then
		return
	end
	local ok, data = pcall(function()
		return requestData:InvokeServer()
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	-- Hide cards that no longer exist
	for name, card in pairs(cards) do
		if not data[name] or data[name] == 0 then
			card.Count.Text = "0"
		end
	end
	for name, count in pairs(data) do
		if type(count) == "number" and count > 0 then
			setMaterialCount(name, count)
		end
	end
end

-- ---- TOAST POPUPS ----
local function spawnToast(text, color)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 260, 0, 50)
	toast.BackgroundColor3 = color or Color3.fromRGB(255, 220, 180)
	toast.BorderSizePixel = 0
	toast.Parent = toasts
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 70, 40)
	stroke.Thickness = 2
	stroke.Parent = toast

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 1, 0)
	lbl.Position = UDim2.new(0, 5, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(80, 50, 30)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = toast

	toast.BackgroundTransparency = 1
	lbl.TextTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(lbl, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
	task.delay(2.5, function()
		TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.5, function()
			toast:Destroy()
		end)
	end)
end

-- ---- TOGGLE ----
local shell = CozyModalShell.wrap(panel, {
	actionId = "materials",
	open = function()
		panel.Visible = true
	end,
	close = function()
		panel.Visible = false
	end,
})

local function setOpen(state)
	if state then
		UIRouter.open("materials")
		shell.open()
	else
		UIRouter.close("materials")
		shell.close()
	end
end

-- Also wire the ZundaHUD button if present
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local hud = pg:WaitForChild("ZundaHUD", 5)
	if not hud then
		return
	end
	local hb = hud:WaitForChild("HudButtons", 5)
	if not hb then
		return
	end
	local hbtn = hb:WaitForChild("HudBtn_materials", 5)
	if hbtn then
		hbtn.MouseButton1Click:Connect(function()
			setOpen(not panel.Visible)
		end)
	end
end)
closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
	local pos = closeBtn.AbsolutePosition
	UIHelper.spawnSparkles(panel, pos.X + 20, pos.Y + 20, Color3.fromRGB(255,255,255), 5)
end)

-- ---- LISTEN FOR NOTIFICATIONS ----
if notify then
	notify.OnClientEvent:Connect(function(kind, message)
		local color
		if kind == "gather_success" then
			color = Color3.fromRGB(180, 230, 180)
		elseif kind == "unlock" then
			color = Color3.fromRGB(255, 220, 130)
		elseif kind == "error" then
			color = Color3.fromRGB(255, 180, 180)
		else
			color = Color3.fromRGB(255, 250, 220)
		end
		spawnToast(message, color)
		refresh()
	end)
end

-- ---- SKY SYNC ----
-- Adjust panel title color based on time of day to feel alive
local function updateSkyColors()
	local title = panel:FindFirstChild("Title")
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local t = hour % 24
	local isNight = t < 6 or t > 19
	if isNight then
		if title then title.TextColor3 = Color3.fromRGB(160, 140, 200) end
		if toggleBtn then toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 150) end
	else
		if title then title.TextColor3 = Color3.fromRGB(200, 240, 230) end
		if toggleBtn then toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50) end
	end
end
Lighting:GetAttributeChangedSignal("CurrentHour"):Connect(updateSkyColors)
updateSkyColors()

-- ---- INITIAL REFRESH ----
task.wait(2)
refresh()
-- Safety re-sync in case events are missed
task.spawn(function()
	while true do
		task.wait(60)
		refresh()
	end
end)

-- Register with UIRouter for modal exclusivity and Escape handling
UIRouter.register("materials", nil, function()
	shell.close()
end)

-- Register with ActionRegistry for Pea Wheel dispatch
ActionRegistry.registerCallback("materials", function()
	setOpen(not panel.Visible)
end)

print("[MaterialsInventory] Loaded")
