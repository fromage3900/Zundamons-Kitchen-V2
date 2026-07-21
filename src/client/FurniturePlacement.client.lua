-- Furniture shop + placement mode. Press P to toggle.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RF = RS:WaitForChild("RemoteFunctions")
local purchaseRF = RF:WaitForChild("PurchaseFurniture")
local placeRF = RF:WaitForChild("PlaceFurniture")
local removeRF = RF:WaitForChild("RemoveFurniture")

local DecorationConfig = require(RS.ConfigurationFiles.DecorationConfig)

local gui = Instance.new("ScreenGui")
gui.Name = "FurniturePlacementGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 80
gui.Enabled = false
gui.Parent = playerGui

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 420, 0, 480)
panel.Position = UDim2.new(0.5, -210, 0.5, -240)
panel.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
panel.BorderSizePixel = 0
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(180, 150, 110)
pStroke.Thickness = 3

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🛋 Furniture Shop"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(80, 40, 30)

local goldLbl = Instance.new("TextLabel", panel)
goldLbl.Name = "GoldDisplay"
goldLbl.Size = UDim2.new(0, 140, 0, 28)
goldLbl.Position = UDim2.new(1, -150, 0, 10)
goldLbl.BackgroundColor3 = Color3.fromRGB(255, 242, 180)
goldLbl.BorderSizePixel = 0
goldLbl.Text = "💰 ---"
goldLbl.Font = Enum.Font.GothamBold
goldLbl.TextSize = 14
goldLbl.TextColor3 = Color3.fromRGB(200, 150, 0)
Instance.new("UICorner", goldLbl).CornerRadius = UDim.new(0, 8)

local tabs = Instance.new("Frame", panel)
tabs.Name = "Tabs"
tabs.Size = UDim2.new(1, -20, 0, 32)
tabs.Position = UDim2.new(0, 10, 0, 46)
tabs.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabs)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)

local allItems = {}
for _, item in ipairs(DecorationConfig.garden_items) do table.insert(allItems, item) end
for _, item in ipairs(DecorationConfig.cottage_items) do table.insert(allItems, item) end

local tabData = {
	{ id = "garden", label = "🌷 Garden", items = DecorationConfig.garden_items },
	{ id = "cottage", label = "🏠 Cottage", items = DecorationConfig.cottage_items },
}
local tabBtns = {}
local activeTab = "garden"

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "ItemList"
scroll.Size = UDim2.new(1, -20, 1, -130)
scroll.Position = UDim2.new(0, 10, 0, 82)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(1, -90, 1, -38)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

