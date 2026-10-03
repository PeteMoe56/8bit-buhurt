# 8-Bit Buhurt: Combat Club - the signed Play bundle (AAB), built on this PC.
#
#   Build_Store.bat                      (double-click; it runs this)
#   powershell -ExecutionPolicy Bypass -File tools\aab_store.ps1 [-Code 3] [-Name 1.0.0]
#
# THE ACTM WAY (3 Oct 2026): Android bundles are built at the desk with the
# upload key that lives on this machine, and uploaded to Play by hand. Codemagic
# is for iOS only (Linux runners aren't on the free plan anyway).
#
# THE KEY NEVER TOUCHES THE REPO. The keystore and its password file both live
# in C:\Dev\keys; the password goes to Godot through this process's environment
# (GODOT_ANDROID_KEYSTORE_RELEASE_*), cleared when the export finishes.
#
# VERSION CODE: Play refuses a code it has seen. The last code shipped is kept
# in export_presets.cfg (version/code); this bumps it by one, writes it back,
# and builds from a scratch copy so the export's android\ folder and .godot
# cache never land in the tree. Commit the preset afterwards.

param(
    [int]$Code = 0,
    [string]$Name = "",
    [string]$Keystore = "C:\Dev\keys\combatclub-upload.jks",
    [string]$Alias = "upload"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_find.ps1"
$root = Split-Path -Parent $PSScriptRoot
function Step($s) { Write-Host "`n>> $s" -ForegroundColor Cyan }
function Die($s)  { Write-Host "`n!! $s" -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------------ 1. tools
$g = Find-Godot
if (-not $g.Path) { Die "No working Godot found. Set `$env:GODOT to the editor .exe, or run tools\android_check.ps1." }
Write-Host "Godot $($g.Version)  $($g.Path)" -ForegroundColor DarkGray
# A gradle build needs the SOURCE template, not just the prebuilt APKs.
if (-not (Test-Path (Join-Path $g.TemplateDir "android_source.zip"))) {
    Die "No android_source.zip in $($g.TemplateDir). Editor > Manage Export Templates > reinstall $($g.Version)."
}
if (-not (Test-Path $Keystore)) { Die "No upload key at $Keystore (make_upload_key.bat makes it)." }

# --------------------------------------------------------------- 2. version
$preset = Join-Path $root "export_presets.cfg"
$text = [IO.File]::ReadAllText($preset)
$m = [regex]::Match($text, '(?m)^version/code=(\d+)')
if (-not $m.Success) { Die "version/code not found in export_presets.cfg" }
$last = [int]$m.Groups[1].Value
if ($Code -le 0) { $Code = $last + 1 }
## THE NAME FROM THE PRESET unless one is passed: bump version/name there (or
## run "Build_Store.bat 1.0.1") for a new version.
if (-not $Name) {
    $nm = [regex]::Match($text, '(?m)^version/name="([^"]*)"')
    $Name = if ($nm.Success) { $nm.Groups[1].Value } else { "1.0.0" }
}
if ($Code -le $last -and $last -gt 1) {
    Write-Host "   version/code $Code is not above the last one built ($last) - Play will refuse it if $last was uploaded." -ForegroundColor Yellow
}
Write-Host "   version $Name ($Code)" -ForegroundColor Green

# ---------------------------------------------------------------- 3. the key
# THE ACTM ARRANGEMENT: ACTM keeps its upload-key password in android\key.properties
# (gitignored), so its bat never asks. Same here, but the file sits beside the
# key in C:\Dev\keys, outside the repo entirely. Asked ONCE, the first run,
# then saved there; never asked again.
$props = [IO.Path]::ChangeExtension($Keystore, ".properties")
$pw = $null
if (Test-Path $props) {
    foreach ($line in Get-Content $props) {
        if ($line -match '^\s*storePassword\s*=\s*(.*)$') { $pw = $Matches[1].Trim() }
        if ($line -match '^\s*keyAlias\s*=\s*(.*)$')      { $Alias = $Matches[1].Trim() }
    }
    Write-Host "   key password from $props" -ForegroundColor DarkGray
}
if (-not $pw) {
    Write-Host "   First run: the password you set in make_upload_key.bat. It is saved to" -ForegroundColor Yellow
    Write-Host "   $props (outside the repo) and not asked again." -ForegroundColor Yellow
    $sec = Read-Host "Upload key password" -AsSecureString
    $pw = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    if (-not $pw) { Die "No password typed." }
    $savePw = $true
}

# NATIVE STDERR IS NOT AN ERROR. Under "Stop", Windows PowerShell 5.1 turns
# any line Godot or gradle writes to stderr (warnings included) into a throw.
$ErrorActionPreference = "Continue"

# ------------------------------------------------------------ 4. scratch copy
Step "Scratch copy"
$work = Join-Path $env:TEMP ("ccaab_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$p = Join-Path $work "p"
& robocopy $root $p /MIR /NFL /NDL /NJH /NJS /NP /XD .git build android logs .godot "Claude outputs" _to_delete | Out-Null
if ($LASTEXITCODE -ge 8) { Die "robocopy failed ($LASTEXITCODE)" }
$pp = Join-Path $p "export_presets.cfg"
$t = [IO.File]::ReadAllText($pp)
$t = [regex]::Replace($t, '(?m)^version/code=.*$', "version/code=$Code")
$t = [regex]::Replace($t, '(?m)^version/name=.*$', "version/name=""$Name""")
[IO.File]::WriteAllText($pp, $t)
## The title screen shows the build: "1.0.0 (3)".
$pg = Join-Path $p "project.godot"
$g2 = [IO.File]::ReadAllText($pg)
$g2 = [regex]::Replace($g2, '(?m)^config/version=.*$', "config/version=""$Name ($Code)""")
[IO.File]::WriteAllText($pg, $g2)
New-Item -ItemType Directory -Force -Path (Join-Path $p "build") | Out-Null

# ------------------------------------------------------------------ 5. export
$aab = Join-Path $p "build\out.aab"
try {
    Step "Importing (first run in a fresh copy takes a minute)"
    & $g.Path --headless --path $p --import 2>&1 | Out-Null
    Step "Gradle export - several minutes"
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $Keystore
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $Alias
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $pw
    # --install-android-build-template only works alongside an export.
    & $g.Path --headless --path $p --install-android-build-template --export-release "Android" $aab 2>&1 |
        Where-Object { "$_" -match "ERROR|FAIL|BUILD|DONE" } | ForEach-Object { Write-Host "   $_" }
} finally {
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_USER -ErrorAction SilentlyContinue
}
if (-not (Test-Path $aab)) { Die "No bundle was made - the lines above name the missing piece. Scratch copy kept at $p" }

# ------------------------------------------------------------- 6. keep it
$outDir = Join-Path $root "build"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$keep = Join-Path $outDir "combat-club-$Name-$Code.aab"
Copy-Item $aab $keep -Force
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
# A typo'd password fails the signing step above, so it is only saved once a
# signed bundle exists.
if ($savePw) {
    Set-Content -Path $props -Value @("storeFile=$Keystore", "keyAlias=$Alias", "storePassword=$pw") -Encoding ASCII
    Write-Host "   saved $props - next run won't ask" -ForegroundColor DarkGray
}
$pw = $null
# Only now, with a bundle in hand, does the tracked code move.
$text = [regex]::Replace($text, '(?m)^version/code=.*$', "version/code=$Code")
[IO.File]::WriteAllText($preset, $text)
$mb = [math]::Round((Get-Item $keep).Length / 1MB, 1)
Write-Host ""
Write-Host "DONE  $keep  ($mb MB)" -ForegroundColor Green
Write-Host "export_presets.cfg version/code is now $Code - commit it with the release." -ForegroundColor Green
Write-Host "Upload: Play Console > Test and release > Closed testing > the draft release > Upload." -ForegroundColor Green
