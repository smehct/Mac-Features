# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single AutoHotkey v2 script, `mac-features.ahk`, that adds macOS-style shortcuts to Windows for a user with a Mac keyboard and a Swiss German (de-CH, 0807) layout. "Cmd" is bound to both the Win key (`#`) and left Alt (`<!`), because it's unclear which one the Mac keyboard's Cmd key reports. Use left Alt only (`<!`), since AltGr on de-CH arrives as LCtrl+RAlt.

- `Cmd+G` types `@` (`SendText`, so it doesn't depend on the layout).
- `Cmd+C/V/A/Z/S/P/F` and `Cmd+Shift+S` send the matching Ctrl shortcut (Win+F would open the Feedback Hub). They're bound to the Win key only, so Alt+letter stays free for menu shortcuts. This replaces Windows' own Win+V (clipboard history), Win+A (quick settings), Win+Z (snap layouts), Win+S (search), Win+P (projection menu) and Win+Shift+S (Snipping Tool). `$#s` uses the keyboard hook so that `Send("#s")` from Cmd+Space doesn't trigger it.
- Tapping `Cmd` alone opens the emoji panel (`#.`) instead of Start. `~LWin` sends the `vkE8` mask key so Windows doesn't open Start, and `~LWin Up` checks `A_PriorKey`, which ignores script-generated input. Start is still reachable with Ctrl+Esc.
- Windows Search (`#s`) and the Alt+Tab switcher always open on the primary monitor, no matter where the mouse, the foreground window or the last-used taskbar is (tested). The user is fine with that, so there's no workaround.
- `Cmd+Tab` is AHK's built-in `AltTab` action as a custom combination (`LWin & Tab`), so the switcher stays open while Cmd is held. This replaces Task View.
- `F3` opens Task View (`#{Tab}`), like Mission Control. This replaces "find next" in apps.
- F-keys work like the Mac media keys: F1/F2 change brightness (laptop panel via WMI `WmiMonitorBrightnessMethods`, external monitors via DDC/CI `dxva2` in `AdjustBrightness`), F7/F8/F9 do previous/play-pause/next, F10/F11/F12 do mute/volume down/volume up. This replaces the apps' own F1 (help), F7–F12, etc.
- `Option+5/6/8/9` type `[ ] { }`, `Option+7` types `|`, `Option+Shift+7` types `\`, and `Option+N` types `~` (directly, not as a dead key), like the Mac de-CH layout. Left Option arrives as `<!`, right Option as AltGr (`<^>!`), so both are bound.
- `SC029`↔`SC056` are swapped, because a Mac ISO keyboard sends the §/° key and the </> key the wrong way round under de-CH.
- `Cmd+Q` sends Alt+F4, but not when the desktop or taskbar is active, because there Alt+F4 opens the shutdown dialog.
- `Shift+Backspace` sends `{Delete}`, because the Mac keyboard has no forward-delete key. `Send` releases Shift first, so in Explorer files go to the Recycle Bin instead of being deleted permanently (which Shift+Del would do).
- `Cmd+Space` opens Windows Search (`#s`), like Spotlight. It's bound to the Win key only and replaces Windows' input-language switcher on Win+Space.
- `Cmd+Shift+4` does a region screenshot like on macOS: a dimmed overlay over the whole virtual screen, a crosshair, drag a frame (Esc cancels), then a thumbnail at the bottom right in a frosted-glass frame. You can drag the thumbnail into any app as a file, swipe it to the right to save it right away, or click it to open the image. If you leave it alone, the PNG moves to the Desktop after about 6 s (hovering keeps it open).

## Commands

AutoHotkey v2 is installed per-user (via `winget install AutoHotkey.AutoHotkey`):

```powershell
$ahk = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
& $ahk mac-features.ahk                      # run / reload (#SingleInstance Force replaces the running copy)
& $ahk /ErrorStdOut /validate mac-features.ahk   # syntax check only
```

The Mac keyboard's Cmd key reports as the Win key. Windows' own Win+G (Xbox Game Bar) fires even though AHK grabs the hotkey, so it's turned off with `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\DisabledHotkeys = "G"`. That takes effect after an Explorer restart or a new sign-in.

Autostart is a shortcut in `shell:startup` (`Mac Features.lnk`) that points to this script. `install.ps1` sets everything up: it installs AHK, creates the autostart shortcut, applies the Win+G registry fix and starts the script. It can be re-run safely. `README.md` is the German user guide and must be kept in sync whenever shortcuts change.

AHK is a GUI exe, so stdout only gets captured with `Start-Process ... -RedirectStandardOutput <file> -Wait` and `/ErrorStdOut=UTF-8` plus `FileAppend(..., "*")` in the script. To test functions headlessly, write a scratch script that `#Include`s `mac-features.ahk`, calls e.g. `Capture(0,0,400,300)`, then `ExitApp`. Hotkeys and the drag gesture need a real user.

## Architecture notes

- Everything is raw Win32/GDI+/Shell calls through `DllCall`, with no AHK libraries:
  - capture: `BitBlt` with `CAPTUREBLT`, then GDI+ `GdipSaveImageToFile` with the PNG encoder CLSID `{557CF406-1A04-11D3-9A73-0000F81EF32E}`. A wrong CLSID makes GDI+ return status 10 and leaves a 0-byte file.
  - drag out: `SHParseDisplayName`, then `SHBindToParent` and `IShellFolder::GetUIObjectOf` (vtable 10) to get an `IDataObject`, then `SHDoDragDrop` with a NULL drop source, so there's no custom COM `IDropSource`. This needs `OleInitialize` at startup. Don't use `SHCreateDataObject` here: its object offers no formats (no CF_HDROP), so Chromium/Electron apps ignore the drop.
- When you click the thumbnail, the screenshot moves to the Desktop and opens in Snipping Tool. `OpenInSnippingTool` looks up the AppX ProgID of `Microsoft.ScreenSketch` under `HKCR\.png\OpenWithProgids` and calls `ShellExecuteEx` with `SEE_MASK_CLASSNAME`. Things that don't open the file: passing it on the command line (`SnippingTool.exe <file>`), the `ms-screensketch:edit?filePath=` protocol, and `IApplicationActivationManager::ActivateForFile` (the app is full-trust).
- Screenshots go to `%TEMP%\MacShots` first and only move to the Desktop when the thumbnail expires or gets clicked. If it gets dragged, the file stays in temp, because drop targets may read it later. Temp files older than 2 days are deleted at startup.
- The thumbnail is two windows. One is an acrylic pane (`SetWindowCompositionAttribute`, `ACCENT_ENABLE_ACRYLICBLURBEHIND`, plus DWM rounded corners and a border colour). The other is an owned picture window on top of it, because GDI content drawn inside an acrylic window turns semi-transparent. Moving or destroying the thumbnail must handle both windows (`MoveThumb`, `FinishThumb`). A mouse-down that moves mostly rightward is a swipe (`SwipeThumb`), anything else starts the OLE drag.
- The thumbnail runs on a 25 ms `SetTimer` (`ThumbTick`) rather than in the hotkey thread, so a new screenshot can finalize the previous thumbnail.
- All GUIs use `-DPIScale` and screen coordinates, so sizes are physical pixels (AHK v2 is per-monitor DPI aware). GUIs that must not steal focus use `WS_EX_NOACTIVATE` (`+E0x08000000`), and the frame lines are click-through (`+E0x20`).
