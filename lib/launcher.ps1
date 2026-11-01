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
function Show-MoonlightWindow([int]$ProcessId) {
 if(-not ('CCMoonlight.LauncherWindow' -as [type])){
  Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace CCMoonlight {
 public static class LauncherWindow {
  delegate bool Callback(IntPtr h, IntPtr arg);
  [DllImport("user32.dll")] static extern bool EnumWindows(Callback callback, IntPtr arg);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] static extern bool ShowWindowAsync(IntPtr h, int command);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  public static bool Show(int pid) {
   IntPtr found=IntPtr.Zero;
   EnumWindows((h,arg)=>{uint owner;GetWindowThreadProcessId(h,out owner);
    if(owner==(uint)pid && IsWindowVisible(h)){found=h;return false;}return true;},IntPtr.Zero);
   if(found==IntPtr.Zero)return false;
   if(IsIconic(found))ShowWindowAsync(found,9);
   SetForegroundWindow(found);
   return true;
  }
 }
}
"@
 }
 return [CCMoonlight.LauncherWindow]::Show($ProcessId)
}
