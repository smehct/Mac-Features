#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
CoordMode "Mouse", "Screen"

; Mac-style shortcuts for Windows.
; "Cmd" is mapped to both the Win key and the left Alt key, because a Mac keyboard
; on Windows reports Cmd as Win (default) or Alt (if swapped in the driver).
;   Cmd+G        -> types "@"
;   Cmd+Shift+4  -> region screenshot with draggable thumbnail
;   Cmd+C/V/A/Z/S/P/F -> copy / paste / select all / undo / save / print / find (Win key only)
;   Cmd+Shift+S  -> save as
;   Cmd alone    -> emoji panel (Win+.) instead of Start
;   Cmd+Tab      -> app switcher (Alt+Tab)
;   Cmd+Q        -> quit app (Alt+F4)
;   F3           -> Task View (Mission Control)
;   F1/F2 brightness, F7/F8/F9 media prev/play/next, F10/F11/F12 mute/down/up
;   §/° and </> keys swapped back to their printed labels
;   Option+5/6/8/9 -> [ ] { },  Option+7 -> |,  Option+Shift+7 -> \,  Option+N -> ~
;   Shift+Backspace -> Delete (Mac keyboards have no forward-delete key)
;   Cmd+Space    -> Windows Search (Win key only; Alt+Space stays the window menu)

global TempDir := A_Temp "\MacShots"
global OverlayHwnd := 0
global ShotActive := false
global ShotCancelled := false
global Thumb := ""

DirCreate TempDir
CleanOldShots()
DllCall("LoadLibrary", "str", "gdiplus")
DllCall("ole32\OleInitialize", "ptr", 0)
OnMessage(0x20, OnSetCursor)  ; WM_SETCURSOR
SetTimer ThumbTick, 25
A_IconTip := "Mac Features (Cmd+G = @, Cmd+Shift+4 = Screenshot)"

