/* PADaemon.ahk
**
** Daemon procedures that run in the background for PACS Assistant
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force


/*
** Global variables and constants
*/

;global PAWindows
;global PAGui





#include PAICDCode.ahk




/***********************************************/


; Start or stop daemons

InitDaemons(start := true) {
	global PA_Active

	; These always run, regardless of PA_Active
	SetTimer(_Dispatcher, DISPATCH_INTERVAL)
	SetTimer(_RefreshGUI, GUIREFRESH_INTERVAL)

	; These run depending on the state of PA_Active and the parameter start
	; If either one is false, don't activate these daemons
	if !PA_Active {
		start := false
	}
	SetTimer(_WatchWindows, (start ? WATCHWINDOWS_UPDATE_INTERVAL : 0))
	SetTimer(_WatchMouse, (start ? WATCHMOUSE_UPDATE_INTERVAL : 0))
	SetTimer(_JiggleMouse, (start ? JIGGLEMOUSE_UPDATE_INTERVAL : 0))

}


/***********************************************/

; Checks the dispatch request queue and calls the queued functions.
;
; The dispatcher is dumb and does not check whether the function is already running.
; Every function callable by the dispatcher should check for and prevent reentry.
;
_Dispatcher() {
	global DispatchQueue

	if DispatchQueue.Length > 0 {
		fn := DispatchQueue.RemoveAt(1)

		; ToolTip(fn.Name . " started")
		fn()

		;		ToolTip(fn.Name . " finished")
	}
}


