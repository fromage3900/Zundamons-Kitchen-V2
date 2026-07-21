local ZundamonSync = {}
local playerStates = {}
local listeners = {}

function ZundamonSync.getState(player)
	local userId = player.UserId
	if not playerStates[userId] then
		playerStates[userId] = {
			companionType = "zundamon",
			position = Vector3.new(),
			animation = "idle",
			emotion = "neutral",
			buff = nil,
			dialogue = {},
			meshModifiers = {},
		}
	end
	return playerStates[userId]
end

function ZundamonSync.setState(player, key, value)
	local state = ZundamonSync.getState(player)
	state[key] = value
	for _, listener in ipairs(listeners) do
		pcall(listener, player, key, value)
	end
	return state
end

function ZundamonSync.setModifier(player, modifierName, params)
	local state = ZundamonSync.getState(player)
	state.meshModifiers[modifierName] = params
	for _, listener in ipairs(listeners) do
		pcall(listener, player, "meshModifiers", state.meshModifiers)
	end
end

function ZundamonSync.removeModifier(player, modifierName)
	local state = ZundamonSync.getState(player)
	state.meshModifiers[modifierName] = nil
	for _, listener in ipairs(listeners) do
		pcall(listener, player, "meshModifiers", state.meshModifiers)
	end
end

function ZundamonSync.onChange(callback)
	table.insert(listeners, callback)
end

function ZundamonSync.clear(player)
	playerStates[player.UserId] = nil
end

function ZundamonSync.getAllStates()
	local result = {}
	for userId, state in pairs(playerStates) do
		result[userId] = state
	end
	return result
end

return ZundamonSync
