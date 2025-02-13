/**
 * PAEPIC.ahk
 *
 * Functions for working with Epic
 *
 *
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <FindText>
#Include PAFindTextStrings.ahk

#Include PAGlobals.ahk
#Include PASound.ahk




/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * Functions to send info to Epic
 */


; Send keystrokes to Epic
;
EPICSend(cmdstring := "") {
    global PAWindowBusy

	if PAActive && cmdstring {
		if hwndEPIC := PAWindows["EPIC"]["main"].hwnd {
			; at this point hwndPS is non-null and points to the current PS window
			PAWindowBusy := true
			BlockInput true				; prevent user input from interfering
			WinActivate(hwndEPIC)
			Send(cmdstring)
			BlockInput false
			PAWindowBusy := false
		}
	}
}



/**********************************************************
 * Functions to retrieve info about Epic
 */


; Returns the status of Epic
;
; Returns TRUE if Epic is running, FALSE if not
;
EPICIsRunning() {
	PAWindows.Update("EPIC")
	return PAWindows["EPIC"]["main"].hwnd ? true : false
}


; Several functions below that return true if a specific EPIC page is showing
; EPIC pages are: login, timezone, chart
;
; FindText() searches entire Epic window ([todo] could narrow the search to speed up slightly)
;


; Returns true if the Epic login page is showing
;
EPICIsLogin() {
	if hwndEPIC := PAWindows["EPIC"]["main"].hwnd {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsLogin"]) {
	;PASound("EPIC Is Login")	; debug
				return true
			}
		} catch {
		}
	}
	return false
}

; Returns true if the Epic time zone confirmation page is showing
;
EPICIsTimezone() {
	if (hwndEPIC := PAWindows["EPIC"]["main"].hwnd) {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsTimezone"]) {
	;PASound("EPIC Is Timezone")	; debug
				return true
			}
		} catch {
		}
	}
	return false
}


; Returns true if the Epic main chart page is showing
;
EPICIsChart() {
	if hwndEPIC := PAWindows["EPIC"]["main"].hwnd {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsChart"]) {
	;PASound("EPIC Is chart")
				return true
			}
		} catch {
		}
	}
	return false
}



/**********************************************************
 * Hook functions called on Epic events
 */


; Hook function called when EPIC main window opens
;
; When the Epic main window appears
EPICOpened_EPICmain() {

	PASound("Epic opened")

	if PASettings["EPIC_restoreatopen"].value {
		; Restore EPIC window positions
		PAWindows.RestoreWindows("EPIC")
	}
	
	if PASettings["EPICtimezone_dismiss"].value {
		; launch daemon to look for and dismiss timezone window
		_EPIC_DismissTimezone(true)	; call directly to initialize the callback
		SetTimer(_EPIC_DismissTimezone, 500)
	}
}


; Hook function called when EPIC main window closed or minimized
;
EPICClosed_EPICmain() {
	PASound("Epic closed")
}


; Helper function to look for and dismiss timezone window,
; setting the time zone to America/Chicago
;
_EPIC_DismissTimezone(initial := false) {
	static tick0 := 0

	if initial {
		tick0 := A_TickCount
		return
	}

	if EPICIsTimezone() {
		EPICSend(EPIC_TIMEZONE . "{Enter}")				; dismiss Timezone dialog with Continue (Alt-O)
		SetTimer(_EPIC_DismissTimezone, 0)
	} else if (A_TickCount - tick0) > EPIC_LOGIN_TIMEOUT * 1000 {
		; timed out, stop checking
		SetTimer(_EPIC_DismissTimezone, 0)
	}

}




/**********************************************************
 * Start up and Shut down functions
 * 
 */



