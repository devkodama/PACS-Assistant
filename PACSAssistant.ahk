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

DetectHiddenWindows false		; don't look for hidden windows by default
DetectHiddenText false			; don't search hidden text by default
SetDefaultMouseSpeed 0			; 0 = fastest




/**********************************************************
 * Includes
 */

#Include <WinEvent>
#Include <Cred>

#Include <Peep.v2>				; for debugging

#Include Utils.ahk
#Include PAGlobals.ahk

#Include PASound.ahk
#Include PAFindTextStrings.ahk

#Include PADaemon.ahk

#Include Network.ahk
#Include PAEI.ahk
#Include PAPS.ahk
#Include PAEPIC.ahk

#Include Hotkeys.ahk

#Include PAInfo.ahk
#Include PASettings.ahk

#Include PAICDCode.ahk

#Include PACSAssistantGUI.ahk

#Include AppManager.ahk


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
	InitDaemons(state)
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
	PASettings_Init()

	; Register Windows hooks to monitor window open and close events for all the
	; windows of interest
	for k, a in App {
		for , w in a.Win {
			if w.criteria {
				; register a hook for this window
				WinEvent.Show(_PAWindowShowCallback, w.criteria, , w.wintext)
				; register a hook for this window
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

	; Basic set up
	PAInit()

	; Set up GUI
	PAGui_Init()

    ; Start daemons
    InitDaemons(true)

}