local function renderTab(tabId)
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local items = {}
	for _, td in ipairs(tabData) do if td.id == tabId then items = td.items; break end end
	local y = 0
	local owned = _G.data and _G.data.furniture_unlocked or {}
	for _, item in ipairs(items) do
		local isOwned = owned and table.find(owned, item.id)
		local card = Instance.new("Frame", scroll)
		card.Size = UDim2.new(1, -6, 0, 64)
		card.Position = UDim2.new(0, 0, 0, y)
		card.BackgroundColor3 = isOwned and Color3.fromRGB(200, 240, 200) or Color3.fromRGB(245, 235, 220)
		card.BorderSizePixel = 0
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local icon = Instance.new("TextLabel", card)
		icon.Size = UDim2.new(0, 44, 0, 44)
		icon.Position = UDim2.new(0, 6, 0.5, -22)
		icon.BackgroundTransparency = 1
		icon.Text = item.icon or "📦"
		icon.TextSize = 28
		local nLbl = Instance.new("TextLabel", card)
		nLbl.Size = UDim2.new(1, -160, 0, 20)
		nLbl.Position = UDim2.new(0, 56, 0, 6)
		nLbl.BackgroundTransparency = 1
		nLbl.Text = item.name
		nLbl.Font = Enum.Font.GothamBold
		nLbl.TextSize = 15
		nLbl.TextColor3 = Color3.fromRGB(80, 40, 30)
		nLbl.TextXAlignment = Enum.TextXAlignment.Left
		local dLbl = Instance.new("TextLabel", card)
		dLbl.Size = UDim2.new(1, -160, 0, 18)
		dLbl.Position = UDim2.new(0, 56, 0, 28)
		dLbl.BackgroundTransparency = 1
		dLbl.Text = item.description or ""
		dLbl.Font = Enum.Font.Gotham
		dLbl.TextSize = 11
		dLbl.TextColor3 = Color3.fromRGB(140, 100, 80)
		dLbl.TextXAlignment = Enum.TextXAlignment.Left

		if isOwned then
			local placeBtn = Instance.new("TextButton", card)
			placeBtn.Size = UDim2.new(0, 90, 0, 28)
			placeBtn.Position = UDim2.new(1, -98, 0.5, -14)
			placeBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			placeBtn.Text = "Place ▶"
			placeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			placeBtn.Font = Enum.Font.GothamBold
			placeBtn.TextSize = 12
			placeBtn.BorderSizePixel = 0
			Instance.new("UICorner", placeBtn).CornerRadius = UDim.new(0, 6)
			placeBtn.MouseButton1Click:Connect(function()
				gui.Enabled = false
				enterPlacementMode(item)
			end)
		else
			local buyBtn = Instance.new("TextButton", card)
			buyBtn.Size = UDim2.new(0, 90, 0, 28)
			buyBtn.Position = UDim2.new(1, -98, 0.5, -14)
			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 100)
			buyBtn.Text = item.price .. "g Buy"
			buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 12
			buyBtn.BorderSizePixel = 0
			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)
			buyBtn.MouseButton1Click:Connect(function()
				local ok, msg = purchaseRF:InvokeServer(item.id)
				if ok then
					local gold = _G.data and _G.data.gold or 0
					local owned2 = _G.data and _G.data.furniture_unlocked or {}
					table.insert(owned2, item.id)
					renderTab(tabId)
					refreshGold()
				end
			end)
		end
		y = y + 70
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function switchTab(id)
	activeTab = id
	for _, td in ipairs(tabData) do
		local btn = tabBtns[td.id]
		if btn then
			btn.BackgroundColor3 = td.id == id and Color3.fromRGB(200, 180, 100) or Color3.fromRGB(235, 225, 210)
		end
	end
	renderTab(id)
end

for _, td in ipairs(tabData) do
	local btn = Instance.new("TextButton", tabs)
	btn.Size = UDim2.new(0, 130, 1, 0)
	btn.BackgroundColor3 = td.id == "garden" and Color3.fromRGB(200, 180, 100) or Color3.fromRGB(235, 225, 210)
	btn.BorderSizePixel = 0
	btn.Text = td.label
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(80, 40, 30)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	tabBtns[td.id] = btn
	btn.MouseButton1Click:Connect(function() switchTab(td.id) end)
end

local function refreshGold()
	local g = _G.data and _G.data.gold or 0
	goldLbl.Text = "💰 " .. tostring(g)
end

-- Placement mode
local placementGhost = nil
local placementItem = nil
local placementAngle = 0
local placementConn = nil

local function enterPlacementMode(item)
	placementItem = item
	placementAngle = 0
	placementGhost = Instance.new("Part")
	placementGhost.Name = "FurnitureGhost"
	placementGhost.Size = Vector3.new(2, 2, 2)
	placementGhost.Anchored = true
	placementGhost.CanCollide = false
	placementGhost.Transparency = 0.6
	placementGhost.Color = Color3.fromRGB(100, 200, 100)
	placementGhost.Material = Enum.Material.SmoothPlastic
	placementGhost.Parent = workspace
	local bb = Instance.new("BillboardGui", placementGhost)
	bb.Size = UDim2.new(0, 100, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = (item.icon or "📦") .. " " .. item.name .. "\n[Click to place | Scroll to rotate | X to cancel]"
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.3
end

local function exitPlacementMode(placed)
	if placementGhost then placementGhost:Destroy(); placementGhost = nil end
	placementItem = nil
	if placementConn then placementConn:Disconnect(); placementConn = nil end
	if not placed then
		gui.Enabled = true
	end
end

local function doPlace(pos)
	if not placementItem or not pos then return end
	local ok, msg = placeRF:InvokeServer(placementItem.id, pos.X, pos.Y, pos.Z, 0, placementAngle, 0)
	if ok then
		exitPlacementMode(true)
	else
		exitPlacementMode(false)
	end
end

-- Toggle
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.P then
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			refreshGold()
			renderTab(activeTab)
		end
	end
	-- X to cancel placement
	if input.KeyCode == Enum.KeyCode.X and placementItem then
		exitPlacementMode(false)
	end
	-- Scroll to rotate during placement
	if input.UserInputType == Enum.UserInputType.MouseWheel and placementItem then
		placementAngle = (placementAngle + (input.Position.Z > 0 and 15 or -15)) % 360
	end
end)

