-- TimedCookingScript wrapper around CookingController
local Controllers = script.Parent:WaitForChild("Controllers")
local CookingController = require(Controllers:WaitForChild("CookingController"))

_G.TimedCooking = CookingController

return CookingController
