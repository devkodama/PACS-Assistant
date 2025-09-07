/**
 * PS.ahk
 *
 * Functions for working with PowerScribe
 *
 *
 * This module defines the functions:
 * 
 * 	PSSend(cmdstring := "")					- Send keystrokes to PowerScribe
 * 	PSPaste(text := "")						- Paste a chunk of text into PowerScribe
 * 
 * 	PSParent()								- Returns the WinItem for either PSmain, PSreport, PSaddendum, or PSlogin, if one exists
 * 
 * 	PSDictateIsOn(forceupdate := false)		- Returns the state of the PS360 Dictate (mic) button
 * 	PSIsRunning()							- Returns TRUE if PS is running, FALSE if not
 * 	PSIsLogin()
 * 	PSIsMain()
 * 	PSIsReport()
 * 	
 * 	PSShow_main()							- Callback functions
 * 	PSShow_recognition()
 * 	PSShow_logout()
 * 	PSShow_savespeech()
 * 	PSShow_savereport()
 * 	PSShow_deletereport()
 * 	PSShow_unfilled()
 * 	PSShow_confirmaddendum()
 * 	PSShow_confirmanotheraddendum()
 * 	PSShow_existing()
 * 	PSShow_continue()
 * 	PSShow_ownership()
 * 	PSShow_microphone()
 * 	PSShow_find()
 * 	PSShow_spelling()
 * 
 * 	PSStart(cred := CurrentUserCredentials)	- Start up PowerScribe
 * 	PSStop()								- Shut down PowerScribe
 * 
 * 	RetrieveDataPS()						- Retrieves obtainable data from PowerScribe main reporting window
 * 
 * 	PSCmdNextField()						- Send the Next field command (Tab) to PS
 * 	PSCmdPrevField()						- Send the Prev field command (Shift-Tab) to PS
 * 	PSCmdEOL()								- Move the cursor to the End of Line in PS
 * 	PSCmdNextEOL()							- Move the cursor down one line then to the End of Line in PS
 * 	PSCmdPrevEOL()							- Move the cursor up one line then to the End of Line in PS
 * 	PSCmdToggleMic()						- Start/Stop Dictation (Toggle Microphone) => F4 in PS
 * 	PSCmdSignReport()						- Sign report => F12 in PS
 * 	PSCmdDraftReport()						- Save as Draft => F9 in PS
 * 	PSCmdPreliminary()						- Save as Prelim => File > Prelim in PS
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */

/*
#Include <FindText>
#Include FindTextStrings.ahk

#Include Globals.ahk
#Include PASound.ahk
*/



/**********************************************************
 * Global variables and constants used in this module
 */


; This is used internally by _PSStopDictate() to determine whether to turn off the mic
global _Dictate_autooff := false

; This holds the most recent parent window (login, main, report, or addendum) before the current one.
; If PS was not running, holds a blank string.
global _PSlastparent := ""



/**********************************************************
 * Functions to send data to PS
 * 
 */


; Send keystrokes to PowerScribe.
PSSend(cmdstring := "") {
    global PAWindowBusy

	if (cmdstring) {
		hwndPS := App["PS"].Win["main"].hwnd
		if hwndPS {
			; at this point hwndPS is non-null and points to the main PS window
			PAWindowBusy := true
			WinActivate(hwndPS)
			Send(cmdstring)
			PAWindowBusy := false
		}
	}

}


; Paste a chunk of text into PowerScribe
;
; Ensures either the PS report window, addendum window, or main window will be receiving the paste.
;
; Uses the clipboard, restoring the previous clipboard contents when finished.
PSPaste(text := "") {
    global PAWindowBusy

	if (text) {

		if !(hwndPS := App["PS"].Win["report"].IsReady()) && !(hwndPS := App["PS"].Win["main"].IsReady()) && !(hwndPS := App["PS"].Win["addendum"].IsReady()) {
			return
		}

		; at this point hwndPS is non-null and points to the current PS window
		PAWindowBusy := true
		saveclipboard := A_Clipboard
		A_Clipboard := text
		WinActivate(hwndPS)
		SendInput("^v")				; paste the text
		Sleep(100)					; requires a delay before restoring keyboard, or else the ^v paste will send the wrong contents (the saved clipboard)
		A_Clipboard := saveclipboard
		PAWindowBusy := false
	}
}



