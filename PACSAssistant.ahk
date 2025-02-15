/* PACSAssistant.ahk
**
** Primary script for PACS Assistant
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force

#MaxThreads 64

DetectHiddenWindows true		; look also for hidden windows by default
DetectHiddenText true			; don't search hidden text by default

SetDefaultMouseSpeed 0			; 0 = fastest


/**
 *
 * Includes
 * 
 */


#Include <WinEvent>
#Include <Cred>

#Include Utils.ahk

#Include PAGlobals.ahk

#Include PASound.ahk

#Include PAFindTextStrings.ahk

#Include PADaemon.ahk
#Include PAHotkeys.ahk
#Include PAVPN.ahk
#Include PAEI.ahk
#Include PAPS.ahk
#Include PAEPIC.ahk

#Include PAInfo.ahk
#Include PASettings.ahk


#Include PAICDCode.ahk

#Include PACSAssistantGUI.ahk


; for debugging use
#Include Debug.ahk




; _WindowKeys is a Map object which allows fast reverse lookup of appplication
; and window keys given a HWND value. It does this by maintaining a reverse
; lookup table that is updated everytime a WindowItem object is updated.
; The table keys are window handles (hwnd), and the return value is an array
; of the form [appname, windowname, visibility], e.g.:
;
;	_WindowKeys[EI_HWND] => ["EI", "desktop", true]
;
; The method _WindowKeys.CountAppWindows(appkey) returns the number of
; open and visible windows that belong to the application appkey (e.g. "EI").
;
; _WindowKeys is utilized by the PAWindows method GetAppWin()
;
global _WindowKeys := Map()

_WindowKeys.CountAppWindows := _WindowKeys_CountAppWindows

_WindowKeys_CountAppWindows(this, appkey) {
	count := 0
	if appkey {
		for hwnd in this {
			if this[hwnd][1] = appkey && this[hwnd][3] {
				count++
			}
		}
	}
	return count
}



; The WindowItem class is defined below. It holds information about an individual
; window in the following properties:
;
;	appkey		- [required] appliation key string
;	winkey		- [required] window key string
;
;	fulltitle	- full title of window, not used for matching
;	searchtitle	- short title of window, used for matching
;	wintext		- window text to match, used for matching
;	ahk_exe		- executable name, used for matching
;	criteria	- combined search string generated from searchtitle and ahk_exe
;
;	hwnd		- 0 if window doesn't exist, HWND of the window otherwise
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	opentime	- timestamp when window was last opened (from A_Now)
;	status		- [optional] status item, window specific usage
;
;	xpos		- saved screen x position of the window
;	ypos		- saved screen w position of the window
;	width		- saved width of the window (must be >= 100)
;	height		- saved height of the window (must be >= 100)
;
;	hook_open	- function to be called when this window is opened
;	hook_close	- function to be called when this window is closed
;
; It has the following methods:
;
;	Update()	- Looks for a window matching the hwnd and updates xpos, ypos, width, height.
;					Updates visibility status and updates reverse lookup table _WindowKeys
;	Close()		- Closes a window by setting it's hwnd to zero, visibility to false, and
;					opentime to null. Calls ahk WinClose() to close the actual window.
;					Also updates reverse lookup table _WindowKeys by deleting entry.
;
;	Send(cmdstring)	- Sends a string to a specified window.
;
;	SetPosition(x, y, w, h)	- Stores the passed window position.
;	SaveCurrentPosition()	- Saves the current x, y, width, and height properties for a window.
;	RestorePosition() 	- Restores window to saved position.
;	CenterWindow(parentWindowItem)	- Centers a window over a parent window
;
;	SaveSettings()	- Saves position info to settings.ini file.
;	ReadSettings()	- Reads position info from settings.ini file.
;
;	Print()		- For debugging. Returns object properties as a string.
;
; WindowItem entries are updated whenever a window is created or closed, to
; reflect the current state of each window of interest.
; 
class WindowItem {
	__New(appkey, winkey, full := "", short := "", text := "", exe := "", hopen := 0, hclose := 0) {
		this.appkey := appkey
		this.winkey := winkey

		this.fulltitle := full
		this.searchtitle := (short ? short : "")
		this.wintext := text
		this.ahk_exe := exe
		this.criteria := this.searchtitle . (this.ahk_exe ? " ahk_exe " . this.ahk_exe : "")

		this.hwnd := 0
		this.visible := false
		this.minimized := false
		this.opentime := 0
		this.status := 0
		
		this.xpos := 0
		this.ypos := 0
		this.width := 0
		this.height := 0

		this.hook_open := hopen
		this.hook_close := hclose

		this.Update()
	}

