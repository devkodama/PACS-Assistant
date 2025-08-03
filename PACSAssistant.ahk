/**
 * PACSAssistant.ahk
 * 
 * Main script for PACS Assistant.
 * 
 * 
 * This module defines the functions:
 * 
 *	PAEnable()					- Enables/disables PACS Assistant
 * 	PAToggle()					- Toggles (enables/disables) PACS Assistant
 * 
 * 	PAShowHome()				- Switches PACS Assistant to Home tab
 * 	PAShowSettings()			- Switches PACS Assistant to Settings tab
 * 	PAShowWindows()				- Switches PACS Assistant to Window Manager tab
 *
 * 	PACSStart(cred := CurrentUserCredentials)	- Start up PACS
 * 	PACSStop()									- Shut down PACS
 * 
 * 	PAInit()					- Called once at startup to do necessary initialization
 * 	PAMain()					- Main starting point for PACS Assistant
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Defaults
 */


#MaxThreads 64

DetectHiddenWindows true		; this needs to be true so we can detect hidden windows
DetectHiddenText false			; don't search hidden text by default

SetDefaultMouseSpeed 0			; 0 = fastest




/**********************************************************
 * Includes
 */


#Include <WinEvent>
#Include <Cred>
#include <DateParse>
#Include <FindText>
#include <_MD_Gen>

#Include <Peep.v2>				; for debugging

#Include Utils.ahk

#Include Globals.ahk
#Include Settings.ahk
#Include FindTextStrings.ahk

#Include Sound.ahk

#Include Info.ahk
#Include ICDCode.ahk

#Include Daemon.ahk

#Include Network.ahk
#Include EI.ahk

#Include Hotkeys.ahk

#Include PS.ahk







#Include EPIC.ahk

#Include GUI.ahk

#Include AppManager.ahk

#Include Help.ahk


; for debugging use
#Include Debug.ahk




/**********************************************************
 * Auto execute section
 * 
 * This is where PACS Assistant execution starts.
 * 
 */


; Main entry point for starting PACS Assistant, by calling PAMain()
;
PAMain()




/**********************************************************
 * Functions to control PACS Manager
 * 
 */


; Enables/disables PACS Assistant
PAEnable(state) {
	global PAActive

	PAActive := state
	DaemonInit(state)
}


; Toggles (enables/disables) PACS Assistant
PAToggle() {
	global PAActive

	PAEnable(!PAActive)
}


; Switches PACS Assistant to Home tab
PAShowHome() {
    PAGui.PostWebMessageAsString("document.getElementById('tab-home').click()")
}


; Switches PACS Assistant to Settings tab
PAShowSettings() {
    PAGui.PostWebMessageAsString("document.getElementById('tab-settings').click()")
}


; Switches PACS Assistant to Window Manager tab
PAShowWindows() {
    PAGui.PostWebMessageAsString("document.getElementById('tab-windows').click()")
}




/**********************************************************
 * Functions to retrieve info from PACS Assistant
 */




/**********************************************************
 * Local functions defined by this module
 * 
 */


; This local callback function is called when a window matching specific criteria
; is shown on screen. It updates the WinItem object for the window.
_PAWindowShowCallback(hwnd, hook, dwmsEventTime) {

	; Figure out which application window was created by searching
	; for matching criteria
	crit := hook.MatchCriteria[1]
	text := hook.MatchCriteria[2]

; PAToolTip("Show " hwnd ": ('" crit "','" text "') => ?")

	for k, a in App {
		for , w in a.Win {
			if crit = w.criteria && text = w.wintext {
				; found the window, update it with the new hwnd
				w.Update(hwnd)
; PAToolTip("Show " hwnd ": ('" crit "','" text "') => " a.key "/" w.key)
				break 2		; break out of both for loops
			}
		}
	}

}


; This local callback function is called when a specific window is closed
;
_PAWindowCloseCallback(hwnd, hook, dwmsEventTime) {

	crit := hook.MatchCriteria[1]
	text := hook.MatchCriteria[2]

; PAToolTip("Close " hwnd ": ('" crit "','" text "') => ?")

	; Figure out which application window was created by searching
	; for matching criteria
	for k, a in App {
		for , w in a.Win {
			if crit = w.criteria && text = w.wintext {
				; found the window, reset the window's properties and call its hook_close
; PAToolTip("Close " hwnd ": ('" crit "','" text "') => " a.key "/" w.key)
				w.Close(false)
				break 2		; break out of both for loops
			}
		}
	}
	
	; try {
	; 	win := GetWinItem(hwnd)
	; 	if win {
	; 		win.Clear()		; Clears the hwnd and other properties
	; 	}
	; }
	
}




/**********************************************************
 * PACS start up and shut down functions
 * 
 */


