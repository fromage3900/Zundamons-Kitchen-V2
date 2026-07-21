local UIAssets = require(script.Parent.Parent.Config.UIAssets)
local UIConfig = require(game.ReplicatedStorage.ConfigurationFiles.UIConfig)

local UIHelper = {}

local function norm(name: string): string
	return name:gsub("%s+", "")
end

local FALLBACK_EMOJI = {
	Wheat = "🌾", ZundaFlower = "🌸", ZundaPea = "🫛",
	ZundaBerry = "🫐", ZundaMushroom = "🍄", ZundaRoot = "🌱",
	Apple = "🍎", Bread = "🍞", Cupcake = "🧁",
	ApplePie = "🥧", ZundaBread = "🫓", ZundaMochi = "🍡",
	RoyalStew = "🍲", Bouquet = "💐", CopperOre = "🪨",
	GoldOre = "💛", Rock = "🪨", Wood = "🪵",
	IronOre = "🔩", MarbleRock = "🔷", PineCone = "🌲",
	WheatSeed = "🫘", EdamamePod = "🫛", SweetPea = "🍬",
	PeaFlower = "🌸", EdamameSnack = "🫛", SweetPeaCake = "🍰",
	PeaFlowerTea = "🍵", ZundaParadise = "✨", Stew = "🍲",
	Cake = "🎂", SaltedPeaBouquet = "💐", MysteryLoot = "✨",
	ZundaLeaf = "🌿",
	["Zunda Flower"] = "🌸", ["Zunda Pea"] = "🫛",
	["Zunda Berry"] = "🫐", ["Zunda Mushroom"] = "🍄",
	["Zunda Root"] = "🌱", ["Apple Pie"] = "🥧",
	["Zunda Bread"] = "🫓", ["Zunda Mochi"] = "🍡",
	["Royal Stew"] = "🍲", ["Pine Cone"] = "🌲",
	["Wheat Seed"] = "🫘", ["Gold Ore"] = "💛",
	["Copper Ore"] = "🪨", ["Iron Ore"] = "🔩",
	["Marble Rock"] = "🔷", ["Wood Log"] = "🪵",
	["Zunda Leaf"] = "🌿",
}

local FALLBACK_COLORS = {
	forage = Color3.fromRGB(100, 200, 80),
	mining = Color3.fromRGB(180, 170, 160),
	food = Color3.fromRGB(240, 200, 140),
	misc = Color3.fromRGB(200, 200, 200),
}

local function isPlaceholder(id: string): boolean
	return typeof(id) == "string" and (id:match("FILL_") ~= nil or id:match("rbxassetid://0$") ~= nil)
end

function UIHelper.getItemIcon(itemName: string): (string?, string?)
	local iconId = UIAssets.icons[itemName]
	if iconId and not isPlaceholder(iconId) then
		return iconId, nil
	end
	for _, id in pairs(UIAssets.icons) do
		if typeof(id) == "string" and not isPlaceholder(id) then
			return id, nil
		end
	end
	return nil, FALLBACK_EMOJI[itemName] or FALLBACK_EMOJI[norm(itemName)] or "📦"
end

function UIHelper.getItemColor(itemName: string, category: string?): Color3
	local iconColor = {
		Wheat = Color3.fromRGB(255, 215, 0),
		ZundaFlower = Color3.fromRGB(200, 120, 255),
		ZundaPea = Color3.fromRGB(120, 200, 80),
		ZundaBerry = Color3.fromRGB(200, 50, 80),
		ZundaMushroom = Color3.fromRGB(180, 100, 60),
		ZundaRoot = Color3.fromRGB(160, 120, 80),
		Apple = Color3.fromRGB(255, 50, 50),
		Bread = Color3.fromRGB(220, 180, 120),
		Cupcake = Color3.fromRGB(255, 180, 200),
		ApplePie = Color3.fromRGB(200, 120, 60),
		ZundaBread = Color3.fromRGB(180, 220, 100),
		ZundaMochi = Color3.fromRGB(150, 200, 150),
		RoyalStew = Color3.fromRGB(200, 150, 50),
		Bouquet = Color3.fromRGB(180, 200, 255),
		CopperOre = Color3.fromRGB(180, 120, 60),
		GoldOre = Color3.fromRGB(255, 215, 0),
		Rock = Color3.fromRGB(180, 170, 160),
		Wood = Color3.fromRGB(160, 110, 70),
		IronOre = Color3.fromRGB(150, 140, 130),
		MarbleRock = Color3.fromRGB(200, 220, 240),
		PineCone = Color3.fromRGB(100, 150, 80),
	}
	return iconColor[itemName] or iconColor[norm(itemName)] or FALLBACK_COLORS[category or "misc"]
end

