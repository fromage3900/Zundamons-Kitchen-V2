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
