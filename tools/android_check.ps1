# 8-Bit Buhurt: Combat Club — is this machine able to build an APK?
#
#   powershell -ExecutionPolicy Bypass -File tools\android_check.ps1
#
# EVERY PREREQUISITE, CHECKED AND NAMED, BEFORE ANYTHING IS BUILT. Godot's
# Android export refuses with a wall of four errors that all say "SDK" and none
# of which say which piece is actually missing, and it refuses AFTER doing the
# work. This asks each question separately and prints what it found, so the
# answer to "why won't it build" is one line rather than a search.
#
# It changes nothing. It only looks.

$ErrorActionPreference = "Continue"
$fails = @()
$warns = @()

function Say($ok, $label, $detail) {
    if ($ok -eq "pass") { $c = "Green" } elseif ($ok -eq "warn") { $c = "Yellow" } else { $c = "Red" }
    Write-Host ("  {0,-5} {1,-28} {2}" -f $ok, $label, $detail) -ForegroundColor $c
    if ($ok -eq "FAIL") { $script:fails += $label }
    if ($ok -eq "warn") { $script:warns += $label }
}

Write-Host ""
Write-Host "=== Combat Club - can this machine build an APK ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------- 1. Godot
# THE ENGINE VERSION HAS TO MATCH THE TEMPLATES EXACTLY. 4.6-stable templates
# do not work with a 4.6.1 editor and the error you get says nothing useful.
$godot = $null
foreach ($c in @(
    $env:GODOT,
    "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6-stable_win64_console.exe",
    "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6-stable_win64.exe",
    "C:\Program Files\Godot\Godot_v4.6-stable_win64_console.exe",
    "C:\Godot\Godot_v4.6-stable_win64_console.exe",
    "C:\Godot\Godot_v4.6-stable_win64.exe"
)) { if ($c -and (Test-Path $c)) { $godot = $c; break } }
if (-not $godot) {
    $p = Get-Command godot -ErrorAction SilentlyContinue
    if ($p) { $godot = $p.Source }
}
if (-not $godot) {
    # Last resort: anything called Godot_v4.6* anywhere obvious.
    $hit = Get-ChildItem -Path @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "C:\Dev") `
        -Filter "Godot_v4.6*.exe" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object { $_.Name -notlike "*console*" } | Select-Object -First 1
    if ($hit) { $godot = $hit.FullName }
}
if ($godot) {
    $ver = (& $godot --version 2>&1 | Select-Object -First 1)
    $okv = "$ver" -match "^4\.6\."
    Say $(if ($okv) { "pass" } else { "FAIL" }) "Godot editor" "$ver  --  $godot"
    if (-not $okv) { Write-Host "         the templates below are 4.6.stable and must match the engine exactly" -ForegroundColor Yellow }
} else {
    Say "FAIL" "Godot editor" "not found - set `$env:GODOT to the .exe, or put it on PATH"
}

# ------------------------------------------------------- 2. Export templates
# 1.2GB, not in the repo, and never should be.
$tpl = "$env:APPDATA\Godot\export_templates\4.6.stable"
$need = @("android_debug.apk", "android_release.apk")
if (Test-Path $tpl) {
    $missing = @($need | Where-Object { -not (Test-Path (Join-Path $tpl $_)) })
    if ($missing.Count -eq 0) {
        $n = (Get-ChildItem $tpl -File).Count
        Say "pass" "Export templates" "$n files in $tpl"
    } else {
        Say "FAIL" "Export templates" ("missing " + ($missing -join ", ") + " in $tpl")
    }
} else {
    Say "FAIL" "Export templates" "no folder at $tpl"
}

# ------------------------------------------------------------ 3. Android SDK
$sdk = $null
foreach ($c in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk")) {
    if ($c -and (Test-Path $c)) { $sdk = $c; break }
}
if ($sdk) { Say "pass" "Android SDK" $sdk }
else { Say "FAIL" "Android SDK" "not found - Android Studio installs it at %LOCALAPPDATA%\Android\Sdk" }

# adb and apksigner are the two binaries Godot names by hand when it refuses.
$adb = $null
if ($sdk) {
    $adb = Join-Path $sdk "platform-tools\adb.exe"
    if (Test-Path $adb) { Say "pass" "platform-tools (adb)" $adb }
    else { Say "FAIL" "platform-tools (adb)" "missing - SDK Manager > SDK Tools > Android SDK Platform-Tools"; $adb = $null }
}

