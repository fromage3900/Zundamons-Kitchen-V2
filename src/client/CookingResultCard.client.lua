-- Cooking result card. Shows after the rhythm game: star rating, gold, streak, mastery.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local UIConfig = require(RS.ConfigurationFiles.UIConfig)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "CookingResultCard"
gui.ResetOnSpawn = false
gui.DisplayOrder = 92
gui.Enabled = false
gui.Parent = playerGui

local backdrop = Instance.new("TextButton", gui)
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.Text = ""
backdrop.BorderSizePixel = 0
backdrop.AutoButtonColor = false
backdrop.Visible = false

local card = Instance.new("Frame", gui)
card.Name = "Card"
card.Size = UDim2.new(0, 340, 0, 240)
card.Position = UDim2.new(0.5, -170, 0.5, -120)
card.BackgroundColor3 = UIConfig.COLORS.PanelBg
card.BorderSizePixel = 0
card.Visible = false
card.BackgroundTransparency = 1
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
local cStroke = Instance.new("UIStroke", card)
cStroke.Color = UIConfig.COLORS.PanelBorder
cStroke.Thickness = 3
cStroke.Transparency = 1

local titleLbl = Instance.new("TextLabel", card)
titleLbl.Name = "Title"
titleLbl.Size = UDim2.new(1, -20, 0, 26)
titleLbl.Position = UDim2.new(0, 10, 0, 10)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = ""
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 18
titleLbl.TextColor3 = UIConfig.COLORS.TextDark
titleLbl.TextTransparency = 1

local starsLbl = Instance.new("TextLabel", card)
starsLbl.Name = "Stars"
starsLbl.Size = UDim2.new(1, -20, 0, 30)
starsLbl.Position = UDim2.new(0, 10, 0, 38)
starsLbl.BackgroundTransparency = 1
starsLbl.Text = ""
starsLbl.Font = Enum.Font.FredokaOne
starsLbl.TextSize = 24
starsLbl.TextStrokeTransparency = 0.4
starsLbl.TextStrokeColor3 = UIConfig.GAME_COLORS.SparkleGold
starsLbl.TextTransparency = 1

local goldLbl = Instance.new("TextLabel", card)
goldLbl.Name = "Gold"
goldLbl.Size = UDim2.new(1, -20, 0, 20)
goldLbl.Position = UDim2.new(0, 10, 0, 70)
goldLbl.BackgroundTransparency = 1
goldLbl.Text = ""
goldLbl.Font = Enum.Font.Gotham
goldLbl.TextSize = 15
goldLbl.TextColor3 = UIConfig.COLORS.Warning
goldLbl.TextTransparency = 1

local streakLbl = Instance.new("TextLabel", card)
streakLbl.Name = "Streak"
streakLbl.Size = UDim2.new(1, -20, 0, 20)
streakLbl.Position = UDim2.new(0, 10, 0, 92)
streakLbl.BackgroundTransparency = 1
streakLbl.Text = ""
streakLbl.Font = Enum.Font.Gotham
streakLbl.TextSize = 14
streakLbl.TextColor3 = UIConfig.COLORS.Success
streakLbl.TextTransparency = 1

local masteryLbl = Instance.new("TextLabel", card)
masteryLbl.Name = "Mastery"
masteryLbl.Size = UDim2.new(1, -20, 0, 20)
masteryLbl.Position = UDim2.new(0, 10, 0, 114)
masteryLbl.BackgroundTransparency = 1
masteryLbl.Text = ""
masteryLbl.Font = Enum.Font.Gotham
masteryLbl.TextSize = 13
masteryLbl.TextColor3 = UIConfig.COLORS.TextDarkSec
masteryLbl.TextTransparency = 1

local dismissBtn = Instance.new("TextButton", card)
dismissBtn.Size = UDim2.new(0, 120, 0, 32)
dismissBtn.Position = UDim2.new(0.5, -60, 1, -42)
dismissBtn.BackgroundColor3 = UIConfig.COLORS.Success
dismissBtn.Text = "OK!"
dismissBtn.TextColor3 = UIConfig.GAME_COLORS.HUDText
dismissBtn.Font = Enum.Font.GothamBold
dismissBtn.TextSize = 16
dismissBtn.BorderSizePixel = 0
dismissBtn.BackgroundTransparency = 1
dismissBtn.TextTransparency = 1
Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 8)

dismissBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

local RE = RS:WaitForChild("RemoteEvents")
local cookResultEv = RE:FindFirstChild("CookingResult")
if cookResultEv then
	cookResultEv.OnClientEvent:Connect(function(data)
		local recipe = data.recipe or ""
		local quality = data.quality or "ok"
		titleLbl.Text = "🍳 " .. recipe
		local starCount = quality == "perfect" and 5 or quality == "great" and 3 or 1
		starsLbl.Text = string.rep("★", starCount) .. string.rep("☆", 5 - starCount)
		goldLbl.Text = "+" .. (data.bonusGold or 0) .. " gold"
		local streak = _G.data and _G.data.cooking_streak or 0
		if streak > 1 then
			streakLbl.Text = "🔥 " .. streak .. " streak!"
		else
			streakLbl.Text = ""
		end
		local served = _G.data and _G.data.recipes_served_count and _G.data.recipes_served_count[recipe] or 0
		local mastery = math.min(math.floor(served / 10 * 100), 100)
		masteryLbl.Text = "Mastery: " .. mastery .. "%"
		gui.Enabled = true
		-- Animate in
		card.Visible = true; backdrop.Visible = true
		card.BackgroundTransparency = 1; cStroke.Transparency = 1
		titleLbl.TextTransparency = 1; starsLbl.TextTransparency = 1; goldLbl.TextTransparency = 1
		streakLbl.TextTransparency = 1; masteryLbl.TextTransparency = 1
		dismissBtn.BackgroundTransparency = 1; dismissBtn.TextTransparency = 1
		card.Size = UDim2.new(0, 0, 0, 0)
		card.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 340, 0, 240), Position = UDim2.new(0.5, -170, 0.5, -120)
		}):Play()
		task.wait(0.2)
		TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(cStroke, TweenInfo.new(0.2), { Transparency = 0 }):Play()
		task.wait(0.15)
		titleLbl.TextTransparency = 0; starsLbl.TextTransparency = 0; goldLbl.TextTransparency = 0
		streakLbl.TextTransparency = 0; masteryLbl.TextTransparency = 0
		task.wait(0.1)
		TweenService:Create(dismissBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
	end)
end
