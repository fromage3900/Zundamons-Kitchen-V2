# Resource Visual Authoring Plugin

This local Studio plugin lets level designers replace harvest visuals without
opening gameplay scripts. It validates an experience-owned Roblox asset before
changing a node, preserves one rollback copy, strips scripts from imported
models, and writes only the canonical resource attributes.

## Install

1. From the repository root run:
   `.\\node_modules\\.bin\\rojo.cmd build tools/resource-visual-authoring/plugin.project.json -o build/ZundaResourceVisualAuthoring.rbxm`
2. In Studio, drag `build/ZundaResourceVisualAuthoring.rbxm` into the place,
   right-click its root Model in Explorer, and choose
   **Save as Local Plugin**.
3. Restart Studio and open **Plugins > Zunda Kitchen > Resource Visuals**.
4. Delete the temporary inserted Model from the place after saving the plugin.
5. Keep Rojo connected. The plugin edits Studio-owned level data only; Rojo
   preserves it through `$ignoreUnknownInstances`.

## Everyday workflow

1. Upload the Mesh or Model under the same group/account that owns the game.
2. Select a resource root Part or a Model with a PrimaryPart.
3. Enter the archetype, stable variant name, asset ID, type, and transform.
4. Validate, preview, then apply.
5. Duplicate the configured node normally. Its behavior and visual attributes
   are copied together.

Invalid or inaccessible assets never replace the existing visual. Use **Restore
previous visual** or Studio Undo if the scale or pivot needs another pass.
