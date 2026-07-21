--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local FishingService = require(ServerScriptService.Services.FishingService)

return function(world)
	FishingService.step(world)
end
