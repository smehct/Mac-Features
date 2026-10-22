#Requires AutoHotkey v2.0
;@Ahk2Exe-SetName Vorschau
;@Ahk2Exe-SetDescription Vorschau - PDF-Programm
;@Ahk2Exe-SetVersion 1.0.0
;@Ahk2Exe-SetMainIcon app\icon.ico

; Opens the Vorschau PDF viewer (local web page in a Chromium app window: Edge, else Chrome).
; Standalone:  AutoHotkey64.exe vorschau.ahk [file.pdf]   (build.ps1 compiles this file to Vorschau.exe)
; A second file goes into the window that is already open, as a new tab.

OpenVorschau(path := "") {
    SplitPath A_IsCompiled ? A_ScriptFullPath : A_LineFile, , &dir   ; compiled: the folder of Vorschau.exe
    stateDir := EnvGet("LOCALAPPDATA") "\Vorschau"
    stateFile := stateDir "\server.json"
    DirCreate stateDir

    if path != "" {
        loop files path, "F"
            path := A_LoopFileFullPath
    }
    state := VorschauReadState(stateFile)
    if state && !VorschauPing(state.port, state.token) {
        try FileDelete stateFile
        state := ""
    }
    if state && path != "" && VorschauQueue(state, path)
        return
    if !state {
        Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' dir '\server.ps1" -Root "' dir '" -State "' stateFile '"', , "Hide")
        loop 80 {
            Sleep 100
            state := VorschauReadState(stateFile)
            if state
                break
        }
        if !state {
            MsgBox "Vorschau-Server konnte nicht gestartet werden."
            return
        }
    }

    ; any Chromium browser works for --app windows; Edge first, then Chrome
    edge := ""
    for exe in ["msedge.exe", "chrome.exe"] {
        reg := ""
        try reg := RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" exe, "")
        if reg != "" && FileExist(reg) {
            edge := reg
            break
        }
        sub := exe = "msedge.exe" ? "\Microsoft\Edge\Application\" : "\Google\Chrome\Application\"
        for dir in [A_ProgramFiles, EnvGet("ProgramFiles(x86)"), EnvGet("LOCALAPPDATA")] {
            if dir != "" && FileExist(dir sub exe) {
                edge := dir sub exe
                break 2
            }
        }
    }
    if edge = "" {
        MsgBox "Weder Microsoft Edge noch Google Chrome wurde gefunden."
        return
    }

    url := "http://127.0.0.1:" state.port "/index.html?t=" state.token
    if path != ""
        url .= "&file=" VorschauUrlEncode(path)
    Run('"' edge '" --app="' url '" --user-data-dir="' stateDir '\profile" --window-size=1180,860 --no-first-run --no-default-browser-check')
}

; hands the file to an open viewer window (it polls the server); false when nobody picks it up
VorschauQueue(state, path) {
    base := "http://127.0.0.1:" state.port "/queue?t=" state.token
    if VorschauHttp("POST", base "&path=" VorschauUrlEncode(path)) != "ok"
        return false
    loop 30 {
        Sleep 100
        if VorschauHttp("GET", base "&count=1") = "0" {
            SetTitleMatchMode 2
            for exe in ["msedge.exe", "chrome.exe"]
                if WinExist("Vorschau ahk_exe " exe) {
                    WinActivate
                    break
                }
            return true
        }
    }
    VorschauHttp("POST", base "&clear=1")
    return false
}

VorschauHttp(method, url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(500, 500, 1000, 1000)
        req.Open(method, url, false)
        req.Send()
        return req.Status = 200 ? Trim(req.ResponseText) : ""
    }
    return ""
}

VorschauReadState(file) {
    if !FileExist(file)
        return ""
    try text := FileRead(file, "UTF-8")
    catch
        return ""
    if RegExMatch(text, '"port"\s*:\s*(\d+)', &p) && RegExMatch(text, '"token"\s*:\s*"([0-9A-Za-z]+)"', &t)
        return {port: p[1], token: t[1]}
    return ""
}

VorschauPing(port, token) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(500, 500, 1000, 1000)
        req.Open("GET", "http://127.0.0.1:" port "/ping?t=" token, false)
        req.Send()
        return req.Status = 200 && req.ResponseText = "ok"
    }
    return false
}

VorschauUrlEncode(s) {
    n := StrPut(s, "UTF-8") - 1
    buf := Buffer(n + 1)
    StrPut(s, buf, "UTF-8")
    out := ""
    loop n {
        b := NumGet(buf, A_Index - 1, "UChar")
        if (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A) || b = 0x2D || b = 0x5F || b = 0x2E || b = 0x7E
            out .= Chr(b)
        else
            out .= Format("%{:02X}", b)
    }
    return out
}

if A_LineFile = A_ScriptFullPath || (A_IsCompiled && A_ScriptName ~= "i)^Vorschau") {
    OpenVorschau(A_Args.Length ? A_Args[1] : "")
    ExitApp
}
