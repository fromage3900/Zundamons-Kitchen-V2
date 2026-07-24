--!strict
-- Ambient NPC patrol system. Spawns NPCs at PatrolSpawn-tagged parts
-- and moves them between PatrolPoint-tagged waypoints.
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenS = TweenService

local NPC_LIST = {
	{ name = "Traveler_01", color = Color3.fromRGB(180, 120, 80) },
	{ name = "Traveler_02", color = Color3.fromRGB(100, 180, 220) },
	{ name = "Traveler_03", color = Color3.fromRGB(220, 160, 100) },
	{ name = "Merchant_01", color = Color3.fromRGB(200, 180, 60) },
}

local activePatrols = {}

local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local npcChatTimestamps = {}

local openMerchantShopEv
do
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	openMerchantShopEv = remotes and remotes:FindFirstChild("OpenMerchantShop")
end

local function createNPCModel(npcDef)
	local model = Instance.new("Model")
	model.Name = npcDef.name
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = npcDef.color
	torso.Anchored = false
	torso.CanCollide = false
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = npcDef.color
	head.Anchored = false
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Position = Vector3.new(0, 1.6, 0)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = head
	weld.Parent = torso
	model.PrimaryPart = torso

	-- These NPCs previously had no interaction surface at all -- QuestManager
	-- tracks "talk to an NPC" objectives via data.npc_chats[name], normally
	-- incremented from a client-fired RemoteEvent. ClickDetector.MouseClick
	-- already fires server-side with the clicking player, so we record the
	-- same data directly here rather than firing a client->server event to
	-- ourselves (which isn't how RemoteEvents work from the server).
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 12
	cd.Parent = torso
	cd.MouseClick:Connect(function(player)
		local now = os.clock()
		local last = npcChatTimestamps[player]
		if last and now - last < 2 then
			return
		end
		npcChatTimestamps[player] = now
		local d = PlayerDataService.getOrCreate(player)
		d.npc_chats = d.npc_chats or {}
		d.npc_chats[npcDef.name] = (d.npc_chats[npcDef.name] or 0) + 1

		-- Merchant_01 opens the existing Furniture Shop (FurniturePlacement.client.lua,
		-- normally toggled with H) rather than a new shop UI.
		if npcDef.name == "Merchant_01" and openMerchantShopEv then
			openMerchantShopEv:FireClient(player)
		end
	end)

	return model
end

local function getWaypoints()
	local tagged = CollectionService:GetTagged("PatrolPoint")
	if #tagged == 0 then
		return {}
	end
	local pts = {}
	for _, p in ipairs(tagged) do
		if p:IsA("BasePart") then
			table.insert(pts, p.Position)
		end
	end
	return pts
end

local function getSpawnPoints()
	local tagged = CollectionService:GetTagged("PatrolSpawn")
	if #tagged == 0 then
		local gameplayArea = Workspace:FindFirstChild("GameplayLoopArea")
		if gameplayArea then
			local center = gameplayArea:GetAttribute("Center") or gameplayArea:FindFirstChild("CenterPart")
			if center and center:IsA("BasePart") then
				return { center.Position + Vector3.new(0, 2, 0) }
			end
			return { Vector3.new(200, -515, -410) }
		end
		return { Vector3.new(200, -515, -410) }
	end
	local pts = {}
	for _, p in ipairs(tagged) do
		if p:IsA("BasePart") then
			table.insert(pts, p.Position)
		end
	end
	return pts
end

local function moveToWaypoint(model, targetPos, speed)
	local torso = model.PrimaryPart
	if not torso then return end
	local dist = (targetPos - torso.Position).Magnitude
	if dist < 2 then return end
	local duration = dist / (speed or 6)
	local goal = { Position = targetPos }
	local tween = TweenS:Create(torso, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
	tween:Play()
	tween.Completed:Once(function()
		table.insert(activePatrols[model.Name] or {}, model.Name .. "_arrived")
	end)
	return tween
end

local function patrolLoop(model, waypoints)
	if #waypoints == 0 then return end
	local wpIdx = 1
	while model and model.Parent do
		local target = waypoints[wpIdx]
		moveToWaypoint(model, target, 5)
		task.wait((target - model.PrimaryPart.Position).Magnitude / 5)
		wpIdx = wpIdx % #waypoints + 1
		task.wait(math.random(2, 5))
	end
end

-- Guest roaming: move a guest NPC within a radius or between waypoints
local function guestRoamLoop(guest, personality)
	local torso = guest:FindFirstChild("Torso")
	if not torso then return end
	local spawnPos = torso.Position
	local waypoints = getWaypoints()
	
	while guest and guest.Parent and torso.Parent do
		if personality == "roamer" then
			-- Wander within a 12-stud radius of spawn
			local angle = math.random() * 2 * math.pi
			local radius = math.random(3, 12)
			local target = spawnPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			moveToWaypoint(guest, target, 3)
			task.wait(math.random(4, 10))
		elseif personality == "patrol" and #waypoints > 0 then
			-- Follow patrol waypoints
			local wp = waypoints[math.random(1, #waypoints)]
			moveToWaypoint(guest, wp, 4)
			task.wait(math.random(5, 12))
		end
		task.wait(1)
	end
end

-- Expose for GuestManager
local NPCPatrolSystem = {}
NPCPatrolSystem.startGuestRoaming = function(guest, personality)
	task.spawn(function()
		guestRoamLoop(guest, personality)
	end)
end

local function spawnPatrolNPCs()
	local waypoints = getWaypoints()
	if #waypoints == 0 then
		print("[NPCPatrol] No PatrolPoint waypoints found — skipping patrol spawn")
		return
	end
	local spawnPoints = getSpawnPoints()
	for i, npcDef in ipairs(NPC_LIST) do
		local spawnPos = spawnPoints[(i - 1) % #spawnPoints + 1]
		local model = createNPCModel(npcDef)
		local torso = model.PrimaryPart
		torso.Position = spawnPos
		torso.Anchored = false
		model.Parent = Workspace
		task.spawn(function()
			patrolLoop(model, waypoints)
		end)
	end
	print("[NPCPatrol] Spawned " .. #NPC_LIST .. " patrol NPCs with " .. #waypoints .. " waypoints")
end

task.delay(5, spawnPatrolNPCs)

CollectionService:GetInstanceAddedSignal("PatrolPoint"):Connect(function()
	task.delay(2, spawnPatrolNPCs)
end)

return NPCPatrolSystem
