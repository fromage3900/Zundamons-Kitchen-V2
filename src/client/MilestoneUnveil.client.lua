-- [[LocalScript] MilestoneUnveil]
-- Dramatic full-screen card reveals for first-time recipe, achievement, and
-- collection unlocks. Listens to existing events; auto-dismisses and queues.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local UIHelper = require(RS.Shared.Modules.UIHelper)
local CollectionConfig = require(RS.ConfigurationFiles.CollectionConfig)
local FONTS = UIConfig.FONTS

local gui = ClientGuiBootstrap.createScreenGui(player, "MilestoneUnveilGui", 100)

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 1
overlay.Parent = gui

local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 420, 0, 260)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.new(0.5, 0, 0.5, 0)
card.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
card.BorderSizePixel = 0
card.Visible = false
card.ZIndex = 2
card.Parent = overlay

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 24)
corner.Parent = card

local cStroke = Instance.new("UIStroke")
cStroke.Color = Color3.fromRGB(160, 210, 150)
cStroke.Thickness = 4
cStroke.Parent = card

local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 80, 0, 80)
icon.Position = UDim2.new(0.5, -40, 0, 20)
icon.BackgroundTransparency = 1
icon.Text = "🏆"
icon.FontFace = FONTS.Title
icon.TextSize = 64
icon.TextColor3 = Color3.fromRGB(80, 80, 80)
icon.ZIndex = 3
icon.Parent = card

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 20, 0, 110)
title.BackgroundTransparency = 1
title.Text = ""
title.FontFace = FONTS.Heading
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(80, 55, 35)
title.ZIndex = 3
title.Parent = card

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -40, 0, 26)
subtitle.Position = UDim2.new(0, 20, 0, 144)
subtitle.BackgroundTransparency = 1
subtitle.Text = ""
subtitle.FontFace = FONTS.Body
subtitle.TextSize = 18
subtitle.TextColor3 = Color3.fromRGB(120, 100, 85)
subtitle.ZIndex = 3
subtitle.Parent = card

local queue = {}
local isShowing = false

local function showCard(kind: string, name: string, extra: string?)
	local config = {
		recipe = { icon = "🍳", title = "NEW RECIPE DISCOVERED!", color = Color3.fromRGB(255, 150, 200) },
		achievement = { icon = "🏆", title = "ACHIEVEMENT UNLOCKED!", color = Color3.fromRGB(255, 200, 80) },
		companion = { icon = "🌱", title = "NEW COMPANION BONDED!", color = Color3.fromRGB(160, 210, 150) },
		biome = { icon = "🗺️", title = "NEW BIOME DISCOVERED!", color = Color3.fromRGB(145, 215, 195) },
	}
	local cfg = config[kind] or config.achievement

	icon.Text = cfg.icon
	title.Text = cfg.title
	subtitle.Text = name
	cStroke.Color = cfg.color

	overlay.Visible = true
	card.Visible = true
	overlay.BackgroundTransparency = 0.4
	card.Size = UDim2.new(0, 0, 0, 0)
	card.BackgroundTransparency = 0
	icon.TextTransparency = 0
	title.TextTransparency = 0
	subtitle.TextTransparency = 0

	-- Zunda "link" pointer while the clickable milestone card is up.
	local zc = _G.ZundaCursors
	if zc then
		zc.setCursor("link")
	end

	local centerX = overlay.AbsoluteSize.X / 2
	local centerY = overlay.AbsoluteSize.Y / 2
	if UIHelper and UIHelper.spawnSparkles then
		UIHelper.spawnSparkles(overlay, centerX, centerY, cfg.color, 16)
	end

	local zsc = _G.ZundaSoundController
	if zsc and zsc.play then
		zsc.play("milestone_unveil")
	end

	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 260),
	}):Play()

	task.delay(3.5, function()
		if not isShowing then
			return
		end
		TweenService:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, TweenInfo.new(0.35), { Size = UDim2.new(0, 0, 0, 0) }):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		TweenService:Create(title, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
	end)

	task.delay(4, function()
		overlay.Visible = false
		card.Visible = false
		isShowing = false

		-- Restore the cursor when the milestone card goes away.
		local zc = _G.ZundaCursors
		if zc then
			zc.pop()
		end

		if #queue > 0 then
			local nextItem = table.remove(queue, 1)
			showCard(nextItem.kind, nextItem.name, nextItem.extra)
		end
	end)
end

local function enqueue(kind: string, name: string, extra: string?)
	if isShowing then
		table.insert(queue, { kind = kind, name = name, extra = extra })
		return
	end
	isShowing = true
	showCard(kind, name, extra)
end

-- Hook existing events
local RE = RS:WaitForChild("RemoteEvents")
local RewardEvents = RS:WaitForChild("RewardEvents")

local recipeEv = RE:FindFirstChild("RecipeUnlocked")
if recipeEv then
	recipeEv.OnClientEvent:Connect(function(data)
		local name = data.recipe or data.tierName or "New Recipe"
		enqueue("recipe", name)
	end)
end

local achievementEv = RewardEvents:FindFirstChild("AchievementUnlocked")
if achievementEv then
	achievementEv.OnClientEvent:Connect(function(name, _desc, icon)
		enqueue("achievement", name or "Achievement")
	end)
end

local previousSnapshot = nil
local snapshotEv = RE:FindFirstChild("CollectionSnapshot")
if snapshotEv then
	snapshotEv.OnClientEvent:Connect(function(snapshot)
		local counts = snapshot and snapshot.counts
		if not counts then
			return
		end
		if previousSnapshot then
			if (counts.companions or 0) > (previousSnapshot.companions or 0) then
				enqueue("companion", "A New Friend")
			end
			if (counts.biomes or 0) > (previousSnapshot.biomes or 0) then
				enqueue("biome", "A New Place")
			end
		end
		previousSnapshot = {}
		for key, value in pairs(counts) do
			previousSnapshot[key] = value
		end
	end)
end

print("[MilestoneUnveil] Ready")
