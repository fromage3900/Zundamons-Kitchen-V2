-- [[Script] CompanionBuffServer (ref: RBXBECA557F11C442D2A370EE1018993A66)]
local RF = game.ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetActiveCompanionBuff = RF:WaitForChild("GetActiveCompanionBuff")
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local CompanionConfig = require(game.ReplicatedStorage.ConfigurationFiles.CompanionConfig)

GetActiveCompanionBuff.OnServerInvoke = function(player, stat)
	local d = PlayerDataService.get(player)
	if not d then
		return 0
	end
	local active = d.active_companion
	if not active then
		return 0
	end
	-- Resolve custom (player-created / AI-generated) companions from the
	-- player's data before falling back to the static catalog, so their buffs
	-- apply like any other companion's.
	local def
	if type(active) == "string" and string.sub(active, 1, 3) == "cc_" then
		local custom = d.custom_companions and d.custom_companions[active]
		if custom and type(custom) == "table" and custom.buff then
			def = custom
		end
	else
		def = CompanionConfig.companions[active]
	end
	if not def or not def.buff then
		return 0
	end
	if def.buff.stat == stat then
		return def.buff.magnitude
	end
	return 0
end

print("[CompanionBuffServer] ready")
