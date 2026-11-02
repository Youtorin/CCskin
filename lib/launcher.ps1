function Get-MoonlightArgument([string]$CommandLine,[string]$Name) {
 $pattern='(?:^|\s)--'+[regex]::Escape($Name)+'(?:=|\s+)(?:"([^"]*)"|([^\s"]+))(?=\s|$)'
 $match=[regex]::Match($CommandLine,$pattern,[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($match.Success){if($match.Groups[1].Success){return $match.Groups[1].Value};return $match.Groups[2].Value}
 return $null
}
function Find-MoonlightRoot($Processes,[string]$Executable,[string]$Profile) {
 @($Processes | Where-Object {
  $_.ExecutablePath -eq $Executable -and $_.CommandLine -and
  (Get-MoonlightArgument $_.CommandLine 'user-data-dir') -eq $Profile -and
  $_.CommandLine -notmatch '(?:^|\s)--type(?:=|\s)'
 })
}
function Initialize-MoonlightNative {
 if(-not ('CCMoonlight.Native' -as [type])){Add-Type -Path (Join-Path $PSScriptRoot 'native.cs')}
}
function Show-MoonlightWindow([int]$ProcessId) {Initialize-MoonlightNative;return [CCMoonlight.Native]::Show($ProcessId)}
function Test-MoonlightWindow([int]$ProcessId) {Initialize-MoonlightNative;return [CCMoonlight.Native]::HasWindow($ProcessId)}
function Write-MoonlightState($State,[string]$Path) {
 $temp=$Path+'.'+[Guid]::NewGuid().ToString('N')+'.tmp'
 try{$State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $temp -Encoding utf8;Move-Item -LiteralPath $temp -Destination $Path -Force}
 finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
}
function Test-MoonlightIdentity($Process,$Expected) {
 return ($Process -and $Process.ProcessId -eq $Expected.ProcessId -and $Process.ExecutablePath -eq $Expected.ExecutablePath -and
  [Math]::Abs(($Process.CreationDate.ToUniversalTime()-$Expected.CreationDate.ToUniversalTime()).TotalMilliseconds) -lt 1)
}
function Get-MoonlightTree($Processes,$Root) {
 # Follow parent links only across matching lifetimes; a reused PID is not a child.
 $found=@{};$found[[int]$Root.ProcessId]=$Root
 do{
  $added=$false
  foreach($p in $Processes){
   if(-not $found.ContainsKey([int]$p.ProcessId) -and $found.ContainsKey([int]$p.ParentProcessId) -and $p.CreationDate -ge $found[[int]$p.ParentProcessId].CreationDate){$found[[int]$p.ProcessId]=$p;$added=$true}
  }
 }while($added)
 return @($found.Values)
}
function Stop-MoonlightTree($Tree) {
 foreach($expected in @($Tree | Sort-Object CreationDate -Descending)){
  $actual=Get-Process -Id ([int]$expected.ProcessId) -ErrorAction SilentlyContinue
  if($actual){
   try{
    # Hold the native handle while rechecking lifetime; avoid one slow WMI query per child.
    $null=$actual.Handle
    if($expected.ExecutablePath -and $actual.Path -eq $expected.ExecutablePath -and [Math]::Abs(($actual.StartTime.ToUniversalTime()-$expected.CreationDate.ToUniversalTime()).TotalMilliseconds) -lt 1){Stop-Process -InputObject $actual -ErrorAction SilentlyContinue;$null=$actual.WaitForExit(1500)}
   }catch [InvalidOperationException]{}catch [ComponentModel.Win32Exception]{}finally{$actual.Dispose()}
  }
 }
}
