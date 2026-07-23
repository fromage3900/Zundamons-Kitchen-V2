-- CompanionManager v4: loads full companion models with textures, sparkle VFX, VN click interaction
local Players    = game:GetService("Players")
local Tween      = game:GetService("TweenService")
local RS         = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local CompanionVisualConfig = require(RS.ConfigurationFiles.CompanionVisualConfig)

-- Cache loaded companion models
local companionModelCache = {}
local ZUNDAPAL_PREFAB_NAME = "zundapalupdate4"

local function loadCompanionModel(compType)
	if companionModelCache[compType] then
		print("[CompanionManager.loadCompanionModel] Using cached model for", compType)
		return companionModelCache[compType]:Clone()
	end

	-- The real zundapal mesh (MeshId rbxassetid://124750913039753) lives in the level
	-- as a MeshPart. A "usable source" here means it contains at least one MeshPart with
	-- a NON-EMPTY MeshId — the empty-mesh catalog placeholders are exactly the "cube".
	local ZUNDAPAL_MESH_ID = "124750913039753"

	local function hasRealMesh(inst)
		if inst:IsA("MeshPart") and inst.MeshId ~= "" then
			return true
		end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("MeshPart") and d.MeshId ~= "" then
				return true
			end
		end
		return false
	end

	-- Turn a source (Model OR a lone MeshPart/BasePart) into a cloned Model with a
	-- recursive PrimaryPart. Rejects sources that have no real mesh (would be a cube).
	local function cacheClone(source)
		if not hasRealMesh(source) then
			return nil
		end
		local clone
		if source:IsA("Model") then
			clone = source:Clone()
		else
			-- Wrap a lone part (the level's `zundapalupdate4` MeshPart) into a Model.
			clone = Instance.new("Model")
			local partClone = source:Clone()
			partClone.Parent = clone
			clone.PrimaryPart = partClone
		end
		if not clone.PrimaryPart then
			local inner = clone:FindFirstChildWhichIsA("Model")
			clone.PrimaryPart = (inner and inner.PrimaryPart)
				or clone:FindFirstChildWhichIsA("BasePart", true)
		end
		if not clone.PrimaryPart then
			clone:Destroy()
			return nil
		end
		companionModelCache[compType] = clone
		return clone:Clone()
	end

	-- PRIMARY (zundapal): the authored mesh placed right in the level. It is named
	-- "zundapalupdate4" (which renders in paths as "Meshes/zundapalupdate4"). Match it
	-- by name OR by its known MeshId so a rename can't reintroduce the cube.
	if compType == "zundapal" or compType == "zundamon" then
		local levelMesh
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("MeshPart") and (d.MeshId:find(ZUNDAPAL_MESH_ID) or d.Name:lower():find("zundapalupdate")) then
				levelMesh = d
				break
			end
		end
		if levelMesh then
			print("[CompanionManager.loadCompanionModel] Using level mesh", levelMesh:GetFullName(), "for", compType)
			local result = cacheClone(levelMesh)
			if result then return result end
		end
	end

	-- Next: authored prefab catalog — but ONLY if it actually has a real mesh
	-- (empty-mesh placeholders are rejected by cacheClone).
	local catalog = ServerStorage:FindFirstChild("CompanionVisualCatalog")
	local prefabs = catalog and catalog:FindFirstChild("Prefabs")
	if prefabs then
		local authored = prefabs:FindFirstChild(compType) or prefabs:FindFirstChild("zundapal")
		if authored then
			local result = cacheClone(authored)
			if result then
				print("[CompanionManager.loadCompanionModel] Using authored prefab", authored.Name, "for", compType)
				return result
			end
		end
	end

	-- Fallback: InsertService by asset ID (production / when the prefab isn't present).
	local compVisual = CompanionVisualConfig.get(compType)
	local assetId = compVisual and compVisual.modelAssetId
	if assetId and assetId ~= "" then
		local success, insertedModel = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)
		if success and insertedModel and insertedModel:IsA("Model") then
			print("[CompanionManager.loadCompanionModel] Loaded", compType, "from assetId:", assetId)
			local result = cacheClone(insertedModel)
			if result then return result end
		end
	end

	-- HARD RULE: a companion is NEVER a cube. If no source resolved yet, wait for the
	-- authored catalog to be present/replicated and try it again, then give up with a
	-- loud error rather than ever spawning a placeholder.
	warn("[CompanionManager.loadCompanionModel] No companion mesh resolved on first pass for", compType, "- waiting for authored prefab…")
	local waited = catalog
	if not waited then
		waited = ServerStorage:WaitForChild("CompanionVisualCatalog", 10)
	end
	local waitedPrefabs = waited and waited:WaitForChild("Prefabs", 5)
	local retry = waitedPrefabs and (waitedPrefabs:FindFirstChild(compType) or waitedPrefabs:FindFirstChild("zundapal"))
	if retry and retry:IsA("Model") then
		local result = cacheClone(retry)
		if result then return result end
	end

	error("[CompanionManager] FATAL: could not resolve a real companion mesh for '" .. tostring(compType)
		.. "'. Expected ServerStorage.CompanionVisualCatalog.Prefabs.zundapal (or a valid asset). Refusing to spawn a placeholder.")
end

-- Companion catalog sourced from Canonical CompanionConfig
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)
local COMPANIONS = CompanionConfig.companions

-- ── RemoteEvents ───────────────────────────────────────────────
local RE      = RS:WaitForChild("RemoteEvents")
local setCompEv = RE:WaitForChild("SetCompanion")
local vnEv    = RE:FindFirstChild("OpenCompanionVN")
if not vnEv then
	vnEv = Instance.new("RemoteEvent"); vnEv.Name="OpenCompanionVN"; vnEv.Parent=RE
end

local activeCompanions = {}

-- ── Build companion ────────────────────────────────────────────
local function buildCompanion(player, compType)
	print("[CompanionManager.buildCompanion] Building companion for", player.Name, "type:", compType)
	local def = COMPANIONS[compType] or COMPANIONS.zundamon
	local name = "ZundaCompanion_" .. player.Name

	-- Remove existing
	local existing = workspace:FindFirstChild(name)
	if existing then
		print("[CompanionManager.buildCompanion] Removing existing companion")
		existing:Destroy()
	end
	local prev = activeCompanions[player.Name]
	if prev then pcall(function() prev:Destroy() end) end

	-- Load the full companion model. NEVER a cube: retry a few times, then abort
	-- (no companion this spawn) rather than fabricate a placeholder.
	local companionModel
	for attempt = 1, 3 do
		local ok, result = pcall(loadCompanionModel, compType)
		if ok and result then
			companionModel = result
			break
		end
		warn("[CompanionManager.buildCompanion] mesh load attempt", attempt, "failed for", compType, "-", tostring(result))
		task.wait(1)
	end

	if not companionModel then
		warn("[CompanionManager.buildCompanion] Could not load a real companion mesh for", player.Name,
			"- refusing to spawn a placeholder. No companion this spawn.")
		return
	end

	companionModel.Name = name
	companionModel.Parent = workspace

	local body = companionModel.PrimaryPart
	if not body then
		body = companionModel:FindFirstChildWhichIsA("BasePart")
		companionModel.PrimaryPart = body
	end

	-- Scale to roughly human height. The authored zundapal mesh is ~50 studs tall;
	-- a Roblox character is ~5. Scale by (target / current) so it stands human-sized.
	local COMPANION_HEIGHT = 5.2
	local currentHeight = companionModel:GetExtentsSize().Y
	if currentHeight > 0.1 then
		local factor = COMPANION_HEIGHT / currentHeight
		-- Only rescale if meaningfully off (avoid re-scaling an already-correct source).
		if factor < 0.9 or factor > 1.1 then
			companionModel:ScaleTo(companionModel:GetScale() * factor)
		end
	end

	-- Start near player
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	body.CFrame = hrp and (hrp.CFrame * CFrame.new(4, 1, 0)) or CFrame.new(47, 8, -74)

	-- Make all parts non-collidable and massless
	for _, part in ipairs(companionModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.CastShadow = false
		end
	end

	-- ── Sparkle ParticleEmitter ────────────────────────────────
	local sparkle = Instance.new("ParticleEmitter", body)
	sparkle.Name = "CompanionSparkles"
	sparkle.Texture = "rbxassetid://241685484"
	sparkle.Rate = 10
	sparkle.LightEmission = 0.3
	sparkle.LightInfluence = 0.4
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Speed = NumberRange.new(1.5, 4)
	sparkle.Lifetime = NumberRange.new(0.6, 1.8)
	sparkle.RotSpeed = NumberRange.new(-180, 180)
	sparkle.Rotation = NumberRange.new(0, 360)
	local sc = def.sparkleColors
	sparkle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   sc[1]),
		ColorSequenceKeypoint.new(0.5, sc[2]),
		ColorSequenceKeypoint.new(1,   sc[3]),
	})
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.25),
		NumberSequenceKeypoint.new(0.4, 0.45),
		NumberSequenceKeypoint.new(1,   0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1,   1),
	})

	-- ── Point light glow ──────────────────────────────────────
	local pl = Instance.new("PointLight", body)
	pl.Brightness = 0.6
	pl.Range      = def.glowRange
	pl.Color      = def.glow
	Tween:Create(pl, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Brightness = 1.0}):Play()

	-- ── Fairy dust Beam trail ────────────────────────────────
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAttach0"
	att0.Position = Vector3.new(0, 0.5, -1.2)
	att0.Parent = body

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAttach1"
	att1.Position = Vector3.new(0, -0.5, 1.5)
	att1.Parent = body

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Texture = "rbxassetid://123808802176536"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 2
	beam.Width0 = 1.5
	beam.Width1 = 0.3
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.50),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	beam.LightEmission = 0.4
	beam.Brightness = 0.25
	beam.Color = ColorSequence.new(def.glow or Color3.fromRGB(200, 180, 255))
	beam.TextureSpeed = 0.5
	beam.Parent = body

	-- ── Face emoji BillboardGui ────────────────────────────────
	local sz = body.Size.Z / 2 + 0.2
	local faceBg = Instance.new("BillboardGui", body)
	faceBg.Name = "FaceBg"
	faceBg.Size = UDim2.new(0, 72, 0, 72)
	faceBg.StudsOffset = Vector3.new(0, 0, sz)
	faceBg.AlwaysOnTop = false
	faceBg.LightInfluence = 0.25
	local faceLabel = Instance.new("TextLabel", faceBg)
	faceLabel.Size = UDim2.new(1,0,1,0)
	faceLabel.BackgroundTransparency = 1
	faceLabel.Text = def.emoji
	faceLabel.Font = Enum.Font.GothamBold
	faceLabel.TextSize = 42

	-- ── Name tag ──────────────────────────────────────────────
	local halfH = body.Size.Y / 2 + 2.2
	local nameBg = Instance.new("BillboardGui", body)
	nameBg.Name = "NameTag"
	nameBg.Size = UDim2.new(0, 140, 0, 28)
	nameBg.StudsOffset = Vector3.new(0, halfH, 0)
	nameBg.AlwaysOnTop = false
	local pill = Instance.new("Frame", nameBg)
	pill.Size = UDim2.new(1,0,1,0)
	pill.BackgroundColor3 = Color3.fromRGB(30,24,40)
	pill.BackgroundTransparency = 0.15
	pill.BorderSizePixel = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(0.5, 0)
	local nLbl = Instance.new("TextLabel", pill)
	nLbl.Size = UDim2.new(1,-8,1,0); nLbl.Position = UDim2.new(0,4,0,0)
	nLbl.BackgroundTransparency = 1
	nLbl.Text = player.Name .. "'s " .. (def.displayName or "Companion") .. " ✨"
	nLbl.Font = Enum.Font.FredokaOne
	nLbl.TextSize = 12
	nLbl.TextColor3 = Color3.fromRGB(240,230,255)
	nLbl.TextXAlignment = Enum.TextXAlignment.Center

	-- ── ClickDetector for VN dialogue ─────────────────────────
	local cd = Instance.new("ClickDetector", body)
	cd.MaxActivationDistance = 20
	local lastClick = 0
	cd.MouseClick:Connect(function(clicker)
		local now = os.clock()
		if now - lastClick < 3 then return end
		lastClick = now
		sparkle.Rate = 60
		task.delay(0.6, function() if sparkle.Parent then sparkle.Rate = 10 end end)
		vnEv:FireClient(clicker, compType, def.emoji)
	end)

	activeCompanions[player.Name] = companionModel

	-- ── Smooth follow loop ─────────────────────────────────────
	-- The authored zundapal mesh is baked upside-down relative to its part axes, so we
	-- apply a correction and keep it upright + facing the player's direction every step
	-- (physics never controls rotation, so orientation must be driven explicitly).
	local ORIENT_CORRECTION = CFrame.Angles(0, 0, math.rad(180)) -- roll 180° to un-flip; keeps facing
	task.spawn(function()
		local t = 0
		while body and body.Parent and companionModel.Parent do
			t = t + 0.05
			local char2 = player.Character
			local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
			if hrp2 then
				local floatY  = math.sin(t * 1.1) * 0.7 + 1.8
				local sideOff = hrp2.CFrame.RightVector * (3.5 + math.sin(t * 0.3) * 0.4)
				local target  = hrp2.Position + sideOff + Vector3.new(0, floatY, 0)
				local dist    = (body.Position - target).Magnitude
				if dist > 0.3 then
					body.AssemblyLinearVelocity = (target - body.Position).Unit * math.min(dist * 5, 35)
				end
				-- Face the same flat direction as the player, upright.
				local fwd = hrp2.CFrame.LookVector
				fwd = Vector3.new(fwd.X, 0, fwd.Z)
				if fwd.Magnitude > 0.01 then
					local facing = CFrame.lookAt(body.Position, body.Position + fwd.Unit).Rotation
					body.AssemblyAngularVelocity = Vector3.zero
					body.CFrame = CFrame.new(body.Position) * facing * ORIENT_CORRECTION
				end
			end
			task.wait(0.05)
		end
	end)

	return companionModel
end

-- ── Player lifecycle ───────────────────────────────────────────
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(2)
		local data = PlayerDataService.getOrCreate(player)
		local compType = data.active_companion or "zundapal"
		buildCompanion(player, compType)
	end)
end

setCompEv.OnServerEvent:Connect(function(player, compType)
	if not COMPANIONS[compType] then
		return
	end
	local data = PlayerDataService.getOrCreate(player)
	local def = COMPANIONS[compType]
	local isFree = def.free == true
	if not isFree and not data["companion_owned_" .. compType] then
		return
	end
	if not data.companions_set then data.companions_set = {} end
	data.companions_set[compType] = true
	data.active_companion = compType
	buildCompanion(player, compType)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

Players.PlayerRemoving:Connect(function(player)
	local m = activeCompanions[player.Name]
	if m then m:Destroy(); activeCompanions[player.Name] = nil end
end)

print("[CompanionManager v4] Full model loading with textures + sparkles + VN click ready")
print("[CompanionManager v4] Using zundapalupdate4 mesh as primary model source")