#g::SendText("@")
<!g::SendText("@")
#c::Send("^c")
#v::Send("^v")  ; replaces Windows' clipboard history on Win+V
#a::Send("^a")
#z::Send("^z")
$#s::Send("^s")  ; $ so the Send("#s") in Cmd+Space doesn't trigger it
#+s::Send("^+s")  ; save as (replaces Windows' Snipping Tool on Win+Shift+S)
#p::Send("^p")
#f::Send("^f")  ; replaces Windows' Feedback Hub on Win+F
; Cmd tapped alone -> emoji panel. The vkE8 mask keeps Windows from opening Start on release;
; A_PriorKey ignores script-generated input, so it is "LWin" only if nothing else was pressed.
~LWin::Send("{Blind}{vkE8}")
~RWin::Send("{Blind}{vkE8}")
~LWin Up::EmojiIfAlone("LWin")
~RWin Up::EmojiIfAlone("RWin")
LWin & Tab::AltTab  ; app switcher stays open while Cmd is held (replaces Task View)
RWin & Tab::AltTab
#q::QuitApp()
F3::Send("#{Tab}")  ; Mission Control -> Task View (replaces "find next" in apps)
F1::AdjustBrightness(-10)
F2::AdjustBrightness(10)
F7::Send("{Media_Prev}")
F8::Send("{Media_Play_Pause}")
F9::Send("{Media_Next}")
F10::Send("{Volume_Mute}")
F11::Send("{Volume_Down}")
F12::Send("{Volume_Up}")
; Mac de-CH brackets on Option (left Alt, or right Option which Windows reports as AltGr)
<!5::SendText("[")
<!6::SendText("]")
<!8::SendText("{")
<!9::SendText("}")
<^>!5::SendText("[")
<^>!6::SendText("]")
<^>!8::SendText("{")
<^>!9::SendText("}")
<!7::SendText("|")
<!+7::SendText("\")
<!n::SendText("~")
<^>!7::SendText("|")
<^>!+7::SendText("\")
<^>!n::SendText("~")
; Mac ISO keyboards report the §/° key and the </> key swapped under Windows' de-CH layout.
SC029::SC056
SC056::SC029
+BS::Send("{Delete}")  ; forward delete; Shift is released, so Explorer recycles instead of hard-deleting
#Space::Send("#s")  ; Spotlight -> Windows Search (replaces the input-language switcher)
#+4::StartShot()
<!+4::StartShot()

EmojiIfAlone(key) {
    if A_PriorKey = key
        Send("#.")
}

; Alt+F4 on the desktop or taskbar would open the shutdown dialog, so skip those.
QuitApp() {
    if WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW") || WinActive("ahk_class Shell_TrayWnd")
        return
    Send("!{F4}")
}

; ---------------------------------------------------------------- brightness

; Laptop panel via WMI, external monitors via DDC/CI. Monitors that support neither are skipped.
AdjustBrightness(delta) {
    level := ""
    try {
        wmi := ComObjGet("winmgmts:\\.\root\WMI")
        for m in wmi.ExecQuery("SELECT CurrentBrightness FROM WmiMonitorBrightness")
            level := Max(0, Min(100, m.CurrentBrightness + delta))
        if level != ""
            for m in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods")
                m.WmiSetBrightness(1, level)
    }
    cb := CallbackCreate(DdcMonitor)
    mons := []
    ObjAddRef(ObjPtr(mons))
    DllCall("EnumDisplayMonitors", "ptr", 0, "ptr", 0, "ptr", cb, "ptr", ObjPtr(mons))
    ObjRelease(ObjPtr(mons))
    CallbackFree(cb)
    for hmon in mons {
        n := 0
        if !DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR", "ptr", hmon, "uint*", &n) || !n
            continue
        size := A_PtrSize + 256  ; PHYSICAL_MONITOR: HANDLE + WCHAR[128]
        phys := Buffer(size * n, 0)
        if !DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "ptr", hmon, "uint", n, "ptr", phys)
            continue
        loop n {
            h := NumGet(phys, (A_Index - 1) * size, "ptr")
            lo := 0, cur := 0, hi := 0
            if DllCall("dxva2\GetMonitorBrightness", "ptr", h, "uint*", &lo, "uint*", &cur, "uint*", &hi) {
                new := Max(lo, Min(hi, cur + Round(delta * (hi - lo) / 100)))
                DllCall("dxva2\SetMonitorBrightness", "ptr", h, "uint", new)
                if level = ""
                    level := Round((new - lo) * 100 / Max(1, hi - lo))
            }
        }
        DllCall("dxva2\DestroyPhysicalMonitors", "uint", n, "ptr", phys)
    }
    if level != "" {
        ToolTip("Helligkeit " level " %")
        SetTimer(() => ToolTip(), -1000)
    }
}

DdcMonitor(hmon, hdc, rect, data) {
    ObjFromPtrAddRef(data).Push(hmon)
    return 1
}

; ---------------------------------------------------------------- selection

StartShot() {
    global ShotActive, ShotCancelled, OverlayHwnd
    if ShotActive
        return
    ShotActive := true
    ShotCancelled := false

    vx := SysGet(76), vy := SysGet(77), vw := SysGet(78), vh := SysGet(79)
    ov := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
    ov.BackColor := "000000"
    ov.Show("NoActivate x" vx " y" vy " w" vw " h" vh)
    WinSetTransparent(70, ov)
    OverlayHwnd := ov.Hwnd

    lines := []
    loop 4 {
        l := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000020")
        l.BackColor := "FFFFFF"
        lines.Push(l)
    }

    Hotkey "Escape", CancelShot, "On"
    rect := ""
    try {
        while !GetKeyState("LButton", "P") {
            if ShotCancelled
                throw Error("cancelled")
            Sleep 10
        }
        MouseGetPos &sx, &sy
        ; keep mouse input on the overlay even when the cursor is over the cut-out hole
        DllCall("SetCapture", "ptr", ov.Hwnd)
        shown := false
        while GetKeyState("LButton", "P") {
            if ShotCancelled
                throw Error("cancelled")
            MouseGetPos &x, &y
            rx := Min(sx, x), ry := Min(sy, y), rw := Abs(x - sx), rh := Abs(y - sy)
            if rw > 0 && rh > 0 {
                SetFrame(lines, rx, ry, rw, rh, shown)
                SetHole(ov.Hwnd, vw, vh, rx - vx, ry - vy, rw, rh)
                shown := true
            }
            Sleep 10
        }
        MouseGetPos &x, &y
        rect := [Min(sx, x), Min(sy, y), Abs(x - sx), Abs(y - sy)]
    }
    DllCall("ReleaseCapture")
    Hotkey "Escape", "Off"
    for l in lines
        l.Destroy()
    ov.Destroy()
    OverlayHwnd := 0
    ShotActive := false

    if rect = "" || rect[3] < 3 || rect[4] < 3
        return
    Sleep 100  ; let the overlay disappear before grabbing pixels
    Capture(rect[1], rect[2], rect[3], rect[4])
}

CancelShot(*) {
    global ShotCancelled
    ShotCancelled := true
}

SetFrame(lines, x, y, w, h, shown) {
    lines[1].Move(x, y, w, 1)
    lines[2].Move(x, y + h - 1, w, 1)
    lines[3].Move(x, y, 1, h)
    lines[4].Move(x + w - 1, y, 1, h)
    if !shown
        for l in lines
            l.Show("NoActivate")
}

; Cuts the selection out of the dimmed overlay so that area shows at full brightness.
SetHole(hwnd, ow, oh, x, y, w, h) {
    rgn := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
    hole := DllCall("CreateRectRgn", "int", x, "int", y, "int", x + w, "int", y + h, "ptr")
    DllCall("CombineRgn", "ptr", rgn, "ptr", rgn, "ptr", hole, "int", 4)  ; RGN_DIFF
    DllCall("DeleteObject", "ptr", hole)
    DllCall("SetWindowRgn", "ptr", hwnd, "ptr", rgn, "int", 1)  ; window now owns rgn
}

OnSetCursor(wParam, lParam, msg, hwnd) {
    if OverlayHwnd && wParam = OverlayHwnd {
        DllCall("SetCursor", "ptr", DllCall("LoadCursor", "ptr", 0, "ptr", 32515, "ptr"))  ; IDC_CROSS
        return 1
    }
}

; ---------------------------------------------------------------- capture

Capture(x, y, w, h) {
    name := FormatTime(, "'Screenshot' yyyy-MM-dd 'at' HH.mm.ss") ".png"
    file := TempDir "\" name

    hdc := DllCall("GetDC", "ptr", 0, "ptr")
    mdc := DllCall("CreateCompatibleDC", "ptr", hdc, "ptr")
    hbm := DllCall("CreateCompatibleBitmap", "ptr", hdc, "int", w, "int", h, "ptr")
    old := DllCall("SelectObject", "ptr", mdc, "ptr", hbm, "ptr")
    DllCall("BitBlt", "ptr", mdc, "int", 0, "int", 0, "int", w, "int", h
        , "ptr", hdc, "int", x, "int", y, "uint", 0x40CC0020)  ; SRCCOPY | CAPTUREBLT
    DllCall("SelectObject", "ptr", mdc, "ptr", old)
    DllCall("DeleteDC", "ptr", mdc)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdc)

    si := Buffer(24, 0)
    NumPut("uint", 1, si)
    token := 0, bmp := 0
    DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", si, "ptr", 0)
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &bmp)
    png := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", png)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", bmp, "wstr", file, "ptr", png, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", bmp)
    DllCall("gdiplus\GdiplusShutdown", "ptr", token)
    DllCall("DeleteObject", "ptr", hbm)

    if FileExist(file)
        ShowThumb(file, name, w, h)
}

