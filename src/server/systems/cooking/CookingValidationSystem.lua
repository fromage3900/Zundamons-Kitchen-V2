--!strict
-- Matter requires scheduled systems to be functions, not callable tables.
local ServerScriptService = game:GetService("ServerScriptService")
local CookingValidation = require(ServerScriptService.Services.CookingValidationSystem)

return function(world)
	return CookingValidation(world)
end