/* PAEI.ahk
**
** for working with EI
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force


/*
** Includes
*/

#Include <FindText>
#Include "PAFindTextStrings.ahk"

#Include PAGlobals.ahk

#include "PAInfo.ahk"


/**
 * Global variables and constants used in this module
 */






/**
 * Functions for sending commands to PS
 * 
 */


; Send Start Reading/Resume Reading command (Shift-Enter) to EI
;
EICmdStartReading() {
	EISend("^{Enter}")					; Start reading
	PASound("EIStartReading")
}

; Display Study Details, by clicking the first Study Details icon
;	that is in off state, found on either EI image window. This
;	effectively toggles between active and comparison study details
;	in the most common scenarios.
; If not already showing, shows the EI Text area.
;
EICmdDisplayStudyDetails() {
	; search images2 window first
	EIhwnd := PAWindows["EI"]["images2"].hwnd
	WinGetClientPos(&x0, &y0, &w0, &h0, EIhwnd)
	result := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EI_SDOff"], , 0, , , , 1)
	if !result {
		; if no match on images2 window, then search images1 window
		EIhwnd := PAWindows["EI"]["images1"].hwnd
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
	if EIhwnd := PAWindows["EI"]["desktop"].hwnd {
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

; Sends the Remove from list command (click on close icon)
;
EICmdRemoveFromList() {
	EIClickImages("EI_RemoveFromList")
}


/**
 * Functions for sending keystrokes and mouse clicks to EI
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
EISend(cmdstring := "", targetwindow := "images1") {
	global PA_WindowBusy
	if (cmdstring) {
		switch targetwindow {
			case "images1":
				hwndEI := PAWindows["EI"]["images1"].hwnd
			case "desktop":
				hwndEI := PAWindows["EI"]["desktop"].hwnd
			case "images2":
				hwndEI := PAWindows["EI"]["images2"].hwnd
			default:
				hwndEI := PAWindows["EI"]["images1"].hwnd
		}
		if (hwndEI) {
			PA_WindowBusy := true
			WinActivate(hwndEI)
			Send(cmdstring)
			PA_WindowBusy := false
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
; Searches the client area of the EI Desktop window within
; the coordinates (0,32) and (320,80) for the button (image search with FindText)
;
EIClickDesktop(buttonname) {

	switch buttonname {
		case "EISearch", "EIList", "EIText", "EIImage", "EIEpic":
			hwndEI := PAWindows["EI"]["desktop"].hwnd
			if hwndEI {
				WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
				if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText[buttonname]) {
					PA_WindowBusy := true
					WinActivate(hwndEI)
					CoordMode("Mouse", "Screen")
					MouseGetPos(&savex, &savey)
					FindText().Click(x, y)
					PA_WindowBusy := false
					MouseMove(savex, savey)
				}
			}
		default:
			;
	}

}


; Click a button image, specified by buttonname, on the EI Images1 window
;
; Valid button names are:
;	"EI_RemoveFromList"
;
; Searches the client area of the EI images1 window within
; the coordinates (0,32) and (320,80) for the button (image search with FindText)
;
EIClickImages(buttonname) {

	switch buttonname {
		case "EI_RemoveFromList":
			hwndEI := PAWindows["EI"]["images1"].hwnd
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
				}
			}
		default:
			;
	}

}




/**
 * Functions for obtaining information about EI
 * 
 */


; Returns the status of EI
;
; Returns TRUE if EI desktop is running, FALSE if not
;
EIIsRunning() {
	global PAWindows

	PAWindows.Update("EI")
	hwnddesktop := PAWindows["EI"]["desktop"].hwnd

	return hwnddesktop ? true : false
}


; Functions to detect whether a specific EI desktop page is showing. 
;
; Checks whether the corresponding button is on or off in EI
;
; Returns true if the page is showing, false if not.
;
EIIsSearch() {
	if hwndEI := PAWindows["EI"]["desktop"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EISearchOn"]) {
			return true
		}
	}
	return false
}
EIIsList() {
	if hwndEI := PAWindows["EI"]["desktop"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EIListOn"]) {
			return true
		}
	}
	return false
}
EIIsText() {
	if hwndEI := PAWindows["EI"]["desktop"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EITextOn"]) {
			return true
		}
	}
	return false
}
EIIsImage() {
	if hwndEI := PAWindows["EI"]["desktop"].hwnd {
		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
		if FindText(&x, &y, x0, y0 + 32, x0 + 320, y0 + 80, 0, 0, PAText["EIImageOn"]) {
			return true
		}
	}
	return false
}


