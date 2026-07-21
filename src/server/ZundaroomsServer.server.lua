--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ZundaroomsService = require(ServerScriptService.Services.ZundaroomsService)

if ZundaroomsService.start() then
	print("[Zundarooms] Mysterious escape encounter ready")
end