-- Mouse placement
local mouse = player:GetMouse()
mouse.Move:Connect(function()
	if not placementGhost or not placementItem then return end
	local hit = mouse.Target
	local pos = mouse.Hit.Position
	if hit then
		pos = Vector3.new(math.round(pos.X / 2) * 2, pos.Y, math.round(pos.Z / 2) * 2)
		placementGhost.Position = pos
		placementGhost.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(placementAngle), 0)
	end
end)

local function onPlacementClick()
	if not placementItem or not placementGhost then return end
	doPlace(placementGhost.Position)
end

mouse.Button1Down:Connect(function()
	if placementItem then onPlacementClick() end
end)

-- Manage placed furniture mode (G to toggle)
local manageMode = false
local manageFrame = Instance.new("Frame", gui)
manageFrame.Name = "ManageBar"
manageFrame.Size = UDim2.new(0, 300, 0, 36)
manageFrame.Position = UDim2.new(0.5, -150, 1, -46)
manageFrame.BackgroundColor3 = Color3.fromRGB(30, 24, 40)
manageFrame.BackgroundTransparency = 0.2
manageFrame.BorderSizePixel = 0
manageFrame.Visible = false
Instance.new("UICorner", manageFrame).CornerRadius = UDim.new(0, 10)
local mLabel = Instance.new("TextLabel", manageFrame)
mLabel.Size = UDim2.new(1, -10, 1, 0)
mLabel.Position = UDim2.new(0, 10, 0, 0)
mLabel.BackgroundTransparency = 1
mLabel.Text = "Manage mode: Click a placed item to remove it. Press G to toggle."
mLabel.Font = Enum.Font.Gotham
mLabel.TextSize = 12
mLabel.TextColor3 = Color3.fromRGB(240, 230, 255)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.G and not placementItem then
		manageMode = not manageMode
		manageFrame.Visible = manageMode
	end
end)

mouse.Button1Down:Connect(function()
	if not manageMode then return end
	local hit = mouse.Target
	if not hit then return end
	-- Check if clicking on a placed furniture mesh
	local model = hit.Parent
	if model and model:GetAttribute("FurnitureIndex") then
		local idx = model:GetAttribute("FurnitureIndex")
		local ok, msg = removeRF:InvokeServer(idx)
		if ok then
			model:Destroy()
		end
	end
end)

-- Place all owned furniture on join
local function restorePlacedFurniture()
	task.wait(5)
	local getRF = RF:FindFirstChild("GetPlacedFurniture")
	if not getRF then return end
	local placements = getRF:InvokeServer()
	if not placements then return end
	for _, p in ipairs(placements) do
		local item = nil
		for _, i in ipairs(allItems) do if i.id == p.itemId then item = i; break end end
		if item and item.meshId and item.meshId ~= "" and not item.meshId:find("FILL_") then
			local numericId = tonumber(string.match(item.meshId, "%d+"))
			if numericId then
				local mesh = Instance.new("MeshPart")
				mesh.Name = "Placed_" .. p.itemId
				mesh.MeshId = "rbxassetid://" .. numericId
				mesh.Size = Vector3.new(2, 2, 2)
				mesh.Anchored = true
				mesh.CanCollide = false
				mesh.Position = Vector3.new(p.x, p.y, p.z)
				mesh.CFrame = CFrame.new(p.x, p.y, p.z) * CFrame.Angles(math.rad(p.rx or 0), math.rad(p.ry or 0), math.rad(p.rz or 0))
				mesh.Parent = workspace
				mesh:SetAttribute("FurnitureIndex", p._index or #placements)
			end
		end
	end
end
task.spawn(restorePlacedFurniture)

print("[FurniturePlacement] Ready — press P for shop, G for manage mode")
