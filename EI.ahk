/**
 * EI.ahk
 * 
 * Functions for working with EI
 *
 * 
 * This module defines the functions:
 * 
 * 	EISend(cmdstring := "", targetwindow := "i1")	- Send keystroke commands to EI 
 * 	EIClickDesktop(buttonname)						- Click a button image, specified by buttonname, on the EI Desktop window
 * 	EIClickImages(buttonname)						- Click a button image, specified by buttonname, on the EI Images1 window
 * 
 * 	EIIsRunning()									- Returns TRUE if EI desktop is running, FALSE if not
 * 	EIIsSearch()									- Functions to detect whether a specific EI desktop page is showing
 * 	EIIsList()										- 
 * 	EIIsText()										- 
 * 	EIIsImage()										- 
 * 	EIGetStudyMode()								- Determines which type of study is being displayed in the EI Text page
 * 
 * 	EIOpen_EIdesktop()								- Hook function called when EI desktop window appears
 * 	EIClose_EIdesktop()								- Hook function called when EI desktop window goes away
 * 	
 * 	EIStart(cred := CurrentUserCredentials)			- Start up Enterprise Imaging Desktop
 * 	EIStop()										- Shut down Enterprise Imaging
 * 
 * 	EIRetrievePatientInfo()							- 
 * 	EIRetrieveStudyInfo(patient)					- 
 * 
 * 	EICmdStartReading()								- Send Start reading/Resume reading commands to EI
 * 	EICmdDisplayStudyDetails()						- Display Study Details, by clicking the Study Details icon
 * 	EICmdToggleListText()							- Toggles between the EI desktop Text and List pages
 * 	EICmdShowSearch()								- Shows the Search page on the EI desktop
 * 	EICmdResetSearch()								- Resets the Search page on the EI desktop, places cursor in the patient last name field
 * 	EICmdRemoveFromList()							- Sends the Remove from list command (click on the close icon)
 * 
 * 
 * On a hospital workstation, EI start up requires a working network connection (no VPN).
 * On a home workstation, EI start up requires a VPN connection.
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <FindText>
#Include "FindTextStrings.ahk"

#Include Globals.ahk
#include "PAInfo.ahk"




/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * Functions to interact with EI
 * 
 */


; Send keystroke commands to EI 
;
; Can specify which window to receive the commands. Options are:
;	"desktop"
;	"images1"
;	"images2"
;
; Commands are sent to the images1 window by default.
;
EISend(cmdstring := "", targetwindow := "i1") {
	global PAWindowBusy
	if (cmdstring) {
		switch targetwindow {
			case "i1":
				hwndEI := App["EI"].Win["i1"].hwnd
			case "d":
				hwndEI := App["EI"].Win["d"].hwnd
			case "i2":
				hwndEI := App["EI"].Win["i2"].hwnd
			default:
				hwndEI := App["EI"].Win["i1"].hwnd
		}
		if (hwndEI) {
			PAWindowBusy := true
;			try {
				WinActivate(hwndEI)
				Sleep(200)
				Send(cmdstring)
;			}
			PAWindowBusy := false
		}
	}
}


; Click a button image, specified by buttonname, on the EI Desktop window
;
; Valid button names are:
;	"EISearch"
;	"EIList"
;	"EIText"
;	"EIImage"
;	"EIEpic"
;
;	"EI_DesktopStartReading"
;
; Searches the client area of the EI Desktop window within
; the coordinates (0,32) and (720,80) for the button (image search with FindText)
;
; Returns true if a button was clicked, false if no button was clicked
;
EIClickDesktop(buttonname) {

	result := false

	switch buttonname {
		case "EISearch", "EIList", "EIText", "EIImage", "EIEpic":
			hwndEI := App["EI"].Win["d"].hwnd
			if hwndEI {
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
				if FindText(&x, &y, x0, y0 + 32, x0 + 720, y0 + 80, 0, 0, PAText[buttonname]) {
					PA_WindowBusy := true
					WinActivate(hwndEI)
					CoordMode("Mouse", "Screen")
					MouseGetPos(&savex, &savey)
					FindText().Click(x, y)
					PA_WindowBusy := false
					MouseMove(savex, savey)
					result := true
				}
			}
		case "EI_DesktopStartReading":
			hwndEI := App["EI"].Win["d"].hwnd
			if hwndEI {
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
				if FindText(&x, &y, x0, y0 + 32, x0 + 720, y0 + 80, 0, 0, PAText[buttonname]) {
					PA_WindowBusy := true
					WinActivate(hwndEI)
					CoordMode("Mouse", "Screen")
					MouseGetPos(&savex, &savey)
					FindText().Click(x, y)
					PA_WindowBusy := false
					MouseMove(savex, savey)
					result := true
				}
			}
		default:
			;
	}

	return result
}


