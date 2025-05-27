GetMonitorFromPoint(x, y) {
    VarSetCapacity(pt, 8, 0)
    NumPut(x, pt, 0, "Int")
    NumPut(y, pt, 4, "Int")
    MONITOR_DEFAULTTONEAREST := 2

    hMonitor := DllCall("User32.dll\MonitorFromPoint", "Int64", NumGet(pt, 0, "Int64"), "UInt", MONITOR_DEFAULTTONEAREST, "Ptr")
    if (!hMonitor)
        return 1

    SysGet, monitorCount, MonitorCount
    Loop, %monitorCount% {
        SysGet, hMonTemp, Monitor, %A_Index%
        if (hMonTemp = hMonitor)
            return A_Index
    }
    return 1
}

WinGet, id, List,,, Program Manager
WinGet, active_id, ID, A

if (!active_id || active_id = 0) {
    WinGet, last_active_id, ID, LastFound
    if (last_active_id && last_active_id != 0) {
        active_id := last_active_id
    } else {
        active_id := ""
    }
}

monitorLeft := monitorTop := monitorRight := monitorBottom := 0

if (active_id != "") {
    WinGetPos, ax, ay, aw, ah, ahk_id %active_id%

    if (aw = 0 && ah = 0) {
        monIndex := 1
    } else {
        monIndex := GetMonitorFromPoint(ax, ay)
    }

    SysGet, monitorLeft, MonitorWorkArea, %monIndex%, 0
    SysGet, monitorTop, MonitorWorkArea, %monIndex%, 1
    SysGet, monitorRight, MonitorWorkArea, %monIndex%, 2
    SysGet, monitorBottom, MonitorWorkArea, %monIndex%, 3
}

validWindows := []

Loop, %id% {
    this_id := id%A_Index%
    WinGet, Style, Style, ahk_id %this_id%
    WinGet, ExStyle, ExStyle, ahk_id %this_id%
    WinGetPos, x, y, w, h, ahk_id %this_id%

    if ((Style & 0x10000000) && !(ExStyle & 0x08000000)) {
        if (monitorLeft = 0 && monitorRight = 0) {
            validWindows.Push(this_id)
        } else {
            if ((w = 0 && h = 0) || (x >= monitorLeft && x < monitorRight && y >= monitorTop && y < monitorBottom)) {
                validWindows.Push(this_id)
            }
        }
    }
}

if (validWindows.Length() <= 1) {
    if (active_id)
        WinMinimize, ahk_id %active_id%
    return
}

activeIndex := 0
Loop % validWindows.Length() {
    if (validWindows[A_Index] = active_id) {
        activeIndex := A_Index
        break
    }
}

nextIndex := activeIndex + 1
if (nextIndex > validWindows.Length())
    nextIndex := 1

next_id := validWindows[nextIndex]

if (active_id) {
    WinMinimize, ahk_id %active_id%
    Sleep, 500
    WinWait, ahk_id %active_id%,, 3
}

DetectHiddenWindows, On

WinShow, ahk_id %next_id%
Sleep, 250
WinActivate, ahk_id %next_id%
WinWaitActive, ahk_id %next_id%,, 3

DllCall("BringWindowToTop", "Ptr", next_id)
DllCall("SetForegroundWindow", "Ptr", next_id)

DetectHiddenWindows, Off
return
