param([switch]$Repair)
$ErrorActionPreference='Stop'
$source=[IO.Path]::GetFullPath($PSScriptRoot)
$target=Join-Path $env:LOCALAPPDATA 'CCMoonlight\app'
if((Test-Path -LiteralPath $target) -and -not $Repair){throw 'Installation already exists. Use Install-Moonlight.ps1 -Repair to restore installation files.'}
$stateRoot=Split-Path $target -Parent
foreach($dir in @($target,$stateRoot)){
 if((Test-Path -LiteralPath $dir) -and ((Get-Item -LiteralPath $dir).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Installation directories must not be links.'}
}
if($source -eq [IO.Path]::GetFullPath($target)){throw 'Run the installer from the downloaded source directory, not the installed copy.'}
$desktop=[Environment]::GetFolderPath('Desktop')
$shell=New-Object -ComObject WScript.Shell
foreach($name in @('CC 月白龙语.lnk','CC 月白龙语 - 恢复.lnk')){
 $shortcut=Join-Path $desktop $name
 if(Test-Path -LiteralPath $shortcut){
  if(-not $Repair){throw 'A matching shortcut already exists. Use -Repair to repair this installation.'}
  $existing=$shell.CreateShortcut($shortcut)
  $entry=if($name -eq 'CC 月白龙语.lnk'){'Start'}else{'Restore'}
  $oldTarget=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $oldArgs='-NoProfile -ExecutionPolicy RemoteSigned -File "'+(Join-Path $target ($entry+'-Moonlight.ps1'))+'"'
  $newArgs='/d /c ""'+(Join-Path $target ($entry+'.cmd'))+'""'
  if(-not (($existing.TargetPath -eq $oldTarget -and $existing.Arguments -eq $oldArgs) -or ($existing.TargetPath -eq $env:ComSpec -and $existing.Arguments -eq $newArgs))){throw 'An unrelated shortcut has the same name; it was not overwritten.'}
 }
}
$null=Get-Command node.exe -ErrorAction Stop
$profile=Join-Path $stateRoot 'profile'
$running=@(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" | Where-Object {$_.CommandLine -and $_.CommandLine.Contains($profile)})
if($running.Count){throw 'Close the themed instance before repairing installation files.'}
$payload=@('assets','lib','runtime','demo','docs','scripts','tests','engine.cjs','manifest.json','README.md','THIRD-PARTY.md','VALIDATION.json','SHA256SUMS.txt','Start.cmd','Restore.cmd','Install.cmd','Repair.cmd','Update.cmd','Start-Moonlight.ps1','Splash-Moonlight.ps1','Watch-Moonlight.ps1','Restore-Moonlight.ps1','Install-Moonlight.ps1','Install-Pet.ps1')
foreach($file in $payload){if(-not(Test-Path -LiteralPath (Join-Path $source $file))){throw "Missing installation file: $file"}}
New-Item -ItemType Directory -Force -Path $target | Out-Null
foreach($file in $payload){Copy-Item -LiteralPath (Join-Path $source $file) -Destination $target -Recurse -Force}
foreach($file in @('.gitignore','.gitattributes')){Copy-Item -LiteralPath (Join-Path $source $file) -Destination $target -Force}
foreach($entry in @(@('CC 月白龙语','Start.cmd'),@('CC 月白龙语 - 恢复','Restore.cmd'))){
 $link=$shell.CreateShortcut((Join-Path $desktop ($entry[0]+'.lnk')))
 $link.TargetPath=$env:ComSpec
 $link.Arguments='/d /c ""'+(Join-Path $target $entry[1])+'""'
 $link.WorkingDirectory=$target;$link.WindowStyle=1;$link.Description='CC Moonlight theme extension';$link.Save()
}
Write-Output "Installed: $target"
