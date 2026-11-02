$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'lib\launcher.ps1')
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
$profile='C:\Users\Example User\CCMoonlight\profile'
$exe='C:\Official App\ChatGPT.exe'
$rootProcess=[pscustomobject]@{ProcessId=111;ExecutablePath=$exe;CommandLine=('"'+$exe+'" --user-data-dir="'+$profile+'" --remote-debugging-port=19435')}
$unrelated=[pscustomobject]@{ProcessId=222;ExecutablePath=$exe;CommandLine=('"'+$exe+'" --user-data-dir="'+$profile+'-other"')}
$child=[pscustomobject]@{ProcessId=333;ExecutablePath=$exe;CommandLine=($rootProcess.CommandLine+' --type=renderer')}
Assert ((@(Find-MoonlightRoot @($rootProcess,$unrelated,$child) $exe $profile)).Count -eq 1) 'Must exclude other profiles and child processes'
Assert ((Get-MoonlightArgument $rootProcess.CommandLine 'remote-debugging-port') -eq '19435') 'Port parsing'
Assert ((Get-MoonlightArgument '--user-data-dir C:\simple\profile --type gpu-process' 'user-data-dir') -eq 'C:\simple\profile') 'Unquoted argument parsing'
Assert ($null -eq (Get-MoonlightArgument '--fake-user-data-dir=x' 'user-data-dir')) 'Argument name boundary'
$script:nodePath=(Get-Command node.exe).Source
$testDir=Join-Path ([IO.Path]::GetTempPath()) ('cc-launcher-test-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
$script:fakeDate=[DateTime]::UtcNow
$script:running=$true;$script:enginePresent=$true;$script:windowFound=$true;$script:badListener=$false
$script:starts=@();$script:stops=@()
function Get-AppxPackage {[pscustomobject]@{InstallLocation='C:\Official App';SignatureKind='Store';Version=[version]'1.0.0'}}
function Get-CimInstance {
 param($ClassName,$Filter,$ErrorAction)
 if($Filter -eq "Name='ChatGPT.exe'"){
  if($script:running){[pscustomobject]@{ProcessId=111;ExecutablePath='C:\Official App\app\ChatGPT.exe';CommandLine=('app --user-data-dir="'+(Join-Path $testDir 'profile')+'" --remote-debugging-port=19435');CreationDate=$script:fakeDate}}
 }elseif($Filter -eq "Name='node.exe'" -and $script:enginePresent){
  [pscustomobject]@{ProcessId=444;ExecutablePath=$script:nodePath;CommandLine=('node "'+(Join-Path $root 'engine.cjs')+'" --session "'+(Join-Path $testDir 'session.json')+'" --no-intro');CreationDate=$script:fakeDate}
 }elseif($Filter -eq "Name='powershell.exe'" -and $script:watcherPresent){
  [pscustomobject]@{ProcessId=666;CommandLine=('powershell -File "'+(Join-Path $root 'Watch-Moonlight.ps1')+'" -SessionPath "'+(Join-Path $testDir 'session.json')+'" -RootPid 111')}
 }elseif($Filter -eq 'ProcessId=112' -and $script:adoptRoot){
  [pscustomobject]@{ProcessId=112;ExecutablePath='C:\Official App\app\ChatGPT.exe';CommandLine=('app --user-data-dir="'+(Join-Path $testDir 'profile')+'" --remote-debugging-port=19435');CreationDate=$script:fakeDate}
 }elseif($Filter -eq 'ProcessId=111' -and $script:running){
  [pscustomobject]@{ProcessId=111;ExecutablePath='C:\Official App\app\ChatGPT.exe';CommandLine=('app --user-data-dir="'+(Join-Path $testDir 'profile')+'" --remote-debugging-port=19435');CreationDate=$script:fakeDate}
 }
}
function Get-Process {param($Id,$ErrorAction) if($Id -ne 113){[pscustomobject]@{Id=$Id;StartTime=$script:fakeDate}}}
function Get-NetTCPConnection {param($LocalPort,$State,$ErrorAction) if($script:running){[pscustomobject]@{LocalAddress='127.0.0.1';OwningProcess=$(if($script:badListener){999}elseif($script:adoptRoot){112}else{111})}}}
function Invoke-RestMethod {param($Uri,$TimeoutSec)
 if($script:httpFailures -gt 0){$script:httpFailures--;throw 'The endpoint is still starting'}
 [pscustomobject]@{webSocketDebuggerUrl='ws://127.0.0.1:19435/devtools/browser/test'}
}
function Start-Process {param($FilePath,$ArgumentList,$WindowStyle,[switch]$PassThru,$RedirectStandardOutput,$RedirectStandardError)
 $script:starts+=,[pscustomobject]@{File=$FilePath;Arguments=$ArgumentList;Style=$WindowStyle}
 if($script:earlyExit -and $FilePath -like '*ChatGPT.exe'){$script:earlyExit=$false;$script:running=$false;return [pscustomobject]@{Id=113;StartTime=$script:fakeDate}}
 if($FilePath -like '*ChatGPT.exe' -and (-not $script:running -or $script:wakeSucceeds)){$script:windowFound=$true}
 if($FilePath -eq $script:nodePath){[pscustomobject]@{Id=555;StartTime=$script:fakeDate}}else{$script:running=$true;[pscustomobject]@{Id=111;StartTime=$script:fakeDate}}
}
function Stop-Process {param($Id,$ErrorAction) $script:stops+= $Id}
function Show-MoonlightWindow {param($ProcessId) $script:windowFound}
function Test-MoonlightWindow {param($ProcessId) $script:windowFound}
function Stop-MoonlightTree {param($Tree) $script:stops+=@($Tree | ForEach-Object {$_.ProcessId});$script:running=$false}
# Execute the production launcher with mocked OS boundaries; no application windows are touched.
$text=[IO.File]::ReadAllText((Join-Path $root 'Start-Moonlight.ps1'))
$text=$text.Replace(". (Join-Path `$PSScriptRoot 'lib\launcher.ps1')",'')
$text=$text.Replace('$PSScriptRoot',("'"+$root.Replace("'","''")+"'"))
$launcher=[scriptblock]::Create($text)
function Reset-State {
 @{pid=999;browserSocket='ws://127.0.0.1:19435/devtools/browser/test'} | ConvertTo-Json | Set-Content (Join-Path $testDir 'session.json')
 $script:starts=@();$script:stops=@()
 $script:watcherPresent=$true;$script:adoptRoot=$false;$script:httpFailures=0;$script:earlyExit=$false;$script:wakeSucceeds=$true
}
try{
 Reset-State
 & $launcher -StateDirectory $testDir -NoIntro
 $state=Get-Content (Join-Path $testDir 'session.json') -Raw | ConvertFrom-Json
 Assert ($state.pid -eq 111 -and $state.enginePid -eq 444) 'Repair stale session PID and retain existing engine'
 Assert ($script:starts.Count -eq 0 -and $script:stops.Count -eq 0) 'Repeated launch must not restart application or engine'
 Reset-State;$script:windowFound=$false
 & $launcher -StateDirectory $testDir -NoIntro
 Assert ($script:starts.Count -eq 1 -and $script:starts[0].Arguments -contains ('--user-data-dir="'+(Join-Path $testDir 'profile')+'"')) 'Windowless instance must request the same profile singleton'
 Reset-State;$script:windowFound=$true;$script:enginePresent=$false
 & $launcher -StateDirectory $testDir -NoIntro
 Assert ($script:starts.Count -eq 1 -and $script:starts[0].Style -eq 'Hidden' -and $script:starts[0].Arguments -contains '--no-intro') 'Recover missing engine without another application'
 Reset-State;$script:badListener=$true
 $caught=$false;try{& $launcher -StateDirectory $testDir -NoIntro}catch{$caught=$_.Exception.Message -like '*listener identity*'}
 Assert ($caught -and $script:stops.Count -eq 0) 'Reject unrelated listener without closing existing application'
 Reset-State;$script:badListener=$false;$script:running=$false
 & $launcher -StateDirectory $testDir -NoIntro
 Assert ($script:starts.Count -eq 2) 'Fresh launch must start app and engine'
 Reset-State;$script:running=$true;$script:enginePresent=$true;$script:httpFailures=2
 & $launcher -StateDirectory $testDir -NoIntro
 Assert ($script:httpFailures -eq 0 -and $script:stops.Count -eq 0) 'Retry transient endpoint errors without terminating the application'
 Reset-State;$script:adoptRoot=$true
 & $launcher -StateDirectory $testDir -NoIntro
 $state=Get-Content (Join-Path $testDir 'session.json') -Raw | ConvertFrom-Json
 Assert ($state.pid -eq 112 -and $script:stops.Count -eq 0) 'Adopt the verified singleton root rather than the short-lived launcher PID'
 Reset-State;$script:watcherPresent=$false
 & $launcher -StateDirectory $testDir -NoIntro
 Assert (@($script:starts | Where-Object {$_.Arguments -contains ('"'+(Join-Path $root 'Watch-Moonlight.ps1')+'"') -and $_.Style -eq 'Hidden'}).Count -eq 1) 'Start one hidden lifecycle watcher'
 Reset-State;$script:running=$false;$script:enginePresent=$false;$script:earlyExit=$true
 & $launcher -StateDirectory $testDir -NoIntro
 Assert (@($script:starts | Where-Object {$_.File -like '*ChatGPT.exe'}).Count -eq 2) 'Retry a short-lived first launch within the same shortcut invocation'
 Reset-State;$script:running=$true;$script:windowFound=$false;$script:wakeSucceeds=$false;$script:enginePresent=$false
 & $launcher -StateDirectory $testDir -NoIntro
 Assert ($script:stops -contains 111 -and @($script:starts | Where-Object {$_.File -like '*ChatGPT.exe'}).Count -eq 2 -and $script:windowFound) 'A live endpoint without a reopened window must recover within the same launch'
 Write-Output 'Launcher regression checks passed (mock OS boundaries).'
}finally{
 # Only this test-owned, resolved temporary directory is removed.
 $resolved=[IO.Path]::GetFullPath($testDir)
 $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
 if($resolved.StartsWith($tempRoot) -and (Split-Path $resolved -Leaf) -like 'cc-launcher-test-*'){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
