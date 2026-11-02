using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
namespace CCMoonlight {
 public static class Native {
  delegate bool WindowCallback(IntPtr h, IntPtr arg);
  delegate bool MonitorCallback(IntPtr monitor, IntPtr dc, ref Rect rect, IntPtr arg);
  [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] static extern bool EnumWindows(WindowCallback callback, IntPtr arg);
  [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr dc, IntPtr clip, MonitorCallback callback, IntPtr arg);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] static extern bool ShowWindowAsync(IntPtr h, int command);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int height, uint flags);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out Rect rect);
  [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
  static IntPtr Window(int pid) {
   IntPtr found=IntPtr.Zero;
   EnumWindows((h,arg)=>{uint owner;GetWindowThreadProcessId(h,out owner);
    if(owner==(uint)pid && IsWindowVisible(h)){found=h;return false;}return true;},IntPtr.Zero);
   return found;
  }
  public static bool HasWindow(int pid) { return Window(pid)!=IntPtr.Zero; }
  public static bool Show(int pid) {
   IntPtr h=Window(pid);if(h==IntPtr.Zero)return false;
   if(IsIconic(h))ShowWindowAsync(h,9);
   SetForegroundWindow(h);return true;
  }
  public static Rect[] Screens() {
   var screens=new List<Rect>();
   EnumDisplayMonitors(IntPtr.Zero,IntPtr.Zero,(IntPtr h,IntPtr dc,ref Rect r,IntPtr arg)=>{screens.Add(r);return true;},IntPtr.Zero);
   return screens.ToArray();
  }
  public static void Place(IntPtr h, Rect r) { SetWindowPos(h,new IntPtr(-1),r.Left,r.Top,r.Right-r.Left,r.Bottom-r.Top,0x0010); }
  public static Rect Bounds(IntPtr h) { Rect r;GetWindowRect(h,out r);return r; }
  public static bool EscapePressed() { return (GetAsyncKeyState(0x1B)&0x8000)!=0; }
 }
}
