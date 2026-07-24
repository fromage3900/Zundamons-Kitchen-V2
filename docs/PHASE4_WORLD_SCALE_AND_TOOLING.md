# Phase 4 — World Scale & Authoring Tooling

Author: research pass, 2026-07-24. Companion to `docs/PHASE4_MONETIZATION_PLAN.md`
(economy) and `docs/PHASE4_GAMEPLAY_DIRECTION.md` (systems direction). This doc
covers two problems the user flagged directly: (A) procedural set-dressing reads
as "too simple and small" for an AAA-scale ambition, and (B) whether the
resource-visual authoring plugin + `ServerStorage.AssetLibrary` convention is a
complete, self-serve ecosystem yet. Every current-behavior claim is cited
`file:line`. Research only — no source files were modified.

---

## Part A — Procedural set-dressing: why it feels small, and the path to AAA scale

### A.1 What the runtime spawner actually does today

`src/server/ProceduralLandscapeSpawner.server.lua` runs once at server start
(`:114`, `spawnAllBiomes()` at module scope) and iterates the 10 biomes in
`LandscapeConfig.biomes` (`LandscapeConfig.lua:6`): GardenVillage, ZundaMarket,
Promenade, Forest, BerryOrchard, MeadowPlaza, SunsetGrove, WheatField,
WheatCrystalGarden, MoonlitGarden.

- **Placement algorithm:** not scatter/poisson-disc at all — it's a fixed,
  hand-authored zone→asset-profile table. Each biome has 3–4 named `zones`
  (e.g. GardenVillage's `Plaza`/`GardenEdge`/`MarketRow`/`PathLoop`,
  `LandscapeConfig.lua:11-16`) each with a `size` in **studs**, capped at
  18–24 (`LandscapeConfig.lua:12-15`). `ProceduralLandscape.generateBiomePlan`
  (`src/shared/Shared/Modules/ProceduralLandscape.lua`) turns each zone's
  `assetProfiles` entries (weighted asset/category pairs, e.g.
  `LandscapeConfig.lua:18-22`) into concrete `placements` with local `x`/`z`
  offsets in roughly ±12 studs (comment, `ProceduralLandscapeSpawner.server.lua:11-12`).
  There is no randomized surface sampling, no poisson-disc spacing, no
  raycast-driven organic scatter in this system — placements are deterministic
  per-biome recipes.
- **Density:** each biome's asset profile lists on the order of 6–10 placement
  slots total across all its zones (e.g. GardenVillage: 3 in `plaza` + 3 in
  `garden` + 2 in `market` + 2 in `path` = 10 slots, `LandscapeConfig.lua:17-36`).
  Combined with a zone size ceiling of ~24 studs, each biome occupies a
  **10-20-stud-radius clump with roughly a dozen props** — this is the direct
  source of "too simple and small."
- **Asset pool:** every placement resolves through `ArchitectureVariants`
  (`ProceduralLandscapeSpawner.server.lua:45`), which is supposed to be
  "auto-generated from the Kenney kit" but **only ever got one real mesh
  entry checked in** — `Lantern` (`ArchitectureVariants.lua:7-8`,
  `rbxassetid://9854046603`). Every other asset name (`MarketHall`,
  `BakeryStall`, `Bench`, `ZundaFlower`, `BerryBush`, `ZundaMushroom`,
  `StreetLamp`) has no real mesh ID, so `spawnMesh` (:42-87) falls through to
  `ProceduralPropBuilder.build` (`ProceduralPropBuilder.lua:173-184`), which
  constructs each prop from `Part`/`Ball`/`Cylinder` primitives in a 7-shape
  hardcoded palette (`ProceduralPropBuilder.lua:14-169`). **The entire visible
  world outside interiors is Part-built primitives, not real meshes** — no
  Greybox_Kit pieces, no uploaded assets, nothing from the new asset pipeline
  is wired into this path today.
