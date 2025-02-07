/* PACSAssistantGUI.ahk
**
** GUI functions for PACS Assistant
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force

/*
** Includes
*/

; Required libraries
#Include <WebView2>
#Include <WebViewToo>

#include "Debug.ahk"

#Include PAGlobals.ahk


/**
 * Globals
 */

global PAWindows
global PAGui
global DispatchQueue


/**
 * 
 */

if (A_IsCompiled) {
    WebViewToo.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll")
}



; Web callback functions

;
; handles JS click events and dispatches to corresponding ahk functions

ClickId(WebView, id) {
    global DispatchQueue
;    PAToolTip("id='" . id . "' was clicked")

    switch id {

        case "app-power":
            if PAStatus_PowerButton="off" {
                DispatchQueue.Push(PAGui_PACSStartup)
            }
        case "app-power-startup":
            DispatchQueue.Push(PAGui_PACSStartup)
        case "app-power-shutdown":
            DispatchQueue.Push(PAGui_PACSShutdown)
        
        case "app-VPN":
            if !VPNIsConnected() {
                DispatchQueue.Push(VPNConnect)
            }
        case "app-VPN-connect":
            DispatchQueue.Push(VPNConnect)
        case "app-VPN-disconnect":
            DispatchQueue.Push(VPNDisconnect)
        case "app-EI":
            if !EIIsRunning() {
                DispatchQueue.Push(EIStart)
            }
        case "app-EI-startup":
            DispatchQueue.Push(EIStart)
        case "app-EI-shutdown":
            DispatchQueue.Push(EIStop)

        case "app-PS":
            PAToolTip("id='" . id . "' was clicked")
;           DispatchQueue.Push(PAGui_ForceClosePS)
        case "app-PS-startup":
            PAToolTip("id='" . id . "' was clicked")
;            DispatchQueue.Push(PAGui_ForceClosePS)
        case "app-PS-shutdown":
            ; DispatchQueue.Push(PAGui_ClosePS)
        case "app-PS-forceclose":
            ; DispatchQueue.Push(PAGui_ForceClosePS)

            case "app-EPIC":
            PASound("EPIC")
        case "app-EPIC-startup":
            PAToolTip("id='" . id . "' was clicked")
        case "app-EPIC-shutdown":
            DispatchQueue.Push(EPICStop)

        case "button-restorewindows":
            DispatchQueue.Push(PAGui_RestoreWindowPositions)
        case "button-savewindows":
            DispatchQueue.Push(PAGui_SaveWindowPositions)
        default:
            PAToolTip("id='" . id . "' was clicked")
    }
}




HoverMessages := Map()
HoverMessages["app-power"] := Map("off", "Press to start PACS",
        "yellow", "",
        "green", "Right click to shut down PACS")
HoverMessages["app-VPN"] := Map("false", "Press to connect VPN",
        "true", "Right click to disconnect VPN")
HoverMessages["app-EI"] := Map("false", "Press to start EI",
        "true", "Right click to shut down EI")
HoverMessages["app-PS"] := Map("false", "",
        "true", "Right click to shut down PowerScribe")
HoverMessages["app-EPIC"] := Map("false", "",
        "true", "Right click to shut down Epic")


HoverEvent(WebView, id) {

    ; strip "app-" prefix to get app name
    app := SubStr(id,5)
    msg := HoverMessages[id][PACurState[app]]
    if msg {
        ; display tooltip
        PAToolTip(msg, 1500)
    }
}





/***************************************/


; Helper functions to simplfy making changes to GUI web page
;

; PAGui_Post() simplifies changes to the DOM.
;
; e.g. GUIPost("patientname", "innerHTML", "John Smith")
; will replace the innerHTML property of the DOM element having id="patientname" with "John Smith"
PAGui_Post(id, propname, propval) {
    if _PAGUI_Running {
	    PAGui.PostWebMessageAsString("document.getElementById('" id "')." propname " = '" propval "'")
    }
}



/***************************************/



; Set Status Bar text
PAGui_SetStatusBar(message := "") {
    global PAStatusBarText

    PAStatusBarText := message
}

; Queues messages for display in the status bar
PAStatus(message := "", duration := 0) {

    ; for now, just calls PAGui_SetStatusBar
    PAGui_SetStatusBar(message)
}



; Restore saved window positions from settings file
PAGui_RestoreWindowPositions(*) {
    static running := false

    ; prevent reentry
    if running {
        return
    }
    running := true

    PAWindows.RestoreWindows()  

    ;done
    running := false
    return
}

; Save current window positions to settings file
PAGui_SaveWindowPositions(*) {
    static running := false

    ; prevent reentry
    if running {
        return
    }
    running := true

    PAWindows.SaveWindowPositions()
    PAWindows.SaveSettings()

    ;done
    running := false
    return
}



