local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ZRStatus = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ZundaroomsStatus")

local SAMPLE_INTERVAL_S = 5

local previousEcho = rawget(_G, "PlaytestEcho")
if type(previousEcho) == "table" and type(previousEcho.stop) == "function" then
	pcall(previousEcho.stop)
end

local PlaytestEcho = {}

local running = false
local sessionId = nil
local startedAt = nil
local startedAtClock = nil
local stoppedDuration = 0
local samplerGeneration = 0
local messageConnection = nil
local errors = {}
local warnings = {}
local stateSamples = {}

local function roundSeconds(value)
	return math.floor(value * 1000 + 0.5) / 1000
end

local function elapsedSeconds()
	-- time() reads 0 in some Studio MCP execution contexts; os.clock() is reliable
	if startedAtClock == nil then
		return 0
	end

	if running then
		return math.max(0, os.clock() - startedAtClock)
	end

	return stoppedDuration
end

local function jsonSafeValue(value)
	local valueType = typeof(value)
	if valueType == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return tostring(value)
		end
		return value
	end

	if valueType == "string" or valueType == "boolean" then
		return value
	end

	if value == nil then
		return nil
	end

	return tostring(value)
end

local function readValueObject(valueObject)
	local ok, value = pcall(function()
		return valueObject.Value
	end)
	if not ok then
		return nil
	end

	return jsonSafeValue(value)
end

local function collectLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats == nil then
		return nil, nil
	end

	local values = {}
	local gold = nil
	for _, child in leaderstats:GetChildren() do
		if child:IsA("ValueBase") then
			local value = readValueObject(child)
			if value ~= nil then
				values[child.Name] = value
				if string.lower(child.Name) == "gold" then
					gold = value
				end
			end
		end
	end

	if next(values) == nil then
		values = nil
	end

	return values, gold
end

local function findPlayerGold(player)
	for attributeName, attributeValue in player:GetAttributes() do
		if string.lower(attributeName) == "gold" then
			return jsonSafeValue(attributeValue)
		end
	end

	for _, child in player:GetChildren() do
		if string.lower(child.Name) == "gold" and child:IsA("ValueBase") then
			return readValueObject(child)
		end
	end

	return nil
end

local function characterPosition(player)
	local character = player.Character
	if character == nil then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		local position = rootPart.Position
		return {
			x = jsonSafeValue(position.X),
			y = jsonSafeValue(position.Y),
			z = jsonSafeValue(position.Z),
		}
	end

	local ok, position = pcall(function()
		return character:GetPivot().Position
	end)
	if not ok then
		return nil
	end

	return {
		x = jsonSafeValue(position.X),
		y = jsonSafeValue(position.Y),
		z = jsonSafeValue(position.Z),
	}
end

local function samplePlayer(player)
	local leaderstats, gold = collectLeaderstats(player)
	if gold == nil then
		gold = findPlayerGold(player)
	end

	-- Zunda data path: server-authoritative projection via RequestPlayerState
	local projectionGold = nil
	local projectionRevision = nil
	local okProjection, rf = pcall(function()
		return game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions", 1)
			and game:GetService("ReplicatedStorage").RemoteFunctions:FindFirstChild("RequestPlayerState")
	end)
	if okProjection and rf then
		-- client contexts invoke via InvokeServer; server context reads the service directly
		local okSrv, PlayerDataService = pcall(function()
			return require(game:GetService("ServerScriptService").Services.PlayerDataService)
		end)
		if okSrv and PlayerDataService and PlayerDataService.getProjection then
			local okProj, proj = pcall(function()
				return PlayerDataService.getProjection(player)
			end)
			if okProj and type(proj) == "table" then
				projectionGold = proj.gold
				projectionRevision = proj.revision
			end
		end
	end

	if gold == nil then
		gold = projectionGold
	end

	local sample = {
		name = player.Name,
		user_id = player.UserId,
	}

	if leaderstats ~= nil then
		sample.leaderstats = leaderstats
	end
	if gold ~= nil then
		sample.gold = gold
	end
	if projectionRevision ~= nil then
		sample.data_revision = projectionRevision
	end

	local position = characterPosition(player)
	if position ~= nil then
		sample.position = position
	end

	return sample
