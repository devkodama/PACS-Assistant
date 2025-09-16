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
 *  SetTray()			        - Redefines the tray menu and tray tooltip
 * 
 * 	PAMain()					- Main starting point for PACS Assistant
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Run as Admin
 */

; Run as Admin in order to interact with other programs that 
; are running as Admin (https://www.autohotkey.com/docs/v2/lib/Run.htm#RunAs)
;
; If this is not done, then we have trouble communicating with windows on 
; hospital workstations.
if not (A_IsAdmin)
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}




/**********************************************************
 * Program-wide defaults
 * 
 * Don't change these without considering global implications!
 *
 */


#MaxThreads 64

DetectHiddenWindows true		; true - this needs to be true so we can detect hidden windows
DetectHiddenText false			; false - don't search hidden text by default

SetDefaultMouseSpeed 0			; 0 = fastest
SetControlDelay 0				; 0 = shortest possible delay

; Makes a script unconditionally use its own folder as its working directory.
; Ensures a consistent starting directory. [Is this necessary?]
SetWorkingDir A_ScriptDir




/**********************************************************
 * Prepare resources for compiled scripts
 * 
 * This needs to be run before anything else.
 *
 */


#Include Compiled.ahk




/**********************************************************
 * Extended AHK Script Properties
 * 
 * These are not defined by AHK but should be
 *
 */


; A_UserDir
; 	The user's home directory. For example: C:\Users\<UserName>
if n := InStr(A_Desktop, "\Desktop", , -1) {
	A_UserDir := SubStr(A_Desktop, 1, n - 1)
} else {
	A_UserDir := ""
}

; A_ProgramFiles_x86
; 	The Program Files directory for 32-bit processes. For example: C:\Program Files (x86)
A_ProgramFiles_x86 := EnvGet("ProgramFiles(x86)")

; A_Version
; 	The program version, as a string. For example: 1.0.2-beta
if A_IsCompiled {
	A_Version := Compiled_VersionString
} else {
    try {
		A_Version := FileRead("version")
	    A_Version := SubStr(A_Version, 1, 32)       ; limit to 32 chars
	} catch {
		A_Version := "" 
	}
}

; A_AhkExe
;	The executable file that is running.
;	For example, for a non-compiled script: AutoHotkey64.exe
;	For example, for a compiled script: PACS Assistant.exe
SplitPath(A_AhkPath, &A_AhkExe)			; just the filename




/**********************************************************
 * Includes
 */


; Libraries
#Include <WebView2>
#Include <WebViewToo>
#Include <WinEvent>
#Include <Cred>
#include <DateParse>
#Include <FindText>
#include <_MD_Gen>

; PACS Assistant modules
#Include Globals.ahk
#Include Utils.ahk
#Include FindTextStrings.ahk

#Include Settings.ahk

#Include Updater.ahk

#Include AppManager.ahk
#Include Layout.ahk

#Include Sound.ahk
#Include Info.ahk
#Include ICDCode.ahk
#Include Daemon.ahk

#Include Network.ahk
#Include EI.ahk
#Include PS.ahk
#Include EPIC.ahk

#Include GUI.ahk
#Include Help.ahk

#Include Hotkeys.ahk

; for debugging
#Include <Peep.v2>				; for debugging
#Include Debug.ahk




/**********************************************************
 * Auto execute section
 * This is where PACS Assistant execution starts.
 * 
*/


; debug
; MsgBox("`nA_WorkingDir=" A_WorkingDir "`nA_ScriptDir=" A_ScriptDir "`n" "`nA_UserName=" A_UserName "`nA_UserDir=" A_UserDir "`nA_ProgramFiles=" A_ProgramFiles "`nA_ProgramFiles=" A_ProgramFiles_x86 "`nA_Desktop=" A_Desktop "`nA_MyDocuments=" A_MyDocuments)


; Main entry point for starting PACS Assistant, call PAMain();
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
 * Hook functions called on PACS Assistant events
 */


; Hook function called when PS main window opens
; PAShow_main(hwnd, hook, dwmsEventTime) {
; 	App["PA"].Win["main"].hwnd := hwnd

; 	; crit := hook.MatchCriteria[1]
; 	; text := hook.MatchCriteria[2]

; ;TTip("PAShow_main(" hwnd ": ('" crit "','" text "')")
; 	if Setting["Debug"].enabled
; 		PlaySound("PACS Assistant show main")

; }