- **World-space bug already fixed this session:** biome zone-plans used to
  render on top of each other near the origin; `BIOME_WORLD_CENTERS`
  (`ProceduralLandscapeSpawner.server.lua:21-32`) now spreads the 10 biomes
  across roughly a 350×250-stud playable area, but each individual biome is
  still only ~20 studs of actual dressed content inside that footprint — i.e.
  10 small islands of decoration in a big empty field, not 10 densely-dressed
  destinations.

### A.2 The Studio-plugin decorator system — parallel, unused, and disconnected

`src/Plugins/*.lua` (`ZundaWorldDecorator.plugin.lua` + 8 modules,
`plugin.project.json`, `README.md`) is a genuinely more sophisticated
architecture: `ScatterEngine.lua` does real Region3 surface scanning
(`:9-37`) and raycast-based random surface sampling with exclusion tags and
target-count-from-area math (`:39-83`, `targetCount = area * density / 100`,
`:47`) — actual poisson-ish random scatter, not a fixed recipe.
`ProceduralGeometry.lua` builds decorations from a 10-entry `DecorationCatalog`
(`lantern_post`, `cherry_tree`, `flower_cluster`, `glow_mushroom`,
`floating_crystal`, `meditation_circle`, `pastel_archway`, `wind_chime`,
`crystal_spire`, `signpost` — `DecorationCatalog.lua:43-234`), with per-decoration
scale jitter and rotation jitter (`ProceduralGeometry.lua:44-68`).
`LODManager.lua` does real distance-banded LOD (`:14-19`, 4 tiers out to 200
studs) that fades transparency and dims lights by camera distance
(`:62-85`). `SetDressingRules.lua` generates distant background silhouettes
(6 vista templates — rolling hills, pagoda, floating crystals, snow peaks,
ruins, kitchen garden, `:9-125`) and has a weather-reaction hook (currently a
no-op that only prints, `:148-163`). `UndoManager.lua` wires into
`ChangeHistoryService` for real Studio undo/redo of decoration batches
(`:12-36`).

**Confirmed disconnected from the runtime game, not merely dormant:**
- `ZoneProfiles.lua` defines **6 zones with different names** — `Village`,
  `Pagoda`, `MysticForest`, `AncientRuins`, `EastPeaks`, `Kitchen`
  (`ZoneProfiles.lua:7-46`) — none of which match any of the 10 real biome
  names in `LandscapeConfig.biomes`. This plugin was built against a zone
  taxonomy that was never reconciled with the shipped biome system.
  `ZoneProfiles.getZone("GardenVillage")` (the real biome) returns `nil`.
- It is a **Studio-only local plugin**, installed manually per the README
  (`src/Plugins/README.md:7-21`) via `rojo build … -o build/ZundaWorldDecorator.rbxm`
  dropped into the Studio Plugins folder — it is never part of the synced game
  tree (`plugin.project.json` builds a separate output, not `src/**` in the
  main `default.project.json`), and its output is never referenced by any
  server/client script. `grep` across `src/server` and `src/client` for
  `ZundaWorldDecorator`/`ScatterEngine`/`DecorationCatalog` (the plugin's own
  module names) returns nothing outside `src/Plugins/` itself.
  `git status` also shows a **deleted** `src/Plugins/Config.DecorationCatalog.lua`
  alongside the new files — evidence of an in-progress, not-yet-stabilized
  build artifact, not a finished shipped tool.
- Net effect: **this is unused scaffolding for a would-be authoring tool**,
  built to a different (probably earlier or aspirational) zone list than the
  one the game actually ships with. It is not redundant with the runtime
  spawner in the sense of both doing the same job on the same data — it's
  disconnected because it targets data (`ZoneProfiles`) the runtime system
  doesn't use, and outputs Part-primitive decorations that don't feed
  `LandscapeConfig`/`ArchitectureVariants` either. It is, however, the
  **stronger algorithm** (real surface scatter + LOD + undo) and is worth
  salvaging rather than the runtime spawner's fixed-recipe placement.

### A.3 What "AAA scale" actually requires here, and the gap