/**********************************************************
 * Functions to retrieve info about PS
 */


; Returns the WinItem for either PSmain, PSreport, PSaddendum, or PSlogin, 
; if they exist (checked in that order).
;
; Returns 0 if none of them exist.
; [todo][need to deprecate this]
PSParent() {
	if App["PS"].Win["main"].hwnd {
		return App["PS"].Win["main"]
	} else if App["PS"].Win["report"].hwnd {
		return App["PS"].Win["report"]
	} else if App["PS"].Win["addendum"].hwnd {
		return App["PS"].Win["addendum"]
	} else if App["PS"].Win["login"].hwnd {
		return App["PS"].Win["login"]
	} else {
		return 0
	}
}


; Returns the state of the PS360 Dictate (mic) button by reading the toolbar button
; The Dicate button must be visible on screen
;
; If the Dictate button is found and is On, returns true.
;
; Otherwise return false.
;
; Search PS360 client window area from (0,16) to (width, 128). The toolbar
; button should be within this area.
;
; Dictate status is cached, only checked every WATCHDICTATE_UPDATE_INTERVAL,
; unless forceupdate is true.
;
; This function also turns off the microphone after an idle timeout, if
; enabled by PASettings["PS_dictate_idleoff"]. It does so by tracking the
; time since the last physical keyboard or mouse activity. This functionality
; depends upon this function being called sufficiently frequently (as it typically is by PADaemon()).
PSDictateIsOn(forceupdate := false) {
	static dictatestatus := false
	static lastcheck := 0

	; If one of PS report, addendum, or main windows does not exist, return false
	if !(hwndPS := App["PS"].Win["report"].IsReady()) && !(hwndPS := App["PS"].Win["main"].IsReady()) && !(hwndPS := App["PS"].Win["addendum"].IsReady()) {
		dictatestatus := false

	} else if forceupdate || ((A_TickCount - lastcheck) > WATCHDICTATE_UPDATE_INTERVAL) {
		try {
			; search window for dictate on button icon using FindText()
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndPS)
			if FindText(&x, &y, x0, y0 + 16, x0 + w0, y0 + 128, 0.001, 0.001, PAText["PSDictateOn"]) {
				; dictate button is on
				dictatestatus := true
				if Setting["PS_dictate_idleoff"].enabled {
					; Turn off mic if no keyboard or mouse activity for a prolonged time.
					; A_TimeIdlePhysical is the number of milliseconds that have elapsed since the system last received physical keyboard or mouse input
					; PASettings["PS_dictate_idletimeout"].value is in minutes, so multiply by 60000 to get milliseconds
					if dictatestatus && A_TimeIdlePhysical > (Setting["PS_dictate_idletimeout"].value * 60000) {
						; microphone is currently on and we have idled for greater than timeout, so turn off the mic
						PSSend("{F4}")		; Stop Dictation
						GUIStatus("Microphone turned off")
						dictatestatus := false
					}
				}
			} else {
				dictatestatus := false
			}
			lastcheck := A_TickCount
		} catch {
			dictatestatus := false
		}
	}

	return dictatestatus
}


; Returns TRUE if PS is running, FALSE if not
PSIsRunning() {
	return App["PS"].isrunning
}