	; Updates the properties of this window.
	;
	; If hwnd is non-zero, it is verified for confirm existence of the window.
	;
	; If hwnd is zero (or no longer exists), then if criteria string is non-empty,
	; then search for the window based on criteria plus wintext.
	;
	; Updates visibility status of the window. If hwnd doesn't exist, visibility is
	; set to false.
	;
	; Also update the _WindowKeys reverse lookup table.
	Update(newhwnd := 0) {
		global _WindowKeys

		; if passed newhwnd is non-zero, assume it is valid
		if newhwnd {
			if this.hwnd {
				; first delete the previous reverse lookup if it exists
				try {
					_WindowKeys.Delete(this.hwnd)
				} catch {
				}
			}

			; save the new hwnd
			this.hwnd := newhwnd
		
			; update visibility status
			this.visible := (WinGetStyle(newhwnd) & WS_VISIBLE) ? true : false

			; update minimized status
			this.minimized := WinGetMinMax(newhwnd) = -1 ? true : false

			; save opening time
			this.opentime := A_Now
		
			; update the reverse lookup entry
			_WindowKeys[newhwnd] := [this.appkey, this.winkey, this.visible]

			; call hook_open if the window is visible and not minimized
			if !_PAUpdate_Initial && PAActive && this.hook_open && (this.visible && !this.minimized) {
				this.hook_open.Call()
			}

			return 
		}

		; Do not want to search hidden text when looking for windows below
		DetectHiddenText(false)
		
		; if hwnd has a value, verify the window still exists
		if this.hwnd  {

			gethwnd := WinExist(this.criteria, this.wintext)
			if gethwnd && gethwnd = this.hwnd {
				; window still exists

				; update visibility status
				newvisible := (WinGetStyle(gethwnd) & WS_VISIBLE) ? true : false
				;this.visible := (WinGetStyle(gethwnd) & WS_VISIBLE) ? true : false

				; update minimized status
				newminimized := WinGetMinMax(gethwnd) = -1 ? true : false
				;this.minimized := WinGetMinMax(gethwnd) = -1 ? true : false

				; update the reverse lookup entry
				_WindowKeys[gethwnd] := [this.appkey, this.winkey, this.visible]
						
				; call hook_open if window transitions from not visible or minimzed to visible and not minimized
				if !_PAUpdate_Initial && PAActive && this.hook_open && (!this.visible || this.minimized) && (newvisible && !newminimized) {
					this.hook_open.Call()
				}

				; call hook_close if window transitions from visible and not minimized to not visible or minimzed
				if PAActive && this.hook_close && (this.visible && !this.minimized) && (!newvisible || newminimized) {
					this.hook_close.Call()
				}

				this.visible := newvisible
				this.minimized := newminimized
					
				return 

			} else {
				; window no longer exists

				; call hook_close if window was last visible and not minimized
				if PAActive && this.hook_close && (this.visible && !this.minimized) {
					this.hook_close.Call()
				}

				; delete the reverse lookup (if it exists)
				try {
					_WindowKeys.Delete(this.hwnd)
				} catch {
				}
				; then reset hwnd to 0, visibility to false, minimized to false, and opentime to 0
				this.hwnd := 0
				this.visible := false
				this.minimized := false
				this.opentime := 0
			}
		
		}

		; at this point hwnd is null, so try to find the window based on criteria and wintext
		if this.criteria {

			gethwnd := WinExist(this.criteria, this.wintext)
			if gethwnd {

				; success, found a matching window, save the hwnd and set the visibility, minimized, and opentime
				this.hwnd := gethwnd
				this.visible := (WinGetStyle(gethwnd) & WS_VISIBLE) ? true : false
				this.minimized := WinGetMinMax(gethwnd) = -1 ? true : false
				this.opentime := A_Now
				
				; update the reverse lookup entry
				_WindowKeys[this.hwnd] := [this.appkey, this.winkey, this.visible]
		
				; call hook_open if the window is visible and not minimized
				if !_PAUpdate_Initial && PAActive && this.hook_open && (this.visible && !this.minimized) {
					this.hook_open.Call()
				}

				; set up callback that triggers (once) when this window gets closed
; WinEvent.Close(_PAWindowCloseCallback, gethwnd, 1)
				
			}

		} else {

			; if criteria is empty, this is a pseudowindow so don't try to find it

		}

	}

