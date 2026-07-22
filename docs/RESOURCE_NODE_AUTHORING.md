# Resource Node Authoring

Harvest behavior and visuals are independent. Loot, durability, tools, yield,
and respawn come from `ResourceArchetype`; replaceable geometry lives only under
the interaction root's `_ResourceVisual` folder.

## Recommended Studio workflow

Install the local plugin in `tools/resource-visual-authoring`, then:

1. Upload a Mesh or Model under the same owner/group as the experience.
2. Select a resource root Part, or a Model with a PrimaryPart.
3. Open **Plugins > Zunda Kitchen > Resource Visuals**.
4. Enter the archetype, stable variant, asset ID, type, and transform.
5. Click **Validate**, **Preview**, then **Apply to selection**.
6. Duplicate the configured node normally for additional placements.

The plugin does not publish or upload assets. Invalid/private assets leave the
existing visual untouched. One previous `_ResourceVisual` is retained for the
plugin's Restore action, and Studio Undo remains available.

## Canonical attributes

- `ResourceArchetype`: gameplay identity (`Rock`, `GoldRock`, `AppleTree`, `Wheat`, etc.)
- `VisualVariant`: reusable catalog name such as `Rock_Common`
- `VisualAssetId`: optional per-instance Roblox ID override
- `VisualAssetType`: `Mesh`, `Model`, `Prefab`, or `Fallback`
- `VisualScale`: visual-only `Vector3`
- `VisualOffset`: visual-only `CFrame`
- `UseFallbackOnFailure`: keep true for production nodes
- `RegistryMeshStatus` / `RegistryMeshDetail`: runtime diagnostics; do not author manually

Resolution order is per-instance ID, Studio catalog entry, Git-backed default,
then procedural fallback. The fallback remains visible until a replacement is
confirmed deliverable, so a failed ID can never make the node blank.

## Supported gameplay archetypes

- PickAxe: `Rock`, `MarbleRock`, `GoldRock`
- Axe: `AppleTree`, `PineTree`
- Sickle: `Wheat`, `ZundaMushroom`, `ZundaBerry`, `ZundaRoot`
- Click: `ZundaFlower`, `ZundaPea`, `EdamamePod`, `ZundaLeaf`, `SweetPea`,
  `PeaFlower`, `SaltedPeaBouquet`, `MysteryLoot`

Authored geometry outside `_ResourceVisual` is never removed. Workspace and the
Studio catalog are protected by Rojo's `$ignoreUnknownInstances` settings.

## One-time legacy migration

From the Studio command bar, review the dry run first:

```lua
require(game.ServerScriptService.DevTools.MigrateResourceVisuals).run(false)
```

Apply only after the listed eight nodes are correct:

```lua
require(game.ServerScriptService.DevTools.MigrateResourceVisuals).run(true)
```
