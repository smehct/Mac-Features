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
;   Cmd+O/N/T/W/X -> open / new / new tab / close tab / cut (Win key only)
;   Cmd+Plus/Minus/0 -> zoom in / out / reset (Win key only)
;   Cmd+O in Explorer or on the desktop -> opens the selected item (Enter), like Finder
;   Cmd alone   -> emoji panel (Win+.) instead of Start
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
#HotIf WinActive("ahk_class CabinetWClass") || WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW")
#o::Send("{Enter}")  ; Cmd+O in Finder: open the selected item
#HotIf
#o::Send("^o")  ; replaces Windows' orientation lock on Win+O
#n::Send("^n")  ; replaces the notification centre on Win+N
#t::Send("^t")  ; replaces the taskbar focus on Win+T
#w::Send("^w")  ; replaces Widgets on Win+W
#x::Send("^x")  ; replaces the power user menu on Win+X
#=::Send("^=")  ; zoom in, replaces Magnifier on Win+Plus
#-::Send("^-")
#NumpadAdd::Send("^{NumpadAdd}")
#NumpadSub::Send("^{NumpadSub}")
#0::Send("^0")
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
    s := Min(293 / w, 187 / h, 1)
    tw := Max(1, Round(w * s)), th := Max(1, Round(h * s))
    bw := 10  ; width of the glass frame around the picture, in pixels
    gw := tw + 2 * bw, gh := th + 2 * bw
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    gx := r - gw - 16, gy := b - gh - 16

    ; Two windows: an acrylic "glass" pane, and the picture on top of it. GDI content drawn
    ; inside an acrylic window turns semi-transparent, so the picture needs its own window.
    glass := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
    glass.BackColor := "000000"
    glass.Show("NoActivate x" gx " y" gy " w" gw " h" gh)
    SetGlass(glass.Hwnd)
    Rounded(glass.Hwnd, 2, 0xFFFFFF)  ; DWMWCP_ROUND, light edge

    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000 +Owner" glass.Hwnd)
    g.MarginX := 0, g.MarginY := 0
    g.Add("Picture", "x0 y0 w" tw " h" th, file)
    g.Show("NoActivate x" (gx + bw) " y" (gy + bw) " w" tw " h" th)
    Rounded(g.Hwnd, 3)  ; DWMWCP_ROUNDSMALL
    Thumb := {gui: g, glass: glass, bw: bw, file: file, name: name, deadline: A_TickCount + 6000}
}

MoveThumb(t, x, y) {
    t.glass.Move(x, y)
    t.gui.Move(x + t.bw, y + t.bw)
}

; The thumbnail follows the mouse to the right; released past 40 px it slides off and is
; saved right away, otherwise it snaps back.
SwipeThumb(startX) {
    t := Thumb
    WinGetPos &gx, &gy, &gw, , t.glass
    off := 0
    while GetKeyState("LButton", "P") {
        MouseGetPos &x
        off := Max(0, x - startX)
        MoveThumb(t, gx + off, gy)
        Sleep 10
    }
    if off < 40 {
        MoveThumb(t, gx, gy)
        return
    }
    while off < gw + 20 {
        off += 30
        MoveThumb(t, gx + off, gy)
        Sleep 10
    }
    FinishThumb()
}

; Frosted-glass background: blurred desktop behind the window with a light tint.
SetGlass(hwnd) {
    accent := Buffer(16, 0)  ; ACCENT_POLICY
    NumPut("int", 4, accent, 0)  ; ACCENT_ENABLE_ACRYLICBLURBEHIND
    NumPut("uint", 0x55F2F2F2, accent, 8)  ; tint, AABBGGRR
    data := Buffer(8 + 2 * A_PtrSize, 0)  ; WINDOWCOMPOSITIONATTRIBDATA
    NumPut("uint", 19, data, 0)  ; WCA_ACCENT_POLICY
    NumPut("ptr", accent.Ptr, data, A_PtrSize)
    NumPut("uint", accent.Size, data, 2 * A_PtrSize)
    DllCall("SetWindowCompositionAttribute", "ptr", hwnd, "ptr", data)
}

; Windows 11 rounded corners (and optionally a border colour, RGB) through DWM.
Rounded(hwnd, pref, border := "") {
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 33, "int*", pref, "uint", 4)  ; DWMWA_WINDOW_CORNER_PREFERENCE
    if border != "" {
        bgr := ((border & 0xFF) << 16) | (border & 0xFF00) | ((border >> 16) & 0xFF)
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "uint", 34, "uint*", bgr, "uint", 4)  ; DWMWA_BORDER_COLOR
    }
}

