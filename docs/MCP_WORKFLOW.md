# MCP Workflow: Live Asset Management & Collaboration

## Overview

This document explains how to connect to the Roblox Studio MCP server, extract asset IDs from your place, and manage live collaboration workflows using the Model Context Protocol tools.

---

## 1. Prerequisites

### Install Studio MCP Plugin

```bash
# The plugin is configured in opencode.json
# Command: npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

This will:
1. Download the Roblox Studio MCP plugin
2. Install it into your Roblox Studio plugins folder
3. Configure the MCP server connection

### Verify Installation

1. Open Roblox Studio
2. Go to **Plugins** → **Roblox Studio MCP**
3. If not visible, restart Studio

### Alternative: Built-in Roblox MCP

If the plugin fails, use Roblox's built-in MCP:
```bash
%LOCALAPPDATA%\Roblox\mcp.bat
```

---

## 2. Starting the MCP Server

### Via OpenCode (Recommended)

Your `opencode.json` is already configured:

```json
{
  "mcp": {
    "roblox-studio": {
      "type": "local",
      "command": ["cmd", "/c", "npx", "-y", "@chrrxs/robloxstudio-mcp@latest", "--auto-install-plugin"],
      "environment": {}
    }
  }
}
```

Start the server:
```bash
npx opencode
```

### Manual Start

```bash
npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

---

## 3. MCP Tool Reference

The Roblox Studio MCP provides 78 tools. The most useful for asset management:

### Asset Discovery

| Tool | Purpose | Example |
|------|---------|---------|
| `roblox-studio_get_connected_instances` | Verify Studio is connected | Check before other commands |
| `roblox-studio_list_assets` | List all assets in open place | Get all asset IDs at once |
| `roblox-studio_get_instance` | Get details of a specific instance | Inspect a model or mesh |
| `roblox-studio_get_asset_info` | Get metadata for an asset ID | Verify asset properties |

### Asset Modification

| Tool | Purpose | Example |
|------|---------|---------|
| `roblox-studio_insert_asset` | Insert a marketplace asset | Add asset to place |
| `roblox-studio_save_game` | Save the place file | Persist changes |
| `roblox-studio_execute_luau` | Run custom Luau script | Batch extract IDs |

### Workflow Tools

| Tool | Purpose | Example |
|------|---------|---------|
| `roblox-studio_solo_playtest` | Test game solo | Validate assets load |
| `roblox-studio_get_hierarchy` | View instance tree | Map asset structure |
| `roblox-studio_set_instance_property` | Modify instance properties | Batch update IDs |

---

## 4. Extracting Asset IDs from Your Place

### Method A: List All Assets (Simple)

```bash
# Using MCP tool
mcp__roblox-studio_list_assets
```

This returns a JSON list of all assets in the place:
```json
{
  "assets": [
    {
      "id": "1234567890",
      "type": "MeshPart",
      "name": "Zunda Berry",
      "path": "Workspace.Environment.Plants.ZundaBerry"
    }
  ]
}
```

### Method B: Execute Luau Script (Advanced)

Run this script via `roblox-studio_execute_luau`:

```lua
-- Extract all rbxassetid:// from the DataModel
local results = {}
local function scanInstance(instance)
    -- Scan properties for asset IDs
    for _, prop in ipairs(instance:GetProperties()) do
        local value = prop.Value
        if type(value) == "string" and string.match(value, "^rbxassetid://%d+$") then
            table.insert(results, {
                path = instance:GetFullName(),
                property = prop.Name,
                value = value
            })
        end
    end
    
    -- Recurse children
    for _, child in ipairs(instance:GetChildren()) do
        scanInstance(child)
    end
end

scanInstance(game)

-- Output results
game:GetService("HttpService"):JSONEncode(results)
```

### Method C: Parse .rbxlx File (Offline)

If you have a saved `.rbxlx` file:

```python
import re
import xml.etree.ElementTree as ET

def extract_assets(rbxlx_path):
    """Extract all asset IDs from a .rbxlx (XML) file."""
    tree = ET.parse(rbxlx_path)
    root = tree.getroot()
    
    # Convert to string and find all rbxassetid:// patterns
    with open(rbxlx_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all asset IDs
    pattern = r'rbxassetid://(\d+)'
    matches = re.findall(pattern, content)
    
    # Deduplicate and categorize
    unique_assets = list(set(matches))
    print(f"Found {len(unique_assets)} unique asset IDs")
    
    return unique_assets

# Usage
assets = extract_assets("place.rbxlx")
for asset_id in assets:
    print(f"rbxassetid://{asset_id}")
```

---

## 5. Populating AssetRegistry

### Step 1: Extract Current Assets

```bash
# Get list from Studio
mcp__roblox-studio_list_assets > assets.json

# Parse and format for AssetRegistry.lua
python scripts/populate_registry.py assets.json
```

### Step 2: Update AssetRegistry.lua

Use the extracted data to fill in the real IDs:

```lua
Meshes = {
    Produce = {
        ZundaBerry = "rbxassetid://1234567890", -- Extracted from Workspace
        Apple = "rbxassetid://0987654321",
    }
}
```

### Step 3: Validate

```lua
-- Run in Studio command bar or via MCP
local AssetRegistry = require(game.ServerStorage.AssetRegistry)
local invalid = AssetRegistry.Validate()

if #invalid > 0 then
    warn("Invalid asset IDs found:")
    for _, id in ipairs(invalid) do
        warn(id)
    end
else
    print("All asset IDs valid!")
end
```

---

## 6. Live Collaboration Setup

### Enable Team Create

1. In Roblox Studio: **File** → **Publish to Roblox**
2. Enable **Team Create** in Game Settings
3. Invite collaborators:

```bash
# MCP command to add collaborator
mcp__roblox-studio_set_team_create_member --username "collaborator_name" --role Editor
```

### Configure Permissions

```json
{
  "TeamCreateRoles": {
    "Owner": ["edit", "delete", "manage_members", "publish"],
    "Editor": ["edit", "delete"],
    "Builder": ["edit_geometry", "edit_lighting"]
  }
}
```

### Sync Strategy

```
┌─────────────────────────────────────────┐
│  GitHub (Source of Truth for Code)      │
│  ├── src/shared/AssetRegistry.lua       │
│  ├── src/server/                        │
│  └── src/client/                        │
└──────────────┬──────────────────────────┘
               │ git push/pull
               ▼
┌─────────────────────────────────────────┐
│  Local Machine (Developer Workstation)  │
│  ├── VS Code                            │
│  ├── Rojo Server (Port 34872)           │
│  └── Wally Packages                     │
└──────────────┬──────────────────────────┘
               │ rojo serve
               ▼
┌─────────────────────────────────────────┐
│  Roblox Studio (Team Create Cloud)      │
│  ├── ReplicatedStorage (synced)         │
│  ├── ServerScriptService (synced)       │
│  ├── StarterPlayerScripts (synced)      │
│  └── Workspace (geometry/lighting)      │
│                                        │
│  NOTE: $ignoreUnknownInstances = true  │
│  Preserves Studio-only geometry         │
└─────────────────────────────────────────┘
```

---

## 7. Asset Sharing Patterns

### Pattern 1: Centralized Registry

```
src/shared/AssetRegistry.lua  ← Single source of truth
            ↓
    All systems import from here
            ↓
    Unique asset IDs maintained centrally
```

**Pros**: Easy to audit, simple to update
**Cons**: Requires manual sync when new assets added

### Pattern 2: Namespaced Collections

```
ReplicatedStorage
├── Assets
│   ├── Meshes
│   │   ├── ZundaBerry (MeshPart)
│   │   └── Apple (MeshPart)
│   ├── Textures
│   │   └── Icons
│   └── Audio
```

**Pros**: Visual in Studio, drag-and-drop friendly
**Cons**: Bloats place file, harder to version control

### Pattern 3: Hybrid (Recommended)