Reference points for a cozy-life-sim of this genre (Infinity Nikki-tier):
- **Density per biome:** hundreds of placed instances per destination, not
  dozens — layered as hero props (5–15 unique/authored pieces), mid-detail
  clutter (50–150 repeated-but-varied props), and ground scatter (200+ small
  instances: grass tufts, pebbles, litter) — current biomes have ~10 *slots*
  total, three orders of magnitude below this.
- **Layered scale:** hero silhouettes readable from far away, mid-ground
  detail readable from walking distance, near-field texture readable up
  close. Today there is no far-silhouette layer at all in the runtime game
  (the plugin's `SetDressingRules` vista system is the only code that does
  this, and it's disconnected — see A.2).
  ​
- **Variation:** avoid the "stamped-out" look — current system has exactly 7
  procedural prop shapes total (`ProceduralPropBuilder.lua:161-169`) reused
  across all 10 biomes with only palette-color changes, so every biome
  visually repeats the same bench/lamp/stall/flower/bush/mushroom regardless
  of its supposed identity (WheatCrystalGarden vs. MoonlitGarden currently
  read almost identically because both draw from the same 7-shape pool).
- **LOD/streaming on Roblox:** Roblox has no native imposter/nanite-style
  system; practical AAA-density on this platform means (1) real `MeshPart`s
  with baked-in LOD via `RenderFidelity`/`StreamingEnabled` region streaming,
  (2) instance count discipline (thousands of small unanchored `Part`s per
  biome will tank client frame time — the plugin's `LODManager` fade-by-distance
  approach, `LODManager.lua:62-85`, is a reasonable client-side mitigation but
  doesn't reduce the underlying part count/network replication cost the way
  real mesh LOD/streaming would), and (3) using `WorldModel`/`StreamingEnabled`
  workspace streaming (not currently referenced anywhere in `src/server` —
  worth confirming project streaming settings separately).
- **Real meshes vs. procedural primitives:** the newly-built asset pipeline
  (`tools/asset-pipeline/`, `upload-asset.js`/`upload-batch.js`, real Open
  Cloud uploads owned by the correct creator — see Part B) is the answer to
  the permission wall that made `ArchitectureVariants` stall at 1 real mesh
  entry. The manifest already references "Greybox_Kit modular architecture
  blocks" for Zundarooms (`tools/asset-pipeline/README.md:37-38`) — the same
  upload path can mint real mesh IDs for market stalls, lamps, fences, and
  foliage kits, feeding `ArchitectureVariants` directly instead of leaving it
  permanently stuck behind `ProceduralPropBuilder`'s primitive fallback.

### A.4 Recommendations, ranked by effort:impact

1. **(High impact, low effort) Raise density inside the existing recipe
   system first, before touching architecture.** `LandscapeConfig.lua`'s
   `assetProfiles` tables are pure data — adding 3–5x more placement entries
   per zone (more benches, more flower clusters, more repeated small props at
   varied local offsets) costs no new code and immediately makes each biome
   read as "dressed" instead of "sparse." This alone won't fix repetition
   (still only 7 shapes) but is the cheapest lever to pull first.
2. **(High impact, medium effort) Feed real Greybox_Kit/Kenney meshes into
   `ArchitectureVariants` via the asset pipeline, replacing `ProceduralPropBuilder`
   as the default path, not just the emergency fallback.** This directly
   attacks the "looks procedural/primitive" complaint and requires no new
   runtime code — `ProceduralLandscapeSpawner.server.lua:47-52` already
   prefers a real `meshId` when `ArchitectureVariants` has one; it's purely a
   content-population problem now that the upload path exists.
3. **(Medium impact, medium effort) Add a ground-clutter/far-silhouette pass
   distinct from hero props.** Nothing today places small-scale ground
   texture (grass tufts, pebbles) or distant vistas in the runtime game. The
   plugin's `SetDressingRules.vistaTemplates` (`SetDressingRules.lua:9-125`)
   is a directly reusable starting point for far silhouettes if ported into a
   runtime module (it's currently pure Part-geometry, Studio-plugin-only —
   no real asset dependency, so porting is copy-and-call, not a rewrite).
4. **(Medium impact, higher effort) Reconcile or retire the Studio-plugin
   decorator.** Its `ScatterEngine`/`LODManager` algorithms are more capable
   than the runtime fixed-recipe system, but it targets a dead zone taxonomy
   (`ZoneProfiles`) and produces disconnected output. Either (a) port
   `ZoneProfiles` to the real 10 biome names and wire its output into
   `LandscapeConfig`-compatible placements so a designer can *author* biome
   recipes visually instead of hand-editing Lua tables, or (b) explicitly mark
   it dead/experimental in the README so it stops looking like a maintained
   parallel system. Don't leave it in its current half-connected state.
5. **(Lower priority, high effort) True instance-count-scaled AAA density
   (hundreds of props/biome) with region streaming.** Worth doing only after
   #2 lands — no point densifying primitive-Part clutter; do it once real
   meshes are in place so the added instances are actually higher production
   value, not more of the same repeated shapes.

---

## Part B — Resource-visual authoring + `ServerStorage.AssetLibrary`: ecosystem gaps

### B.1 Current shape of the system

`ResourceVisualService.lua` (`src/server/Services/ResourceVisualService.lua`)
is the authoritative runtime resolver, with resolution order confirmed at
`applyModel` (`:361-413`) and `applyMeshAsync` (`:415-478`): **(1) baked
prefab in `ServerStorage.AssetLibrary.ResourceNodes.<VisualVariant>`** checked
first (`:364-383`, `:416-435`), **(2) `InsertService:LoadAsset`/`ContentProvider`
fallback** for third-party/public asset IDs (`:385-412`, `:437-477`), **(3)
Part-primitive procedural fallback** built per-archetype in `buildFallback`
(`:99-229`) always present underneath so nothing is ever invisible.
`tools/resource-visual-authoring/ResourceVisualAuthoringPlugin.server.lua`
authors into that same `AssetLibrary.ResourceNodes` folder (`getAssetLibraryPrefab`,
`:348-365`; checked first in `applyToRoot`, `:367-390`) and separately maintains
a `ServerStorage.ResourceVisualCatalog.Entries` JSON-exportable snapshot
(`catalogRoot`/`writeCatalogEntry`, `:317-346`; export/import buttons,
`:601-649`).

`tools/asset-pipeline/upload-asset.js`/`upload-batch.js` mint real Open Cloud
asset IDs owned by the correct creator (`CreatorId = 3930496852`,
`tools/asset-pipeline/README.md:5-8`), fixing the root cause of "you don't
have authority to use this asset ID." The README is explicit that the
uploader's output is **not** auto-placed — it lands in the Roblox inventory
and must be manually Toolbox-dragged in, then moved into
`ServerStorage.AssetLibrary.<System>.<name>` (`tools/asset-pipeline/README.md:50-60`).

### B.2 Gap 1 — Upload → AssetLibrary is a manual, undocumented-in-tooling handoff

Confirmed: there is no code path connecting `upload-asset.js`'s output (an
asset ID printed to stdout) to Studio placement. The README's own instructions
(`:50-60`) are the entire "integration" — a human must Toolbox-search, drag,
rename, and re-parent by hand every time. This is a real gap for a solo dev
doing this repeatedly (every resource node variant, companion, room segment).
**Recommendation:** a "Insert last uploaded asset" button in
`ResourceVisualAuthoringPlugin.server.lua` that reads `upload-results.json`
(already produced by `upload-batch.js`, gitignored per README:46-48) via
`HttpService`-adjacent file read is not possible from a Studio plugin sandbox
(no filesystem access) — so the realistic fix is smaller: extend the plugin's
existing asset-ID input (`assetBox`, `:99`) to accept a **paste of the printed
asset ID directly**, then auto-call `InsertService:LoadAsset` and drop the
result straight into `AssetLibrary.<archetype>.<variant>` with one button,
instead of requiring the Toolbox search step. This removes the Toolbox-search
friction (the actual manual-labor bottleneck) while staying inside what a
Studio plugin can do. Effort: low (the plugin already has `validateAsset`
model-loading and `AssetLibrary` write logic — `:198-243`, `:348-365` — this
is composing existing functions with a new button, not new capability).