; Click a button image, specified by buttonname, on the EI Images1 window
;
; Valid button names are:
;	"EI_RemoveFromList"
;	"EI_StartReading"
;
; Searches the client area of the EI images1 window within
; the coordinates (0,0) and (1000,64) for the button (image search with FindText)
;
; Returns true if a button was clicked, false if no button was clicked
;
EIClickImages(buttonname) {

	result := false

	switch buttonname {
		case "EI_RemoveFromList":
			hwndEI := App["EI"].Win["i1"].hwnd
			if hwndEI {
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
				if FindText(&x, &y, x0, y0, x0 + 1000, y0 + 64, 0, 0, PAText[buttonname]) {
					PA_WindowBusy := true
					WinActivate(hwndEI)
					CoordMode("Mouse", "Screen")
					MouseGetPos(&savex, &savey)
					FindText().Click(x, y)
					PA_WindowBusy := false
					MouseMove(savex, savey)
					result := true
				}
			}
		case "EI_StartReading":
			hwndEI := App["EI"].Win["i1"].hwnd
			if hwndEI {
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
				if FindText(&x, &y, x0, y0, x0 + 1000, y0 + 64, 0, 0, PAText[buttonname]) {
					PA_WindowBusy := true
					WinActivate(hwndEI)
					CoordMode("Mouse", "Screen")
					MouseGetPos(&savex, &savey)
					FindText().Click(x, y)
					PA_WindowBusy := false
					MouseMove(savex, savey)
					result := true
				}
			}
		default:
			;
	}

	return result
}




/**********************************************************
 * Functions to retrieve info about EI
 */


; Returns the status of EI desktop
;
; Returns TRUE if EI desktop is running, FALSE if not
;
EIIsRunning() {
	App["EI"].Update()
	return App["EI"].Win["d"].hwnd ? true : false
}


; Functions to detect whether a specific EI desktop page is showing. 
;
; Checks whether the corresponding button is on or off in EI
;
; Returns true if the page is showing, false if not.
;
EIIsSearch() {
	if hwndEI := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EISearchOn"]) {
			return true
		}
	}
	return false
}
EIIsList() {
	if hwndEI := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EIListOn"]) {
			return true
		}
	}
	return false
}
EIIsText() {
	if hwndEI := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EITextOn"]) {
			return true
		}
	}
	return false
}
EIIsImage() {
	if hwndEI := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EIImageOn"]) {
			return true
		}
	}
	return false
}


; Determines which type of study is being displayed in the EI Text page
;
; Returns "Reading", "Study", "Comparison", or "Addendum" [todo]
;
; 	"Reading" means an unread study
;	"Study" means a previously read study on the primary screen
;	"Comparison" means a comparison study, being compared to either an unread or previously read study
;
; The Text area should be showing or else this function will return the empty string.
;
EIGetStudyMode() {

	if hwndEI := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EITextOn"]) {
			if ok := FindText(&x, &y, x0, y0 + 80, x0 + w0, y0 + 160, 0, 0, PAText["EI_Mode"]) {
				if ok[1].id = "EI_Reading" {
					return "Reading"
				}
				if ok.Length > 1 && (ok[2].id = "EI_Comparison" || ok[1].id = "EI_Comparison") {
					return "Comparison"
				}
				if ok[1].id = "EI_Study" {
					return "Study"
				}
				if ok[1].id = "EI_Addendum" {
					return "Addendum"
				}
			}
		}
	}
	return ""

}




/**********************************************************
 * Hook functions called on EI events
 */


