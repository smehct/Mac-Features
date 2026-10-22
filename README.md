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

### Vorschau: PDF-Programm wie auf dem Mac

Im Ordner `vorschau\` liegt ein eigenes PDF-Programm im Stil von Vorschau. Es läuft als App-Fenster in Edge (sonst Chrome) und braucht keine Installation ausser dem Skript. Gestartet wird es so:

- **Vorschau.exe** im Ordner `vorschau\` doppelklicken, oder eine PDF darauf ziehen. `install.ps1` baut die Datei, legt den Startmenü-Eintrag «Vorschau» an und trägt Vorschau bei «Öffnen mit» für PDF-Dateien ein. Zum Standardprogramm machst du es mit Rechtsklick auf eine PDF, «Öffnen mit», «Andere App wählen», «Vorschau», «Immer». Danach öffnet ein Doppelklick auf eine PDF direkt Vorschau, und jede weitere PDF geht als neuer Tab im bereits offenen Fenster auf.
- In einem Explorer-Fenster eine PDF-Datei markieren und **Cmd+O** drücken.
- Oder von Hand: `vorschau\Vorschau.exe datei.pdf` (ohne Exe: `AutoHotkey64.exe vorschau\vorschau.ahk datei.pdf`).

Was es kann:

| Bereich | Funktionen |
|---|---|
| Lesen | Mehrere PDFs in Tabs (Schliessen mit ✕ oder Mittelklick), Seitenleiste mit Miniaturen, Inhaltsverzeichnis und Kommentarliste (Pfeil am Seitenleisten-Knopf), Zoom, Suche mit Trefferzähler, Drucken |
| Markieren | Hervorheben, Unterstreichen und Durchstreichen als drei eigene Knöpfe mit Farbwahl, Notizen und Kommentare (auch zu Markierungen), Textfelder mit fett, kursiv, unterstrichen, durchgestrichen, Ausrichtung, Schriftart, Grösse und Farbe, Unterschrift, eigene Stempel, Bilder einfügen. Alles lässt sich danach auswählen, verschieben, kopieren, einsetzen, duplizieren und löschen |
| Zeichnen | Stift, Filzstift, Marker, Radierer, Formen (Rechteck, Oval, Linie, Pfeil in eine oder in beide Richtungen), Strichdicke und Schriftgrösse per Schieberegler |
| Bemassen | Strecken und Flächen messen, Massstab kalibrieren oder als 1:N festlegen, Einheit mm, cm, m, in oder ft. Endpunkte lassen sich nachziehen, die Beschriftung per Doppelklick ändern, bei neuem Massstab rechnen sich alle Masse neu |
| Formulare | Textfelder, Kontrollkästchen, Optionsfelder und Auswahllisten direkt ausfüllen |
| Seiten | Drehen, Löschen, per Ziehen umsortieren, weitere PDFs hineinziehen oder einfügen (zusammenbauen) |
| Sichern | Cmd+S speichert in die Datei, Cmd+Shift+S exportiert unter neuem Namen |
| Claude | Funkel-Knopf oben rechts: fragt die lokale Claude-CLI zum Dokument. Claude kann auch Werkzeuge bedienen («markiere alle Beträge grün», «drehe Seite 3», «füll das Feld Name aus»): Er schlägt die Änderungen vor, du siehst sie als Liste und wendest sie mit «Anwenden» an (ein Cmd+Z macht alles rückgängig). Bei markiertem Text erscheint daneben ein kleines Claude-Symbol für Erklären, Zusammenfassen und Übersetzen, aber nur, wenn die CLI angemeldet ist |

Aufbau von oben nach unten: obere Leiste mit den Grundfunktionen (Seitenleiste, Zoom, Teilen, Dateiname, Textauswahl und Objektauswahl als zwei Umschalter, Hervorheben, Kommentar, Messen, Drehen, Werkzeugkoffer, Claude, Suche), darunter die Markierungsleiste (Zeichnen, Formen, Text, Unterschrift, Stempel, Bild, Strichdicke, Farbe, Textstil), darunter die Tabs. Ein Klick auf den Dateinamen öffnet ein Menü zum Umbenennen (auch auf der Festplatte), Sichern und «Sichern unter …».

Beide Leisten lassen sich anpassen: Rechtsklick auf eine Leiste und «Werkzeugleisten anpassen …» wählen (oder den Regler-Knopf am Ende der Markierungsleiste), dann Symbole ziehen, um sie umzusortieren, oder anklicken, um sie aus- und wieder einzublenden. Unten erscheint eine Leiste mit «Zurücksetzen» und «Fertig». Aus dieser Leiste lassen sich ausserdem Abstände auf eine Leiste ziehen: ein flexibler Abstand schiebt alles dahinter an den Rand der Leiste (links- oder rechtsbündig), ein fester Abstand ist eine kleine Lücke. Ein Klick auf einen Abstand entfernt ihn wieder.

Kürzel im Programm: Cmd+O öffnen (in neuem Tab), Cmd+T neuer Tab, Cmd+Shift+Pfeil links/rechts Tab wechseln, Cmd+C / Cmd+X / Cmd+V / Cmd+D kopieren, ausschneiden, einsetzen, duplizieren (ausgewähltes Element), Pfeiltasten verschieben das Element (mit Shift grösser), Cmd+S sichern, Cmd+Shift+S exportieren, Cmd+P drucken, Cmd+F suchen, Cmd+G nächster Treffer, Cmd+Z / Cmd+Shift+Z rückgängig / wiederholen, Cmd+R nach rechts drehen, Cmd+Shift+R nach links drehen, Cmd+Plus / Cmd+Minus / Cmd+0 / Cmd+9 zoomen (100 % / Seitenbreite), Cmd+Shift+A Markierungsleiste, Cmd+Backspace Seite oder Markierung löschen. Cmd+L (links drehen) fängt Windows nicht ab, dafür gibt es Cmd+Shift+R.

Gut zu wissen:

- Der Name bei Kommentaren wird beim ersten Kommentar abgefragt (vorgeschlagen wird dein Windows-Name) und lässt sich oben in der Kommentarliste ändern. Er steht zusammen mit dem Datum im PDF-Kommentar, damit andere sehen, von wem er stammt. Die Dokument-Eigenschaften (Autor, Titel) lässt Vorschau beim Sichern unverändert, eingetragen wird nur «Vorschau» als Erzeuger.
- Notizen und Kommentare werden als echte PDF-Kommentare gespeichert und erscheinen auch in anderen PDF-Programmen. Alle Markierungen (Zeichnungen, Stempel, Bilder, Bemassungen, Text) sehen in anderen Programmen wie ins PDF eingebrannt aus. Vorschau legt sie beim Sichern aber zusätzlich als Daten in der Datei ab. Öffnet man das PDF wieder in Vorschau, sind sie weiterhin bearbeitbar, verschiebbar und löschbar, auch die Seitendrehung. Das klappt nur, solange die Datei nicht von einem anderen Programm neu geschrieben wurde, das die Seiteninhalte zusammenfasst. Dann bleiben die Markierungen eingebrannt (ungeprüft).
- Die Claude-Funktion schickt den Text der PDF an die lokale Claude-CLI, die dabei ohne Werkzeuge läuft. Sie muss installiert und angemeldet sein (`claude`, dann `/login`).
- Unterschrift, eigene Stempel, Name für Kommentare und Massstab merkt sich das Programm unter `%LOCALAPPDATA%\Vorschau\prefs.json`.

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
