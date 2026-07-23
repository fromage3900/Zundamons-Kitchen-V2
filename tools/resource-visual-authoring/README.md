# Resource Visual Authoring Plugin

This local Studio plugin lets level designers replace harvest visuals without
opening gameplay scripts. It validates an experience-owned Roblox asset before
changing a node, preserves one rollback copy, strips scripts from imported
models, and writes only the canonical resource attributes.

## Install

1. From the repository root run:
   `.\\node_modules\\.bin\\rojo.cmd build tools/resource-visual-authoring/plugin.project.json -o build/ZundaResourceVisualAuthoring.rbxm`
2. **Preferred (never touches the place):** open the Studio **Plugins** tab →
   **Plugins Folder**, and drop `build/ZundaResourceVisualAuthoring.rbxm` in there
   directly. Restart Studio.
3. Open **Plugins > Zunda Kitchen > Resource Visuals**.
4. Keep Rojo connected. The plugin edits Studio-owned level data only; Rojo
   preserves it through `$ignoreUnknownInstances`.

> ⚠️ **Do not leave the plugin Model in the place.** If you use the older
> "drag into place → right-click → Save as Local Plugin" flow instead of step 2,
> you **must** delete the temporary `ZundaResourceVisualAuthoring` Model from
> Workspace immediately afterward. If it is saved into the `.rbxl`, its server
> Script runs at play time and throws
> `attempt to index nil with 'CreateToolbar'` on every load (the `plugin` global
> only exists in the Studio plugin context). The script now bails out safely in
> that case, but the stray Model should still be deleted and the place re-saved.

## Everyday workflow

1. Upload the Mesh or Model under the same group/account that owns the game.
2. Select a resource root Part or a Model with a PrimaryPart.
3. Enter the archetype, stable variant name, asset ID, type, and transform.
4. Validate, preview, then apply.
5. Duplicate the configured node normally. Its behavior and visual attributes
   are copied together.

Invalid or inaccessible assets never replace the existing visual. Use **Restore
previous visual** or Studio Undo if the scale or pivot needs another pass.
