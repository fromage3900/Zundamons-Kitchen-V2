# Builds the Rojo-authored Studio plugins from src/Plugins and installs them
# into Studio's plugin folder. Studio must be restarted to pick up changes.
#
# Usage:  powershell -ExecutionPolicy Bypass -File scripts/install_plugins.ps1
# Gates:  the pre-commit hook already gates the plugin sources on commit.

$ErrorActionPreference = "Stop"
$plugins = "$env:LOCALAPPDATA\Roblox\Plugins"
$out = Join-Path $PSScriptRoot "..\build\plugins"

New-Item -ItemType Directory -Force -Path $out | Out-Null
New-Item -ItemType Directory -Force -Path $plugins | Out-Null

function Install-Plugin {
	param([string]$Name, [string]$Project, [string]$SourceLua)
	$rbxmx = Join-Path $out "$Name.rbxmx"
	Write-Host "Building $Name..."
	rojo build $Project --output $rbxmx
	if ($LASTEXITCODE -ne 0) { throw "Rojo build failed for $Name" }
	Copy-Item $rbxmx (Join-Path $plugins "$Name.rbxmx") -Force
	Write-Host "Installed $Name.rbxmx ($([math]::Round((Get-Item $rbxmx).Length/1KB)) KB) -> $plugins"
}

Install-Plugin -Name "ZundaMaterialAuthoring" -Project "src/Plugins/material-plugin.project.json" -SourceLua "src/Plugins/ZundaMaterialAuthoring.plugin.lua"
Install-Plugin -Name "ZundaWorldDecorator" -Project "src/Plugins/plugin.project.json" -SourceLua "src/Plugins/ZundaWorldDecorator.plugin.lua"

Write-Host "`nDone. Restart Studio, then check: Plugins tab -> Zunda Material Authoring / Zunda World Decorator."