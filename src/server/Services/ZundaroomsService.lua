--!strict
-- Small server-owned escape encounter. Rooms are runtime-only and never alter
-- Studio-authored geometry; designers opt in by tagging entrance parts.

local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.ConfigurationFiles.ZundaroomsConfig)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RewardCore = require(ServerScriptService.Services.RewardCore)
local statusEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ZundaroomsStatus") :: RemoteEvent

type Session = {
	player: Player,
	origin: CFrame,
	room: Folder,
	entity: BasePart,
	exit: BasePart,
	startedAt: number,
	lastStepAt: number,
}

local ZundaroomsService = {}
local sessions: { [number]: Session } = {}
local entryDebounce: { [number]: number } = {}
local boundEntries: { [Instance]: boolean } = setmetatable({}, { __mode = "k" })
local started = false
local runtime = workspace:FindFirstChild("ZundaroomsRuntime") or Instance.new("Folder")
runtime.Name = "ZundaroomsRuntime"
runtime.Parent = workspace

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	transparency: number
): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cframe
	item.Anchored = true
	item.CanCollide = true
	item.Color = color
	item.Material = Enum.Material.SmoothPlastic
	item.Transparency = transparency
	item.Parent = parent
	return item
end

local function loadEntityVisual(): Model?
	local replicatedModels = ReplicatedStorage:FindFirstChild("Models")
	local authored = ServerStorage:FindFirstChild("ZundaroomsEntity")
		or (replicatedModels and replicatedModels:FindFirstChild("ZundaroomsEntity"))
	local loaded: Instance? = nil
	if authored and authored:IsA("Model") then
		loaded = authored:Clone()
	elseif Config.entityModelAssetId ~= "" then
		local numericId = tonumber(string.match(Config.entityModelAssetId, "%d+"))
		if numericId then
			local ok, result = pcall(function()
				return InsertService:LoadAsset(numericId)
			end)
			if ok then
				loaded = result
			end
		end
	end
	if not loaded or not loaded:IsA("Model") then
		return nil
	end
	for _, descendant in loaded:GetDescendants() do
		if
			descendant:IsA("LuaSourceContainer")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("ClickDetector")
			or descendant:IsA("ProximityPrompt")
		then
			descendant:Destroy()
		end
	end
	if not loaded:FindFirstChildWhichIsA("BasePart", true) then
		loaded:Destroy()
		return nil
	end
	return loaded
end

local function attachEntityVisual(entity: BasePart, room: Instance)
	local visual = loadEntityVisual()
	if not visual then
		return
	end
	visual.Name = "ZundaroomsEntityVisual"
	visual.Parent = room
	if Config.entityVisualScale ~= 1 then
		visual:ScaleTo(Config.entityVisualScale)
	end
	visual:PivotTo(entity.CFrame * Config.entityVisualOffset)
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = entity
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
	entity.Transparency = 1
end

local function addUnique(list: { any }, value: any)
	if not table.find(list, value) then
		table.insert(list, value)
	end
end

local function unlocked(player: Player): boolean
	local data = PlayerDataService.get(player)
	return data ~= nil
		and (
			(data.guests_served or 0) >= Config.unlockGuestsServed
			or table.find(data.locations_unlocked or {}, "Zundarooms") ~= nil
		)
end

local function cleanup(userId: number)
	local session = sessions[userId]
	if not session then
		return
	end
	sessions[userId] = nil
	if session.room.Parent then
		session.room:Destroy()
	end
end

local function returnPlayer(session: Session)
	local character = session.player.Character
	if character and character.Parent then
		character:PivotTo(session.origin)
	end
end

local function finish(session: Session, outcome: string)
	if sessions[session.player.UserId] ~= session then
		return
	end
	if outcome == "escaped" then
		RewardCore.settle(session.player, {
			gold = Config.escapeGold,
			xp = Config.escapeXP,
			reason = "zundarooms_escape",
			popupItem = "Zundarooms Memory",
		}, function(data)
			data.zundarooms_escapes = (data.zundarooms_escapes or 0) + 1
			data.zones_visited = data.zones_visited or {}
			data.zones_visited.Zundarooms = true
			data.locations_unlocked = data.locations_unlocked or {}
			addUnique(data.locations_unlocked, "Zundarooms")
			return true
		end)
	end
	statusEvent:FireClient(session.player, outcome)
	returnPlayer(session)
	cleanup(session.player.UserId)
