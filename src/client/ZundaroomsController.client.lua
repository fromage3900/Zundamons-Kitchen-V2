--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.ConfigurationFiles.UIConfig)
local gui = require(ReplicatedStorage.ConfigurationFiles.ClientGuiBootstrap).createScreenGui(
	Players.LocalPlayer,
	"ZundaroomsStatusGui",
	110
)
local banner = Instance.new("TextLabel")
banner.Size = UDim2.new(0, 520, 0, 64)
banner.Position = UDim2.new(0.5, -260, 0.12, 0)
banner.BackgroundColor3 = Color3.fromRGB(18, 20, 14)
banner.BackgroundTransparency = 0.15
banner.TextColor3 = Color3.fromRGB(220, 230, 190)
banner.Font = Enum.Font.GothamBold
banner.TextSize = 22
banner.TextWrapped = true
banner.Visible = false
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

local messages = {
	locked = "The wall feels solid. Serve a guest, then listen again.",
	entered = "You slipped somewhere unfinished. Find the pale exit. Do not let it reach you.",
	escaped = "You escaped... but something remembers you.",
	caught = "You wake beside the wall. No one believes what followed you.",
	timeout = "The rooms fold inward and return you to the village.",
}

ReplicatedStorage.RemoteEvents.ZundaroomsStatus.OnClientEvent:Connect(function(status)
	banner.Text = messages[status] or "The walls are humming."
	banner.Visible = true
	task.delay(status == "entered" and 5 or 3.5, function()
		banner.Visible = false
	end)
end)