### B.3 Gap 2 — Which systems still bypass `AssetLibrary` prefab-first

Grep for `InsertService:LoadAsset` across `src/` (excluding
`ResourceVisualService.lua` itself, which is prefab-first) found 4 remaining
call sites:

| Site | Prefab-first already? | Notes |
| --- | --- | --- |
| `CompanionManager.server.lua:105` | **Yes** | Checks level-baked mesh, then `ServerStorage.CompanionVisualCatalog.Prefabs` (`:87-98`), `InsertService` is the last-resort fallback (`:100-110`), with a "never a cube" hard-fail-loud policy below it (`:112-115`). Already migrated. |
| `GuestManager.server.lua:165` | **Partially** | Pre-built `animalTemplates` (level meshes, no InsertService, comment confirms "no permission wall," `:146-149`) are checked first; `InsertService` only fires for guest types without a pre-built template (`:157-165`). Not `AssetLibrary`-based, but avoids the permission wall via a different mechanism. Lower priority to migrate. |
| `Services/ZundaroomsService.lua:69` | **Yes** | Checks `ServerStorage.ZundaroomsEntity` or `ReplicatedStorage.Models.ZundaroomsEntity` first (`:57-60`), `InsertService` only as fallback when `Config.entityModelAssetId` is set and no authored model exists (`:61-69`). Comment at `:182,186` explicitly references the `AssetLibrary.Companions`/`AssetLibrary.ResourceNodes` convention. Already migrated in spirit. |
| `ProceduralLandscapePreview.server.lua:37` | **No — gap** | This dev/preview script has **no** authored-prefab check at all; it calls `InsertService:LoadAsset` directly on `placement.assetId` with no fallback to `AssetLibrary` and no procedural-fallback safety net (`:24-49`). It is a `.server.lua` dev-preview tool, likely not part of the live game loop, but if ever re-enabled it would hit the exact permission wall the rest of the codebase has already solved. |
| `ProceduralLandscapeSpawner.server.lua` (Part A) | **No — the real gap** | This is the highest-traffic system without any `AssetLibrary` awareness at all — it goes straight from `ArchitectureVariants` to `ProceduralPropBuilder`'s Part-primitives, never checking an `AssetLibrary.Landscape` (or similar) folder the way `ResourceVisualService`/`CompanionManager`/`ZundaroomsService` all do. |

