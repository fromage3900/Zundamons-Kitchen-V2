local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Tween   = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local player  = Players.LocalPlayer
local gui     = script.Parent

local UIHelper = require(RS.Shared.Modules.UIHelper)
local craftConfig = require(RS.ConfigurationFiles.CraftConfig)

local C = {
	bg        = Color3.fromRGB(255, 248, 235),
	border    = Color3.fromRGB(180, 150, 110),
	text      = Color3.fromRGB(80,  55,  35),
	sub       = Color3.fromRGB(140, 110, 80),
	tabAct    = Color3.fromRGB(180, 150, 110),
	tabIdle   = Color3.fromRGB(240, 230, 215),
	card      = Color3.fromRGB(250, 242, 228),
	searchBg  = Color3.fromRGB(245, 238, 222),
	owned     = Color3.fromRGB(160, 210, 150),
}

local ALL_ITEMS = {
	{ name="Apple",        cat="Forage", price=5   },
	{ name="Wheat",        cat="Forage", price=10  },
	{ name="WheatSeed",    cat="Forage", price=1   },
	{ name="Pine Cone",    cat="Forage", price=5   },
	{ name="Zunda Flower", cat="Forage", price=12  },
	{ name="Zunda Pea",    cat="Forage", price=18  },
	{ name="Zunda Berry",  cat="Forage", price=20  },
	{ name="Zunda Mushroom",cat="Forage",price=25  },
	{ name="Zunda Root",   cat="Forage", price=22  },
	{ name="Zunda Leaf",   cat="Forage", price=8   },
	{ name="Sweet Pea",    cat="Forage", price=15  },
	{ name="Pea Flower",   cat="Forage", price=10  },
	{ name="Edamame Pod",  cat="Forage", price=14  },
	{ name="Rock",         cat="Mining", price=10  },
	{ name="Iron Ore",     cat="Mining", price=8   },
	{ name="Gold Ore",     cat="Mining", price=30  },
	{ name="Gold",         cat="Mining", price=30  },
	{ name="Marble Rock",  cat="Mining", price=15  },
	{ name="Wood Log",     cat="Mining", price=20  },
}

local ALL_RECIPES = {}
for name, ing in pairs(craftConfig.recipes) do
	local ingList = {}
	for item, amt in pairs(ing) do
		table.insert(ingList, amt .. "x " .. item)
	end
	local goldVal = 0
	for _, item in ipairs(ingList) do
		local num = tonumber(item:match("%d+"))
		if num then goldVal = goldVal + num * 3 end
	end
	table.insert(ALL_RECIPES, { name = name, ing = ing, gold = math.max(goldVal + 20, 40) })
end
table.sort(ALL_RECIPES, function(a, b) return a.name < b.name end)

local ZONES_INFO = {
	{emoji="🏘", name="Zunda Village",   desc="Spawn area with town shops & NPC guests.",       pos="(47, 4, -74)"},
	{emoji="🍳", name="Kitchen Garden",  desc="Farming, cooking & the main gameplay loop.",     pos="(9, 4, -41)" },
	{emoji="🗻", name="Eastern Peaks",   desc="Elevated highlands near the east pyramid.",      pos="(130, 23, 73)"},
	{emoji="✨", name="Mystic Heights",  desc="High cliffs with the best stargazing spot!",     pos="(149, 35, -195)"},
	{emoji="⛩", name="Hilltop Shrine",  desc="Ancient shrine atop the eastern hill.",          pos="(85, 30, 120)" },
	{emoji="🏛", name="Ancient Ruins",   desc="Northwestern ruins with mysterious energy.",     pos="(-20, 12, -150)"},
}

local function getPlayerOwned()
	local ok, data = pcall(function()
		return RS:WaitForChild("RemoteFunctions"):WaitForChild("RequestData"):InvokeServer()
	end)
	if ok and data then return data end
	return {}
