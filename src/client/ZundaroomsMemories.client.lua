--!strict
-- Zundarooms memory fragments: client-side banner + journal overlay.
-- Fired by the server on escape through ZundaroomsStatus(status, memories).
-- Shows the memories carried out of this run and keeps a persistent
-- "Memories recovered" counter in the existing ZundaHUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RE = ReplicatedStorage.RemoteEvents
local statusEvent = RE:WaitForChild("ZundaroomsStatus") :: RemoteEvent

-- Persistent counter in ZundaHUD (top-right), survives across sessions.
local function getOrCreateCounter()
	local hud = player:WaitForChild("PlayerGui"):FindFirstChild("ZundaHUD")
	if not hud or not hud:IsA("ScreenGui") then
		return nil
	end
	local existing = hud:FindFirstChild("ZundaroomsCounter")
	if existing and existing:IsA("Frame") then
		return existing
	end
	local frame = Instance.new("Frame")
	frame.Name = "ZundaroomsCounter"
	frame.Size = UDim2.new(0, 220, 0, 30)
	frame.Position = UDim2.new(1, -232, 0, 8)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 14)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = hud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", frame).Color = Color3.fromRGB(120, 140, 100)
	Instance.new("UIStroke", frame).Thickness = 1
	local label = Instance.new("TextLabel")
	label.Name = "CountLabel"
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 6, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "Memories: 0"
	label.TextColor3 = Color3.fromRGB(200, 210, 170)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	return frame
end

-- One-shot escape readout for the memories carried out of THIS run.
local function showEscaped(memories: { { id: string, text: string } })
	if #memories == 0 then
		return
	end

	local gui = player:WaitForChild("PlayerGui")
	local readout = Instance.new("ScreenGui")
	readout.Name = "ZundaroomsReadout"
	readout.ResetOnSpawn = false
	readout.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	readout.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 380, 0, 140)
	panel.Position = UDim2.new(0.5, -190, 0.5, -70)
	panel.BackgroundColor3 = Color3.fromRGB(14, 16, 12)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = readout
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", panel)
	stroke.Color = Color3.fromRGB(160, 180, 130)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 26)
	title.Position = UDim2.new(0, 8, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Carried out of the rooms"
	title.TextColor3 = Color3.fromRGB(220, 230, 195)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextWrapped = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local list = Instance.new("TextLabel")
	list.Name = "List"
	list.Size = UDim2.new(1, -16, 0, 90)
	list.Position = UDim2.new(0, 8, 0, 36)
	list.BackgroundTransparency = 1
	list.TextColor3 = Color3.fromRGB(185, 195, 155)
	list.Font = Enum.Font.Gotham
	list.TextSize = 12
	list.TextWrapped = true
	list.TextXAlignment = Enum.TextXAlignment.Left
	local lines: { string } = {}
	for _, mem in ipairs(memories) do
		table.insert(lines, "• " .. mem.text)
	end
	list.Text = table.concat(lines, "\n")
	list.Parent = panel

	panel.Position = UDim2.new(0.5, -190, 0.5, -90)
	TweenService:Create(
		panel,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -190, 0.5, -70) }
	):Play()

	-- Bump the persistent counter.
	local counter = getOrCreateCounter()
	if counter then
		local label = counter:FindFirstChild("CountLabel")
		if label then
			local current = tonumber(string.match(label.Text, "Memories: (%d+)") or "0") or 0
			label.Text = string.format("Memories: %d", current + #memories)
		end
	end

	task.delay(6, function()
		TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -190, 0.5, -100), BackgroundTransparency = 1 }
		):Play()
		task.delay(0.25, function()
			readout:Destroy()
		end)
	end)
end

-- Existing contract: server fires ZundaroomsStatus(status) for all outcomes,
-- and ZundaroomsStatus("escaped", memories) on a successful escape.
statusEvent.OnClientEvent:Connect(function(status, memories)
	if status == "escaped" and memories and #memories > 0 then
		showEscaped(memories)
	end
end)

print("[ZundaroomsMemories] client journal ready")
