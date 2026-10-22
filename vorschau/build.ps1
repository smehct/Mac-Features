# Builds Vorschau.exe (the launcher) from vorschau.ahk with the official AutoHotkey compiler (Ahk2Exe).
# The exe starts the hidden server (server.ps1) and the viewer window, so it must stay next to server.ps1 and app\.
# Run:  powershell -ExecutionPolicy Bypass -File vorschau\build.ps1 [-Force]
param([switch]$Force)

$ErrorActionPreference = "Stop"
$src = Join-Path $PSScriptRoot "vorschau.ahk"
$exe = Join-Path $PSScriptRoot "Vorschau.exe"
$icon = Join-Path $PSScriptRoot "app\icon.ico"
$base = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if (-not (Test-Path $base)) { throw "AutoHotkey v2 fehlt (install.ps1 installiert es)." }

if (-not $Force -and (Test-Path $exe) -and (Get-Item $exe).LastWriteTime -ge (Get-Item $src).LastWriteTime) {
    Write-Host "Vorschau.exe ist aktuell."
    return
}

$tools = Join-Path $env:LOCALAPPDATA "Vorschau\tools\Ahk2Exe"
$compiler = Join-Path $tools "Ahk2Exe.exe"
if (-not (Test-Path $compiler)) {
    Write-Host "Lade den AutoHotkey-Compiler (Ahk2Exe) von github.com/AutoHotkey/Ahk2Exe ..."
    New-Item -ItemType Directory -Force $tools | Out-Null
    $rel = Invoke-RestMethod "https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest" -Headers @{ "User-Agent" = "vorschau-build" }
    $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    if (-not $asset) { throw "Kein Compiler-Download gefunden." }
    $zip = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath $tools -Force
    Remove-Item $zip
    if (-not (Test-Path $compiler)) { throw "Ahk2Exe.exe nicht im Download gefunden." }
}

Write-Host "Baue Vorschau.exe ..."
$p = Start-Process $compiler -Wait -PassThru -ArgumentList "/in", "`"$src`"", "/out", "`"$exe`"", "/icon", "`"$icon`"", "/base", "`"$base`"", "/silent"
if ($p.ExitCode -ne 0 -or -not (Test-Path $exe)) { throw "Ahk2Exe ist mit Code $($p.ExitCode) beendet, Vorschau.exe fehlt." }
Write-Host "Fertig: $exe"