end

-- Studio-authored corridor segment override -- same prefab-first convention
-- as AssetLibrary.Companions / AssetLibrary.ResourceNodes established
-- elsewhere. Falls back to the procedural box below when absent, so an empty
-- catalog never blocks play.
local function getSegmentPrefab(): Model?
	local assetLibrary = ServerStorage:FindFirstChild("AssetLibrary")
	local zundarooms = assetLibrary and assetLibrary:FindFirstChild("Zundarooms")
	local prefab = zundarooms and zundarooms:FindFirstChild("RoomSegment")
	if prefab and prefab:IsA("Model") then
		return prefab
	end
	return nil
end

-- Sparse flickering fixtures instead of even room light -- the unevenness and
-- buzzing is a core part of the liminal-space read.
local function addFlickerLight(parent: Instance, position: Vector3)
	local fixture = Instance.new("Part")
	fixture.Name = "LightFixture"
	fixture.Size = Vector3.new(2, 0.3, 2)
	fixture.Position = position
	fixture.Anchored = true
	fixture.CanCollide = false
	fixture.CanQuery = false
	fixture.Material = Enum.Material.Neon
	fixture.Color = Color3.fromRGB(235, 230, 200)
	fixture.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(235, 225, 190)
	light.Range = 18
	light.Brightness = Config.fixtureFlickerMax
	light.Parent = fixture

	task.spawn(function()
		while fixture.Parent do
			light.Brightness = Config.fixtureFlickerMin
				+ math.random() * (Config.fixtureFlickerMax - Config.fixtureFlickerMin)
			task.wait(math.random() < 0.15 and 0.05 or math.random(1, 3))
		end
	end)
end

-- One corridor segment: floor/ceiling/side walls (procedural, always built as
-- the collision safety net) plus the authored visual overlay if a
-- RoomSegment prefab exists. baseZ is this segment's near (start) edge.
local function buildSegment(folder: Instance, slotX: number, baseZ: number, prefab: Model?)
	local center = Vector3.new(slotX, Config.roomY, baseZ + Config.roomLength / 2)
	local wallColor = Color3.fromRGB(90, 88, 78)
	part(folder, "Floor", Vector3.new(Config.roomWidth, 1, Config.roomLength), CFrame.new(center), Color3.fromRGB(70, 66, 56), 0)
	part(folder, "Ceiling", Vector3.new(Config.roomWidth, 1, Config.roomLength), CFrame.new(center + Vector3.new(0, 10, 0)), wallColor, 0)
	part(folder, "LeftWall", Vector3.new(1, 10, Config.roomLength), CFrame.new(center + Vector3.new(-Config.roomWidth / 2, 5, 0)), wallColor, 0)
	part(folder, "RightWall", Vector3.new(1, 10, Config.roomLength), CFrame.new(center + Vector3.new(Config.roomWidth / 2, 5, 0)), wallColor, 0)

	local fixturesPerSegment = math.max(1, math.floor(Config.roomLength / Config.fixtureSpacing))
	for i = 1, fixturesPerSegment do
		local z = baseZ + (i - 0.5) * (Config.roomLength / fixturesPerSegment)
		addFlickerLight(folder, Vector3.new(slotX, Config.roomY + 9.5, z))
	end

	if prefab then
		local visual = prefab:Clone()
		visual.Name = "SegmentVisual"
		visual:PivotTo(CFrame.new(center))
		visual.Parent = folder
		for _, descendant in visual:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
			end
		end
	end
end

