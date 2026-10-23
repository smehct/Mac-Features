# Mac Features für Windows

Ein AutoHotkey-Skript, das die gewohnten Mac-Tastenkürzel und den Mac-Screenshot unter Windows nachbildet. Es ist für eine **Mac-Tastatur mit Schweizerdeutschem Layout** an einem Windows-PC gedacht.

## Was es kann

### Tastenkürzel

Auf einer Mac-Tastatur kommt die Cmd-Taste unter Windows als Windows-Taste an, die Option-Taste (alt) als Alt-Taste.

| Taste | Funktion |
|---|---|
| Cmd allein drücken | Emoji-Fenster öffnen |
| Cmd+C / Cmd+V | Kopieren / Einfügen |
| Cmd+A | Alles markieren |
| Cmd+Z / Cmd+Shift+Z | Rückgängig / Wiederholen |
| Cmd+S / Cmd+Shift+S | Speichern / Speichern unter |
| Cmd+P | Drucken |
| Cmd+F | Suchen im Programm |
| Cmd+O / Cmd+N / Cmd+T / Cmd+W / Cmd+X | Öffnen / Neu / Neuer Tab / Tab schliessen / Ausschneiden |
| Cmd+O im Explorer oder auf dem Desktop | Markiertes Objekt öffnen (wie im Finder) |
| Cmd+Plus / Cmd+Minus / Cmd+0 | Vergrössern / Verkleinern / Originalgrösse |
| Cmd+Q | Programm beenden (auf Desktop und Taskleiste absichtlich ohne Wirkung) |
| Cmd+Tab | Zwischen offenen Programmen wechseln |
| Cmd+Leertaste | Windows-Suche öffnen (wie Spotlight) |
| Cmd+G | `@` |
| Cmd+Shift+4 | Screenshot eines Bereichs (siehe unten) |
| Shift+Löschen | Zeichen rechts vom Cursor löschen (Entf) |

### Sonderzeichen auf der Option-Taste

Funktioniert mit der linken und der rechten Option-Taste.