	; Closes the window info by zeroing its hwnd property, sets visibility to false,
	; sets minimized to false, sets opentime to null.
	;
	; Calls ahk WinClose() to close the actual window (unless called with parameter false)
	;
	; Also update the _WindowKeys reverse lookup table.
	Close(callwinclose := true) {
		global _WindowKeys
		
		if this.hwnd  {

			; delete the reverse lookup (if it exists)
			try {
				_WindowKeys.Delete(this.hwnd)
			} catch {
			}

			; close the actual window, if requested
			if callwinclose {
				try {
					WinClose(this.hwnd)
				} catch {
				}
			}
	
			; reset hwnd to 0, visibility to false, minimized to false, and opentime to null
			this.hwnd := 0
			this.visible := false
			this.minimized := false
			this.opentime := 0
		}
	}
	
	; Send a string of keystrokes to a specific window
	Send(cmdstring := "") {
		global PAWindowBusy

		if (cmdstring) {
			if (this.hwnd) {
				PAWindowBusy := true
				WinActivate(this.hwnd)
				Send(cmdstring)
				PAWindowBusy := false
			}
		}	
	}

	; Sets the passed window position
	SetPosition(x, y, w, h) {
		if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
			this.xpos := x
			this.ypos := y
			this.width := w
			this.height := h
		}
	}

	; Stores the current window position
	SaveCurrentPosition() {
		try {
			if this.hwnd {
				WinGetPos(&x, &y, &w, &h, this.hwnd)
				if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
					this.xpos := x
					this.ypos := y
					this.width := w
					this.height := h
				}
			}
		}
	}

	; Restore window position to saved position
	RestorePosition() {
		try {
			if this.hwnd && this.width >= WINDOWPOSITION_MINWIDTH && this.height >= WINDOWPOSITION_MINHEIGHT {
;				PAToolTip("Restoring " this.appkey "/" this.winkey ":" this.xpos "," this.ypos "," this.width "," this.height ":" this.hwnd)
				WinMove(this.xpos, this.ypos, this.width, this.height, this.hwnd)
			}
		} catch {
			; ignore errors
		}
	}

	; Centers a window over a parent window
	; returns true on success, false on failure
	CenterWindow(parent) {

		if parent {

			cw := 0
			pw := 0

			; get child and parent window positions and dimensions
			if this.hwnd {
				WinGetPos( , , &cw, &ch, this.hwnd)
			}
			if parent.hwnd {
				WinGetPos(&px, &py, &pw, &ph, parent.hwnd)
			}
			if cw = 0 || pw = 0 {
				return false
			}
			; calculate new position
			nx := px + (pw - cw) / 2
			ny := py + (ph - ch) / 2

			; move child window
			WinMove(nx, ny, , , this.hwnd)
			
			return true

		} else {
			
			return false

		}

	}

	; Saves position info to settings.ini file.
	SaveSettings() {
		if this.width >= WINDOWPOSITION_MINWIDTH && this.height >= WINDOWPOSITION_MINHEIGHT {
			appkey := this.appkey
			winkey := this.winkey
			sectionname := A_ComputerName . "_WindowPosition"
			inifile := PASettings["inifile"].value
			if inifile {
				IniWrite(this.xpos, inifile, sectionname, appkey . winkey . "_xpos") 
				IniWrite(this.ypos, inifile, sectionname, appkey . winkey . "_ypos")
				IniWrite(this.width, inifile, sectionname, appkey . winkey . "_width")
				IniWrite(this.height, inifile, sectionname, appkey . winkey . "_height")
			}
		}
	}

	; Reads position info from settings.ini file.
	ReadSettings() {
		appkey := this.appkey
		winkey := this.winkey
		sectionname := A_ComputerName . "_WindowPosition"
		inifile := PASettings["inifile"].value
		if inifile {
			x := IniRead(inifile, sectionname, appkey . winkey . "_xpos", -1)
			y := IniRead(inifile, sectionname, appkey . winkey . "_ypos", -1)
			w := IniRead(inifile, sectionname, appkey . winkey . "_width", 0)
			h := IniRead(inifile, sectionname, appkey . winkey . "_height", 0)
			if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
				this.xpos := x
				this.ypos := y
				this.width := w
				this.height := h
			}
		}
	}


	Print() {
		output := ""
		if this.hwnd {
			try {
				WinGetPos(&x, &y, &w, &h, this.hwnd)
				output .= this.appkey "/" this.winkey " (" (this.visible ? "visible" : "hidden") (this.minimized ? "/minimized" : "") "): " this.hwnd " (" x "," y "," w "," h ")/(" this.xpos "," this.ypos "," this.width "," this.height ") <br />"
			} catch {
				output .= "Failed on WinGetPos(&x, &y, &w, &h, this.hwnd=" this.hwnd ")"
			}
		}
		return output
	}

}