; Start up PACS
; 
; The parameter cred is a Credentials object with username and password properties.
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; First connects the VPN if needed (home), or ensures a network connection (hospital).
;
; Upon successful network/VPN connection, starts EI.
;
; Returns 1 once start up is successful, 0 if unsuccessful
; 
PACSStart(cred := CurrentUserCredentials) {
    static running := false

    ; prevent reentry
    if running {
        return -1
    }
    running := true

	; if no password, ask user before proceeding
	if !cred.Password && !GUIGetPassword() {
		; couldn't get a password from the user, return failure (0)
        GUIStatus("PACS not started - password needed")
		running := false
		return 0
	}
	cred.password := CurrentUserCredentials.password

	GUIStatus("Starting PACS...")
    tick0 := A_TickCount

	resultNetwork := NetworkIsConnected(true)
	if !resultNetwork {
		if !WorkstationIsHospital() {
		    resultNetwork := (VPNStart(cred) = 1)
		}
	}

	if resultNetwork {
		; have network connection, try to start EI
        resultEI := (EIStart(cred) = 1) ? true : false
    } else {
		; no network connection, can't start EI
        resultEI := false
    }

	if !resultEI {
        GUIStatus("PACS not started - Could not start EI, PowerScribe, and/or Epic (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		GUIStatus("Could not start EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
    } else if !resultNetwork {
		if WorkstationIsHospital() {
	        GUIStatus("PACS not started - No network connection (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		} else {
	        GUIStatus("PACS not started - No VPN connection (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		}
		result := 0
	} else {
        ; EI desktop was started successfully
		; also implies PowerScribe and Epic were started successfully
	    GUIStatus("PACS started (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
        result := 1
    }

    ;done
    running := false
    return result
}


; Shut down PACS
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; First shuts down EI (which also shuts down PowerScribe and Epic)
;
; Upon successful EI shutdown, then disconnects the VPN (if using VPN)
;
; Returns 1 if shut down is successful, 0 if unsuccessful
; 
PACSStop() {
    static running := false

    ; prevent reentry
    if running {
        return -1
    }
    running := true

	; shut down PACS - EI then VPN
	GUIStatus("Shutting down PACS...")
	tick0 := A_TickCount

    resultEI := (EIStop() = 1)
	if resultEI {
		if !WorkstationIsHospital() {
			resultNetwork := (VPNStop() = 1)
		} else {
			resultNetwork := true
		}
	}

    if !resultEI {
        GUIStatus("PACS shut down not completed - EI, PowerScribe, and/or Epic was not shut down (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
        result := 0
    } else if !resultNetwork {
        GUIStatus("PACS shut down not completed - VPN was not disconnected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
        result := 0
    } else {
        GUIStatus("PACS shut down successfully (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
    	result := 1
	}

    ;done
    running := false
    return result
}




/**********************************************************
 * Main and initialization functions for PACS Assistant
 */


; Called once at startup to do necessary initialization
;
PAInit() {
	global PAApps
	global App

	; Get Windows system double click setting
	PADoubleClickSetting := DllCall("GetDoubleClickTime")

	; initialize the PAApps[] global with all of the defined App objects
	for k, a in App {
		PAApps.Push(a)
	}

	; Initialize systemwide settings
	SettingsInit()

	; Register Windows hooks to monitor window open and close events for all the
	; windows of interest
	for k, a in App {
		for , w in a.Win {
			if w.criteria {
				; register a hook for this window
				WinEvent.Show(_PAWindowShowCallback, w.criteria, , w.wintext)
			}
		}
	}

;	This causes PA to crash on exit
;	WinEvent.Close(_PAWindowCloseCallback, App["PS"].Win["logout"].criteria, , App["PS"].Win["logout"].wintext)

	; Update all windows
	UpdateAll()

	; Read all stored window positions from user's settings.ini file
	ReadPositionsAll()

	; Set up special EI key mappings
	PA_MapActivateEIKeys()

	; Read ICD code file
	ICDReadCodeFile()

}


; Main starting point for PACS Assistant
;
PAMain() {

	; set PACS Assistant application icon
	TraySetIcon("PA.ico")

	; PACS Assistant basic set up
	PAInit()

	; Set up and show GUI
	GUIMain()

    ; Start daemons
    DaemonInit()

	; Check for a username. 
	; If no current username, post an alert and ask for one.
	if !CurrentUserCredentials.username {
		GUIAlert("To get started, enter your username and password on the Settings page.", "green")
		PAShowSettings()
	} 
		; Display informational alerts the first few time(s) PA is run
		n := Setting["run"].value
		if n < 1 {
			GUIAlert("🡨 Tabs on the left side navigate between Home, Settings, Window Manager, and Help pages.", "blue")
			GUIAlert("Icons on the right side start and stop applications. Left click to start. Right click to stop. 🡪", "blue")
			GUIAlert("⮦ On/Off toggle switch on the lower left enables/disables many PACS Assistant functions (or F2)", "blue")
			Setting["run"].value := n + 1
		}

	

}
