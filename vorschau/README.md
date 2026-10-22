# Vorschau

Ein PDF-Programm für Windows im Stil der macOS-Vorschau. Lesen, markieren, kommentieren, zeichnen, bemassen, Formulare ausfüllen, Seiten umsortieren und zusammenbauen, signieren, stempeln, drucken, dazu optional Fragen an die lokale Claude-CLI.

## Starten

`Vorschau.exe` doppelklicken, oder eine PDF darauf ziehen. Weitere PDFs öffnen als Tabs im selben Fenster.

Voraussetzungen: Windows 10/11 mit PowerShell 5.1 (ist dabei) und Microsoft Edge oder Google Chrome. Die Exe startet einen kleinen lokalen Server (`server.ps1`, nur auf 127.0.0.1) und ein App-Fenster. Sie muss neben `server.ps1` und dem Ordner `app\` liegen.

Als PDF-Programm eintragen (nur für den eigenen Benutzer):

```powershell
powershell -ExecutionPolicy Bypass -File .\register.ps1
```

Danach Rechtsklick auf eine PDF, «Öffnen mit», «Andere App wählen», «Vorschau», «Immer».

## Selbst bauen

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Force
```

`build.ps1` braucht AutoHotkey v2 und lädt den Compiler Ahk2Exe von github.com/AutoHotkey/Ahk2Exe, falls er fehlt.

## Technik

Seite aus reinem JavaScript (`app\`) mit pdf.js (Anzeige, Apache-2.0) und pdf-lib (Schreiben, MIT), beides unter `app\lib` mitgeliefert. Markierungen werden beim Sichern ins PDF gezeichnet und zusätzlich als Daten abgelegt, damit sie beim erneuten Öffnen in Vorschau wieder bearbeitbar sind. Kommentare werden als echte PDF-Kommentare gespeichert.

Ausführliche Funktionsliste und Bedienung: siehe die README im Projekt Mac-Features, Abschnitt «Vorschau».