; PAWindows is a global Map object which stores information about 
; all the windows of interest. Stored info includes arrays of application 
; and window keys, and WindowItem objects for each window which 
; contain specifics for each window.
;
; The following are valid application keys for PAWindows:
;
;	"PA"	- PACS Assistant
;	"VPN"	- Cisco VPN
;	"EI"	- Agfa EI
;	"PS"	- PowerScribe
;	"EPIC"	- Epic
;	"DCAD"	- DynaCAD Prostate and Breast
;	"DLUNG"	- DynaCAD Lung
;
; A list of valid applications keys are stored as an array under the special key "keys", i.e.:
;
;	PAWindows["keys"] := ["PA", "VPN", "EI", "PS", "EPIC", "DCAD", "DLUNG"]
;
; This special entry allows functions that need it to iterate through the 
; valid applications keys.
;
; Each application entry of PAWindows is a Map object which maps individual windows to
; an instance of a WindowItem object which holds information about the window.
; The possible windows keys for each entry of PAWindows depends on the application key:
;
;	"PA"	-	"main"
;	"VPN"	-	"main"
;	"EI"	-	"desktop", "images1", "images2", "4dm", "mpr", "collaborator"
;	"PS"	-	"main", 
;	"EPIC"	-	"main", "chat"
;	"DCAD"	-	"main"
;	"DLUNG"	-	"main", "second"
;
; A list of valid window keys for each application are stored as an array under the
; special key "keys" for each application, i.e.:
;
;	PAWindows["EI"]["keys"] := ["desktop", "images1", "images2", "4dm", "mpr", "collaborator"]
;
; This special entry allows functions that need it to iterate through the 
; valid windows keys.
;
; PAWindows has the following methods:
;
;	SaveSettings([appkey]) - saves the positions of currently open windows (i.e.
;		which have a valid hwd) to the settings.ini file. Optionally
;		only save for a specific app by passing app key as parameter.
;
;	ReadSettings([appkey]) - reads the positions of currently open windows (i.e.
;		which have a valid hwd) by reading from the settings.ini file. Optionally
;		only read for a specific app by passing app key as parameter.
;
;	RestoreWindows([appkey]) - repositions windows to their last saved window positions
;		(if a valid position is stored). Optionally only restore for
;		a specific app by passing app key as parameter.
;
;	Update([appkey]) - Updates the info for currently open windows. Optionally
;		update only for a specific app by passing app key as parameter.
;
;	GetAppWin(hwnd, &appkey, &winkey, &visibility) - Given a window handle, retrives
;		the app and win keys and the visibility of the window. Returns true
;		if the hwnd exists, false if not.
;
;	Print() - Returns a string with info about every window in PAWindows
;
global PAWindows := Map()

PAWindows["keys"] := ["PA", "VPN", "EI", "PS", "EPIC", "DCAD", "DLUNG"]
PAWindows["PA"] := Map()
PAWindows["VPN"] := Map()
PAWindows["EI"] := Map()
PAWindows["PS"] := Map()
PAWindows["EPIC"] := Map()
PAWindows["DCAD"] := Map()
PAWindows["DLUNG"] := Map()

PAWindows["PA"]["keys"] := ["main"]
PAWindows["PA"]["main"] := WindowItem("PA", "main", "PACS Assistant", "PACS Assistant", , "AutoHotkey64.exe")