; Detect whether a specific PS pseudowindow is showing.
;
; These	PS pseudowindows are subwindows of main: login, home, report, addendum
;
; Returns the hwnd of the parent window if the pseudowindow is showing, 0 if not.
PSIsLogin() {
	PShwnd := App["PS"].Win["main"].IsReady() 
	if PShwnd {
		; look for the wintext string within the PS main window
		try {
			if InStr(WinGetText(PShwnd), App["PS"].Win["login"].wintext) {
				; found the wintext string, return the hwnd of the parent window
				return PShwnd
			}
		} catch { 
		}
	}
	return 0
}
PSIsHome() {
	PShwnd := App["PS"].Win["main"].IsReady() 
	if PShwnd {
		; look for the wintext string within the PS main window
		try {
			if InStr(WinGetText(PShwnd), App["PS"].Win["home"].wintext) {
				; found the wintext string, return the hwnd of the parent window
				return PShwnd
			}
		} catch { 
		}
	}
	return 0
}
PSIsReport() {
	PShwnd := App["PS"].Win["main"].IsReady() 
	if PShwnd {
		; look for the wintext string within the PS main window
		try {
			if InStr(WinGetText(PShwnd), App["PS"].Win["report"].wintext) {
				; found the wintext string, return the hwnd of the parent window
				return PShwnd
			}
		} catch { 
		}
	}
	return 0
}
PSIsAddendum() {
	PShwnd := App["PS"].Win["main"].IsReady() 
	if PShwnd {
		; look for the wintext string within the PS main window
		try {
			if InStr(WinGetText(PShwnd), App["PS"].Win["addendum"].wintext) {
				; found the wintext string, return the hwnd of the parent window
				return PShwnd
			}
		} catch { 
		}
	}
	return 0
}




/**********************************************************
 * Callback functions called on PS window events
 */


