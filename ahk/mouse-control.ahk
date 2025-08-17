#Requires AutoHotkey v2.0
#SingleInstance
InstallKeybdHook

global CONTROL_TYPE_NAME_VIM := "vim"
global CONTROL_TYPE_NAME_INSERT := "none"

global INPUT_MODE := {
    type: CONTROL_TYPE_NAME_VIM,
    quick: false,
}

global MOUSE_FORCE := 5
global MOUSE_RESISTANCE := 0.892

global VELOCITY_X := 0
global VELOCITY_Y := 0

global DRAGGING := false
global DOUBLE_PRESS_ACTION_IS_ACTIVE := false
global cursorMovementTimer := 0

global modeIndicators := []
global modeTexts := []
global centralIndicators := []
global centralIndicatorTimer := 0

CreateModeIndicator()
CreateCentralIndicators()

EnterNormalMode()

CreateModeIndicator() {
    global modeIndicators, modeTexts
    monitorCount := MonitorGetCount()
    modeIndicators := Array()
    modeTexts := Array()

    if (monitorCount > 0) {
        modeIndicators.Length := monitorCount
        modeTexts.Length := monitorCount
    } else {
        return
    }

    loop monitorCount {
        monitorIndex := A_Index
        modeIndicator := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner +E0x20")
        modeIndicator.BackColor := "000000"
        modeText := modeIndicator.Add("Text", "cFFFFFF w120 h40 Right", "mouse ⌘")
        modeText.SetFont("s18 bold", "BIZ UDPGothic")

        MonitorGet monitorIndex, &monLeft, , &monRight, &monBottom
        xPos := monRight - 165
        yPos := monBottom - 40

        modeIndicator.Show("x" xPos " y" yPos " NoActivate")
        WinSetTransColor("000000 200", modeIndicator)
        WinSetAlwaysOnTop(1, modeIndicator)

        modeIndicators[monitorIndex] := modeIndicator
        modeTexts[monitorIndex] := modeText
    }
}

CreateCentralIndicators() {
    global centralIndicators
    monitorCount := MonitorGetCount()
    centralIndicators := Array()
    if (monitorCount > 0)
        centralIndicators.Length := monitorCount
    else
        return
    ;
        loop monitorCount {
            monitorIndex := A_Index
            indicatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20")
            indicatorGui.BackColor := "333333"
            indicatorText := indicatorGui.Add("Text", "cFFFFFF Center vCentralText" .
                monitorIndex,
                ""
            )
            indicatorText.SetFont("s20 bold", "BIZ UDPGothic")
            WinSetTransColor("000000 200", indicatorGui)

            centralIndicators[monitorIndex] := { gui: indicatorGui, text: indicatorText }
        }
}

UpdateModeIndicator(mode) {
    global modeIndicators, modeTexts

    if (!modeIndicators.Length)
        CreateModeIndicator()

    loop modeIndicators.Length {
        monitorIndex := A_Index
        if (!modeTexts.Has(monitorIndex) || !modeIndicators.Has(monitorIndex))
            continue

        modeText := modeTexts[monitorIndex]
        modeIndicator := modeIndicators[monitorIndex]

        if (InStr(mode, "MOUSE") || InStr(mode, "VIM")) {
            modeText.SetFont("cFFFFFFF")
        } else {
            modeText.SetFont("cFFFFFFF")
        }
        modeText.Value := mode

        ; Asegurar que el indicador esté siempre encima
        WinSetAlwaysOnTop(1, modeIndicator)
    }
}

Accelerate(velocity, pos, neg) {
    if (pos == 0 && neg == 0) {
        return 0
    }
    else if (pos + neg == 0) {
        return velocity * 0.666
    }
    else {
        return velocity * MOUSE_RESISTANCE + MOUSE_FORCE * (pos + neg)
    }
}