function UIHelper.createItemIcon(itemName: string, size: UDim2?, parent: Instance?): GuiObject
	local iconId, fallbackEmoji = UIHelper.getItemIcon(itemName)
	local sz = size or UDim2.fromOffset(48, 48)

	if iconId then
		local img = Instance.new("ImageLabel")
		img.Size = sz
		img.Image = iconId
		img.BackgroundTransparency = 1
		img.BorderSizePixel = 0
		img.ScaleType = Enum.ScaleType.Fit
		if parent then img.Parent = parent end
		return img
	end

	local label = Instance.new("TextLabel")
	label.Size = sz
	label.BackgroundTransparency = 1
	label.Text = fallbackEmoji or "📦"
	label.Font = Enum.Font.GothamBold
	label.TextSize = math.min(sz.X.Offset or 48, 48) * 0.6
	label.TextColor3 = UIConfig.COLORS.TextPrimary
	label.BorderSizePixel = 0
	if parent then label.Parent = parent end
	return label
end

function UIHelper:getCategory(itemName: string): string
	local catMap = {
		ZundaFlower = "forage", ZundaPea = "forage", ZundaBerry = "forage",
		ZundaMushroom = "forage", ZundaRoot = "forage", Apple = "forage",
		Wheat = "forage", PineCone = "forage", ZundaLeaf = "forage",
		EdamamePod = "forage", SweetPea = "forage", PeaFlower = "forage",
		Bouquet = "forage", MysteryLoot = "forage",
		Rock = "mining", IronOre = "mining", GoldOre = "mining",
		MarbleRock = "mining", Wood = "mining",
		Bread = "food", ApplePie = "food", ZundaBread = "food",
		ZundaMochi = "food", RoyalStew = "food", Cake = "food",
		Cupcake = "food", Stew = "food", EdamameSnack = "food",
		SweetPeaCake = "food", PeaFlowerTea = "food", ZundaParadise = "food",
		SaltedPeaBouquet = "food",
	}
	return catMap[itemName] or catMap[norm(itemName)] or "misc"
end

function UIHelper.createCard(name: string, count: number, category: string?, parent: Instance?): Frame
	local cat = category or UIHelper.getCategory(name)
	local color = UIHelper.getItemColor(name, cat)
	local card = Instance.new("Frame")
	card.Name = name
	card.Size = UDim2.fromOffset(118, 108)
	card.BackgroundColor3 = color:Lerp(Color3.fromRGB(255, 255, 255), 0.72)
	card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = color:Lerp(Color3.fromRGB(180, 160, 180), 0.3)
	stroke.Parent = card

	local icon = UIHelper.createItemIcon(name, UDim2.fromOffset(48, 48), card)
	icon.Position = UDim2.new(0.5, -24, 0, 8)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -8, 0, 28)
	nameLbl.Position = UDim2.new(0, 4, 0, 58)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.Font = Enum.Font.GothamMedium
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.fromRGB(68, 52, 78)
	nameLbl.TextWrapped = true
	nameLbl.TextXAlignment = Enum.TextXAlignment.Center
	nameLbl.Parent = card

	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(32, 22)
	badge.Position = UDim2.new(1, -34, 0, 4)
	badge.BackgroundColor3 = color
	badge.BorderSizePixel = 0
	badge.Parent = card
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size = UDim2.new(1, 0, 1, 0)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text = tostring(count)
	badgeLbl.Font = Enum.Font.GothamBold
	badgeLbl.TextSize = 13
	badgeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeLbl.Parent = badge

	if parent then card.Parent = parent end
	return card
end

function UIHelper.spawnSparkles(parent: Instance, x: number, y: number, color: Color3?, count: number?)
	local TweenS = game:GetService("TweenService")
	count = count or 8
	local sparkleChars = {"✨", "⭐", "💫", "🌸", "🍃"}
	for i = 1, count do
		local s = Instance.new("TextLabel", parent)
		s.Size = UDim2.fromOffset(16, 16)
		s.Position = UDim2.new(0, x - 8, 0, y - 8)
		s.BackgroundTransparency = 1
		s.Text = sparkleChars[math.random(1, #sparkleChars)]
		s.Font = Enum.Font.GothamBold
		s.TextScaled = true
		s.TextColor3 = color or Color3.fromRGB(255, 220, 100)
		s.ZIndex = 100
		local angle = math.random() * math.pi * 2
		local dist = math.random(30, 80)
		local tx = x + math.cos(angle) * dist - 8
		local ty = y + math.sin(angle) * dist - 8
		TweenS:Create(s, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, tx, 0, ty),
			TextTransparency = 1,
			Rotation = math.random(-180, 180),
		}):Play()
		game:GetService("Debris"):AddItem(s, 1)
	end
end

function UIHelper.wireSparkleOnClick(button: TextButton, color: Color3?)
	button.MouseButton1Click:Connect(function()
		local absPos = button.AbsolutePosition
		local size = button.AbsoluteSize
		UIHelper.spawnSparkles(button.Parent, absPos.X + size.X / 2, absPos.Y + size.Y / 2, color)
	end)
end

return UIHelper
