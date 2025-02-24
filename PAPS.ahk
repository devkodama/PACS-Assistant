/**
 * PAPS.ahk
 *
 * Functions for working with PowerScribe 360
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

#Include PACSAssistant.ahk




/**********************************************************
 * Global variables and constants used in this module
 */


; This is used internally by _PSStopDictate() to determine whether to turn off the mic
global _Dictate_autooff := false




/**********************************************************
 * Functions to send info to PS
 * 
 */


; Send keystroke to PowerScribe
;
; Can be either the login, main, report, or addendum window
;
PSSend(cmdstring := "") {
    global PAWindowBusy

	if (cmdstring) {
		winitem := PSParent()
		if winitem {
			hwndPS := winitem.hwnd

			; at this point hwndPS is non-null and points to the current PS window
			PAWindowBusy := true
			WinActivate(hwndPS)
			Send(cmdstring)
			PAWindowBusy := false
		}
	}

		; if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
		; 	return
		; }

		; at this point hwndPS is non-null and points to the current PS window
	; 	PAWindowBusy := true
	; 	WinActivate(hwndPS)
	; 	Send(cmdstring)
	; 	PAWindowBusy := false
	; }

}


; Paste a chunk of text into PowerScribe
;
; Ensures either the PS report window or PS addendum window will be receiving the paste.
;
; Uses the clipboard, restoring the previous clipboard contents when finished.
;
PSPaste(text := "") {
    global PAWindowBusy

	if (text) {
		if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
			return
		}

		; at this point hwndPS is non-null and points to the current PS window
		PAWindowBusy := true
		saveclipboard := A_Clipboard
		A_Clipboard := text
		WinActivate(hwndPS)
		SendInput("^v")					; paste the text
		Sleep(100)					; requires a delay before restoring keyboard, or else the ^v paste will send the wrong contents (the saved clipboard)
		A_Clipboard := saveclipboard
		PAWindowBusy := false
	}
}




/**********************************************************
 * Functions to retrieve info about PS
 */


; Returns the WindowItem for either PSmain, PSreport, PSaddendum, or PSlogin, 
; if they exist (checked in that order).
;
; Returns 0 if none of them exist.
PSParent() {
	if PAWindows["PS"]["main"].hwnd {
		return PAWindows["PS"]["main"]
	} else if PAWindows["PS"]["report"].hwnd {
		return PAWindows["PS"]["report"]
	} else if PAWindows["PS"]["addendum"].hwnd {
		return PAWindows["PS"]["addendum"]
	} else if PAWindows["PS"]["login"].hwnd {
		return PAWindows["PS"]["login"]
	} else {
		return 0
	}
}