/**********************************************************
 * Local functions defined by this module
 * 
 */




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
 *  Initialization and main functions for PACS Assistant
 */


; Called once at startup to do necessary initialization
;
PAInit() {
	global App
	global PollShow
	global PollClose
	gLobal Layout

	; Call Updater to update this program file.
	Updater()

	; Initialize systemwide settings
	SettingsInit()
	
	; Read current layout from user's settings.ini file
    Layout[Setting["Layout"].value].Read(Setting["Layout"].value)        ; read from .ini file

	; Register Windows hooks to monitor window show events for all the windows of interest.
	; Set up arrays of windows that need to be polled for hook_show and hook_close calls.
	for appkey, a in App {
		for wkey, w in a.Win {
			if !w.parentwindow {
				; this is a real window
				if w.criteria {
					; it has search criteria
					if w.hook_show {
						; it has a show hook, so register it
						if w.pollflag {
							; this requires polling, add this window (WinItem) to the polling queue for show callbacks
							PollShow.Push(w)
						} else {
							; use the Windows event system, register a WinEvent.Show callback
							WinEvent.Show(w.hook_show, w.criteria, , w.wintext)
						}
					}
					if w.hook_close {
						; close hooks all require polling, add this window (WinItem) to the polling queue for close callbacks
						PollClose.Push(w)
					}
				}
			} else {
				; this is a pseudowindow, always requires polling (so ignore pollflag value)
				if w.hook_show {
					; add this window (WinItem) to the polling queue for show callbacks
					PollShow.Push(w)
				}
				if w.hook_close {
					; close hooks all require polling, add this window (WinItem) to the polling queue for close callbacks
					PollClose.Push(w)
				}
			}
		}
	}

	; Read ICD code file
	ICDReadCodeFile()

	; Get Windows system double click setting - [todo] move this somewhere else
	PA_DoubleClickSetting := DllCall("GetDoubleClickTime")

}


; Replaces the system tray icon, right-click menu, and tooltip.
;
; Copied from https://github.com/Nigh/ahk-autoupdate-template/blob/main/tray.ahk
SetTray() {
	
    ; returns a function that runs the specified webpage
    gotoWebpage_maker(url) {
        webpage(*) {
            Run(url)
        }
        return webpage
    }

    ; exit the application
	quit_pa(*) {
TTip("Quit PACS Assistant")
;		trueExit("", "")
	}

    ; set PACS Assistant tray icon
	TraySetIcon("PA.ico")


    ; create the tray menu
	tray := A_TrayMenu

;    tray.delete

;	tray.add("v" . version, (*) => {})

    ; tray.add()
	; tray.add("Github ahk-autoupdate-template", gotoWebpage_maker("https://github.com/Nigh/ahk-autoupdate-template"))
    ; tray.add("Other", other_callback(ItemName, ItemPos, MenuRef))

    ; tray.add()
	; tray.add("Quit PACS Assistant", quit_pa)
	; tray.ClickCount := 1

    ; set tray icon's tooltip
    A_IconTip := "PACS Assistant`n" . A_Version . (A_IsCompiled ? "c" : "")

}


; Main function for PACS Assistant
;
PAMain() {
	
	; set PACS Assistant tray icon, right-click menu, and tooltip
	SetTray()

	; PACS Assistant basic set up
	PAInit()

	; Set up and show GUI
	GUIMain()

    ; Start daemons
    DaemonInit()

	; Check for a username. 
	; If no current username, post an alert 
	if !CurrentUserCredentials.username {
		GUIAlert("To get started, enter your username and password on the Settings page.", "green")
		PAShowSettings()
	} 

	; Display informational alerts the first time PA is run
	n := Setting["run"].value
	if n < 1 {
		GUIAlert("Tabs on the left side navigate between Home, Window Manager, Settings, and Help pages. Icons on the right side start and stop applications, left click to start, right click menu to stop.", "blue")
		; GUIAlert("Icons on the right side start and stop applications. Left click to start. Right click to stop. 🡪", "blue")
		GUIAlert("⮦ On/Off toggle switch on the lower left enables/disables many PACS Assistant functions", "blue")
		Setting["run"].value := n + 1
	}

}
