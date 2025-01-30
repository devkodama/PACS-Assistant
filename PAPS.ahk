/* PAPS.ahk
**
** Utility scripts for working with PowerScribe 360
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


/*
** Global variables and constants used in this module
*/

WM_SETTEXT := 0x000C
WM_GETTEXT := 0x000D
EM_GETSEL := 0x00B0
EM_SETSEL := 0x00B1
EM_SETREADONLY := 0x00CF




/**
 * Functions for sending keystrokes and mouse clicks to EI
 * 
 */


; Send keystroke commands to PowerScribe
;
; Ensures either the PS report window or PS addendum window will be receiving the keystrokes.
;
PSSend(cmdstring := "") {
    global PA_WindowBusy

	if (cmdstring) {
		if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
			return
		}

		; at this point hwndPS is non-null and points to the current PS window
		PA_WindowBusy := true
		WinActivate(hwndPS)
		Send(cmdstring)
		PA_WindowBusy := false
	}
}


; Paste a chunk of text into PowerScribe
;
; Ensures either the PS report window or PS addendum window will be receiving the paste.
;
; Uses the clipboard, restoring the previous clipboard contents when finished.
;
PSPaste(text := "") {
    global PA_WindowBusy

	if (text) {
		if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
			return
		}

		; at this point hwndPS is non-null and points to the current PS window
		PA_WindowBusy := true
		saveclipboard := A_Clipboard
		A_Clipboard := text
		WinActivate(hwndPS)
		SendInput("^v")					; paste the text
		Sleep(100)					; requires a delay before restoring keyboard, or else the ^v paste will send the wrong contents (the saved clipboard)
		A_Clipboard := saveclipboard
		PA_WindowBusy := false
	}
}


/**
 *  Functions for obtaining information about PS
 * 
 */


; Returns the state of the PS360 Dictate button by reading the toolbar button
; The Dicate button must be visible on screen
; 
; If the Dictate button is On, returns true
; Otherwise returns false
;
; Search PS360 client window area from (0,16) to (width, 128). The toolbar
; button should be within this area.
;
; Dictate status is cached, only checked every WATCHDICTATE_UPDATE_INTERVAL, unless
; forceupdate is true.
;
;
PSDictateIsOn(forceupdate := false) {
	static dictatestatus := false
	static lastcheck := A_TickCount

	; if PS report or addendum or main window does not exist, return false
	if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
		dictatestatus := false
	}

	if forceupdate || ((A_TickCount - lastcheck) > WATCHDICTATE_UPDATE_INTERVAL) {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndPS)
			if FindText(&x, &y, x0, y0 + 16, x0 + w0, y0 + 128, 0.001, 0.001, PAText["PSDictateOn"]) {
				dictatestatus := true
			} else {
				dictatestatus := false
			}
		} catch {
			dictatestatus := false
		}
		lastcheck := A_TickCount
	}

	return dictatestatus
}


; Functions to detect whether a specific PS desktop page is showing. 
;
; Returns true if the page is showing, false if not.
;
; Valid IE desktop pages are: search, list, text, image
;
PSIsReport() {
	if PAWindows["PS"]["report"].hwnd || PAWindows["PS"]["addendum"].hwnd {
		return true
	}
	return false
}




/**
 * Hook functions
 * 
 */


; Hook function called when PS login window appears
;
PSOpen_PSlogin() {
	; Restore PS window positions
	PAWindows.RestoreWindows("PS")

	PASound("Powerscribe started")
}


; Hook function called when PS main window appears
;

PSOpen_PSmain() {
	; remove the current patient
	PACurrentPatient.lastfirst := ""
	PACurrentPatient.dob := ""
	PACurrentPatient.sex := ""

	PACurrentStudy.lastfirst := ""
	PACurrentStudy.dobraw := ""
	PACurrentStudy.description := ""
	PACurrentStudy.facility := ""
	PACurrentStudy.patienttype := ""
	PACurrentStudy.priority := ""
	PACurrentStudy.orderingmd := ""
	PACurrentStudy.referringmd := ""
	PACurrentStudy.reason := ""
	PACurrentStudy.techcomments := ""
}


; Hook function called when PS main window goes away
;
PSClose_PSmain() {

}


; helper function called by PSOpen_PSreport() and PSClose_PSreport()
_PSStopDictate() {
	global PA_Dictate_autooff

	; only turn off mic if user is report window is not reopened within timeout
	if PA_Dictate_autooff {
		PSSend("{F4}")						; Stop Dictation
;		PASound("toggle dictate")
		PA_Dictate_autooff := false
	}
}


