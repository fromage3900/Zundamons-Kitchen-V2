-- [[LocalScript] PeaWheelBootstrap]]
-- Verifies that all Pea Wheel action callbacks are registered.
-- Panel scripts now register their own callbacks with ActionRegistry directly,
-- so this bootstrap no longer attempts to require() LocalScripts (which return nil).

local Players = game:GetService("Players")
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local ActionRegistry = require(playerScripts:WaitForChild("ConfigurationFiles"):WaitForChild("UIActionRegistry"))

local EXPECTED_ACTIONS = {
	"inventory",
	"cook",
	"quests",
	"compendium",
	"materials",
	"map",
	"companions",
	"settings",
}

local function verifyCallbacks()
	local allRegistered = true
	for _, actionId in ipairs(EXPECTED_ACTIONS) do
		local def = ActionRegistry.getAction(actionId)
		if def and type(def.callback) == "function" then
			print("[PeaWheelBootstrap] ✓ " .. actionId .. " callback registered")
		else
			warn("[PeaWheelBootstrap] ✗ " .. actionId .. " callback NOT registered")
			allRegistered = false
		end
	end
	if allRegistered then
		print("[PeaWheelBootstrap] All action callbacks verified ✓")
	else
		warn("[PeaWheelBootstrap] Some callbacks missing — panels may not be loaded yet")
	end
	return allRegistered
end

-- Panel scripts load asynchronously; poll until all callbacks are registered
task.spawn(function()
	for i = 1, 20 do
		task.wait(0.25)
		if verifyCallbacks() then
			break
		end
	end
end)

print("[PeaWheelBootstrap] Verification started — panels register callbacks directly")
