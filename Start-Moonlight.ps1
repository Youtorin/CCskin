param([string]$StateDirectory=(Join-Path $env:LOCALAPPDATA 'CCMoonlight'),[switch]$NoIntro)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\launcher.ps1')
$mutex=[Threading.Mutex]::new($false,'Local\CCMoonlight-Launcher')
if(-not $mutex.WaitOne(0)){$mutex.Dispose();Write-Output 'Moonlight is already starting. Please wait for its window.';return}
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
 $profile=Join-Path $StateDirectory 'profile'
 New-Item -ItemType Directory -Force -Path $profile | Out-Null
 if((Get-Item -LiteralPath $profile).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Profile directory must not be a link.'}
 # Discover the live root independently of a potentially stale session PID.
 $roots=@(Find-MoonlightRoot @(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'") $exe $profile)
 if($roots.Count -gt 1){throw 'Multiple themed root processes found. Close extra theme instances manually.'}
 $reuse=$roots.Count -eq 1
 $port=19435
 if($reuse){
  $portText=Get-MoonlightArgument $roots[0].CommandLine 'remote-debugging-port'
  if($portText -notmatch '^\d+$' -or [int]$portText -lt 1024 -or [int]$portText -gt 65535){throw 'The existing themed process has no valid debugging port. Close its window before restarting.'}
  $port=[int]$portText
  $launched=Get-Process -Id $roots[0].ProcessId
 }else{
  while(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue){$port++;if($port -gt 19534){throw 'No free theme debugging port.'}}
 }
 $oldSession=$null
 if(Test-Path -LiteralPath $statePath){try{$oldSession=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json}catch{Write-Warning 'Rebuilding unreadable session state.'}}
 $introEnabled=$true
 $launchPreferences=Join-Path $StateDirectory 'launch-preferences.json'
 if(Test-Path -LiteralPath $launchPreferences){try{$prefs=Get-Content -LiteralPath $launchPreferences -Raw | ConvertFrom-Json;$introEnabled=($prefs.intro -ne $false -and $prefs.reducedMotion -ne $true)}catch{}}
 $handshake=$null
 if(-not $reuse -and -not $NoIntro -and $introEnabled){
  $handshake=Join-Path $StateDirectory ('startup-'+[Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $handshake | Out-Null
  $splashArgs=@('-NoProfile','-STA','-ExecutionPolicy','RemoteSigned','-File',('"'+(Join-Path $PSScriptRoot 'Splash-Moonlight.ps1')+'"'),'-HandshakeDirectory',('"'+$handshake+'"'),'-VideoPath',('"'+(Join-Path $PSScriptRoot 'assets\startup.mp4')+'"'))
  $splash=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $splashArgs -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $handshake 'stderr.log')
  $splashDeadline=[DateTime]::UtcNow.AddSeconds(8)
  while(-not (Test-Path -LiteralPath (Join-Path $handshake 'visible')) -and -not $splash.HasExited -and [DateTime]::UtcNow -lt $splashDeadline){Start-Sleep -Milliseconds 100}
  if(-not (Test-Path -LiteralPath (Join-Path $handshake 'visible'))){
   [IO.File]::WriteAllText((Join-Path $handshake 'failed'),'Splash did not become ready')
   throw "Startup video window failed to open. See $handshake. Run with -NoIntro to bypass it."
  }
 }
 $appArgs=@('--remote-debugging-address=127.0.0.1',"--remote-debugging-port=$port",('--user-data-dir="'+$profile+'"'),'--no-first-run')
 if(-not $reuse){$launched=Start-Process -FilePath $exe -ArgumentList $appArgs -WindowStyle Normal -PassThru}
 $state=[ordered]@{schema=1;version=$package.Version.ToString();executable=$exe;profile=$profile;port=$port;pid=$launched.Id;createdUtc=$launched.StartTime.ToUniversalTime().ToString('o');enginePath=(Join-Path $PSScriptRoot 'engine.cjs');node=$node;enginePid=$null;browserSocket=$null}
 if($handshake){$state | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $handshake 'launch.json') -Encoding utf8}
 try{
  $deadline=[DateTime]::UtcNow.AddSeconds(45)
  do{
   $listeners=@(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
   if($listeners.Count){
    foreach($listener in $listeners){
     if($listener.LocalAddress -ne '127.0.0.1' -or $listener.OwningProcess -ne $launched.Id){throw 'Debugging listener identity is not trusted.'}
    }
    $version=Invoke-RestMethod "http://127.0.0.1:$port/json/version" -TimeoutSec 2
    if($version.webSocketDebuggerUrl -match "^ws://127\.0\.0\.1:$port/devtools/browser/[\w-]+$"){$state.browserSocket=$version.webSocketDebuggerUrl;break}
   }
   Start-Sleep -Milliseconds 400
  }while([DateTime]::UtcNow -lt $deadline)
  if(-not $state.browserSocket){throw 'The application did not expose a verified debugging endpoint.'}
  $engineCommand='(?:^|\s)"?'+[regex]::Escape($state.enginePath)+'"?(?=\s|$)'
  $sessionCommand='(?:^|\s)--session\s+"?'+[regex]::Escape($statePath)+'"?(?=\s|$)'
  $engines=@(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object {$_.ExecutablePath -eq $node -and $_.CommandLine -match $engineCommand -and $_.CommandLine -match $sessionCommand -and $_.CommandLine -notmatch '(?:^|\s)--(?:restore|close|once)(?:\s|$)'})
  if($engines.Count -gt 1){throw 'Multiple theme engines found. No running instance was stopped.'}
  if($engines.Count -and (!$reuse -or !$oldSession -or $oldSession.browserSocket -ne $state.browserSocket)){
   # Only replace the verified theme engine; keep the native application and its drafts intact.
   Stop-Process -Id $engines[0].ProcessId -ErrorAction SilentlyContinue
   $engines=@()
  }
  if($engines.Count){
   $state.enginePid=$engines[0].ProcessId
   $state.engineCreatedUtc=$engines[0].CreationDate.ToUniversalTime().ToString('o')
  }
  $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
  if(-not $engines.Count){
   $engineArgs=@(('"'+$state.enginePath+'"'),'--session',('"'+$statePath+'"'))
   $engineArgs+='--no-intro'
   if($handshake){$engineArgs+=@('--ready-file',('"'+(Join-Path $handshake 'theme-ready')+'"'))}
   $engine=Start-Process -FilePath $node -ArgumentList $engineArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $StateDirectory 'engine.log') -RedirectStandardError (Join-Path $StateDirectory 'engine-error.log')
   $state.enginePid=$engine.Id;$state.engineCreatedUtc=$engine.StartTime.ToUniversalTime().ToString('o')
   $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
  }
  if($reuse){
   if(-not (Show-MoonlightWindow $launched.Id)){
    # Request a window through Chromium's existing profile singleton when only its background process remains.
    Start-Process -FilePath $exe -ArgumentList $appArgs -WindowStyle Normal | Out-Null
   }
   Write-Output 'Reused the running Moonlight instance and requested its window.'
  }else{Write-Output "Moonlight started. Session: $statePath"}
 }catch{
  if($handshake){[IO.File]::WriteAllText((Join-Path $handshake 'failed'),$_.Exception.Message)}
  if(-not $reuse){
   $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($launched.Id)" -ErrorAction SilentlyContinue
   if($p -and $p.ExecutablePath -eq $exe -and $p.CommandLine -and (Get-MoonlightArgument $p.CommandLine 'user-data-dir') -eq $profile -and [Math]::Abs(($p.CreationDate.ToUniversalTime()-$launched.StartTime.ToUniversalTime()).TotalSeconds) -lt 1){Stop-Process -Id $p.ProcessId -ErrorAction SilentlyContinue}
  }
  throw
 }
}catch{
 if($handshake){[IO.File]::WriteAllText((Join-Path $handshake 'failed'),$_.Exception.Message)}
 throw
}finally{$mutex.ReleaseMutex();$mutex.Dispose()}
