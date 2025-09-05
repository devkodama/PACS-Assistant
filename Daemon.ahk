/**
 * Daemon.ahk
 * 
 * Daemons that run in the background for PACS Assistant
 * 
 * 
 * This module defines the functions:
 * 
 * 	DaemonInit(start := true)			- Start or stop daemons
 * 
 * 	_Dispatcher()						- Checks the dispatch request queue and calls the queued functions
 * 	_RefreshGUI()						- Refreshes the GUI display
 * 	_WatchWindows()						- Update the status of all windows
 * 
 * 	_WatchMouse()						- Update the hwnd of the window under the mouse cursor
 * 	_JiggleMouse()						- Jiggle the mouse to keep screen awake
 *  _ClearCapsLock()					- Clear CapsLock after no keyboard input for a specified time
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Functions defined by this module
 * 
 */


; Start or stop daemons
;
DaemonInit(start := true) {

	; these daemons run regardless of PAActive
	SetTimer(_Dispatcher, (start ? DISPATCH_INTERVAL : 0))
	SetTimer(_RefreshGUI, (start ? GUIREFRESH_INTERVAL : 0))
	SetTimer(_WatchWindows, (start ? WATCHWINDOWS_UPDATE_INTERVAL : 0))

	; these daemons only act if PAActive is true
	SetTimer(_WatchMouse, (start ? WATCHMOUSE_UPDATE_INTERVAL : 0))
	SetTimer(_JiggleMouse, (start ? JIGGLEMOUSE_UPDATE_INTERVAL : 0))
	SetTimer(_ClearCapsLock, (start ? CAPSLOCK_TIMEOUT / 2 : 0))
}




/**********************************************************
 * Local functions used within this module
 * 
 */


; Checks the dispatch request queues and calls the queued functions.
;
; The dispatcher is dumb and does not check whether the function is already running.
; Every function callable by the dispatcher should check for and prevent reentry if neceesary.
_Dispatcher() {
	global DispatchQueue
	global HookShowQueue
	global HookCloseQueue
	; runs regardless of PAActive

	if DispatchQueue.Length > 0 {
		; call fn() via SetTimer to simulate multithreading
		fn := DispatchQueue.RemoveAt(1)
		SetTimer(fn, -1)
	}
	
	if HookShowQueue.Length > 0 {
		; call fn() via SetTimer to simulate multithreading
		fn := HookShowQueue.RemoveAt(1)
		SetTimer(fn, -1)
	}
	
	if HookCloseQueue.Length > 0 {
		; call fn() via SetTimer to simulate multithreading
		fn := HookCloseQueue.RemoveAt(1)
		SetTimer(fn, -1)
	}
	
}


