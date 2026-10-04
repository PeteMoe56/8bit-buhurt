# 8-Bit Buhurt: Combat Club - the Steam build: Windows + Linux, uploaded with SteamPipe.
#
#   Build_Steam.bat                          (double-click; it runs this)
#   powershell -ExecutionPolicy Bypass -File tools\steam_build.ps1 [-User bonkworks] [-NoUpload] [-Desc "1.0.0 rc1"]
#
# WHAT IT DOES (4 Oct 2026):
#   1. finds Godot 4.6.2 and checks the Windows and Linux export templates are installed
#   2. exports the "Windows Desktop" and "Linux" presets into build\steam\content\windows and \linux
#      (each one a single binary with the .pck embedded)
#   3. writes the SteamPipe scripts into build\steam\scripts
#      app 5005040 -> depot 5005041 (Windows), depot 5005042 (Linux + SteamOS)
#   4. runs steamcmd to upload them, unless -NoUpload
#
# YOUR LOGIN STAYS YOURS. steamcmd asks for the password and the Steam Guard code
# itself, in this window. Nothing here reads, stores or passes a password.
#
# NOTHING GOES LIVE. The build is uploaded with no branch set live. In Steamworks:
# SteamPipe > Builds, pick the build, set it live on "default" (or a beta branch)
# and Publish. That is the step that puts it in front of players and reviewers.
#
# steamcmd: put it at C:\Dev\steamcmd\steamcmd.exe (download steamcmd.zip from
# https://developer.valvesoftware.com/wiki/SteamCMD, unzip there), or pass
# -SteamCmd <path>, or set $env:STEAMCMD.

param(
    [string]$User = $env:STEAM_USER,
    [string]$SteamCmd = $(if ($env:STEAMCMD) { $env:STEAMCMD } else { "C:\Dev\steamcmd\steamcmd.exe" }),
    [string]$Desc = "",
    [switch]$NoUpload
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\godot_find.ps1"
$root = Split-Path -Parent $PSScriptRoot
function Step($s) { Write-Host "`n>> $s" -ForegroundColor Cyan }
function Die($s)  { Write-Host "`n!! $s" -ForegroundColor Red; exit 1 }

$APP = 5005040
$DEPOT_WIN = 5005041
$DEPOT_LINUX = 5005042

# ------------------------------------------------------------------ 1. tools
Step "Godot and templates"
$g = Find-Godot
if (-not $g.Path) { Die "No working Godot found. Set `$env:GODOT to the editor .exe." }
Write-Host "Godot $($g.Version)  $($g.Path)" -ForegroundColor DarkGray
foreach ($t in @("windows_release_x86_64.exe", "linux_release.x86_64")) {
    if (-not (Test-Path (Join-Path $g.TemplateDir $t))) {
        Die "No $t in $($g.TemplateDir). Editor > Editor > Manage Export Templates > install $($g.Version)."
    }
}

# ------------------------------------------------------------- 2. version
$preset = Join-Path $root "export_presets.cfg"
$text = [IO.File]::ReadAllText($preset)
$m = [regex]::Match($text, '(?m)^version/name="([^"]+)"')
$ver = if ($m.Success) { $m.Groups[1].Value } else { "0.0.0" }
# US Central, like every other date this project writes.
$tz = [TimeZoneInfo]::FindSystemTimeZoneById("Central Standard Time")
$stamp = [TimeZoneInfo]::ConvertTime([DateTime]::UtcNow, $tz).ToString("yyyy-MM-dd HH:mm")
if ($Desc -eq "") { $Desc = "Combat Club $ver  $stamp CT" }
Write-Host "Build description: $Desc" -ForegroundColor DarkGray

# -------------------------------------------------------------- 3. export
$out = Join-Path $root "build\steam"
$win = Join-Path $out "content\windows"
$lin = Join-Path $out "content\linux"
$scripts = Join-Path $out "scripts"
foreach ($d in @($win, $lin, $scripts)) {
    if (Test-Path $d) { Remove-Item -Recurse -Force $d }
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

function Export($presetName, $file) {
    Step "Export: $presetName"
    & $g.Path --headless --path $root --export-release $presetName $file 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    if (-not (Test-Path $file)) { Die "$presetName export did not produce $file" }
    $mb = [math]::Round((Get-Item $file).Length / 1MB, 1)
    Write-Host "   $file  ($mb MB)" -ForegroundColor Green
}
Export "Windows Desktop" (Join-Path $win "combat-club.exe")
Export "Linux" (Join-Path $lin "combat-club.x86_64")
# The licences the fonts and the UI art ask to travel with the game.
foreach ($dst in @($win, $lin)) {
    Copy-Item (Join-Path $root "fonts\OFL.txt") (Join-Path $dst "OFL-BuhurtPlate.txt") -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $root "fonts\fallback\LanaPixel-OFL.txt") (Join-Path $dst "OFL-LanaPixel.txt") -ErrorAction SilentlyContinue
}

# ------------------------------------------------------ 4. SteamPipe scripts
Step "SteamPipe scripts"
function Depot($id, $content) {
@"
"DepotBuild"
{
	"DepotID" "$id"
	"ContentRoot" "$content"
	"FileMapping"
	{
		"LocalPath" "*"
		"DepotPath" "."
		"Recursive" "1"
	}
}
"@
}
[IO.File]::WriteAllText((Join-Path $scripts "depot_$DEPOT_WIN.vdf"), (Depot $DEPOT_WIN $win))
[IO.File]::WriteAllText((Join-Path $scripts "depot_$DEPOT_LINUX.vdf"), (Depot $DEPOT_LINUX $lin))
$appVdf = Join-Path $scripts "app_$APP.vdf"
[IO.File]::WriteAllText($appVdf, @"
"AppBuild"
{
	"AppID" "$APP"
	"Desc" "$Desc"
	"BuildOutput" "$(Join-Path $out 'output')"
	"ContentRoot" "$out"
	"SetLive" ""
	"Depots"
	{
		"$DEPOT_WIN" "depot_$DEPOT_WIN.vdf"
		"$DEPOT_LINUX" "depot_$DEPOT_LINUX.vdf"
	}
}
"@)
Write-Host "   $appVdf" -ForegroundColor Green

if ($NoUpload) {
    Write-Host "`nExported and scripted; not uploaded (-NoUpload)." -ForegroundColor Yellow
    Write-Host "Upload later:  `"$SteamCmd`" +login <you> +run_app_build `"$appVdf`" +quit"
    exit 0
}

# ------------------------------------------------------------ 5. upload
Step "Upload with steamcmd"
if (-not (Test-Path $SteamCmd)) {
    Die "No steamcmd at $SteamCmd. Unzip steamcmd.zip into C:\Dev\steamcmd (see the top of this file), or pass -SteamCmd."
}
if (-not $User) { $User = Read-Host "Steam account name (the Steamworks login)" }
Write-Host "steamcmd will ask for your password and Steam Guard code here." -ForegroundColor Yellow
& $SteamCmd +login $User +run_app_build $appVdf +quit
if ($LASTEXITCODE -ne 0) { Die "steamcmd exited $LASTEXITCODE. Its log is in $(Join-Path $out 'output')." }
Write-Host "`nUploaded. Steamworks > SteamPipe > Builds: set it live on a branch, then Publish." -ForegroundColor Green