end

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"; panel.Size = UDim2.new(0, 600, 0, 580)
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = C.bg; panel.BorderSizePixel = 0; panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 24)
local bst = Instance.new("UIStroke", panel); bst.Thickness = 3; bst.Color = C.border

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -80, 0, 52); title.Position = UDim2.new(0, 18, 0, 12)
title.BackgroundTransparency = 1; title.Text = "📚  Compendium"
title.Font = Enum.Font.FredokaOne; title.TextSize = 30
title.TextColor3 = C.text; title.TextXAlignment = Enum.TextXAlignment.Left

local progressBar = Instance.new("Frame", panel)
progressBar.Size = UDim2.new(0.3, 0, 0, 6); progressBar.Position = UDim2.new(0, 18, 0, 62)
progressBar.BackgroundColor3 = Color3.fromRGB(230, 220, 205); progressBar.BorderSizePixel = 0
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0.5, 0)
local progFill = Instance.new("Frame", progressBar)
progFill.Size = UDim2.new(0, 0, 1, 0); progFill.BackgroundColor3 = C.owned; progFill.BorderSizePixel = 0
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0.5, 0)
local progLabel = Instance.new("TextLabel", panel)
progLabel.Size = UDim2.new(0.3, 0, 0, 16); progLabel.Position = UDim2.new(0, 18, 0, 70)
progLabel.BackgroundTransparency = 1; progLabel.Text = "Loading..."
progLabel.Font = Enum.Font.Gotham; progLabel.TextSize = 11; progLabel.TextColor3 = C.sub
progLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 40, 0, 40); closeBtn.Position = UDim2.new(1, -54, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 120); closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.FredokaOne; closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

local searchBox = Instance.new("TextBox", panel)
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(0.48, 0, 0, 34); searchBox.Position = UDim2.new(0, 16, 0, 96)
searchBox.BackgroundColor3 = C.searchBg; searchBox.BorderSizePixel = 0
searchBox.PlaceholderText = "🔍  Search items, recipes..."
searchBox.PlaceholderColor3 = C.sub; searchBox.Text = ""
searchBox.TextColor3 = C.text; searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 14
searchBox.ClearTextOnFocus = false
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 10)

local tabBar = Instance.new("Frame", panel)
tabBar.Size = UDim2.new(0.48, -8, 0, 34); tabBar.Position = UDim2.new(0.52, 8, 0, 96)
tabBar.BackgroundTransparency = 1; tabBar.BorderSizePixel = 0
local tbl = Instance.new("UIListLayout", tabBar)
tbl.FillDirection = Enum.FillDirection.Horizontal; tbl.Padding = UDim.new(0, 6); tbl.VerticalAlignment = Enum.VerticalAlignment.Center

local function mkTab(name, lbl, order)
	local b = Instance.new("TextButton", tabBar)
	b.Name = "Tab_" .. name; b.Size = UDim2.new(0, 90, 1, 0); b.LayoutOrder = order
	b.BackgroundColor3 = order == 1 and C.tabAct or C.tabIdle
	b.Text = lbl; b.Font = Enum.Font.FredokaOne; b.TextSize = 14
	b.TextColor3 = order == 1 and Color3.fromRGB(255, 255, 255) or C.text
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end
local tabRecipes = mkTab("recipes", "🍳  Recipes", 1)
local tabItems = mkTab("items", "📦  Items", 2)
local tabZones = mkTab("zones", "🗺  Zones", 3)

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "Content"; scroll.Size = UDim2.new(1, -32, 0, 410)
scroll.Position = UDim2.new(0, 16, 0, 142); scroll.BackgroundColor3 = Color3.fromRGB(248, 240, 230)
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = C.border; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 14)
local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0, 8); ll.SortOrder = Enum.SortOrder.LayoutOrder
local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)

local function clearScroll()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end
	scroll.CanvasPosition = Vector2.new(0, 0)
end

