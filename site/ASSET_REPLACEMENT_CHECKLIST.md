# Asset Replacement Checklist

This is the collaborator-safe path for replacing visuals and sounds. Upload all
production assets under the same account/group that owns the Roblox experience.

## Harvest nodes: rocks, trees, wheat, flowers, gold, crops

1. Build and install `build/ZundaResourceVisualAuthoring.rbxm` as a local plugin.
2. In Studio, select the invisible interaction root Part for one resource.
3. Open **Plugins > Zunda Kitchen > Resource Visuals**.
4. Choose the existing `ResourceArchetype` and a stable `VisualVariant`.
5. Paste the uploaded Mesh or Model asset ID and select its type.
6. Enter scale, vertical offset, and Y rotation.
7. Click **Validate**, then **Preview**, then **Apply to selection**.
8. Test harvesting and respawn before using **Replace all nodes using this variant**.
9. Duplicate the finished root for more placements; do not duplicate only the visual child.

The plugin owns only `_ResourceVisual`. Do not place gameplay scripts, click
detectors, loot settings, or durability inside that folder.

## Companion prefabs: dog, parrot, bird, and Zundapal variants

1. Import the FBX or insert the owner/group Model into Studio.
2. Remove imported scripts and set a useful PrimaryPart.
3. In `ServerStorage`, create this hierarchy once:

```text
CompanionVisualCatalog
|-- Prefabs
`-- Entries
```

4. Put complete Models under `Prefabs`, named exactly by companion key:
   `zundapal`, `dog`, `parrot`, `cat`, `zundamon`, `zundacat`, `zundabunny`,
   `tantanmon`, `ankomon`, `cardamon`, `antimon`, or `sakuradamon`.
5. For the shared `zundapalupdate4` rig, either duplicate the Model once per key
   and author each `SurfaceAppearance` in Studio, or keep one `zundapal` prefab
   and add a Configuration under `Entries/<companion key>`.
6. Optional entry attributes are `BasePrefab`, `ModelAssetId`, `ColorMap`,
   `NormalMap`, `RoughnessMap`, and `MetalnessMap`.
7. Test each key through the companion shop and Set Companion action. Verify the
   model follows, remains non-collidable, opens its own VN dialogue, and applies
   the configured buff.

Studio prefabs win over uploaded fallback IDs. Rojo preserves the Studio-owned
catalog, and unavailable assets fall back to the procedural companion body.

## Zundaroom pursuer

1. Import `zundabackroomsentity.fbx` through Studio's 3D Importer.
2. Group the imported parts into a Model named `ZundaroomsEntity`.
3. Set its PrimaryPart and author materials/SurfaceAppearance in Studio.
4. Move the Model directly under `ServerStorage`.
5. Enter a private Zundaroom session and verify facing, scale, chase clearance,
   catch distance, and cleanup after escape/death/timeout.

The server uses the authored Model automatically. If it is absent or invalid,
the black procedural pursuer remains available.

## Sound effects

1. Upload replacement audio under the experience owner/group and wait for moderation.
2. In `SoundService`, locate the letter-named Sound used by `SoundConfig.SoundMap`.
3. Replace only its `SoundId`; keep the object name so existing UI actions continue working.
4. Tune base volume on the Sound and action volume in `SoundConfig` only when necessary.
5. Test panel open/close, hover, click, Pea Wheel, success/error, cooking,
   level-up, quest completion, and coin feedback independently.
6. Keep attribution for third-party audio in `CREDITS.md`.

Local WAV files in Git do not automatically become Roblox audio assets.

## Companion monetization release gate

Premium purchases remain intentionally disabled until real Dev Product IDs exist.
Before enabling them:

1. Create products under the production experience owner/group.
2. Replace every zero/placeholder ID in `MarketplaceConfig`.
3. Ensure each product exists in both `products` and `companionDevProductIds`.
4. Confirm premium companions have `free = false` in `CompanionConfig`.
5. Test receipts in a private published universe, including reconnect after purchase.
6. Set `MarketplaceConfig.enabled = true` only after every receipt test passes.

Never test public monetization with placeholder product IDs.

## UI mechanics coverage

- Inventory, quests, companion shop, VN, wardrobe/style points, crafting,
  serving, fishing, settings, and the Pea Wheel have client surfaces.
- Challenge Mode and daily challenge status currently have server remotes but do
  not yet have a complete player-facing start/status/claim interface. Treat that
  as a separate UI completion task rather than hiding it inside asset replacement.
