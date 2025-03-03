/**
 * GUI.ahk
 * 
 * GUI functions for PACS Assistant
 * 
 * 
 * This module defines the functions:
 *  
 * 
 * 
 * 
 * 
 * 
 */

#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */

#Include <WebView2>
#Include <WebViewToo>

#Include Globals.ahk
#Include Utils.ahk

#include Debug.ahk




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

global pwdGUI

; queue of callback functions to be called
global DispatchQueue




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
            TTip("This doesn't work yet")
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


; GUIPost() sets the property propname of an element with the given id in javascript.
;
;   GUIPost(id, propname, propval)  -->  document.getElementById('id').propname = 'propval';
;
; It does so by calling the WebViewToo().PostWebMessageAsString() method.
;
; e.g. GUIPost("patientname", "innerHTML", "John Smith") will replace the innerHTML property 
; of the DOM element having id="patientname" with "John Smith"
;
GUIPost(id, propname, propval) {
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
    GUIPost("cancelbutton", "style.display", "flex")
    PACancelRequest := false
}


; Call this to hide the Cancel button on the status bar
GUIHideCancelButton() {
    GUIPost("cancelbutton", "style.display", "none")
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

  TTip("GUIRestoreWindowPositions")
    ReadPositionsAll()
    RestorePositionsAll()

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

  TTip("GUISaveWindowPositions")
    SavePositionsAll()
    WritePositionsAll()

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
	 * First, MyWindow.Settings.IsWebMessageEnabled must be set to true
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

    PAGUI.AddCallbackToScript("Hover", HoverEvent)  ; don't want to continue to use this for hovers


    ; display the PACS Assistant window
    ; and restore PACS Assistant window position

    winPA := App["PA"].Win["main"]
    winPA.ReadPosition()
    x := winPA.savepos.x
    y := winPA.savepos.y
    w := winPA.savepos.w
    h := winPA.savepos.h

    if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
        PAGUI.Show("x" x " y" y " w" w " h" h)
        Sleep(500)                      ; need time for GUI to be set up
    } else {
        ; invalid position, don't use to show
        PAGUI.Show()
        Sleep(500)                      ; need time for GUI to be set up
        PAGUI.GetClientPos(, , &w, &h)  ; get actual size of client window
    }
    GUISize(PAGUI, 0, w, h)         ; call resize to calculate and set the height of the main display area

    winPA.Update()

    ; declare GUI to be up and running
    _GUIIsRunning := true

    ; update GUI to show current username
    if Setting["username"].value {
        GUIPost("curuser", "innerHTML", " - " . Setting["username"].value)
    } else {
        GUIPost("curuser", "innerHTML", "")
    }

    ; initialize the settings page
    SettingsGeneratePage()

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

    ; show the gui
    pwdGUI.Show("w380 h140" )

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
;    GUIPost("main", "style", "`"height: " . h . "px;`"")

}


; Called when the main GUI window is closed
GUIExit(*) {

    GUIStatus("Closing PACS Assistant...")

    ; save PA window position
    winPA := App["PA"].Win["main"]
    winPA.SavePosition()
    winPA.WritePosition()

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
