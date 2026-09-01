# Zundamon Chef Master NPC Import Contract

The future gamewide Zundamon NPC is the emotional home base for chef progression. Players should return after earning XP to celebrate rank milestones, preview the next unlock, and receive a short scripted VN moment. Keep `RewardCore` authoritative for XP and levels.

## Studio model contract

1. Import the model as `ZundamonChefMaster` under `Workspace/NPCs`.
2. Give it a `PrimaryPart`; keep visual mesh parts inside the model.
3. Add CollectionService tag `ChefMasterNPC`.
4. Add attributes `NPCId = "zundamon_chef_master"`, `SpeakerKey = "chef_master"`, `InteractionDistance = 12`, and `PromptText = "Review Chef Journey"`.
5. Do not embed LocalScripts, remotes, or progression logic in the mesh.

## Intended promotion flow

`Interact → validate player/profile/distance → show tier and next requirement → confirm promotion → RewardCore validates banked XP → apply once → project HUD → play VN celebration`.

Levels currently advance automatically in `RewardCore`, so the first imported NPC should be informational. Moving to banked-XP promotions requires an explicit schema/migration decision and parity tests; do not silently change it during mesh import.

Place the NPC beside a recognizable kitchen landmark with a calm return path, warm green/gold glow, a chef-rank pennant, and one clear prompt. Dialogue should recognize the current tier, celebrate effort, preview one attainable goal, and never shame slow progress.

## Companion mesh variants

Repository-authored companion models override asset-ID fallbacks. Add each model under `src/shared/Models/Companions` using the exact key: `zundamon`, `zundacat`, `zundabunny`, `tantanmon`, `ankomon`, `cardamon`, `antimon`, or `sakuradamon`. Each must be a Model with a PrimaryPart (or at least one BasePart). Do not embed scripts; follow behavior, dialogue, VFX, ownership, and buffs remain keyed by the model name.

---

# Companion Pipeline — FBX → Rigged Model → Animation (Audit 2026-08-25)

Source: `crucialassets/zundapalupdate4.fbx` (440 KB, binary FBX 7.7, single FbxMesh, 36 Skeleton/LimbNode bones including thigh_stretch/leg_stretch/leg_twist/thigh_twist/c_* helpers, toes_01.l/.r, shoulder.l/.r, arm_stretch.l/.r, forearm_stretch/twist, neck.x, root; Skin 1, 36 Clusters, 75 Deformers; Take `root|rigAction` 1.0s, vertex TextureColor present). Runtime live mesh is `Workspace.Meshes/zundapalupdate4` — lone MeshPart `rbxassetid://124750913039753` wrapped to Model and scaled 5.2 studs (human) with flat ZundaGreen fallback `Color3.fromRGB(160,210,150)` when no SurfaceAppearance. Zero bones → no animation; blocked status in `docs/PLAYTEST_NOTES.md:15` is accurate until rig ships.

## 1) FBX Import Checklist (Avatar Importer Custom)

**Do not use R15 import.** Use **Avatar Importer → Custom** so the lightweight 36-bone helper rig imports without R15 retarget constraints (465-bone UE/Melusina skeletons are explicitly NOT needed here — keep ~30-40 deform bones).

1. Blender source (`zundapalupdate4.blend` → export `zundapalupdate4.fbx`):
   - Apply transforms (scale/rotation), verify no zero-weight verts (all verts weighted, normalized sum = 1.0), no ngons.
   - Export: Forward `-Z`, Up `Y`, Smoothing `Face`, `Tangent` on if normal maps, `Armature + Mesh` selected, leaf bones off, animation **off** unless exporting a baked take.