; Hook function called when EI desktop window appears
; This gets called either when desktop window is first opened or is restored
;
EIOpen_EIdesktop() {

	PlaySound("EI desktop opened")

	if Setting["EI_restoreatopen"].value {
		; Restore EI window positions
		App["EI"].RestorePositions()
	}
	
	; this doesn't work for unclear reasons
	; Show collaborator window if requested
	; if PAOpt_ShowCollaborator {
	; 	; Allow time for window to appear
	; 	tick0 := A_TickCount
	; 	loop {
	; 		if (hwndcollaborator := PAWindows["EI"]["collaborator"].hwnd) {
	; 			WinRestore(hwndcollaborator)
	; 			WinActivate(hwndcollaborator)
	; 			; Restore EI collaborator window position
	; 			PAWindows["EI"]["collaborator"].RestorePosition()
	; 		}
	; 		PAWindows.Update()
	; 		PAToolTip("[" hwndcollaborator "] collaborator " (A_TickCount - tick0) / 1000)
	; 	} until hwndcollaborator || (A_TickCount - tick0 > EI_COLLABORATOR_TIMEOUT * 1000)
	; }

}


; Hook function called when EI desktop window goes away
; This gets called either when desktop window is closed OR minimized
;
EIClose_EIdesktop() {
	PlaySound("EI desktop closed")
}




/**********************************************************
 * Start up and Shut down functions
 * 
 */


