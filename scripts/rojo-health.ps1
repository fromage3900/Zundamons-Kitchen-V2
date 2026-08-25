# rojo-health.ps1 - inspect the Rojo serve + git sync state
# Usage: powershell -ExecutionPolicy Bypass -File scripts/rojo-health.ps1
$ErrorActionPreference = 'SilentlyContinue'
Write-Host '== Rojo process health ==' -ForegroundColor Cyan
$procs = Get-CimInstance Win32_Process -Filter "Name='rojo.exe'"
if (-not $procs) { Write-Host '  NO rojo process running.' -ForegroundColor Yellow }
$serveCount = 0
foreach ($p in $procs) {
    $l = $p.CommandLine
    $serving = $l -match 'serve default.project.json'
    $srcmap = $l -match 'sourcemap'
    if ($serving) { $serveCount += 1 }
    $kind = if ($serving) { 'SERVE' } elseif ($srcmap) { 'sourcemap-watch' } else { 'other' }
    Write-Host ("  PID {0,-6} [{1,-16}] {2}" -f $p.ProcessId, $kind, $l)
}
if ($serveCount -lt 1) { Write-Host '  NOTE: no `rojo serve` running.' -ForegroundColor Yellow }
if ($serveCount -gt 1) { Write-Host ('WARNING: {0} serves - duplicates corrupt.' -f $serveCount) -ForegroundColor Red }
Write-Host '== Listening ports (30000-40000) ==' -ForegroundColor Cyan
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -ge 30000 -and $_.LocalPort -le 40000 } | ForEach-Object { Write-Host ('  :{0} -> PID {1}' -f $_.LocalPort, $_.OwningProcess) }
Write-Host '== Git sync ==' -ForegroundColor Cyan
git fetch origin --quiet
$statusLine = git status -sb | Select-Object -First 1
Write-Host ('  ' + $statusLine)
if ($statusLine -match 'ahead|behind') { Write-Host 'WARNING: not in sync with origin/main.' -ForegroundColor Red }
Write-Host '== done ==' -ForegroundColor Green