; Refreshes the GUI display
;
_RefreshGUI() {
	global PAGui
	global PA_Active
	global PAStatusBarText
	global PAStatus_PowerButton
	global PACurrentPatient
	global PACurrentStudy
	global PAWindowInfo

	static running := false
	static statusbartext := ""
	static statusbarlastupdate := A_TickCount
	static curstate := Map(
		"microphone", "",
		"PA", 0,
		"VPN", "",
		"EI", "",
		"PS", "",
		"EPIC", "",
		"power", ""
	)

	; don't allow reentry
	if running {
		return
	}
	running := true

	; Update current patient display if there have been any changes
	if true || PACurrentPatient.changed {

		patientname := StrUpper(PACurrentPatient.lastfirst)
		dob := PACurrentPatient.dob
		age := PACurrentPatient.age
		sex := PACurrentPatient.sex

		PAGui.PostWebMessageAsString("document.getElementById('patientname').innerHTML = `"" . patientname . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('dob').innerHTML = `"" . dob . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('agesex').innerHTML = `"" . age . " " . sex . "`"")

		; reset changed flag
		PACurrentPatient.changed := false
	}
	; Update current study display if there have been any changes
	if true || PACurrentStudy.changed {

		if true || PACurrentStudy.accession {

			studyinfo := ""
			studyinfo .= "acc=" . PACurrentStudy.accession
			studyinfo .= " // " . PACurrentStudy.description
			studyinfo .= "<br />" . PACurrentStudy.facility
			studyinfo .= " // " . PACurrentStudy.patienttype
			studyinfo .= " // " . PACurrentStudy.priority
			studyinfo .= " // " . PACurrentStudy.orderingmd
			for o in PACurrentStudy.other {
				studyinfo .= " // other=" . o
			}
			studyinfo .= "<br /><br />REASON: " . PACurrentStudy.reason
			studyinfo .= "<br /><br />COMMENTS: " . PACurrentStudy.techcomments
			studyinfo .= "<br /><br />"

			icdcodes := ""
			spos := 1
			while fpos := RegExMatch(PACurrentStudy.reason, "i)\b([A-TV-Z][0-9][A-Z0-9](\.?[A-Z0-9]{0,4})?)\b", &fobj, spos) {
	;	            msgbox "Found icd10: " fobj[0] " spos: " spos " fpos: " fpos " fobj.Len: " fobj.Len
				icdcodes .= (icdcodes?"<br />":"") . fobj[0] . " - " . ICDLookupCode(fobj[0])
				spos := fpos + fobj.Len
			}
			spos := 1
			while fpos := RegExMatch(PACurrentStudy.techcomments, "i)\b([A-TV-Z][0-9][A-Z0-9](\.?[A-Z0-9]{0,4})?)\b", &fobj, spos) {
	;	            msgbox "Found icd10: " fobj[0] " spos: " spos " fpos: " fpos " fobj.Len: " fobj.Len
				icdcodes .= (icdcodes?"<br />":"") . fobj[0] . " - " . ICDLookupCode(fobj[0])
				spos := fpos + fobj.Len
			}

			if icdcodes {
				studyinfo .= "ICD Codes: " . icdcodes . "<br />"
			}

	;PAToolTip(studyinfo)
		} else {

			studyinfo := "No exam"
		}

		PAGui.PostWebMessageAsString("document.getElementById('studyinfo').innerHTML = '" . studyinfo . "'")

		; reset changed flag
		PACurrentStudy.changed := false
	}

	; Update window info area
	PAGui.PostWebMessageAsString("document.getElementById('windowinfo').innerHTML = `"" . PAWindowInfo . A_Now . "`"")


	; Update status bar text
	if (statusbartext != PAStatusBarText) {
		statusbartext := PAStatusBarText
		PAGui.PostWebMessageAsString("document.getElementById('statusbartext').innerHTML = `"" . PAStatusBarText . "`"")
		statusbarlastupdate := A_TickCount
	} else if A_TickCount - statusbarlastupdate > GUISTATUSBAR_TIMEOUT {
		; remove status message after timeout period
		PAGui.PostWebMessageAsString("document.getElementById('statusbartext').innerHTML = `"`"")
	}


	; update dictate button (microphone) status
	dictateon := PSDictateIsOn()
	if  dictateon && curstate["microphone"] != "true" {
		statustext := MICROPHONETEXT_ON
		statuscolor := MICROPHONECOLOR_ON
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').innerHTML = `"" . statustext . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').style = `"background-color: " . statuscolor . ";`"")
		curstate["microphone"] := "true"
	} else if !dictateon && curstate["microphone"] != "false" {
		statustext := MICROPHONETEXT_OFF
		statuscolor := MICROPHONECOLOR_OFF
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').innerHTML = `"" . statustext . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').style = `"background-color: " . statuscolor . ";`"")
		curstate["microphone"] := "false"
	}



	; Update app icon indicators
	status := 0x00

	; update VPN status on GUI
	connected := VPNIsConnected()
	if connected {
		status |= 0x01
		if curstate["VPN"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-connected.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: block;`"")
			curstate["VPN"] := "true"
		}
	} else if !connected && curstate["VPN"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: none;`"")
		curstate["VPN"] := "false"
	}

	; update EI desktop status on GUI
	visible := PAWindows["EI"]["desktop"].visible
	if visible {
		status |= 0x02
		if curstate["EI"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-EI').style = `"background-image: url('images/EI.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EI-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EI-shutdown').style = `"display: block;`"")
			curstate["EI"] := "true"
		}
	} else if !visible && curstate["EI"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-EI').style = `"background-image: url('images/EI-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EI-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EI-shutdown').style = `"display: none;`"")
		curstate["EI"] := "false"
	}

	; update PS status on GUI
	visible := PAWindows["PS"]["main"].visible || PAWindows["PS"]["report"].visible
	if visible {
		status |= 0x04
		if curstate["PS"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-PS').style = `"background-image: url('images/PS.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-shutdown').style = `"display: block;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-forceclose').style = `"display: block;`"")
			curstate["PS"] := "true"
		}
	} else if !visible && curstate["PS"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-PS').style = `"background-image: url('images/PS-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-shutdown').style = `"display: none;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-forceclose').style = `"display: none;`"")
		curstate["PS"] := "false"
	}

	; update EPIC status on GUI
	visible := PAWindows["EPIC"]["main"].visible
	if visible {
		status |= 0x08
		if curstate["EPIC"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC').style = `"background-image: url('images/EPIC.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-shutdown').style = `"display: block;`"")
			curstate["EPIC"] := "true"
		}
	} else if !visible && curstate["EPIC"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC').style = `"background-image: url('images/EPIC-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-shutdown').style = `"display: none;`"")
		curstate["EPIC"] := "false"
	}

	; update power button status on GUI
	; also update global PAStatus_PowerButon with the same status
	switch status {
		case 0x00:
			if curstate["power"] != "off" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-off.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"Press to start PACS`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: block;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: none;`"")
				curstate["power"] := "off"
				PAStatus_PowerButton := "off"
			}
		case 0x0f:
			if curstate["power"] != "green" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-green.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"PACS is running`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: none;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: block;`"")
				curstate["power"] := "green"
				PAStatus_PowerButton := "green"
			}
		default:
			if curstate["power"] != "yellow" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-yellow.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"PACS is starting up...`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: block;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: block;`"")
				curstate["power"] := "yellow"
				PAStatus_PowerButton := "yellow"
			}
	}

	; update buttons if necessary
	if  curstate["PA"] != PA_Active {
		curstate["PA"] := PA_Active
		PAGui.PostWebMessageAsString("document.getElementById('button-togglePA').innerHTML = `"" . (PA_Active?"Disable PACS Assistant":"Enable PACS Assistant") . "`"")
	}

	; done
	running := false
	return
}



; Jiggle the mouse to keep screen awake
_JiggleMouse() {
	if PAOptions["MouseJiggler"].setting {
		MouseMove(1, 1, , "R")
		MouseMove(-1, -1, , "R")
	}
}



/***********************************************/

; Update the hwnd of the window under the mouse cursor
;
; Also makes the window active if appropriate.
; Automatic window activation is suspended if Shift key is being held down
;
; Typically used with a timer, e.g. SetTimer(_WatchMouse, UPDATE_INTERVAL)
;
; PA_Active must be true for this function to be active
;
_WatchMouse() {
	global PA_Active
	global PA_WindowUnderMouse
	global PA_WindowBusy
	static running := false
	static restore_EPICchat := 0	; either 0, or array of [x, y, w, h, extended_h]

	; PA_Active must be true for this function to be active
	if !PA_Active {
		return
	}

	; don't allow reentry
	if running {
		return
	}
	running := true

	; local function to restore windows that have been enlarged
	_RestoreSaved() {
		if restore_EPICchat {
			hwndEPICchat := PAWindows["EPIC"]["chat"].hwnd
			try {
				WinGetPos(&x, &y, &w, &h, hwndEPICchat)
				if x != restore_EPICchat[1] || y != restore_EPICchat[2] || w != restore_EPICchat[3] || h != restore_EPICchat[5] {
					; user moved the window after it was enlarged, don't restore
				} else {
					if hwndEPICchat {
						WinMove(restore_EPICchat[1], restore_EPICchat[2], restore_EPICchat[3], restore_EPICchat[4], hwndEPICchat)
					}
				}
				restore_EPICchat := 0
			} catch {
				PAWindows["EPIC"]["chat"].Update()
			}
		}
	}
	; local function to autoclose the PS spelling window
	_ClosePSspelling() {
		if PAOptions["PSspelling_autoclose"] && PAWindows["PS"]["spelling"].visible {
			PAWindows["PS"]["spelling"].Close()
		}
	}

	; get the handle of the window under the mouse
	MouseGetPos(, , &hwnd)

	; store it
	PA_WindowUnderMouse := hwnd

	; activate window under the mouse, if appropriate
	;
	; only activate window if another window is not busy
	; and if not already active
	; and Lshift is not being held down
	if !PA_WindowBusy && !GetKeyState("LShift", "P") && !WinActive(hwnd) && PAWindows.GetAppWin(hwnd, &app, &win) {
		switch app {
			case "EI":
				; close PS Spelling window
				_ClosePSspelling()

				; don't activate if there are more than one PS windows open
				if _WindowKeys.CountAppWindows("PS") < 2 {
					_RestoreSaved()
					WinActivate(hwnd)
				}
			case "PS":
				_RestoreSaved()
				WinActivate(hwnd)
			case "PA":
				_RestoreSaved()
				WinActivate(hwnd)
			case "EPIC":
				switch win {
					case "chat":
						if !restore_EPICchat {
							WinGetPos(&x, &y, &w, &h, hwnd)
							if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
								extended_h := (h < 600) ? 600 : h
								restore_EPICchat := [x, y, w, h, extended_h]
								WinMove(x, y, w, extended_h, hwnd)
								; [todo] if mouse was in bottom 70px of the chat window, move the mouse down by the same amount as the window was extended downwards
								CoordMode "Mouse", "Screen"
								MouseGetPos(&mousex, &mousey)
								;							msgbox x ", " y ", " w ", " h "/" extended_h ", " mousex ", " mousey
								if mousey >= y + h - 70 {
									MouseMove(mousex, mousey + extended_h - h)
								}
							} else {
								restore_EPICchat := 0
							}
						}
						_ClosePSspelling()
						; don't activate if there are more than one PS windows open
						if _WindowKeys.CountAppWindows("PS") < 2 {
							WinActivate(hwnd)
						}
					default:
						_ClosePSspelling()
						; don't activate if there are more than one PS windows open
						if _WindowKeys.CountAppWindows("PS") < 2 {
							_RestoreSaved()
							WinActivate(hwnd)
						}
				}
			default:
				; do nothing
		}
	}

	running := false
	return
}



; Update the status of all PAWindows
;
; Typically used with a timer, e.g. SetTimer(_WatchWindows, UPDATE_INTERVAL)
;
_WatchWindows() {
	global PA_Active
	global PAWindows
	global PAWindowInfo
	
	; update the open/visibility status of all windows
	PAWindows.Update()

	; update status of psuedowindows (pages within some windows like EI desktop or EPIC)
	


	; [todo] if PS spelling window is open for more than 1 second while mouse is not
	; over a PS window, then close it

	; update window info for GUI
	PAWindowInfo := PAWindows.Print() . "#" . EIGetStudyMode() . "#"


}