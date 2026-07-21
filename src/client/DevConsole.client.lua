-- [[LocalScript] DevConsole]]
-- In-game asset validation + debugging console
-- Checks UIAssets placeholders and reports issues

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RS = game:GetService("ReplicatedStorage")

-- Wait for UIAssets to load
local UIAssets = RS:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("UIAssets")
local UIAssetsModule = require(UIAssets)

-- Check for placeholder assets on startup
local function checkPlaceholders()
	local issues = {}

	-- Check icons
	for itemName, assetId in pairs(UIAssetsModule.icons) do
		if UIAssetsModule.isPlaceholder(assetId) then
			warn("[AssetCheck] Missing icon: " .. itemName)
			table.insert(issues, { type = "icon", name = itemName })
		end
	end

	-- Check sounds
	for soundName, assetId in pairs(UIAssetsModule.sounds) do
		if UIAssetsModule.isPlaceholder(assetId) then
			warn("[AssetCheck] Missing sound: " .. soundName)
			table.insert(issues, { type = "sound", name = soundName })
		end
	end

	-- Report to output
	if #issues > 0 then
		print("[DevConsole] Found " .. #issues .. " placeholder assets - check Output panel")
	else
		print("[DevConsole] All assets configured! ✅")
	end

	return issues
end

-- Run check when GUI loads
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	checkPlaceholders()
end)

print("[DevConsole] Asset checker loaded")
