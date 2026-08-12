-- [[Script] GuestManager (ref: RBX0F6550E0891E47F9B20D70EEFC302651)]]
-- GuestManager: Spawns and manages guest NPCs

local configFolder = game.ReplicatedStorage:FindFirstChild("ConfigurationFiles")
if not configFolder then
	configFolder = game.ReplicatedStorage:WaitForChild("ConfigurationFiles", 15)
end
local CONFIG = configFolder and require(configFolder:WaitForChild("ProgressionConfig", 10))
if not CONFIG then
	warn("[GuestManager] ProgressionConfig not found — guests disabled")
	return {}
end

local zoneAssets = workspace:FindFirstChild("ZoneAssets")
local guestTemplate = zoneAssets and zoneAssets:FindFirstChild("GuestTemplate")
	or workspace:WaitForChild("ZoneAssets", 15):WaitForChild("GuestTemplate", 10)

local GUEST_SPAWN_FOLDER = workspace:FindFirstChild("Guests") or Instance.new("Folder")
if not GUEST_SPAWN_FOLDER.Parent then
	GUEST_SPAWN_FOLDER.Name = "Guests"
	GUEST_SPAWN_FOLDER.Parent = workspace
end

local activeGuests = {} -- {guest_instance = {guest_model, player, recipe, timeout_thread}}
local guestIdCounter = 0

local remoteEventsFolder = game.ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
	remoteEventsFolder = Instance.new("Folder")
	remoteEventsFolder.Name = "RemoteEvents"
	remoteEventsFolder.Parent = game.ReplicatedStorage
end
if not remoteEventsFolder:FindFirstChild("ShowVNDialogue") then
	local vnEv = Instance.new("RemoteEvent")
	vnEv.Name = "ShowVNDialogue"
	vnEv.Parent = remoteEventsFolder
end

-- Spawn points: queue slots in the GameplayLoopArea ServingArea.
-- If GuestSpawn-tagged parts exist (preferred), they will override these.
local CollectionService = game:GetService("CollectionService")
local SPAWN_POINTS = {
	Vector3.new(188, -518, -415), -- LoopServingPoint_1 fallback
	Vector3.new(196, -518, -415),
	Vector3.new(204, -518, -415),
	Vector3.new(212, -518, -415),
}

-- Refresh spawn points from world if GuestSpawn parts are tagged
local function refreshSpawnPoints()
	local tagged = CollectionService:GetTagged("GuestSpawn")
	if #tagged > 0 then
		local pts = {}
		for _, p in ipairs(tagged) do
			if p:IsA("BasePart") then
				table.insert(pts, p.Position + Vector3.new(0, 2, 0))
			end
		end
		if #pts > 0 then
			SPAWN_POINTS = pts
		end
	end
end
refreshSpawnPoints()

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local NPCConfig = require(RS.Shared.Config.NPCConfig)
local InsertService = game:GetService("InsertService")

local ServingService: any = nil

-- Cache loaded mesh templates
local meshTemplateCache = {}

-- Animal guest templates: cloned + normalized from the ambient "animal-*" models
-- already placed in the level, so guests can be cute animals (fox, penguin,
-- bunny, etc.) asking to be served -- not just Kenney humans (several of which
-- fail to load and fall back to plain capsules anyway). Built once at startup.
-- Each template's largest BasePart becomes "Torso", every limb is pre-welded
-- to it at correct offsets so the whole animal moves as a unit when the guest
-- is positioned/roams, and PrimaryPart is set so NPCPatrolSystem.moveToWaypoint
-- can actually tween it.
local animalTemplates = {} -- [name] = normalized Model
local ANIMAL_GUEST_SCALE = 1.6

