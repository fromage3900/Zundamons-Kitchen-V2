# Asset pipeline — Roblox Open Cloud uploader

Fixes the root cause of "you don't have the authority to use this asset ID":
`InsertService`/`ContentProvider` reject anything not owned by the
experience's creator (confirmed `game.CreatorId = 3930496852`, `CreatorType =
User` — your personal account). Manual Toolbox imports don't reliably fix
this either. Uploading through Open Cloud with the creator context set
correctly does, permanently, for every asset uploaded this way.

## One-time setup

1. Go to https://create.roblox.com/credentials → API Keys → Create API Key.
2. Grant it the **Assets API** permission (Read + Write), scoped to your
   user account (the one that owns this experience).
3. Set the key as an environment variable — **never paste the raw key into
   chat or commit it to git**:
   ```bash
   export ROBLOX_API_KEY="your-key-here"   # Git Bash, current session only
   ```
   or, to persist across terminals on Windows:
   ```powershell
   setx ROBLOX_API_KEY "your-key-here"     # then open a NEW terminal
   ```

## Upload a single file

```bash
node tools/asset-pipeline/upload-asset.js <filePath> <assetType> <displayName>
```

`assetType` is one of `Model` (fbx/obj/glb), `Decal` (png/jpg), `Audio`
(mp3/ogg), `Animation`. Prints `rbxassetid://<id>` on success.

## Batch upload

`manifest.json` lists the candidate files found on a G:/F: drive scan
(2026-07-24) — Greybox_Kit modular architecture blocks for `Zundarooms`'s
`RoomSegment` prefab, and a sakura petal mesh to replace the broken
particle texture in `AmbientParticles.lua`. Edit the manifest to add/remove
entries, then:

```bash
node tools/asset-pipeline/upload-batch.js
```

Results (including any failures) are written to `upload-results.json`
(gitignored — it will contain your asset ids, not secrets, but keep it local
until you decide what to commit).

## After uploading

An uploaded `Model` asset lands in your Roblox inventory but is NOT
automatically placed in the game. In Studio: Toolbox → search your account's
"My Creations" → drag the model into the place, then move it into the
matching `ServerStorage.AssetLibrary.<System>.<name>` folder (see
`docs/PHASE3_HANDOFF.md` for the convention — e.g.
`AssetLibrary.Zundarooms.RoomSegment`, `AssetLibrary.Companions.<type>`,
`AssetLibrary.ResourceNodes.<variant>`). Once it's there, the game code
already prefers it over any `InsertService`/asset-ID fallback path — no
further code changes needed.