end

local function captureStateSample()
	local playerSamples = {}
	for _, player in Players:GetPlayers() do
		local ok, sample = pcall(samplePlayer, player)
		if ok then
			table.insert(playerSamples, sample)
		end
	end

	table.sort(playerSamples, function(left, right)
		return left.user_id < right.user_id
	end)

	table.insert(stateSamples, {
		at_s = roundSeconds(elapsedSeconds()),
		players = playerSamples,
	})
end

local function inferScriptName(message)
	local firstLine = string.match(message, "^[^\r\n]*") or message
	local directName = string.match(firstLine, "^%s*(.-):%d+:%s")
	if directName and directName ~= "" then
		return directName
	end

	local stackName = string.match(message, "[Ss]cript ['\"]([^'\"]+)['\"]")
	if stackName and stackName ~= "" then
		return stackName
	end

	return "Unknown"
end

local function captureMessage(message, messageType)
	local destination = nil
	if messageType == Enum.MessageType.MessageError then
		destination = errors
	elseif messageType == Enum.MessageType.MessageWarning then
		destination = warnings
	end

	if destination == nil then
		return
	end

	table.insert(destination, {
		at_s = roundSeconds(elapsedSeconds()),
		message = message,
		script = inferScriptName(message),
	})
end

local function disconnectMessageListener()
	if messageConnection ~= nil then
		messageConnection:Disconnect()
		messageConnection = nil
	end
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in value do
		copy[key] = deepCopy(childValue)
	end
	return copy
end

function PlaytestEcho.start()
	if running then
		return sessionId
	end

	disconnectMessageListener()
	errors = {}
	warnings = {}
	stateSamples = {}
	sessionId = HttpService:GenerateGUID(false)
	startedAt = DateTime.now():ToIsoDate()
	startedAtClock = os.clock()
	stoppedDuration = 0
	running = true
	samplerGeneration += 1

	-- ZRStatus timeline buffer (client-context; server→client RE not heard in server context)
	if ZRStatus then
		_G.PlaytestEcho.zrEvents = {}
		_G.PlaytestEcho.zrConnection = ZRStatus.OnClientEvent:Connect(function(status, memories)
			table.insert(_G.PlaytestEcho.zrEvents, {
				at_s = roundSeconds(elapsedSeconds()),
				status = status,
				memories = memories,
			})
		end)
	end

	local generation = samplerGeneration
	messageConnection = LogService.MessageOut:Connect(captureMessage)
	captureStateSample()

	task.spawn(function()
		while running and generation == samplerGeneration do
			task.wait(SAMPLE_INTERVAL_S)
			if running and generation == samplerGeneration then
				captureStateSample()
			end
		end
	end)

	return sessionId
end

function PlaytestEcho.stop()
	if sessionId == nil then
		return nil
	end

	if running then
		stoppedDuration = math.max(0, os.clock() - startedAtClock)
		running = false
		samplerGeneration += 1
		disconnectMessageListener()

		-- disconnect ZRStatus listener
		if ZRStatus and _G.PlaytestEcho.zrConnection then
			_G.PlaytestEcho.zrConnection:Disconnect()
			_G.PlaytestEcho.zrConnection = nil
		end
	end

	return PlaytestEcho.dump()
end

function PlaytestEcho.dump()
	assert(sessionId ~= nil, "PlaytestEcho.start() must be called before dump()")

	local zrEvents = nil
	if ZRStatus and rawget(_G, "PlaytestEcho") == PlaytestEcho and _G.PlaytestEcho.zrEvents then
		zrEvents = deepCopy(_G.PlaytestEcho.zrEvents)
	end

	return {
		session_id = sessionId,
		started_at = startedAt,
		duration_s = roundSeconds(elapsedSeconds()),
		errors = deepCopy(errors),
		warnings = deepCopy(warnings),
		state_samples = deepCopy(stateSamples),
		zundarooms_status_events = zrEvents,
	}
end

_G.PlaytestEcho = PlaytestEcho

return PlaytestEcho
