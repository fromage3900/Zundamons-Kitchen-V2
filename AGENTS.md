# Roblox Studio & Rojo 7.7.0 Workspace Rules

### 1. Rojo Level Preservation ($ignoreUnknownInstances)
- When configuring `default.project.json`, ALWAYS include `"$ignoreUnknownInstances": true` under `"Workspace"`.
- This prevents Rojo from wiping out terrain, meshes, models, and 3D level geometry placed manually inside Roblox Studio during code synchronizations.

### 2. Client UI Decoupling & Visibility
- Never use `script.Parent` for UI references in client scripts synced to `StarterPlayerScripts`.
- All client UI scripts must dynamically construct or locate their interface in `PlayerGui` via `ClientGuiBootstrap`.
- Explicitly set `gui.ResetOnSpawn = false` on top-level `ScreenGui` instances to survive player respawns.
- Explicitly set `panel.Visible = false` on startup for modal/dialogue panels (e.g. `VNController`) to avoid UI overlaps on game start.

### 3. Wally Package Structure & Dependencies
- Server-only modules (such as `ProfileService`) must be declared under `[server-dependencies]` in `wally.toml`.
- `default.project.json` must map `"Packages": { "$path": "Packages" }` in `ReplicatedStorage` and `"ServerPackages": { "$path": "ServerPackages" }` in `ServerScriptService`.
- `.gitignore` must ignore `Packages/`, `ServerPackages/`, `wally.exe`, and `wally.zip`.

### 4. ServerScriptService Path Consistency
- When `src/server` is mapped directly to `ServerScriptService` in `default.project.json`, imports must use `ServerScriptService.Services.X` or `ServerScriptService.systems.X`. Never prepend an extra `.Server.` path segment.

### 5. MCP (Model Context Protocol) — Roblox Studio Integration
- Use **chrxxs/robloxstudio-mcp** (`@chrrxs/robloxstudio-mcp@latest`) as the Studio MCP server — 78 tools, actively maintained, MIT.
- `opencode.json` config: `{"command": ["cmd", "/c", "npx", "-y", "@chrrxs/robloxstudio-mcp@latest", "--auto-install-plugin"]}`
- Tool names follow the pattern `roblox-studio_<tool_name>` (e.g. `roblox-studio_execute_luau`, `roblox-studio_get_instance`, `roblox-studio_solo_playtest`).
- Ensure no other MCP server (e.g. paralov/roblox-studio-opencode-mcp on port 28821) is running — they conflict. Kill stale processes with `Stop-Process -Id <PID> -Force`.
- Use `get_connected_instances` to verify Studio is linked before calling other tools.
- Fallback: Roblox built-in MCP at `%LOCALAPPDATA%\Roblox\mcp.bat` (no plugin needed, limited tools).
