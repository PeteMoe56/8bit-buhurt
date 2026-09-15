# Finding the Godot binary, and asking IT what version it is.
#
# Dot-sourced by android_check.ps1 and android_run.ps1:
#     . "$PSScriptRoot\godot_find.ps1"
#
# WRITTEN BECAUSE BOTH SCRIPTS HARD-CODED "4.6". Pete's machine runs 4.6.2, and
# a hard-coded 4.6 sent the check looking for templates in a folder that will
# never exist while telling him, confidently, that his engine was wrong. **A
# number that has to agree with another number is a number that will stop
# agreeing** — so the version is asked for once, here, and the template folder
# is derived from the answer instead of typed next to it.
#
# AND THE CONSOLE WRAPPER IS A TRAP. `Godot_v4.x-stable_win64_console.exe` is a
# stub that relaunches the main `.exe` beside it by exact filename. If that file
# has been renamed or was never extracted, the wrapper exits with
# "Main executable ... not found" — which looks exactly like a broken engine and
# is a missing sibling. So every candidate is asked `--version` and only one
# that answers with a real version string is accepted.

function Get-GodotVersion($exe) {
    # STDERR FOLDED IN ON PURPOSE. The console wrapper's failure goes to stderr,
    # and an error you do not read is an error that did not happen.
    $out = (& $exe --version 2>&1 | Out-String)
    $m = [regex]::Match($out, '(?m)^\s*(\d+\.\d+(?:\.\d+)?\.[A-Za-z]+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Find-Godot {
    $seen = New-Object System.Collections.Generic.List[string]

    function Add-Candidate($p) {
        if ($p -and (Test-Path $p) -and -not $seen.Contains($p)) { $seen.Add($p) }
    }

    Add-Candidate $env:GODOT
    $onPath = Get-Command godot -ErrorAction SilentlyContinue
    if ($onPath) { Add-Candidate $onPath.Source }

    # The usual places, then a search of the ones people actually use.
    foreach ($d in @(
        "$env:LOCALAPPDATA\Programs\Godot",
        "C:\Program Files\Godot",
        "C:\Godot",
        "$env:USERPROFILE\Desktop\Game Dev",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Downloads",
        "C:\Dev"
    )) {
        if (-not (Test-Path $d)) { continue }
        # MAIN EXE BEFORE CONSOLE EXE. The console build is nicer for logs, but a
        # console build whose sibling is missing is not an engine at all, and
        # preferring it is what produced the FAIL this function exists to fix.
        # Both get tried; the order just decides which is asked first.
        $hits = Get-ChildItem -Path $d -Filter "Godot*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue |
                Sort-Object { $_.Name -like "*console*" }, { $_.Name } -Descending:$false
        foreach ($h in $hits) { Add-Candidate $h.FullName }
    }

    foreach ($c in $seen) {
        $v = Get-GodotVersion $c
        if ($v) {
            return [pscustomobject]@{
                Path        = $c
                Version     = $v
                # The export-template folder is named for the version string the
                # binary reports, exactly: "4.6.stable", "4.6.2.stable",
                # "4.7.beta3". Derived, never typed.
                TemplateDir = Join-Path "$env:APPDATA\Godot\export_templates" $v
                Tried       = $seen.Count
            }
        }
    }

    return [pscustomobject]@{
        Path = $null; Version = $null; TemplateDir = $null; Tried = $seen.Count
    }
}
