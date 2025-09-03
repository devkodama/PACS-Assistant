/**
 * GUI.ahk
 * 
 * GUI functions for PACS Assistant
 * 
 * 
 * This module defines the functions:
 *  
 *  ClickId(WebView, id)                - handles JS click events and dispatches to corresponding ahk functions
 * 
 *  HoverEvent(WebView, id)             -
 * 
 *  GUISetPropVal(id, propname, propval)
 *  GUISetStatusBar(message := "")
 *  GUIStatus(message := "", duration := 0)
 * 
 *  GUIAlert(message, type := "info")
 *  
 *  GUIShowCancelButton()
 *  GUIHideCancelButton()
 *  GUICancelButton()
 * 
 *  GUIRestoreWindowPositions(*)        - Restore saved window positions from settings file
 *  GUISaveWindowPositions(*)           - Save current window positions to settings file
 * 
 *  GUIMain(*)                          - Called to create and show main GUI window
 * 
 *  GUIGetPassword([prompt])            - Shows a modal dialog to ask for the user's password.
 *  SetDarkWindowFrame(hwnd, boolEnable:=1) - helper function to set a gui window to dark mode
 * 
 *  GUISize(thisGui, MinMax, Width, Height) - Event handler, Called whenever GUI is resized
 *  GUIExit(*)                              - Event handler, Called when the main GUI window is closed
 * 
 * 
 * 
 * 
 */

#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Compile options
 */


if (A_IsCompiled) {
    WebViewToo.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll")
}




/**********************************************************
 * Global variables and constants used in this module
 */


; the main PACS Assistant GUI
global PAGUI

; queue of callback functions to be called
global DispatchQueue := Array()




/**********************************************************
 * Web callback functions
 */


; handles JS click events and dispatches to corresponding ahk functions
;
ClickId(WebView, id) {
    global DispatchQueue

    switch id {

        ; Power button
        case "app-power":
            if PAStatus_PowerButton="off" {
                DispatchQueue.Push(PACSStart)
            }
        case "app-power-startup":
            DispatchQueue.Push(PACSStart)
        case "app-power-shutdown":
            DispatchQueue.Push(PACSStop)
        
        ; Network/VPN button
        case "app-Network":
            if !WorkstationIsHospital() && !VPNIsConnected() {
                DispatchQueue.Push(VPNStart)
            }
        case "app-Network-connect":
            if !WorkstationIsHospital() && !VPNIsConnected() {
                DispatchQueue.Push(VPNStart)
            }
        case "app-Network-disconnect":
            if !WorkstationIsHospital() && VPNIsConnected() {
                DispatchQueue.Push(VPNStop)
            }

        ; EI button
        case "app-EI":
            if !EIIsRunning() {
                DispatchQueue.Push(EIStart)
            }
        case "app-EI-startup":
            DispatchQueue.Push(EIStart)
        case "app-EI-shutdown":
            DispatchQueue.Push(EIStop)

        ; PS button
        case "app-PS":
            if !PSIsRunning() {
                DispatchQueue.Push(PSStart)
            }
        case "app-PS-startup":
            DispatchQueue.Push(PSStart)
        case "app-PS-shutdown":
            DispatchQueue.Push(PSStop)
        case "app-PS-forceclose":
            TTip("This doesn't work")
            ; DispatchQueue.Push(GUIForceClosePS)

        ; EPIC button
        case "app-EPIC":
            if !EPICIsRunning() {
                DispatchQueue.Push(EPICstart)
            }
        case "app-EPIC-startup":
            DispatchQueue.Push(EPICstart)
        case "app-EPIC-shutdown":
            DispatchQueue.Push(EPICStop)

        ; Window save and restore buttons
        case "button-restorewindows":
            DispatchQueue.Push(GUIRestoreWindowPositions)
        case "button-savewindows":
            DispatchQueue.Push(GUISaveWindowPositions)

        ; Cancel buttons
        case "cancelbutton":
            DispatchQueue.Push(GUICancelButton)

        default:
            TTip("id='" . id . "' was clicked")
    }
}