local function buildRecipeCard(r, idx, owned)
	local card = Instance.new("Frame", scroll)
	card.Name = "R_" .. idx; card.Size = UDim2.new(1, 0, 0, 84)
	card.LayoutOrder = idx; card.BackgroundColor3 = C.card; card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	local cs = Instance.new("UIStroke", card); cs.Thickness = 1
	cs.Color = Color3.fromRGB(195, 175, 150)

	local icon = UIHelper.createItemIcon(r.name, UDim2.fromOffset(48, 48), card)
	icon.Position = UDim2.new(0, 10, 0.5, -24)
	icon.BackgroundColor3 = Color3.fromRGB(240, 232, 218)
	icon.BackgroundTransparency = 0
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)

	local nm = Instance.new("TextLabel", card)
	nm.Size = UDim2.new(1, -170, 0, 24); nm.Position = UDim2.new(0, 68, 0, 10)
	nm.BackgroundTransparency = 1; nm.Text = r.name
	nm.Font = Enum.Font.FredokaOne; nm.TextSize = 16
	nm.TextColor3 = C.text; nm.TextXAlignment = Enum.TextXAlignment.Left

	local ingParts = {}
	for item, amt in pairs(r.ing) do
		table.insert(ingParts, amt .. "x " .. item)
	end
	local ingLbl = Instance.new("TextLabel", card)
	ingLbl.Size = UDim2.new(1, -170, 0, 38); ingLbl.Position = UDim2.new(0, 68, 0, 34)
	ingLbl.BackgroundTransparency = 1
	ingLbl.Text = "Needs: " .. table.concat(ingParts, ", ")
	ingLbl.Font = Enum.Font.Gotham; ingLbl.TextSize = 12
	ingLbl.TextColor3 = C.sub; ingLbl.TextXAlignment = Enum.TextXAlignment.Left
	ingLbl.TextWrapped = true

	local badge = Instance.new("Frame", card)
	badge.Size = UDim2.new(0, 68, 0, 28); badge.Position = UDim2.new(1, -76, 0, 12)
	badge.BackgroundColor3 = Color3.fromRGB(255, 242, 180); badge.BorderSizePixel = 0
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", badge).Color = Color3.fromRGB(220, 180, 50)
	local bLbl = Instance.new("TextLabel", badge)
	bLbl.Size = UDim2.new(1, 0, 1, 0); bLbl.BackgroundTransparency = 1
	bLbl.Text = "💰 " .. r.gold; bLbl.Font = Enum.Font.FredokaOne
	bLbl.TextSize = 14; bLbl.TextColor3 = Color3.fromRGB(150, 110, 20)

	if owned then
		local ownedBadge = Instance.new("Frame", card)
		ownedBadge.Size = UDim2.new(0, 60, 0, 22); ownedBadge.Position = UDim2.new(1, -68, 0, 48)
		ownedBadge.BackgroundColor3 = C.owned; ownedBadge.BorderSizePixel = 0
		Instance.new("UICorner", ownedBadge).CornerRadius = UDim.new(0, 6)
		local oLbl = Instance.new("TextLabel", ownedBadge)
		oLbl.Size = UDim2.new(1, 0, 1, 0); oLbl.BackgroundTransparency = 1
		oLbl.Text = "✅ " .. owned; oLbl.Font = Enum.Font.GothamBold
		oLbl.TextSize = 11; oLbl.TextColor3 = Color3.fromRGB(50, 110, 50)
	end
end

