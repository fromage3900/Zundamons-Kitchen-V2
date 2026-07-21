-- First-use AI chat disclosure modal (Roblox generative AI transparency).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local DisclaimerConfig = require(RS.ConfigurationFiles.DisclaimerConfig)
local UIComponents = require(RS.ConfigurationFiles.UIComponents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RF = RS:WaitForChild("RemoteFunctions")

local getStatus = RF:WaitForChild("GetLlmDisclaimerStatus", 15)
local acceptRemote = RF:WaitForChild("AcceptLlmDisclaimer", 15)

local accepted = false
local modalOpen = false
local pendingCallbacks: { () -> () } = {}

local function refreshStatus()
	if not getStatus then
		return
	end
	local ok, result = pcall(function()
		return getStatus:InvokeServer()
	end)
	if ok and result == true then
		accepted = true
	end
end

refreshStatus()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LlmDisclaimerGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 200
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 6, 16)
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = screenGui

local panel = UIComponents.createPanel({
	Size = UDim2.fromOffset(480, 360),
	Parent = screenGui,
})
panel.Name = "Panel"
panel.Visible = false
panel.ZIndex = 2

local title = UIComponents.createLabel({
	Text = DisclaimerConfig.title,
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.fromOffset(12, 12),
	Parent = panel,
})

local body = UIComponents.createLabel({
	Text = DisclaimerConfig.body,
	Size = UDim2.new(1, -24, 1, -120),
	Position = UDim2.fromOffset(12, 52),
	Parent = panel,
})
body.TextWrapped = true
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextSize = 14

local acceptBtn = UIComponents.createButton({
	Text = DisclaimerConfig.acceptLabel,
	Size = UDim2.new(0.48, -8, 0, 40),
	Position = UDim2.new(0.02, 0, 1, -52),
	Parent = panel,
})

local declineBtn = UIComponents.createButton({
	Text = DisclaimerConfig.declineLabel,
	Size = UDim2.new(0.48, -8, 0, 40),
	Position = UDim2.new(0.5, 8, 1, -52),
	Parent = panel,
})

local function closeModal()
	modalOpen = false
	backdrop.Visible = false
	panel.Visible = false
end

local function flushPending()
	local queue = pendingCallbacks
	pendingCallbacks = {}
	for _, cb in ipairs(queue) do
		task.spawn(cb)
	end
end

local function onAccepted()
	accepted = true
	closeModal()
	flushPending()
end

acceptBtn.MouseButton1Click:Connect(function()
	if not acceptRemote then
		return
	end
	local ok, result = pcall(function()
		return acceptRemote:InvokeServer(true)
	end)
	if ok and result == true then
		onAccepted()
	end
end)

declineBtn.MouseButton1Click:Connect(function()
	closeModal()
	pendingCallbacks = {}
end)

_G.ZundaLlmDisclaimer = {
	hasAccepted = function()
		return accepted
	end,
	ensureAccepted = function(onReady: () -> ())
		if accepted then
			onReady()
			return
		end
		table.insert(pendingCallbacks, onReady)
		if modalOpen then
			return
		end
		modalOpen = true
		backdrop.Visible = true
		panel.Visible = true
		UIComponents.animateIn(panel)
	end,
}

print("[DisclaimerGate] AI disclosure gate ready")
