param([string]$Variant, [string]$Mode='import', [string]$Script='')
$taskRoot = "C:\Users\PeterM\Documents\Codex\work\harness-2-r2\$Variant"
$logRoot = 'C:\Dev\RetroBuhurt\docs\harness-2\codex\work-r2\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$modes = if ($Mode -eq 'sweep') { @('default','heldout') } else { @($Mode) }
foreach ($part in $modes) {
 $psi = [System.Diagnostics.ProcessStartInfo]::new()
 $psi.FileName = 'C:\Users\PeterM\Desktop\Godot_v4.6.2-stable_win64.exe'
 $prefix = "--headless --path $taskRoot --log-file $logRoot\$Variant-$part-engine.log"
 if ($part -eq 'import') { $psi.Arguments = "$prefix --editor --import --quit" }
 elseif ($part -eq 'default' -or $part -eq 'heldout') {
   $bases = if ($part -eq 'heldout') { '17011 29033 43049 67061 91081' } else { '' }
   $psi.Arguments = "$prefix --script res://tools/probe_harness_budget.gd -- 5 20 $bases --out=res://docs/bakeoff-2/harness/codex-r2-$Variant/$part"
 } else { $psi.Arguments = "$prefix --script $Script" }
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
 [System.IO.File]::WriteAllText("$logRoot\$Variant-$part-stdout.txt", $result)
 $result -split "`n" | Select-Object -Last 9
 "EXIT=$($proc.ExitCode)"
 if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
}
