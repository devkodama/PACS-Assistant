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


#Include PAGlobals.ahk

#include PAICDCode.ahk




/***********************************************/


; Start or stop daemons

InitDaemons(start := true) {

	SetTimer(_Dispatcher, (start ? DISPATCH_INTERVAL : 0))
	SetTimer(_RefreshGUI, (start ? GUIREFRESH_INTERVAL : 0))

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

	; runs regardless of PAActive

	if DispatchQueue.Length > 0 {
		; call fn() via SetTimer to simulate multithreading
		fn := DispatchQueue.RemoveAt(1)
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
		return
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
	if true || PACurrentStudy.changed {

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

		PAGui.PostWebMessageAsString("document.getElementById('studyinfo').innerHTML = '" . studyinfo . "'")

	}


	; Update window info area
	PAGui.PostWebMessageAsString("document.getElementById('windowinfo').innerHTML = `"" . PAWindowInfo . "`"")


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
	onoff := PASettings["active"].value
	if onoff && !PAActive {
		PAActive := true
		PAStatus("PACS Assistant enabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').setAttribute('checked', '');")
	} else if !onoff && PAActive {
		PAActive := false
		PAStatus("PACS Assistant disabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').removeAttribute('checked');")
	}
;PAGui_Post("log", "innerHTML", PAActive " / " PASettings["active"].value)
		
	; Update app icon indicators
	status := 0x00

	; update VPN status on GUI
	connected := VPNIsConnected()
	if connected {
		status |= 0x01
		if PACurState["VPN"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-connected.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: block;`"")
			PACurState["VPN"] := "true"
		}
	} else if !connected && PACurState["VPN"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: none;`"")
		PACurState["VPN"] := "false"
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
	visible := App["PS"].Win["main"].visible || App["PS"].Win["report"].visible
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


; Refreshes the GUI display
;
_RefreshGUI2() {
	global PAGui
	global PAActive
	global PAStatusBarText
	global PAStatus_PowerButton
	global PACurrentPatient
	global PACurrentStudy
	global PAWindowInfo
	global PACurState
	global PAApps

	static running := false
	static statusbartext := ""
	static statusbarlastupdate := A_TickCount
	
	; runs regardless of PAActive

	; don't allow reentry
	if running {
		return
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
	if true || PACurrentStudy.changed {

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

		icdcodes := "<br />"
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

		PAGui.PostWebMessageAsString("document.getElementById('studyinfo').innerHTML = '" . studyinfo . "'")

	}


	; Update window info area
	PAGui.PostWebMessageAsString("document.getElementById('windowinfo').innerHTML = `"" . PAWindowInfo . "`"")


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
	onoff := PASettings["active"].value
	if onoff && !PAActive {
		PAActive := true
		PAStatus("PACS Assistant enabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').setAttribute('checked', '');")
	} else if !onoff && PAActive {
		PAActive := false
		PAStatus("PACS Assistant disabled")
		PAGui.PostWebMessageAsString("document.getElementById('tab-active').removeAttribute('checked');")
	}
;PAGui_Post("log", "innerHTML", PAActive " / " PASettings["active"].value)
		
	; Update app icon indicators
	status := 0x00

	; update VPN status on GUI
	connected := VPNIsConnected()
	if connected {
		status |= 0x01
		if PACurState["VPN"] != "true" {
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-connected.png');`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: none;`"")
			PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: block;`"")
			PACurState["VPN"] := "true"
		}
	} else if !connected && PACurState["VPN"] != "false" {
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN').style = `"background-image: url('images/VPN-off.png');`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-connect').style = `"display: block;`"")
		PAGui.PostWebMessageAsString("document.getElementById('app-VPN-disconnect').style = `"display: none;`"")
		PACurState["VPN"] := "false"
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
	visible := App["PS"].Win["login"].visible || App["PS"].Win["report"].visible || App["PS"].Win["main"].visible || App["PS"].Win["addendum"].visible
	visible := App["PS"].Win["main"].visible
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




/***********************************************/



; Update the status of all PAWindows
;
; Typically used with a timer, e.g. SetTimer(_WatchWindows, UPDATE_INTERVAL)
;
_WatchWindows() {
	global PAActive
	global PAWindowInfo
	
	; update all app windows
	UpdateAll()

	; update status of psuedowindows (pages within some windows like EI desktop or EPIC)
	

	; [todo] if PS spelling window is open for more than 1 second while mouse is not
	; over a PS window, then close it


	; update window info for GUI
	; PAWindowInfo := PAWindows.Print() . "<br />"
	
	PAWindowInfo := PrintWindows() . FormatTime(A_Now,"M/d/yyyy HH:mm:ss")


}




; Update the hwnd of the window under the mouse cursor
;
; Also makes the window active if appropriate.
; Automatic window activation is suspended if Shift key is being held down
;
; Typically used with a timer, e.g. SetTimer(_WatchMouse, UPDATE_INTERVAL)
;
; PAActive must be true for this function to be active
;
; PA_WindowBusy must be false for focus following to be allowed
;
_WatchMouse() {
	global PAActive
	global PA_WindowUnderMouse
	global PAWindowBusy
	global App
	static running := false
	static restore_EPICchat := 0	; either 0, or array of [x, y, w, h, extended_h]

	if !PAActive {
		return
	}

	; don't allow reentry
	if running {
		return
	}
	running := true

; try {
	; local function to restore windows that have been enlarged
	_RestoreSaved() {
		if restore_EPICchat {
			hwndEPICchat := App["EPIC"].Win["chat"].hwnd
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
				App["EPIC"].Win["chat"].Update()
			}
		}
	}
	; local function to autoclose the PS spelling window
	_ClosePSspelling() {
		if PASettings["PSSPspelling_autoclose"].value && App["PSSP"].Win["spelling"].visible {
			App["PSSP"].Win["spelling"].Close()
		}
	}

	; get the handle of the window under the mouse
	hwnd := Mouse()

	; store it
	PA_WindowUnderMouse := hwnd

	; activate window under the mouse, if appropriate
	;
	; only activate window if another window is not busy
	; and if not already active
	; and Lshift is not being held down
	if !PAWindowBusy && !GetKeyState("LShift", "P") && !WinActive(hwnd) {

		appkey := GetAppkey(hwnd)
		winkey := GetWinkey(hwnd)
		if appkey && winkey {
			switch appkey {
				case "EI":
					; close PS Spelling window
					_ClosePSspelling()

					; don't activate if there are more than one PS windows open
					if App["PS"].CountOpenWindows() < 2 {
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
					switch winkey {
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
							; if _WindowKeys.CountAppWindows("PS") < 2 {
							if App["PS"].CountOpenWindows() < 2 {
								WinActivate(hwnd)
							}
						default:
							_ClosePSspelling()
							; don't activate if there are more than one PS windows open
							; if _WindowKeys.CountAppWindows("PS") < 2 {
							if App["PS"].CountOpenWindows() < 2 {
								_RestoreSaved()
								WinActivate(hwnd)
							}
					}
				default:
					; do nothing
			}
		}
	}

; } catch {
; }


	running := false
	return
}




; Jiggle the mouse to keep screen awake
_JiggleMouse() {
	if !PAActive {
		return
	}

	if PASettings["MouseJiggler"].value {
		MouseMove(1, 1, , "R")
		MouseMove(-1, -1, , "R")
	}
}