; Returns the state of the PS360 Dictate button by reading the toolbar button
; The Dicate button must be visible on screen
; 
; If the Dictate button is On, returns true
; Otherwise returns false
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
; depends upon this function being called frequently (as it typically is by PADaemon()).
;
PSDictateIsOn(forceupdate := false) {
	static dictatestatus := false
	static lastcheck := A_TickCount

	; if PS report or addendum or main window does not exist, return false
	if !(hwndPS := PAWindows["PS"]["report"].hwnd) && !(hwndPS := PAWindows["PS"]["main"].hwnd) && !(hwndPS := PAWindows["PS"]["addendum"].hwnd) {
		dictatestatus := false
	} else if forceupdate || ((A_TickCount - lastcheck) > WATCHDICTATE_UPDATE_INTERVAL) {
		try {
			WinGetClientPos(&x0, &y0, &w0, &h0, hwndPS)
			if FindText(&x, &y, x0, y0 + 16, x0 + w0, y0 + 128, 0.001, 0.001, PAText["PSDictateOn"]) {
				; dictate button is on
				if PASettings["PS_dictate_idleoff"].value {
					; A_TimeIdlePhysical is the number of milliseconds that have elapsed since the system last received physical keyboard or mouse input
					; PASettings["PS_dictate_idletimeout"].value is in minutes, so multiply by 60000 to get milliseconds
					if dictatestatus && A_TimeIdlePhysical > (PASettings["PS_dictate_idletimeout"].value * 60000) {
						; microphone is currently on and we have idled for greater than timeout, so turn off the mic
						PSSend("{F4}")		; Stop Dictation
						dictatestatus := false
					} else {
						; haven't idled long enough, don't turn off mic
						dictatestatus := true
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


; Functions to detect whether a specific PS window is showing. 
;
; PS windows are login, main, or report. The addendum window is considered a report window.
;
; Returns true if the page is showing, false if not.
;
PSIsLogin() {
	return PAWindows["PS"]["login"].hwnd ? true : false
}
PSIsMain() {
	return PAWindows["PS"]["main"].hwnd ? true : false
}
PSIsReport() {
	return PAWindows["PS"]["report"].hwnd || PAWindows["PS"]["addendum"].hwnd ? true : false
}




/**********************************************************
 * Hook functions called on PS events
 */


; Hook function called when PS login window appears
;
PSOpen_PSlogin() {

	; [todo] determine if PS was just opened or just closed

	if PASettings["PS_restoreatopen"].value {
		; Restore PS window positions
		PAWindows.RestoreWindows("PS")
	}

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
	global _Dictate_autooff

	; only turn off mic if user is report window is not reopened within timeout
	if _Dictate_autooff {
		PSSend("{F4}")						; Stop Dictation
;		PASound("PSToggleMic")
		_Dictate_autooff := false
	}
}


; Hook function called when PS report window appears
PSOpen_PSreport() {
	global PACurrentPatient
	global PACurrentStudy
	global _Dictate_autooff

	PAStatus("Report opened")

	; Automatically turn on microphone when opening a report (and off when closing a report)
	if PASettings["PS_dictate_autoon"].value {
PAToolTip("ao")
		if _Dictate_autooff {
PAToolTip("ao keep")
			; mic should already by on, so cancel the autooff timer
			SetTimer(_PSStopDictate, 0)		; cancel pending microphone off action	
			_Dictate_autooff := false
		}
		; check to ensure the mic is on, turn it on if it isn't
		if !PSDictateIsOn(true) {			
PAToolTip("ao on")
			; mic is not on so turn it on
			PSSend("{F4}")						; Start Dictation
			PASound("PSToggleMic")
		}
	}	



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

;	Sleep(1000)		; try to improve reliability of EI data scraping

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

}


; Hook function called when PS report window goes away
PSClose_PSreport() {
	global _Dictate_autooff

	if PASettings["PS_dictate_autoon"].value && PSDictateIsOn(true) {
		; Stop dictation afer a delay, to see whether user is dictating
		; another report (in which case don't turn off dictate mode).
		_Dictate_autooff := true
		SetTimer(_PSStopDictate, -(PS_DICTATEAUTOOFF_DELAY * 1000))		; turn off mic after delay
	}
}


; Hook function called when PS window appears
PSOpen_PSlogout() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["logout"].CenterWindow(PSParent())
	}
;PAToolTip(PASettings["PSlogout_dismiss"].value " / " PASettings["PSlogout_dismiss_reply"].key " / " PASettings["PSlogout_dismiss_reply"].value)
	if PASettings["PSlogout_dismiss"].value {
		if PAWindows["PS"]["logout"].hwnd {
;			ControlSend("{Enter}", PASettings["PSlogout_dismiss_reply"].value, PAWindows["PS"]["logout"].hwnd)
SetControlDelay -1
ControlClick(PASettings["PSlogout_dismiss_reply"].value, PAWindows["PS"]["logout"].hwnd)
		}
	}
}


; Hook function called when PS window appears
PSOpen_PSsavespeech() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["savespeech"].CenterWindow(PSParent())
	}
	if PASettings["PSsavespeech_dismiss"].value {
		if PAWindows["PS"]["savespeech"].hwnd {
SetControlDelay -1
ControlClick(PASettings["PSsavespeech_dismiss_reply"].value, PAWindows["PS"]["savespeech"].hwnd)
		}
	}
}


; Hook function called when PS window appears
PSOpen_PSsavereport() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["savereport"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSdeletereport() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["deletereport"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSunfilled() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["unfilled"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSconfirmaddendum() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["confirmaddendum"].CenterWindow(PSParent())
	}
	if PASettings["PSconfirmaddendum_dismiss"].value {
		if PAWindows["PS"]["confirmaddendum"].hwnd {
SetControlDelay -1
ControlClick(PASettings["PSconfirmaddendum_dismiss_reply"].value, PAWindows["PS"]["confirmaddendum"].hwnd)
		}
	}
}


; Hook function called when PS window appears
PSOpen_PSconfirmanotheraddendum() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["confirmanotheraddendum"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSexisting() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["existing"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PScontinue() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["continue"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSownership() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["ownership"].CenterWindow(PSParent())
	}
}


; Hook function called when PS window appears
PSOpen_PSmicrophone() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["microphone"].CenterWindow(PSParent())
	}
	if PASettings["PSmicrophone_dismiss"].value {
		if PAWindows["PS"]["microphone"].hwnd {
			SetControlDelay -1
			ControlClick(PASettings["PSmicrophone_dismiss_reply"].value, PAWindows["PS"]["microphone"].hwnd)
		}
	}
}


; Hook function called when PS window appears
PSOpen_PSfind() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["find"].CenterWindow(PSParent())
	}
}


; Hook function called when PS spelling appears
PSOpen_PSspelling() {
	if PASettings["PScenter_dialog"].value {
		PAWindows["PS"]["spelling"].CenterWindow(PSParent())
	}
}




/**********************************************************
 * Start up and Shut down functions
 * 
 */


; [todo]
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If PS is already running, returns immediately with return value 1.
;
; Returns 1 if successful at starting PS, 0 if not
; 
PSStart() {
	return 0
}


; Shut down PS
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If PS is already stopped, returns immediately with return value 1.
;
; Returns 1 if successful, 0 if not
; 
PSStop(sendclose := true) {

	tick0 := A_TickCount

	PAStatus("Shutting down PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	PAGui_ShowCancelButton()

	if sendclose {
		PSSend("!{F4}")
	}

	result := false
	cancelled := false
	winitem := PSParent()
	
	while !cancelled && winitem && (A_TickCount-tick0 < PS_SHUTDOWN_TIMEOUT * 1000) {
		PAStatus("Shutting down PowerScribe... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		if winitem.winkey == "login" {
			; We're at the login window. Close it.
			PSSend("!{F4}")
		}
		Sleep(500)
		PAWindows.Update("PS")
		winitem := PSParent()
		if PACancelRequest {
			cancelled := true
			break
		}
	}

	PAGui_HideCancelButton()

	if cancelled {
		PAStatus("PowerScribe shut down cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := false
	} else if winitem {
		; PS still didn't close (timed out)
		PAStatus("Could not shut down PowerScribe (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := false
	} else {
		PAStatus("PowerScribe shut down (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		result := true
	}

	return result
}




/**********************************************************
 * PS data retrieval and parsing functions
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




/**********************************************************
 * PS Commands
 *  
 */


; Sends the Next field command (Tab) to PS
PSCmdNextField() {
	PSSend("{Tab}")
	PASound("PSTab")
}


; Sends the Prev field command (Shift-Tab) to PS
PSCmdPrevField() {
	PSSend("{Blind}+{Tab}")
	PASound("PSTab")
}


; Move the cursor to the End of Line in PS
PSCmdEOL() {
	PSSend("{End}")
	PASound("PSTab")
}


; Move the cursor down one line then to the End of Line in PS
PSCmdNextEOL() {
	PSSend("{Down}{End}")
	PASound("PSTab")
}


; Move the cursor up one line then to the End of Line in PS
PSCmdPrevEOL() {
	PSSend("{Up}{End}")
	PASound("PSTab")
}


; Start/Stop Dictation (Toggle Microphone) => F4 in PS
PSCmdToggleMic() {
	PSSend("{F4}")							; Start/Stop Dictation
	PASound("PSToggleMic")
}


; Sign report => F12 in PS
PSCmdSignReport() {
	PSSend("{F12}")							; Sign report
	PASound("PSSignReport")
}


; Save as Draft => F9 in PS
PSCmdDraftReport() {
	PSSend("{F9}")							; save as Draft
	PASound("PSDraftReport")
}


; Save as Prelim => File > Prelim in PS
PSCmdPreliminary() {
	PSSend("{Alt down}fm{Alt up}")			; save as Prelim
	PASound("PSSPreliminary")
}