ThumbTick() {
    global Thumb
    if !IsObject(Thumb)
        return
    MouseGetPos &mx, &my, &win
    over := (win = Thumb.gui.Hwnd || win = Thumb.glass.Hwnd)
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
            ; mostly rightward = swipe away (the thumbnail sits at the right screen edge, so
            ; drops into apps go left or up)
            if x - mx > 2 * Abs(y - my) {
                SwipeThumb(mx)
                return
            }
            if StartDrag(Thumb.file)
                FinishThumb(false)
            return
        }
        Sleep 10
    }
    f := Thumb.file
    FinishThumb()
    ; Mac opens the markup view on click; the file is on the Desktop by now.
    saved := A_Desktop "\" StrSplit(f, "\")[-1]
    if !OpenInSnippingTool(saved)
        Run '"' saved '"'
}

; Opens an image in Snipping Tool through its "Open with" ProgID (looked up, because the AppX
; hash is not documented). Snipping Tool ignores files passed on its command line or protocol.
OpenInSnippingTool(path) {
    progId := ""
    loop reg "HKCR\.png\OpenWithProgids" {
        try aumid := RegRead("HKCR\" A_LoopRegName "\Application", "AppUserModelID")
        catch
            continue
        if InStr(aumid, "Microsoft.ScreenSketch_") = 1 {
            progId := A_LoopRegName
            break
        }
    }
    if progId = ""
        return false
    sei := Buffer(112, 0)  ; SHELLEXECUTEINFOW on x64
    NumPut("uint", 112, sei, 0)
    NumPut("uint", 0x1, sei, 4)  ; SEE_MASK_CLASSNAME
    NumPut("ptr", StrPtr("open"), sei, 16)
    NumPut("ptr", StrPtr(path), sei, 24)
    NumPut("int", 1, sei, 48)  ; SW_SHOWNORMAL
    NumPut("ptr", StrPtr(progId), sei, 72)
    return DllCall("shell32\ShellExecuteExW", "ptr", sei)
}

; Moves the screenshot to the Desktop (unless it was dragged elsewhere) and closes the thumbnail.
FinishThumb(save := true) {
    global Thumb
    if !IsObject(Thumb)
        return
    t := Thumb
    Thumb := ""
    t.gui.Destroy()
    t.glass.Destroy()
    if save {
        try FileMove(t.file, A_Desktop "\" t.name)
        catch
            try FileCopy(t.file, A_Desktop "\" t.name)
    }
}

; Starts an OLE file drag from the temp file. Returns true if it was dropped on a target.
; The data object comes from the parent folder's IShellFolder::GetUIObjectOf, like Explorer's
; own drags: it offers CF_HDROP, FileContents etc. (SHCreateDataObject offers no formats, so
; browsers and Electron apps ignore the drop.)
StartDrag(file) {
    pidl := 0, psf := 0, child := 0, pdo := 0, effect := 0
    if DllCall("shell32\SHParseDisplayName", "wstr", file, "ptr", 0, "ptr*", &pidl, "uint", 0, "ptr", 0)
        return false
    iidFolder := Buffer(16), iidData := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", "{000214E6-0000-0000-C000-000000000046}", "ptr", iidFolder)
    DllCall("ole32\CLSIDFromString", "str", "{0000010e-0000-0000-C000-000000000046}", "ptr", iidData)
    try {
        if !DllCall("shell32\SHBindToParent", "ptr", pidl, "ptr", iidFolder, "ptr*", &psf, "ptr*", &child) {
            ComCall(10, psf, "ptr", 0, "uint", 1, "ptr*", child, "ptr", iidData, "ptr", 0, "ptr*", &pdo)  ; GetUIObjectOf
            DllCall("shell32\SHDoDragDrop", "ptr", 0, "ptr", pdo, "ptr", 0, "uint", 1, "uint*", &effect)  ; DROPEFFECT_COPY
        }
    }
    if pdo
        ObjRelease(pdo)
    if psf
        ObjRelease(psf)
    DllCall("ole32\CoTaskMemFree", "ptr", pidl)  ; child points into pidl, no separate free
    return effect != 0
}

CleanOldShots() {
    loop files TempDir "\*.png" {
        if DateDiff(A_Now, A_LoopFileTimeModified, "Days") >= 2
            try FileDelete A_LoopFileFullPath
    }
}