MoveCursor() {
    LEFT := 0 - GetKeyState("SC023", "P")
    DOWN := 0 + GetKeyState("SC024", "P")
    UP := 0 - GetKeyState("SC025", "P")
    RIGHT := 0 + GetKeyState("SC026", "P")

    if (
        INPUT_MODE.type != CONTROL_TYPE_NAME_INSERT &&
        INPUT_MODE.quick &&
        !GetKeyState("Capslock", "P")
    ) {
        EnterInsertMode()
        return
    }

    if (INPUT_MODE.type == CONTROL_TYPE_NAME_INSERT) {
        global VELOCITY_X := 0
        global VELOCITY_Y := 0

        SetTimer(MoveCursor, 0)
        global cursorMovementTimer := 0
        return
    }

    global VELOCITY_X := Accelerate(VELOCITY_X, LEFT, RIGHT)
    global VELOCITY_Y := Accelerate(VELOCITY_Y, UP, DOWN)

    if (Abs(VELOCITY_X) < 0.05 && Abs(VELOCITY_Y) < 0.05) {
        return
    }

    RestoreDPI := DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

    MouseMove(VELOCITY_X, VELOCITY_Y, 0, "R")
}

EnterNormalMode(quick := false) {
    if (DRAGGING) {
        Click("L Up")
        Click("R Up")
        Click("M Up")
        global DRAGGING := false
    }

    INPUT_MODE.type := CONTROL_TYPE_NAME_VIM
    INPUT_MODE.quick := quick

    msg := "NORMAL"
    msg := INPUT_MODE.quick ? msg . "q" : msg

    UpdateModeIndicator(msg)

    if (cursorMovementTimer) {
        SetTimer(MoveCursor, 0)
    }

    SetTimer(MoveCursor, 5)
    global cursorMovementTimer := 1
}

EnterInsertMode(quick := false) {
    if (DRAGGING) {
        Click("L Up")
        Click("R Up")
        Click("M Up")
        global DRAGGING := false
    }

    msg := quick ? "INSERT" : "I"

    UpdateModeIndicator(msg)

    INPUT_MODE.type := CONTROL_TYPE_NAME_INSERT
    INPUT_MODE.quick := quick

    if (cursorMovementTimer) {
        SetTimer(MoveCursor, 0)
        global cursorMovementTimer := 0
    }

    global VELOCITY_X := 0
    global VELOCITY_Y := 0
}

ClickInsert(quick := true) {
    Click
    EnterInsertMode(quick)
}

DoubleClickInsert(quick := true) {
    Click
    Sleep(100)
    Click
    EnterInsertMode(quick)
}

Drag(mouseButton := "L") {
    global

    Click("L Up")
    Click("R Up")
    Click("M Up")

    if (DRAGGING) {
        Click(mouseButton " Up")
        DRAGGING := false

        return
    }

    Click(mouseButton " Down")
    DRAGGING := true
}

Yank() {
    wx := 0, wy := 0, width := 0
    WinGetPos(&wx, &wy, &width, , "A")
    center := wx + width - 180
    y := wy + 12
    MouseMove(center, y)
    Drag()
}

EmulateMouseButton(button := "L") {
    if (InStr(A_ThisHotkey, "Up")) {
        Click(button " Up")
    }
    else {
        Click(button " Down")
    }

    global DRAGGING := false
}

JumpMiddle() {
    CoordMode("Mouse", "Screen")
    MouseMove(A_ScreenWidth // 2, A_ScreenHeight // 2)
}

GetMonitorLeftEdge() {
    mx := 0

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx)

    return mx // A_ScreenWidth * A_ScreenWidth
}

JumpToEdge(direction) {
    x := 0, y := 0

    switch direction {
        case "left":
            x := GetMonitorLeftEdge() + 2

            CoordMode("Mouse", "Screen")
            MouseGetPos(, &y)

        case "bottom":
            y := A_ScreenHeight

            CoordMode("Mouse", "Screen")
            MouseGetPos(&x)

        case "top":
            CoordMode("Mouse", "Screen")
            MouseGetPos(&x)

        case "right":
            x := GetMonitorLeftEdge() + A_ScreenWidth - 2

            CoordMode("Mouse", "Screen")
            MouseGetPos(, &y)
    }

    MouseMove(x, y)
}

MouseBrowserNavigate(to) {
    if (to == "back") {
        Click("X1")
    }
    else if (to == "forward") {
        Click("X2")
    }
}

ScrollTo(direction) {
    switch direction {
        case "up":
            Click("WheelUp")
        case "down":
            Click("WheelDown")
    }

    DoByDoublePress(ScrollTo.Bind(direction), 5)
}

