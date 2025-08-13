#Requires AutoHotkey v2.0
FileInstall "WarZoneAhk.png", "WarZoneAhk.png", 1  ; عدد 1 یعنی همیشه در EXE جاسازی شود
; --- اسپلش اسکرین ---
ShowSplashScreen() {
    width := 708, height := 200
    xPos := (A_ScreenWidth - width) // 2, yPos := (A_ScreenHeight - height) // 2

    bgGui := Gui()
    bgGui.Opt("-Caption +AlwaysOnTop +E0x20")
    bgGui.BackColor := "334D5C"
    bgGui.Show("x" xPos " y" yPos " w" width " h" height)
    WinSetTransparent(180, bgGui.Hwnd)

    textGui := Gui()
    textGui.Opt("-Caption +AlwaysOnTop +Parent" bgGui.Hwnd)
    textGui.BackColor := "334D5C"
    textGui.SetFont("s45 Bold cYellow", "Segoe UI")
    textGui.Add("Text", "x+100 y+60 w" width-60 " h" height-80, "Warzone Tools")  
    
    ; حاشیه‌های زرد
    textGui.Add("Text", "x0 y0 w" width " h2 BackgroundYellow")
    textGui.Add("Text", "x0 y0 w2 h" height " BackgroundYellow")
    textGui.Add("Text", "x" (width-2) " y0 w2 h" height " BackgroundYellow")
    textGui.Add("Text", "x0 y" (height-2) " w" width " h2 BackgroundYellow")

    textGui.Show("x0 y0")

    FadeIn(bgGui.Hwnd, 1000)
    Sleep 3000
    FadeOut(bgGui.Hwnd, 1000)
    Sleep 1000
    bgGui.Destroy()
    
    global splashScreenFinished := true
}

