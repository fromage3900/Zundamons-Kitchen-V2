--!strict
-- Compatibility wrapper; authoritative behavior lives in CookingService.
local ServerScriptService = game:GetService("ServerScriptService")
local CookingService = require(ServerScriptService.Services.CookingService)

return setmetatable({}, {
	__call = function(_, world)
		CookingService.step(world)
	end,
})