DoByDoublePress(callback, repeatFor := 1) {
    global

    if (DOUBLE_PRESS_ACTION_IS_ACTIVE) {
        return
    }

    try {
        if (A_TimeSincePriorHotkey < 250 && A_ThisHotkey = A_PriorHotkey) {
            DOUBLE_PRESS_ACTION_IS_ACTIVE := true

            loop repeatFor {
                callback()
            }

            DOUBLE_PRESS_ACTION_IS_ACTIVE := false
        }
    }
}

ResetMouseState() {
    Click("L Up")
    Click("R Up")
    Click("M Up")
    global DRAGGING := false
    global VELOCITY_X := 0
    global VELOCITY_Y := 0

    if (cursorMovementTimer) {
        SetTimer(MoveCursor, 0)
        global cursorMovementTimer := 0
    }

    EnterInsertMode(false)
    msg := "RESET"
    UpdateModeIndicator(msg)
}

F12:: ResetMouseState()

Home:: EnterNormalMode()
Insert:: EnterInsertMode()
!i:: EnterInsertMode()
!n:: EnterNormalMode()

+Home:: Send("{Home}")
+Insert:: Send("{Insert}")

^Capslock:: Send("{ Capslock }")
^+Capslock:: SetCapsLockState("Off")

#HotIf (INPUT_MODE.type != CONTROL_TYPE_NAME_INSERT)
+SC029:: ClickInsert(false)
SC029:: ClickInsert(true)
~SC021:: EnterInsertMode(true)
~^SC021:: EnterInsertMode(true)
~^SC014:: EnterInsertMode(true)
~Delete:: EnterInsertMode(true)
SC027:: EnterInsertMode(true)
~Lwin:: EnterInsertMode(true)
SC023:: return
+SC023:: JumpToEdge("left")
SC024:: return
+SC024:: JumpToEdge("bottom")
SC025:: return
+SC025:: JumpToEdge("top")
SC026:: return
+SC026:: JumpToEdge("right")
*SC017:: EmulateMouseButton()
*SC017 Up:: EmulateMouseButton()
*SC018:: EmulateMouseButton("R")
*SC018 Up:: EmulateMouseButton("R")
*SC019:: EmulateMouseButton("M")
*SC019 Up:: EmulateMouseButton("M")
+SC015:: Yank()
SC02F:: Drag()
SC02C:: Drag("R")
SC02E:: Drag("M")
SC032:: JumpMiddle()
SC031:: MouseBrowserNavigate("forward")
SC030:: MouseBrowserNavigate("back")
*SC00A:: ScrollTo("up")
*SC00B:: ScrollTo("down")
SC01A:: ScrollTo("up")
SC01B:: ScrollTo("down")
SC015:: ScrollTo("up")
SC012:: ScrollTo("down")
^l:: EnterInsertMode(true)

/* #HotIf (INPUT_MODE.type != CONTROL_TYPE_NAME_INSERT && !INPUT_MODE.quick)
Capslock:: EnterInsertMode(true)
+Capslock:: EnterInsertMode() */

#HotIf (INPUT_MODE.type != CONTROL_TYPE_NAME_INSERT && INPUT_MODE.quick)
Capslock:: return
SC032:: JumpMiddle()

#HotIf (INPUT_MODE.type != CONTROL_TYPE_NAME_INSERT && WinActive("ahk_class CabinetWClass"))
^SC023:: Send("{ Left }")
^SC024:: Send("{ Down }")
^SC025:: Send("{ Up }")
^SC026:: Send("{ Right }")

#HotIf (INPUT_MODE.type == CONTROL_TYPE_NAME_INSERT && !INPUT_MODE.quick)
Capslock:: EnterNormalMode(true)
+Capslock:: EnterNormalMode()

#HotIf (INPUT_MODE.type == CONTROL_TYPE_NAME_INSERT && INPUT_MODE.quick)
~Enter:: EnterNormalMode()
~^SC02E:: EnterNormalMode()
Escape:: EnterNormalMode()
Capslock:: EnterNormalMode()
+Capslock:: EnterNormalMode()