PAWindows["VPN"]["keys"] := ["main", "prefs", "login", "otp", "connected"]
PAWindows["VPN"]["main"] := WindowItem("VPN", "main", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Preferences", "vpnui.exe")
PAWindows["VPN"]["prefs"] := WindowItem("VPN", "prefs", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Export Stats", "vpnui.exe")
PAWindows["VPN"]["login"] := WindowItem("VPN", "login", "Cisco AnyConnect |", "Cisco AnyConnect |", "Username", "vpnui.exe")
PAWindows["VPN"]["otp"] := WindowItem("VPN", "otp", "Cisco AnyConnect |", "Cisco AnyConnect |", "Answer", "vpnui.exe")
PAWindows["VPN"]["connected"] := WindowItem("VPN", "connected", "Cisco AnyConnect", "Cisco AnyConnect", "Security policies", "vpnui.exe")

PAWindows["EI"]["keys"] := ["login", "desktop", "images1", "images2", "4dm", "options", "assign", "mpr", "collaborator"]
PAWindows["EI"]["login"] := WindowItem("EI", "login", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging", , "javaw.exe")
PAWindows["EI"]["desktop"] := WindowItem("EI", "desktop", "Diagnostic Desktop - 8.2.2.062  - mivcsp.adventhealth.com - AHEIAE1", "Diagnostic Desktop - 8", , "javaw.exe", EIOpen_EIdesktop, EIClose_EIdesktop)
PAWindows["EI"]["images1"] := WindowItem("EI", "images1", "Diagnostic Desktop - Images (1 of 2)", "Diagnostic Desktop - Images (1", , "javaw.exe")
PAWindows["EI"]["images2"] := WindowItem("EI", "images2", "Diagnostic Desktop - Images (2 of 2)", "Diagnostic Desktop - Images (2", , "javaw.exe")
PAWindows["EI"]["4dm"] := WindowItem("EI", "4dm" ,"4DM(Enterprise Imaging) v2017", "4DM", , "Corridor4DM.exe")
PAWindows["EI"]["options"] := WindowItem("EI", "options", "Options", "Options", , "javaw.exe")
PAWindows["EI"]["assign"] := WindowItem("EI", "assign", "Assign", "Assign", , "javaw.exe")
PAWindows["EI"]["mpr"] := WindowItem("EI", "mpr", "IMPAX Volume Viewing 3D + MPR Viewing", "IMPAX Volume", , "javawClinapps.exe")
PAWindows["EI"]["collaborator"] := WindowItem("EI", "collaborator", "Collaborator", "Collaborator", , "javaw.exe")

PAWindows["PS"]["keys"] := ["login", "main", "report", "addendum", "logout", "savespeech", "savereport", "deletereport", "unfilled", "confirmaddendum", "confirmanotheraddendum", "existing", "continue", "ownership", "compare", "microphone", "find", "spelling"]
PAWindows["PS"]["login"] := WindowItem("PS", "login", "PowerScribe 360 | Reporting", "PowerScribe", "Disable speech", "Nuance.PowerScribe360.exe", PSOpen_PSlogin)
PAWindows["PS"]["main"] := WindowItem("PS", "main", "PowerScribe 360 | Reporting", "PowerScribe", "Signing queue", "Nuance.PowerScribe360.exe", PSOpen_PSmain, PSClose_PSmain)
PAWindows["PS"]["report"] := WindowItem("PS", "report", "PowerScribe 360 | Reporting", "PowerScribe", "Report -", "Nuance.PowerScribe360.exe", PSOpen_PSreport, PSClose_PSreport)
PAWindows["PS"]["addendum"] := WindowItem("PS", "addendum", "PowerScribe 360 | Reporting", "PowerScribe", "Addendum -", "Nuance.PowerScribe360.exe", PSOpen_PSreport, PSClose_PSreport)
PAWindows["PS"]["logout"] := WindowItem("PS", "logout", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you wish to log off the application?", "Nuance.PowerScribe360.exe", PSOpen_PSlogout)
PAWindows["PS"]["savespeech"] := WindowItem("PS", "savespeech", "PowerScribe 360 | Reporting", "PowerScribe", "Your speech files have changed. Do you wish to save the changes?", "Nuance.PowerScribe360.exe", PSOpen_PSsavespeech)
PAWindows["PS"]["savereport"] := WindowItem("PS", "savereport", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to save the changes to the", "Nuance.PowerScribe360.exe", PSOpen_PSsavereport)
PAWindows["PS"]["deletereport"] := WindowItem("PS", "deletereport", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to delete", "Nuance.PowerScribe360.exe", PSOpen_PSdeletereport)
PAWindows["PS"]["unfilled"] := WindowItem("PS", "unfilled", "PowerScribe 360 | Reporting", "PowerScribe", "This report has unfilled fields. Are you sure you wish to sign it?", "Nuance.PowerScribe360.exe", PSOpen_PSunfilled)
PAWindows["PS"]["confirmaddendum"] := WindowItem("PS", "confirmaddendum", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create an addendum", "Nuance.PowerScribe360.exe", PSOpen_PSconfirmaddendum)
PAWindows["PS"]["confirmanotheraddendum"] := WindowItem("PS", "confirmanotheraddendum", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create another addendum", "Nuance.PowerScribe360.exe", PSOpen_PSconfirmanotheraddendum)
PAWindows["PS"]["existing"] := WindowItem("PS", "existing", "PowerScribe 360 | Reporting", "PowerScribe", "is associated with an existing report", "Nuance.PowerScribe360.exe", PSOpen_PSexisting)
PAWindows["PS"]["continue"] := WindowItem("PS", "continue", "PowerScribe 360 | Reporting", "PowerScribe", "Do you wish to continue editing", "Nuance.PowerScribe360.exe", PSOpen_PScontinue)
PAWindows["PS"]["ownership"] := WindowItem("PS", "ownership", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to acquire ownership", "Nuance.PowerScribe360.exe", PSOpen_PSownership)
PAWindows["PS"]["compare"] := WindowItem("PS", "compare")
PAWindows["PS"]["microphone"] := WindowItem("PS", "microphone", "PowerScribe 360 | Reporting", "PowerScribe", "Your microphone is disconnected", "Nuance.PowerScribe360.exe", PSOpen_PSmicrophone)
PAWindows["PS"]["find"] := WindowItem("PS", "find", "Find and Replace", "Find and", , "Nuance.PowerScribe360.exe", PSOpen_PSfind)
PAWindows["PS"]["spelling"] := WindowItem("PS", "spelling", "Spelling Window", "Spelling", , "natspeak.exe", PSOpen_PSspelling)

PAWindows["EPIC"]["keys"] := ["login", "main", "chat"]
PAWindows["EPIC"]["main"] := WindowItem("EPIC", "main", "Hyperspace – Production (PRD)", "Production", , "Hyperdrive.exe", EPICOpened_EPICmain, EPICClosed_EPICmain)
PAWindows["EPIC"]["chat"] := WindowItem("EPIC", "chat", "Secure Chat", "Secure Chat", , "Hyperdrive.exe")
; pseudowindows
PAWindows["EPIC"]["login"] := WindowItem("EPIC", "login")
PAWindows["EPIC"]["timezone"] := WindowItem("EPIC", "timezone")
PAWindows["EPIC"]["chart"] := WindowItem("EPIC", "timezone")

PAWindows["DCAD"]["keys"] := ["login", "main", "study"]
PAWindows["DCAD"]["login"] := WindowItem("DCAD", "login", "Login", "Login", , "StudyManager.exe")
PAWindows["DCAD"]["main"] := WindowItem("DCAD", "main", "Philips DynaCAD", "Philips DynaCAD", , "StudyManager.exe")
PAWindows["DCAD"]["study"] := WindowItem("DCAD", "study", , , , "MRW.exe")

PAWindows["DLUNG"]["keys"] := ["login", "main", "second"]
PAWindows["DLUNG"]["login"] := WindowItem("DLUNG", "login", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
PAWindows["DLUNG"]["main"] := WindowItem("DLUNG", "main", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
PAWindows["DLUNG"]["second"] := WindowItem("DLUNG", "second", "DynaCAD Lung - Second Screen", "DynaCAD Lung - Second", , "MeVisLabApp.exe")


; Methods to save and restore window positions from settings.ini file
PAWindows.SaveSettings := PAWindows_SaveSettings
PAWindows.ReadSettings := PAWindows_ReadSettings
PAWindows.SaveWindowPositions := PAWindows_SaveWindowPositions
PAWindows.RestoreWindows := PAWindows_RestoreWindows

PAWindows.Update := PAWindows_Update
PAWindows.GetAppWin := PAWindows_GetAppWin

; Debug method to print contents of PAWindows
PAWindows.Print := PAWindows_Print

PAWindows_SaveSettings(this, appkey := "") {
	if appkey != "" {
		for winkey in this[appkey]["keys"] {
			curwin := PAWindows[appkey][winkey]
			curwin.SaveSettings()
		}
	} else {
		for appkey in this["keys"] {
			for winkey in this[appkey]["keys"] {
				curwin := PAWindows[appkey][winkey]
				curwin.SaveSettings()
			}
		}
	}
}

PAWindows_ReadSettings(this, appkey := "") {
	if appkey != "" {
		for winkey in this[appkey]["keys"] {
			PAWindows[appkey][winkey].ReadSettings()
		}
	} else {
		for appkey in this["keys"] {
			for winkey in this[appkey]["keys"] {
				PAWindows[appkey][winkey].ReadSettings()
			}
		}
	}
}

PAWindows_SaveWindowPositions(this, appkey := "") {
	if appkey != "" {
		for winkey in this[appkey]["keys"] {
			PAWindows[appkey][winkey].SaveCurrentPosition()
		}
	} else {
		for appkey in this["keys"] {
			for winkey in this[appkey]["keys"] {
				PAWindows[appkey][winkey].SaveCurrentPosition()
			}
		}
	}
}

PAWindows_RestoreWindows(this, appkey := "", excludeEIimage := true) {
	if appkey != "" {
		for winkey in this[appkey]["keys"] {
			if excludeEIimage && appkey = "EI" && (winkey = "images1" || winkey = "images2") {
				; skip restoring this window
			} else {
				PAWindows[appkey][winkey].RestorePosition()
			}
		}
	} else {
		for appkey in this["keys"] {
			for winkey in this[appkey]["keys"] {
				if excludeEIimage && appkey = "EI" && (winkey = "images1" || winkey = "images2") {
					; skip restoring this window
				} else {
					PAWindows[appkey][winkey].RestorePosition()
				}
			}
		}
	}
}

PAWindows_Update(this, appkey := "") {
	global _PAUpdate_Initial

	if appkey != "" {
		for winkey in this[appkey]["keys"] {
			PAWindows[appkey][winkey].Update()
		}
	} else {
		for appkey in this["keys"] {
			for winkey in this[appkey]["keys"] {
				PAWindows[appkey][winkey].Update()
			}
		}
	}
	
	global _PAUpdate_Initial := false
}

; Given a window handle, retrives the app and win keys and the visibility
; of the window. Returns true if hwnd exists in the reverse lookup table, false if not.
;
; If hwnd is empty or zero, the last window under the mouse position
; as recorded by PA_WindowUnderMouse is used to look up the app and window keys.
;
PAWindows_GetAppWin(this, hwnd, &appkey := "", &winkey := "", &visibility := false) {
	global PA_WindowUnderMouse

	if !hwnd {
		hwnd := PA_WindowUnderMouse
	}

	appwinarr := _WindowKeys.Get(hwnd, 0)
	if appwinarr {
		appkey := appwinarr[1]
		winkey := appwinarr[2]
		visibility := appwinarr[3]
		return true
	} else {
		appkey := ""
		winkey := ""
		visibility := false
		return false
	}

}



; Print data on all windows with existing handles
; Returned as a string
PAWindows_Print(this) {
	output := ""
	for appkey in this["keys"] {
		for winkey in this[appkey]["keys"] {
			curwin := PAWindows[appkey][winkey]
			if curwin.hwnd {
				output .= curwin.Print()
			}
		}
	}
	return output
}




/******************************/


; Checks that PAActive is true, and
; checks app and win of the currently active window to see if they match one of the passed contexts
;
; app is a string parameter. If app is empty "", then calls
; PAWindows.GetAppWin("", &app, &win) is called to get the application
; and window currently under the mouse (as last saved to PA_WindowUnderMouse).
;
; win is a string parameter. May be left empty, in case only the app
; part needs to match.
;
; contexts are strings of a format similar to:
;	"EI"						- matches any EI window
;	"EI images1 images2"		- matches either EI images1 or images2 windows
;	"EI desktop/list desktop/text"	- matches EI desktop window if list page or text page is showing
;	"PS"						- matches any PS window
;	"PS report"					- matches PS report window
;	...
;
; Multiple context strings may be passed.
; 
; An array of strings may also be passed for context, instead of one or more strings
;
; Returns true if it matches any of the context strings.
;
; Returns false if it doesn't match any of the context strings.
;
; Case sensitive
;
PAContext(contexts*) {
	app := ""
	win := ""

	if !PAActive {
		return false
	}

	if IsObject(contexts[1]) {
		; we got an array of strings as the first parameter so split it up
		sarr := Array()
		for s in contexts[1] {
			sarr.Push(s)
		}
	} else {
		; contexts[] is an array of strings
		sarr := contexts
	}
	; sarr now contains an array of context strings

	if app != "" || PAWindows.GetAppWin("", &app, &win) {
	
		; check app, win again each context string
		for context in sarr {

			carr := StrSplit(context, " ")
			capp := carr[1]		;get the app from the context string
		
			if app == capp {
				j := 2
				if j > carr.Length {
					; no windows to match with, so we've succeeded
					return true
				}
				if win = "" {
					; no window name to match, so we've succeeded
					return true
				}
				; need to check for a match among the windows in the context
				while j <= carr.Length {
					cwin := carr[j]
					j++
					; check if there is a page context
					if (k := InStr(cwin, "/")) {
						cpag := SubStr(cwin, k + 1)
						cwin := SubStr(cwin, 1, k - 1)
;						PAToolTip(cwin "/" cpag)
						if win == cwin {
							; found a window match, look for a page match
							switch cpag {
								case "list":
									if EIIsList() {
										return true
									}
								case "text":
									if EIIsText() {
										return true
									}
								case "search":
									if EIIsSearch() {
										return true
									}
								case "image":
									if EIIsImage() {
										return true
									}
							}
						}
					} else if win == cwin {
						; found a window match, so we've succeeded
						return true
					}
				}
			}
		}

	} else {

		return false

	}

}





; This callback function is called when a window matching specific criteria
; is shown on screen.
_PAWindowShowCallback(hwnd, hook, dwmsEventTime) {

	; Figure out which application window was created by searching PAWindows
	; for matching criteria
	crit := hook.MatchCriteria[1]
	text := hook.MatchCriteria[2]
	for app in PAWindows["keys"] {
		for win in PAWindows[app]["keys"] {
			if crit = PAWindows[app][win].criteria && text = PAWindows[app][win].wintext {

				; found the window
				PAWindows[app][win].Update(hwnd)

				; ToolTip "Window opened: " app "/" win " [" hwnd "] <- " crit "/" text "`n"
				; SetTimer ToolTip, -7000

				; set up an event trigger for when this window is closed
;debug				WinEvent.Close(_PAWindowCloseCallback, hwnd, 1)
				break 2		; break out of both for loops
			}
		}
	}
}


; This callback function is called when a specific window is closed
;
_PAWindowCloseCallback(hwnd, hook, dwmsEventTime) {

	; Update the PAWindows and _WindowKeys entries for the closed window.
	
	if PAWindows.GetAppWin(hwnd, &app, &win) {

		; ToolTip "Window closed: " app "/" win " [" hwnd "]" 
		; SetTimer ToolTip, -5000
		try {
			PAWindows[app][win].Close(false)
		} catch {
		}
	}
	
}





; Helper functions
PAToolTip(message, duration := 5000) {
	static currentmessage := ""

	if SubStr(message, 1, 1) = "+" {
		currentmessage := currentmessage . SubStr(message, 2)
	} else {
		currentmessage := message
	}
	
	ToolTip currentmessage
	SetTimer ToolTip, -duration
}

/*

; Enable/disable PACS Assistant
PAEnable(state) {
	global PAActive

	PAActive := state
	InitDaemons(state)
	
	; PAToolTip(PAActive . " [" . !PAActive . "]")

}


; Toggle (enable/disable) PACS Assistant
PAToggle() {
	global PAActive

	PAEnable(!PAActive)
}
*/



; Called once at startup to do necessary initialization
;
PA_Init() {

	; Get Windows system double click setting
	PA_DoubleClickSetting := DllCall("GetDoubleClickTime")

	; Initialize systemwide settings
	PASettings_Init()

	; Register Windows hooks to monitor window open events for all the
	; windows of interest (all of the windows in PAWindows)
; debugmsg := ""
	for app in PAWindows["keys"] {
		for win in PAWindows[app]["keys"] {
			if PAWindows[app][win].criteria {
				WinEvent.Show(_PAWindowshowCallback, PAWindows[app][win].criteria, ,PAWindows[app][win].wintext)
; debugmsg .= PAWindows[app][win].criteria " / " PAWindows[app][win].wintext "`n"
			}
		}
	}

; MsgBox(debugmsg)
	;

	PAWindows.Update()

	PAWindows.ReadSettings()

	; Set up special EI key mappings
	PA_MapActivateEIKeys()

	; Read ICD code file
	ICDReadCodeFile()

}



; Main starting point for PACS Assistant
;
PA_Main() {
	global PACurrentPatient

	; Basic set up
	PA_Init()

	; Set up GUI
	PAGui_Init()

    ; Start daemons
    InitDaemons(true)
	
}




; Start up PACS Assistant

PA_Main()

