# Resource Node Authoring

Resource gameplay is mesh-independent. A tree, rock, flower, crop, or future Kenney model receives behavior from its `ResourceArchetype`; scripts never depend on a particular mesh name or hierarchy.

## Collaborator workflow

1. Place or duplicate a `BasePart`, `MeshPart`, or `Model` without replacing the surrounding Studio-authored world.
2. Add the CollectionService tag `ResourceNode`.
3. Add a string attribute `ResourceArchetype` using one supported value below.
4. For a click-gather `Model`, set its `PrimaryPart`; the bootstrap attaches interaction to that part.
5. Keep `UseRegistryMesh` false or absent to preserve the placed visual. Set it true only when the registry should assign the uploaded mesh from `MeshAssets.lua`.
6. Optionally set `VisualVariant` to a key from `MeshAssets.lua`. Changing this key swaps visuals without changing loot, tools, health, or respawn behavior.

Tool archetypes:

- `Rock`, `MarbleRock`, `GoldRock` — PickAxe
- `AppleTree`, `PineTree` — Axe
- `Wheat`, `ZundaMushroom`, `ZundaBerry`, `ZundaRoot` — Sickle

Click archetypes:

- `ZundaFlower`, `ZundaPea`, `EdamamePod`, `ZundaLeaf`, `SweetPea`
- `PeaFlower`, `SaltedPeaBouquet`, `MysteryLoot`

## Kenney and custom mesh swapping

Uploaded Kenney assets belong in `MeshAssets.lua` under a stable visual key such as `Tree`, `Rock`, or `ZundaFlower`. Do not put asset IDs into harvest scripts. Add or change a variant in the registry, then set `VisualVariant` on placed nodes. Source FBX/Blender archives remain local or in an approved large-file asset store; Roblox-ready asset IDs and attribution belong in Git.

## Overrides

The bootstrap supplies safe defaults but preserves authored overrides for `Health`, `MaxHealth`, `Respawn`, `Yield`, and `Available`. This allows a special landmark tree or rare flower to use the same gameplay archetype with bespoke tuning.

`default.project.json` keeps `$ignoreUnknownInstances: true` under Workspace, so Rojo synchronization does not remove placed terrain, models, or level geometry.