; Refreshes the GUI display
;
_RefreshGUI() {
	global PAGui
	global PAActive
	global PAStatusBarText
	global PAStatus_PowerButton
	global PACurrentPatient
	global PACurrentStudy
	global PAWindowInfo
	global PACurState

	static running := false
	static statusbartext := ""
	static statusbarlastupdate := A_TickCount
	
	; runs regardless of PAActive

	; don't allow reentry
	if running {
;		return
	}
	running := true

	; Update current patient display if there have been any changes
	if PACurrentPatient.changed {

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
	if PACurrentStudy.changed {

		studyinfo := ""
		; studyinfo .= "acc=" . PACurrentStudy.accession
		studyinfo .= "<br /><b>" PACurrentStudy.description "</b>"

; ToolTip(PACurrentStudy.description)
; Sleep(500)

		; studyinfo .= "<br />" . PACurrentStudy.facility
		; studyinfo .= " // " . PACurrentStudy.patienttype
		; studyinfo .= " // " . PACurrentStudy.priority
		studyinfo .= "<br /> " . StrTitle(PACurrentStudy.orderingmd)

		studyinfo .= "<br /><br />laterality: " . PACurrentStudy.laterality


		for o in PACurrentStudy.other {
			studyinfo .= "<br /> other: " . o
		}
		; studyinfo .= "<br /><br /><span style ='color: #808080; font-size: 0.8em;'>reason </span>" . PACurrentStudy.reason
		; studyinfo .= "<br /><span style ='color: #808080; font-size: 0.8em;'>tech</span>" . PACurrentStudy.techcomments
		studyinfo .= "<br /><span>reason: </span>" . PACurrentStudy.reason
		studyinfo .= "<br /><span >tech: </span>" . PACurrentStudy.techcomments

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

		; if any icdcodes were found, show them 
		if icdcodes {
			studyinfo .= "ICD Codes: " . icdcodes . "<br />"
		}
	
; PAToolTip(studyinfo)

		; reset changed flag
		PACurrentStudy.changed := false

		PAGui.PostWebMessageAsString("document.getElementById('studyinfo').innerHTML = '" . studyinfo . "'")

	} else {

		studyinfo := "No exam"
;  PAToolTip(studyinfo)

	;	PAGui.PostWebMessageAsString("document.getElementById('studyinfo').innerHTML = '" . studyinfo . "'")

	}


	; Update window info area
	PAGui.PostWebMessageAsString("document.getElementById('windowinfo').innerHTML = `"" . PAWindowInfo . "`"")

	; debug - status of all windows
	; output := ""
	; for , a in App {
	; 	for , w in a.Win {
	; 		output .= a.key "/" w.key "-" w.hwnd " " (w.visible?"v":"h") (w.minimized?"/m":"") "<br />"
	; 	}
	; }
	; PAGui.PostWebMessageAsString("document.getElementById('windowinfo').innerHTML = `"" . output . "`"")


	; Update status bar text
	if true || (statusbartext != PAStatusBarText) {
		statusbartext := PAStatusBarText
		PAGui.PostWebMessageAsString("document.getElementById('statusbartext').innerHTML = `"" . PAStatusBarText . "`"")
		statusbarlastupdate := A_TickCount
	} else if (A_TickCount - statusbarlastupdate) > GUISTATUSBAR_TIMEOUT {
		; remove status message after timeout period
		PAGui.PostWebMessageAsString("document.getElementById('statusbartext').innerHTML = `"`"")
	}


	; update dictate button (microphone) status
	dictateon := PSDictateIsOn()
	if dictateon && PACurState["microphone"] != "true" {
		statustext := MICROPHONETEXT_ON
		statuscolor := MICROPHONECOLOR_ON
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').innerHTML = `"" . statustext . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').style = `"background-color: " . statuscolor . ";`"")
		PACurState["microphone"] := "true"
	} else if !dictateon && PACurState["microphone"] != "false" {
		statustext := MICROPHONETEXT_OFF
		statuscolor := MICROPHONECOLOR_OFF
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').innerHTML = `"" . statustext . "`"")
		PAGui.PostWebMessageAsString("document.getElementById('microphonestatus').style = `"background-color: " . statuscolor . ";`"")
		PACurState["microphone"] := "false"
	}

	; Update top level on/off switch status
	; Also update the global PAActive as a shadow copy of PASettings["active"].value
	onoff := Setting["active"].value
	if onoff && !PAActive {
		PAActive := true
		GUIStatus("PACS Assistant enabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').setAttribute('checked', '');")
	} else if !onoff && PAActive {
		PAActive := false
		GUIStatus("PACS Assistant disabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').removeAttribute('checked');")
	}
;GUISetPropVal("log", "innerHTML", PAActive " / " PASettings["active"].value)
		
	; Update app icon indicators
	status := 0x00

	; update Network/VPN status on GUI
	hospital := WorkstationIsHospital()
	connected := NetworkIsConnected()
	if hospital {
		if connected {
			status |= 0x01
			if PACurState["Network"] != "true" {
				PAGui.PostWebMessageAsString("document.getElementById('app-Network').style = `"background-image: url('images/Network-connected.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-Network-connect').style = `"display: none;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-Network-disconnect').style = `"display: block;`"")
				PACurState["Network"] := "true"
			}
		} else if !connected && PACurState["Network"] != "false" {
			PAGui.PostWebMessageAsString("document.getElementById('app-Network').style = `"background-image: url('images/Network-off.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-Network-connect').style = `"display: block;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-Network-disconnect').style = `"display: none;`"")
			PACurState["Network"] := "false"
		}
	} else {
		; update VPN status on GUI
		connected := VPNIsConnected()
		if connected {
			status |= 0x01
			if PACurState["Network"] != "true" {
				PAGui.PostWebMessageAsString("document.getElementById('app-Network').style = `"background-image: url('images/VPN-connected.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-Network-connect').style = `"display: none;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-Network-disconnect').style = `"display: block;`"")
				PACurState["Network"] := "true"
			}
		} else if !connected && PACurState["Network"] != "false" {
			PAGui.PostWebMessageAsString("document.getElementById('app-Network').style = `"background-image: url('images/VPN-off.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-Network-connect').style = `"display: block;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-Network-disconnect').style = `"display: none;`"")
			PACurState["Network"] := "false"
		}
	}

	; update EI desktop status on GUI
	visible := App["EI"].Win["d"].visible
	if visible {
		status |= 0x02
		if PACurState["EI"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-EI').style = `"background-image: url('images/EI.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EI-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EI-shutdown').style = `"display: block;`"")
			PACurState["EI"] := "true"
		}
	} else if !visible && PACurState["EI"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-EI').style = `"background-image: url('images/EI-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EI-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EI-shutdown').style = `"display: none;`"")
		PACurState["EI"] := "false"
	}

	; update PS status on GUI
	visible := App["PS"].Win["main"].visible || App["PS"].Win["report"].visible || App["PS"].Win["login"].visible || App["PS"].Win["addendum"].visible || App["PS"].Win["login"].visible
	if visible {
		status |= 0x04
		if PACurState["PS"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-PS').style = `"background-image: url('images/PS.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-shutdown').style = `"display: block;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-PS-forceclose').style = `"display: block;`"")
			PACurState["PS"] := "true"
		}
	} else if !visible && PACurState["PS"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-PS').style = `"background-image: url('images/PS-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-shutdown').style = `"display: none;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-PS-forceclose').style = `"display: none;`"")
		PACurState["PS"] := "false"
	}

	; update EPIC status on GUI
	visible := App["EPIC"].Win["main"].visible
	if visible {
		status |= 0x08
		if PACurState["EPIC"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC').style = `"background-image: url('images/EPIC.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-startup').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-shutdown').style = `"display: block;`"")
			PACurState["EPIC"] := "true"
		}
	} else if !visible && PACurState["EPIC"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC').style = `"background-image: url('images/EPIC-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-startup').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-EPIC-shutdown').style = `"display: none;`"")
		PACurState["EPIC"] := "false"
	}

	; update power button status on GUI
	; also update global PAStatus_PowerButon with the same status
	switch status {
		case 0x00:
			if PACurState["power"] != "off" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-off.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"Press to start PACS`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: block;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: none;`"")
				PACurState["power"] := "off"
				PAStatus_PowerButton := "off"
			}
		case 0x0f:
			if PACurState["power"] != "green" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-green.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"PACS is running`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: none;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: block;`"")
				PACurState["power"] := "green"
				PAStatus_PowerButton := "green"
			}
		default:
			if PACurState["power"] != "yellow" {
				PAGui.PostWebMessageAsString("document.getElementById('app-power').style = `"background-image: url('images/power-yellow.png');`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power').alt = `"PACS is starting up...`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-startup').style = `"display: block;`"")
				PAGui.PostWebMessageAsString("document.getElementById('app-power-shutdown').style = `"display: block;`"")
				PACurState["power"] := "yellow"
				PAStatus_PowerButton := "yellow"
			}
	}

	; done
	running := false
	return
}