; Determines which type of study is being displayed in the EI Text page
;
; Returns "Reading", "Study", "Comparison", or "Addendum"[todo]
;
; 	"Reading" means an unread study
;	 "Study" means a previously read study on the primary screen
;	 "Comparison" means a comparison study, being compared to either an unread or previously read study
;
; The Text area must be showing or else this function will return the empty string.;
;
EIGetStudyMode() {
	if hwndEI := PAWindows["EI"]["desktop"].hwnd {
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



/**
 * Hook functions
 * 
 */


; Hook function called when EI desktop window appears
;
EIOpen_EIdesktop() {
	global PAWindows

	PASound("EI desktop opened")

	if PASettings["EI_restoreatopen"].value {
		; Restore EI window positions
		PAWindows.RestoreWindows("EI")
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
;
EIClose_EIdesktop() {

	PASound("EI desktop closed")

}



/***********************************************/


/**
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
; If EI is not already running and VPN is not connected, returns 0.
;
; If EI is not already running and VPN is connected, starts up EI and uses cred to log in.
; The parameter cred is an object with username and password properties.
;
; Returns 1 if EI startup is successful, 0 if unsuccessful. (e.g.
;  after timeout or if user cancels).
; 
EIStart(cred := CurrentUserCredentials) {
	global PA_WindowBusy
	static running := false			; true if the EIStartup is already running

	; if EIStart() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if desktop is aleady up and running, return 1 (true)
	if EIIsRunning() {
		PAStatus("EI is already running")
	 	running := false
	 	return 1
	}

	; hwnddesktop := WinExist(PAWindows["EI"]["desktop"].searchtitle, PAWindows["EI"]["desktop"].wintext)
	; if hwnddesktop {
	; 	PAStatus("EI is already running")
	; 	running := false
	; 	return 1
	; }

	; require VPN to be connected, if not quit and return 0 (failure)
	if !VPNIsConnected(true) {
		PAStatus("Could not start EI - VPN is not connected")
		running := false
		return 0
	}
	
	tick0 := A_TickCount
	PAStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")

	; if EI login window does not exist, then EI has not been run, so run EI
	; or if EI login window does exist but is hidden, then need to kill EI process then rerun EI
	hwndlogin := WinExist(PAWindows["EI"]["login"].searchtitle, PAWindows["EI"]["login"].wintext)
	hiddenlogin := !PAWindows["EI"]["login"].visible
	if !hwndlogin || (hwndlogin && hiddenlogin) {
		if hwndlogin {
			; if EI login window is hidden, likely EI was running then closed
			; need to kill the existing process and start over, since the login box doesn't
			; display properly with just WinShow()
			pidlogin := WinGetPID(hwndlogin)
			if pidlogin {
				ProcessClose(pidlogin)
				PAWindows.Update("EI")
			}
; PAToolTip("killed EI login process")
			hwndlogin := 0
		}

		; now run EI
		Run('"' . EXE_EI . '" ' . EI_SERVER)
		PAWindows.Update("EI")

		; wait for login window to be appear
		tick1 := A_TickCount
		while !(hwndlogin := PAWindows["EI"]["login"].hwnd) && (A_TickCount - tick1 < EI_LOGIN_TIMEOUT * 1000) {
			PAWindows.Update("EI")
			Sleep(500)
			PAStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		}
	}

	; if couldn't get a login window, return failure
	if !hwndlogin {
		PAStatus("Could not start EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	}

	; restore the EI login window if it is minimized
	if PAWindows["EI"]["login"].minimized {
		WinRestore(hwndlogin)
	}

	; prevent focus following
	PA_WindowBusy := true

	; wait for EI login window to be visible
	while !PAWindows["EI"]["login"].visible && A_TickCount - tick0 < EI_LOGIN_TIMEOUT * 1000 {
		Sleep(500)
		PAStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; if EI Login window still not visible after time out, return failure
	if !PAWindows["EI"]["login"].visible {
		PAStatus("Could not start EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	}

	; EI login window should be visible
	WinActivate(hwndlogin)

	; delay to allow display of the username and password edit fields
	sleep(500)
	
	; locate the username and password fields
	WinGetClientPos(&x0, &y0, &w0, &h0, hwndlogin)
	ok := FindText(&x, &y, x0, y0, x0 + w0, y0 + h0, 0, 0, PAText["EILoginField"])
	if ok {
		; enter the credentials and press OK to start login
		CoordMode("Mouse", "Screen")
		PA_WindowBusy := true
		BlockInput true
		MouseGetPos(&savex, &savey)
		Click(ok[1].x, ok[1].y + 8)
		Send("^a" . cred.username)
		Click(ok[2].x, ok[2].y + 8)
		Send("^a" . cred.password)
		Send("!o")					; Presses OK key (Alt-O) to start login
		MouseMove(savex, savey)
		BlockInput false
		PA_WindowBusy := false
	}

	Sleep(500)
	PAWindows.Update("EI")

	; waits for EI desktop window to appear
	tick1 := A_TickCount
	while !(hwnddesktop := PAWindows["EI"]["desktop"].hwnd) && (A_TickCount - tick1 < EI_DESKTOP_TIMEOUT * 1000) {
		PAWindows.Update("EI")
		Sleep(500)
		PAStatus("Starting EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; if no desktop window after timeout, return failure
	if !hwnddesktop {
		PAStatus("Could not start EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	} else {
		PAStatus("EI started (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; restore focus following
	PA_WindowBusy := false

	; done
	running := false
	return 1
}



; Shut down Enterprise Imaging
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; Monitors EI desktop until it is closed then returns true. If EI desktop
; does not close within EI_SHUTDOWN_TIMEOUT, returns false.
;
; Shutting down EI has the side effects of closing PowerScribe and Epic.
;
; Returns 1 if EI shut down is successful, 0 if unsuccessful. (e.g.
;  after timeout or if user cancels).
;
EIStop() {
	static running := false			; true if the EIStop is already running

	; if EIStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if EI is not running, immediately return success
	if !EIIsRunning() {
		PAStatus("IE is not running")
		running := false
		return 1
	}


	tick0 := A_TickCount
	PAStatus("Shutting down EI...")
	
	; Close EI desktop
	EISend("!{F4}", "desktop")

	; wait for EI desktop to go away
	tick0 := A_TickCount
	while PAWindows["EI"]["desktop"].hwnd && (A_TickCount-tick0 < EI_SHUTDOWN_TIMEOUT * 1000) {
		sleep(500)
		PAStatus("Shutting down EI... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		PAWindows.Update("EI")
	}

	if PAWindows["EI"]["desktop"].hwnd {
		; EI desktop window is still not closed
		PAStatus("Could not shut down EI (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		running := false
		return 0
	} else {
		PAStatus("EI shut down (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}
	
	; done
	running := false
	return 1
}

;TODO the case where EI is already closed and didn't signal PS to close. The dialog boxes won't appear

	; ; if powerscribe is running, wait for its close dialogs
	; if WinExist("PowerScribe") {

	; 	;wait for dialog to confirm logoff from powerscribe
	; 	hwndPS := WinWait("PowerScribe", "Are you sure you wish to log off the application?", 30)			; 30 second timeout
	; 	if (hwndPS) {
	; 		ControlSend("{Enter}", "Yes", hwndPS)
	; 	}

	; 	;wait for dialog to confirm save speech files
	; 	hwndPS := WinWait("PowerScribe", "Your speech files have changed. Do you wish to save the changes?", 5)			; 5 second timeout
	; 	if (hwndPS) {
	; 		ControlSend("{Enter}", "Yes", hwndPS)
	; 	}

	; 	; wait for the powerscribe login screen, then shut down powerscribe
	; 	hwndPS := WinWait("PowerScribe", "Disable speech", 60)			; 60 second timeout
	; 	if (hwndPS) {
	; 		WinActivate(hwndPS)
	; 		Send "!{F4}"				; send Alt-F4 to shutdown EI
	; 	}

	; }
; 
; 
; }






/***********************************************/


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

	if EIhwnd := PAWindows["EI"]["desktop"].hwnd {

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
									PAToolTip("ClipWait (1) timed out")
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

	if EIhwnd := PAWindows["EI"]["desktop"].hwnd {

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
										PAToolTip("ClipWait (2) timed out")
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



/*
; Retrieves obtainable data from EI Desktop window
; Returns parsed data in data map, similar to:
;	data["firstname"] = Last_name
;	data["lastname"] = First_name
;	...
; Or returns empty object if no EI Desktop window
;
; See _EIParseContents() definition for possible keys
;
RetrieveDataEI() {
	hwndEI := WinExist("Diagnostic Desktop - 8")
	if (hwndEI) {

		; Active EI window to work with it
		WinActivate hwndEI

		; Retrieve the location and size of the workspace of the EI window
		WinGetClientPos &EIx, &EIy, &EIw, &EIh, hwndEI

		; Create return data object
		data := Map()

		; Look for Patient Info section and extract contents
		try {
			if ImageSearch(&x0, &y0, 0, 0, EIw, 256, "images\img_PatientInfo.png") {
				;MsgBox "img_PatientInfo was found at " x0 "x" y0

				; look for right edge of Patient Info section
				if ImageSearch(&x1, &y, x0, y0, EIh-x0, y0+16, "images\img_BlueVR16.png")
					{} ;MsgBox "img_BlueVR16 was found at " x1 "x" y
				else
				{} ;MsgBox "img_BlueVR16 not found"

				; look for bottom edge of Patient Info section
				if ImageSearch(&x, &y1, x0, y0, x0+32, EIh-y0, "images\img_BlueHR32.png")
					{} ;MsgBox "img_BlueHR32 was found at " x "x" y1
				else
				{} ;MsgBox "img_BlueHR32 not found"

				; Patient Info section is bound by x0, y0, x1, y1
				; Look for all the edit boxes within the Patient Info section and extract the text
				; Parse the text into data fields
				xcur := x - 1
				ycur := y0
				A_Clipboard := ""
				;contents := ""

				foundall := _EIParsePatientInfo()		;initialize PatientInfo section, sets foundall to false
				while !foundall && ImageSearch(&x, &y, xcur, ycur, x1, y1, "images\img_ULCornerEditBox.png") {
					; found one, copy the text
					;MsgBox x "," y " cur[" xcur "," ycur "]"

					Click x+4, y+4
					SendInput "^a^c"
					ClipWait 0.05				; 50 ms timeout
					contents := A_Clipboard
					;msgbox "'" contents "'"
					foundall := _EIParsePatientInfo(&data, contents)

					; update search start position for next iteration
					ycur := y + 4
					A_Clipboard := ""
					;MsgBox "next starting position " xcur "," ycur " end pos[" x1 "," y1 "]"
				}

			} else
				{} ;MsgBox "img_PatientInfo not found"

		}
		catch as exc {
				MsgBox "1 ImageSearch failed due to the following error:`n" exc.Message
		}

		; Look for Study Info section and extract contents
		try {
			if ImageSearch(&x0, &y0, 0, 0, EIw, 256, "images\img_StudyInfo.png") {
				;MsgBox "img_StudyInfo was found at " x0 "x" y0

				; look for right edge of Study Info section
				if ImageSearch(&x1, &y, x0, y0, EIh - x0, y0 + 16, "images\img_BlueVR16.png")
					{} ;MsgBox "img_BlueVR16 was found at " x1 "x" y
				else
					{} ;MsgBox "img_BlueVR16 not found"

				; look for bottom edge of Study Info section
				if ImageSearch(&x, &y1, x0, y0, x0 + 32, EIh - y0, "images\img_BlueHR32.png")
					{} ;MsgBox "img_BlueHR32 was found at " x "x" y1
				else
					{} ;MsgBox "img_BlueHR32 not found"

				; Study Info section is bound by x0, y0, x1, y1
				; Look for all the edit boxes within the Study Info section and extract the text
				; Parse the text into data fields
				xcur := x0-1
				ycur := y0
				A_Clipboard := ""

				edit2flag := 0

				foundall := _EIParseStudyInfo()		;initialize PatientInfo section, sets foundall to false
				while !foundall && ImageSearch(&x, &y, xcur, ycur, x1, y1, "images\img_ULCornerEditBox.png") {

					; found one, copy the text
					;MsgBox x "," y " cur[" xcur "," ycur "]"

					Click x + 4, y + 4
					SendInput "^a^c"
					ClipWait 0.05				; 50 ms timeout
					contents := A_Clipboard

					hint := ""
					foundall := _EIParseStudyInfo(&data, contents, hint)

					; update search start position for next iteration
					ycur := y + 4
					A_Clipboard := ""
					;MsgBox "next starting position " xcur "," ycur " end pos[" x1 "," y1 "]"
				}

				xcur := x0-1
				ycur := y0
				A_Clipboard := ""
				while !foundall && ImageSearch(&x, &y, xcur, ycur, x1, y1, "images\img_ULCornerEditBox2.png") {

					; found one, copy the text
					;MsgBox x "," y " cur[" xcur "," ycur "]"

					Click x + 4, y + 4
					SendInput "^a^c"
					ClipWait 0.05				; 50 ms timeout
					contents := A_Clipboard

					hint := "reason"
					foundall := _EIParseStudyInfo(&data, contents, hint)

					; update search start position for next iteration
					ycur := y + 4
					A_Clipboard := ""
					;MsgBox "next starting position " xcur "," ycur " end pos[" x1 "," y1 "]"
				}

			} else
				{} ;MsgBox "img_StudyInfo not found"

		}
		catch as exc {
				MsgBox "2 ImageSearch failed due to the following error:`n" exc.Message
		}


		return data
	}

	return		; nothing returned
}

*/




; Looks for data within the passed contents string matching the following items:
; 	Performing facility
;	Patient type at acquisition
;	Task priority
;	Ordering physician
;	Study description
;	Accession number
;	Reason for study
;
; and stores the string in:
;	data["facility"]
;	data["patienttype"]
;	data["priority"]
;	data["orderingmd"]
;	data["study"]
;	data["accession"]
;	data["reason"]
;
; Once all items have been found, function returns true.
;
; If unrecognized data are found, strings are stored in:
;	data["unknown1"]
;	data["unknown2"]
;	...
;
; To reset and search for a new set of data, call with no parameters.
; Function will return false again.
;
xx_EIParseStudyInfo(&data := "", contents := "", hint := "") {
	static index :=0
	static foundfacility := false
	static foundpatienttype := false
	static foundpriority := false
	static foundorderingmd := false
	static foundstudy := false
	static foundaccession := false
	static foundreason := false

	if data = "" {
		index := 0
		foundfacility := false
		foundpatienttype := false
		foundpriority := false
		foundorderingmd := false
		foundstudy := false
		foundaccession := false
		foundreason := false

	} else if contents = "" {
		; contents are empty, return without storing it

	} else if SubStr(contents, 1, 8) = "com.agfa" {
		; ignore this field, return without storing it

	} else {
		; look for data matches

		if !foundaccession && SubStr(contents, 1, 3) = "ADV" {
			foundaccession := true
			key := "accession"
		} else if !foundfacility && SubStr(contents, 1, 6) = "AH UCM" {
			foundfacility := true
			key := "facility"
		} else if !foundpriority && RegExMatch(contents, "^Routine|^STAT") {
			foundpriority := true
			key := "priority"
		} else if !foundpatienttype && RegExMatch(contents, "^Ambulatory|^Hospitalized") {
			foundpatienttype := true
			key := "patienttype"
		} else if !foundstudy RegExMatch(contents, "^BI |^CT |^DR |^MR |^NM |^US |^XR ") {
			foundstudy := true
			key := "study"
		} else if !foundorderingmd && RegExMatch(contents, "^[A-Z ]+,[A-Z ]+") {
			foundorderingmd := true
			key := "orderingmd"
		} else {

			if hint {
				key := hint
			} else {
				key := "unknown" . String(index++)
			}
		}

		data[key] := contents
	}

	return foundfacility && foundpatienttype && foundpriority && foundorderingmd && foundstudy && foundaccession && foundreason
}