; ---------------------------------------------------------------- thumbnail

ShowThumb(file, name, w, h) {
    global Thumb
    FinishThumb()
    s := Min(220 / w, 140 / h, 1)
    tw := Max(1, Round(w * s)), th := Max(1, Round(h * s))
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
    g.MarginX := 0, g.MarginY := 0
    g.BackColor := "FFFFFF"
    g.Add("Picture", "x2 y2 w" tw " h" th, file)
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    g.Show("NoActivate x" (r - tw - 4 - 16) " y" (b - th - 4 - 16) " w" (tw + 4) " h" (th + 4))
    Thumb := {gui: g, file: file, name: name, deadline: A_TickCount + 6000}
}

ThumbTick() {
    global Thumb
    if !IsObject(Thumb)
        return
    MouseGetPos &mx, &my, &win
    over := (win = Thumb.gui.Hwnd)
    if over
        Thumb.deadline := A_TickCount + 3000
    else if A_TickCount > Thumb.deadline {
        FinishThumb()
        return
    }
    if !over || !GetKeyState("LButton", "P")
        return
    while GetKeyState("LButton", "P") {
        MouseGetPos &x, &y
        if Abs(x - mx) > 6 || Abs(y - my) > 6 {
            if StartDrag(Thumb.file)
                FinishThumb(false)
            return
        }
        Sleep 10
    }
    f := Thumb.file
    FinishThumb()
    ; Mac opens the preview on click; the file is on the Desktop by now.
    Run '"' A_Desktop "\" StrSplit(f, "\")[-1] '"'
}

; Moves the screenshot to the Desktop (unless it was dragged elsewhere) and closes the thumbnail.
FinishThumb(save := true) {
    global Thumb
    if !IsObject(Thumb)
        return
    t := Thumb
    Thumb := ""
    t.gui.Destroy()
    if save {
        try FileMove(t.file, A_Desktop "\" t.name)
        catch
            try FileCopy(t.file, A_Desktop "\" t.name)
    }
}

; Starts an OLE file drag from the temp file. Returns true if it was dropped on a target.
StartDrag(file) {
    pidl := 0, pdo := 0, effect := 0
    if DllCall("shell32\SHParseDisplayName", "wstr", file, "ptr", 0, "ptr*", &pidl, "uint", 0, "ptr", 0)
        return false
    iid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", "{0000010e-0000-0000-C000-000000000046}", "ptr", iid)
    hr := DllCall("shell32\SHCreateDataObject", "ptr", 0, "uint", 1, "ptr*", pidl, "ptr", 0
        , "ptr", iid, "ptr*", &pdo)
    if !hr
        DllCall("shell32\SHDoDragDrop", "ptr", 0, "ptr", pdo, "ptr", 0, "uint", 1, "uint*", &effect)  ; DROPEFFECT_COPY
    if pdo
        ObjRelease(pdo)
    DllCall("ole32\CoTaskMemFree", "ptr", pidl)
    return effect != 0
}

CleanOldShots() {
    loop files TempDir "\*.png" {
        if DateDiff(A_Now, A_LoopFileTimeModified, "Days") >= 2
            try FileDelete A_LoopFileFullPath
    }
}