| Taste | Zeichen |
|---|---|
| Option+5 / Option+6 | `[` / `]` |
| Option+8 / Option+9 | `{` / `}` |
| Option+7 | `\|` |
| Option+Shift+7 | `\` |
| Option+N | `~` |
| Option+G | `@` (wie Cmd+G) |

Ausserdem sind die Taste links neben der 1 (§ °) und die Taste neben der linken Shift-Taste (< >) getauscht, damit sie das liefern, was draufsteht.

### Funktionstasten

| Taste | Funktion |
|---|---|
| F1 / F2 | Helligkeit runter / rauf (Laptop-Bildschirm und externe Monitore mit DDC/CI) |
| F3 | Alle Fenster anzeigen (Taskansicht, wie Mission Control) |
| F7 / F8 / F9 | Vorheriger Titel / Play-Pause / Nächster Titel |
| F10 / F11 / F12 | Stumm / Leiser / Lauter |

### Screenshot wie beim Mac

1. **Cmd+Shift+4** drücken. Der Bildschirm wird abgedunkelt, der Mauszeiger zum Fadenkreuz.
2. Mit gedrückter Maustaste einen Rahmen aufziehen. Der gewählte Bereich wird hell. Mit **Esc** abbrechen.
3. Unten rechts erscheint ein Vorschaubild mit Glasrahmen:
   - **Ziehen:** Das Bild per Drag & Drop direkt in ein Programm ziehen, z.B. in einen Chat, eine Mail oder einen Ordner.
   - **Nach rechts wegwischen:** Das Bild anfassen und nach rechts aus dem Bildschirm schieben. Es wird sofort auf dem Desktop gespeichert.
   - **Klicken:** Das Bild wird auf dem Desktop gespeichert und öffnet sich im Snipping Tool zum Bearbeiten. Ist das Snipping Tool nicht installiert, öffnet sich das Bild im Standardprogramm.
   - **Nichts tun:** Nach etwa 6 Sekunden liegt das Bild als `Screenshot JJJJ-MM-TT at HH.MM.SS.png` auf dem Desktop. Solange die Maus über dem Vorschaubild ist, bleibt es stehen.

## Installation

### Variante A: mit dem Installationsskript

1. Das Repository herunterladen: oben auf **Code → Download ZIP** klicken und den Ordner an einen festen Ort entpacken, z.B. `C:\Users\<Name>\Mac-Features`. Wer Git hat, kann auch klonen:

   ```bash
   git clone https://github.com/smehct/Mac-Features.git
   ```

2. Im Ordner eine PowerShell öffnen (im Explorer in die Adresszeile `powershell` tippen und Enter drücken) und ausführen:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

   Das Skript installiert AutoHotkey v2, richtet den Autostart ein, schaltet die Xbox Game Bar auf Win+G ab und startet die Mac-Kürzel.

3. Einmal ab- und wieder anmelden, damit die Game-Bar-Einstellung greift.

### Variante B: von Hand

1. [AutoHotkey v2](https://www.autohotkey.com/) installieren.
2. Das Repository herunterladen und entpacken (siehe oben).
3. Doppelklick auf `mac-features.ahk`. Unten rechts im Infobereich erscheint ein grünes H-Symbol, dann ist alles aktiv.
4. Autostart: `Win+R` drücken, `shell:startup` eingeben und eine Verknüpfung zu `mac-features.ahk` in diesen Ordner legen.
5. Damit Cmd+G nicht zusätzlich die Xbox Game Bar und Cmd+Z nicht die Fenster-Layouts öffnet, in PowerShell ausführen und danach ab- und wieder anmelden:

   ```powershell
   Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisabledHotkeys -Value "GZ"
   ```

**Wichtig:** Den Ordner nach der Installation nicht verschieben, sonst findet der Autostart das Skript nicht mehr. Falls doch, `install.ps1` am neuen Ort nochmals ausführen.

## Was dafür wegfällt

Die Kürzel überschreiben einige Windows-Funktionen:

| Windows-Kürzel | Ursprüngliche Funktion | Alternative |
|---|---|---|
| Win allein | Startmenü | Ctrl+Esc oder Klick auf das Windows-Symbol |
| Win+Leertaste | Tastatursprache wechseln | Alt+Shift |
| Win+V | Zwischenablage-Verlauf | – |
| Win+A | Schnelleinstellungen | Klick unten rechts auf WLAN/Lautstärke |
| Win+Z | Fenster-Andock-Layouts | – |
| Win+S | Suche | Cmd+Leertaste |
| Win+Shift+S | Snipping Tool | Cmd+Shift+4 |
| Win+P | Bildschirm projizieren | Schnelleinstellungen → Projizieren |
| Win+F | Feedback-Hub | – |
| Win+G | Xbox Game Bar | – |
| Win+O | Bildschirmausrichtung sperren | – |
| Win+N | Benachrichtigungen und Kalender | Klick auf Datum und Uhrzeit |
| Win+T | Taskleiste durchschalten | – |
| Win+W | Widgets | Klick auf das Widget-Symbol in der Taskleiste |
| Win+X | Power-Menü | Rechtsklick auf das Windows-Symbol |
| Win+Plus / Win+Minus | Bildschirmlupe | – |
| Win+Tab | Taskansicht | F3 |
| F1, F3, F7–F12 | Hilfe, Weitersuchen, Vollbild usw. in Programmen | – |

## Bekannte Grenzen

- Windows-Suche und Cmd+Tab öffnen sich immer auf dem Hauptbildschirm, das lässt Windows nicht anders zu.
- Option+N tippt die Tilde direkt. Kombinationen wie ñ gehen damit nicht.
- Bei mehreren Monitoren mit unterschiedlicher Skalierung kann der Screenshot-Rahmen leicht verschoben wirken.

## Anpassen, beenden, entfernen

- **Anpassen:** `mac-features.ahk` in einem Texteditor öffnen. Jede Zeile wie `#c::Send("^c")` ist ein Kürzel (`#` = Cmd/Win, `!` = Alt/Option, `+` = Shift, `^` = Ctrl). Nach dem Speichern das Skript per Doppelklick neu starten.
- **Beenden:** Rechtsklick auf das grüne H-Symbol im Infobereich → **Exit**.
- **Entfernen:** Skript beenden, die Verknüpfung „Mac Features“ aus `shell:startup` löschen und die Game-Bar-Einstellung zurücksetzen:

  ```powershell
  Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisabledHotkeys
  ```