local function buildItemCard(item, idx)
	local catColor = UIHelper.getItemColor(item.name)
	local card = Instance.new("Frame", scroll)
	card.Name = "I_" .. idx; card.Size = UDim2.new(1, 0, 0, 56)
	card.LayoutOrder = idx
	card.BackgroundColor3 = catColor:Lerp(Color3.fromRGB(255, 255, 255), 0.82)
	card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

	local icon = UIHelper.createItemIcon(item.name, UDim2.fromOffset(36, 36), card)
	icon.Position = UDim2.new(0, 8, 0.5, -18)
	icon.BackgroundTransparency = 1

	local nm = Instance.new("TextLabel", card)
	nm.Size = UDim2.new(0, 200, 0, 24); nm.Position = UDim2.new(0, 50, 0, 8)
	nm.BackgroundTransparency = 1; nm.Text = item.name
	nm.Font = Enum.Font.FredokaOne; nm.TextSize = 15
	nm.TextColor3 = C.text; nm.TextXAlignment = Enum.TextXAlignment.Left

	local cat = Instance.new("TextLabel", card)
	cat.Size = UDim2.new(0, 100, 0, 16); cat.Position = UDim2.new(0, 50, 0, 32)
	cat.BackgroundTransparency = 1; cat.Text = item.cat
	cat.Font = Enum.Font.Gotham; cat.TextSize = 11
	cat.TextColor3 = C.sub; cat.TextXAlignment = Enum.TextXAlignment.Left

	local priceLbl = Instance.new("TextLabel", card)
	priceLbl.Size = UDim2.new(0, 80, 1, 0); priceLbl.Position = UDim2.new(1, -88, 0, 0)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Text = "💰 " .. item.price .. "g"
	priceLbl.Font = Enum.Font.FredokaOne; priceLbl.TextSize = 14
	priceLbl.TextColor3 = Color3.fromRGB(160, 120, 30)
	priceLbl.TextXAlignment = Enum.TextXAlignment.Right

	local catColor2 = UIHelper.getItemColor(item.name)
	local countLbl = Instance.new("TextLabel", card)
	countLbl.Size = UDim2.new(0, 60, 1, 0); countLbl.Position = UDim2.new(1, -150, 0, 0)
	countLbl.BackgroundTransparency = 1
	countLbl.Text = "0x"; countLbl.Font = Enum.Font.GothamBold
	countLbl.TextSize = 13; countLbl.TextColor3 = catColor2
	countLbl.TextXAlignment = Enum.TextXAlignment.Right
	return countLbl
end

local function buildZoneCard(z, idx)
	local card = Instance.new("Frame", scroll)
	card.Name = "Z_" .. idx; card.Size = UDim2.new(1, 0, 0, 76)
	card.LayoutOrder = idx; card.BackgroundColor3 = C.card; card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	local cs = Instance.new("UIStroke", card); cs.Thickness = 1.5; cs.Color = C.border

	local em = Instance.new("TextLabel", card)
	em.Size = UDim2.new(0, 52, 0, 52); em.Position = UDim2.new(0, 10, 0.5, -26)
	em.BackgroundColor3 = Color3.fromRGB(235, 225, 210); em.Text = z.emoji
	em.Font = Enum.Font.GothamBold; em.TextSize = 28
	em.TextXAlignment = Enum.TextXAlignment.Center; em.BorderSizePixel = 0
	Instance.new("UICorner", em).CornerRadius = UDim.new(0, 10)

	local nm = Instance.new("TextLabel", card)
	nm.Size = UDim2.new(1, -180, 0, 22); nm.Position = UDim2.new(0, 70, 0, 10)
	nm.BackgroundTransparency = 1; nm.Text = z.name
	nm.Font = Enum.Font.FredokaOne; nm.TextSize = 16
	nm.TextColor3 = C.text; nm.TextXAlignment = Enum.TextXAlignment.Left

	local desc = Instance.new("TextLabel", card)
	desc.Size = UDim2.new(1, -100, 0, 30); desc.Position = UDim2.new(0, 70, 0, 34)
	desc.BackgroundTransparency = 1; desc.Text = z.desc
	desc.Font = Enum.Font.Gotham; desc.TextSize = 12
	desc.TextColor3 = C.sub; desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true

	local pos = Instance.new("TextLabel", card)
	pos.Size = UDim2.new(0, 100, 1, 0); pos.Position = UDim2.new(1, -110, 0, 0)
	pos.BackgroundTransparency = 1; pos.Text = z.pos
	pos.Font = Enum.Font.Code; pos.TextSize = 11
	pos.TextColor3 = Color3.fromRGB(160, 150, 140); pos.TextXAlignment = Enum.TextXAlignment.Right
end

