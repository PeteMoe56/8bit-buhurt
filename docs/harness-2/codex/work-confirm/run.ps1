param([string]$Mode='primary')
$taskRoot = if ($Mode -eq 'primary' -or $Mode -eq 'version') { 'C:\Dev\RetroBuhurt' } else { 'C:\Users\PeterM\Documents\Codex\work\harness-confirm-sensible' }
$logRoot = 'C:\Dev\RetroBuhurt\docs\harness-2\codex\work-confirm\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = 'C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe'
$prefix = "--headless --path $taskRoot --log-file $logRoot\$Mode-engine.log"
if ($Mode -eq 'version') { $psi.Arguments = '--version' }
elseif ($Mode -eq 'import') { $psi.Arguments = "$prefix --editor --import --quit" }
else {
 $script = if ($Mode -eq 'primary') { 'probe_harness_budget.gd' } else { 'probe_harness_budget_sensible.gd' }
 $out = if ($Mode -eq 'primary') { 'codex-confirm' } else { 'codex-confirm-sensible' }
 $psi.Arguments = "$prefix --script res://tools/$script -- 5 20 110017 130021 150041 170047 190027 --out=res://docs/bakeoff-2/harness/$out"
}
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['APPDATA'] = "$logRoot\runtime-$Mode"
$proc = [System.Diagnostics.Process]::Start($psi)
$stdout = $proc.StandardOutput.ReadToEndAsync()
$stderr = $proc.StandardError.ReadToEndAsync()
$proc.WaitForExit()
$result = $stdout.Result + $stderr.Result
[System.IO.File]::WriteAllText("$logRoot\$Mode-stdout.txt", $result)
$result -split "`n" | Select-Object -Last 9
"EXIT=$($proc.ExitCode)"
exit $proc.ExitCode
