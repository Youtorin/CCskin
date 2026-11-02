param([Parameter(Mandatory=$true)][string]$HandshakeDirectory,[Parameter(Mandatory=$true)][string]$VideoPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'lib\launcher.ps1')
Initialize-MoonlightNative
# Native monitor rectangles and SetWindowPos use physical pixels, including negative origins.
$null=[CCMoonlight.Native]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$app=New-Object Windows.Application
$app.ShutdownMode='OnExplicitShutdown'
$script:windows=@();$script:finished=$false
$clock=[Diagnostics.Stopwatch]::StartNew()
$player=New-Object Windows.Media.MediaPlayer
$player.IsMuted=$true
# One decoder and playback clock, rendered in full on every monitor.
$drawing=New-Object Windows.Media.VideoDrawing
$drawing.Player=$player;$drawing.Rect=New-Object Windows.Rect(0,0,2560,1440)
$brush=New-Object Windows.Media.DrawingBrush($drawing)
$brush.Stretch='Uniform'
function Close-Intro([string]$Reason) {
 if($script:finished){return};$script:finished=$true
 $timer.Stop()
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'video-done'),$Reason)
 $ready=Test-Path -LiteralPath (Join-Path $HandshakeDirectory 'theme-ready')
 # Never freeze on the last frame while waiting for the client.
 foreach($w in $script:windows){$w.Hide()}
 $player.Close()
 $launchPath=Join-Path $HandshakeDirectory 'launch.json'
 if(Test-Path -LiteralPath $launchPath){
  try{
   $launch=Get-Content -LiteralPath $launchPath -Raw | ConvertFrom-Json
   $p=Get-Process -Id ([int]$launch.pid) -ErrorAction SilentlyContinue
   if($p -and [Math]::Abs(($p.StartTime.ToUniversalTime()-([DateTime]$launch.createdUtc).ToUniversalTime()).TotalSeconds) -lt 1){[void](Show-MoonlightWindow $p.Id)}
  }catch{}
 }
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'result.json'),(@{themeReady=$ready;reason=$Reason;elapsedMs=$clock.ElapsedMilliseconds;monitors=$script:windows.Count} | ConvertTo-Json))
 foreach($w in $script:windows){$w.Close()}
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'closed'),'closed')
 $app.Shutdown()
}
foreach($screen in [CCMoonlight.Native]::Screens()){
 $window=New-Object Windows.Window
 $window.Title='CC Moonlight startup';$window.WindowStyle='None';$window.ResizeMode='NoResize'
 $window.Topmost=$true;$window.ShowInTaskbar=$false;$window.ShowActivated=$false
 $window.Background=[Windows.Media.Brushes]::Black
 $window.Tag=$screen
 $window.Add_SourceInitialized({param($sender,$eventArgs)
  $handle=[Windows.Interop.WindowInteropHelper]::new($sender).Handle
  [CCMoonlight.Native]::Place($handle,$sender.Tag)
 })
 $grid=New-Object Windows.Controls.Grid
 $surface=New-Object Windows.Shapes.Rectangle;$surface.Fill=$brush
 $null=$grid.Children.Add($surface)
 $skip=New-Object Windows.Controls.Button
 $skip.Content='跳过动画';$skip.HorizontalAlignment='Right';$skip.VerticalAlignment='Bottom';$skip.Margin='24';$skip.Padding='16,8'
 $skip.Add_Click({Close-Intro 'skipped'});$null=$grid.Children.Add($skip)
 $window.Content=$grid
 $window.Add_KeyDown({if($_.Key -eq 'Escape'){Close-Intro 'skipped'}})
 $window.Add_Closed({if(-not $script:finished){Close-Intro 'dismissed'}})
 $script:windows+=$window
}
$player.Add_MediaOpened({
 $drawing.Rect=New-Object Windows.Rect(0,0,$player.NaturalVideoWidth,$player.NaturalVideoHeight)
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'video-opened'),'ready')
 $player.Play()
})
$player.Add_MediaEnded({Close-Intro 'ended'})
$player.Add_MediaFailed({Close-Intro 'media-failed'})
$timer=New-Object Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromMilliseconds(50)
$timer.Add_Tick({
 try{
  if([CCMoonlight.Native]::EscapePressed()){Close-Intro 'skipped'}
  elseif(Test-Path -LiteralPath (Join-Path $HandshakeDirectory 'failed')){Close-Intro 'launch-failed'}
  elseif($clock.Elapsed.TotalSeconds -gt 15){Close-Intro 'media-timeout'}
 }catch{
  [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'splash-error.txt'),$_.Exception.Message)
  Close-Intro 'error'
 }
})
try{
 foreach($w in $script:windows){$w.Show()}
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'screens.json'),(ConvertTo-Json -Depth 4 -InputObject @($script:windows | ForEach-Object {@{expected=$_.Tag;actual=[CCMoonlight.Native]::Bounds([Windows.Interop.WindowInteropHelper]::new($_).Handle)}})))
 [IO.File]::WriteAllText((Join-Path $HandshakeDirectory 'visible'),'ready')
 $timer.Start();$player.Open([Uri]::new($VideoPath));$null=$app.Run()
}finally{if(-not $script:finished){Close-Intro 'shutdown'}}
