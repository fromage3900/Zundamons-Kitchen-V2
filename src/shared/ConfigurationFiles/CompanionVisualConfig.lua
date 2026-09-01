--!strict
-- Git-backed companion visual defaults. Studio-owned entries under
-- ServerStorage.CompanionVisualCatalog override these without script edits.
--
-- ============================================================================
-- AUDIT 2026-08-25 — Companion Visual Pipeline (Zundapal → AAA)
-- ============================================================================
-- Source mesh (authored): crucialassets/zundapalupdate4.fbx (440 KB, binary
-- FBX 7.7, 1 FbxMesh, 36 Skeleton/LimbNode, 36 Cluster/Skin, single Take
-- "root|rigAction" 1.0s, vertex TextureColor). Imported in Studio as
-- Workspace.Meshes/zundapalupdate4 — MeshPart, MeshId
-- rbxassetid://124750913039753, wrapped to Model at runtime.
--
-- | # | Companion key | modelAssetId (fallback)          | basePrefab        | MeshPart vs Model          | SurfaceAppearance | PrimaryPart          | Scale               | Orient |
-- |---|---------------|----------------------------------|-------------------|------------------------------|-------------------|----------------------|---------------------|--------|
-- | 1 | zundamon      | rbxassetid://121481310719137    | zundapalupdate4   | Live: Model (wrapped MeshPart); Asset: Model | None (flat fallback) | Wrapped MeshPart | 5.2 stud (factor-guarded 0.9-1.1) | 180° Y (legacy static mesh) |
-- | 2 | zundapal      | rbxassetid://121481310719137    | zundapalupdate4   | Same as zundamon (alias)   | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- | 3 | dog           | rbxassetid://123070508686616    | dog               | Asset Model                | Unknown (verify)  | First BasePart     | 5.2                 | identity (rig is correctly oriented) |
-- | 4 | parrot        | rbxassetid://84382956251208     | parrot            | Asset Model                | Unknown           | First BasePart     | 5.2                 | identity |
-- | 5 | cat           | rbxassetid://131662379743903    | cat               | Asset Model                | Unknown           | First BasePart     | 5.2                 | identity |
-- | 6 | zundacat      | rbxassetid://101663144452966    | zundapalupdate4   | Shares zundapal mesh until own rig ships | None | Wrapped MeshPart | 5.2       | 180° Y (inherits base) |
-- | 7 | zundabunny    | rbxassetid://76425192775041     | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- | 8 | tantanmon     | rbxassetid://107150527246774    | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- | 9 | ankomon       | rbxassetid://110290651922538    | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- |10 | cardamon      | rbxassetid://91041813069462     | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- |11 | antimon       | rbxassetid://94125444857929     | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- |12 | sakuradamon   | rbxassetid://128478553136178    | zundapalupdate4   | Shares zundapal mesh       | None                | Wrapped MeshPart   | 5.2                 | 180° Y |
-- |13+| sumimon/kagamon/suzurimon/wasabimon/yurimon/kinakomon/kuroyurimon/matchamon/shisomon/karintomon/tsukimidamon/hoshidamon | fallback defaultAssetId | zundapalupdate4 | Shares zundapal mesh (no own asset yet) | None | Wrapped MeshPart | 5.2 | 180° Y until custom rig |
-- Fallback color for untextured MeshParts (no TextureID + no SurfaceAppearance) is
-- Color3.fromRGB(160,210,150) (ZundaGreen) with SmoothPlastic — see
-- CompanionManager.server.lua:302. CompanionManager rejects any MeshPart with
-- empty MeshId (hasRealMesh) so a cube is structurally impossible.
--
-- ============================================================================
-- RIG UPGRADE PATH — FBX → Rigged Model (Avatar Importer Custom)
-- ============================================================================
-- Goal: replace lone static MeshPart with a skinned Model (Humanoid/Animator or
-- AnimationController/Animator), keep 5.2-stud scaling and follow logic intact.
--
-- 1. Blender source (crucialassets/zundapalupdate4.fbx):
--    Rig has 36 bones (thigh_stretch.l/.r, leg_stretch, leg_twist, thigh_twist,
--    c_*_stretch, shoulder.l/.r, arm_stretch, forearm_stretch/twist, toes_01,
--    neck.x, root). This is a lightweight helper-bone rig (NOT a 465-bone
--    UE/AAA skeleton) — ideal for Roblox. Do NOT inflate to 465 bones; keep
--    ~30-40 deform bones + helpers. Weight paint must be normalized (all verts
--    influenced, sum = 1.0, no zero-weight verts).
-- 2. FBX export: Apply transforms, Forward -Z / Up Y, Smoothing Face, Tangent
--    enabled if using normal maps, Armature + Mesh selected, Animation enabled
--    only for the rig + baked takes (otherwise export with no animation and
--    upload clips separately).
-- 3. Studio import — Avatar Importer **Custom** (NOT R15): Game Settings →
--    Avatar → Import → Custom. Set Rig Type = Custom, ensure HipHeight is
--    auto, verify PrimaryPart is the root/HRP bone. Confirm MeshId non-empty,
--    SurfaceAppearance.ColorMap present, and skeleton appears under the Model.
--    Humanoid path: importer creates Humanoid + Animator under the Model.
--    AnimationController path: for pure creatures, delete Humanoid after import
--    and add AnimationController + Animator (legs-less companion prefers this).
--    CompanionManager.server.lua:250-271 detects either and loads tracks.
-- 4. SurfaceAppearance: assign ColorMap = rbxassetid://<Zundamon_BaseColor>,
--    NormalMap/RoughnessMap if available, AlphaMode Overlay for lashes.
--    See docs/ZUNDAMON_CHEF_MASTER_IMPORT.md § SurfaceAppearance setup.
-- 5. Prefab placement: save rigged Model to ServerStorage.CompanionVisualCatalog
--    .Prefabs.<companionKey> (e.g. Prefabs.zundamon) with the exact key from
--    CompanionConfig.lua (init.meta.json is Folder). This outranks asset-ID
--    loads — see CompanionManager.server.lua:88-98.
-- 6. Animation clips: upload as Roblox Animation assets (see spec below), paste
--    IDs into idleAnimationId / walkAnimationId. Code is ready for IDs; nil
--    degrades to VFX-only follow with a log (no error spam).
--
-- Humanoid/Animator vs AnimationController:
--   Humanoid gives automatic HipHeight/ground ray, but enforces R6/R15
--   assumptions and extra states. AnimationController is lighter and ideal for
--   chibi creatures with no Humanoid states needed — either works; the loader
--   prefers Humanoid if present, else AC. Both must have an Animator child.
--
-- ============================================================================
-- ANIMATION SPEC — two clips, ready for IDs (code gated, no upload yet)
-- ============================================================================
-- | Clip | Name   | Length | Loop | Priority     | Fade | Playback | Notes |
-- |------|--------|--------|------|--------------|------|----------|--------------------------------|
-- | idle | wait   | 2.0 s  | true | Core (Enum.AnimationPriority.Core) | 0.2 s in/out | weight 1, speed 1 | Subtle breathe/idle sway + ear twitch; 30 fps, 60 keys. Looped. Root motion OFF. |
-- | walk | walk   | 1.0 s  | true | Core | 0.2 s | weight 1, speed scales with | Cycle covers 1 step pair; 30 fps, 30 keys. Root motion OFF — movement driven by CompanionManager follow physics (AssemblyLinearVelocity). |
--
-- State machine: CompanionManager.server.lua:507-543 — distance threshold 1.0 stud
--   isMoving = dist > 1.0 → walk, else idle. Transition Stop(0.2)/Play(0.2).
--   Physics moves when dist > 0.3 with velocity = min(dist*5, 35). History:
--   Heartbeat cadence (~60 Hz) replaces old 20 Hz task.wait to remove stutter.
--   Threshold verified: 1.0 stud gives a hysteresis band vs 0.3 stop so the
--   companion does not flicker at rest.
--
-- Upload steps (Studio GUI): select rigged Model → Animation Editor → Create
--   new → import FBX take or keyframe → publish to Roblox → copy rbxassetid://…
--   → paste into visuals[companionKey].idleAnimationId / walkAnimationId.
--   See docs/ZUNDAMON_CHEF_MASTER_IMPORT.md § Animation asset upload.
--
-- Fallback & robustness: empty MeshId rejected (hasRealMesh), cube refused
--   (error instead of placeholder), load retried 3× with 1 s backoff, scale
--   guard 0.9-1.1 prevents re-scaling an already-correct source. Logging
--   improved to warn on each rejection/retry at CompanionManager lines below.