**Recommendation:** give `ProceduralLandscapeSpawner.server.lua`'s `spawnMesh`
(`:42-87`) the same 3-tier resolution order as `ResourceVisualService.apply`:
check `ServerStorage.AssetLibrary.Landscape.<category>.<asset>` first, then the
existing `ArchitectureVariants` meshId path, then `ProceduralPropBuilder` as
final fallback. This is the single most impactful "consistency" fix and is
also the direct on-ramp for Part A's recommendation #2 (feeding real meshes
into the landscape system). Effort: low — the pattern to copy is already
proven three times over in this codebase.

### B.4 Gap 3 — Versioning/backup: `AssetLibrary.Prefabs` has no snapshot at all

Confirmed asymmetry: `ResourceVisualAuthoringPlugin.server.lua` has a full
export/import cycle for `ServerStorage.ResourceVisualCatalog.Entries`
(Configuration objects holding only attribute *metadata* — asset ID, scale,
offset — `:601-649`), which is JSON-serializable because those entries are
lightweight data, not full models. **`ServerStorage.AssetLibrary` has no
equivalent** — it holds full `Model` prefabs (actual mesh geometry), which
cannot be meaningfully JSON-snapshotted the way the catalog's attribute-only
entries can. Per user memory (`rbxl-baked-instances.md`), it is confirmed
non-Rojo and place-baked only, meaning **the `.rbxl` file itself is the only
backup**, and only as of the last `File → Publish`.
**Recommendation (minimal safety net, low effort):** a "Sanity check
AssetLibrary" plugin button that walks `ServerStorage.AssetLibrary` and prints
a per-folder instance count + a list of any Model with zero `BasePart`
descendants (the exact failure mode that produced the original invisible/cube
bugs this session fixed) — cheap to add to the existing
`ResourceVisualAuthoringPlugin.server.lua` widget (it already has a
`diagnosticsButton` pattern to copy, `:583-599`) and gives a fast yes/no on
"did the last publish actually save my prefabs" without needing a real
snapshot format. A true content snapshot (exporting mesh IDs/CFrames of every
prefab, so at least a partial rebuild is possible if the whole folder is ever
emptied) is a larger lift and lower priority — recommend only if repeated data
loss actually occurs.