; Update the status of all windows
;
; Typically used with a timer, e.g. SetTimer(_WatchWindows, UPDATE_INTERVAL)
_WatchWindows() {
	global PAWindowInfo
	global HookShowQueue
	global HookCloseQueue
	
	; runs regardless of PAActive

	; [todo] if PS spelling window is open for more than 1 second while mouse is not
	; over a PS window, then close it?

	; poll windows to trigger hook_show
	for w in PollShow {
		if w.hwnd && !w._showstate && w.hook_show { 
			w._showstate := true
			HookShowQueue.Push(w.hook_show)
		}
	}

	; poll windows to trigger hook_close
	for w in PollClose {
		if !w.hwnd && !w._closestate && w.hook_close { 
			w._closestate := true
			HookCloseQueue.Push(w.hook_close)
		}
	}


	; update window info for GUI
	PAWindowInfo := PrintWindows( , , true) . FormatTime(A_Now,"M/d/yyyy HH:mm:ss")

}


; Performs focus following by activiating the window under the mouse when appropriate.
;
; Focus following is suspended if any of the following are true:
;	Setting["FocusFollow"].enabled is false
;	PAActive is false
; 	PA_WindowBusy is true
; 	Shift key is being held down
;
; Typically used with a timer, e.g. SetTimer(_WatchMouse, UPDATE_INTERVAL)
_WatchMouse() {
	global PAActive
	global PAWindowBusy
	global App
	static running := false

	; local function to close the PS spelling window if autoclose is enabled
	_ClosePSspelling() {
		if Setting["PSSPspelling_autoclose"].enabled && App["PSSP"].Win["spelling"].visible {
			App["PSSP"].Win["spelling"].Close()
		}
	}

	; don't allow reentry
	if running {
		return
	}
	running := true

	; check if we should do focus following, if not return
	if !PAActive || PAWindowBusy || !Setting["FocusFollow"].enabled {
		running := false
		return
	}

	; get the handle of the window under the mouse
	hwnd := WindowUnderMouse()

	; Activate the window under the mouse

	; If the desired window is already active, just return
	if WinExist("A") = hwnd {
		running := false
		return
	}

	; only activate window if Lshift is not being held down
	if !GetKeyState("LShift", "P") {

		appkey := GetAppkey(hwnd)
		winkey := GetWinkey(hwnd)
		if appkey && winkey {
			switch appkey {
				case "EI":
					; close PS Spelling window
					_ClosePSspelling()
					try {
						WinActivate(hwnd)
					}
				case "PS":
					try {
						WinActivate(hwnd)
					}
				case "PA":
					_ClosePSspelling()
					try {
						WinActivate(hwnd)
					}
				case "EPIC":
					_ClosePSspelling()
					try {
						WinActivate(hwnd)
					}
				default:
					; do nothing
			}
		}
	}

	running := false
	return
}


; Jiggle the mouse to keep screen awake
;
_JiggleMouse() {
	if !PAActive {
		return
	}

	if Setting["MouseJiggler"].enabled {
		MouseMove(1, 1, , "R")
		MouseMove(-1, -1, , "R")
	}
}


; Clear CapsLock after no keyboard input for a specified time
;
_ClearCapsLock() {
	if !PAActive {
		return
	}

	if Setting["ClearCapsLock"].enabled && A_TimeIdleKeyboard > CAPSLOCK_TIMEOUT {
		SetCapsLockState false
	}
}
