-- [[LocalScript] CraftingScript (ref: RBX0DC7A0732A82493992F3FC69FDF2E0AA)]]
-- CraftingScript: Client-side crafting UI controller
-- Press K to toggle the crafting panel, click a recipe to craft it.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientGuiBootstrap = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("ClientGuiBootstrap"))

local gui
local panel
local closeBtn
local scroll

for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") and g:FindFirstChild("RecipeList", true) then
		gui = g
		gui.ResetOnSpawn = false
		panel = gui:FindFirstChild("Panel", true)
		closeBtn = panel:FindFirstChild("CloseBtn", true)
		scroll = panel:FindFirstChild("RecipeList", true)
		break
	end
end

if not gui or not panel or not scroll then
	gui = ClientGuiBootstrap.createScreenGui(player, "CraftingGui", 25)

	panel = Instance.new("Frame", gui)
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 460, 0, 520)
	panel.Position = UDim2.new(0.5, -230, 0.5, -260)
	panel.BackgroundColor3 = Color3.fromRGB(30, 24, 42)
	panel.BorderSizePixel = 0
	panel.Visible = false
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(220, 160, 230)
	stroke.Thickness = 2.5

	local title = Instance.new("TextLabel", panel)
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 48)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🍳  Crafting Kitchen"
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 26
	title.TextColor3 = Color3.fromRGB(255, 220, 245)
	title.TextXAlignment = Enum.TextXAlignment.Left

	closeBtn = Instance.new("TextButton", panel)
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -48, 0, 14)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BorderSizePixel = 0
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

	scroll = Instance.new("ScrollingFrame", panel)
	scroll.Name = "RecipeList"
	scroll.Size = UDim2.new(1, -32, 1, -80)
	scroll.Position = UDim2.new(0, 16, 0, 68)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 160, 230)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
end

local craftFunc = RS:WaitForChild("RemoteFunctions"):WaitForChild("CraftFunction")
local requestData = RS:WaitForChild("RemoteFunctions"):WaitForChild("RequestData")

local craftConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("CraftConfig"))
local UIHelper = require(RS:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("UIHelper"))
local UIConfig = require(RS:WaitForChild("ConfigurationFiles"):WaitForChild("UIConfig"))

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

		-- Helper: send craft to server (server will return "Cooking" to start minigame, or "Fail")
		local function submitCraft()
			craftBtn.Text = "\u{2728}" -- ✨ while server processes
			local ok, result = pcall(function()
				return craftFunc:InvokeServer(recipe.name, hrp.Position)
			end)
            if ok and result == "Cooking" then
                if _G.TimedCooking and _G.TimedCooking.start then
                    craftBtn.Text = "Cooking\u{2026}"
                    _G.TimedCooking.start(recipe.name, function(quality)
                        craftBtn.Text = quality:upper() .. "!"
                        if quality == "perfect" then
                            craftBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                        elseif quality == "great" then
                            craftBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                        else
                            craftBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 100)
                        end
                        task.delay(2, function()
                            craftBtn.Text = "Craft"
                            craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaGreen
                        end)
                    end)
                end
            else
                craftBtn.Text = "Need more!"
                craftBtn.BackgroundColor3 = UIConfig.COLORS.Danger
                task.delay(1.8, function()
                    craftBtn.Text = "Craft"
                    craftBtn.BackgroundColor3 = UIConfig.COLORS.PeaGreen
                end)
            end
		end

		submitCraft()
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
