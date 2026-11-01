param([Parameter(Mandatory=$true)][string]$HandshakeDirectory,[Parameter(Mandatory=$true)][string]$VideoPath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
. (Join-Path $PSScriptRoot 'lib\launcher.ps1')
# A separate startup surface covers the native loading window until the theme is ready.
$window=New-Object Windows.Window
$window.Title='CC Moonlight startup'
$window.WindowStyle='None';$window.ResizeMode='NoResize';$window.Topmost=$true
$window.ShowInTaskbar=$false
$window.Left=[Windows.SystemParameters]::VirtualScreenLeft
$window.Top=[Windows.SystemParameters]::VirtualScreenTop
$window.Width=[Windows.SystemParameters]::VirtualScreenWidth
$window.Height=[Windows.SystemParameters]::VirtualScreenHeight
$window.Background=[Windows.Media.Brushes]::Black
$grid=New-Object Windows.Controls.Grid
$video=New-Object Windows.Controls.MediaElement
$video.LoadedBehavior='Manual';$video.UnloadedBehavior='Close';$video.Stretch='Uniform';$video.IsMuted=$true
$grid.Children.Add($video) | Out-Null
$label=New-Object Windows.Controls.TextBlock
$label.Text='月白龙语 · 正在准备工作台';$label.Foreground=[Windows.Media.Brushes]::White
$label.HorizontalAlignment='Center';$label.VerticalAlignment='Bottom';$label.Margin='24';$label.FontSize=14
$grid.Children.Add($label) | Out-Null
$skip=New-Object Windows.Controls.Button
$skip.Content='跳过动画';$skip.HorizontalAlignment='Right';$skip.VerticalAlignment='Bottom';$skip.Margin='24';$skip.Padding='16,8'
$grid.Children.Add($skip) | Out-Null
$window.Content=$grid
$script:videoDone=$false;$script:handoffAt=$null;$script:started=[DateTime]::UtcNow
function Complete-Video {[IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'video-done'),'done');$script:videoDone=$true;$skip.IsEnabled=$false;$label.Text='正在准备工作台…'}
$skip.Add_Click({Complete-Video})
$window.Add_KeyDown({if($_.Key -eq 'Escape'){Complete-Video}})
$video.Add_MediaOpened({[IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'video-opened'),'ready')})
$video.Add_MediaEnded({Complete-Video})
$video.Add_MediaFailed({$label.Text='正在准备工作台…';Complete-Video})
$window.Add_ContentRendered({
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'visible'),'ready')
 $video.Source=[Uri]::new($VideoPath);$video.Play()
})
$timer=New-Object Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromMilliseconds(100)
$timer.Add_Tick({
 try{
  $elapsed=([DateTime]::UtcNow-$script:started).TotalSeconds
  if($elapsed -gt 15 -and -not $script:videoDone){Complete-Video}
  $ready=Test-Path -LiteralPath (Join-Path $HandshakeDirectory 'theme-ready')
  $failed=Test-Path -LiteralPath (Join-Path $HandshakeDirectory 'failed')
  if(($ready -and $script:videoDone) -or $failed -or $elapsed -gt 65){
   if(-not $script:handoffAt){
    $launchPath=Join-Path $HandshakeDirectory 'launch.json'
    if(Test-Path -LiteralPath $launchPath){
     $launch=Get-Content -LiteralPath $launchPath -Raw | ConvertFrom-Json
     $process=Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$launch.pid)" -ErrorAction SilentlyContinue
     if($process -and $process.ExecutablePath -eq $launch.executable -and (Get-MoonlightArgument $process.CommandLine 'user-data-dir') -eq $launch.profile -and [Math]::Abs(($process.CreationDate.ToUniversalTime()-[DateTime]::Parse($launch.createdUtc).ToUniversalTime()).TotalSeconds) -lt 1){
      [void](Show-MoonlightWindow $process.ProcessId)
     }
    }
    $script:handoffAt=[DateTime]::UtcNow
    [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'result.json'),(@{themeReady=$ready;failed=$failed;timedOut=($elapsed -gt 65)} | ConvertTo-Json))
   }elseif(([DateTime]::UtcNow-$script:handoffAt).TotalMilliseconds -ge 350){$window.Close()}
  }
 }catch{
  [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'splash-error.txt'),$_.Exception.Message)
  $window.Close()
 }
})
$window.Add_Closed({$timer.Stop();$video.Close();[IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'closed'),'closed')})
$timer.Start()
$window.ShowDialog() | Out-Null
