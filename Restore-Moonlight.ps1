param([string]$StateDirectory=(Join-Path $env:LOCALAPPDATA 'CCMoonlight'))
$ErrorActionPreference='Stop'
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
  if($state.engineCreatedUtc -and [Math]::Abs(($engine.CreationDate.ToUniversalTime()-[DateTime]::Parse($state.engineCreatedUtc).ToUniversalTime()).TotalSeconds) -gt 1){throw 'Engine process creation time changed.'}
  Stop-Process -Id $engine.ProcessId
 }
}
$root=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$state.pid)" -ErrorAction SilentlyContinue
if($root){
 if($root.ExecutablePath -ne $expected -or -not $root.CommandLine.Contains($state.profile)){throw 'Application identity mismatch.'}
 if($state.createdUtc -and [Math]::Abs(($root.CreationDate.ToUniversalTime()-[DateTime]::Parse($state.createdUtc).ToUniversalTime()).TotalSeconds) -gt 1){throw 'Application process creation time changed.'}
 try{& $state.node $state.enginePath --session $path --restore --close}catch{Write-Warning 'Theme removal could not be confirmed.'}
 $process=Get-Process -Id $root.ProcessId -ErrorAction SilentlyContinue
 if($process -and -not $process.WaitForExit(3000)){
  $targets=@(Invoke-RestMethod "http://127.0.0.1:$($state.port)/json/list" -TimeoutSec 2)
  $process.Refresh()
  if($process.MainWindowHandle -ne 0 -or @($targets | Where-Object {$_.type -eq 'page'}).Count){throw 'The themed window did not close. Save any draft and close it manually; no visible window was force-terminated.'}
  # Owl may keep a windowless runtime alive after Browser.close.
  $residual=@(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" | Where-Object {$_.ExecutablePath -eq $expected -and $_.CommandLine -and $_.CommandLine.Contains($state.profile)})
  foreach($item in $residual){Stop-Process -Id $item.ProcessId -ErrorAction SilentlyContinue}
 }
}
$listener=Get-NetTCPConnection -LocalPort ([int]$state.port) -State Listen -ErrorAction SilentlyContinue
if($listener){throw 'A listener remains; verify the themed application is fully closed.'}
Write-Output 'Theme instance closed and debugging port released. Original Codex instance and configuration were not changed.'
