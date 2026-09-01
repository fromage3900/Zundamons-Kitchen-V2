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
	-- Depth progression (see ZundaroomsConfig): deeper runs are longer,
	-- faster, and pay more. All per-session so mid-run config edits and
	-- fragment speed penalties never leak across sessions.
	depth: number,
	segmentCount: number,
	entitySpeed: number,
	timeout: number,
	-- Memory fragments picked up THIS run. Only persisted on escape.
	fragmentsCollected: { string },
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

-- Depth = how far this player has pushed into the rooms. Derived from
-- persisted escapes, clamped by config. Depth 0 == the original encounter.
local function depthFor(player: Player): number
	local data = PlayerDataService.get(player)
	local escapes = data and (data.zundarooms_escapes or 0) or 0
	return math.clamp(escapes, 0, Config.maxDepth)
end

-- Pick fragment memories for a run, preferring lore the player has not
-- recovered yet so the collection fills out across runs.
local function pickMemories(player: Player, count: number): { { id: string, text: string } }
	local data = PlayerDataService.get(player)
	local seen: { [string]: boolean } = {}
	if data and data.zundarooms_memories then
		for _, id in ipairs(data.zundarooms_memories) do
			seen[id] = true
		end
	end
	local fresh = {}
	local dupes = {}
	for _, memory in ipairs(Config.memories) do
		table.insert(seen[memory.id] and dupes or fresh, memory)
	end
	local pool = {}
	for _, list in { fresh, dupes } do
		-- Fisher-Yates within each tier; fresh lore always outranks dupes.
		for i = #list, 2, -1 do
			local j = math.random(i)
			list[i], list[j] = list[j], list[i]
		end
		for _, memory in ipairs(list) do
			table.insert(pool, memory)
		end
	end
	local picked = {}
	for i = 1, math.min(count, #pool) do
		table.insert(picked, pool[i])
	end
	return picked
end

-- Spawn the run's picked memory fragments along the corridor. Each fragment
-- is a top-level neon cover with a SurfaceGui label that survives the whole
-- run and pays gold/XP + speeds the entity on pickup. The entity's base speed
-- is passed in so the fragment can compute the per-run speed penalty without
-- reaching back into Config.
local function CreateFragments(
	folder: Instance,
	slotX: number,
	corridorLength: number,
	runtime: Instance,
	runMemories: { { id: string, text: string } }
): { Model }
	local pickups: { Model } = {}
	local spacing = corridorLength / math.max(1, #runMemories)
	for i, memory in ipairs(runMemories) do
		local offset = (i - 1 + 0.5) * spacing
		local z = offset - corridorLength / 2
		local cover = Instance.new("Part")
		cover.Name = "Fragment_" .. memory.id
		cover.Size = Vector3.new(1.2, 1.2, 3)
		cover.CFrame = CFrame.new(Vector3.new(slotX, Config.roomY, z))
		cover.Anchored = true
		cover.CanCollide = false
		cover.CanQuery = false
		cover.Material = Enum.Material.Neon
		cover.Color = Color3.fromRGB(220, 235, 200)
		cover.Transparency = 0.0
		cover.Parent = folder

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.Adornee = cover
		gui.LightInfluence = 0.0
		gui.Parent = cover

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -4, 0, 32)
		label.Position = UDim2.new(0, 4, 0, 4)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(18, 20, 14)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 12
		label.TextWrapped = true
		label.Text = memory.text
		label.Parent = gui

		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(220, 235, 200)
		glow.Range = 6
		glow.Parent = cover

		local idx = #pickups + 1
		pickups[idx] = cover
	end
	return pickups
end

-- Pick up one fragment: read the memory id from the part name, record it in the
-- session's collected set, award gold/XP immediately, and speed the entity for
-- the rest of this run. Fragment visuals are NOT re-parented across sessions, so
-- session.entitySpeed is the authoritative per-session speed to add the bonus to.
local function PickupFragment(session: Session, fragment: Instance)
	if not session.fragmentsCollected then
		session.fragmentsCollected = {}
	end
	-- names are "Fragment_<id>" (e.g. "Fragment_hum")
	local memoryId = fragment.Name:match("^Fragment_(.+)$")
	if not memoryId then
		return
	end
	if table.find(session.fragmentsCollected, memoryId) then
		return
	end
	table.insert(session.fragmentsCollected, memoryId)
	-- immediate reward (fair even if the player gets caught later)
	local payload = {
		gold = Config.fragmentGold,
		xp = Config.fragmentXP,
		reason = "zundarooms_fragment",
		popupItem = "Zundarooms Memory",
	}
	RewardCore.settle(session.player, payload, function(data)
		data.zundarooms_escapes = data.zundarooms_escapes or 0
		return true
	end)
	-- speed the entity for the rest of this run
	session.entitySpeed = session.entitySpeed + Config.fragmentEntitySpeedBonus
	-- destroy the visual so it does not double-collect
	if fragment.Parent then
		fragment:Destroy()
	end
end

-- Clear any leftover fragment visuals from a session that ends without an
-- escape (caught / timeout / leave / retry). Runs from cleanup AFTER the
-- room folder is destroyed, so it operates on session.fragmentsCollected
-- ids and re-derives the parts from the destroyed folder's former children.
local function ClearFragments(session: Session)
	-- session.fragmentsCollected holds ids, but the visual parts are gone
	-- once session.room is destroyed. This is a no-op on the happy path;
	-- kept for correctness if future code re-parents fragments out of the
	-- room before destruction.
	if not session.room.Parent then
		return
	end
	for _, child in ipairs(session.room:GetChildren()) do
		if child.Name:match("^Fragment_") then
			child:Destroy()
		end
	end
end

local ZundaroomsCollectionHistory = {}
function ZundaroomsCollectionHistory.merge(session: Session)
	local data = PlayerDataService.get(session.player)
	if not data then
		return
	end
	data.zundarooms_memories = data.zundarooms_memories or {}
	for _, id in ipairs(session.fragmentsCollected) do
		if not table.find(data.zundarooms_memories, id) then
			table.insert(data.zundarooms_memories, id)
		end
	end
end

local function cleanup(userId: number)
	local session = sessions[userId]
	if not session then
		return
	end
	sessions[userId] = nil
	ClearFragments(session)
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
		local escapedMemories: { { id: string, text: string } } = {}
		for _, id in ipairs(session.fragmentsCollected) do
			for _, m in ipairs(Config.memories) do
				if m.id == id then
					table.insert(escapedMemories, m)
					break
				end
			end
		end
		statusEvent:FireClient(session.player, "escaped", escapedMemories)
		returnPlayer(session)
		cleanup(session.player.UserId)
		return
	end
	statusEvent:FireClient(session.player, "caught")
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
	part(
		folder,
		"Floor",
		Vector3.new(Config.roomWidth, 1, Config.roomLength),
		CFrame.new(center),
		Color3.fromRGB(70, 66, 56),
		0
	)
	part(
		folder,
		"Ceiling",
		Vector3.new(Config.roomWidth, 1, Config.roomLength),
		CFrame.new(center + Vector3.new(0, 10, 0)),
		wallColor,
		0
	)
	part(
		folder,
		"LeftWall",
		Vector3.new(1, 10, Config.roomLength),
		CFrame.new(center + Vector3.new(-Config.roomWidth / 2, 5, 0)),
		wallColor,
		0
	)
	part(
		folder,
		"RightWall",
		Vector3.new(1, 10, Config.roomLength),
		CFrame.new(center + Vector3.new(Config.roomWidth / 2, 5, 0)),
		wallColor,
		0
	)

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
	local depth = depthFor(player)
	-- Run geometry from config, then pushed out by depth. Entity speed and
	-- timeout are per-session fields so mid-run config edits do not touch
	-- a running player, and the fragment speed penalty is local to this run.
	local segmentCount = Config.segmentCount + math.max(0, depth * Config.depthSegmentsPerLevel)
	local entitySpeed = Config.entitySpeed + depth * Config.depthEntitySpeedPerLevel
	-- Extra head start for a longer corridor, so the entity is never unfairly
	-- faster on deeper runs just because the corridor grew.
	local timeout = Config.sessionTimeout
		+ math.max(0, segmentCount - Config.segmentCount) * Config.depthTimeoutPerSegment
	local slot = player.UserId % 1000
	local slotX = slot * (Config.roomWidth * (segmentCount + 2))
	local folder = Instance.new("Folder")
	folder.Name = "Room_" .. player.UserId
	folder.Parent = runtime

	local prefab = getSegmentPrefab()
	local corridorLength = Config.roomLength * segmentCount
	for segIndex = 0, segmentCount - 1 do
		buildSegment(folder, slotX, segIndex * Config.roomLength, prefab)
	end

	-- Memory fragments spawned mid-corridor. Touching one pays gold/XP and
	-- speeds the entity for the rest of the run (it notices you). Picked from
	-- the player's incompleted set so the fragment collection fills out across
	-- runs rather than repeatedly dropping the same ones.
	-- Session starts with an EMPTY collected set so the first touch actually
	-- pays gold/XP + speeds the entity (see PickupFragment for the guard).
	local runMemories = pickMemories(player, Config.fragmentsPerRun)
	local picked = CreateFragments(folder, slotX, corridorLength, runtime, runMemories)

	-- The catchDistance is unchanged between runs.
	local catchDistance = Config.catchDistance

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
	local session: Session = {
		player = player,
		origin = origin,
		room = folder,
		entity = entity,
		exit = exit,
		startedAt = now,
		lastStepAt = now,
		depth = depth,
		segmentCount = segmentCount,
		entitySpeed = entitySpeed,
		timeout = timeout,
		catchDistance = catchDistance,
		-- The run's picked memories: full text pairs, so the escape result
		-- can persist both ids and the text once for the in-game journal.
		fragmentsCollected = {},
	}
	exit.Touched:Connect(function(hit)
		local touchingPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if touchingPlayer == player then
			finish(session, "escaped")
		end
	end)
	-- fragment touch attribution (distinguish player touches from tag overlap)
	local fragmentTouches: { [Instance]: boolean } = {}
	for _, f in ipairs(picked) do
		f.Touched:Connect(function(hit)
			local touchingPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if touchingPlayer and touchingPlayer == player and not fragmentTouches[f] then
				fragmentTouches[f] = true
				PickupFragment(session, f)
			end
		end)
	end
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
		if offset.Magnitude <= session.catchDistance then
			finish(session, "caught")
		elseif now - session.startedAt >= session.timeout then
			finish(session, "timeout")
		elseif offset.Magnitude > 0 then
			session.entity.CFrame =
				CFrame.lookAt(session.entity.Position + offset.Unit * session.entitySpeed * dt, root.Position)
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
