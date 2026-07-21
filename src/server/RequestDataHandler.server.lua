-- [[Script] RequestDataHandler (ref: RBX503CB1D186324F68A761F54B1BC9D8FE)]]
-- Returns a filtered copy of player materials data for client UIs.

local RS = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

local RF = RS:WaitForChild("RemoteFunctions")
local requestData = RF:FindFirstChild("RequestData") or Instance.new("RemoteFunction")
requestData.Name = "RequestData"
requestData.Parent = RF

local HIDDEN = {
	recipes_unlocked = true,
	cosmetics_unlocked = true,
	furniture_unlocked = true,
	locations_unlocked = true,
	owned_clothing = true,
	owned_decorations = true,
	recipes_served_count = true,
	tools = true,
	keybinds = true,
}

requestData.OnServerInvoke = function(player)
	local d = PlayerDataService.get(player)
	if not d then
		return {}
	end

	local out = {}
	for k, v in pairs(d) do
		if not HIDDEN[k] then
			out[k] = v
		end
	end
	return out
end

print("[RequestDataHandler] Ready")