; Hook function called when PS report window appears
PSOpen_PSreport() {
	global PACurrentPatient
	global PACurrentStudy
	global PA_Dictate_autooff

	PAStatus("Report opened")

	; When the PS report window appears, refresh the current patient in PA
	
	PACurrentPatient.lastfirst := ""
	PACurrentPatient.dob := ""
	PACurrentPatient.sex := ""

	PACurrentStudy.lastfirst := ""
	PACurrentStudy.dobraw := ""
	PACurrentStudy.accession := ""
	PACurrentStudy.description := ""
	PACurrentStudy.facility := ""
	PACurrentStudy.patienttype := ""
	PACurrentStudy.priority := ""
	PACurrentStudy.orderingmd := ""
	PACurrentStudy.referringmd := ""
	PACurrentStudy.reason := ""
	PACurrentStudy.techcomments := ""

	Sleep(1000)		; try to improve reliability of EI data scraping

	pt := EIRetrievePatientInfo()
	if pt { 
		PACurrentPatient.lastname := pt.lastname
		PACurrentPatient.firstname := pt.firstname
		PACurrentPatient.dob := pt.dob
		PACurrentPatient.sex := pt.sex

		st := EIRetrieveStudyInfo(pt)
		If st {
			PACurrentStudy.lastfirst := st.lastfirst
			PACurrentStudy.dobraw := st.dobraw
			PACurrentStudy.accession := st.accession
			PACurrentStudy.description := st.description
			PACurrentStudy.facility := st.facility
			PACurrentStudy.patienttype := st.patienttype
			PACurrentStudy.priority := st.priority
			PACurrentStudy.orderingmd := st.orderingmd
			PACurrentStudy.referringmd := st.referringmd
			PACurrentStudy.reason := st.reason
			PACurrentStudy.techcomments := st.techcomments
		}
	}

	if PAOptions["PS_dictate_autoon"].setting {
		if PA_Dictate_autooff {
			; mic should already by on, so cancel the autooff timer and don't toggle the mic
			SetTimer(_PSStopDictate, 0)		; cancel pending microphone off action	
			PA_Dictate_autooff := false
		} else if !PSDictateIsOn(true) {
			; mic is not on so start dication
			PSSend("{F4}")						; Start Dictation
			PASound("toggle dictate")
		}
	}	

	; if PA_Dictate_autooff {
	; 	; mic should already by on, so don't do anything
	; 	PA_Dictate_autooff := false
	; 	SetTimer(_PSStopDictate, 0)		; cancel pending microphone off action
	; } else {
	; 	if PAOptions["PS_dictate_autoon"] && !PSDictateIsOn(true) {
	; 		PSSend("{F4}")						; Start Dictation
	; 		PASound("toggle dictate")
	; 	}
	; }

}


; Hook function called when PS report window goes away
PSClose_PSreport() {
	global PA_Dictate_autooff

	if PAOptions["PS_dictate_autoon"].setting && PSDictateIsOn(true) {
		; Stop dictation afer a delay, to see whether user is dictating
		; another report (in which case don't turn off dictate mode).
		PA_Dictate_autooff := true
		SetTimer(_PSStopDictate, -PS_DICTATEAUTOOFF_DELAY)		; turn off mic after delay
	}
}


; Hook function called when PS window appears
PSOpen_PSlogout() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["logout"].CenterWindow(_PSParent())
	}
	if PAOptions["PSlogout_dismiss"].setting {
		Sleep(1000)			; delay 1s
		PAToolTip("yes")
		ControlClick(PAOptions["PSlogout_dismiss_reply"].setting, PAWindows["PS"]["logout"].hwnd)
	}
}

; Hook function called when PS window appears
PSOpen_PSsavespeech() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["savespeech"].CenterWindow(_PSParent())
	}
	if PAOptions["PSsavespeech_dismiss"].setting {
		Sleep(1000)			; delay 1s
		ControlClick(PAOptions["PSsavespeech_dismiss_reply"].setting, PAWindows["PS"]["confirmaddendum"].hwnd)
	}
}

; Hook function called when PS window appears
PSOpen_PSsavereport() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["savereport"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSdeletereport() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["deletereport"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSunfilled() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["unfilled"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSconfirmaddendum() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["confirmaddendum"].CenterWindow(_PSParent())
	}
	if PAOptions["PSconfirmaddendum_dismiss"].setting {
		Sleep(1000)			; delay 1s
		ControlClick(PAOptions["PSconfirmaddendum_dismiss_reply"].setting, PAWindows["PS"]["confirmaddendum"].hwnd)
	}
}

; Hook function called when PS window appears
PSOpen_PSconfirmanotheraddendum() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["confirmanotheraddendum"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSexisting() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["existing"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PScontinue() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["continue"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSownership() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["ownership"].CenterWindow(_PSParent())
	}
}

; Hook function called when PS window appears
PSOpen_PSmicrophone() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["microphone"].CenterWindow(_PSParent())
	}
	if PAOptions["PSmicrophone_dismiss"].setting {
		Sleep(1000)			; delay 1s
		ControlClick(PAOptions["PSmicrophone_dismiss_reply"].setting, PAWindows["PS"]["microphone"].hwnd)
	}
}

; Hook function called when PS window appears
PSOpen_PSfind() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["find"].CenterWindow(_PSParent())
	}
}

PSOpen_PSspelling() {
	if PAOptions["PScenter_dialog"].setting {
		PAWindows["PS"]["spelling"].CenterWindow(_PSParent())
	}
}


; returns the WindowItem for either PSmain, PSreport, PSaddendum, or PSlogin
_PSParent() {
	if PAWindows["PS"]["main"].hwnd {
		return PAWindows["PS"]["main"]
	}
	if PAWindows["PS"]["report"].hwnd {
		return PAWindows["PS"]["report"]
	}
	if PAWindows["PS"]["addendum"].hwnd {
		return PAWindows["PS"]["addendum"]
	}
	if PAWindows["PS"]["login"].hwnd {
		return PAWindows["PS"]["login"]
	}
}




/***********************************************/


/**
 * Start up and Shut down functions
 * 
 */





/***********************************************/



/**
 * 
 * 
 */




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
