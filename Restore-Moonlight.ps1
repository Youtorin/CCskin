param([string]$StateDirectory=(Join-Path $env:LOCALAPPDATA 'CCMoonlight'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\launcher.ps1')
$mutex=[Threading.Mutex]::new($false,'Local\CCMoonlight-Launcher')
$locked=$false
try{$locked=$mutex.WaitOne(30000)}catch [Threading.AbandonedMutexException]{$locked=$true}
if(-not $locked){$mutex.Dispose();throw 'The current launch is still busy; close the application after it finishes starting.'}
try{
$path=Join-Path $StateDirectory 'session.json'
if(-not(Test-Path -LiteralPath $path)){Write-Output 'No theme session exists.';exit 0}
$state=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
if([IO.Path]::GetFullPath($state.profile) -ne [IO.Path]::GetFullPath((Join-Path $StateDirectory 'profile'))){throw 'Unexpected profile location.'}
if([IO.Path]::GetFullPath($state.enginePath) -ne [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'engine.cjs'))){throw 'Unexpected engine location.'}
$package=Get-AppxPackage -Name OpenAI.Codex
$expected=Join-Path $package.InstallLocation 'app\ChatGPT.exe'
if($state.executable -ne $expected){throw 'Package changed; close the old themed window manually. No processes were stopped.'}
if($state.enginePid){
 $engine=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$state.enginePid)" -ErrorAction SilentlyContinue
 if($engine){
  if($engine.ExecutablePath -ne $state.node -or -not $engine.CommandLine.Contains($state.enginePath) -or -not $engine.CommandLine.Contains($path)){throw 'Engine identity mismatch.'}
  if($state.engineCreatedUtc -and [Math]::Abs(($engine.CreationDate.ToUniversalTime()-([DateTime]$state.engineCreatedUtc).ToUniversalTime()).TotalSeconds) -gt 1){throw 'Engine process creation time changed.'}
  Stop-Process -Id $engine.ProcessId
 }
}
$root=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$state.pid)" -ErrorAction SilentlyContinue
if($root){
 if($root.ExecutablePath -ne $expected -or (Get-MoonlightArgument $root.CommandLine 'user-data-dir') -ne $state.profile){throw 'Application identity mismatch.'}
 if($state.createdUtc -and [Math]::Abs(($root.CreationDate.ToUniversalTime()-([DateTime]$state.createdUtc).ToUniversalTime()).TotalSeconds) -gt 1){throw 'Application process creation time changed.'}
 $tree=@(Get-MoonlightTree @(Get-CimInstance Win32_Process) $root)
 try{& $state.node $state.enginePath --session $path --restore --close}catch{Write-Warning 'Theme removal could not be confirmed.'}
 $process=Get-Process -Id $root.ProcessId -ErrorAction SilentlyContinue
 if($process -and -not $process.WaitForExit(3000)){
  if(Test-MoonlightWindow $root.ProcessId){throw 'The themed window did not close. Save any draft and close it manually; no visible window was force-terminated.'}
 }
 # Renderer/utility processes may omit --user-data-dir. Use verified ancestry and creation times.
 Stop-MoonlightTree $tree
}
$deadline=[DateTime]::UtcNow.AddSeconds(5)
do{
 $listener=Get-NetTCPConnection -LocalPort ([int]$state.port) -State Listen -ErrorAction SilentlyContinue
 if(-not $listener){break};Start-Sleep -Milliseconds 100
}while([DateTime]::UtcNow -lt $deadline)
if($listener){throw 'A listener remains; verify the themed application is fully closed.'}
Write-Output 'Theme instance closed and debugging port released. Original Codex instance and configuration were not changed.'
}finally{$mutex.ReleaseMutex();$mutex.Dispose()}
