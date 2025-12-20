# Quick launcher for TinyMMO (master + gateway + world + two clients) on Windows PowerShell.
# Set $env:GODOT_BIN to override the Godot executable; defaults to 'godot'.

$bin = "D:\AI\Cliffwald\Godot_v4.5.1-stable_win64_console.exe"
if (-not (Test-Path $bin)) {
    Write-Error "Godot executable '$bin' not found."
    exit 1
}
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path

function Launch {
    param(
        [string]$name,
        [string[]]$arguments
    )
    Start-Process -FilePath $bin -WorkingDirectory $proj -ArgumentList $arguments -WindowStyle Normal
    Write-Host "Starting $name..."
}

# Servers
Launch "master-server" @("--path",".","--headless","--feature","master-server","--config=res://data/config/master_config.cfg")
Launch "gateway-server" @("--path",".","--headless","--feature","gateway-server","--config=res://data/config/gateway_config.cfg")
Launch "world-server" @("--path",".","--headless","--feature","world-server","--config=res://data/config/world_config.cfg")

# Clients with diagnostics
$env:CLIFFWALD_NET_DEBUG = "1"
Launch "client-1" @("--path",".","--feature","client")
Launch "client-2" @("--path",".","--feature","client")
