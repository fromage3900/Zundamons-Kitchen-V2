-- [[LocalScript] CraftingScript (ref: RBX0DC7A0732A82493992F3FC69FDF2E0AA)]]
-- CraftingScript: Client-side crafting UI controller
-- Press K to toggle the crafting panel, click a recipe to craft it.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local panel = script.Parent:WaitForChild("Panel")
local closeBtn = panel:WaitForChild("TitleBar"):WaitForChild("CloseBtn")
local scroll = panel:WaitForChild("RecipeList")

local craftFunc = RS:WaitForChild("RemoteFunctions"):WaitForChild("CraftFunction")
local requestData = RS:WaitForChild("RemoteFunctions"):WaitForChild("RequestData")

-- Load recipes from server config to avoid sync issues
-- Recipes are read-only; locked recipes handled server-side
local craftConfig = require(RS.ConfigurationFiles:WaitForChild("CraftConfig"))
local UIHelper = require(RS.Shared.Modules.UIHelper)
local UIConfig = require(RS.ConfigurationFiles.UIConfig)

-- Build RECIPES array from Config (format for UI display)
local RECIPES = {}
for recipeName, ings in pairs(craftConfig.recipes) do
	local locked = ings.locked == true
	-- Convert locked flag to separate table
	local recipeEntry = {
		name = recipeName,
		ings = ings,
		locked = locked,
	}
	-- Remove the locked key from ings for display
	if locked then
		ings.locked = nil
	end
	table.insert(RECIPES, recipeEntry)
end

-- Helper: build ingredient labels with icons
local function buildIngredientLine(parent, xPos, yPos, width, item, count)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0, width, 0, 24)
	row.Position = UDim2.new(0, xPos, 0, yPos)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = parent

	local icon = UIHelper.createItemIcon(item, UDim2.fromOffset(20, 20), row)
	icon.Position = UDim2.new(0, 0, 0.5, -10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = count .. "x " .. item
    lbl.TextColor3 = UIConfig.COLORS.TextDarkSec
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.FontFace = UIConfig.FONTS.Body
    lbl.Parent = row
end

-- Build a card for each recipe
local function buildRecipeCard(recipe)
	local card = Instance.new("Frame")
	card.Name = "Recipe_" .. recipe.name
	card.Size = UDim2.new(1, -10, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(255, 245, 230)
	card.BorderSizePixel = 0
	card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.7, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = recipe.name
    nameLabel.TextColor3 = UIConfig.COLORS.TextDark
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextScaled = true
    nameLabel.FontFace = UIConfig.FONTS.Heading
    nameLabel.Parent = card

	-- Unlock hint for locked recipes
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Name = "HintLabel"
    hintLabel.Size = UDim2.new(0.7, 0, 0, 16)
    hintLabel.Position = UDim2.new(0, 10, 0, 32)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = recipe.locked and "🔒 Unlocks at Tier 2 (15 guests)" or ""
    hintLabel.TextColor3 = UIConfig.COLORS.ZundamonPink
    hintLabel.TextXAlignment = Enum.TextXAlignment.Left
    hintLabel.TextScaled = true
    hintLabel.FontFace = UIConfig.FONTS.Body
    hintLabel.Visible = recipe.locked
    hintLabel.Parent = card

	local ingY = 0
	for item, count in recipe.ings do
		buildIngredientLine(card, 10, 50 + ingY, 280, item, count)
		ingY = ingY + 22
	end

    local craftBtn = Instance.new("TextButton")
    craftBtn.Size = UDim2.new(0, 90, 0, 50)
    craftBtn.Position = UDim2.new(1, -100, 0, 10)
    craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaGreen
    craftBtn.TextColor3 = UIConfig.COLORS.TextWhite
    craftBtn.Text = "Craft"
    craftBtn.TextScaled = true
    craftBtn.FontFace = UIConfig.FONTS.Heading
    craftBtn.Parent = card
    Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0, 6)

	craftBtn.MouseButton1Click:Connect(function()
		local pos = craftBtn.AbsolutePosition
		local sz = craftBtn.AbsoluteSize
		UIHelper.spawnSparkles(craftBtn.Parent, pos.X + sz.X / 2, pos.Y + sz.Y / 2, Color3.fromRGB(120, 200, 120), 5)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		-- Prevent double-tap while a cook is running
		if _G.TimedCooking and _G.TimedCooking.isCooking() then
			return
		end

		-- Helper: send craft to server with score data for server-authoritative quality
		local function submitCraft(quality, scores)
			craftBtn.Text = "\u{2728}" -- ✨ while server processes
			local ok, result = pcall(function()
				return craftFunc:InvokeServer(recipe.name, hrp.Position, scores or {})
			end)
            if ok and result == "Success" then
                if quality == "perfect" then
                    craftBtn.Text = "PERFECT \u{2728}"
                    craftBtn.BackgroundColor3 = UIConfig.COLORS.ZundamonGold
                    UIHelper.spawnSparkles(craftBtn.Parent, pos.X + sz.X / 2, pos.Y, Color3.fromRGB(255, 220, 80), 12)
                elseif quality == "great" then
                    craftBtn.Text = "Great \u{2713}"
                    craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaGreen
                    UIHelper.spawnSparkles(craftBtn.Parent, pos.X + sz.X / 2, pos.Y, Color3.fromRGB(120, 255, 120), 8)
                else
                    craftBtn.Text = "OK \u{2713}"
                    craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaLight
                end
            else
                craftBtn.Text = "Need more!"
                craftBtn.BackgroundColor3 = UIConfig.COLORS.Danger
            end
            task.delay(1.8, function()
                craftBtn.Text = "Craft"
                craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaGreen
            end)
		end

		-- Run the timed cooking mini-game if available, otherwise fall through
		if _G.TimedCooking and _G.TimedCooking.start then
			craftBtn.Text = "Cooking\u{2026}"
			local started = _G.TimedCooking.start(recipe.name, function(quality, scores)
				submitCraft(quality, scores)
			end)
			if not started then
				craftBtn.Text = "Craft"
			end
		else
			submitCraft("ok")
		end
	end)
end

-- Build all recipe cards once on load
for _, r in ipairs(RECIPES) do
	buildRecipeCard(r)
end

-- Toggle panel
local function setOpen(state)
	panel.Visible = state
end

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.K then
		setOpen(not panel.Visible)
	end
end)

-- Wire the ZundaHUD button if present (added in HudButtons row)
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
	local hbtn = hb:WaitForChild("HudBtn_crafting", 5)
	if hbtn then
		hbtn.MouseButton1Click:Connect(function()
			setOpen(not panel.Visible)
		end)
	end
end)

print("[CraftingScript] Loaded - Press K to open crafting panel")