2. Studio: `Avatar Import Preview` → `Import` → `Custom` → select FBX:
   - Confirm preview shows single MeshPart + skeleton tree (Root → thigh_stretch → … → toes_01). If you see two meshes, you exported duplicates.
   - Import → Model appears in workspace. Rename to `zundapalupdate4_rigged` for verification, then move canonical copy to `ServerStorage.CompanionVisualCatalog.Prefabs.zundamon` (exact key from `CompanionConfig.lua`). Variant keys `zundacat`, `zundabunny`, `tantanmon`, `ankomon`, `cardamon`, `antimon`, `sakuradamon` plus extended catalog `sumimon`/`kagamon`/`suzurimon`/… share the base rig until own FBXs ship — they reuse `zundapalupdate4` basePrefab.
3. Verify:
   - Model is a `Model` (not lone MeshPart) with `PrimaryPart` set (root bone or HRP). CompanionManager wraps lone MeshParts, but a rigged Model must already have PrimaryPart.
   - At least one `MeshPart` descendant has non-empty `MeshId` (empty = cube, rejected by `hasRealMesh` at `src/server/CompanionManager.server.lua:26`). Check `MeshId ~= ""`.
   - No scripts/remotes inside the Model.

## 2) SurfaceAppearance Setup (PBR)

The current level mesh has `TextureID == ""` and no `SurfaceAppearance` → `CompanionManager.server.lua:368` falls back to flat `Color 160,210,150 / SmoothPlastic` (verified live, not white). After rig ships, wire PBR:

1. Select the imported `MeshPart`(s) → Add `SurfaceAppearance`:
   - `ColorMap` = `rbxassetid://<Zundamon_BaseColor>` (baked albedo from `.spp` / Substance `zundapal_lowpolybake.spp` 57 MB).
   - `NormalMap`, `RoughnessMap`/`MetalnessMap` if available (pack per Roblox spec).
   - `AlphaMode = Overlay` for lash/eye cards that need transparency.
2. Leave `TextureID` blank when `SurfaceAppearance` is present (they are mutually exclusive; SurfaceAppearance wins).
3. Verify in Explorer: `MeshPart → SurfaceAppearance → ColorMap` non-empty, `MeshId` non-empty. Run `ZundaPalette.verifyCompanionPBR()` playtest helper or inspect `CompanionManager` fallback log: `PBR path: no flat-color fallback needed` means wiring is correct; `Applied flat ZundaGreen fallback to N MeshPart(s)` means `ColorMap` is still missing.
4. Save place and commit the palette reference in `src/Plugins/ZundaPalette.lua` (canonical Infinity Nikki pastel: ZundaGreen 160,210,150 etc. — AGENTS.md §7).

## 3) Rig Upgrade Path (Humanoid/Animator vs AnimationController)

- **Lightweight, not 465 bones.** The source rig is 36 bones with twist/stretch helpers — keep it. Roblox cannot drive a 465-bone skeleton efficiently and the chibi model does not need it. Weight paint must be normalized; helpers (`c_arm_stretch`, `c_thigh_stretch`) carry 0.3–0.5 weights to prevent elbow/knee collapse.
- **Avatar Importer Custom creates:**
  - Option A — **Humanoid + Animator**: importer auto-adds `Humanoid` (HipHeight ~2, auto) and `Animator` under the Model. Preferred when you want Humanoid states/ground ray, but brings R15 state overhead.
  - Option B — **AnimationController + Animator** (recommended for companion): delete the auto `Humanoid`, add `AnimationController` + `Animator` under the Model. Lighter, no Humanoid states — CompanionManager detects either (`src/server/CompanionManager.server.lua:283-308`). Both require an `Animator` child; code creates one if missing.
- Orientation: the old static level mesh was baked upside-down and needed `orientCorrection = CFrame.Angles(0, pi, 0)` (180° Y). A correctly Avatar-Imported rig comes oriented already — `CompanionVisualConfig.visuals.<key>.orientCorrection` defaults to `identity` (nil) except legacy `zundamon`/`zundapal` entries that keep 180° until the rig replaces the static MeshPart. Do not apply 180° unconditionally or the new rig flips.
- Scale: importer preserves ~50-stud height; `CompanionManager` rescales to 5.2 studs (`Model:ScaleTo`) with guard 0.9-1.1 (`src/server/CompanionManager.server.lua:15,362`). Already-correct rigs skip rescale. Do not manually pre-scale in Blender — let runtime handle it.

