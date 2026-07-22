# Asset Management & Collaboration Guide

## Overview

This document defines how assets are organized, distributed, and made accessible to all collaborators working on Zundamon's Kitchen V2.

---

## 1. Asset Registry Architecture

### Single Source of Truth

All asset IDs are stored in `src/shared/AssetRegistry.lua`. This file is:
- Synced via Rojo to `ReplicatedStorage.AssetRegistry`
- Available to both client and server code
- The ONLY place where `rbxassetid://` strings should be defined

### Asset Categories

```
AssetRegistry
├── Meshes           - 3D models (produce, cookware, environment)
├── Textures         - UI icons, decals, material textures
├── Audio           - SFX and music
├── Particles       - VFX systems
└── Animations      - Animation IDs for characters/objects
```

### Usage Pattern

```lua
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)

-- Retrieve asset ID
local berryMeshId = AssetRegistry.Meshes.Produce.ZundaBerry

-- Use in code
local mesh = Instance.new("MeshPart")
mesh.MeshId = berryMeshId
```

---

## 2. Creating Assets in Roblox Creator Marketplace

### Step 1: Upload Assets

1. Open Roblox Creator Dashboard: https://create.roblox.com/
2. Go to **Assets** → **My Models** or **My Decals**
3. Upload your assets:
   - FBX files → Auto-convert to MeshParts
   - PNG/JPG → Decals/Textures
   - MP3/WAV → Audio
4. Note the generated asset IDs (e.g., `1234567890`)

### Step 2: Organize into Collections

Create a **Collection** named "Zundamon's Kitchen Assets":

1. In Creator Dashboard, go to **Collections**
2. Create new collection: `ZundamonsKitchenAssets`
3. Add assets with tags for categorization:
   - `Mesh-Produce`
   - `Mesh-Cookware`
   - `Texture-UI`
   - `Audio-SFX`
   - `Particle-VFX`

### Step 3: Make Assets Available to Team

For Team Create collaboration:
1. Open your place in Roblox Studio
2. Go to **File** → **Publish to Roblox** (if not already published)
3. Enable **Team Create** in Game Settings
4. Invite collaborators by username

**Important**: Assets uploaded to your account are only available to users with access to your place. For broader distribution, use:
- **Group assets** (if using a Roblox Group)
- **Public marketplace** (for community assets)
- **Roblox Package** (for private team libraries)

---

## 3. Live Collaboration Workflows

### Roblox Team Create (Real-Time)

**Best for**: Level designers, layout artists, prop placement

**Setup**:
1. In Roblox Studio: **File** → **Team Create** → **Turn on**
2. Set permissions:
   - **Owner**: Full control, can manage members
   - **Editor**: Can edit and save
   - **Builder**: Can edit geometry, not scripts
3. Share invite link with collaborators

**Rules** (from `COLLABORATOR_PROMPTS.md`):
- Level designers work ONLY on layout, terrain, lighting, props
- Never edit `ReplicatedStorage` scripts or remotes
- Tag resource nodes using `ResourceNodeAuthoring` conventions
- Report changes: location, tags, attributes modified

**Sync Strategy**:
- Rojo syncs code from your local repository into Studio
- Team Create syncs geometry/lighting back to cloud
- Use `$ignoreUnknownInstances = true` to preserve Studio-only geometry during Rojo syncs

### Git + Rojo (Code-First)

**Best for**: Scripters, systems developers, gameplay logic

**Workflow**:
```bash
# Pull latest changes
git pull origin main

# Sync code to Studio
rojo serve

# Make changes in VS Code
# ...
# Save and commit
git add .
git commit -m "feat: add cooking validation"
git push
```

**Branching Strategy**:
- `main` - Production-ready code
- `codex/expanded-gameplay-experiments` - Feature prototyping
- `feature/<name>` - Isolated experiments

### Hybrid Model (Recommended)

Combine both approaches:
- **Code logic** → Git + Rojo + VS Code
- **Level geometry** → Team Create in Studio
- **Assets** → Roblox Marketplace + AssetRegistry

---

## 4. Populating AssetRegistry with Real IDs

### Manual Method (Current)

```lua
Meshes = {
    Produce = {
        ZundaBerry = "rbxassetid://1234567890", -- Replace with real ID
    }
}
```

### MCP-Assisted Method (When Studio Plugin Active)

If you have the `@chrrxs/robloxstudio-mcp` plugin connected:

```bash
# List all assets in current place
mcp__roblox-studio_list_assets

# Get specific asset info
mcp__roblox-studio_get_asset --id 1234567890

# Batch extract all asset IDs from scene
# (requires custom script execution via MCP)
```

**Note**: The MCP tool requires:
1. Roblox Studio running with plugin installed
2. Plugin connected to MCP server
3. Place file open in Studio

### Python/Batch Extraction

You can extract asset IDs from a `.rbxlx` (XML) place file:

```python
import re

with open("place.rbxlx", "r") as f:
    content = f.read()

# Find all rbxassetid:// references
assets = re.findall(r'rbxassetid://(\d+)', content)
print(f"Found {len(assets)} asset references")
```

---

## 5. Asset Sharing Infrastructure

