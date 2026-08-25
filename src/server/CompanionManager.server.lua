-- CompanionManager v4: loads full companion models with textures, sparkle VFX, VN click interaction
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local CompanionVisualConfig = require(RS.ConfigurationFiles.CompanionVisualConfig)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)

-- Cache loaded companion models
local companionModelCache = {}
local ZUNDAPAL_PREFAB_NAME = "zundapalupdate4"

-- Robustness constants (audit 2026-08-25): scale guard, animation fade, retry budget
local COMPANION_HEIGHT = 5.2
local SCALE_GUARD_LOW = 0.9
local SCALE_GUARD_HIGH = 1.1
local MESH_LOAD_MAX_RETRIES = 3
local ANIM_FADE = 0.2
local ANIM_PRIORITY = Enum.AnimationPriority.Core

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
			warn(
				"[CompanionManager.cacheClone] REJECTED empty MeshId source",
				source:GetFullName(),
				"for",
				compType,
				"- refusing cube placeholder (hasRealMesh=false)"
			)
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
			clone.PrimaryPart = (inner and inner.PrimaryPart) or clone:FindFirstChildWhichIsA("BasePart", true)
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
			if result then
				return result
			else
				warn(
					"[CompanionManager.loadCompanionModel] Level mesh",
					levelMesh:GetFullName(),
					"rejected (empty MeshId) for",
					compType
				)
			end
		else
			print(
				"[CompanionManager.loadCompanionModel] No level mesh found for",
				compType,
				"- trying authored catalog"
			)
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
			else
				warn(
					"[CompanionManager.loadCompanionModel] Authored prefab",
					authored:GetFullName(),
					"rejected (empty MeshId) for",
					compType
				)
			end
		else
			print("[CompanionManager.loadCompanionModel] No authored prefab for", compType, "in catalog")
		end
	else
		print(
			"[CompanionManager.loadCompanionModel] No CompanionVisualCatalog/Prefabs folder — skipping catalog path for",
			compType
		)
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
			if result then
				return result
			else
				warn(
					"[CompanionManager.loadCompanionModel] InsertService asset",
					assetId,
					"rejected (empty MeshId / no real mesh) for",
					compType
				)
			end
		else
			warn(
				"[CompanionManager.loadCompanionModel] InsertService:LoadAsset failed for",
				compType,
				"assetId:",
				assetId,
				"success:",
				success
			)
		end
	else
		warn(
			"[CompanionManager.loadCompanionModel] No assetId configured for",
			compType,
			"- cannot InsertService fallback"
		)
	end

	-- HARD RULE: a companion is NEVER a cube. If no source resolved yet, wait for the
	-- authored catalog to be present/replicated and try it again, then give up with a
	-- loud error rather than ever spawning a placeholder.
	warn(
		"[CompanionManager.loadCompanionModel] No companion mesh resolved on first pass for",
		compType,
		"- waiting for authored prefab…"
	)
	local waited = catalog
	if not waited then
		waited = ServerStorage:WaitForChild("CompanionVisualCatalog", 10)
	end
	local waitedPrefabs = waited and waited:WaitForChild("Prefabs", 5)
	local retry = waitedPrefabs and (waitedPrefabs:FindFirstChild(compType) or waitedPrefabs:FindFirstChild("zundapal"))
	if retry and retry:IsA("Model") then
		local result = cacheClone(retry)
		if result then
			return result
		end
	end

	error(
		"[CompanionManager] FATAL: could not resolve a real companion mesh for '"
			.. tostring(compType)
			.. "'. Expected ServerStorage.CompanionVisualCatalog.Prefabs.zundapal (or a valid asset). Refusing to spawn a placeholder."
	)
end

-- Companion catalog sourced from Canonical CompanionConfig
local CompanionConfig = require(RS.ConfigurationFiles.CompanionConfig)
local COMPANIONS = CompanionConfig.companions

-- ── RemoteEvents ───────────────────────────────────────────────
local RE = RS:WaitForChild("RemoteEvents")
local setCompEv = RE:WaitForChild("SetCompanion")
local vnEv = RE:FindFirstChild("OpenCompanionVN")
if not vnEv then
	vnEv = Instance.new("RemoteEvent")
	vnEv.Name = "OpenCompanionVN"
	vnEv.Parent = RE
end

local activeCompanions = {}

