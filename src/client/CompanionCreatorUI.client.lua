-- [[LocalScript] CompanionCreatorUI]
-- "Summon a Companion" creator panel. Type a theme (or pick a preset), hit
-- Summon, and the server AI-generates (or deterministic-fallback) a brand-new
-- companion, registers it in your data, equips it, and it walks beside you.
--
-- Wires to CompanionCreatorServer via SummonCompanion RemoteFunction.
-- Uses the same UI conventions as the Companion Boutique (CozyModalShell +
-- UIRouter + ClientGuiBootstrap).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ClientGuiBootstrap = require(RS.ConfigurationFiles.ClientGuiBootstrap)
local CozyModalShell = require(RS.ConfigurationFiles.CozyModalShell)
local UIRouter = require(RS.ConfigurationFiles.UIRouter)
local UIHelper = require(RS.Shared.Modules.UIHelper)
local ActionRegistry =
	require(player:WaitForChild("PlayerScripts"):WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

local gui = ClientGuiBootstrap.createScreenGui(player, "CompanionCreatorGui", 29)

local RE = RS:WaitForChild("RemoteEvents")
local RF = RS:WaitForChild("RemoteFunctions")
local SummonCompanion = RF:WaitForChild("SummonCompanion")
local CreateCompanion = RF:WaitForChild("CreateCompanion")
local SetCompanion = RE:WaitForChild("SetCompanion")

-- ── Backdrop ──────────────────────────────────────────────────
local backdrop = Instance.new("Frame", gui)
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(16, 10, 26)
backdrop.BackgroundTransparency = 0.45
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.ZIndex = 1

-- ── Panel ─────────────────────────────────────────────────────
local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 520, 0, 460)
panel.Position = UDim2.new(0.5, -260, 0.5, -230)
panel.BackgroundColor3 = Color3.fromRGB(255, 247, 240)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 22)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(255, 170, 190)
pStroke.Thickness = 3

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -100, 0, 52)
title.Position = UDim2.new(0, 24, 0, 14)
title.BackgroundTransparency = 1
title.Text = "✨  Summon a Companion  ✨"
title.Font = Enum.Font.FredokaOne
title.TextSize = 30
title.TextColor3 = Color3.fromRGB(120, 60, 110)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -52, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 100)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 30
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 4
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- ── Theme input ───────────────────────────────────────────────
local promptLbl = Instance.new("TextLabel", panel)
promptLbl.Size = UDim2.new(1, -40, 0, 24)
promptLbl.Position = UDim2.new(0, 20, 0, 76)
promptLbl.BackgroundTransparency = 1
promptLbl.Text = 'Describe your companion (e.g. "a sleepy moon fox who loves rice balls"):'
promptLbl.Font = Enum.Font.GothamBold
promptLbl.TextSize = 16
promptLbl.TextColor3 = Color3.fromRGB(110, 85, 105)
promptLbl.TextXAlignment = Enum.TextXAlignment.Left
promptLbl.ZIndex = 3

local themeBox = Instance.new("TextBox", panel)
themeBox.Name = "ThemeBox"
themeBox.Size = UDim2.new(1, -40, 0, 52)
themeBox.Position = UDim2.new(0, 20, 0, 104)
themeBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
themeBox.BorderSizePixel = 0
themeBox.PlaceholderText = "a sleepy moon fox…"
themeBox.PlaceholderColor3 = Color3.fromRGB(180, 160, 180)
themeBox.Font = Enum.Font.Gotham
themeBox.TextSize = 18
themeBox.TextColor3 = Color3.fromRGB(60, 45, 70)
themeBox.ClearTextOnFocus = true
themeBox.ZIndex = 3
Instance.new("UICorner", themeBox).CornerRadius = UDim.new(0, 12)
local tStroke = Instance.new("UIStroke", themeBox)
tStroke.Color = Color3.fromRGB(220, 160, 230)
tStroke.Thickness = 2

-- ── Preset chips ──────────────────────────────────────────────
local presetsLbl = Instance.new("TextLabel", panel)
presetsLbl.Size = UDim2.new(1, -40, 0, 22)
presetsLbl.Position = UDim2.new(0, 20, 0, 168)
presetsLbl.BackgroundTransparency = 1
presetsLbl.Text = "or try a preset:"
presetsLbl.Font = Enum.Font.GothamBold
presetsLbl.TextSize = 14
presetsLbl.TextColor3 = Color3.fromRGB(130, 105, 125)
presetsLbl.TextXAlignment = Enum.TextXAlignment.Left
presetsLbl.ZIndex = 3

local PRESETS = {
	{ "🦊  Moon Fox", "a sleepy moon fox who loves rice balls" },
	{ "🍄  Marsh Spirit", "a shy mushroom spirit that hums while you cook" },
	{ "🫧  Bubble Ghost", "a bubbly sea-foam ghost that giggles" },
	{ "🌸  Blossom Pup", "a gentle cherry-blossom puppy" },
	{ "🌙  Night Heron", "a quiet night heron that watches the stars" },
}