PSShow_main(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["main"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show main")
	if Setting["PS_restoreatopen"].enabled {
		App["PS"].Win["main"].RestorePosition()
	}
}

PSShow_recognition(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["recognition"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show recognition")
}

PSShow_logout(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["logout"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show logout")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["logout"].CenterWindow(App["PS"].Win["main"])
	}
	if Setting["PSlogout_dismiss"].enabled {
		ControlClick(Setting["PSlogout_dismiss_reply"].value, App["PS"].Win["logout"].hwnd)
	}
}

PSShow_savespeech(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["savespeech"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show savespeech")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["savespeech"].CenterWindow(App["PS"].Win["main"])
	}
	if Setting["PSsavespeech_dismiss"].enabled {
		ControlClick(Setting["PSsavespeech_dismiss_reply"].value, App["PS"].Win["savespeech"].hwnd)
	}
}

PSShow_savereport(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["savereport"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show savereport")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["savereport"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_deletereport(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["deletereport"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show deletereport")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["deletereport"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_unfilled(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["unfilled"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show unfilled")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["unfilled"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_confirmaddendum(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["confirmaddendum"].hwnd := hwnd
	if Setting["Debug"].enabled {
		PlaySound("PS show confirmaddendum")
	}
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["confirmaddendum"].CenterWindow(App["PS"].Win["main"])
	}
	if Setting["PSconfirmaddendum_dismiss"].enabled {
		ControlClick(Setting["PSconfirmaddendum_dismiss_reply"].value, App["PS"].Win["confirmaddendum"].hwnd)
	}
}

PSShow_confirmanother(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["confirmanother"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show confirmanother")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["confirmanother"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_existing(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["existing"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show existing")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["existing"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_continue(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["continue"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show continue")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["continue"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_ownership(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["ownership"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show ownership")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["ownership"].CenterWindow(App["PS"].Win["main"])
	}
}

PSShow_microphone(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["microphone"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show microphone")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["microphone"].CenterWindow(App["PS"].Win["main"])
	}
	if Setting["PSmicrophone_dismiss"].value {
		ControlClick(Setting["PSmicrophone_dismiss_reply"].value, App["PS"].Win["microphone"].hwnd)
	}
}

PSShow_ras(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["ras"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show ras")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["ras"].CenterWindow(App["PS"].Win["main"])
	}
	if Setting["PSras_dismiss"].enabled {
		ControlClick(Setting["PSras_dismiss_reply"].value, App["PS"].Win["ras"].hwnd)
		MsgBox("Clicked on " Setting["PSras_dismiss_reply"].value " for ras dialog (" App["PS"].Win["ras"].hwnd ")" )
	}
}

PSShow_find(hwnd, hook, dwmsEventTime) {
	App["PS"].Win["find"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show find")
	if Setting["PScenter_dialog"].enabled {
		App["PS"].Win["find"].CenterWindow(App["PS"].Win["main"])
	}
}


PSSPShow_spelling(hwnd, hook, dwmsEventTime) {
	App["PSSP"].Win["spelling"].hwnd := hwnd
	if Setting["Debug"].enabled
		PlaySound("PS show spelling")
	if Setting["PScenter_dialog"].enabled {
		App["PSSP"].Win["spelling"].CenterWindow(App["PS"].Win["main"])
	}
}



; helper functions to turn on or off the mic, called by PSShow_report() and PSClose_report()
; initial should be set to true the first time this is called
_PSTurnOnMic(initial := false) {
	static cmdsenttime := 0			; timestamp of last command send

	if initial {
		; cancel any pending call to turn off the mic
		SetTimer(_PSTurnOffMic, 0)
		if !PSDictateIsOn(true) {
			; try to turn on the mic
			PSCmdToggleMic()
			cmdsenttime := A_TickCount
			; check every 500 milliseconds
			SetTimer(_PSTurnOnMic, 500)
		} else {
			; mic is already on, don't send toggle mic command, and stop checking
			SetTimer(_PSTurnOnMic, 0)
		}
	} else {
		; Check if the mic is on
		if !PSDictateIsOn(true) {
			; mic is still not on
			; if it's been over PS_DICTATERETRY_DELAY milliseconds, resend toggle mic command
			if (A_TickCount - cmdsenttime) > PS_DICTATERETRY_DELAY {
				PSCmdToggleMic()
				cmdsenttime := A_TickCount
			}
		} else {
			; mic is now on, turn off further checking
			PlaySound("PSToggleMic")
			SetTimer(_PSTurnOnMic, 0)
		}
	}
}

_PSTurnOffMic(initial := false, delay := 0) {
	static cmdsenttime := 0			; timestamp of last command send

	if initial {
		if PSDictateIsOn(true) {
			if delay {
				; wait for delay milliseconds before turning off the mic
				cmdsenttime := A_TickCount - PS_DICTATERETRY_DELAY	; this guarantees we will send the toggle mic command at next fn call
				SetTimer(_PSTurnOffMic, delay)
			} else {
				; try to turn off the mic
				PSCmdToggleMic()
				cmdsenttime := A_TickCount
				; check every 500 milliseconds
				SetTimer(_PSTurnOffMic, 500)
			}
		} else {
			; mic is already off, don't send toggle mic command, and stop checking
			SetTimer(_PSTurnOffMic, 0)
		}
	} else {
		; Check if the mic is off
		if PSDictateIsOn(true) {
			; mic is still not off
			; if it's been over PS_DICTATERETRY_DELAY milliseconds, resend toggle mic command
			if (A_TickCount - cmdsenttime) > PS_DICTATERETRY_DELAY {
				PSCmdToggleMic()
				cmdsenttime := A_TickCount
			}
		} else {
			; mic is now off, turn off further checking
			PlaySound("PSToggleMic")
			SetTimer(_PSTurnOffMic, 0)
		}
	}
}


;
PSShow_login() {
	if Setting["Debug"].enabled
		PlaySound("PS show login")

}

PSClose_login() {
	if Setting["Debug"].enabled
		PlaySound("PS close login")

}

PSShow_home() {
	if Setting["Debug"].enabled
		PlaySound("PS show home")

	; Automatically turn off microphone when closing a report
	if Setting["PS_dictate_autoon"].enabled {
		; turn off the mic if it is on
		_PSTurnOffMic(true, PS_DICTATEAUTOOFF_DELAY)
	}
}

PSClose_home() {
	if Setting["Debug"].enabled
		PlaySound("PS close home")

}

;
PSShow_report() {
	if Setting["Debug"].enabled
		PlaySound("PS show report")

	; Automatically turn on microphone when opening a report
	if Setting["PS_dictate_autoon"].enabled {
		; turn on the mic if it is not on
		_PSTurnOnMic(true)
	}
}

PSClose_report() {
	if Setting["Debug"].enabled
		PlaySound("PS close report")

}

PSShow_addendum() {
	if Setting["Debug"].enabled
		PlaySound("PS show addendum")

	; Automatically turn on microphone when opening a report
	if Setting["PS_dictate_autoon"].enabled {
		; turn on the mic if it is not on
		_PSTurnOnMic(true)
	}
}

PSClose_addendum() {
	if Setting["Debug"].enabled
		PlaySound("PS close addendum")

	; Automatically turn off microphone when closing a report
	if Setting["PS_dictate_autoon"].enabled {
		; turn off the mic if it is on
		_PSTurnOffMic(true)
	}
}


/**********************************************************
 * Hook functions called on PS events
 */


; [todo] need to deprecate these PSOpen_PSreport() and PSClose_PSreport()


; helper function to turn off mic, called by PSOpen_PSreport() and PSClose_PSreport()
; _PSStopDictate() {
; 	if App["PS"].Win["report"].hwnd || App["PS"].Win["main"].hwnd || App["PS"].Win["addendum"].hwnd {
; 		if PSDictateIsOn(true) {
; 			PSSend("{F4}")						; Stop Dictation
; 		}
; 	}
; }


; Hook function called when PS report pseudowindow appears
; PSOpen_PSreport() {
; 	GUIStatus("Report opened")

; 	; Automatically turn on microphone when opening a report (and off when closing a report)
; 	if Setting["PS_dictate_autoon"].value {
; 		; cancel the autooff timer
; 		SetTimer(_PSStopDictate, 0)		; cancel any pending microphone off action	

; 		; check to ensure the mic is on, turn it on if it isn't
; 		; keep trying for up to 5 seconds
; 		tick0 := A_TickCount
; 		while !PSDictateIsOn(true) && (A_TickCount - tick0 < 5000) {			
; 			; mic is not on so turn it on
; 			PSSend("{F4}")						; Start Dictation
; 			Sleep(500)
; 		}
; 		if PSDictateIsOn() {
; 			PlaySound("PSToggleMic")
; 		}
; 	}
; }


; Hook function called when PS report pseudowindow goes away
; PSClose_PSreport() {
; 	global PACurrentStudy
	
; 	GUIStatus("Report closed")

; 	if Setting["PS_dictate_autoon"].value { ;&& PSDictateIsOn(true) {
; 		; Stop dictation afer a delay to see whether user is dictating
; 		; another report (in which case don't turn off dictate mode).
; 		SetTimer(_PSStopDictate, -(PS_DICTATEAUTOOFF_DELAY * 1000))		; turn off mic after brief delay
; 	}
; }




/**********************************************************
 * Start up and Shut down functions
 * 
 */


; Start up PowerScribe
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If PS is already running, returns immediately with return value 1.
;
; Returns 1 if successful at starting PS, 0 if not
; 
PSStart(cred := CurrentUserCredentials) {
	global PAWindowBusy
	global PACancelRequest
	static running := false			; true if PSStart is already running

	; if PSStart() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if PS is aleady up and running, return 1 (true)
	if PSIsRunning() {
		GUIStatus("PowerScribe is already running")
	 	running := false
	 	return 1
	}

	; if no username, ask user before proceeding
	if !cred.username && !GUIGetUsername() {
		; couldn't get a username from the user, return failure (0)
		GUIStatus("Could not start PowerScribe - username needed")
		running := false
		return 0
	}
	
	; if no password, ask user before proceeding
	if !cred.Password && !GUIGetPassword() {
		; couldn't get a password from the user, return failure (0)
		GUIStatus("Could not start PowerScribe - password needed")
		running := false
		return 0
	}
	cred.password := CurrentUserCredentials.password

	; start up PS
	GUIStatus("Starting PowerScribe...")
	tick0 := A_TickCount
	cancelled := false
	failed := false

	; prevent focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; run PS
	Run('"' . EXE_PS . '"')
	Sleep(500)
	; App["PS"].Update()

	; wait for login window to exist
	tick1 := A_TickCount
	while !(hwndlogin := App["PS"].Win["login"].IsReady()) && (A_TickCount - tick1 < PS_LOGIN_TIMEOUT * 1000) {
		GUIStatus("Starting PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		Sleep(500)
		if PACancelRequest {
			cancelled := true
			break		; while
		}
	}

	if !cancelled {

		if !hwndlogin {
			; if PS Login window still not ready after time out, return failure
			failed := true

		} else {
			; PS login window is ready

			; delay to allow enabling of Log On button
			sleep(1000)

;			WinActivate(hwndlogin)

			; Need to wait until "Loading system components..." has completed and text is gone
			; so that Log On button will be enabled
			while (A_TickCount - tick1 < PS_LOGIN_TIMEOUT * 1000) {
				GUIStatus("Starting PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				if !InStr(WinGetText(hwndlogin), "Loading system components", true) {
					; success, exit while
					break		; while
				}
				Sleep(500)
				if PACancelRequest {
					cancelled := true
					break		; while
				}
			}

			if !cancelled {

				; we have a fully loaded login form
				; enter username and password and press OK
				; the r7 is the PS version number, probably requires updating with version upgrades
				BlockInput true
				ControlSetText(cred.username, "WindowsForms10.EDIT.app.0.26ac0ad_r7_ad12", hwndlogin)
				ControlSetText(cred.password, "WindowsForms10.EDIT.app.0.26ac0ad_r7_ad11", hwndlogin)
				ControlClick("WindowsForms10.BUTTON.app.0.26ac0ad_r7_ad12", hwndlogin, , , , "NA") 
				BlockInput false
				
				Sleep(500)

				; waits for PS home window to appear
				tick1 := A_TickCount
				while !cancelled && !(hwndmain := App["PS"].Win["home"].IsReady()) && (A_TickCount - tick1 < PS_MAIN_TIMEOUT * 1000) {
					GUIStatus("Starting PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
					Sleep(500)
					if PACancelRequest {
						cancelled := true
						break		; while
					}
				}

				if !cancelled && !hwndmain {
					; if PS main window still not visible after time out, return failure
					failed := true
				}
			}
		}
	}

	GUIHideCancelButton()

	if cancelled {

		; user cancelled
		GUIStatus("PowerScribe startup cancelled - cleaning up...")

		; in this case, PS may have already been started up
		; if there is a PS process, then need to kill PS process before we exit
		if App["PS"].pid {
			try {
				ProcessClose(App["PS"].pid)
			}
			Sleep(500)
			; App["PS"].Update()
		}

		GUIStatus("PowerScribe startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else if failed {

		; if failure, or if no main window by now, return as failure
		GUIStatus("Could not start PowerScribe (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else {

		; success
		GUIStatus("PowerScribe startup completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1

	}

	; restore focus following
	PAWindowBusy := false

	running := false
	return result
}


; Shut down PowerScribe
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If PS is already stopped, returns immediately with return value 1.
;
; Returns 1 if successful, 0 if not
; 
PSStop() {
	global PACancelRequest
	static running := false			; true if the EIStop is already running

	; if PSStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if PS is not running, immediately return success
	if !PSIsRunning() {
		GUIStatus("PowerScribe is not running")
		running := false
		return 1
	}

	; shut down PS
	GUIStatus("Shutting down PowerScribe...")
	tick0 := A_TickCount

	; prevent focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; close PS
	PSSend("!{F4}")

	result := false
	cancelled := false
	
	; wait for PS to close
	while !cancelled && PSIsRunning() && (A_TickCount-tick0 < PS_SHUTDOWN_TIMEOUT * 1000) {
		GUIStatus("Shutting down PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		Sleep(500)
		; the login window should close automatically when going from main to login
		; if it doesn't, we can close it here
		if PSIsLogin() {
			; We're at the login window. Close it.
			PSSend("!{F4}")
		}
		; App["PS"].Update()
		if PACancelRequest {
			cancelled := true
			break
		}
	}

	GUIHideCancelButton()

	if cancelled {
		GUIStatus("PowerScribe shut down cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := false
	} else if PSIsRunning() {
		; PS still didn't close (timed out)
		GUIStatus("Could not shut down PowerScribe (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := false
	} else {
		GUIStatus("PowerScribe shut down (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := true
	}

	; restore focus following
	PAWindowBusy := false

	; done
	running := false
	return result
}




/**********************************************************
 * PS data retrieval and parsing functions
 *  
 */


; [wip]
;
; Retrieves obtainable data from PowerScribe main reporting window
; Returns parsed data in data map:
;	["firstname"] = Last name
;	["lastname"] = First name
;	["accession"] = "ADV1234567890"
;	["report"] = text of report body
; Returns empty object if no PowerScribe window
;
RetrieveDataPS() {

	hwndPS := WinExist("PowerScribe")
	if (hwndPS) {
		data := Map()

		text :=  WinGetText(hwndPS)

		headerpos := RegExMatch(text, "Report - ([A-Z]+), ([A-Z]+) - (ADV[0-9]+)", &headerobj)

		if (headerpos) {
			data["firstname"] := headerobj[2]
			data["lastname"] := headerobj[1]
			data["accession"] := headerobj[3]

			footerpos := RegExMatch(text, "Findings Only\s+Original Report", &reportobj)
			;msgbox footerpos

			if (footerpos) {
				data["report"] := Trim(SubStr(text, headerpos + headerobj.Len + 2, footerpos - headerpos - headerobj.Len - 2))
				;msgbox headerobj.Len
				;msgbox reportobj.Len
				;msgbox data["report"]

			} else {
				data["report"] := ""
			}
			return data
		}

		return 0		; nothing returned
	}

	return 0		; nothing returned
}




/**********************************************************
 * PS Commands
 *  
 */


; Send the Next field command (Tab) to PS
PSCmdNextField() {
	PSSend("{Tab}")
	PlaySound("PSTab")
}


; Send the Prev field command (Shift-Tab) to PS
PSCmdPrevField() {
	PSSend("{Blind}+{Tab}")
	PlaySound("PSTab")
}


; Move the cursor to the End of Line in PS
PSCmdEOL() {
	PSSend("{End}")
	PlaySound("PSTab")
}


; Move the cursor down one line then to the End of Line in PS
PSCmdNextEOL() {
	PSSend("{Down}{End}")
	PlaySound("PSTab")
}


; Move the cursor up one line then to the End of Line in PS
PSCmdPrevEOL() {
	PSSend("{Up}{End}")
	PlaySound("PSTab")
}


; Start/Stop Dictation (Toggle Microphone) => F4 in PS
PSCmdToggleMic() {
	PSSend("{F4}")							; Start/Stop Dictation
}


; Sign report => F12 in PS
PSCmdSignReport() {
	PSSend("{F12}")							; Sign report
	PlaySound("PSSignReport")
}


; Save as Draft => F9 in PS
PSCmdDraftReport() {
	PSSend("{F9}")							; save as Draft
	PlaySound("PSDraftReport")
}


; Save as Prelim => File > Prelim in PS
PSCmdPreliminary() {
	PSSend("{Alt down}fm{Alt up}")			; save as Prelim
	PlaySound("PSSPreliminary")
}
