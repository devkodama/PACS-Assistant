/* PAEPIC.ahk
**
** Utility scripts for working with Epic
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force


/*
** Includes
*/

#Include <FindText>
#Include PAFindTextStrings.ahk

#Include PAGlobals.ahk

/*
** Global variables and constants used in this module
*/




/***********************************************/

; Send keystroke commands to Epic
;
; PSSend(cmdstring := "") {
;     global PA_WindowBusy

; 	if (cmdstring) {
; 		if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) {
; 			return
; 		}

; 		; at this point hwndPS is non-null and points to the current PS window
; 		PA_WindowBusy := true
; 		WinActivate(hwndPS)
; 		Send(cmdstring)
; 		PA_WindowBusy := false
; 	}
; }



; Returns the state of the PS360 Dictate button by reading the toolbar button
; The Dicate button must be visible on screen
; 
; If the Dictate button is On, returns true
; Otherwise returns false
;
; Search PS360 client window area from (0,16) to (width, 128). The toolbar
; button should be within this area.
;
; Dictate status is cached, only checked every WATCHDICTATE_UPDATE_INTERVAL
;
; PSDictateIsOn() {
; 	static dictatestatus := false
; 	static lastcheck := A_TickCount

; 	; if PS report or main window does not exist, return false
; 	if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) {
; 		dictatestatus := false
; 	}

; 	if (A_TickCount - lastcheck) > WATCHDICTATE_UPDATE_INTERVAL {
; 		try {
; 			WinGetClientPos(&x0, &y0, &w0, &h0, hwndPS)
; 			if FindText(&x, &y, x0, y0 + 16, x0 + w0, y0 + 128, 0.001, 0.001, PAText["PSDictateOn"]) {
; 				dictatestatus := true
; 			} else {
; 				dictatestatus := false
; 			}
; 		} catch {
; 			dictatestatus := false
; 		}
; 		lastcheck := A_TickCount
; 	}

; 	return dictatestatus
; }



/***********************************************/


; Hook function called when EPIC main window opens
;
; When the Epic main window appears
EPICOpened_EPICmain() {

	PASound("Epic opened")

	; launch daemon to monitor for login window and timezone window


}


; Hook function called when EPIC main window opens
;
; When the Epic main window appears
EPICClosed_EPICmain() {

	PASound("Epic closed")
}



/***********************************************/


; Returns the status of Epic
;
; Returns TRUE if Epic is running, FALSE if not
;
EPICIsRunning() {
	global PAWindows

	PAWindows.Update("EPIC")
	hwndEPIC := PAWindows["EPIC"]["main"].hwnd

	return hwndEPIC ? true : false
}


; Functions that return true if a specific EPIC page is showing
;
; EPIC pages are: login, timezone, chart
;
EPICIsLogin() {
	if EPIChwnd := PAWindows["EPIC"]["main"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, EPIChwnd)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EPICIsLogin"]) {
			return true
		}
	}
	return false
}

EPICIsTimezone() {
	if EPIChwnd := PAWindows["EPIC"]["main"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, EPIChwnd)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EPICIsTimezone"]) {
			return true
		}
	}
	return false
}

EPICIsChart() {
	if EPIChwnd := PAWindows["EPIC"]["main"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, EPIChwnd)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EPICIsChart"]) {
			return true
		}
	}
	return false
}



/***********************************************/

/**
 * Start up and Shut down functions
 * 
 */


; [todo] Start Epic
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If Epic is already running, returns immediately with return value 1.
;
; Returns 1 if successful at starting Epic, 0 if not
; 
EPICStart() {
	global PA_Active
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

	; don't want automatic activation of window under mouse while trying to stop Epic
	savePA_Active := PA_Active
	PA_Active := false

	tick0 := A_TickCount
	PAStatus("Starting Epic...")
	


; start Epic here



	; restore previous PA_Active status
	PA_Active := savePA_Active

	if !PAWindows["EPIC"]["main"].hwnd {
		; Epic desktop window is still not opened
		PAStatus("Could not start Epic (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	} else {
		PAStatus("Epic started (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; done
	running := false
	return 1
}


; Stop Epic
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If Epic is already not running, returns immediately with return value 1.
;
; Returns 1 if successful, 0 if not
; 
EPICStop() {
	global PA_Active
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

	; don't want automatic activation of window under mouse while trying to stop Epic
	savePA_Active := PA_Active
	PA_Active := false

	tick0 := A_TickCount
	PAStatus("Shutting down Epic...")
	
	; close Epic
	hwndEPIC := PAWindows["EPIC"]["main"].hwnd
    if hwndEPIC {
        WinClose(hwndEPIC)
    }
	
	; wait for Epic main window to go away
	tick0 := A_TickCount
	loop {
		sleep(500)
		PAStatus("Shutting down Epic... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		PAWindows.Update("EPIC")
	} until !PAWindows["EPIC"]["main"].hwnd || (A_TickCount-tick0 > EPIC_SHUTDOWN_TIMEOUT * 1000) 

	; restore previous PA_Active status
	PA_Active := savePA_Active

	if PAWindows["EPIC"]["main"].hwnd {
		; Epic desktop window is still not closed
		PAStatus("Could not shut down Epic (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	} else {
		PAStatus("Epic shut down (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; done
	running := false
	return 1
}