$bt = $null
if ($sdk -and (Test-Path (Join-Path $sdk "build-tools"))) {
    # NEWEST FIRST. Godot picks one itself; this reports which ones exist so a
    # machine with only an ancient build-tools is visible rather than puzzling.
    $bt = Get-ChildItem (Join-Path $sdk "build-tools") -Directory |
          Sort-Object Name -Descending | Select-Object -First 1
    if ($bt -and (Test-Path (Join-Path $bt.FullName "apksigner.bat"))) {
        Say "pass" "build-tools (apksigner)" $bt.Name
    } else {
        Say "FAIL" "build-tools (apksigner)" "found $($bt.Name) with no apksigner.bat"
    }
} elseif ($sdk) {
    Say "FAIL" "build-tools (apksigner)" "no build-tools at all - SDK Manager > SDK Tools > Android SDK Build-Tools"
}

# --------------------------------------------------------------------- 4. Java
# apksigner.bat is a wrapper around java. No java, no signed APK, and the error
# blames the SDK.
$java = $null
foreach ($c in @(
    "$env:JAVA_HOME\bin\java.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\java.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\java.exe"
)) { if ($c -and (Test-Path $c)) { $java = $c; break } }
if (-not $java) {
    $p = Get-Command java -ErrorAction SilentlyContinue
    if ($p) { $java = $p.Source }
}
if ($java) {
    $jv = (& $java -version 2>&1 | Select-Object -First 1)
    Say "pass" "Java (for apksigner)" "$jv"
} else {
    Say "FAIL" "Java (for apksigner)" "none - Android Studio ships one at ...\Android Studio\jbr"
}

# ----------------------------------------------------------- 5. Debug keystore
# Godot 4.6 will generate this itself if it is missing, but only if it can find
# keytool - so a missing one plus a missing java is two failures wearing one hat.
$ks = "$env:USERPROFILE\.android\debug.keystore"
if (Test-Path $ks) { Say "pass" "Debug keystore" $ks }
else { Say "warn" "Debug keystore" "absent - Godot will make one, or see the keytool line in docs/EXPORTING.md" }

# ------------------------------------------- 6. Godot knows where the SDK is
# THE ONE SETTING THAT IS NOT IN THIS REPO AND NEVER WILL BE. It is an EDITOR
# setting, per machine, and it is the single reason the Android export refused
# on every machine this project has been built on so far.
$es = Get-ChildItem "$env:APPDATA\Godot" -Filter "editor_settings-4*.tres" -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending | Select-Object -First 1
if ($es) {
    $line = Select-String -Path $es.FullName -Pattern 'android_sdk_path' -ErrorAction SilentlyContinue |
            Select-Object -First 1
    if ($line -and $line.Line -notmatch '=\s*""') {
        Say "pass" "Godot's SDK path setting" ($line.Line.Trim())
    } else {
        Say "FAIL" "Godot's SDK path setting" "empty in $($es.Name) - Editor Settings > Export > Android > Android Sdk Path"
    }
} else {
    Say "warn" "Godot's SDK path setting" "no editor settings file yet - open the editor once"
}

# -------------------------------------------------------------- 7. An emulator
# ARCHITECTURE MATTERS AND IS EASY TO GET WRONG. The Android preset ships
# arm64-v8a and x86_64 and deliberately NOT armeabi-v7a. On an Intel or AMD
# Windows box the emulator image must be x86_64; an arm64 image will run under
# emulation at a speed nobody would test a game at.
$avds = Get-ChildItem "$env:USERPROFILE\.android\avd" -Filter "*.ini" -ErrorAction SilentlyContinue
if ($avds -and $avds.Count -gt 0) {
    Say "pass" "Emulator AVDs" (($avds | ForEach-Object { $_.BaseName }) -join ", ")
} else {
    Say "warn" "Emulator AVDs" "none - Android Studio > Device Manager > Create Virtual Device"
}
if ($adb) {
    $devs = (& $adb devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "\S" })
    if ($devs) { Say "pass" "Running devices" (($devs -join " | ")) }
    else { Say "warn" "Running devices" "none attached - start the emulator before installing" }
}

# -------------------------------------------------------------------- verdict
Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "READY TO BUILD. Next: tools\android_run.ps1" -ForegroundColor Green
} else {
    Write-Host ("BLOCKED ON " + $fails.Count + ": " + ($fails -join ", ")) -ForegroundColor Red
}
if ($warns.Count -gt 0) {
    Write-Host ("Worth a look: " + ($warns -join ", ")) -ForegroundColor Yellow
}
Write-Host ""