; Start up Enterprise Imaging Desktop
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If EI is already running, returns immediately (without using credentials)
; with return value 1.
;
; If EI is not already running and network is not connected, returns 0.
;
; If EI is not already running and network is connected, starts up EI
; and uses cred to log in. The parameter cred is an object with username 
; and password properties.
;
; Periodically checks PACancelRequest to see if it the startup attempt
; should be cancelled
;
; Returns 1 if EI startup is successful, 0 if unsuccessful. (e.g.
; after timeout or if user cancels).
; 
EIStart(cred := CurrentUserCredentials) {
	global PAWindowBusy
	global PACancelRequest
	static running := false			; true if the EIStart is already running

	; if EIStart() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if EI desktop is aleady up and running, return 1 (true)
	if EIIsRunning() {
		GUIStatus("EI is already running")
	 	running := false
	 	return 1
	}

	; require appropriate network connection
	; if not quit and return 0 (failure)
	if !NetworkIsConnected(true) {
		if WorkstationIsHospital() {
			GUIStatus("Could not start EI - Network is not connected")
		} else {
			GUIStatus("Could not start EI - VPN is not connected")
			; [todo] ask user if they want to connect the vpn
		}
		running := false
		return 0
	}
	
	; if no password, ask user before proceeding
	if !cred.Password && !GUIGetPassword() {
		; couldn't get a password from the user, return failure (0)
        GUIStatus("Could not start EI - password needed")
		running := false
		return 0
	}
	cred.password := CurrentUserCredentials.password

	; start up EI
	GUIStatus("Starting EI...")
	tick0 := A_TickCount
	cancelled := false
	failed := false				; EI
	PSfailed := false			; PS

	; prevent focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; check if we already have a visible true login window
	;
	; Note that there are two windows that will match the criteria for the login window.
	; Both match the criteria for App["EI"].Win["login"] but have different HWNDs.
	;
	; The first is a hidden window that bootstraps the login procedure and monitors the shut
	; down procedure. This window is detected if DetectHiddenWindows is set to true. 
	; This hidden window persists after EI desktop is closed, and must be killed before EI 
	; can be run again.
	;
	; The second is the true login window that becomes visible and shows the username/password fields.
	; This is the window we want for logging in.
	App["EI"].Update()
	if !((hwndlogin := App["EI"].Win["login"].hwnd) && App["EI"].Win["login"].visible) {
		; no visible true login window

		; EI desktop window isn't showing, so kill any existing EI process then (re)run EI.
		App["EI"].Update()
		if App["EI"].pid {
			try {
				ProcessClose(App["EI"].pid)
			}
		}

		; now run EI
		Run('"' . EXE_EI . '" ' . EI_SERVER)
		Sleep(500)
		App["EI"].Update()

		; wait for true login window to exist
		tick1 := A_TickCount
		while !(hwndlogin := App["EI"].Win["login"].hwnd) && (A_TickCount - tick1 < EI_LOGIN_TIMEOUT * 1000) {
			GUIStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
			Sleep(500)
			App["EI"].Win["login"].Update()
			if PACancelRequest {
				cancelled := true
				break		; while
			}
		}
	}

	; if couldn't get to the true login window, return with failure
	if !hwndlogin {
		failed := true
	}

	if !cancelled && !failed {
		; got a true EI login window, start the login process

		; wait for EI login window to be visible (should already be)
		while !App["EI"].Win["login"].visible && A_TickCount - tick0 < EI_LOGIN_TIMEOUT * 1000 {
			GUIStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
			Sleep(500)
			App["EI"].Win["login"].Update()
			if PACancelRequest {
				cancelled := true
				break		; while
			}
		}
		
		if !App["EI"].Win["login"].visible {
			
			; if EI Login window still not visible after time out, return failure
			failed := true

		} else {

			; EI login window is visible, can use it
			WinActivate(hwndlogin)

			; delay to allow display of the username and password edit fields
			sleep(1000)

			if PACancelRequest {
				cancelled := true
			}
		}
		
		if !cancelled && !failed {

			; locate the username and password fields
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndlogin)
			ok := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EILoginField"])
			if ok {
				; enter the credentials and press OK to start login
				CoordMode("Mouse", "Screen")
				BlockInput true				; prevent user input from interfering
				MouseGetPos(&savex, &savey)

				Click(ok[1].x, ok[1].y + 8)
				Send("^a" . cred.username)
				Click(ok[2].x, ok[2].y + 8)
				Send("^a" . cred.password)
				Send("!o")					; Presses OK key (Alt-O) to start login
				
				MouseMove(savex, savey)
				BlockInput false
			}

			Sleep(500)
			App["EI"].Update()

			if PACancelRequest {
				cancelled := true
			}

			; waits for EI desktop window to appear
			tick1 := A_TickCount
			while !cancelled && !(hwnddesktop := App["EI"].Win["d"].hwnd) && (A_TickCount - tick1 < EI_DESKTOP_TIMEOUT * 1000) {
				GUIStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				Sleep(500)
				App["EI"].Win["d"].Update()
				if PACancelRequest {
					cancelled := true
					break
				}
			}

			if !hwnddesktop {
				; if EI desktop window still not visible after time out, return failure
				failed := true
			}

			; EI desktop is running
			; now wait for EPIC and PS to complete loading
			; in practice we can just wait for PS since it normally takes much longer then EPIC
			tick1 := A_TickCount
			while !cancelled && !(hwndmain := App["PS"].Win["main"].hwnd) && (A_TickCount - tick1 < PS_MAIN_TIMEOUT * 1000) {
				GUIStatus("Waiting for PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				Sleep(500)
				App["PS"].Win["main"].Update()
				if PACancelRequest {
					cancelled := true
					break		; while
				}
			}
			if !hwndmain {
				; if PS main window still not visible after time out, return failure
				PSfailed := true
			}

		}
	}

	GUIHideCancelButton()

	if cancelled {

		; user cancelled
		GUIStatus("EI startup cancelled - cleaning up...")

		; in this case, EI may have already been started up
		; if there is an EI process, then need to kill EI process before we exit
		if App["EI"].pid {
			try {
				ProcessClose(App["EI"].pid)
			}
			Sleep(500)
			App["EI"].Update()
		}

		GUIStatus("EI startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else if failed {

		; if failure, or if no desktop window by now, return as failure
		GUIStatus("Could not start EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else if PSfailed {
	
		GUIStatus("EI started, but could not start PowerScribe (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
	
	} else {

		; success
		GUIStatus("EI startup completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1

	}

	; restore focus following
	PAWindowBusy := false

	running := false
	return result
}


; Shut down Enterprise Imaging
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; Shutting down EI normally has side effects of closing PowerScribe and Epic.
; This function monitors and waits for PowerScribe and Epic to fully close
; as well before returning.
;
; Wait time is defined by EI_SHUTDOWN_TIMEOUT. If complete shutdown does not
; occur by that time, returns 0 (failure).
;
; Periodically checks PACancelRequest to see if it the startup attempt
; should be cancelled.
;
; Returns 1 if EI, PS, and Epic are all shut down is successful,
; 0 if unsuccessful (e.g. after timeout or if user cancels).
;
EIStop() {
	global PACancelRequest
	static running := false			; true if the EIStop is already running

	; if EIStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if EI is not running, immediately return success
	if !EIIsRunning() {
		GUIStatus("IE is not running")
		running := false
		return 1
	}

	; shut down EI
	GUIStatus("Shutting down EI...")
	tick0 := A_TickCount

	cancelled := false
	resultEI := false
	resultPS := false
	resultEPIC := false
	
	; prevent focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; Close the EI desktop
	EISend("!{F4}", "d")

	; wait for EI desktop to go away
	while !cancelled && (hwndEI := App["EI"].Win["d"].hwnd) && (A_TickCount-tick0 < EI_SHUTDOWN_TIMEOUT * 1000) {
		GUIStatus("Shutting down EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		sleep(500)
		App["EI"].Update()
		if PACancelRequest {
			cancelled := true
			break
		}
	}
	if !hwndEI {
		; EI desktop successfuly closed
		resultEI := true
	}

	if !cancelled {

		pscloseflag := false		; set to true if an Alt-F4 has been sent to close PS

		; wait for both PS & Epic to shut down
		while !cancelled && (!resultPS || !resultEPIC) && (A_TickCount-tick0 < EI_SHUTDOWN_TIMEOUT * 1000) {
	
			GUIStatus("Shutting down EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
			sleep(500)
			App["PS"].Update()
			App["EPIC"].Update()
			
			; winitem := PSParent()
			if !PSIsRunning() {
				; PS successfully closed
				resultPS := true
			} else if !pscloseflag && PSIsLogin() {
				; We're at the login window. Close it.
				PSSend("!{F4}")
				pscloseflag := true
			}
	
			if !EPICIsRunning() {
				resultEPIC := true
			} else if EPICIsLogin() {
				; need to shut down Epic
				try {
					ProcessClose(App["EPIC"].pid)
				}
			}

			if PACancelRequest {
				cancelled := true
				break
			}
		}
	}

	GUIHideCancelButton()

	if cancelled {

		; user cancelled
		GUIStatus("EI shut down cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else if resultEI && resultPS && resultEPIC {

		; shut down successful
		
		; After EI desktop is closed, a hidden EI login window persists in the background.
		; It needs to run until PS and Epic are closed (by EI). After PS and Epic have
		; been closed, we can kill the hidden process so it doesn't interfere with running EI again.
		if App["EI"].pid {
			try {
				ProcessClose(App["EI"].pid)
				sleep(500)
				App["EI"].Update()
			}
		}

		GUIStatus("EI shut down completed (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 1

	} else if !resultEI {
		
		; something went wrong
		GUIStatus("Could not shut down EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
		
	} else if !resultPS {
		
		; something went wrong
		GUIStatus("Could not shut down PowerScribe (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
		
	} else if !resultEPIC {
		
		; something went wrong
		GUIStatus("Could not shut down Epic (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0

	} else {		

		; something went wrong
		GUIStatus("Could not shut down EI, PowerScribe, and/or Epic (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := 0
		
	}

	; restore focus following
	PAWindowBusy := false

	; done
	running := false
	return result
}




/**********************************************************
 * EI data retrieval and parsing functions
 *  
 */


; [wip]
;
; Retrieves data from Patient Info section data of EI Desktop text page
;
; Returns a Patient object if successful, or 0 if unsuccessful
;
; See _EIParsePatientInfo() definition
;
EIRetrievePatientInfo() {

	; Create return Patient object
	patientinfo := Patient()

	if EIhwnd := App["EI"].Win["d"].hwnd {

		WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)

		; ensure the Text area is showing
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EITextOn"]) {

			; Look for Patient Info section and extract contents
			if FindText(&xPI, &yPI, x0, y0 + 32, x0 + 160, y0 + 160, 0, 0, PAText["EI_Patientinfo"]) {

				; modify xPI to be the left side of the Patient Info target (rather than the center)
				xPI := xPI - 40

				; look for right edge of Patient Info section
				if FindText(&xR, &yR, xPI, yPI, xPI + w0, yPI + 12, 0, 0, PAText["EI_Vert"]) {

					; look for bottom edge of Patient Info section
					if FindText(&xB, &yB, xPI, yPI, xR, yPI + h0, 0, 0, PAText["EI_Horz"]) {

						; Active EI window to work with it
						WinActivate EIhwnd
						
						; Patient Info section is roughly bound by xPI, yPI, xR, yB
						; Look for edit boxes within the Patient Info section and extract the text
						; Parse the text into data fields
						xcur := x - 1
						ycur := y0
						saveclip := A_Clipboard
						A_Clipboard := ""

						foundall := _EIParsePatientInfo()		;initialize PatientInfo section, sets foundall to false
						ok := FindText(&x, &y, xPI, yPI, xR, yB, 0, 0, PAText["EI_UL"])		; look for edit boxes
						if ok {	
							for k, v in ok {
;								FindText().MouseTip(v.x, v.y) ; Show a blinking red box at the center of the result.

								CoordMode("Mouse","Screen")
								BlockInput true
								MouseGetPos(&savex, &savey)
								if GetKeyState("LButton") {
									Click("U")
								}
								if GetKeyState("RButton") {
									Click("U R")
								}
								Click(v.x + 2, v.y)
								SendInput("^a^c")
								if !ClipWait(0.05) {				; wait until clipboard contains data, with 100 ms timeout
;									PAToolTip("ClipWait (1) timed out")
									SoundBeep(250)
								}
								MouseMove(savex, savey)
								BlockInput false
								contents := A_Clipboard
								foundall := _EIParsePatientInfo(&patientinfo, contents)
								A_Clipboard := ""

								if foundall {
									break
								}
							}

							A_Clipboard := saveclip
							return patientinfo
						}
						
						A_Clipboard := saveclip
					}
				}
			}
		}
	}

	return 0
}


; Looks for data within the passed contents string to match the following items:
; 	Patient name
;	Patient date of birth
;	Patient sex
;
; and stores the string in:
;	patientinfo.patientname"
;	patientinfo.dob
;	patientinfo.sex
;
; where patientinfo is a Patient object
;
; Once all items have been found, function returns true. Returns false if not all items have been found.
;
; Unrecognized data strings are stored in patientinfo.other[]  
;	patientinfo.other["unknown1", "unknown2", ...]
;
; To reset and search for a new set of data, call with no parameters.
; Function will return false again.
;
; [todo] Allow apostrophe, hyphen, period in patient names
;
_EIParsePatientInfo(&patientinfo := "", contents := "") {
	static index :=0
	static foundpatientname := false
	static founddob := false
	static foundsex := false

	if patientinfo = "" {
		foundpatientname := false
		founddob := false
		foundsex := false

	} else if contents = "" {
		; contents are empty, return without storing it

	} else if SubStr(contents, 1, 8) = "com.agfa" {
		; ignore this field, return without storing it

	} else {
		; look for data matches

		if !founddob && RegExMatch(contents, "^[0-9]{2}-[0-9]{2}-[0-9]{4}$") {
			founddob := true
			patientinfo.dob := contents
		} else if !foundsex && RegExMatch(contents, "^Female|Male|Other") {
			foundsex := true
			patientinfo.sex := contents
		} else if !foundpatientname && RegExMatch(contents, "^[A-Z \-]+,[A-Z ]+") {
			foundpatientname := true
			patientinfo.lastfirst := contents
		} else {
			patientinfo.other.Push(contents)
		}

	}

	return foundpatientname && founddob && foundsex
}


; Retrieves data from Study Info section data of EI Desktop text page
;
; Should be passed a Patient object, with whom this study is associated
;
; Returns a Study object if successful, or 0 if unsuccessful
;
; See _EIParseStudyInfo() definition
;
EIRetrieveStudyInfo(patient) {

	; Create return Study object
	studyinfo := Study()

	if EIhwnd := App["EI"].Win["d"].hwnd {

		WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)

		; ensure the Text area is showing
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EITextOn"]) {

			; Look for Study Info section
			if FindText(&xSI, &ySI, x0, y0 + 32, x0 + w0, y0 + h0, 0, 0, PAText["EI_Studyinfo"]) {

				; modify xSI to be the left side of the Study Info target (rather than the center)
				xSI := xSI - 40

				; look for right edge of Study Info section
				if FindText(&xR, &yR, xSI, ySI, xSI + w0, ySI + 12, 0, 0, PAText["EI_Vert"]) {

					; Look for Technologist's comments section
					if FindText(&xTI, &yTI, xSI, y0 + 32, xR, y0 + h0, 0, 0, PAText["EI_Technologist"]) {

;			FindText().MouseTip(xTI, yTI) ; Show a blinking red box at the center of the result.

						; modify xTI to be the left side of the Technologist's comments target (rather than the center)
						xTI := xTI - 40

						; look for bottom edge of Technologist's comments section
						if FindText(&xB, &yB, xTI, yTI, xR, yTI + h0, 0, 0, PAText["EI_Horz"]) {


							; Active EI window to work with it
							WinActivate EIhwnd
							
							; Study Info section is roughly bound by xSI, ySI, xR, yTI
							; Technologist's comments section is roughly bound by xTI, yTI, xR, yB

							; Look for edit boxes within the Study Info section
							; and extract the text. Parse the text into data fields.
							xcur := x - 1
							ycur := y0
							saveclip := A_Clipboard
							A_Clipboard := ""
			
			; FindText().MouseTip(xR, yTI) ; Show a blinking red box at the center of the result.

							foundall := _EIParseStudyInfo()		;initialize Study info section, sets foundall to false
							ok := FindText(&x, &y, xSI, ySI, xR, yTI, 0, 0, PAText["EI_UL"])		; look for edit boxes
							if ok {	
								for k, v in ok {
	
	; FindText().MouseTip(v.x, v.y) ; Show a blinking red box at the center of the result.

									CoordMode("Mouse","Screen")
									BlockInput true
									MouseGetPos(&savex, &savey)
									if GetKeyState("LButton") {
										Click("U")
									}
									if GetKeyState("RButton") {
										Click("U R")
									}
									Click(v.x + 2, v.y, 2)
									SendInput("^a^c")
									if !ClipWait(0.1) {				; wait until clipboard contains data, with 100 ms timeout
;										PAToolTip("ClipWait (2) timed out")
										SoundBeep(250)
									}
									MouseMove(savex, savey)
									BlockInput false
									contents := A_Clipboard
;					PAToolTip(contents)
									foundall := _EIParseStudyInfo(&studyinfo, contents, "study")
									A_Clipboard := ""

									if foundall {
										break
									}
								}
							}

							; Now look for edit boxes within the Technologist's comments section
							; and extract the text. Parse the text into data fields.
							xcur := x - 1
							ycur := y0
							A_Clipboard := ""
n:=1
							ok := FindText(&x, &y, xTI, yTI, xR, yB, 0, 0, PAText["EI_UL"])		; look for edit boxes
							if ok {	
								for k, v in ok {
									
									
					; FindText().MouseTip(v.x, v.y) ; Show a blinking red box at the center of the result.
if n++ > 2 {
	break
}

									CoordMode("Mouse","Screen")
									BlockInput true
									MouseGetPos(&savex, &savey)
									if GetKeyState("LButton") {
										Click("U")
									}
									if GetKeyState("RButton") {
										Click("U R")
									}
									Click(v.x + 2, v.y, 2)
									SendInput("^a^c")
									if !ClipWait(0.1) {				; wait until clipboard contains data, with 100 ms timeout
;										PAToolTip("ClipWait (3) timed out")
										SoundBeep(250)
									}
									MouseMove(savex, savey)
									BlockInput false
									contents := A_Clipboard
									foundall := _EIParseStudyInfo(&studyinfo, contents, "tech")
									A_Clipboard := ""

									if foundall {
										break
									}
								}

							}

							A_Clipboard := saveclip

							return studyinfo
						}
					}
				}
			}
		}
	}

	return 0
}


; Looks for data within the passed contents string to match the following items:
;	Accession number
;	Study description
;	Performing facility
;	Patient type at acquisition
;	Task priority
;	Ordering physician
;	Reason for study
;	Technologist's comments
;
; and stores the data in studyinfo, which is a Study object
;
; Once all items have been found, function returns true. Returns false if not all items have been found.
;
; Unrecognized data strings are stored in studyinfo.other[]  
;	studyinfo.other["unknown1", "unknown2", ...]
;
; To reset and search for a new set of data, call with no parameters.
; Function will return false again.
;
_EIParseStudyInfo(&studyinfo := "", contents := "", section := "study") {
	static index :=0
	static foundaccession := false
	static founddescription := false
	static foundfacility := false
	static foundpatienttype := false
	static foundpriority := false
	static foundorderingmd := false
	static foundreferringmd := false
	static foundreason := false
	static foundtechcomments := false
	
	if studyinfo = "" {
		foundaccession := false
		founddescription := false
		foundfacility := false
		foundpatienttype := false
		foundpriority := false
		foundorderingmd := false
		foundreferringmd := false
		foundreason := true
		foundtechcomments := false
	
	} else if contents = "" {
		; contents are empty, return without storing it

	} else if SubStr(contents, 1, 8) = "com.agfa" {
		; ignore this field, return without storing it

	} else {

		switch section {
			case "study":

				; look for data matches
				if !foundaccession && SubStr(contents, 1, 3) = "ADV" {
					foundaccession := true
					studyinfo.accession := contents
				} else if !foundfacility && SubStr(contents, 1, 6) = "AH UCM" {
					foundfacility := true
					studyinfo.facility := contents
				} else if !foundpriority && RegExMatch(contents, "^STAT|^Urgent|^High|^Normal|^Routine") {
					foundpriority := true
					studyinfo.priority := contents
				} else if !foundpatienttype && RegExMatch(contents, "^Ambulatory|^Hospitalized|^Emergency") {
					foundpatienttype := true
					studyinfo.patienttype := contents
				} else if !studyinfo.description && RegExMatch(contents, "^BI |^CT |^DR |^MR |^NM |^US |^XR ") {
					founddescription := true
					studyinfo.description := contents
;					PAToolTip(contents)
				} else if RegExMatch(contents, "^[A-Z ]+,[A-Z ]+") {
					if !foundorderingmd {
						studyinfo.orderingmd := contents
						foundorderingmd := true
					} else if !foundreferringmd {
						studyinfo.referringmd := contents
						foundreferringmd := true
					}
				} else if RegExMatch(contents, "^\.?(BOL|GLE|HIN|LAG.*)") {
					; found a location code
					if SubStr(contents, 1, 1) = "." {
						; remove leading period
						studyinfo.other.Push(SubStr(contents, 2))
					} else {
						studyinfo.other.Push(contents)
					}
				} else {
					; let's assume this goes into reason for study
					foundreason := true
					studyinfo.reason .= (studyinfo.reason?" | ":"") . contents
				}

				return foundaccession && founddescription && foundfacility && foundpatienttype && foundpriority && foundorderingmd && foundreason

			case "tech":
				; foundtechcomments := trueS
				studyinfo.techcomments .= (studyinfo.techcomments ? " // " : "") . contents

				return foundtechcomments 		

			default:
				studyinfo.other.Push(contents)
		}
	}

	return foundaccession && founddescription && foundfacility && foundpatienttype && foundpriority && foundorderingmd && foundreason && foundtechcomments
}




/**********************************************************
 * EI Commands
 *  
 */


; Send Start reading/Resume reading commands to EI
;
; Uses EIClickImages to target eyeglasses icon since that works for
; both Start reading and Resume reading. Ctrl-Enter is a shortcut
; for Start reading but it doesn't work for Resume reading.
;
EICmdStartReading() {
	if !EIClickImages("EI_StartReading") {
		EIClickDesktop("EI_DesktopStartReading")
	}
	PlaySound("EIStartReading")
}


; Display Study Details, by clicking the first Study Details icon
;	that is in off state, found on either EI image window. This
;	effectively toggles between active and comparison study details
;	in the most common scenarios.
;
; If not already showing, switches to the EI Text area.
;
EICmdDisplayStudyDetails() {
	; search images2 window first
	EIhwnd := App["EI"].Win["i2"].hwnd
	WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)
	result := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EI_SDOff"], , 0, , , , 1)
	if !result {
		; if no match on images2 window, then search images1 window
		EIhwnd := App["EI"].Win["i1"].hwnd
		WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)
		result := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EI_SDOff"], , 0, , , , 1)
	}
	if result {
		; found an icon to click
		WinActivate(EIhwnd)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&savex, &savey)
		FindText().Click(x, y)
		MouseMove(savex, savey)
		if !EIIsText() {
			; switch EI Desktop to Text page
			EIClickDesktop("EIText")
		}
		return true
	} else {
		; didn't find an icon to click
		return false
	}
}


; Toggles between the EI desktop Text and List pages
;
EICmdToggleListText() {
	if EIIsList() {
		EIClickDesktop("EIText")
	} else {
		EIClickDesktop("EIList")
	}
}


; Shows the Search page on the EI desktop
;
EICmdShowSearch() {
	EIClickDesktop("EISearch")
}


; Resets the Search page on the EI desktop, places cursor in the patient last name field
; Assumes the Search page is already showing
;
EICmdResetSearch() {
	if EIhwnd := App["EI"].Win["d"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)
		if FindText(&x:="wait", &y:=0.2, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EISearch_Clear"], , 0, , , , 1) {
			WinActivate(EIhwnd)
			CoordMode("Mouse", "Screen")
			Click(x, y)					; clear search fields
			if FindText(&x:="wait", &y:=0.2, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EISearch_LastName"], , 0, , , , 1) {
				Click(x, y)				; click in patient last name search field
				MouseMove(x, y + 16)	; move the mouse away from the edit field
			}
		}
	}	
}


; Sends the Remove from list command (click on the close icon)
;
EICmdRemoveFromList() {
	EIClickImages("EI_RemoveFromList")
}
