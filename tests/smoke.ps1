# Optional Windows integration: an empty, isolated profile. Never uses the installed user's session.
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
. (Join-Path $repo 'lib\launcher.ps1')
$testState=Join-Path $repo ('work\smoke-'+[Guid]::NewGuid().ToString('N'))
$watch=[Diagnostics.Stopwatch]::StartNew()
& (Join-Path $repo 'Start-Moonlight.ps1') -StateDirectory $testState -NoIntro
$state=Get-Content -LiteralPath (Join-Path $testState 'session.json') -Raw | ConvertFrom-Json
$root=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$state.pid)"
if(-not $root -or (Get-MoonlightArgument $root.CommandLine 'user-data-dir') -ne (Join-Path $testState 'profile')){throw 'Smoke test refuses to touch a different profile.'}
$tree=@(Get-MoonlightTree @(Get-CimInstance Win32_Process) $root)
$deadline=[DateTime]::UtcNow.AddSeconds(15)
while(-not (Test-MoonlightWindow $root.ProcessId) -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 200}
$visible=Test-MoonlightWindow $root.ProcessId
if(-not $visible){throw "Isolated application has no visible window. Diagnostics: $testState"}
$startedMs=$watch.ElapsedMilliseconds
Start-Sleep -Seconds 3
# Browser.close reproduces the native exit path, including a windowless root that survives it.
& $state.node $state.enginePath --session (Join-Path $testState 'session.json') --close
$closedAt=$watch.ElapsedMilliseconds
$deadline=[DateTime]::UtcNow.AddSeconds(20)
do{
 $live=@{};Get-CimInstance Win32_Process | ForEach-Object {$live[[int]$_.ProcessId]=$_}
 $remaining=@($tree | Where-Object {Test-MoonlightIdentity $live[[int]$_.ProcessId] $_})
 if(-not $remaining.Count){break};Start-Sleep -Milliseconds 500
}while([DateTime]::UtcNow -lt $deadline)
if($remaining.Count){throw "Isolated shutdown left $($remaining.Count) processes. Diagnostics: $testState"}
$listeners=@(Get-NetTCPConnection -LocalPort ([int]$state.port) -State Listen -ErrorAction SilentlyContinue)
if($listeners.Count){throw 'Isolated debugging listener remained after exit.'}
[pscustomobject]@{startedMs=$startedMs;cleanupMs=$watch.ElapsedMilliseconds-$closedAt;trackedProcesses=$tree.Count;remaining=0;stateDirectory=$testState} | ConvertTo-Json