; Start Epic
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If Epic is already running, returns immediately with return value 1.
;
; Returns 1 if successful at starting Epic, 0 if not
; 
EPICStart(cred := CurrentUserCredentials) {
	global PAWindowBusy
	global PACancelRequest
	static running := false
	
	; if EPICStart() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if EPIC is not running, immediately return success
	if EPICIsRunning() {
		PAStatus("Epic is already running")
		running := false
		return 1
	}

	; Start Epic

	result := 0
	cancelled := false
	failed := false
	tick0 := A_TickCount
	PAStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")

	PAGui_ShowCancelButton()

	; prevent focus following
	PAWindowBusy := true

	Run('"' . EXE_EPIC . '" env="PRD"')
	PAWindows.Update("EPIC")

	while !cancelled && !(hwndEPIC := PAWindows["EPIC"]["main"].hwnd) && (A_TickCount - tick0 < EPIC_LOGIN_TIMEOUT * 1000) {
		PAStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		Sleep(500)
		PAWindows.Update("EPIC")
		if PACancelRequest {
				cancelled := true
				break		; while
		}
	}

	if !cancelled && hwndEPIC {
		; wait for login window to be exist
		tick1 := A_TickCount
		while !cancelled && !(islogin := EPICIsLogin()) && (A_TickCount - tick1 < EI_LOGIN_TIMEOUT * 1000) {
			PAStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
			Sleep(500)
			PAWindows.Update("EPIC")
			if PACancelRequest {
					cancelled := true
					break		; while
			}
		}

		if !cancelled && islogin {
			; got a login window, now enter credentials

			; locate the username field
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			ok := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICLoginUser"])
			if ok {
				; enter the username

				CoordMode("Mouse", "Screen")
				BlockInput true				; prevent user input from interfering
				MouseGetPos(&savex, &savey)	; save current mouse position

				Click(ok[1].x, ok[1].y)
				Send("^a" . cred.username)

				; locate the password field
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
				ok := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICLoginPassword"])
				if ok {
					; enter the password and press OK to start login
					Click(ok[1].x, ok[1].y)
					Send("^a" . cred.password)
					Send("!o")					; Presses OK key (Alt-O) to start login
				}

				MouseMove(savex, savey)		; restore mouse position
				BlockInput false

				; now wait for Epic to get past the time zone screen to consider login successful
				while !cancelled && !(istimezone := EPICIsTimezone()) && !(ischart := EPICIsChart()) && (A_TickCount - tick1 < EI_LOGIN_TIMEOUT * 1000) {
					PAStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
					Sleep(500)
					PAWindows.Update("EPIC")
					if PACancelRequest {
							cancelled := true
							break		; while
					}
				}
				; now wait for Epic to get to the chart screen
				while !cancelled && !(ischart := EPICIsChart()) && (A_TickCount - tick1 < EI_LOGIN_TIMEOUT * 1000) {
					PAStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
					Sleep(500)
					PAWindows.Update("EPIC")
					if PACancelRequest {
							cancelled := true
							break		; while
					}
				}
				if !ischart {
					failed := true
				}
			}
		}
	}	
	
	PAGui_HideCancelButton()

	if cancelled {
		PAStatus("EPIC startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else if failed {
		PAStatus("Could not start EPIC (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else {
		PAStatus("EPIC startup completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1
	}
	
	PAWindowBusy := false	; restore focus following

	; done
	running := false
	return result
}


; Shut down Epic
;
; Log out, close application.
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If Epic is already not running, returns immediately with return value 1.
;
; Returns 1 if successful, 0 if not
; 
EPICStop() {
	global PAWindowBusy
	global PACancelRequest
	static running := false
	
	; if EPICStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if EPIC is not running, immediately return success
	if !EPICIsRunning() {
		PAStatus("Epic is not running")
		running := false
		return 1
	}

	cancelled := false
	failed := false
	tick0 := A_TickCount
	PAStatus("Shutting down Epic...")

	PAGui_ShowCancelButton()

	; prevent focus following
	PAWindowBusy := true

	; close Epic
	hwndEPIC := PAWindows["EPIC"]["main"].hwnd
    if hwndEPIC {
        WinClose(hwndEPIC)
    }

	; wait for Epic main window to go away
	while !cancelled && PAWindows["EPIC"]["main"].hwnd && (A_TickCount-tick0 < EPIC_SHUTDOWN_TIMEOUT * 1000) {
		PAStatus("Shutting down Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		sleep(500)
		PAWindows.Update("EPIC")
		if PACancelRequest {
			cancelled := true
			break		; while
		}
	}

	if PAWindows["EPIC"]["main"].hwnd {
		failed := true
	}

	PAGui_HideCancelButton()

	if cancelled {
		PAStatus("EPIC shut down cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else if failed {
		PAStatus("Could not shut down EPIC (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else {
		PAStatus("EPIC shut down completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1
	}
	
	PAWindowBusy := false	; restore focus following

	; done
	running := false
	return result
}




/**********************************************************
 * Epic data retrieval and parsing functions
 *  
 */






/**********************************************************
 * Epic Commands
 *  
 */