; Hover messages and hover function
;
; [todo] Plan to replace this hover system with js or something else
;
HoverMessages := Map()
HoverMessages["app-power"] := Map("off", "Press to start PACS",
        "yellow", "",
        "green", "Right click to shut down PACS")
HoverMessages["app-Network"] := Map("false", "Press to connect Network",
        "true", "Right click to disconnect Network")
HoverMessages["app-EI"] := Map("false", "Press to start EI",
        "true", "Right click to shut down EI")
HoverMessages["app-PS"] := Map("false", "",
        "true", "Right click to shut down PowerScribe")
HoverMessages["app-EPIC"] := Map("false", "Press to start Epic",
        "true", "Right click to shut down Epic")

HoverEvent(WebView, id) {

    ; strip "app-" prefix to get app name
    ; app := SubStr(id,5)
    ; msg := HoverMessages[id][PACurState[app]]
    ; if msg {
    ;     ; display tooltip
    ;     TTip(msg, 1000)
    ; }

}




/**********************************************************
 * Helper functions to simplfy making changes to GUI web page
 */


; GUISetPropVal() sets the property propname of an element with the given id in javascript.
;
;   GUISetPropVal(id, propname, propval)  -->  document.getElementById('id').propname = 'propval';
;
; It does so by calling the WebViewToo().PostWebMessageAsString() method.
;
; e.g. GUISetPropVal("patientname", "innerHTML", "John Smith") will replace the innerHTML property value
; of the DOM element having id="patientname" with "John Smith"
;
GUISetPropVal(id, propname, propval) {
    if _GUIIsRunning {
	    PAGUI.PostWebMessageAsString("document.getElementById('" id "')." propname " = '" propval "';")
    }
}


; Set Status Bar text
GUISetStatusBar(message := "") {
    global PAStatusBarText

    PAStatusBarText := message
}


; Queues messages for display in the status bar
GUIStatus(message := "", duration := 0) {

    ; for now, just calls GUISetStatusBar
    GUISetStatusBar(message)
}


; Displays an alert box at the top of the PA window
;
; Alert types:
;   "info"
;   "success"
;   "warning"
;   "danger"
;
GUIAlert(message, type := "info") {

; TTip("paalert: " message ", " type)

    ; clean up - remove dismissed alerts
    PAGUI.PostWebMessageAsString("document.querySelectorAll('.alert.dismissed').forEach(elem => {elem.remove();});")
    
    ; append new alert after existing alerts
    alerthtml := "<div class=`"alert " . type . "`"><span class=`"closebtn`" onclick=`"closeAlert(this)`">&times;</span>" . EscapeHTML(message) . "</div>"
    PAGUI.PostWebMessageAsString("document.getElementById('alerts').insertAdjacentHTML('beforeend', '" . alerthtml . "');")
}


; Call this to show the Cancel button on the status bar
; Resets the global PACancelRequest to false
GUIShowCancelButton() {
    global PACancelRequest

    PAGUI.PostWebMessageAsString("document.getElementById('cancelbutton').removeAttribute('disabled', '');")
    GUISetPropVal("cancelbutton", "style.display", "flex")
    PACancelRequest := false
}


; Call this to hide the Cancel button on the status bar
GUIHideCancelButton() {
    GUISetPropVal("cancelbutton", "style.display", "none")
}


; This gets called to handle a click on the Cancel button
GUICancelButton() {
    global PACancelRequest

    ; disable the cancel button so it can't get clicked again
    PAGUI.PostWebMessageAsString("document.getElementById('cancelbutton').setAttribute('disabled', '');")
    PACancelRequest := true
}


; Restore saved window positions from settings file
GUIRestoreWindowPositions(*) {
    static running := false

    ; prevent reentry
    if running {
        return
    }
    running := true

    GUIStatus("Restoring windows...")

    ReadPositionsAll()
    RestorePositionsAll()

    GUIStatus("Restored")

    ;done
    running := false
    return
}


