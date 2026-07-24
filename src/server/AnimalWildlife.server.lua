--!strict
-- Ambient decorative wildlife: turns the ~26 static "animal-*" meshes already
-- placed in the level (a stack of ~22 of them all sitting on top of each
-- other at one spawn point, plus a handful of already-scattered singles)
-- into gently-roaming ambient NPCs. Purely cosmetic -- no interaction,
-- damage, or server-authoritative gameplay, just life for the world and a
-- cheap way to make large lobbies feel populated.

local RunService = game:GetService("RunService")

local WANDER_RADIUS = 22       -- studs from each animal's home point
local WALK_SPEED = 4           -- studs/sec while moving between wander points
local IDLE_MIN, IDLE_MAX = 3, 9 -- seconds paused between wanders
local SCATTER_CENTER = Vector3.new(28, 0, -7)
local SCATTER_RADIUS = 170     -- spreads the stacked cluster across the map

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function findGroundY(x: number, z: number, exclude: { Instance }): number?
	raycastParams.FilterDescendantsInstances = exclude
	local result = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), raycastParams)
	return result and result.Position.Y
end

local function collectAnimalModels(): { Model }
	local models = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and string.sub(d.Name, 1, 7) == "animal-" then
			table.insert(models, d)
		end
	end
	return models
end

-- Detect the stacked cluster (many models sharing ~the same X/Z) vs the
-- already-placed singles (unique positions, respect existing level design).
local function isStacked(model: Model, allPivots: { [Model]: Vector3 }): boolean
	local pos = allPivots[model]
	local sameColumn = 0
	for _, p in pairs(allPivots) do
		if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude < 3 then
			sameColumn += 1
		end
	end
	return sameColumn >= 3
end

local function wander(model: Model, homeCFrame: CFrame)
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end

	task.spawn(function()
		-- Stagger start so ~26 animals don't all step in lockstep
		task.wait(math.random() * IDLE_MAX)
		while model.Parent do
			local angle = math.random() * math.pi * 2
			local dist = math.random() * WANDER_RADIUS
			local tx = homeCFrame.Position.X + math.cos(angle) * dist
			local tz = homeCFrame.Position.Z + math.sin(angle) * dist
			local groundY = findGroundY(tx, tz, parts)
			if groundY then
				local startCFrame = model:GetPivot()
				local goalPos = Vector3.new(tx, groundY, tz)
				local flatDir = goalPos - startCFrame.Position
				flatDir = Vector3.new(flatDir.X, 0, flatDir.Z)
				local goalCFrame = (flatDir.Magnitude > 0.5)
					and CFrame.lookAt(goalPos, goalPos + flatDir.Unit)
					or CFrame.new(goalPos) * (startCFrame - startCFrame.Position)

				local travelDist = (Vector3.new(startCFrame.Position.X, 0, startCFrame.Position.Z) - Vector3.new(goalPos.X, 0, goalPos.Z)).Magnitude
				local duration = math.max(0.6, travelDist / WALK_SPEED)
				local t0 = os.clock()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					if not model.Parent then
						if conn then conn:Disconnect() end
						return
					end
					local alpha = math.clamp((os.clock() - t0) / duration, 0, 1)
					model:PivotTo(startCFrame:Lerp(goalCFrame, alpha))
					if alpha >= 1 and conn then
						conn:Disconnect()
					end
				end)
				task.wait(duration + 0.05)
			end
			task.wait(IDLE_MIN + math.random() * (IDLE_MAX - IDLE_MIN))
		end
	end)
end

local function setup()
	local models = collectAnimalModels()
	local pivots: { [Model]: Vector3 } = {}
	for _, m in ipairs(models) do
		local ok, piv = pcall(function() return m:GetPivot() end)
		if ok then pivots[m] = piv.Position end
	end

	local scattered, kept = 0, 0
	for _, m in ipairs(models) do
		if pivots[m] then
			local homeCFrame
			if isStacked(m, pivots) then
				-- Disperse: pick a random point in the scatter area, ground-snap it
				local angle = math.random() * math.pi * 2
				local dist = math.sqrt(math.random()) * SCATTER_RADIUS -- sqrt for uniform area density
				local x = SCATTER_CENTER.X + math.cos(angle) * dist
				local z = SCATTER_CENTER.Z + math.sin(angle) * dist
				local parts = {}
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then table.insert(parts, d) end
				end
				local groundY = findGroundY(x, z, parts)
				if groundY then
					homeCFrame = CFrame.new(x, groundY, z)
					m:PivotTo(homeCFrame)
					scattered += 1
				end
			else
				-- Already placed by hand -- roam around where it already is.
				homeCFrame = m:GetPivot()
				kept += 1
			end
			if homeCFrame then
				wander(m, homeCFrame)
			end
		end
	end

	print(("[AnimalWildlife] %d animals dispersed from the stacked spawn point, %d already-placed animals kept in position -- all now roaming"):format(scattered, kept))
end

task.spawn(setup)