; Start up PACS
; 
; The parameter cred is a Credentials object with username and password properties.
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; First connects the VPN, if not already connected.
;
; Upon successful VPN connection, starts EI, if not already running.
;
; Returns 1 once start up is successful, 0 if unsuccessful
; 
PAGui_PACSStartup(cred := CurrentUserCredentials) {
    static running := false

    ; prevent reentry
    if running {
        return -1
    }
    running := true

    resultVPN := VPNConnect(cred)
    if resultVPN = 1 {
        resultEI := EIStart(cred)
    } else {
        resultEI := 0
    }

    if resultVPN && resultEI {
            PAStatus("PACS started")
            returnresult := 1
    } else {
        if !resultVPN {
            PAStatus("PACS not started - VPN not connected")
            returnresult := 0
        } else if !resultEI {
            PAStatus("PACS not started - EI could not be started")
            returnresult := 0
        }
    }

    ;done
    running := false
    return returnresult
}


; Shut down PACS
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; First shuts down EI
;
; Upon successful EI shutdown, then disconnects the VPN
;
; Returns 1 if shut down is successful, 0 if unsuccessful
; 
PAGui_PACSShutdown() {
    static running := false

    ; prevent reentry
    if running {
        return -1
    }
    running := true

    resultEI := EIStop()
    if resultEI = 1 {
        
        ; [todo] need to wait until PS and EPIC (and EI?) are fully shut down before disconnecting the VPN

        resultVPN := VPNDisconnect()
    } else {
        resultVPN := 0
    }


    if resultEI && resultVPN {
        PAStatus("PACS shut down successfully")
        returnresult := 1
    } else {
        if !resultEI {
            PAStatus("PACS shut down not completed - EI not stopped")
            returnresult := 0
        } else if !resultVPN {
            PAStatus("PACS shut down not completed - VPN not disconnected")
            returnresult := 0
        }
    }

    ;done
    running := false
    return returnresult
}




; Called when GUI window is first started (opened)
PAGui_Init(*) {
    global PAGui
    global _PAGUI_Running

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
    PAGui.Load(PAGUI_HOMEPAGE)
    
    ; set up resize handler
    PAGui.OnEvent("Size", PAGui_Size)
    
    ; set up exit handler
    PAGui.OnEvent("Close", (*) => PAGui_Exit())
    
    ; set up event handlers for web page
    ; parameters are "<function name for html>", <ahk function name>
    PAGui.AddCallbackToScript("Hover", HoverEvent)
    PAGui.AddCallbackToScript("ClickId", ClickId)
    PAGui.AddCallbackToScript("HandleFormInput", HandleFormInput)

    ;MyWindow.AddHostObjectToScript("ahkButtonClick", {func:WebButtonClickEvent})
    
    ;MyWindow.AddCallBackToScript("CopyGlyphCode", CopyGlyphCodeEvent)
    ;MyWindow.AddCallBackToScript("Tooltip", WebTooltipEvent)
    ;MyWindow.AddCallbackToScript("ahkFormSubmit", FormSubmitHandler)


    PAGui.Title := PAGUI_WINDOWTITLE


    ; display the PACS Assistant window
    ; restore PACS Assistant window position
	x := PAWindows["PA"]["main"].xpos
	y := PAWindows["PA"]["main"].ypos
	w := PAWindows["PA"]["main"].width
	h := PAWindows["PA"]["main"].height
	if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
		PAGui.Show("X" . x . " Y" . y . " W" . w . " H" . h, PAGUI_WINDOWTITLE)
;        PAGui.Show()

        PAWindows.Update("PA")

        PAWindows["PA"]["main"].RestorePosition()

	} else {

		PAGui.Show()

	}

    ; call resize to calculate and set the height of the main display area
    ; wihtout actually changing the window size
    PAGui.GetClientPos(, , &w, &h)
    PAGui_Size(PAGui, 0, w, h)
  
    ; Set up the Settings page, which has dynamically generated HTML
	; PAGui.PostWebMessageAsString("document.getElementById('settingsform').innerHTML = '" PASettings_HTMLForm() "'")
    ; form := PASettings_HTMLForm()
    
    ; For unknown reasons, need to sleep to give GUI form time to render
    ; before trying to manipulate DOM. Without the Sleep(), the Settings
    ; form doesn't get displayed.
    Sleep(1000)
    
    ; declare GUI to be up and running
    _PAGUI_Running := true

    ; update GUI to show current user
    if PASettings["username"].value {
        PAGui_Post("curuser", "innerHTML", " - " . PASettings["username"].value)
    } else {
        PAGui_Post("curuser", "innerHTML", "")
    }

    ; display the settings page
    PAGui_Post("settingsform", "innerHTML", PASettings_HTMLForm())

    ; PAGui_Post("log", "innerHTML", CurrentUserCredentials.username "/" CurrentUserCredentials.password (PASettings.Has("inifile") ? "/" PASettings["inifile"].value : ""))

}


; Called when GUI is resized
PAGui_Size(thisGui, MinMax, Width, Height) {

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
PAGui_Exit(*) {

    PAStatus("Closing PACS Assistant...")

    ; save PA window position
    PAWindows.SaveWindowPositions("PA")
    PAWindows.SaveSettings("PA")

    ; stop daemons
    InitDaemons(false)

    ; stop windows "Close" event callbacks
    WinEvent.Stop("Close")

    Sleep(1000)
    
    ; terminate the script
    ExitApp()
}
