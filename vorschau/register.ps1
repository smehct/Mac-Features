# Registers Vorschau.exe as a program for PDF files ("Open with"), only for the current user (HKCU).
# Run:  powershell -ExecutionPolicy Bypass -File .\register.ps1
$ErrorActionPreference = "Stop"
$vorschau = Join-Path $PSScriptRoot "Vorschau.exe"
if (-not (Test-Path $vorschau)) { throw "Vorschau.exe fehlt, zuerst build.ps1 ausfuehren." }
$cls = "HKCU:\Software\Classes"
$cmd = "`"$vorschau`" `"%1`""
foreach ($key in "$cls\Applications\Vorschau.exe", "$cls\Vorschau.PDF") {
    New-Item -Force "$key\shell\open\command" -Value $cmd | Out-Null
    New-Item -Force "$key\DefaultIcon" -Value "`"$vorschau`",0" | Out-Null
}
Set-ItemProperty "$cls\Applications\Vorschau.exe" -Name FriendlyAppName -Value "Vorschau"
New-Item -Force "$cls\Applications\Vorschau.exe\SupportedTypes" | Out-Null
Set-ItemProperty "$cls\Applications\Vorschau.exe\SupportedTypes" -Name ".pdf" -Value ""
Set-ItemProperty "$cls\Vorschau.PDF" -Name "(default)" -Value "PDF-Dokument (Vorschau)"
New-Item -Force "$cls\.pdf\OpenWithProgids" | Out-Null
New-ItemProperty "$cls\.pdf\OpenWithProgids" -Name "Vorschau.PDF" -PropertyType Binary -Value ([byte[]]@()) -Force | Out-Null
Write-Host "Vorschau ist als PDF-Programm eingetragen."
Write-Host "Als Standard: Rechtsklick auf eine PDF > Oeffnen mit > Andere App waehlen > Vorschau > Immer."