local function createRoom(player: Player, origin: CFrame): Session
	local slot = player.UserId % 1000
	local slotX = slot * (Config.roomWidth * (Config.segmentCount + 2))
	local folder = Instance.new("Folder")
	folder.Name = "Room_" .. player.UserId
	folder.Parent = runtime

	local prefab = getSegmentPrefab()
	local corridorLength = Config.roomLength * Config.segmentCount
	for segIndex = 0, Config.segmentCount - 1 do
		buildSegment(folder, slotX, segIndex * Config.roomLength, prefab)
	end

	local backWall = part(
		folder,
		"BackWall",
		Vector3.new(Config.roomWidth, 10, 1),
		CFrame.new(Vector3.new(slotX, Config.roomY, 0)),
		Color3.fromRGB(90, 88, 78),
		0
	)
	backWall.CFrame = backWall.CFrame * CFrame.new(0, 5, 0)

	local exit = part(
		folder,
		"Escape",
		Vector3.new(8, 9, 1),
		CFrame.new(Vector3.new(slotX, Config.roomY + 4.5, corridorLength - 2)),
		Color3.fromRGB(210, 225, 170),
		0.2
	)
	exit.CanCollide = false
	-- Entity starts a fixed handicap behind the player, not deep in a separate
	-- room -- with a corridor this long, starting it near the far exit again
	-- would give a trivially long head start.
	local entity = part(
		folder,
		"UnidentifiedEntity",
		Vector3.new(4, 7, 4),
		CFrame.new(Vector3.new(slotX, Config.roomY + 3.5, -12)),
		Color3.fromRGB(8, 8, 8),
		0.08
	)
	entity.Shape = Enum.PartType.Ball
	entity.CanCollide = false
	attachEntityVisual(entity, folder)
	local now = os.clock()
	local session = {
		player = player,
		origin = origin,
		room = folder,
		entity = entity,
		exit = exit,
		startedAt = now,
		lastStepAt = now,
	}
	exit.Touched:Connect(function(hit)
		local touchingPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if touchingPlayer == player then
			finish(session, "escaped")
		end
	end)
	return session
end

function ZundaroomsService.enter(player: Player): (boolean, string)
	if sessions[player.UserId] then
		return false, "session_active"
	end
	if not unlocked(player) then
		statusEvent:FireClient(player, "locked")
		return false, "locked"
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false, "character_unavailable"
	end
	local session = createRoom(player, character:GetPivot())
	sessions[player.UserId] = session
	-- Begin a short distance ahead of the entity's handicap spawn (not at a
	-- named "Floor" part -- segments now share that name across the corridor).
	character:PivotTo(session.entity.CFrame * CFrame.new(0, 0, 20))
	statusEvent:FireClient(player, "entered")
	return true, "entered"
end

local function bindEntrance(entrance: Instance)
	if boundEntries[entrance] or not entrance:IsA("BasePart") then
		return
	end
	boundEntries[entrance] = true
	entrance.CanTouch = true
	entrance.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local now = os.clock()
		if now - (entryDebounce[player.UserId] or 0) < 2 then
			return
		end
		entryDebounce[player.UserId] = now
		ZundaroomsService.enter(player)
	end)
end

function ZundaroomsService.start(): boolean
	if started then
		return false
	end
	started = true
	for _, entrance in ipairs(CollectionService:GetTagged("ZundaroomsEntrance")) do
		bindEntrance(entrance)
	end
	CollectionService:GetInstanceAddedSignal("ZundaroomsEntrance"):Connect(bindEntrance)
	if #CollectionService:GetTagged("ZundaroomsEntrance") == 0 then
		local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawn then
			local fallback = part(
				runtime,
				"UnstableWall",
				Vector3.new(6, 8, 1),
				spawn.CFrame + Vector3.new(18, 4, 0),
				Color3.fromRGB(116, 133, 86),
				0.55
			)
			fallback.CanCollide = false
			CollectionService:AddTag(fallback, "ZundaroomsEntrance")
		end
	end
	return true
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for userId, session in pairs(sessions) do
		local character = session.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
			finish(session, "caught")
			continue
		end
		local dt = math.clamp(now - session.lastStepAt, 0, 0.1)
		session.lastStepAt = now
		local offset = root.Position - session.entity.Position
		if offset.Magnitude <= Config.catchDistance then
			finish(session, "caught")
		elseif now - session.startedAt >= Config.sessionTimeout then
			finish(session, "timeout")
		elseif offset.Magnitude > 0 then
			session.entity.CFrame =
				CFrame.lookAt(session.entity.Position + offset.Unit * Config.entitySpeed * dt, root.Position)
		end
		if not sessions[userId] then
			continue
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cleanup(player.UserId)
	entryDebounce[player.UserId] = nil
end)

return ZundaroomsService
