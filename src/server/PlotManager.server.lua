-- [[Script] PlotManager (ref: RBX16990E9968B7409A862E400CBFD031A6)]]
-- PlotManager: Handles plot claiming, ownership, and unlocking
-- Lives in ServerScriptService/Plots/
-- Plot progression: Plot 1 = free, Plot 2 = 10 guests, Plot 3 = 25, Plot 4 = 50

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
local notifyRE = RE:FindFirstChild("NotifyPlayer") or Instance.new("RemoteEvent")
notifyRE.Name = "NotifyPlayer"
notifyRE.Parent = RE

local PLOT_REQUIREMENTS = {1, 10, 25, 50}  -- guests_served needed per plot
local PLOT_CENTERS = {
    [1] = Vector3.new(145, -509, -420),
    [2] = Vector3.new(165, -509, -420),
    [3] = Vector3.new(145, -509, -440),
    [4] = Vector3.new(165, -509, -440),
}

-- Track which plots are claimed: plotNum -> playerName
local claimedPlots = {}

-- Update the in-world plot signs to reflect ownership
local function updatePlotSigns()
    for plotNum = 1, 4 do
        local signName = "PlotSign_" .. plotNum
        local sign = workspace:FindFirstChild(signName, true)
        if sign then
            local sg = sign:FindFirstChildOfClass("SurfaceGui")
            if sg then
                local lbl = sg:FindFirstChildOfClass("Frame")
                    and sg:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel")
                    or sg:FindFirstChildOfClass("TextLabel")
                if lbl then
                    local owner = claimedPlots[plotNum]
                    if owner then
                        lbl.Text = "🏠 " .. owner .. "'s Plot"
                    else
                        local req = PLOT_REQUIREMENTS[plotNum]
                        if plotNum == 1 then
                            lbl.Text = "✅ Plot 1\nClaim it!"
                        else
                            lbl.Text = "🔒 Plot " .. plotNum .. "\nServe " .. req .. " guests"
                        end
                    end
                end
            end
        end
    end
end

-- Attempt to claim a plot for a player
local function claimPlot(player, plotNum)
	local data = PlayerDataService.get(player)
    if not data then return false, "Data not ready" end

    -- Check if player already has a plot
    if data.owned_plot then
        return false, "You already own Plot " .. data.owned_plot .. "!"
    end

    -- Check if plot is taken
    if claimedPlots[plotNum] then
        return false, "That plot is already taken!"
    end

    -- Check guest requirement
    local req = PLOT_REQUIREMENTS[plotNum] or 999
    local guests = data.guests_served or 0
    if guests < req then
        return false, "Need to serve " .. req .. " guests first! (you have " .. guests .. ")"
    end

    -- Claim it
    claimedPlots[plotNum] = player.Name
    data.owned_plot = plotNum

    updatePlotSigns()
    notifyRE:FireClient(player, "unlock", "🏠 You claimed Plot " .. plotNum .. "!")
    print("[PlotManager] " .. player.Name .. " claimed plot " .. plotNum)
    return true, "Plot " .. plotNum .. " is now yours!"
end

-- Expose globally for use by other systems
_G.claimPlot = claimPlot
_G.claimedPlots = claimedPlots

-- Create ClaimPlot RemoteFunction
local RF = ReplicatedStorage:WaitForChild("RemoteFunctions")
local claimRF = RF:FindFirstChild("ClaimPlot") or Instance.new("RemoteFunction")
claimRF.Name = "ClaimPlot"
claimRF.Parent = RF

claimRF.OnServerInvoke = function(player, plotNum)
    local success, msg = claimPlot(player, plotNum)
    return {success=success, message=msg}
end

-- Wire ClickDetectors on each PlotSign so clicking directly attempts to claim
local function wirePlotSignClicks()
    for plotNum = 1, 4 do
        local sign = workspace:FindFirstChild("PlotSign_" .. plotNum)
        if sign and sign:IsA("BasePart") then
            sign:SetAttribute("PlotNumber", plotNum)
            local cd = sign:FindFirstChildOfClass("ClickDetector")
            if not cd then
                cd = Instance.new("ClickDetector")
                cd.MaxActivationDistance = 20
                cd.Parent = sign
            end
            cd.MouseClick:Connect(function(player)
                local success, msg = claimPlot(player, plotNum)
                notifyRE:FireClient(player, success and "unlock" or "error", msg)
            end)
        end
    end
end

wirePlotSignClicks()
-- Initial sign refresh
updatePlotSigns()

-- On player join: restore their plot from saved data
Players.PlayerAdded:Connect(function(player)
    -- Wait for DataManager to load data
    task.wait(3)
    local data = PlayerDataService.get(player)
    if data and data.owned_plot then
        claimedPlots[data.owned_plot] = player.Name
        updatePlotSigns()
        print("[PlotManager] Restored " .. player.Name .. "'s plot: " .. data.owned_plot)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    -- Release plot claim from memory (data saves to DataStore via DataManager)
    for k, v in pairs(claimedPlots) do
        if v == player.Name then claimedPlots[k] = nil end
    end
    updatePlotSigns()
end)

print("[PlotManager] Ready - 4 plots available")