local function buildAnimalTemplates()
	local seen = {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and string.sub(m.Name, 1, 7) == "animal-" and not seen[m.Name] then
			seen[m.Name] = true
			local biggest, biggestVol
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					local v = d.Size.X * d.Size.Y * d.Size.Z
					if not biggestVol or v > biggestVol then
						biggestVol = v
						biggest = d
					end
				end
			end
			if biggest then
				local template = m:Clone()
				local parts, body = {}, nil
				for _, d in ipairs(template:GetDescendants()) do
					if d:IsA("BasePart") then
						table.insert(parts, d)
						if d.Name == biggest.Name and not body then
							body = d
						end
					end
				end
				body = body or parts[1]
				body.Name = "Torso"
				template.PrimaryPart = body
				pcall(function()
					template:ScaleTo(ANIMAL_GUEST_SCALE)
				end)
				-- Normalize only -- welding + positioning is handled uniformly in
				-- createGuest (which moves the whole model with PivotTo, then
				-- welds limbs at correct offsets). Pre-welding here would create
				-- conflicting double-welds.
				body.Anchored = false
				body.CanCollide = false
				for _, d in ipairs(parts) do
					if d.Parent ~= template then
						d.Parent = template
					end
					if d ~= body then
						d.Anchored = false
						d.CanCollide = false
						d.Massless = true
					end
				end
				template.Name = m.Name
				animalTemplates[m.Name] = template
			end
		end
	end
	local n = 0
	for _ in pairs(animalTemplates) do
		n += 1
	end
	print("[GuestManager] Built " .. n .. " animal guest templates from level meshes")
end

local function loadMeshTemplate(meshType)
	-- Animal guest templates are pre-built, correctly assembled clones -- return
	-- one directly (no InsertService, no permission wall, already normalized).
	if animalTemplates[meshType] then
		return animalTemplates[meshType]:Clone()
	end
	if meshTemplateCache[meshType] then
		return meshTemplateCache[meshType]:Clone()
	end

	local template = NPCConfig.guestTemplates[meshType]
	if not template then
		warn("[GuestManager] Unknown mesh type:", meshType)
		return nil
	end

	local success, loaded = pcall(function()
		local assetId = tonumber(template.meshId:match("%d+"))
		return InsertService:LoadAsset(assetId)
	end)

	if not success or not loaded then
		warn("[GuestManager] Failed to load mesh:", meshType, loaded)
		return nil
	end

	-- Kenney rig assets load as a wrapper Model containing a nested character
	-- Model with MeshParts named "body-mesh"/"head-mesh" (not "Torso"/"Head").
	-- Find + normalize them, and flatten everything to direct children so the
	-- rest of this script's FindFirstChild("Torso") lookups keep working.
	local bodyPart, headPart
	for _, d in ipairs(loaded:GetDescendants()) do
		if d:IsA("BasePart") then
			local lname = d.Name:lower()
			if not bodyPart and (lname:find("body") or lname == "torso") then
				bodyPart = d
			elseif not headPart and lname:find("head") then
				headPart = d
			end
		end
	end

	if not bodyPart then
		warn("[GuestManager] Mesh missing body part:", meshType)
		loaded:Destroy()
		return nil
	end

	local flat = Instance.new("Model")
	flat.Name = meshType
	bodyPart.Name = "Torso"
	bodyPart.Parent = flat
	if headPart then
		headPart.Name = "Head"
		headPart.Parent = flat
	end
	for _, d in ipairs(loaded:GetDescendants()) do
		if d:IsA("BasePart") and d ~= bodyPart and d ~= headPart then
			d.Parent = flat
		end
	end
	loaded:Destroy()

	meshTemplateCache[meshType] = flat
	return flat:Clone()
end

-- Create a guest for a specific player
-- Guest cap is PER PLAYER, not global: with the old global count a full queue
-- for one player starved everyone else on the server.
local function countGuestsForPlayer(player)
	local count = 0
	for _, guestData in pairs(activeGuests) do
		if guestData[2] == player then
			count = count + 1
		end
	end
	return count
end

local function createGuest(player)
	if countGuestsForPlayer(player) >= CONFIG.guest_settings.max_guests_at_once then
		return nil
	end

	-- Clone template
	local clonedTemplate = guestTemplate:Clone()
	local guest
	if clonedTemplate:IsA("Model") then
		guest = clonedTemplate
	else
		guest = Instance.new("Model")
		for _, child in ipairs(clonedTemplate:GetChildren()) do
			child.Parent = guest
		end
		clonedTemplate:Destroy()
	end
	guestIdCounter = guestIdCounter + 1
	guest.Name = "Guest_" .. guestIdCounter

	-- Select random mesh type. Prefer the cute animal guests (built from level
	-- meshes) -- they always load cleanly. Mix in the Kenney human types too for
	-- variety. If no animal templates were built (e.g. none in the level yet),
	-- fall back to the Kenney pool alone.
	local meshTypes = {}
	for name in pairs(animalTemplates) do
		table.insert(meshTypes, name)
	end
	local animalCount = #meshTypes
	if animalCount == 0 then
		for meshType in pairs(NPCConfig.guestTemplates) do
			table.insert(meshTypes, meshType)
		end
	else
		-- ~1 in 4 guests is a Kenney human for variety; the rest are animals.
		if math.random() < 0.25 then
			local kenney = {}
			for meshType in pairs(NPCConfig.guestTemplates) do
				table.insert(kenney, meshType)
			end
			if #kenney > 0 then
				table.insert(meshTypes, kenney[math.random(1, #kenney)])
			end
		end
	end
	local selectedMeshType = meshTypes[math.random(1, #meshTypes)]

	-- Try to load mesh template
	local meshModel = loadMeshTemplate(selectedMeshType)
	if meshModel then
		-- Use mesh-based guest
		guest:ClearAllChildren()
		for _, child in ipairs(meshModel:GetChildren()) do
			child.Parent = guest
		end
		meshModel:Destroy()

		-- Apply scale (Kenney meshes only -- animal templates are pre-scaled at
		-- build time and have no NPCConfig entry).
		local tmpl = NPCConfig.guestTemplates[selectedMeshType]
		local torso = guest:FindFirstChild("Torso")
		if torso and tmpl and tmpl.scale then
			torso.Size = torso.Size * tmpl.scale
		end
		-- Set PrimaryPart so NPCPatrolSystem.moveToWaypoint (which tweens
		-- model.PrimaryPart) can actually move the guest -- without this, every
		-- mesh guest silently failed to roam.
		if torso then
			guest.PrimaryPart = torso
		end

		print("[GuestManager] Using mesh guest:", selectedMeshType)
	else
		-- Fallback to procedural capsule
		warn("[GuestManager] Using procedural capsule for guest")
		local prefs = CONFIG.guest_preferences
		local pref = prefs[math.random(1, #prefs)]
		local npcColor = Color3.fromRGB(180, 120, 80)
		if pref.name == "Food Critic" then
			npcColor = Color3.fromRGB(100, 180, 220)
		elseif pref.name == "Regular Customer" then
			npcColor = Color3.fromRGB(220, 160, 100)
		elseif pref.name == "Picnic Guest" then
			npcColor = Color3.fromRGB(200, 180, 60)
		elseif pref.name and pref.name:find("Challenge") then
			npcColor = Color3.fromRGB(220, 80, 80)
		end
		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2.5, 1)
		torso.Color = npcColor
		torso.Anchored = false
		torso.CanCollide = false
		torso.Parent = guest
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.2, 1.2, 1.2)
		head.Color = npcColor
		head.Anchored = false
		head.CanCollide = false
		head.Position = Vector3.new(0, 2, 0)
		head.Parent = guest
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = head
		weld.Parent = torso
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = guest
		guest.PrimaryPart = torso
	end

	-- Set mesh type attribute
	guest:SetAttribute("MeshType", selectedMeshType)

	-- Pick a random guest preference
	local preference = CONFIG.guest_preferences[math.random(1, #CONFIG.guest_preferences)]
	local recipe = preference.preferred_recipes[math.random(1, #preference.preferred_recipes)]
	local pay = math.random(preference.pay_range[1], preference.pay_range[2])
	local patience = CONFIG.guest_settings.guest_patience
	if preference.challenge then
		patience = preference.challenge.patience
	end

	-- Set guest attributes
	guest:SetAttribute("GuestName", preference.name)
	guest:SetAttribute("PreferredRecipe", recipe)
	guest:SetAttribute("PayAmount", pay)
	guest:SetAttribute("SpawnTime", os.clock())
	guest:SetAttribute("Patience", patience)
	guest:SetAttribute("ServingPlayer", player.Name)
	guest:SetAttribute("ServingUserId", player.UserId)
	guest:SetAttribute("ServingState", "active")
	guest:SetAttribute("IsChallenge", preference.challenge and true or false)
	guest:SetAttribute("BonusGold", preference.challenge and preference.challenge.bonus_gold or 0)

	-- Trigger VN dialogue for guest spawn (with cooldown to avoid spam)
	if selectedMeshType then
		local lastDialogueTime = _G._lastGuestDialogueTime or 0
		local now = os.clock()
		if now - lastDialogueTime >= 60 then
			_G._lastGuestDialogueTime = now
			local ok, VNDialogueData = pcall(require, RS.ConfigurationFiles.VNDialogueData)
			-- Fall back to DEFAULT so every guest type gets spawn dialogue, not
			-- just ones with a bespoke entry (24 animal meshes have no bespoke
			-- entry and would otherwise never say anything).
			local dialogue = ok
				and VNDialogueData
				and VNDialogueData.GUEST_BY_TYPE
				and (VNDialogueData.GUEST_BY_TYPE[selectedMeshType] or VNDialogueData.GUEST_BY_TYPE.DEFAULT)
			if dialogue and dialogue.spawn then
				local spawnLine = dialogue.spawn
				if type(spawnLine) == "table" then
					spawnLine = spawnLine[math.random(1, #spawnLine)]
				end
				local text = spawnLine:gsub("{recipe}", recipe)
				local VNEvent = RS.RemoteEvents:FindFirstChild("ShowVNDialogue")
				if not VNEvent then
					VNEvent = Instance.new("RemoteEvent")
					VNEvent.Name = "ShowVNDialogue"
					VNEvent.Parent = RS.RemoteEvents
				end
				VNEvent:FireClient(player, "guest", text)
			end
		end
	end

	-- Apply decoration patience buffs
	local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
	local d = PlayerDataService.get(player)
	if d and d.active_decor_buffs and d.active_decor_buffs.patience > 0 then
		local buffMult = 1 + d.active_decor_buffs.patience
		guest:SetAttribute("Patience", math.floor(patience * buffMult))
	end

	-- Position at a free spawn slot
	local usedSlots = {}
	for _, g in pairs(GUEST_SPAWN_FOLDER:GetChildren()) do
		local torso = g:FindFirstChild("Torso")
		if torso then
			for i, sp in ipairs(SPAWN_POINTS) do
				if (torso.Position - sp).Magnitude < 4 then
					usedSlots[i] = true
				end
			end
		end
	end
	local spawnPos = nil
	for i, sp in ipairs(SPAWN_POINTS) do
		if not usedSlots[i] then
			spawnPos = sp
			break
		end
	end
	if not spawnPos then
		spawnPos = SPAWN_POINTS[1]
	end

	local torso = guest:FindFirstChild("Torso")
	if torso then
		-- Move the WHOLE model to the slot as a unit (PivotTo) so multi-part
		-- meshes stay coherent -- setting torso.CFrame alone left the limbs
		-- behind at their template positions, and the weld loop below then
		-- locked that huge stale offset (animals' legs ended up ~180 studs away).
		if guest.PrimaryPart then
			guest:PivotTo(CFrame.new(spawnPos))
		else
			torso.CFrame = CFrame.new(spawnPos)
		end
		torso.Anchored = true -- Keep guest still so they don't fall
	end

	-- Weld all limbs to torso so the model moves together (offsets are now
	-- correct because the whole model was moved coherently above).
	for _, part in ipairs(guest:GetDescendants()) do
		if part:IsA("BasePart") and part ~= torso then
			local w = Instance.new("WeldConstraint")
			w.Part0 = torso
			w.Part1 = part
			w.Parent = torso
			part.Anchored = false -- Let limbs be controlled by weld
		end
	end

	-- Disable humanoid physics to prevent falling/walking
	local humanoid = guest:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
	end

	-- Add ClickDetector to torso for serving
	if torso and not torso:FindFirstChildOfClass("ClickDetector") then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 20
		cd.Parent = torso
	end

	-- Billboard GUI above guest showing their order + patience bar
	local billSize = preference.challenge and 180 or 160
	local bill = Instance.new("BillboardGui")
	bill.Name = "OrderBubble"
	bill.Size = UDim2.new(0, billSize, 0, 90)
	bill.StudsOffset = Vector3.new(0, 4.5, 0)
	bill.AlwaysOnTop = false
	bill.Parent = torso

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(255, 250, 220)
	bg.BorderSizePixel = 0
	bg.Parent = bill
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

	-- Patience bar background
	local patienceBg = Instance.new("Frame")
	patienceBg.Name = "PatienceBg"
	patienceBg.Size = UDim2.new(1, -20, 0, 6)
	patienceBg.Position = UDim2.new(0, 10, 0, 3)
	patienceBg.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	patienceBg.BorderSizePixel = 0
	patienceBg.Parent = bg
	Instance.new("UICorner", patienceBg).CornerRadius = UDim.new(1, 0)

	-- Patience bar fill
	local patienceFill = Instance.new("Frame")
	patienceFill.Name = "PatienceFill"
	patienceFill.Size = UDim2.new(1, 0, 1, 0)
	patienceFill.BackgroundColor3 = preference.challenge and Color3.fromRGB(220, 80, 80)
		or CONFIG.patience_colors.normal
	patienceFill.BorderSizePixel = 0
	patienceFill.Parent = patienceBg
	Instance.new("UICorner", patienceFill).CornerRadius = UDim.new(1, 0)
	if preference.challenge then
		local star = Instance.new("TextLabel")
		star.Size = UDim2.new(0, 20, 0, 20)
		star.Position = UDim2.new(1, -22, 0, 2)
		star.BackgroundTransparency = 1
		star.Text = "⭐"
		star.TextScaled = true
		star.Parent = bill
	end

	local orderLabel = Instance.new("TextLabel")
	orderLabel.Name = "OrderLabel"
	orderLabel.Size = UDim2.new(1, -8, 0, 28)
	orderLabel.Position = UDim2.new(0, 4, 0, 12)
	orderLabel.BackgroundTransparency = 1
	orderLabel.Text = recipe
	orderLabel.TextColor3 = Color3.fromRGB(80, 40, 10)
	orderLabel.TextScaled = true
	orderLabel.Font = Enum.Font.GothamBold
	orderLabel.Parent = bg

	local payLabel = Instance.new("TextLabel")
	payLabel.Name = "PayLabel"
	payLabel.Size = UDim2.new(1, -8, 0, 22)
	payLabel.Position = UDim2.new(0, 4, 0, 44)
	payLabel.BackgroundTransparency = 1
	payLabel.Text = preference.challenge and "+ " .. pay .. " ⭐ +" .. preference.challenge.bonus_gold .. " bonus"
		or "+ " .. pay .. " Gold"
	payLabel.TextColor3 = Color3.fromRGB(200, 150, 0)
	payLabel.TextScaled = true
	payLabel.Font = Enum.Font.Gotham
	payLabel.Parent = bg
	-- Assign personality type for roaming behavior. Guests are mostly roamers now
	-- (they wander a small radius around their serving slot so they feel alive
	-- and "milling about" instead of frozen) with a few stationary. Patrol is
	-- intentionally dropped for guests -- it sends them across the whole map via
	-- PatrolPoint waypoints, away from the serving area where they need to be
	-- clickable. (Patrol stays in use for the ambient Traveler/Merchant NPCs.)
	local personalityTypes = { "stationary", "roamer" }
	local personalityWeights = { 0.2, 0.8 } -- 20% stationary, 80% roamer
	local roll = math.random()
	local cumulative = 0
	local personality = "stationary"
	for i, pType in ipairs(personalityTypes) do
		cumulative = cumulative + personalityWeights[i]
		if roll <= cumulative then
			personality = pType
			break
		end
	end
	guest:SetAttribute("Personality", personality)

	-- Parent to Guests folder BEFORE starting roaming -- guestRoamLoop's
	-- `while guest.Parent do` check runs synchronously the instant task.spawn is
	-- called (task.spawn runs up to the first yield immediately), so if the
	-- roam loop was started while guest.Parent was still nil it exited on its
	-- very first iteration with no error, silently. This was why NO guest ever
	-- actually roamed despite spawn logs claiming "personality: roamer".
	guest.Parent = GUEST_SPAWN_FOLDER

	-- If roamer, start roaming behavior
	if personality ~= "stationary" then
		task.spawn(function()
			local NPCPatrolSystem = require(game:GetService("ServerScriptService").NPCPatrolSystem)
			if NPCPatrolSystem and NPCPatrolSystem.startGuestRoaming then
				NPCPatrolSystem.startGuestRoaming(guest, personality)
			end
		end)
	end

	print(
		"[GuestManager] Spawned guest "
			.. guest.Name
			.. " for "
			.. player.Name
			.. " wanting "
			.. recipe
			.. " (personality: "
			.. personality
			.. ")"
	)

	return guest
end

-- Check if guest has timed out (been waiting too long)
local function checkGuestTimeout(guest)
	if not guest or not guest.Parent then
		return true
	end

	local spawnTime = guest:GetAttribute("SpawnTime")
	local patience = guest:GetAttribute("Patience")

	if (os.clock() - spawnTime) > patience then
		return true -- Timed out
	end

	return false
end

-- Remove a guest (served or timed out)
local function removeGuest(guest, reason)
	if not guest or not guest.Parent then
		return
	end

	local guestName = guest.Name
	local playerName = guest:GetAttribute("ServingPlayer")

	print("[GuestManager] Guest " .. guestName .. " removed (" .. reason .. ")")

	-- Trigger VN dialogue and fire GuestTimedOut event on guest timeout
	if reason == "timeout" then
		local meshType = guest:GetAttribute("MeshType")
		local ok2, VNDialogueData = pcall(require, RS.ConfigurationFiles.VNDialogueData)
		local dialogue = ok2
			and VNDialogueData
			and VNDialogueData.GUEST_BY_TYPE
			and (VNDialogueData.GUEST_BY_TYPE[meshType] or VNDialogueData.GUEST_BY_TYPE.DEFAULT)
		local servingPlayer = game.Players:FindFirstChild(playerName)
		if not servingPlayer then
			local userId = guest:GetAttribute("ServingUserId")
			if typeof(userId) == "number" then
				servingPlayer = game.Players:GetPlayerByUserId(userId)
			end
		end

		if dialogue and dialogue.timeout and servingPlayer then
			local timeoutLine = dialogue.timeout
			if type(timeoutLine) == "table" then
				timeoutLine = timeoutLine[math.random(1, #timeoutLine)]
			end
			local VNEvent = RS.RemoteEvents:FindFirstChild("ShowVNDialogue")
			if VNEvent then
				VNEvent:FireClient(servingPlayer, "guest", timeoutLine)
			end
		end

		if servingPlayer then
			local guestType = guest:GetAttribute("MeshType") or guest:GetAttribute("GuestType") or "default"
			if not ServingService then
				local sf = SSS:FindFirstChild("Services")
				local ssMod = sf and sf:FindFirstChild("ServingService")
				if ssMod then
					ServingService = require(ssMod)
				end
			end
			if ServingService then
				if ServingService.onGuestTimeout then
					ServingService.onGuestTimeout(servingPlayer, guestType)
				elseif ServingService.GuestTimedOut then
					ServingService.GuestTimedOut:Fire(servingPlayer, guestType)
				end
			end
		end
	end

	guest:Destroy()
	activeGuests[guestName] = nil
end

-- Main guest spawning loop
local function guestSpawnLoop()
	while true do
		-- Wait random interval between spawn attempts
		local spawnDelay =
			math.random(CONFIG.guest_settings.spawn_interval_min, CONFIG.guest_settings.spawn_interval_max)
		task.wait(spawnDelay)

		-- Try to spawn a guest for each online player
		for _, player in pairs(game.Players:GetPlayers()) do
			local guest = createGuest(player)
			if guest then
				activeGuests[guest.Name] = { guest, player }
			end
		end
	end
end

-- Main guest timeout/cleanup loop
local function guestTimeoutLoop()
	while true do
		task.wait(5) -- Check timeouts every 5 seconds

		for guestName, guestData in pairs(activeGuests) do
			local guest = guestData[1]

			if not guest or not guest.Parent then
				activeGuests[guestName] = nil
			elseif checkGuestTimeout(guest) then
				removeGuest(guest, "timeout")
			end
		end
	end
end

local Players = game:GetService("Players")
local servicesFolder = SSS:FindFirstChild("Services")
local GuestService = servicesFolder and servicesFolder:FindFirstChild("GuestService")
if GuestService then
	GuestService = require(GuestService)
end
local ssModule = servicesFolder and servicesFolder:FindFirstChild("ServingService")
if ssModule then
	ServingService = require(ssModule)
end

-- Expose for ServingSystem to call when guest is served
if GuestService and GuestService.setRemoveGuestCallback then
	GuestService.setRemoveGuestCallback(removeGuest)
end

-- Build the animal guest template pool from the level's animal-* meshes before
-- the first guest spawns (5s spawn delay gives this ample time).
buildAnimalTemplates()

-- Start loops
task.spawn(guestSpawnLoop)
task.spawn(guestTimeoutLoop)

-- Spawn guest for players who join later
Players.PlayerAdded:Connect(function(player)
	task.wait(5) -- Wait for player to load
	local guest = createGuest(player)
	if guest then
		activeGuests[guest.Name] = { guest, player }
	end
end)

print("[GuestManager] Started - first guest spawns in 5 seconds")
