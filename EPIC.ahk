/**
 * EPIC.ahk
 *
 * Functions for working with Epic
 *
 *
 * This module defines the functions:
 * 
 * 	EPICSend(cmdstring := "")					- 
 * 
 * 	EPICIsRunning()								- Returns TRUE if Epic is running, FALSE if not
 * 	EPICIsLogin()								- Returns true if the Epic login page is showing
 * 	EPICIsTimezone()							- Returns true if the Epic time zone confirmation page is showing
 * 	EPICIsChart()								- Returns true if the Epic main chart page is showing
 * 
 * 	EPICOpened_EPICmain()						- Hook functions
 * 	EPICClosed_EPICmain()						- 
 * 
 * 	EPICStart(cred := CurrentUserCredentials)	- Start Epic
 * 	EPICStop()									- EPICStop()
 * 
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
 * Global variables and constants used in this module
 */




/**********************************************************
 * Functions to send data to Epic
 */


; Send keystrokes to Epic
;
EPICSend(cmdstring := "") {
    global PAWindowBusy

	if PAActive && cmdstring {
		if hwndEPIC := App["EPIC"].Win["main"].hwnd {
			; at this point hwndPS is non-null and points to the current PS window
			PAWindowBusy := true
			BlockInput true				; prevent user input from interfering
			WinActivate(hwndEPIC)
			Sleep(200)
			Send(cmdstring)
			BlockInput false
			PAWindowBusy := false
		}
	}
}


; Helper function to look for and dismiss timezone window,
; setting the time zone to America/Chicago
;
_EPIC_DismissTimezone(initialize := false) {
	static tick0 := 0

	if initialize {
TTip("0")
		tick0 := A_TickCount
		return					; return after initializing
	}

	if EPICIsTimezone() {
		; dismiss Timezone dialog with Continue (Alt-O)
TTip("a")
		EPICSend("{Alt down}o{Alt up}")
		SetTimer(_EPIC_DismissTimezone, 0)
	} else if (A_TickCount - tick0) > EPIC_LOGIN_TIMEOUT * 1000 {
		; timed out, stop checking
TTip("b")
		SetTimer(_EPIC_DismissTimezone, 0)
	} else {
TTip("c")
	}
}


; Helper function to look for and dismmiss Break the Glass dialog window.
; Reason is Direct Patient Care.
; Requires password to be set
_EPICBreakTheGlass() {

	; look for the window


	; Alt-R goes to the Reason field
	; Send the keys "d{Tab}" to put "Direct Patient Care" into the field

	; Alt-P goes to the Password field
	; Send the user's password, followed by "{Enter}" to complete the dialog.


}




/**********************************************************
 * Functions to retrieve info about Epic
 */


; Returns TRUE if Epic is running, FALSE if not
;
EPICIsRunning() {
	return App["EPIC"].isrunning
}


; Several functions below that return true if a specific EPIC page is showing
; EPIC pages are: login, timezone, chart
;
; FindText() searches entire Epic window ([todo] could narrow the search to speed up slightly)
;


; Returns true if the Epic login page is showing
;
EPICIsLogin() {
	; App["EPIC"].Win["main"].Update()
	if hwndEPIC := App["EPIC"].Win["main"].hwnd {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsLogin"]) {
TTip("EPICIsLogin")
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
	; App["EPIC"].Win["main"].Update()
	if hwndEPIC := App["EPIC"].Win["main"].hwnd {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsTimezone"]) {
TTip("EPICIsTimezone")
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
	; App["EPIC"].Win["main"].Update()
	if hwndEPIC := App["EPIC"].Win["main"].hwnd {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndEPIC)
			if FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EPICIsChart"]) {
TTip("EPICIsChart")
				return true
			}
		} catch {
		}
	}
	return false
}




/**********************************************************
 * Callback functions called on Network window events
 */


EPICShow_main(hwnd, hook, dwmsEventTime)
{
	App["EPIC"].Win["main"].hwnd := hwnd
	PlaySound("EPIC show main")
}

EPICShow_chat(hwnd, hook, dwmsEventTime)
{
	App["EPIC"].Win["chat"].hwnd := hwnd
	PlaySound("EPIC show chat")
}




/**********************************************************
 * Hook functions called on Epic events
 */