- **Code references**: Use `AssetRegistry.lua`
- **Studio prefabs**: Store in `src/shared/Models/` (synced via Rojo)
- **Runtime loading**: Dynamic instantiation via `InsertService` or `ContentProvider`

---

## 8. Ensuring Asset Availability

### For Collaborators (Build Time)

1. **Git clone** → Get all code including AssetRegistry
2. **wally install** → Get all dependencies
3. **rojo serve** → Sync to Studio
4. **Studio opens** → Assets from AssetRegistry automatically available

### For Players (Runtime)

1. Assets uploaded to Roblox are globally cached by CDN
2. No special handling needed - `rbxassetid://123456` works for all players
3. Use `ContentProvider:PreloadAsync()` for critical assets

### For Offline Development

1. Keep placeholder IDs in AssetRegistry
2. Test with low-poly substitutes if asset unavailable
3. Use `--!ignore` comments for missing assets during development

---

## 9. Advanced Workflows

### Batch Asset Import

```lua
-- Run via MCP to batch-import from Collection
local CollectionService = game:GetService("CollectionService")
local ASSET_COLLECTION_ID = "1234567890" -- Your collection ID

local function importCollectionAssets()
    -- Use AssetService API (requires HTTP requests)
    local HttpService = game:GetService("HttpService")
    local url = "https://api.roblox.com/Collections/%s/Items"
    
    -- Fetch collection items
    local response = HttpService:GetAsync(url:format(ASSET_COLLECTION_ID))
    local items = HttpService:JSONDecode(response)
    
    -- Process each item
    for _, item in items do
        print(item.Name, item.AssetId)
        -- Add to AssetRegistry
    end
end
```

### Asset Validation Pipeline

```lua
-- CI/CD validation script
local AssetRegistry = require(game.ServerStorage.AssetRegistry)

local function validateAllAssets()
    local results = {
        valid = 0,
        invalid = {},
        missing = AssetRegistry.GetMissingIDs()
    }
    
    -- Check each asset exists on Roblox
    for category, _ in AssetRegistry do
        if category ~= "Name" and category ~= "Version" and category ~= "LastUpdated" then
            -- Validate each subcategory
        end
    end
    
    -- Output report
    return results
end
```

### Synchronization with External Tools

```bash
# Sync with Roblox Creator Dashboard assets
python scripts/sync_assets.py \
  --collection "ZundamonsKitchenAssets" \
  --output src/shared/AssetRegistry.lua \
  --format lua

# Validate against live place
python scripts/validate_assets.py \
  --registry src/shared/AssetRegistry.lua \
  --place "place.rbxlx"
```

---

## 10. Troubleshooting MCP Issues

### Plugin Not Detected

```bash
# Reset MCP installation
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\.roblox-mcp"
npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```

### Connection Timeout

Verify no other MCP servers are running on conflicting ports:
```powershell
# Check for stale MCP processes
Get-Process | Where-Object {$_.Name -like "*mcp*"} | Stop-Process -Force
```

### Assets Not Syncing

1. Verify `$ignoreUnknownInstances = true` in `default.project.json`
2. Check Rojo server is running: `rojo serve`
3. Ensure no .rbxlx.lock file blocking saves
4. Clear Studio cache: **File** → **Studio Settings** → **Clear Cache**

---

## 11. Next Steps

1. **Install MCP plugin** in Roblox Studio
2. **Connect** via `npx opencode`
3. **Extract** current asset IDs using `roblox-studio_list_assets`
4. **Populate** `AssetRegistry.lua` with real IDs
5. **Test** in Studio to ensure assets load
6. **Document** all new assets in `docs/ASSET_MANAGEMENT.md`

---

## Resources

- [MCP Tools Documentation](https://github.com/chrrxs/robloxstudio-mcp)
- [Roblox Creator API](https://developer.roblox.com/en-us/api-reference)
- [Team Create Guide](https://developer.roblox.com/en-us/articles/Team-Create)
- [Rojo Documentation](https://rojo.space/docs)