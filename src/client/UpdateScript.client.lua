-- [[LocalScript] UpdateScript (ref: RBX1CDC33CDBEF940A7BB30E89D3D319B74)]]
-- Pink & Green Progression Panel UpdateScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")

local function findGuiWithChild(childName)
	for _, g in ipairs(playerGui:GetChildren()) do
		if g:IsA("ScreenGui") and g:FindFirstChild(childName, true) then
			g.ResetOnSpawn = false
			return g
		end
	end
	return nil
end

local panelGui = findGuiWithChild("MainFrame")
if not panelGui then
	print("[UpdateScript] No GUI with MainFrame found — Progression panel skipped")
	return
end
local mainFrame = panelGui:FindFirstChild("MainFrame", true)
local goldLabel = mainFrame and mainFrame:FindFirstChild("GoldLabel", true)
local guestsLabel = mainFrame and mainFrame:FindFirstChild("GuestsLabel", true)
local progressFill = mainFrame and mainFrame:FindFirstChild("ProgressBg", true) and mainFrame.ProgressBg:FindFirstChild("Fill")
local progressLabel = mainFrame and mainFrame:FindFirstChild("ProgressLabel", true)
if not mainFrame or not goldLabel then
	print("[UpdateScript] Required GUI elements not found — skipping")
	return
end

-- RemoteFunction for data
local requestData = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
    and ReplicatedStorage.RemoteFunctions:WaitForChild("RequestData", 10)
local popupEvent = ReplicatedStorage:FindFirstChild("RewardEvents") and ReplicatedStorage.RewardEvents:FindFirstChild("PopupEvent")

-- Progression tiers (mirrors ProgressionConfig)
local TIERS = {
    {guests = 0,  name = "Humble Baker",  next = 5,  nextName = "Royal Chef"},
    {guests = 5,  name = "Royal Chef",    next = 20, nextName = "Master Chef"},
    {guests = 20, name = "Master Chef",   next = 50, nextName = "Legend"},
    {guests = 50, name = "Legend",        next = 50, nextName = "MAX TIER"},
}

local lastGold, lastGuests = -1, -1

local function updateUI()
    if not requestData then return end

    local ok, data = pcall(function()
        return requestData:InvokeServer()
    end)
    if not ok or not data then return end
    _G.data = data

    local gold = data.gold or 0
    local guests = data.guests_served or 0

    if gold == lastGold and guests == lastGuests then return end
    lastGold = gold
    lastGuests = guests

    -- Update labels
    goldLabel.Text = "💰  " .. gold .. " Gold"
    guestsLabel.Text = "👥  " .. guests .. " Guests Served"

    -- Find current tier and next milestone
    local currentTier = TIERS[1]
    for _, tier in ipairs(TIERS) do
        if guests >= tier.guests then
            currentTier = tier
        end
    end

    -- Progress bar
    local nextGuests = currentTier.next
    local tierStart = currentTier.guests
    if nextGuests > tierStart then
        local progress = math.clamp((guests - tierStart) / (nextGuests - tierStart), 0, 1)
        progressFill.Size = UDim2.new(progress, 0, 1, 0)
        progressLabel.Text = string.format("🎯 %s  →  Serve %d guests for %s!",
            currentTier.name, nextGuests, currentTier.nextName)
    else
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressLabel.Text = "⭐ LEGEND CHEF - MAX TIER REACHED!"
    end
end

-- Event-driven refresh (PopupEvent fires on gold/XP changes)
if popupEvent then
    popupEvent.OnClientEvent:Connect(function()
        updateUI()
    end)
end
updateUI()
-- Safety fallback poll
task.spawn(function()
    while true do
        task.wait(60)
        updateUI()
    end
end)
