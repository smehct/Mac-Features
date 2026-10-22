# Sets up mac-features.ahk: installs AutoHotkey v2, adds an autostart shortcut,
# turns off Windows' own Win+G (Xbox Game Bar) and starts the script.
# Run from the repository folder:  powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = "Stop"
$script = Join-Path $PSScriptRoot "mac-features.ahk"
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path $ahk)) {
    Write-Host "Installiere AutoHotkey v2 ..."
    winget install --id AutoHotkey.AutoHotkey -e --accept-package-agreements --accept-source-agreements --silent
    if (-not (Test-Path $ahk)) { throw "AutoHotkey wurde nicht unter $ahk gefunden." }
}

Write-Host "Lege Autostart-Verknuepfung an ..."
$lnk = Join-Path ([Environment]::GetFolderPath("Startup")) "Mac Features.lnk"
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath = $ahk
$shortcut.Arguments = "`"$script`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Save()

Write-Host "Schalte Win+G (Xbox Game Bar) ab ..."
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisabledHotkeys -Value "G" -Type String

Write-Host "Starte das Skript ..."
Start-Process $ahk -ArgumentList "`"$script`""

Write-Host ""
Write-Host "Fertig. Damit Cmd+G nicht mehr die Game Bar oeffnet, einmal ab- und wieder anmelden."
