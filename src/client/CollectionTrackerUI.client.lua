-- [[LocalScript] CollectionTrackerUI]
-- Pea Wheel panel showing completion stats for companions, achievements,
-- recipes, and biomes. Reads from a server snapshot; totals are authoritative
-- config values so the UI stays in sync as content is added.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local player = Players.LocalPlayer

local gui = require(RS.ConfigurationFiles.ClientGuiBootstrap).createScreenGui(player, "CollectionTrackerGui", 28)
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local CollectionConfig = require(RS.ConfigurationFiles.CollectionConfig)
local CozyModalShell = require(RS.ConfigurationFiles.CozyModalShell)
local UIRouter = require(RS.ConfigurationFiles.UIRouter)
local ActionRegistry =
	require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")
local snapshotEvent = RE:WaitForChild("CollectionSnapshot")
local getSnapshot = RF:WaitForChild("GetCollectionSnapshot")

local FONTS = UIConfig.FONTS

-- Infinity Nikki pastel palette
local C = {
	bg = Color3.fromRGB(255, 248, 240),
	border = Color3.fromRGB(160, 210, 150),
	text = Color3.fromRGB(80, 80, 80),
	sub = Color3.fromRGB(120, 120, 120),
	barBg = Color3.fromRGB(230, 225, 215),
}

local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 460, 0, 520)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Visible = false
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 22)
local bst = Instance.new("UIStroke", panel)
bst.Thickness = 3
bst.Color = C.border

local hdr = Instance.new("TextLabel", panel)
hdr.Name = "Header"
hdr.Size = UDim2.new(1, -70, 0, 52)
hdr.Position = UDim2.new(0, 18, 0, 12)
hdr.BackgroundTransparency = 1
hdr.Text = "📚  Collection"
hdr.Font = FONTS.Title
hdr.TextSize = 28
hdr.TextColor3 = C.text
hdr.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", panel)
sub.Name = "Subtitle"
sub.Size = UDim2.new(1, -36, 0, 18)
sub.Position = UDim2.new(0, 18, 0, 58)
sub.BackgroundTransparency = 1
sub.Text = "Track everything you've discovered so far ✨"
sub.Font = FONTS.Body
sub.TextSize = 13
sub.TextColor3 = C.sub
sub.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -52, 0, 14)
closeBtn.BackgroundColor3 = C.border
closeBtn.Text = "✕"
closeBtn.Font = FONTS.Heading
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "CategoryList"
scroll.Size = UDim2.new(1, -32, 0, 428)
scroll.Position = UDim2.new(0, 16, 0, 82)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.border
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0, 12)

local cards = {}

local function buildCard(category)
	local card = Instance.new("Frame", scroll)
	card.Name = "Card_" .. category.id
	card.Size = UDim2.new(1, 0, 0, 86)
	card.BackgroundColor3 = Color3.fromRGB(252, 250, 245)
	card.BorderSizePixel = 0
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

	local accent = Instance.new("Frame", card)
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 6, 1, -16)
	accent.Position = UDim2.new(0, 8, 0, 8)
	accent.BackgroundColor3 = category.color
	accent.BorderSizePixel = 0
	Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("TextLabel", card)
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 22, 0, 12)
	icon.BackgroundTransparency = 1
	icon.Text = category.icon
	icon.Font = FONTS.Body
	icon.TextSize = 28
	icon.TextColor3 = C.text

	local title = Instance.new("TextLabel", card)
	title.Name = "Title"
	title.Size = UDim2.new(1, -90, 0, 22)
	title.Position = UDim2.new(0, 70, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = category.label
	title.Font = FONTS.Heading
	title.TextSize = 18
	title.TextColor3 = C.text
	title.TextXAlignment = Enum.TextXAlignment.Left

	local count = Instance.new("TextLabel", card)
	count.Name = "Count"
	count.Size = UDim2.new(0, 70, 0, 22)
	count.Position = UDim2.new(1, -78, 0, 10)
	count.BackgroundTransparency = 1
	count.Text = "0 / 0"
	count.Font = FONTS.Heading
	count.TextSize = 16
	count.TextColor3 = C.text
	count.TextXAlignment = Enum.TextXAlignment.Right

	local barBg = Instance.new("Frame", card)
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -86, 0, 12)
	barBg.Position = UDim2.new(0, 70, 0, 40)
	barBg.BackgroundColor3 = C.barBg
	barBg.BorderSizePixel = 0
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", barBg)
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = category.color
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local pct = Instance.new("TextLabel", card)
	pct.Name = "Percent"
	pct.Size = UDim2.new(1, -86, 0, 18)
	pct.Position = UDim2.new(0, 70, 0, 56)
	pct.BackgroundTransparency = 1
	pct.Text = "0% complete"
	pct.Font = FONTS.Body
	pct.TextSize = 13
	pct.TextColor3 = C.sub
	pct.TextXAlignment = Enum.TextXAlignment.Left

	return {
		card = card,
		count = count,
		fill = fill,
		pct = pct,
	}
end

for _, category in ipairs(CollectionConfig.categories) do
	cards[category.id] = buildCard(category)
end

local function updatePanel(snapshot)
	if not snapshot then
		return
	end
	local counts = snapshot.counts or {}
	local totals = snapshot.totals or {}

	for _, category in ipairs(CollectionConfig.categories) do
		local w = cards[category.id]
		if w then
			local current = counts[category.id] or 0
			local total = totals[category.id] or 1
			w.count.Text = current .. " / " .. total
			local ratio = math.clamp(current / total, 0, 1)
			Tween:Create(w.fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(ratio, 0, 1, 0),
			}):Play()
			w.pct.Text = math.floor(ratio * 100 + 0.5) .. "% complete"
		end
	end
end

local function refresh()
	local ok, snapshot = pcall(function()
		return getSnapshot:InvokeServer()
	end)
	if ok and snapshot then
		updatePanel(snapshot)
	end
end

snapshotEvent.OnClientEvent:Connect(updatePanel)
task.spawn(refresh)

local open = false
local shell = CozyModalShell.wrap(panel, {
	actionId = "collection",
	open = function()
		panel.Size = UDim2.new(0, 460, 0, 10)
		Tween:Create(
			panel,
			TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 460, 0, 520) }
		):Play()
		refresh()
	end,
	close = function()
		panel.Visible = false
		open = false
	end,
})

local function toggle()
	if open then
		UIRouter.close("collection")
		open = false
	else
		UIRouter.open("collection")
		open = true
		shell.open()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	UIRouter.close("collection")
	open = false
	shell.close()
	local pos = closeBtn.AbsolutePosition
	UIHelper.spawnSparkles(panel, pos.X + 19, pos.Y + 19, Color3.fromRGB(255, 255, 255), 6)
end)

UIRouter.register("collection", nil, function()
	shell.close()
end)

ActionRegistry.registerCallback("collection", toggle)

print("[CollectionTrackerUI] Ready")