FadeIn(hWnd, duration) {
    Loop 25 {
        WinSetTransparent(A_Index * 10, hWnd)
        Sleep(duration // 25)
    }
}

FadeOut(hWnd, duration) {
    Loop 25 {
        WinSetTransparent(250 - (A_Index * 10), hWnd)
        Sleep(duration // 25)
    }
}

; --- متغیرهای عمومی ---
global isPaused := false
global isLoopActive := false
global isMouseMoving := false
global isSendingG := false
global currentRecoil := 3.0
global recoilStep := 0.5
global alertX := 890
global alertY := 5
global alertWidth := 135
global alertHeight := 60
global splashScreenFinished := false
global cKeyCooldown := false

; --- کد اصلی ---
SetKeyDelay 10, 10
SetTitleMatchMode 2

ShowSplashScreen()

offIcon := A_ScriptDir . "\WarZoneAhk.png"
myGui := Gui()
myGui.Add("Picture", "vStatusIcon w60 h60", offIcon)
myGui.BackColor := "000000"
myGui.Opt("-MinimizeBox -MaximizeBox +AlwaysOnTop -Caption +Owner")

; --- عملکرد کلید C ---
~c::
{
    global isPaused, isLoopActive, cKeyCooldown, splashScreenFinished
    
    if !splashScreenFinished || isPaused || !isLoopActive || cKeyCooldown
        return
    
    cKeyCooldown := true
    Send("{Ctrl down}")
    Sleep 20
    Send("{Space down}")
    Sleep 60
    Send("{Ctrl up}")
    Sleep 20
    Send("{Space up}")
    Sleep 300
    cKeyCooldown := false
}

SetTimer SendGKey, 20000

Loop {
    global isLoopActive, splashScreenFinished
    if !splashScreenFinished
        continue
    Sleep 10
}

~LButton::
{
    global isPaused, isMouseMoving, currentRecoil, splashScreenFinished
    if !splashScreenFinished || isPaused || !isMouseMoving
        return

    recoilDelay := 80
    actualRecoil := Round(currentRecoil)

    Loop {
        if !GetKeyState("LButton", "P") || !isMouseMoving
            break
        DllCall("mouse_event", "UInt", 0x01, "Int", 0, "Int", actualRecoil, "UInt", 0, "Int", 0)
        Sleep recoilDelay
    }
}

; تغییر: فعال‌سازی/غیرفعال‌سازی کل اسکریپت با کنترل + راست
^Right::
{
    global isPaused, isLoopActive, isMouseMoving, isSendingG, splashScreenFinished
    if !splashScreenFinished
        return
        
    isPaused := !isPaused
    isSendingG := !isPaused
    if isPaused {
        isLoopActive := false
        isMouseMoving := false
        myGui.Show("x1838 y910 w70 h70")
        WinSetTransparent 180, myGui.Hwnd
        ShowSimpleAlert("SCRIPT OFF")
    } else {
        isLoopActive := true
        isMouseMoving := true
        myGui.Hide()
        ShowSimpleAlert("SCRIPT ON")
    }
}

; تغییر: فعال‌سازی/غیرفعال‌سازی ریکویل با کنترل + چپ
^Left::
{
    global isMouseMoving, splashScreenFinished
    if !splashScreenFinished
        return
    isMouseMoving := !isMouseMoving
    if isMouseMoving
        ShowSimpleAlert("RECOIL ON")
    else
        ShowSimpleAlert("RECOIL OFF")
}

~Enter::
{
    global isSendingG, splashScreenFinished
    if !splashScreenFinished
        return
    isSendingG := !isSendingG
}

SendGKey() {
    global isSendingG, splashScreenFinished
    if !splashScreenFinished
        return
    if isSendingG {
        Send("{G}")
    }
}

; تنظیم ریکویل با کنترل + بالا/پایین
^Up::
{
    global splashScreenFinished
    if !splashScreenFinished
        return
    AdjustRecoil(1)
}

^Down::
{
    global splashScreenFinished
    if !splashScreenFinished
        return
    AdjustRecoil(-1)
}

AdjustRecoil(direction) {
    global currentRecoil, recoilStep
    newRecoil := currentRecoil + (direction * recoilStep)

    if (newRecoil < 1)
        newRecoil := 1
    else if (newRecoil > 10)
        newRecoil := 10

    currentRecoil := newRecoil
    ShowAlert("Recoil", Round(currentRecoil, 1))
}

ShowSimpleAlert(message) {
    global alertX, alertY, alertWidth, alertHeight

    alertGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    alertGui.BackColor := "0F1923"

    textColor := InStr(message, "ON") ? "0x00FF00" : "0xFF0000"
    alertGui.SetFont("s14 w700", "Segoe UI")
    alertGui.Add("Text", "x0 y0 w" alertWidth " h" alertHeight " Center c" textColor, message)
    alertGui.Show("x" alertX " y" alertY " w" alertWidth " h" alertHeight)

    WinSetTransparent 220, alertGui.Hwnd
    SetTimer () => alertGui.Destroy(), -1500
}

ShowAlert(title, message) {
    global alertX, alertY, alertWidth, alertHeight

    alertGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    alertGui.BackColor := "0F1923"

    alertGui.SetFont("s10 w700 cFFD700", "Segoe UI")
    alertGui.Add("Text", "x" alertWidth " y5 w50 Right", title)

    alertGui.SetFont("s12 w700 cFFFFFF")
    alertGui.Add("Text", "x0 y20 w" alertWidth " Center", message)

    alertGui.Show("x" alertX " y" alertY " w" alertWidth " h" alertHeight)
    WinSetTransparent 220, alertGui.Hwnd
    SetTimer () => alertGui.destroy(), -1500
}

; --- نمایش نام سازنده ---
^!+s::  ; Ctrl+Alt+Shift+S
{
    creatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    creatorGui.BackColor := "0F1923"
    creatorGui.SetFont("s12 cWhite", "Segoe UI")
    creatorGui.Add("Text", "x10 y10", "HoseinSH74(patrio4)")
    creatorGui.Show("x" (A_ScreenWidth-200) " y" (A_ScreenHeight-50) " w200 h40")
    WinSetTransparent 200, creatorGui.Hwnd
    SetTimer () => creatorGui.Destroy(), 3000
}
