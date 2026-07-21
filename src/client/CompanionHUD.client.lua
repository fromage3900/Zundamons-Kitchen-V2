-- Companion HUD: shows active companion, buff, quick-switch buttons.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local setCompEv = RS.RemoteEvents:WaitForChild("SetCompanion")

local COMPANIONS = shared and shared.ZundaCompanionCatalog or nil

local gui = Instance.new("ScreenGui")
gui.Name = "CompanionHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = playerGui

local bar = Instance.new("Frame", gui)
bar.Name = "Bar"
bar.Size = UDim2.new(0, 200, 0, 44)
bar.Position = UDim2.new(0, 10, 0.7, 0)
bar.BackgroundColor3 = UIConfig.GAME_COLORS.HUDBg
bar.BackgroundTransparency = 0.2
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)
local bStroke = Instance.new("UIStroke", bar)
bStroke.Color = UIConfig.COLORS.PanelBorder
bStroke.Thickness = 1.5

local emojiLbl = Instance.new("TextLabel", bar)
emojiLbl.Name = "Emoji"
emojiLbl.Size = UDim2.new(0, 36, 0, 36)
emojiLbl.Position = UDim2.new(0, 4, 0.5, -18)
emojiLbl.BackgroundTransparency = 1
emojiLbl.Text = "🍡"
emojiLbl.Font = Enum.Font.GothamBold
emojiLbl.TextSize = 22

local nameLbl = Instance.new("TextLabel", bar)
nameLbl.Name = "Name"
nameLbl.Size = UDim2.new(1, -44, 0, 18)
nameLbl.Position = UDim2.new(0, 44, 0, 4)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = "Zundamon"
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 13
nameLbl.TextColor3 = UIConfig.GAME_COLORS.HUDText
nameLbl.TextXAlignment = Enum.TextXAlignment.Left

local buffLbl = Instance.new("TextLabel", bar)
buffLbl.Name = "Buff"
buffLbl.Size = UDim2.new(1, -44, 0, 16)
buffLbl.Position = UDim2.new(0, 44, 0, 24)
buffLbl.BackgroundTransparency = 1
buffLbl.Text = ""
buffLbl.Font = Enum.Font.Gotham
buffLbl.TextSize = 11
buffLbl.TextColor3 = UIConfig.COLORS.TextSecondary
buffLbl.TextXAlignment = Enum.TextXAlignment.Left

local function updateDisplay(compType)
	if not COMPANIONS then return end
	local def = COMPANIONS[compType] or COMPANIONS.zundamon
	emojiLbl.Text = def.emoji or "🍡"
	nameLbl.Text = def.displayName or "Zundamon"
	local buffDesc = def.buff and def.buff.description or ""
	local flavorText = buffDesc ~= "" and buffDesc or def.flavor or ""
	buffLbl.Text = flavorText
	if def.buff and def.buff.stat then
		local mult = def.buff.magnitude or 0
		if buffDesc ~= "" then
			buffLbl.TextColor3 = UIConfig.COLORS.Success
		else
			buffLbl.TextColor3 = UIConfig.COLORS.TextSecondary
		end
	else
		buffLbl.TextColor3 = UIConfig.COLORS.TextSecondary
	end
end

-- Listen for companion changes
local dataRE = RS.RemoteEvents:FindFirstChild("UpdateData")
if dataRE then
	dataRE.OnClientEvent:Connect(function(data)
		if data and data.active_companion then
			updateDisplay(data.active_companion)
		end
	end)
end

-- Initial load
task.spawn(function()
	task.wait(3)
	local data = _G.data or {}
	updateDisplay(data.active_companion or "zundamon")
end)

print("[CompanionHUD] Ready")
