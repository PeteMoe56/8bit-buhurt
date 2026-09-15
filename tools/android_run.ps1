# 8-Bit Buhurt: Combat Club — export a debug APK and put it on the emulator.
#
#   powershell -ExecutionPolicy Bypass -File tools\android_run.ps1
#   powershell -ExecutionPolicy Bypass -File tools\android_run.ps1 -Avd Pixel_7_API_34
#   powershell -ExecutionPolicy Bypass -File tools\android_run.ps1 -NoBoot   # device already up
#
# Run tools\android_check.ps1 first. This one assumes the prerequisites and
# fails loudly rather than diagnosing.
#
# DEBUG, NOT RELEASE, AND ON PURPOSE. A debug build signs itself with the SDK's
# own throwaway keystore, so there is no credential anywhere near this script or
# the repo. A release build needs your own keystore and that is a separate
# conversation with its own rule - see docs/EXPORTING.md.

param(
    [string]$Avd = "",
    [switch]$NoBoot,
    [switch]$KeepRunning
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_find.ps1"
$root = Split-Path -Parent $PSScriptRoot
$apk  = Join-Path $root "build\combat-club.apk"
$pkg  = "com.bonkworks.combatclub"

function Step($s) { Write-Host "`n>> $s" -ForegroundColor Cyan }
function Die($s)  { Write-Host "`n!! $s" -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------------ the tools
# ASKED, NOT ASSUMED. Same finder the check script uses, so the two cannot
# disagree about which binary or which version this machine has.
$g = Find-Godot
if (-not $g.Path) { Die "No working Godot found. Set `$env:GODOT to the editor .exe and run again." }
$godot = $g.Path
Write-Host "Godot $($g.Version)  $godot" -ForegroundColor DarkGray
if (-not (Test-Path (Join-Path $g.TemplateDir "android_debug.apk"))) {
    Die "No android_debug.apk template for $($g.Version). Expected it in $($g.TemplateDir) - run tools\android_check.ps1."
}

$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
$adb = Join-Path $sdk "platform-tools\adb.exe"
$emu = Join-Path $sdk "emulator\emulator.exe"
if (-not (Test-Path $adb)) { Die "No adb at $adb - run tools\android_check.ps1" }

# ------------------------------------------------------------- 1. the emulator
# STARTED FIRST, because it takes 30-60 seconds to boot and the export takes
# about the same. Booting it while Godot works is the whole saving.
$booting = $null
if (-not $NoBoot) {
    $attached = (& $adb devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "device$" })
    if ($attached) {
        Step "A device is already attached - skipping the emulator"
    } else {
        if (-not (Test-Path $emu)) { Die "No emulator at $emu - SDK Manager > SDK Tools > Android Emulator" }
        if (-not $Avd) {
            $first = (& $emu -list-avds 2>&1 | Where-Object { $_ -match "\S" } | Select-Object -First 1)
            if (-not $first) { Die "No AVD exists. Android Studio > Device Manager > Create Virtual Device (x86_64 image)." }
            $Avd = "$first".Trim()
        }
        Step "Booting emulator '$Avd' in the background"
        $booting = Start-Process -FilePath $emu -ArgumentList @("-avd", $Avd) -PassThru
    }
}

# ---------------------------------------------------------------- 2. the export
Step "Exporting the debug APK"
New-Item -ItemType Directory -Force -Path (Join-Path $root "build") | Out-Null
Push-Location $root
try {
    # `--export-debug`, NOT `--export-release`. Release needs a keystore.
    & $godot --headless --path . --export-debug "Android" $apk 2>&1 | ForEach-Object { Write-Host "   $_" }
} finally { Pop-Location }
if (-not (Test-Path $apk)) { Die "Godot did not produce $apk - read the lines above, they name the missing piece." }
$mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "   $apk  ($mb MB)" -ForegroundColor Green

# ------------------------------------------------------------ 3. wait for boot
Step "Waiting for the device"
& $adb wait-for-device
# `wait-for-device` returns as soon as adb can talk to it, which is well before
# Android is up. The package manager is what has to be alive to take an install.
for ($i = 0; $i -lt 120; $i++) {
    $b = (& $adb shell getprop sys.boot_completed 2>$null)
    if ("$b".Trim() -eq "1") { break }
    Start-Sleep -Seconds 2
}
Write-Host "   booted" -ForegroundColor Green

# -------------------------------------------------------------- 4. the install
Step "Installing"
$out = (& $adb install -r $apk 2>&1)
$out | ForEach-Object { Write-Host "   $_" }
if ("$out" -match "INSTALL_FAILED_NO_MATCHING_ABIS") {
    Die "The AVD's architecture is not in the build. The preset ships arm64-v8a and x86_64 - on an Intel/AMD PC, make an x86_64 AVD."
}
if ("$out" -notmatch "Success") { Die "Install failed - see above." }

# --------------------------------------------------------------- 5. launch it
Step "Launching"
& $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Seconds 3

# THE GAME IS SENSOR_LANDSCAPE. An AVD that boots portrait shows it rotated
# unless auto-rotate is on, which is a five-minute puzzle the first time.
& $adb shell settings put system accelerometer_rotation 1 2>$null | Out-Null

Write-Host ""
Write-Host "Running. Logs:  $adb logcat -s godot" -ForegroundColor Green
Write-Host "Screenshot:     $adb exec-out screencap -p > shot.png" -ForegroundColor Green
Write-Host ""
if ($booting -and -not $KeepRunning) {
    Write-Host "The emulator was started by this script - close it when you are done." -ForegroundColor Yellow
}
