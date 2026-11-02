$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$handshake=Join-Path $repo ('work\splash-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $handshake -Force | Out-Null
$splashArgs=@('-NoProfile','-STA','-ExecutionPolicy','RemoteSigned','-File',('"'+(Join-Path $repo 'Splash-Moonlight.ps1')+'"'),'-HandshakeDirectory',('"'+$handshake+'"'),'-VideoPath',('"'+(Join-Path $repo 'assets\startup.mp4')+'"'))
$p=Start-Process powershell.exe -ArgumentList $splashArgs -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $handshake 'stderr.log')
if(-not $p.WaitForExit(25000)){throw "Splash did not exit: $handshake"}
if($null -ne $p.ExitCode -and $p.ExitCode -ne 0){throw (Get-Content -LiteralPath (Join-Path $handshake 'stderr.log') -Raw)}
$screens=Get-Content -LiteralPath (Join-Path $handshake 'screens.json') -Raw | ConvertFrom-Json
foreach($screen in $screens){foreach($key in @('Left','Top','Right','Bottom')){if($screen.expected.$key -ne $screen.actual.$key){throw "Monitor bounds mismatch ($key): $handshake"}}}
$result=Get-Content -LiteralPath (Join-Path $handshake 'result.json') -Raw | ConvertFrom-Json
if($result.reason -ne 'ended'){throw "Video did not end naturally: $handshake"}
$done=Get-Item -LiteralPath (Join-Path $handshake 'video-done');$closed=Get-Item -LiteralPath (Join-Path $handshake 'closed')
$delay=($closed.LastWriteTimeUtc-$done.LastWriteTimeUtc).TotalMilliseconds
if($delay -gt 500){throw "Post-video handoff took $delay ms"}
[pscustomobject]@{monitors=@($screens).Count;actualBoundsMatch=$true;videoEnded=$true;closeAfterVideoMs=$delay;elapsedMs=$result.elapsedMs} | ConvertTo-Json