### Roblox Packages (Private)

For reusable asset libraries:

1. In Studio, select a model
2. Go to **Model** tab → **Packages** → **Publish to Roblox**
3. Set to **Private** (only team members can use)
4. Note the Package ID

**Usage in code**:
```lua
local PackageService = game:GetService("PackageService")
local asset = PackageService:LoadPackage("package-id-here")
```

### Wally + Git Submodules

For code packages that include asset prefabs:
- Store reference prefabs in `src/shared/Models/`
- Sync via Rojo to `ReplicatedStorage.Models`
- Version control in Git

---

## 6. Ensuring Asset Availability for All Collaborators

### Tier 1: Access Control (Roblox Permissions)

1. **Owner** (you): Full permissions
2. **Developers**: Edit Studio scripts, can run Rojo
3. **Builders**: Edit geometry only via Team Create

**Setup**:
- Enable Team Create in place settings
- Invite by Roblox username
- Set roles in Team Create panel

### Tier 2: Asset Permissions

- Assets uploaded to **your account** → Only you + collaborators in your places
- Assets in a **Group** → Available to all group members
- **Public assets** → Available to everyone

**Recommendation**: Use a Roblox Group for team assets:
1. Create group at https://www.roblox.com/groups
2. Upload assets to group
3. Invite collaborators to group
4. Set group permissions

### Tier 3: Version Control (Git)

```bash
# .gitignore ensures Packages/ and ServerPackages/ are excluded
# But track these in Git:
- src/shared/AssetRegistry.lua    ✓
- docs/ASSET_MANAGEMENT.md        ✓
- default.project.json            ✓
- Luau source files               ✓

# Do NOT track:
- Packages/ (Wally-managed)       ✗
- ServerPackages/                 ✗
- *.rbxlx (binary)                ✗
- crucialassets/*.fbx (bloat)     ✗
```

**Result**: Collaborators clone repo, run `wally install`, see latest asset IDs.

### Tier 4: Runtime Availability

To ensure assets load at runtime for all players:

```lua
-- Server-side preload (critical assets)
local ContentProvider = game:GetService("ContentProvider")

local function preloadAssets()
    local assets = {
        AssetRegistry.Meshes.Produce.ZundaBerry,
        AssetRegistry.Audio.SFX.Harvest,
        -- ... more critical assets
    }
    
    ContentProvider:PreloadAsync(assets)
end

game:GetService("Players").PlayerAdded:Connect(function(player)
    -- Ensure assets are available when player loads
    task.wait(1)
    preloadAssets()
end)
```

**Note**: Roblox Content Delivery Network (CDN) caches assets by ID. Once uploaded, `rbxassetid://123456` is globally available.

---

## 7. Collaboration Checklist

### For New Collaborators

- [ ] Invited to Roblox Group (if using group assets)
- [ ] Added as Team Create member in Studio
- [ ] Given Git repository access (GitHub/GitLab)
- [ ] Provided `opencode.json` setup instructions
- [ ] Instructed to run `wally install` after cloning
- [ ] Added to `COLLABORATOR_PROMPTS.md` with role-specific instructions

### For Asset Authors

- [ ] Uploaded to Creator Dashboard
- [ ] Added to "Zundamon's Kitchen Assets" collection
- [ ] Asset ID added to `AssetRegistry.lua`
- [ ] Asset referenced in game code (not hardcoded)
- [ ] Asset tested in Studio and in solo playtest

### For Live Sessions

- [ ] Rojo server running (`rojo serve`)
- [ ] Studio connected to MCP (if using MCP tools)
- [ ] Team Create enabled
- [ ] Place file saved before sharing
- [ ] Asset IDs validated via `AssetRegistry.Validate()`

---

## 8. Troubleshooting

### "Asset not found" errors

1. Verify asset is uploaded to your account/group
2. Check `AssetRegistry.lua` for correct ID
3. Ensure asset is not deleted from Creator Dashboard
4. Check if asset is set to **Public** or **Friends** (not **Private**)

### Team Create sync conflicts

1. Save place before enabling Team Create
2. Each member should use isolated `default.project.json` path mappings
3. Never edit same `ReplicatedStorage` script simultaneously
4. Use Git branches for non-conflicting script changes

### MCP connection failures

1. Verify plugin installed in Studio: **Plugins** → **Roblox Studio MCP**
2. Check `opencode.json` configuration
3. Restart Studio and MCP server
4. Fallback: Use Studio built-in MCP at `%LOCALAPPDATA%\Roblox\mcp.bat`

---

## 9. Next Steps

1. **Immediate**: Upload current `crucialassets/*.fbx` to Roblox Creator Dashboard
2. **Week 1**: Populate `AssetRegistry.lua` with real IDs
3. **Week 2**: Set up Roblox Group for team asset sharing
4. **Ongoing**: Document all new assets in `AssetRegistry` before use

---

## Resources

- Roblox Creator Dashboard: https://create.roblox.com/
- Team Create Docs: https://developer.roblox.com/en-us/articles/Team-Create
- Rojo Docs: https://rojo.space/
- Roblox Studio MCP: https://github.com/chrrxs/robloxstudio-mcp