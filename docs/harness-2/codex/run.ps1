param([string]$Variant, [string]$Mode='import', [string]$Script='')
$taskRoot = "C:\Users\PeterM\Documents\Codex\work\harness-2\$Variant"
$logRoot = "C:\Users\PeterM\Documents\Codex\work\harness-2\logs"
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = 'C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe'
$prefix = "--headless --path $taskRoot --log-file $logRoot\$Variant-$Mode-engine.log"
if ($Mode -eq 'import') { $psi.Arguments = "$prefix --editor --import --quit" }
elseif ($Mode -eq 'sweep') { $psi.Arguments = "$prefix --script res://tools/probe_harness_budget.gd -- 5 20 --out=res://docs/bakeoff-2/harness/codex-$Variant" }
else { $psi.Arguments = "$prefix --script $Script" }
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['APPDATA'] = "$taskRoot\.runtime"
$proc = [System.Diagnostics.Process]::Start($psi)
$stdout = $proc.StandardOutput.ReadToEndAsync()
$stderr = $proc.StandardError.ReadToEndAsync()
$proc.WaitForExit()
$result = $stdout.Result + $stderr.Result
[System.IO.File]::WriteAllText("$logRoot\$Variant-$Mode-stdout.txt", $result)
$result
"EXIT=$($proc.ExitCode)"
exit $proc.ExitCode
