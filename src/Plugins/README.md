# Zunda World Decorator

A Studio-only authoring plugin for procedurally decorating game zones with an
Infinity Nikki aesthetic. Think of it as **dressing up your world like an outfit** —
each zone has a style identity, and decorations are chosen to match.

## Install

1. From the repository root run:
   `.\node_modules\.bin\rojo.cmd build src/Plugins/plugin.project.json -o build/ZundaWorldDecorator.rbxm`
2. **Preferred (never touches the place):** open the Studio **Plugins** tab →
   **Plugins Folder**, and drop `build/ZundaWorldDecorator.rbxm` in there
   directly. Restart Studio.
3. Open **Plugins > Zunda Decorator > Toggle Decorator**.
4. Keep Rojo connected. The plugin edits Studio-owned level data only; Rojo
   preserves it through `$ignoreUnknownInstances`.

> ⚠️ **Do not leave the plugin Model in the place.** If you use the older
> "drag into place → right-click → Save as Local Plugin" flow instead of step 2,
> you **must** delete the temporary `ZundaWorldDecorator` Model from
> Workspace immediately afterward.

## Infinity Nikki Aesthetic

- **Pastel palette:** Zunda green (RGB 160, 210, 150), gold (RGB 255, 200, 80),
  pink (RGB 255, 150, 200), mint (RGB 145, 215, 195)
- **Style identities:** Each zone has a fashion identity (Casual Cute, Traditional
  Elegance, Dreamy Whimsy, Vintage Romance, Alpine Sporty, Culinary Cute)
- **Style matching:** Decorations are chosen based on their tags matching the
  zone's style affinity — higher match = better placement quality
- **Sparkle density:** LOD system scales light brightness and transparency based
  on camera distance, maintaining the "sparkle" effect at all ranges

## Zone Style Identities

| Zone | Style Identity | Affinity Tags |
|---|---|---|
| Village | Casual Cute | village, garden, path |
| Pagoda | Traditional Elegance | pagoda, garden, village |
| Mystic Forest | Dreamy Whimsy | forest, mystic, ruins |
| Ancient Ruins | Vintage Romance | ruins, mystic, peaks |
| East Peaks | Alpine Sporty | peaks, mystic, ruins |
| Kitchen | Culinary Cute | village, garden, path |

## Decoration Catalog

10 procedurally-generated decoration types:
- `lantern_post` — Pastel Street Lamp
- `cherry_tree` — Cherry Blossom Tree
- `flower_cluster` — Pastel Flower Cluster
- `glow_mushroom` — Glowing Mushroom
- `floating_crystal` — Floating Crystal
- `meditation_circle` — Stone Meditation Circle
- `pastel_archway` — Pastel Archway
- `wind_chime` — Wind Chime
- `crystal_spire` — Crystal Spire
- `signpost` — Pastel Signpost

## Workflow

1. Select a zone from the dropdown
2. Select a decoration type
3. Adjust density (0.0–1.0)
4. Toggle Apply Materials / Apply Vistas / Dry Run
5. Click **✨ Decorate Zone**
6. Use **↩ Undo Zone** to rollback, or **🗑 Clear All** to remove everything

## Architecture

```
src/Plugins/
├── ZundaWorldDecorator.plugin.lua    # Entry point (Studio plugin)
├── plugin.project.json               # Rojo build config
├── README.md                         # This file
├── DecorationCatalog.lua             # Data-driven decoration blueprints
├── ZoneProfiles.lua                  # Zone metadata + style identities
├── ScatterEngine.lua                 # Surface sampling + placement logic
├── ProceduralGeometry.lua            # Builds decorations as Roblox parts
├── MainWidget.lua                    # Dockable UI (pastel aesthetic)
├── UndoManager.lua                   # ChangeHistory-based undo
├── MaterialPalette.lua               # MaterialVariant registration
├── MaterialVariantSystem.lua         # Terrain painting
├── SetDressingRules.lua              # Distant vistas + weather reactions
└── LODManager.lua                    # Distance-based LOD (sparkle scaling)
```
