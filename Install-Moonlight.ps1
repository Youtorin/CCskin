$ErrorActionPreference='Stop'
$source=[IO.Path]::GetFullPath($PSScriptRoot)
$target=Join-Path $env:LOCALAPPDATA 'CCMoonlight\app'
if(Test-Path -LiteralPath $target){throw 'Installation already exists. Close the themed instance and back up the existing app directory before updating.'}
$desktop=[Environment]::GetFolderPath('Desktop')
foreach($name in @('CC 月白龙语.lnk','CC 月白龙语 - 恢复.lnk')){if(Test-Path -LiteralPath (Join-Path $desktop $name)){throw 'A matching desktop shortcut already exists; it was not overwritten.'}}
$null=Get-Command node.exe -ErrorAction Stop
New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse
$shell=New-Object -ComObject WScript.Shell
foreach($entry in @(@('CC 月白龙语','Start-Moonlight.ps1'),@('CC 月白龙语 - 恢复','Restore-Moonlight.ps1'))){
 $link=$shell.CreateShortcut((Join-Path $desktop ($entry[0]+'.lnk')))
 $link.TargetPath=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $link.Arguments='-NoProfile -ExecutionPolicy RemoteSigned -File "'+(Join-Path $target $entry[1])+'"'
 $link.WorkingDirectory=$target;$link.WindowStyle=7;$link.Description='CC Moonlight theme extension';$link.Save()
}
Write-Output "Installed: $target"