local CompanionVisualConfig = {}

CompanionVisualConfig.defaultAssetId = "rbxassetid://84382956251208"
CompanionVisualConfig.defaultPrefab = "zundapalupdate4"

-- Animation spec constants (mirror the table above; consumed by docs and future tooling)
CompanionVisualConfig.AnimationSpec = {
	idle = {
		name = "wait",
		lengthSeconds = 2.0,
		loop = true,
		priority = Enum.AnimationPriority.Core,
		fadeSeconds = 0.2,
	},
	walk = {
		name = "walk",
		lengthSeconds = 1.0,
		loop = true,
		priority = Enum.AnimationPriority.Core,
		fadeSeconds = 0.2,
	},
	transitionThresholdStuds = 1.0,
	movementThresholdStuds = 0.3,
}

CompanionVisualConfig.visuals = {
	zundamon = {
		modelAssetId = "rbxassetid://121481310719137",
		basePrefab = "zundapalupdate4",
		-- TODO(upload): replace nil with rbxassetid://<idle> and rbxassetid://<walk> after Studio upload
		-- idle: 2.0s loop, walk: 1.0s loop, both Core, fade 0.2 (see header spec)
		idleAnimationId = nil,
		walkAnimationId = nil,
		orientCorrection = CFrame.Angles(0, math.rad(180), 0),
	},
	zundapal = {
		modelAssetId = "rbxassetid://121481310719137",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
		orientCorrection = CFrame.Angles(0, math.rad(180), 0),
	}, -- Backward compat alias
	dog = {
		modelAssetId = "rbxassetid://123070508686616",
		basePrefab = "dog",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	parrot = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "parrot",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	cat = {
		modelAssetId = "rbxassetid://131662379743903",
		basePrefab = "cat",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	zundacat = {
		modelAssetId = "rbxassetid://101663144452966",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	zundabunny = {
		modelAssetId = "rbxassetid://76425192775041",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	tantanmon = {
		modelAssetId = "rbxassetid://107150527246774",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	ankomon = {
		modelAssetId = "rbxassetid://110290651922538",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	cardamon = {
		modelAssetId = "rbxassetid://91041813069462",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	antimon = {
		modelAssetId = "rbxassetid://94125444857929",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	sakuradamon = {
		modelAssetId = "rbxassetid://128478553136178",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	-- Extended catalog companions (added 2026-08-25 audit): share zundapal rig until own rigs ship.
	-- Each reuses basePrefab zundapalupdate4 so the loader finds Workspace.Meshes/zundapalupdate4
	-- without falling back to dead asset IDs. Override per-type when custom FBX + animations exist.
	sumimon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	kagamon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	suzurimon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	wasabimon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	yurimon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	kinakomon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	kuroyurimon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	matchamon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	shisomon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	karintomon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	tsukimidamon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
	hoshidamon = {
		modelAssetId = "rbxassetid://84382956251208",
		basePrefab = "zundapalupdate4",
		idleAnimationId = nil,
		walkAnimationId = nil,
	},
}

function CompanionVisualConfig.get(companionKey: string): any
	return CompanionVisualConfig.visuals[companionKey]
		or { modelAssetId = CompanionVisualConfig.defaultAssetId, basePrefab = CompanionVisualConfig.defaultPrefab }
end

return table.freeze(CompanionVisualConfig)