; Hook function called when EPIC main window opens
;
; When the Epic main window appears
EPICOpened_EPICmain() {

	PlaySound("Epic started")

	if Setting["EPIC_restoreatopen"].value {
		; Restore EPIC window positions
		App["EPIC"].RestorePositions()
	}
	
	if Setting["EPICtimezone_dismiss"].value {
		; launch daemon to look for and dismiss timezone window
		_EPIC_DismissTimezone(true)	; call directly to initialize the callback
		SetTimer(_EPIC_DismissTimezone, 500)
	}
}


; Hook function called when EPIC main window closed or minimized
;
EPICClosed_EPICmain() {
	PlaySound("Epic closed")
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

	; if EPIC is already running, immediately return success
	if EPICIsRunning() {
		GUIStatus("Epic is already running")
		running := false
		return 1
	}

	; if no username, ask user before proceeding
	if !cred.username && !GUIGetUsername() {
		; couldn't get a username from the user, return failure (0)
		GUIStatus("Could not start Epic - username needed")
		running := false
		return 0
	}
	
	; if no password, ask user before proceeding
	if !cred.Password && !GUIGetPassword() {
		; couldn't get a password from the user, return failure (0)
		GUIStatus("Could not start Epic - password needed")
		running := false
		return 0
	}
	cred.password := CurrentUserCredentials.password
	
	; Start Epic
	GUIStatus("Starting Epic...")
	tick0 := A_TickCount
	cancelled := false
	failed := false

	; prevent focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; run Epic
	; Run('"' . EXE_EPIC . '" env="PRD"')
	Run('"' . EXE_EPIC . '" ' . EPIC_CLIOPTIONS)
	Sleep(1000)
	; App["EPIC"].Update()

	; wait for login window to exist
	while !cancelled && !(islogin := EPICIsLogin()) && (A_TickCount - tick0 < EPIC_LOGIN_TIMEOUT * 1000) {
		GUIStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		Sleep(500)
		if PACancelRequest {
				cancelled := true
				break		; while
		}
	}

	; if couldn't get to the login window, return with failure
	if !islogin {
		failed := true
	}

	if !cancelled && !failed {
		; got a login window, now enter credentials
		Sleep(500)

		; locate the username field
		hwndEPIC := App["EPIC"].Win["main"].hwnd
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
			} else {
				; couldn't find the password field
				failed := true
			}

			MouseMove(savex, savey)		; restore mouse position
			BlockInput false

			if PACancelRequest {
				cancelled := true
			}

			; now wait for Epic to get to the chart screen to consider login successful
			while !cancelled && !failed && !(ischart := EPICIsChart()) && (A_TickCount - tick0 < EPIC_LOGIN_TIMEOUT * 1000) {
				GUIStatus("Starting Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				Sleep(500)
				; App["EPIC"].Update()		; unncessary to update
				if PACancelRequest {
					cancelled := true
					break		; while
				}
			}
			; if couldn't get to the login window, return with failure
			if !ischart {
				failed := true
			}

		} else {

			; couldn't find the username field
			failed := true

		}
	}	
	
	GUIHideCancelButton()

	if cancelled {

		; user cancelled
		GUIStatus("EPIC startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else if failed {

		GUIStatus("Could not start EPIC (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else {

		GUIStatus("EPIC startup completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1

	}
	
	; restore focus following
	PAWindowBusy := false

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
		GUIStatus("Epic is not running")
		running := false
		return 1
	}

	cancelled := false
	failed := false
	tick0 := A_TickCount
	GUIStatus("Shutting down Epic...")

	GUIShowCancelButton()

	; prevent focus following
	PAWindowBusy := true

	; close Epic
	hwndEPIC := App["EPIC"].Win["main"].hwnd
    if hwndEPIC {
        WinClose(hwndEPIC)
    }

	; wait for Epic main window to go away
	while !cancelled && App["EPIC"].Win["main"].hwnd && (A_TickCount-tick0 < EPIC_SHUTDOWN_TIMEOUT * 1000) {
		GUIStatus("Shutting down Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		sleep(500)
		; App["EPIC"].Update()
		if PACancelRequest {
			cancelled := true
			break		; while
		}
	}

	if App["EPIC"].Win["main"].hwnd {
		failed := true
	}

	GUIHideCancelButton()

	if cancelled {
		GUIStatus("EPIC shut down cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else if failed {
		GUIStatus("Could not shut down EPIC (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	} else {
		GUIStatus("EPIC shut down completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
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

