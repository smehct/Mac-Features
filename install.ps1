# Sets up mac-features.ahk: installs AutoHotkey v2, adds an autostart shortcut, builds Vorschau.exe
# (start menu entry, "Open with" for PDF files),
# turns off Windows' own Win+G (Xbox Game Bar) and Win+Z (snap layouts) and starts the script.
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

Write-Host "Baue Vorschau.exe ..."
& (Join-Path $PSScriptRoot "vorschau\build.ps1")
$vorschau = Join-Path $PSScriptRoot "vorschau\Vorschau.exe"

Write-Host "Lege Startmenue-Verknuepfung fuer Vorschau an ..."
$lnk = Join-Path ([Environment]::GetFolderPath("Programs")) "Vorschau.lnk"
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath = $vorschau
$shortcut.WorkingDirectory = Join-Path $PSScriptRoot "vorschau"
$shortcut.IconLocation = "$vorschau,0"
$shortcut.Save()

# "Oeffnen mit" fuer PDF-Dateien, nur fuer diesen Benutzer (HKCU); Standardprogramm muss man selbst festlegen.
& (Join-Path $PSScriptRoot "vorschau\register.ps1")

Write-Host "Schalte Win+G (Xbox Game Bar) und Win+Z (Fenster-Layouts) ab ..."
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisabledHotkeys -Value "GZ" -Type String

Write-Host "Starte das Skript ..."
Start-Process $ahk -ArgumentList "`"$script`""

Write-Host ""
Write-Host "Fertig. Damit Cmd+G nicht mehr die Game Bar oeffnet, einmal ab- und wieder anmelden."
Write-Host "Vorschau als Standard fuer PDF: Rechtsklick auf eine PDF > Oeffnen mit > Andere App waehlen > Vorschau > Immer."