; Save current window positions to settings file
GUISaveWindowPositions(*) {
    static running := false

    ; prevent reentry
    if running {
        return
    }
    running := true

    GUIStatus("Remembering window positions...")

    SavePositionsAll()

;    Peep(App["PS"].Win["login"].savepos)
;    Peep(App["PS"].Win["main"].savepos)

    ; write to settings file
    WritePositionsAll()

    GUIStatus("Remembered")

    ;done
    running := false
    return
}




/**********************************************************
 * Main GUI functions
 * 
 */


; Called to create and show main GUI window
;
GUIMain(*) {
    global PAGUI
    global _GUIIsRunning

    ; Create the GUI
    PAGUI := WebViewToo( , , , true)
    PAGUI.Opt("+Resize -MaximizeBox")

    ; other options?   +MinSize640x480 +MaxSize1280x960 +OwnDialogs

    ; load the GUI page
    PAGUI.Load(GUIHOMEPAGE)
    PAGUI.Title := GUIWINDOWTITLE

    /**
	 * In order to use PostWebMessageAsJson() or PostWebMessageAsString(), you'll need to setup your webpage to listen to messages
	 *
     * First, MyWindow.Settings.IsWebMessageEnabled must be set to true
	 * 
     * On your webpage itself, you'll need to setup an EventListner and Handler for the WebMessages
	 * 		window.chrome.webview.addEventListener('message', ahkWebMessage);
	 * 		function ahkWebMessage(Msg) {
	 * 			console.log(Msg);
	 * 		}
	**/
    PAGUI.Settings.IsWebMessageEnabled := true
    
    ; set up resize handler
    PAGUI.OnEvent("Size", GUISize)
    
    ; set up exit handler
    PAGUI.OnEvent("Close", (*) => GUIExit())
    
    ; set up event handlers for web page
    ; parameters are "<function name for html>", <ahk function name>
    PAGUI.AddCallbackToScript("ClickId", ClickId)
    PAGUI.AddCallbackToScript("HandleFormInput", HandleFormInput)

    PAGUI.AddCallbackToScript("Hover", HoverEvent)  ; [todo] don't want to continue to use this for hovers


    ; get previously saved PACS Assistant window position
    App["PA"].ReadPositions()
    PAmain := App["PA"].Win["main"]
    x := PAmain.savepos.x
    y := PAmain.savepos.y
    w := PAmain.savepos.w
    h := PAmain.savepos.h

    if w < WINPOS_MINWIDTH || h < WINPOS_MINHEIGHT {
        ; invalid winpos, calculate some default values

        ; position PA GUI in upper right corner of 3rd monitor from right
        ; with a width of PA_DEFAULTWIDTH
        n := MonitorCount()
        if n > 2 {
            n := n - 2
        } else {
            n := 1
        }
        pos := MonitorPos(n)
        x := pos.x + pos.w - PA_DEFAULTWIDTH
        y := 0
        w := PA_DEFAULTWIDTH
        h := PA_DEFAULTHEIGHT
        PAmain.savepos.x := x
        PAmain.savepos.y := y
        PAmain.savepos.w := w
        PAmain.savepos.h := h
    
    }

    ; now show the PACS Assistant GUI window
    PAGUI.Show("x" x " y" y " w" w " h" h)
    Sleep(750)                      ; need time for GUI to be set up

    ; PAGUI.GetClientPos(, , &w, &h)  ; get actual size of client window

    GUISize(PAGUI, 0, w, h)         ; call resize to calculate and set the height of the main display area

;    PAmain.Update()

    ; declare GUI to be up and running
    _GUIIsRunning := true

    ; add username to title bar
    if Setting["username"].value {
        GUISetPropVal("curuser", "innerHTML", " - " . Setting["username"].value)
    } else {
        GUISetPropVal("curuser", "innerHTML", "")
    }

    ; initialize the settings page
    SettingsGeneratePage()

    ; initialize the Help page
    HelpShowReadme()

}




/**********************************************************
 * Main GUI functions
 * 
 */


