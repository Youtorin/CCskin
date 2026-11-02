$ErrorActionPreference='Stop'
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\launcher.ps1')
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
$date=[DateTime]::UtcNow
function Proc($Id,$Parent,$Offset,$Path){[pscustomobject]@{ProcessId=$Id;ParentProcessId=$Parent;CreationDate=$date.AddSeconds($Offset);ExecutablePath=$Path}}
$root=Proc 10 1 0 'official.exe'
$child=Proc 11 10 1 'official.exe'
$helper=Proc 12 11 2 'helper.exe'
$unrelated=Proc 20 1 0 'official.exe'
$oldPidChild=Proc 30 10 -5 'other.exe'
$tree=@(Get-MoonlightTree @($root,$child,$helper,$unrelated,$oldPidChild) $root)
Assert ($tree.Count -eq 3) 'Track descendants without a profile argument; exclude unrelated processes and stale parent PIDs'
$script:live=@($root,(Proc 11 1 10 'official.exe'),$helper,$unrelated)
$script:stops=@()
function Get-Process {param($Id,$ErrorAction)
 $p=$script:live | Where-Object {$_.ProcessId -eq $Id}
 if($p){$result=[pscustomobject]@{Id=$p.ProcessId;Path=$p.ExecutablePath;StartTime=$p.CreationDate;Handle=1};$result | Add-Member ScriptMethod Dispose {};$result | Add-Member ScriptMethod WaitForExit {$true};return $result}
}
function Stop-Process {param($InputObject,$ErrorAction) $script:stops+=$InputObject.Id}
Stop-MoonlightTree $tree
Assert ($script:stops.Count -eq 2 -and $script:stops -contains 10 -and $script:stops -contains 12) 'Revalidate process creation time before stopping; never terminate reused PIDs'
Write-Output 'Lifecycle ancestry and PID-reuse checks passed.'
