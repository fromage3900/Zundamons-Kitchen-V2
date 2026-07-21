-- [[LocalScript] MaterialsScript (ref: RBX860E7F775E52472195E1528E84F05BDA)]]
-- MaterialsScript: Materials inventory panel + pickup notifications + sky sync.
-- Listens to NotifyPlayer / loot pickups and updates the materials panel.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Panel")
local toggleBtn = gui:WaitForChild("ToggleButton")
local closeBtn = panel.TitleBar:WaitForChild("TextButton")
local listFrame = panel:WaitForChild("MaterialsList")
local toasts = gui:WaitForChild("ToastContainer")

local RE = RS:WaitForChild("RemoteEvents")
local notify = RE:FindFirstChild("NotifyPlayer")
local makeLoot = RE:FindFirstChild("MakeLootEvent")
local requestData = RS:WaitForChild("RemoteFunctions"):FindFirstChild("RequestData")
local UIHelper = require(RS.Shared.Modules.UIHelper)

local function styleFor(name)
	return {color = UIHelper.getItemColor(name), icon = nil}
end

-- ---- MATERIAL CARDS ----
local cards = {}
local function getOrCreateCard(name)
	if cards[name] then return cards[name] end
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
	if not requestData then return end
	local ok, data = pcall(function() return requestData:InvokeServer() end)
	if not ok or type(data) ~= "table" then return end
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
	TweenService:Create(toast, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	task.delay(2.5, function()
		TweenService:Create(toast, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		TweenService:Create(lbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
		task.delay(0.5, function() toast:Destroy() end)
	end)
end

-- ---- TOGGLE ----
local function setOpen(state) panel.Visible = state end
toggleBtn.MouseButton1Click:Connect(function() setOpen(not panel.Visible) end)

-- Also wire the ZundaHUD button if present
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local hud = pg:WaitForChild("ZundaHUD", 5)
	if not hud then return end
	local hb = hud:WaitForChild("HudButtons", 5)
	if not hb then return end
	local hbtn = hb:WaitForChild("HudBtn_materials", 5)
	if hbtn then
		hbtn.MouseButton1Click:Connect(function() setOpen(not panel.Visible) end)
	end
end)
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then setOpen(not panel.Visible) end
end)

-- ---- LISTEN FOR NOTIFICATIONS ----
if notify then
	notify.OnClientEvent:Connect(function(kind, message)
		local color
		if kind == "gather_success" then color = Color3.fromRGB(180, 230, 180)
		elseif kind == "unlock" then color = Color3.fromRGB(255, 220, 130)
		elseif kind == "error" then color = Color3.fromRGB(255, 180, 180)
		else color = Color3.fromRGB(255, 250, 220) end
		spawnToast(message, color)
		refresh()
	end)
end

-- ---- SKY SYNC ----
-- Adjust panel title color based on time of day to feel alive
local function updateSkyColors()
	local hour = Lighting:GetAttribute("CurrentHour") or 12
	local t = hour % 24
	local isNight = t < 6 or t > 19
	if isNight then
		panel.TitleBar.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
		toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
	else
		panel.TitleBar.BackgroundColor3 = Color3.fromRGB(220, 180, 200)
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
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

print("[MaterialsInventory] Loaded - press I to toggle")
