--!strict
-- CompanionStats: quest counters for companion and NPC dialogue interactions.

local PlayerDataService = require(script.Parent.PlayerDataService)
local CompanionConfig = require(game.ReplicatedStorage.ConfigurationFiles.CompanionConfig)

local CompanionStats = {}

local function ensureStats(data: { [string]: any })
	if not data.stats then
		data.stats = {
			perfectCooks = 0,
			companion_chats = 0,
			npc_chats = 0,
		}
	end
end

function CompanionStats.recordCompanionChat(player: Player)
	local data = PlayerDataService.getOrCreate(player)
	ensureStats(data)
	data.stats.companion_chats = (data.stats.companion_chats or 0) + 1
end

function CompanionStats.recordNpcChat(player: Player, speakerKey: string): boolean
	if not CompanionConfig.npcSpeakers[speakerKey] then
		return false
	end
	local data = PlayerDataService.getOrCreate(player)
	ensureStats(data)
	data.stats.npc_chats = (data.stats.npc_chats or 0) + 1
	return true
end

return CompanionStats
