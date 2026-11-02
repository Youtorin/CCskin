param([Parameter(Mandatory=$true)][string]$SessionPath,[Parameter(Mandatory=$true)][int]$RootPid)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\launcher.ps1')
$state=Get-Content -LiteralPath $SessionPath -Raw | ConvertFrom-Json
if($state.pid -ne $RootPid){return}
$initialProcesses=@(Get-CimInstance Win32_Process)
$root=$initialProcesses | Where-Object {$_.ProcessId -eq $RootPid} | Select-Object -First 1
if(-not $root -or $root.ExecutablePath -ne $state.executable -or (Get-MoonlightArgument $root.CommandLine 'user-data-dir') -ne $state.profile -or
 [Math]::Abs(($root.CreationDate.ToUniversalTime()-([DateTime]$state.createdUtc).ToUniversalTime()).TotalSeconds) -gt 1){return}
$known=@{};$seenWindow=$false;$emptySince=$null;$startupDeadline=[DateTime]::UtcNow.AddSeconds(60)
foreach($p in @(Get-MoonlightTree $initialProcesses $root)){$known[[int]$p.ProcessId]=$p}
Initialize-MoonlightNative
$mutex=[Threading.Mutex]::new($false,'Local\CCMoonlight-Launcher')
try{
 while($true){
  $current=Get-Content -LiteralPath $SessionPath -Raw | ConvertFrom-Json
  if($current.pid -ne $RootPid -or $current.createdUtc -ne $state.createdUtc){return}
  $processes=@(Get-CimInstance Win32_Process)
  $live=$processes | Where-Object {$_.ProcessId -eq $RootPid} | Select-Object -First 1
  $same=Test-MoonlightIdentity $live $root
  if($same){foreach($p in @(Get-MoonlightTree $processes $root)){$known[[int]$p.ProcessId]=$p}}
  $visible=$same -and (Test-MoonlightWindow $RootPid)
  if($visible){$seenWindow=$true;$emptySince=$null}
  elseif($seenWindow -and -not $emptySince){$emptySince=[DateTime]::UtcNow}
  # Minimized windows are still visible to EnumWindows. Only a closed UI starts this grace period.
  if(-not $same -or ($emptySince -and ([DateTime]::UtcNow-$emptySince).TotalSeconds -ge 3) -or (-not $seenWindow -and [DateTime]::UtcNow -gt $startupDeadline)){
   $locked=$false
   try{$locked=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$locked=$true}
   if($locked){
    try{
     $current=Get-Content -LiteralPath $SessionPath -Raw | ConvertFrom-Json
     if($current.pid -ne $RootPid -or $current.createdUtc -ne $state.createdUtc){return}
     if($same -and (Test-MoonlightWindow $RootPid)){$emptySince=$null;continue}
     if($same){try{& $current.node $current.enginePath --session $SessionPath --close | Out-Null}catch{};Start-Sleep -Milliseconds 500}
     if(Test-MoonlightWindow $RootPid){$emptySince=$null;continue}
     # Cached descendants allow cleanup even when the parent exits before its children.
     Stop-MoonlightTree @($known.Values)
     if($current.enginePid){
      $engine=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$current.enginePid)" -ErrorAction SilentlyContinue
      if($engine -and $engine.ExecutablePath -eq $current.node -and $engine.CommandLine.Contains(('"'+$current.enginePath+'"')) -and
       $engine.CommandLine.Contains(('"'+$SessionPath+'"')) -and $current.engineCreatedUtc -and
       [Math]::Abs(($engine.CreationDate.ToUniversalTime()-([DateTime]$current.engineCreatedUtc).ToUniversalTime()).TotalSeconds) -lt 1){Stop-Process -Id $engine.ProcessId -ErrorAction SilentlyContinue}
     }
     [IO.File]::AppendAllText((Join-Path (Split-Path $SessionPath) 'lifecycle.log'),([DateTime]::UtcNow.ToString('o')+" closed root $RootPid and verified descendants`r`n"))
     return
    }finally{$mutex.ReleaseMutex()}
   }
  }
  Start-Sleep -Seconds 1
 }
}finally{$mutex.Dispose()}