-- ── Build companion ────────────────────────────────────────────
-- Resolve the companion definition for a build. Custom (player-created /
-- AI-generated) companions live in PlayerData.custom_companions[compType] and
-- are merged onto the catalog shape so the rest of buildCompanion (which reads
-- def.emoji / def.glow / def.sparkleColors / def.displayName / def.buff) works
-- unchanged. A custom companion reuses the shared base body (see loadCompanionModel's
-- default fallback for unknown keys), recolored per its spec.
local function resolveDef(player, compType)
	if type(compType) == "string" and string.sub(compType, 1, 3) == "cc_" then
		local data = PlayerDataService.get(player)
		local custom = data and data.custom_companions and data.custom_companions[compType]
		if custom and type(custom) == "table" then
			return {
				emoji = custom.emoji or "🌱",
				glow = custom.glow or Color3.fromRGB(180, 200, 255),
				glowRange = 18,
				sparkleColors = custom.sparkleColors or {},
				buff = custom.buff,
				displayName = custom.displayName or custom.name or "Zundamon",
				flavor = custom.flavor,
				persona = custom.persona,
				signature_recipes = custom.signature_recipes or {},
				synergy_gold = custom.synergy_gold or 5,
				isCustom = true,
			}
		end
	end
	return COMPANIONS[compType] or COMPANIONS.zundamon
end

