-- Recipe unlock toast: animated card when new recipes are discovered via tier-up.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RecipeUnlockToast"
gui.ResetOnSpawn = false
gui.DisplayOrder = 93
gui.Enabled = false
gui.Parent = playerGui

local card = Instance.new("Frame", gui)
card.Name = "Card"
card.Size = UDim2.new(0, 300, 0, 160)
card.Position = UDim2.new(0.5, -150, -0.2, 0)
card.BackgroundColor3 = Color3.fromRGB(255, 248, 235)
card.BorderSizePixel = 0
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
local cStroke = Instance.new("UIStroke", card)
cStroke.Color = Color3.fromRGB(255, 200, 50)
cStroke.Thickness = 3

local title = Instance.new("TextLabel", card)
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "★ NEW RECIPE UNLOCKED! ★"
title.Font = Enum.Font.FredokaOne
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 200, 50)

local tierLbl = Instance.new("TextLabel", card)
tierLbl.Name = "Tier"
tierLbl.Size = UDim2.new(1, -20, 0, 18)
tierLbl.Position = UDim2.new(0, 10, 0, 34)
tierLbl.BackgroundTransparency = 1
tierLbl.Text = ""
tierLbl.Font = Enum.Font.Gotham
tierLbl.TextSize = 13
tierLbl.TextColor3 = Color3.fromRGB(140, 100, 80)

local recipeList = Instance.new("TextLabel", card)
recipeList.Name = "Recipes"
recipeList.Size = UDim2.new(1, -20, 1, -80)
recipeList.Position = UDim2.new(0, 10, 0, 56)
recipeList.BackgroundTransparency = 1
recipeList.Text = ""
recipeList.Font = Enum.Font.GothamBold
recipeList.TextSize = 15
recipeList.TextColor3 = Color3.fromRGB(80, 40, 30)
recipeList.TextXAlignment = Enum.TextXAlignment.Left
recipeList.TextYAlignment = Enum.TextYAlignment.Top

local dismissBtn = Instance.new("TextButton", card)
dismissBtn.Size = UDim2.new(0, 100, 0, 28)
dismissBtn.Position = UDim2.new(0.5, -50, 1, -36)
dismissBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
dismissBtn.Text = "Yum!"
dismissBtn.TextColor3 = Color3.fromRGB(80, 40, 30)
dismissBtn.Font = Enum.Font.GothamBold
dismissBtn.TextSize = 14
dismissBtn.BorderSizePixel = 0
Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 8)

dismissBtn.MouseButton1Click:Connect(function()
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		Position = UDim2.new(0.5, -150, -0.2, 0)
	}):Play()
	task.wait(0.3)
	gui.Enabled = false
end)

local RE = RS:WaitForChild("RemoteEvents")
local unlockEv = RE:FindFirstChild("RecipeUnlocked")
if unlockEv then
	unlockEv.OnClientEvent:Connect(function(data)
		if not data or not data.recipes or #data.recipes == 0 then return end
		tierLbl.Text = "Tier " .. (data.tier or "?") .. ": " .. (data.tierName or "")
		local lines = {}
		for _, r in ipairs(data.recipes) do
			table.insert(lines, "  🍽 " .. r)
		end
		recipeList.Text = table.concat(lines, "\n")
		gui.Enabled = true
		card.Position = UDim2.new(0.5, -150, -0.2, 0)
		TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -150, 0.1, 0)
		}):Play()
	end)
end