### B.5 Gap 4 — Collaboration: docs recommend discipline, no tooling gap-check exists

No code implements a "diff last publish vs. current `AssetLibrary` contents"
check — this is purely a process recommendation in existing docs today, not a
tooling gap that's been attempted and left unfinished. Given this is
apparently a solo-dev project (single `CreatorId`, `tools/asset-pipeline/README.md:5`),
Team Create/publish-discipline is very likely sufficient for now — building a
diff tool is speculative work for a collaboration scenario that doesn't yet
exist. **Recommendation: defer.** Revisit only if/when a second author is
actually added to the project.

### B.6 Gap 5 — Documentation is scattered across 5 docs with real drift risk

Confirmed scattered, not duplicated-but-consistent: `docs/PHASE3_HANDOFF.md`
(98 lines), `docs/RESOURCE_NODE_AUTHORING.md` (60 lines),
`docs/ASSET_MANAGEMENT.md` (358 lines), `docs/ASSET_REPLACEMENT_CHECKLIST.md`
(92 lines), plus `tools/asset-pipeline/README.md` (60 lines) and
`src/Plugins/README.md` all touch overlapping ground (the `AssetLibrary.<System>.<name>`
convention is referenced independently in at least 3 of these). No single doc
walks upload→place→tag→verify end-to-end for the *current* (post-Open-Cloud)
pipeline — `ASSET_MANAGEMENT.md` at 358 lines is old enough to predate the
asset-pipeline tool entirely (worth confirming it doesn't contradict the newer
Open Cloud flow). **Recommendation: consolidate into one
`docs/ASSET_PIPELINE.md`** covering the full current flow (Open Cloud upload
OR Toolbox → `AssetLibrary` placement → `ResourceVisualCatalog`/tag reference
→ live verification), with the other four either folded in or reduced to
historical/handoff notes explicitly marked superseded. This is a documentation
task, not a code task — flagging for the user to do or delegate, not doing it
here per the read-only scope of this pass.

---

## Summary of top recommendations

**Part A (world scale), ranked:**
1. Multiply placement density in `LandscapeConfig.lua`'s existing data tables — no new code.
2. Feed real Greybox_Kit/Kenney meshes into `ArchitectureVariants` via the now-working asset pipeline, so the spawner's existing meshId-preferred path actually fires.
3. Reconcile or retire `src/Plugins/*` — it has the better scatter/LOD algorithm but targets a dead zone taxonomy and produces disconnected output.

**Part B (authoring ecosystem), ranked:**
1. Give `ProceduralLandscapeSpawner.server.lua` the same `AssetLibrary`-first resolution order already proven in `ResourceVisualService`/`CompanionManager`/`ZundaroomsService`.
2. Add a one-click "paste uploaded asset ID → place in AssetLibrary" button to the authoring plugin, removing the manual Toolbox-search step (full auto-place isn't possible from a Studio plugin sandbox).
3. Add a lightweight `AssetLibrary` sanity-check/diagnostics button (instance counts, empty-mesh detection) as the safety net for its non-Rojo, publish-only backup story.
