param([string]$StateDirectory=(Join-Path $env:LOCALAPPDATA 'CCMoonlight'),[switch]$NoIntro)
$ErrorActionPreference='Stop'
$mutex=[Threading.Mutex]::new($false,'Local\CCMoonlight-Launcher')
if(-not $mutex.WaitOne(0)){throw 'Moonlight launcher is already running.'}
try{
 $node=(Get-Command node.exe -ErrorAction Stop).Source
 $nodeMajor=[int]((& $node -p 'process.versions.node.split(String.fromCharCode(46))[0]') | Select-Object -Last 1)
 if($nodeMajor -lt 22){throw 'Node.js 22 or newer is required.'}
 $package=Get-AppxPackage -Name OpenAI.Codex
 if(@($package).Count -ne 1 -or $package.SignatureKind -ne 'Store'){throw 'A registered official Codex Store package is required.'}
 $exe=Join-Path $package.InstallLocation 'app\ChatGPT.exe'
 New-Item -ItemType Directory -Force -Path $StateDirectory | Out-Null
 $StateDirectory=[IO.Path]::GetFullPath($StateDirectory)
 if((Get-Item -LiteralPath $StateDirectory).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'State directory must not be a link.'}
 $statePath=Join-Path $StateDirectory 'session.json'
 if(Test-Path -LiteralPath $statePath){
  $old=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
  $oldProcess=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$old.pid)" -ErrorAction SilentlyContinue
  if($oldProcess -and $oldProcess.ExecutablePath -eq $old.executable -and $oldProcess.CommandLine.Contains($old.profile)){
   throw 'The themed instance is already running. Use its existing window, or Restore-Moonlight.ps1 before restarting.'
  }
 }
 $profile=Join-Path $StateDirectory 'profile'
 New-Item -ItemType Directory -Force -Path $profile | Out-Null
 if((Get-Item -LiteralPath $profile).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Profile directory must not be a link.'}
 $port=19435
 while(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue){$port++;if($port -gt 19534){throw 'No free theme debugging port.'}}
 $appArgs=@('--remote-debugging-address=127.0.0.1',"--remote-debugging-port=$port",('--user-data-dir="'+$profile+'"'),'--no-first-run')
 $launched=Start-Process -FilePath $exe -ArgumentList $appArgs -WindowStyle Normal -PassThru
 $state=[ordered]@{schema=1;version=$package.Version.ToString();executable=$exe;profile=$profile;port=$port;pid=$launched.Id;createdUtc=$launched.StartTime.ToUniversalTime().ToString('o');enginePath=(Join-Path $PSScriptRoot 'engine.cjs');node=$node;enginePid=$null;browserSocket=$null}
 try{
  $deadline=[DateTime]::UtcNow.AddSeconds(45)
  do{
   $listeners=@(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
   if($listeners.Count){
    foreach($listener in $listeners){
     $owner=Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)"
     if($listener.LocalAddress -ne '127.0.0.1' -or $owner.ExecutablePath -ne $exe -or -not $owner.CommandLine.Contains($profile)){throw 'Debugging listener identity is not trusted.'}
    }
    $version=Invoke-RestMethod "http://127.0.0.1:$port/json/version" -TimeoutSec 2
    if($version.webSocketDebuggerUrl -match "^ws://127\.0\.0\.1:$port/devtools/browser/[\w-]+$"){$state.browserSocket=$version.webSocketDebuggerUrl;break}
   }
   Start-Sleep -Milliseconds 400
  }while([DateTime]::UtcNow -lt $deadline)
  if(-not $state.browserSocket){throw 'The application did not expose a verified debugging endpoint.'}
  $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
  $engineArgs=@(('"'+$state.enginePath+'"'),'--session',('"'+$statePath+'"'))
  if($NoIntro){$engineArgs+='--no-intro'}
  $engine=Start-Process -FilePath $node -ArgumentList $engineArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $StateDirectory 'engine.log') -RedirectStandardError (Join-Path $StateDirectory 'engine-error.log')
  $state.enginePid=$engine.Id;$state.engineCreatedUtc=$engine.StartTime.ToUniversalTime().ToString('o')
  $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
  Write-Output "Moonlight started. Session: $statePath"
 }catch{
  $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($launched.Id)" -ErrorAction SilentlyContinue
  if($p -and $p.ExecutablePath -eq $exe -and $p.CommandLine.Contains($profile)){Stop-Process -Id $p.ProcessId -ErrorAction SilentlyContinue}
  throw
 }
}finally{$mutex.ReleaseMutex();$mutex.Dispose()}
