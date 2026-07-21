--!strict
-- Read-only projection from PlayerDataService into the persistent top-level HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateChanged = ReplicatedStorage.RemoteEvents:WaitForChild("PlayerStateChanged") :: RemoteEvent
local requestState = ReplicatedStorage.RemoteFunctions:WaitForChild("RequestPlayerState") :: RemoteFunction

local hud = playerGui:WaitForChild("ZundaHUD") :: ScreenGui
hud.ResetOnSpawn = false
local statBar = hud:WaitForChild("StatBar") :: Frame

local layout = statBar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = statBar

local function label(name: string): TextLabel
	local existing = statBar:FindFirstChild(name)
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Size = UDim2.fromOffset(135, 32)
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.GothamBold
	item.TextColor3 = Color3.fromRGB(249, 244, 224)
	item.TextSize = 15
	item.Parent = statBar
	return item
end

local goldLabel = label("GoldPill")
local guestsLabel = label("GuestsPill")
local lastRevision = -1

local function render(state: any)
	if type(state) ~= "table" then
		return
	end
	local revision = tonumber(state.revision) or 0
	if revision < lastRevision then
		return
	end
	lastRevision = revision
	goldLabel.Text = string.format("Gold  %d", tonumber(state.gold) or 0)
	guestsLabel.Text = string.format("Guests  %d", tonumber(state.guestsServed) or 0)
end

stateChanged.OnClientEvent:Connect(render)

local ok, initial = pcall(function()
	return requestState:InvokeServer()
end)
if ok then
	render(initial)
end