local function buildCompanion(player, compType)
	print("[CompanionManager.buildCompanion] Building companion for", player.Name, "type:", compType)
	local def = resolveDef(player, compType)
	local name = "ZundaCompanion_" .. player.Name

	-- Remove existing
	local existing = workspace:FindFirstChild(name)
	if existing then
		print("[CompanionManager.buildCompanion] Removing existing companion")
		existing:Destroy()
	end
	local prev = activeCompanions[player.Name]
	if prev then
		pcall(function()
			prev:Destroy()
		end)
	end

	-- Load the full companion model. NEVER a cube: retry 3× with 1 s backoff, then abort
	-- (no companion this spawn) rather than fabricate a placeholder. Cube refusal is hard.
	local companionModel
	for attempt = 1, MESH_LOAD_MAX_RETRIES do
		local ok, result = pcall(loadCompanionModel, compType)
		if ok and result then
			if attempt > 1 then
				print("[CompanionManager.buildCompanion] mesh load succeeded on retry", attempt, "for", compType)
			end
			companionModel = result
			break
		end
		warn(
			"[CompanionManager.buildCompanion] mesh load attempt",
			attempt .. "/" .. tostring(MESH_LOAD_MAX_RETRIES),
			"failed for",
			compType,
			"-",
			tostring(result),
			(attempt < MESH_LOAD_MAX_RETRIES and "(retrying in 1s…)" or "(final — cube refusal)")
		)
		if attempt < MESH_LOAD_MAX_RETRIES then
			task.wait(1)
		end
	end

	if not companionModel then
		warn(
			"[CompanionManager.buildCompanion] Could not load a real companion mesh for",
			player.Name,
			"- refusing to spawn a placeholder. No companion this spawn."
		)
		return
	end

	companionModel.Name = name
	companionModel.Parent = workspace

	local body = companionModel.PrimaryPart
	if not body then
		body = companionModel:FindFirstChildWhichIsA("BasePart")
		companionModel.PrimaryPart = body
	end

	-- ── Animation support ──────────────────────────────────────────
	-- Detect Humanoid (Avatar-Importer rigs) or AnimationController (non-humanoid rigs).
	-- Rig upgrade path: import FBX via Avatar Importer Custom (see
	-- CompanionVisualConfig header) → Humanoid+Animator or AC+Animator. Code
	-- prefers Humanoid if present, else AC. Static MeshParts (no bones) degrade
	-- gracefully to VFX-only follow.
	local animator: Animator? = nil
	local humanoid = companionModel:FindFirstChildOfClass("Humanoid")
	local animationController = companionModel:FindFirstChildOfClass("AnimationController")

	if humanoid then
		-- Avatar rig: use Humanoid's Animator (R15/Custom assumptions, HipHeight auto)
		animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		print("[CompanionManager.buildCompanion] Using Humanoid Animator for", compType)
	elseif animationController then
		-- Non-humanoid rig (preferred for chibi creature): lighter, no Humanoid states
		animator = animationController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animationController
		end
		print("[CompanionManager.buildCompanion] Using AnimationController Animator for", compType)
	else
		-- Static mesh: no bones / no animation support — idle/walk will stay nil
		-- and follow logic degrades to VFX + physics only (no error spam).
		print(
			"[CompanionManager.buildCompanion] No Humanoid or AnimationController; animation disabled for",
			compType,
			"- static MeshPart only"
		)
	end

	-- Scale to roughly human height. The authored zundapal mesh is ~50 studs tall;
	-- a Roblox character is ~5. Scale by (target / current) so it stands human-sized.
	-- Scale guard 0.9-1.1 prevents re-scaling an already-correct rigged source and
	-- avoids physics thrash on repeated respawns.
	local currentHeight = companionModel:GetExtentsSize().Y
	if currentHeight > 0.1 then
		local factor = COMPANION_HEIGHT / currentHeight
		if factor < SCALE_GUARD_LOW or factor > SCALE_GUARD_HIGH then
			local okScale, errScale = pcall(function()
				companionModel:ScaleTo(companionModel:GetScale() * factor)
			end)
			if okScale then
				print(
					string.format(
						"[CompanionManager.buildCompanion] Scaled %s: height %.2f → %.2f (factor %.3f, guard %.1f-%.1f)",
						compType,
						currentHeight,
						COMPANION_HEIGHT,
						factor,
						SCALE_GUARD_LOW,
						SCALE_GUARD_HIGH
					)
				)
			else
				warn(
					"[CompanionManager.buildCompanion] ScaleTo failed for",
					compType,
					"factor",
					factor,
					"err:",
					tostring(errScale)
				)
			end
		else
			print(
				string.format(
					"[CompanionManager.buildCompanion] Scale guard: %s already %.2f studs (factor %.3f within %.1f-%.1f) — skipping rescale",
					compType,
					currentHeight,
					factor,
					SCALE_GUARD_LOW,
					SCALE_GUARD_HIGH
				)
			)
		end
	else
		warn(
			"[CompanionManager.buildCompanion] Suspicious extents height",
			currentHeight,
			"for",
			compType,
			"- skipping scale"
		)
	end

	-- Start near player
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	body.CFrame = hrp and (hrp.CFrame * CFrame.new(4, 1, 0)) or CFrame.new(47, 8, -74)

	-- Make all parts non-collidable and massless, with color fallback for untextured meshes.
	-- Audit: zundapalupdate4.mtl currently exports with blank TextureID and no
	-- SurfaceAppearance → falls back to flat ZundaGreen (160,210,150). After PBR
	-- re-import, SurfaceAppearance.ColorMap should be rbxassetid://<Zundamon_BaseColor>
	-- and this fallback will naturally stop firing (verify via ZundaPalette.verifyCompanionPBR).
	local fallbackCount = 0
	for _, part in ipairs(companionModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.CastShadow = false
			if
				part:IsA("MeshPart")
				and part.TextureID == ""
				and not part:FindFirstChildOfClass("SurfaceAppearance")
			then
				part.Color = Color3.fromRGB(160, 210, 150)
				part.Material = Enum.Material.SmoothPlastic
				fallbackCount += 1
			end
		end
	end
	if fallbackCount > 0 then
		print(
			string.format(
				"[CompanionManager.buildCompanion] Applied flat ZundaGreen fallback to %d MeshPart(s) for %s (no TextureID/SurfaceAppearance — see CompanionVisualConfig audit)",
				fallbackCount,
				compType
			)
		)
	else
		print(
			"[CompanionManager.buildCompanion] PBR path: no flat-color fallback needed for",
			compType,
			"(TextureID or SurfaceAppearance present)"
		)
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
		ColorSequenceKeypoint.new(0, sc[1]),
		ColorSequenceKeypoint.new(0.5, sc[2]),
		ColorSequenceKeypoint.new(1, sc[3]),
	})
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.4, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	-- ── Point light glow ──────────────────────────────────────
	local pl = Instance.new("PointLight", body)
	pl.Brightness = 0.6
	pl.Range = def.glowRange
	pl.Color = def.glow
	Tween
		:Create(pl, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Brightness = 1.0 })
		:Play()

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
	faceLabel.Size = UDim2.new(1, 0, 1, 0)
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
	pill.Size = UDim2.new(1, 0, 1, 0)
	pill.BackgroundColor3 = Color3.fromRGB(30, 24, 40)
	pill.BackgroundTransparency = 0.15
	pill.BorderSizePixel = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(0.5, 0)
	local nLbl = Instance.new("TextLabel", pill)
	nLbl.Size = UDim2.new(1, -8, 1, 0)
	nLbl.Position = UDim2.new(0, 4, 0, 0)
	nLbl.BackgroundTransparency = 1
	nLbl.Text = player.Name .. "'s " .. (def.displayName or "Companion") .. " ✨"
	nLbl.Font = Enum.Font.FredokaOne
	nLbl.TextSize = 12
	nLbl.TextColor3 = Color3.fromRGB(240, 230, 255)
	nLbl.TextXAlignment = Enum.TextXAlignment.Center

	-- ── ClickDetector for VN dialogue ─────────────────────────
	local cd = Instance.new("ClickDetector", body)
	cd.MaxActivationDistance = 20
	local lastClick = 0
	cd.MouseClick:Connect(function(clicker)
		local now = os.clock()
		if now - lastClick < 3 then
			return
		end
		lastClick = now
		sparkle.Rate = 60
		task.delay(0.6, function()
			if sparkle.Parent then
				sparkle.Rate = 10
			end
		end)
		-- Per-companion bond XP (distinct from the flat, global
		-- companion_affection/companion_chats counters QuestManager already
		-- tracks) -- the start of an Uma-Musume-style "bond with THIS specific
		-- companion" progression. Same 3s click cooldown as the VN trigger above.
		PlayerDataService.addCompanionBond(clicker, compType, 1)
		local bondTier = PlayerDataService.getCompanionBondTier(clicker, compType)
		vnEv:FireClient(clicker, compType, def.emoji, bondTier)
	end)

	activeCompanions[player.Name] = companionModel

	-- ── Smooth follow loop ─────────────────────────────────────
	-- Orientation correction is per-companion-type, not a blanket constant: the
	-- OLD static zundapal level-mesh was baked upside-down and needed a 180°
	-- roll, but that mesh is gone now (replaced by a properly Avatar-Imported
	-- rig, which comes in correctly oriented already) -- applying the old
	-- correction unconditionally was flipping the new rig upside-down instead
	-- of fixing it. Defaults to no correction; set per-type in
	-- CompanionVisualConfig only if a specific mesh actually needs one.
	local compVisualForOrient = CompanionVisualConfig.get(compType)
	local ORIENT_CORRECTION = (compVisualForOrient and compVisualForOrient.orientCorrection) or CFrame.identity
	do
		local t = 0
		local currentAnimState = "idle" -- Track current animation state
		local idleTrack = nil
		local walkTrack = nil

		-- Load animation tracks if animator is available. Clips are defined in
		-- CompanionVisualConfig.AnimationSpec (idle 2.0s loop, walk 1.0s loop,
		-- both Core, fade 0.2). Until Studio GUI upload provides IDs, both stay
		-- nil and the companion degrades to VFX-only follow — no error spam.
		if animator then
			local compVisual = CompanionVisualConfig.get(compType)
			local idleAnimId = compVisual and compVisual.idleAnimationId
			local walkAnimId = compVisual and compVisual.walkAnimationId

			if idleAnimId and idleAnimId ~= "" then
				local idleAnim = Instance.new("Animation")
				idleAnim.AnimationId = idleAnimId
				-- Guard LoadAnimation: a bad/missing animation asset makes
				-- LoadAnimation throw (e.g. "Argument 3 missing or nil" with a
				-- placeholder ID 2510798496 from playtest) and error-spams every
				-- build. Degrade to no track instead of crashing.
				local okIdle, trackOrErr = pcall(function()
					return animator:LoadAnimation(idleAnim)
				end)
				if okIdle and trackOrErr then
					idleTrack = trackOrErr :: AnimationTrack
					idleTrack.Priority = ANIM_PRIORITY
					idleTrack.Looped = true
				else
					warn(
						"[CompanionManager.buildCompanion] idle LoadAnimation failed for",
						compType,
						"id:",
						idleAnimId,
						"err:",
						tostring(trackOrErr)
					)
				end
			else
				print(
					"[CompanionManager.buildCompanion] idleAnimationId nil for",
					compType,
					"- awaiting Studio upload (2.0s loop, Core, fade 0.2)"
				)
			end

			if walkAnimId and walkAnimId ~= "" then
				local walkAnim = Instance.new("Animation")
				walkAnim.AnimationId = walkAnimId
				local okWalk, trackOrErr = pcall(function()
					return animator:LoadAnimation(walkAnim)
				end)
				if okWalk and trackOrErr then
					walkTrack = trackOrErr :: AnimationTrack
					walkTrack.Priority = ANIM_PRIORITY
					walkTrack.Looped = true
				else
					warn(
						"[CompanionManager.buildCompanion] walk LoadAnimation failed for",
						compType,
						"id:",
						walkAnimId,
						"err:",
						tostring(trackOrErr)
					)
				end
			else
				print(
					"[CompanionManager.buildCompanion] walkAnimationId nil for",
					compType,
					"- awaiting Studio upload (1.0s loop, Core, fade 0.2)"
				)
			end

			print(
				"[CompanionManager.buildCompanion] Animation tracks loaded for",
				compType,
				"- idle:",
				idleTrack ~= nil,
				"walk:",
				walkTrack ~= nil,
				"(Core, fade",
				ANIM_FADE,
				")"
			)
		else
			print(
				"[CompanionManager.buildCompanion] No animator for",
				compType,
				"- animation disabled (static mesh, no bones)"
			)
		end

		-- Runs on Heartbeat (matches render rate, ~60Hz) instead of a 20Hz
		-- task.wait loop -- the old low tick rate combined with a hard .CFrame
		-- write each tick (which forces a physics "snap" on an unanchored part)
		-- read as visible stutter, especially noticeable since the player moves
		-- at full frame rate. Same follow/orientation logic, just smoother cadence.
		local followConn
		followConn = RunService.Heartbeat:Connect(function(dt)
			if not (body and body.Parent and companionModel.Parent) then
				if followConn then
					followConn:Disconnect()
				end
				return
			end
			t = t + dt
			local char2 = player.Character
			local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
			if hrp2 then
				local floatY = math.sin(t * 1.1) * 0.7 + 1.8
				local sideOff = hrp2.CFrame.RightVector * (3.5 + math.sin(t * 0.3) * 0.4)
				local target = hrp2.Position + sideOff + Vector3.new(0, floatY, 0)
				local dist = (body.Position - target).Magnitude

				-- ── Animation state management ────────────────────────
				-- Spec: CompanionVisualConfig.AnimationSpec (idle 2.0s loop / walk 1.0s loop, Core, fade 0.2).
				-- State threshold 1.0 stud verified: isMoving = dist > 1.0 → walk, else idle.
				-- Physics moves when dist > 0.3 with velocity = min(dist*5, 35) (verified
				-- line 642) so the 0.7-stud hysteresis band (1.0 vs 0.3) prevents flicker
				-- at rest. Transition uses Stop(ANIM_FADE)/Play(ANIM_FADE) = 0.2s crossfade.
				local transitionThreshold = CompanionVisualConfig.AnimationSpec
						and CompanionVisualConfig.AnimationSpec.transitionThresholdStuds
					or 1.0
				local isMoving = dist > transitionThreshold
				local newAnimState = isMoving and "walk" or "idle"

				if newAnimState ~= currentAnimState then
					-- State transition: stop old, play new with 0.2s fade (Core priority)
					if currentAnimState == "idle" and idleTrack then
						idleTrack:Stop(ANIM_FADE)
					elseif currentAnimState == "walk" and walkTrack then
						walkTrack:Stop(ANIM_FADE)
					end

					if newAnimState == "walk" and walkTrack then
						walkTrack:Play(ANIM_FADE)
					elseif newAnimState == "idle" and idleTrack then
						idleTrack:Play(ANIM_FADE)
					end

					currentAnimState = newAnimState
				end

				-- ── Movement physics (verified 400-528) ───────────────
				-- dist > 0.3 threshold matches spec movementThresholdStuds; velocity
				-- scales with distance (dist*5 capped 35) for smooth catch-up without teleport.
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
		end)
	end

	return companionModel
end

-- ── Player lifecycle ───────────────────────────────────────────
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(2)
		local data = PlayerDataService.getOrCreate(player)

		-- Migration: convert old "zundapal" references to "zundamon"
		if data.active_companion == "zundapal" then
			data.active_companion = "zundamon"
		end
		if data.companion_owned_zundapal then
			data.companion_owned_zundamon = true
		end
		if data.companions_set and data.companions_set.zundapal then
			data.companions_set.zundamon = true
		end

		local compType = data.active_companion or "zundamon"
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
	if not data.companions_set then
		data.companions_set = {}
	end
	data.companions_set[compType] = true
	data.active_companion = compType
	buildCompanion(player, compType)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

Players.PlayerRemoving:Connect(function(player)
	local m = activeCompanions[player.Name]
	if m then
		m:Destroy()
		activeCompanions[player.Name] = nil
	end
end)

print("[CompanionManager v4] Full model loading with textures + sparkles + VN click ready")
print("[CompanionManager v4] Using zundapalupdate4 mesh as primary model source")
