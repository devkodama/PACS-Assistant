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


global PAGui
global DispatchQueue




/**********************************************************
 * Web callback functions
 */


; handles JS click events and dispatches to corresponding ahk functions
;
ClickId(WebView, id) {
    global DispatchQueue
;    PAToolTip("id='" . id . "' was clicked")

    switch id {

        case "app-power":
            if PAStatus_PowerButton="off" {
                DispatchQueue.Push(PACSStart)
            }
        case "app-power-startup":
            DispatchQueue.Push(PACSStart)
        case "app-power-shutdown":
            DispatchQueue.Push(PACSStop)
        
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
        case "app-EI":
            if !EIIsRunning() {
                DispatchQueue.Push(EIStart)
            }
        case "app-EI-startup":
            DispatchQueue.Push(EIStart)
        case "app-EI-shutdown":
            DispatchQueue.Push(EIStop)

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

        case "app-EPIC":
            if !EPICIsRunning() {
                DispatchQueue.Push(EPICstart)
            }
        case "app-EPIC-startup":
            DispatchQueue.Push(EPICstart)
        case "app-EPIC-shutdown":
            DispatchQueue.Push(EPICStop)

        case "button-restorewindows":
            DispatchQueue.Push(GUIRestoreWindowPositions)
        case "button-savewindows":
            DispatchQueue.Push(GUISaveWindowPositions)

        case "cancelbutton":
            DispatchQueue.Push(GUICancelButton)

        default:
            TTip("id='" . id . "' was clicked")
    }
}




; Hover messages and hover function
;
; [todo] Plan to replace this with js
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


; GUIPost() simplifies changes to the DOM.
;
; e.g. GUIPost("patientname", "innerHTML", "John Smith")
; will replace the innerHTML property of the DOM element having id="patientname" with "John Smith"
GUIPost(id, propname, propval) {
    if _GUIRunning {
	    PAGui.PostWebMessageAsString("document.getElementById('" id "')." propname " = '" propval "';")
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

TTip("paalert: " message ", " type)

    ; PAGui.PostWebMessageAsString("")

    ; clean up - remove dismissed alerts
    PAGui.PostWebMessageAsString("document.querySelectorAll('.alert.dismissed').forEach(elem => {elem.remove();});")
    
    ; append new alert
    alerthtml := "<div class=`"alert " . type . "`"><span class=`"closebtn`" onclick=`"closeAlert(this)`">&times;</span>" . EscapeHTML(message) . "</div>"

    PAGui.PostWebMessageAsString("document.getElementById('alerts').insertAdjacentHTML('beforeend', '" . alerthtml . "');")
    
}


; Call this to show the Cancel button on the status bar
; Resets the global PACancelRequest to false
GUIShowCancelButton() {
    global PACancelRequest

    PAGui.PostWebMessageAsString("document.getElementById('cancelbutton').removeAttribute('disabled', '');")
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

    PAGui.PostWebMessageAsString("document.getElementById('cancelbutton').setAttribute('disabled', '');")
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








; Called when GUI window is first started (opened)
GUIInit(*) {
    global PAGui
    global _GUIRunning

    ; Create the GUI
    PAGui := WebViewToo(,,, true)

    ;PAGui.Debug()
    PAGui.Opt("+Resize -MaximizeBox")

    /**
	 * In order to use PostWebMessageAsJson() or PostWebMessageAsString(), you'll need to setup your webpage to listen to messages
	 * First, MyWindow.Settings.IsWebMessageEnabled must be set to true
	 * On your webpage itself, you'll need to setup an EventListner and Handler for the WebMessages
	 * 		window.chrome.webview.addEventListener('message', ahkWebMessage);
	 * 		function ahkWebMessage(Msg) {
	 * 			console.log(Msg);
	 * 		}
	**/
    PAGui.Settings.IsWebMessageEnabled := true

    ; load the page
    PAGui.Load(GUIHOMEPAGE)
    
    ; set up resize handler
    PAGui.OnEvent("Size", GUISize)
    
    ; set up exit handler
    PAGui.OnEvent("Close", (*) => GUIExit())
    
    ; set up event handlers for web page
    ; parameters are "<function name for html>", <ahk function name>
    PAGui.AddCallbackToScript("ClickId", ClickId)
    PAGui.AddCallbackToScript("HandleFormInput", HandleFormInput)

    PAGui.AddCallbackToScript("Hover", HoverEvent)  ; don't want to use this for hovers

    PAGui.Title := GUIWINDOWTITLE

    ; display the PACS Assistant window
    ; and restore PACS Assistant window position

    win := App["PA"].Win["main"]
    win.ReadPosition()
    x := win.savepos.x
    y := win.savepos.y
    w := win.savepos.w
    h := win.savepos.h

    if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
        PAGui.Show("x" x " y" y " w" w " h" h)
        Sleep(300)                      ; need time for GUI to be set up
        GUISize(PAGui, 0, w, h)      ; call resize to calculate and set the height of the main display area
    } else {
        PAGui.Show()
        Sleep(500)                      ; need time for GUI to be set up
        PAGui.GetClientPos(, , &w, &h)  ; get actual size of client window
        GUISize(PAGui, 0, w, h)      ; call resize to calculate and set the height of the main display area
    }    


    win.Update()

    ; declare GUI to be up and running
    _GUIRunning := true

    ; update GUI to show current username
    if Setting["username"].value {
        GUIPost("curuser", "innerHTML", " - " . Setting["username"].value)
    } else {
        GUIPost("curuser", "innerHTML", "")
    }

    ; display the settings page
    PASettings_HTMLForm()

    ; GUIPost("log", "innerHTML", CurrentUserCredentials.username "/" CurrentUserCredentials.password (PASettings.Has("inifile") ? "/" PASettings["inifile"].value : ""))

}


; Called whenever GUI is resized
GUISize(thisGui, MinMax, Width, Height) {

    if MinMax = -1 {
        ; The window has been minimized. No action needed.
        return
    }

    ; Otherwise, the window has been resized or maximized.
    ; Recalculate the height of the main display area and change the height of div#main

;    PAGui.GetClientPos(&x, &y, &w, &h)
;    PAToolTip(x ", " y ", " w ", " h)
    h := Height - 54
    PAGui.PostWebMessageAsString("document.getElementById('main').style = `"height: " . h . "px;`"")

}


; Called when GUI window is closed
GUIExit(*) {

    GUIStatus("Closing PACS Assistant...")

    ; save PA window position
    win := App["PA"].Win["main"]
    win.SavePosition
    win.WritePosition



    ; stop all WinEvent windows event callbacks
    ;WinEvent.Stop()



    ; stop daemons
    DaemonInit(false)


    ; Sleep(1000)


    ; terminate the script
    ExitApp()
}