local activeTab = "recipes"
local function render(id)
	activeTab = id
	for _, btn in ipairs({tabRecipes, tabItems, tabZones}) do
		local isActive = btn.Name == "Tab_" .. id
		btn.BackgroundColor3 = isActive and C.tabAct or C.tabIdle
		btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or C.text
	end
	clearScroll()

	local data = getPlayerOwned()
	local ownedCount, totalCount = 0, 0

	if id == "recipes" then
		local filtered = ALL_RECIPES
		local q = searchBox.Text:lower():gsub("%s+", "")
		if q ~= "" then
			filtered = {}
			for _, r in ipairs(ALL_RECIPES) do
				if r.name:lower():find(q, 1, true) then
					table.insert(filtered, r)
				end
			end
		end
		for i, r in ipairs(filtered) do
			local count = data[r.name] or 0
			local owned = count > 0 and tostring(count) or nil
			buildRecipeCard(r, i, owned)
			totalCount = totalCount + 1
			if count > 0 then ownedCount = ownedCount + 1 end
		end
	elseif id == "items" then
		local filtered = ALL_ITEMS
		local q = searchBox.Text:lower():gsub("%s+", "")
		if q ~= "" then
			filtered = {}
			for _, it in ipairs(ALL_ITEMS) do
				if it.name:lower():find(q, 1, true) or it.cat:lower():find(q, 1, true) then
					table.insert(filtered, it)
				end
			end
		end
		for i, item in ipairs(filtered) do
			local countLbl = buildItemCard(item, i)
			local count = data[item.name] or 0
			if item.name == "Gold" then count = data.gold or 0 end
			countLbl.Text = count .. "x"
			totalCount = totalCount + 1
			if count > 0 then ownedCount = ownedCount + 1 end
		end
	elseif id == "zones" then
		for i, z in ipairs(ZONES_INFO) do
			buildZoneCard(z, i)
			totalCount = totalCount + 1
			local zones = data.zones_visited or {}
			local zoneKey = z.name:gsub("%s+", ""):lower():sub(1, 6)
			local visited = false
			-- check each zone ID
			for _, id2 in ipairs({"village", "kitchen", "eastpeaks", "mystic", "hilltop", "ruins"}) do
				if zones[id2] then visited = true end
			end
			if visited then ownedCount = ownedCount + 1 end
		end
	end

	if totalCount > 0 then
		local pct = math.floor(ownedCount / totalCount * 100)
		progFill:TweenSize(UDim2.new(pct / 100, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		progLabel.Text = "📊  " .. ownedCount .. " / " .. totalCount .. " discovered (" .. pct .. "%)"
	end
end

local searchDebounce
searchBox.FocusLost:Connect(function()
	if searchDebounce then searchDebounce:Cancel() end
	searchDebounce = task.delay(0.15, function() render(activeTab) end)
end)
searchBox.Changed:Connect(function(prop)
	if prop == "Text" and searchDebounce then
		searchDebounce:Cancel()
		searchDebounce = task.delay(0.2, function() render(activeTab) end)
	end
end)

tabRecipes.MouseButton1Click:Connect(function() render("recipes") end)
tabItems.MouseButton1Click:Connect(function() render("items") end)
tabZones.MouseButton1Click:Connect(function() render("zones") end)

local open = false
local function toggle()
	open = not open
	panel.Visible = open
	if open then
		render("recipes")
		panel.Size = UDim2.new(0, 600, 0, 10)
		Tween:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 600, 0, 580) }):Play()
	end
	UIHelper.spawnSparkles(panel, panel.AbsolutePosition.X + 300, panel.AbsolutePosition.Y + 40,
		Color3.fromRGB(180, 150, 110), 6)
end
closeBtn.MouseButton1Click:Connect(function() open = true; toggle() end)

task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local hud = pg:WaitForChild("ZundaHUD", 15)
	if hud then
		local bar = hud:WaitForChild("HudButtons", 8)
		if bar then
			local btn = bar:FindFirstChild("HudBtn_compendium")
			if btn then btn.MouseButton1Click:Connect(toggle) end
		end
	end
end)

UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.C then toggle() end
end)

print("[Compendium v2] AC style, search bar, owned tracking, dynamic data")