; Shows a modal dialog to ask for the user's password.
;
; Can optionally specify a text prompt.
;
; If non-empty, the password is stored in Setting["password"]
;
; Returns true on success (non-empty password), false on cancel or failure.
;
GUIGetPassword(prompt := "Please enter your password") {
    global Setting
    local pwd
    local done

    _GUIProcessCancel(*) {
        pwdGUI.Hide()
        pwd := ""
        done := true
    }
    _GUIProcessPassword(*) {
        pwd := pwdGUI.Submit().password
        done := true
    }

    ; create the password GUI (ahk style gui)
    pwdGUI := Gui("+AlwaysOnTop -SysMenu +Owner +0x80880000", "Password")
    SetDarkWindowFrame(pwdGui)

    pwdGUI.SetFont("s10")
    pwdGUI.Add("Text", "x20 y40", prompt)
    pwdGUI.Add("Edit", "yp vpassword Password Limit" . PA_PASSWORD_MAXLENGTH)
    pwdGUI.Add("Button", "x120 y80", "Cancel").OnEvent("Click", _GUIProcessCancel)
    pwdGUI.Add("Button", "yp default", "Ok").OnEvent("Click", _GUIProcessPassword)
    pwdGUI.OnEvent("Close", _GUIProcessPassword)

    ; calculate position for dialog window
    p := App["PA"].Win["main"].pos
    if p.w < WINPOS_MINWIDTH || p.h < WINPOS_MINHEIGHT {
        ; invalid w or h, use sensible default
        x := 400
        y := 400
    } else {
        ; center over PA main window
        x := p.x + (p.w - 380) / 2
        y := p.y + (p.h - 140) / 2
    }

    ; show the gui
    pwdGUI.Show("x" x " y" y " w380 h140")

    ; wait for the user to enter a password or cancel
    done := false
    while !done {
        Sleep(500)
    }

    if pwd {
        ; we got a non-empty password, store it
        Setting["password"].value := pwd
        ; update the GUI Settings page
        SettingsGeneratePage()
        return true
    } else {
        ; didn't get a password, don't save anything
        return false
    }
}


; helper function to set a gui window to dark mode
;
SetDarkWindowFrame(hwnd, boolEnable:=1) {
    hwnd := WinExist(hwnd)
    if VerCompare(A_OSVersion, "10.0.17763") >= 0
        attr := 19
    if VerCompare(A_OSVersion, "10.0.18985") >= 0
        attr := 20
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", attr, "int*", boolEnable, "int", 4)
}




/**********************************************************
 * GUI event handlers
 * 
 */


; Called whenever GUI is resized
;
; It calculates the height of the useful display area, which is the window height
; minus the height of the title and status bars (currently 24px + 24px)
;
; This allows the main display area to be given a definite height so it will
; display a vertical scroll bar when contents exceed its height.
;
GUISize(thisGui, MinMax, Width, Height) {

    ; (-1 = minimized, 1 = maximized, 0 = neither minimized nor maximized)
    if MinMax = -1 {
        ; The window has been minimized. No action needed.
        return
    }

    ; Otherwise, the window has been resized or maximized
    ; Recalculate the height of the main display area and change the height of div#main

;    PAGui.GetClientPos(&x, &y, &w, &h)
;    PAToolTip(x ", " y ", " w ", " h)

    h := Height - 50
    PAGUI.PostWebMessageAsString("document.getElementById('main').style = `"height: " . h . "px;`"")
;    GUISetPropVal("main", "style", "`"height: " . h . "px;`"")

}


; Called when the main GUI window is closed
GUIExit(*) {

    GUIStatus("Closing PACS Assistant...")

    ; save PA window positions
    appPA := App["PA"]
    appPA.SavePositions()
    appPA.WritePositions()

    ; stop daemons
    DaemonInit(false)

    ; If this is not a hospital workstation, because 
    ; password might not have been written to local store because
    ; Setting["storepassword"] may not have existed when Setting["password"]
    ; was updated, or may have been changed after Setting["password"]
    ; was updated, we update the local password storage now.
    if !WorkstationIsHospital() {
        Setting["password"].SaveSetting()
    }

    ; terminate the script
    ExitApp()
}