## 4) Animation Asset Upload Steps (Studio GUI only)

Code is ready for IDs; all `idleAnimationId`/`walkAnimationId` are `nil` pending upload (graceful VFX-only degrade, no error spam). When the rig is in place:

1. Select the rigged Model in Studio → `Animation Editor` → `Create New`.
2. Clip A — **idle / wait**: 2.0 s, 30 fps (60 keys), loop `true`, subtle breathe/sway + ear twitch, root motion OFF (movement is driven by follow physics `AssemblyLinearVelocity`, not root motion).
3. Clip B — **walk**: 1.0 s, 30 fps (30 keys), loop `true`, one full step cycle, root motion OFF.
4. `Menu → Publish to Roblox` → each clip becomes an Animation asset (`rbxassetid://…`). Copy IDs.
5. Paste into `src/shared/ConfigurationFiles/CompanionVisualConfig.lua`:
   ```lua
   zundamon = {
       modelAssetId = "rbxassetid://121481310719137",
       basePrefab = "zundapalupdate4",
       idleAnimationId = "rbxassetid://<idle-2.0s-loop>",
       walkAnimationId = "rbxassetid://<walk-1.0s-loop>",
       orientCorrection = nil, -- remove 180° once rig replaces static MeshPart
   },
   ```
   Repeat for any variant that gets its own clips; shared zundapal rig can reuse the same IDs until per-companion clips exist.
6. Properties: both clips `Priority = Core` (`Enum.AnimationPriority.Core`), crossfade 0.2 s (`ANIM_FADE`, `src/server/CompanionManager.server.lua:18,539`). Loader sets `track.Priority = Core`, `track.Looped = true` and does `Stop(0.2)/Play(0.2)` on transition (`src/server/CompanionManager.server.lua:551-650`, threshold `dist > 1.0` → walk else idle, physics moves when `dist > 0.3` with `min(dist*5,35)`).

## 5) Fallback & Robustness (verify in Studio)

- Empty MeshId rejection: `hasRealMesh` (`CompanionManager.server.lua:26`) rejects any `MeshPart` where `MeshId == ""` — those are the cubes/placeholders from empty catalog entries (`ServerStorage.CompanionVisualCatalog.Prefabs.zundapal` with blank MeshId). `cacheClone` warns `REJECTED empty MeshId source … refusing cube placeholder`.
- Cube refusal: if no source resolves, `loadCompanionModel` errors loudly instead of spawning a cube (`error "[CompanionManager] FATAL… Refusing to spawn a placeholder."` at line 153). `buildCompanion` catches via 3× retry then aborts (`Could not load a real companion mesh — refusing to spawn a placeholder. No companion this spawn.`).
- Retry 3×: `buildCompanion` retries `loadCompanionModel` 3 times with 1 s backoff (`MESH_LOAD_MAX_RETRIES`, `src/server/CompanionManager.server.lua:245`), logging `mesh load attempt 1/3 failed … (retrying in 1s…)` — matches `PLAYTEST_NOTES.md` fix #1 verification (`extents 4.9×5.2×4.0`).
- Scale guard 0.9-1.1: `if factor < 0.9 or factor > 1.1 then ScaleTo else skip` (`src/server/CompanionManager.server.lua:362`), logging scaled height or `Scale guard: already X studs (factor Y within 0.9-1.1) — skipping rescale`. Prevents physics thrash on repeated respawns.
- Logging: all paths now warn with full `GetFullName()` and asset IDs; `playtest` `Argument 3 missing or nil` errors from bad `AnimationId` 2510798496 are guarded by `pcall(animator:LoadAnimation)` and degrade to `walkAnimationId nil … awaiting upload` info logs instead of spam.
