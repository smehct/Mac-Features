# Tiny local web server for Vorschau. Serves the viewer from -Root and reads/writes PDF files for it.
# Listens on 127.0.0.1 only; every file/prefs request needs the random token written to -State.
# Exits by itself once no viewer window has pinged for a while.
param([string]$Root, [string]$State)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path $Root).Path.TrimEnd('\')
$token = [guid]::NewGuid().ToString('N')
$prefsFile = Join-Path (Split-Path $State) 'prefs.json'
$idleLimit = 180   # seconds; minimised windows ping only about once a minute

$listener = $null
foreach ($i in 1..60) {
    $port = Get-Random -Minimum 49152 -Maximum 65000
    try {
        $l = New-Object System.Net.HttpListener
        $l.Prefixes.Add("http://127.0.0.1:$port/")
        $l.Start()
        $listener = $l
        break
    } catch { }
}
if (-not $listener) { exit 1 }

@{ port = $port; token = $token; pid = $PID } | ConvertTo-Json | Set-Content -Path $State -Encoding ASCII

$mime = @{
    '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'
    '.css' = 'text/css; charset=utf-8'; '.json' = 'application/json'; '.svg' = 'image/svg+xml'
    '.png' = 'image/png'; '.bcmap' = 'application/octet-stream'; '.pfb' = 'application/octet-stream'
    '.ttf' = 'font/ttf'; '.txt' = 'text/plain; charset=utf-8'
}

function Send($ctx, [int]$code, [byte[]]$bytes, [string]$type) {
    $r = $ctx.Response
    $r.StatusCode = $code
    $r.ContentType = $type
    $r.Headers['Cache-Control'] = 'no-store'
    $r.ContentLength64 = $bytes.Length
    $r.OutputStream.Write($bytes, 0, $bytes.Length)
    $r.OutputStream.Close()
}
function SendText($ctx, [int]$code, [string]$text) {
    Send $ctx $code ([Text.Encoding]::UTF8.GetBytes($text)) 'text/plain; charset=utf-8'
}

$lastPing = Get-Date
$jobs = @{}
$queue = New-Object System.Collections.ArrayList
try {
    while ($true) {
        $task = $listener.GetContextAsync()
        while (-not $task.Wait(2000)) {
            if (((Get-Date) - $lastPing).TotalSeconds -gt $idleLimit) { exit 0 }
        }
        $ctx = $task.Result
        try {
            $req = $ctx.Request
            $path = $req.Url.AbsolutePath
            $q = $req.QueryString
            $authed = ($q['t'] -eq $token)
            switch ($path) {
                '/ping' {
                    if (-not $authed) { SendText $ctx 403 'forbidden'; break }
                    $lastPing = Get-Date
                    SendText $ctx 200 'ok'
                }
                '/file' {
                    $f = $q['path']
                    if (-not $authed -or -not $f -or [IO.Path]::GetExtension($f).ToLower() -ne '.pdf') { SendText $ctx 403 'forbidden'; break }
                    if ($req.HttpMethod -eq 'GET') {
                        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { SendText $ctx 404 'not found'; break }
                        Send $ctx 200 ([IO.File]::ReadAllBytes($f)) 'application/pdf'
                    } elseif ($req.HttpMethod -eq 'PUT') {
                        $ms = New-Object IO.MemoryStream
                        $req.InputStream.CopyTo($ms)
                        $tmp = "$f.vorschau.tmp"
                        [IO.File]::WriteAllBytes($tmp, $ms.ToArray())
                        Move-Item -LiteralPath $tmp -Destination $f -Force
                        SendText $ctx 200 'saved'
                    } else { SendText $ctx 405 'method' }
                }
                '/queue' {
                    # files to open as new tabs in a running viewer window (the launcher posts, the windows poll)
                    if (-not $authed) { SendText $ctx 403 'forbidden'; break }
                    $lastPing = Get-Date
                    if ($req.HttpMethod -eq 'POST') {
                        if ($q['clear']) { $queue.Clear(); SendText $ctx 200 'ok'; break }
                        $f = $q['path']
                        if (-not $f -or [IO.Path]::GetExtension($f).ToLower() -ne '.pdf') { SendText $ctx 403 'forbidden'; break }
                        [void]$queue.Add($f); SendText $ctx 200 'ok'
                    } elseif ($q['count']) { SendText $ctx 200 ([string]$queue.Count) }
                    else { $items = @($queue); $queue.Clear(); SendText $ctx 200 (ConvertTo-Json -InputObject $items -Compress) }
                }
                '/whoami' {
                    # suggested comment author: the Windows full name, else the user name
                    if (-not $authed) { SendText $ctx 403 'forbidden'; break }
                    $n = $null
                    try { $n = (Get-CimInstance Win32_UserAccount -Filter "Name='$($env:USERNAME)' AND LocalAccount=True" -ErrorAction Stop).FullName } catch { }
                    if (-not $n) { $n = $env:USERNAME }
                    SendText $ctx 200 $n
                }
                '/rename' {
                    # renames a PDF inside its own folder; the new name may not contain a path
                    $f = $q['path']; $n = $q['name']
                    if (-not $authed -or $req.HttpMethod -ne 'POST' -or -not $f -or -not $n -or [IO.Path]::GetExtension($f).ToLower() -ne '.pdf') { SendText $ctx 403 'forbidden'; break }
                    if ($n -match '[\\/:*?"<>|]' -or [IO.Path]::GetExtension($n).ToLower() -ne '.pdf') { SendText $ctx 400 'ungueltiger Name'; break }
                    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { SendText $ctx 404 'not found'; break }
                    $target = Join-Path (Split-Path $f) $n
                    if ((Test-Path -LiteralPath $target) -and ($target -ne $f)) { SendText $ctx 409 'Datei existiert schon'; break }
                    if ($target -ne $f) { Move-Item -LiteralPath $f -Destination $target }
                    SendText $ctx 200 $target
                }
                '/claude' {
                    # Runs the local Claude CLI without any tools (the PDF text is untrusted input) as a background job.
                    if (-not $authed) { SendText $ctx 403 'forbidden'; break }
                    $lastPing = Get-Date
                    $dir = Join-Path (Split-Path $State) 'jobs'
                    if ($req.HttpMethod -eq 'POST') {
                        if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { SendText $ctx 501 'Claude CLI nicht gefunden'; break }
                        if ($q['login']) {
                            # opens a normal terminal with the interactive CLI, where the user types /login
                            Start-Process cmd.exe -ArgumentList '/c start "Claude anmelden" cmd /k claude'
                            $script:authAt = $null
                            SendText $ctx 200 'ok'; break
                        }
                        New-Item -ItemType Directory -Force $dir | Out-Null
                        $id = [guid]::NewGuid().ToString('N')
                        $inF = Join-Path $dir "$id.in"; $outF = Join-Path $dir "$id.out"; $errF = Join-Path $dir "$id.err"
                        $sr = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
                        [IO.File]::WriteAllText($inF, $sr.ReadToEnd(), (New-Object Text.UTF8Encoding $false))
                        $proc = Start-Process cmd.exe -ArgumentList '/c claude -p --tools "" --no-session-persistence --output-format text' `
                            -RedirectStandardInput $inF -RedirectStandardOutput $outF -RedirectStandardError $errF -WindowStyle Hidden -PassThru
                        $jobs[$id] = @{ p = $proc; t = Get-Date; files = @($inF, $outF, $errF) }
                        SendText $ctx 200 (@{ id = $id } | ConvertTo-Json -Compress)
                    } elseif ($q['status']) {
                        # signed-in check for the floating "ask Claude" button, cached for a few seconds
                        if (-not $script:authAt -or ((Get-Date) - $script:authAt).TotalSeconds -gt 20) {
                            $has = [bool](Get-Command claude -ErrorAction SilentlyContinue); $ok = $false
                            if ($has) { try { $ok = [bool](ConvertFrom-Json ((& claude auth status 2>$null) | Out-String)).loggedIn } catch { $ok = $false } }
                            $script:authAt = Get-Date; $script:authVal = @{ loggedIn = $ok; cli = $has }
                        }
                        SendText $ctx 200 ($script:authVal | ConvertTo-Json -Compress)
                    } else {
                        $j = $jobs[$q['id']]
                        if (-not $j) { SendText $ctx 404 'unbekannt'; break }
                        $res = @{ done = $false }
                        $timedOut = (((Get-Date) - $j.t).TotalSeconds -gt 300)
                        if ($j.p.HasExited -or $timedOut) {
                            if ($timedOut -and -not $j.p.HasExited) { Stop-Process -Id $j.p.Id -Force -ErrorAction SilentlyContinue }
                            $o = ''; $er = ''
                            if (Test-Path $j.files[1]) { $o = [IO.File]::ReadAllText($j.files[1], [Text.Encoding]::UTF8) }
                            if (Test-Path $j.files[2]) { $er = [IO.File]::ReadAllText($j.files[2], [Text.Encoding]::UTF8) }
                            $res = @{ done = $true; out = $o; err = $er; timeout = $timedOut }
                            $j.files | ForEach-Object { Remove-Item -LiteralPath $_ -ErrorAction SilentlyContinue }
                            $jobs.Remove($q['id'])
                        }
                        Send $ctx 200 ([Text.Encoding]::UTF8.GetBytes(($res | ConvertTo-Json -Compress))) 'application/json'
                    }
                }
                '/prefs' {
                    if (-not $authed) { SendText $ctx 403 'forbidden'; break }
                    if ($req.HttpMethod -eq 'GET') {
                        $t = '{}'
                        if (Test-Path -LiteralPath $prefsFile) { $t = [IO.File]::ReadAllText($prefsFile) }
                        Send $ctx 200 ([Text.Encoding]::UTF8.GetBytes($t)) 'application/json'
                    } elseif ($req.HttpMethod -eq 'PUT') {
                        $sr = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
                        [IO.File]::WriteAllText($prefsFile, $sr.ReadToEnd())
                        SendText $ctx 200 'saved'
                    } else { SendText $ctx 405 'method' }
                }
                default {
                    $rel = if ($path -eq '/') { 'app\index.html' } else { 'app' + $path.Replace('/', '\') }
                    $full = [IO.Path]::GetFullPath((Join-Path $Root $rel))
                    $appRoot = Join-Path $Root 'app'
                    if (-not $full.StartsWith($appRoot + '\') -or -not (Test-Path -LiteralPath $full -PathType Leaf)) { SendText $ctx 404 'not found'; break }
                    $ext = [IO.Path]::GetExtension($full).ToLower()
                    $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
                    Send $ctx 200 ([IO.File]::ReadAllBytes($full)) $type
                }
            }
        } catch {
            try { SendText $ctx 500 $_.Exception.Message } catch { }
        }
    }
} finally {
    $listener.Stop()
    Remove-Item -LiteralPath $State -ErrorAction SilentlyContinue
}