local chipsFrame = Instance.new("Frame", panel)
chipsFrame.Name = "PresetChips"
chipsFrame.Size = UDim2.new(1, -40, 0, 120)
chipsFrame.Position = UDim2.new(0, 20, 0, 192)
chipsFrame.BackgroundTransparency = 1
chipsFrame.ZIndex = 3
local chipsLayout = Instance.new("UIGridLayout", chipsFrame)
chipsLayout.CellSize = UDim2.new(0, 150, 0, 46)
chipsLayout.CellPadding = UDim2.new(0, 8, 0, 8)
chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder

for i, preset in ipairs(PRESETS) do
	local chip = Instance.new("TextButton", chipsFrame)
	chip.Size = UDim2.new(0, 150, 0, 46)
	chip.Text = preset[1]
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = 15
	chip.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
	chip.TextColor3 = Color3.fromRGB(255, 255, 255)
	chip.BorderSizePixel = 0
	chip.LayoutOrder = i
	chip.AutoButtonColor = true
	chip.ZIndex = 4
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 10)
	local cs = Instance.new("UIStroke", chip)
	cs.Color = Color3.fromRGB(220, 180, 255)
	cs.Thickness = 2
	chip.MouseButton1Click:Connect(function()
		themeBox.Text = preset[2]
	end)
end

-- ── Summon button ─────────────────────────────────────────────
local summonBtn = Instance.new("TextButton", panel)
summonBtn.Size = UDim2.new(1, -40, 0, 72)
summonBtn.Position = UDim2.new(0, 20, 1, -88)
summonBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 90)
summonBtn.Text = "🌱  Summon Companion  🌱"
summonBtn.Font = Enum.Font.FredokaOne
summonBtn.TextSize = 28
summonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
summonBtn.BorderSizePixel = 0
summonBtn.ZIndex = 3
Instance.new("UICorner", summonBtn).CornerRadius = UDim.new(0, 16)
local sStroke = Instance.new("UIStroke", summonBtn)
sStroke.Color = Color3.fromRGB(255, 220, 160)
sStroke.Thickness = 3

local statusLbl = Instance.new("TextLabel", panel)
statusLbl.Size = UDim2.new(1, -40, 0, 22)
statusLbl.Position = UDim2.new(0, 20, 1, -16)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 14
statusLbl.TextColor3 = Color3.fromRGB(90, 130, 90)
statusLbl.TextXAlignment = Enum.TextXAlignment.Center
statusLbl.ZIndex = 3

local busy = false

local function sparkleAround()
	local pos = summonBtn.AbsolutePosition
	UIHelper.spawnSparkles(
		panel,
		pos.X + summonBtn.AbsoluteSize.X / 2,
		pos.Y + summonBtn.AbsoluteSize.Y / 2,
		Color3.fromRGB(255, 255, 255),
		8
	)
end

summonBtn.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	busy = true
	statusLbl.Text = "Summoning…"
	statusLbl.TextColor3 = Color3.fromRGB(150, 110, 60)
	summonBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

	local theme = themeBox.Text
	local ok, okResult, generated
	task.spawn(function()
		local s1, res1, gen1 = pcall(function()
			return SummonCompanion:InvokeServer(theme)
		end)
		if s1 and res1 == true then
			ok, okResult, generated = true, gen1
		else
			ok, okResult = s1, res1 or "summon_failed"
		end

		busy = false
		if ok and okResult then
			statusLbl.Text = "✨ " .. (generated and generated.name or "New companion") .. " joined you!"
			statusLbl.TextColor3 = Color3.fromRGB(90, 150, 90)
			summonBtn.BackgroundColor3 = Color3.fromRGB(90, 160, 100)
			summonBtn.Text = "✓ Summoned!"
			sparkleAround()
			task.delay(2, function()
				summonBtn.Text = "🌱  Summon Companion  🌱"
				summonBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 90)
			end)
		else
			statusLbl.Text = "Hmm… the summon fizzled. Try a different idea."
			statusLbl.TextColor3 = Color3.fromRGB(180, 80, 80)
			summonBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 90)
		end
	end)
end)

-- ── Shell + routing (matches Companion Boutique) ──────────────
local shell = CozyModalShell.wrap(panel, {
	open = function()
		backdrop.Visible = true
		panel.Visible = true
		statusLbl.Text = ""
		themeBox.Text = ""
		summonBtn.Text = "🌱  Summon Companion  🌱"
		summonBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 90)
		busy = false
	end,
	close = function()
		panel.Visible = false
		backdrop.Visible = false
	end,
})

local function open()
	UIRouter.open("companion_creator")
	shell.open()
end
local function close()
	UIRouter.close("companion_creator")
	shell.close()
end
local function toggle()
	if panel.Visible then
		close()
	else
		open()
	end
end

closeBtn.MouseButton1Click:Connect(close)
UIRouter.register("companion_creator", shell.open, shell.close)
ActionRegistry.registerCallback("companion_creator", toggle)

_G.ZundaCompanionCreator = { open = open, close = close, toggle = toggle }

print("[CompanionCreatorUI] Ready — registered with ActionRegistry + UIRouter")
