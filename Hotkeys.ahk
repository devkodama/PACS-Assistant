/**
 * Hotkeys.ahk
 * 
 * Hotkey definitions for PACS Assistant
 * 
 */ 


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#include <Cred>

#Include Globals.ahk

#Include Network.ahk




/**********************************************************
 * Hotkey definitions
 */


; F2 is the top level on/off switch for PACS Assistant.
;
; It toggles the switch by sending a mouse click to the PA GUI.
; Directly changing PASettings["active"].value does not work, 
; as it does not update the toggle switch on screen.
;
; [todo] if PA is minimized, this doesn't work; 
; might want to check and directly change PASettings["active"].value
;
; [todo] should be calling a PAEnable() function rather than doing controlclick here
;
F2:: {
	;	global PASettings
	;   PASettings["active"].value := !PAActive
	
	if (hwndPA := App["PA"].Win["main"].hwnd) {
		; click on the on screen toggle switch, which is located in the lower
		; left corner of the GUI at approx x = 25 and y = WinHeight - 55
		WinGetPos( , , &w, &h, hwndPA)
		ControlClick("X25 Y" . (h - 55), hwndPA)
	}
}


; Tab key mapping:
;	Tab -> PowerScribe Next field
;	Shift-Tab -> PowerScribe Previous field
;	Ctrl-Tab -> PowerScribe Go to end of current line (End). If pressed again,
;			move down one line and go to end of line.
;	Ctrl-Shift-Tab -> PowerScribe Move up one line and go to end of line.
;
;	In effect for EI (images, 4dm, desktop text and list areas), PS (main or report) windows
;
$Tab:: {
	if Setting["hkTab"].on && Context(Mouse(), "PS main report addendum", "EI i1 i2 4dm d/text d/list") {
		PSCmdNextField()
	} else {
		Send("{Tab}")
	}
}
$+Tab:: {
	if Setting["hkTab"].on && Context(Mouse(), "PS main report addendum", "EI i1 i2 4dm d/text d/list") {
		PSCmdPrevField()
	} else {
		Send("+{Tab}")
	}
}
$^Tab:: {
	if Setting["hkTab"].on && Context(Mouse(), "PS main report addendum", "EI i1 i2 4dm d/text d/list") {
		if A_PriorHotkey = ThisHotkey {
			PSCmdNextEOL()
		} else {
			PSCmdEOL()
		}
	} else {
		Send("^{Tab}")
	}
}
$^+Tab:: {
	if Setting["hkTab"].on && Context(Mouse(), "PS main report addendum", "EI i1 i2 4dm d/text d/list") {
		PSCmdPrevEOL()
	} else {
		Send("^+{Tab}")
	}
}


; CapsLock mapping
;	CapsLock -> PowerScribe Start/Stop Dictation (F4)
;	Shift-CapsLock -> PowerScribe Sign Dictation (F12)
;						or EI Start reading, Resume reading, Start list
;	Ctrl-CapsLock -> PowerScribe Draft Dictation (F9)
;	Ctrl-Shift-CapsLock -> PowerScribe Prelim Dictation (Alt-F Alt-M (File > Prelim))
;
; In effect for EI and PS windows.
; Alt-CapsLock still works to toggle Caps Lock when the above mappings are in effect.
;
$CapsLock:: {
	if Setting["hkCapsLock"].on && Context(Mouse(), "EI", "PS", "PA") {
		PSCmdToggleMic()
	} else {
		SetCapsLockState(!GetKeyState("CapsLock", "T"))
	}
}
$+CapsLock:: {
	if Setting["hkCapsLock"].on && Context(Mouse(), "EI", "PS", "PA") {
		if PSIsReport() {
			; PS has an open report, so sign the report
			PSCmdSignReport()
		} else {
			; PS does not have an open report, so try to start reading the next case
			EICmdStartReading()
		}
	} else {
		SetCapsLockState true
	}
}
$^CapsLock:: {
	if Setting["hkCapsLock"].on && Context(Mouse(), "EI", "PS", "PA") {
		PSCmdDraftReport()
	} else {
		; do nothing
	}
}
$^+CapsLock:: {
	if Setting["hkCapsLock"].on && Context(Mouse(), "EI", "PS", "PA") {
		PSCmdPreliminary() 
	} else {
		; do nothing
	}
}


; ` key mapping
;	` -> Display Study Details
;	Shift-` -> Toggle between EI List and Text views
;			If List view is currently selected, then click the EI Text button
;			Otherwise, click the EI List button
;	Ctrl-` -> Switch to EI Search area. If pressed a second time, 
;			clear search fields and place cursor in patient last name
;			search field
;
; In effect for EI and PS windows.
;
$`:: {
	if Setting["hkBacktick"].on && Context(Mouse(), "EI", "PS") {
		EICmdDisplayStudyDetails()
	} else {
		Send("``")
	}
}
$+`:: {
	if Setting["hkBacktick"].on && Context(Mouse(), "EI", "PS") {
		EICmdToggleListText()
	} else {
		Send("+``")
	}
}
$^`:: {
	if Setting["hkBacktick"].on && Context(Mouse(), "EI", "PS") {
		if A_PriorHotkey = ThisHotkey {
			EICmdResetSearch()
		} else {
			EICmdShowSearch()
		}
	} else {
		Send("^``")
	}
}


; Esc key mapping
;	Shift-Esc -> Close current study (Remove from list)
;
; In effect for EI images1 and images2 windows.
;
$+Esc:: {
	if Setting["hkEsc"].on && Context(Mouse(), "EI i1 i2") {
		EICmdRemoveFromList()
	} else {
		Send("+{Esc}")
	}
}


; Ctrl-Y and Ctrl-Z mapping
;	Ctrl-Y -> PowerScribe Redo
;	Ctrl-Z -> PowerScribe Undo
;
; In effect for EI (images1, images2, or 4dm), PS windows, also for EI desktop
;	window if Text area is displaying
;
$^y:: {
	if Setting["hkCtrlYZ"].on && Context(Mouse(), "PS", "EI i1 i2 d/text 4dm") {
		PSSend("^y")
	} else {
		Send("^y")
	}
}
$^z:: {
	if Setting["hkCtrlYZ"].on && Context(Mouse(), "PS", "EI i1 i2 d/text 4dm") {
		PSSend("^z")
	} else {
		Send("^z")
	}
}


; Space bar key mapping
;
; Send a double click (Click 2) at the current mouse position.
; Blocks user mouse movement or input while sending the double 
; click, for reliability
;
; In effect for EI image windows, EI desktop if list area showing
;
; If ClickLock is set to Manual, then pressing space bar while L mouse button is down
; will engage click lock. A second press will disengage. In effect for EI image windows
;
; [todo] If pressed while the mouse cursor is on the PS report window and
; a text selection exists, sends Delete keystroke
;
$Space:: {
	global LButton_ClickLockon
	global LButton_ClickLocktrigger
	
	if Context(Mouse(), "EI i1 i2") {
		if Setting["ClickLock"].value = "Manual" && GetKeyState("LButton") {
			; space was pressed while L mouse button is logically down, inside an EI images window
			if !LButton_ClickLocktrigger {
				; check whether L mouse button is physically down
				if GetKeyState("LButton", "P") {
					; if L mouse being pressed, activate click lock, for when L mouse button is released (see LButton hotkey)
					PASound("EIClickLockOn")
					LButton_ClickLocktrigger := true	
				} else {
					; if L mouse not being pressed, logically release the L mouse button
					if LButton_ClickLockon {
						Click("U")
						PASound("EIClickLockOff")
						LButton_ClickLockon := false
					}
				}
			} else {
				; ClickLock already triggered, so untrigger it
				PASound("EIClickLockOff")
				LButton_ClickLocktrigger := false
			}
		} else {
			; avoid double clicking on a window by checking system double click timeout
			if Setting["hkSpaceClick"].on && (!A_TimeSincePriorHotkey || A_PriorHotkey != A_ThisHotkey || A_TimeSincePriorHotkey > PADoubleClickSetting) {
				BlockInput true
				Click 2
				BlockInput false
			}
		}
	} else if Context(Mouse(), "EI d/list") {
		; avoid double clicking on a window by checking system double click timeout
		if Setting["hkSpaceClick"].on && (!A_TimeSincePriorHotkey || A_PriorHotkey != A_ThisHotkey || A_TimeSincePriorHotkey > PADoubleClickSetting) {
			BlockInput true
			Click 2
			BlockInput false
		}
	} else if Context(Mouse(), "PS report addendum") {
		if Setting["hkSpaceDelete"].on {
			; Check to see if there is a text selection in the PS report area
			; If so, smart delete it

		} else {
			; If not, send a space
			Send("{Space}")
		}
	} else {
		; Send a space
		Send("{Space}")
	}
}


; Mouse button mappings for click lock
;
; Spacebar can activate click lock, see above
;
; [todo] Auto click lock doesn't work properly
;
global LButton_ClickLockon := false		; true when ClickLock is engaged
global LButton_ClickLocktrigger := false	; true when Clicklock has been triggered by spacebar but before Lbutton is released
global LButton_lastdown := 0			; tick count of last L button down


; R button needs to release click lock
~RButton:: {
	global LButton_ClickLockon
	global LButton_lastdown

	; PAToolTip("RButton down - last:" Button_lastdown)
	if PAActive {
		if LButton_ClickLockon {
			Click("U")							; L mouse button up
			PASound("EIClickLockOff")
			LButton_ClickLockon := false
		}
	}
}


; L button
; Right now, Auto has been disabled in PASettings() [wip]
~LButton:: {
	global LButton_ClickLockon
	global LButton_lastdown

	; PAToolTip("LButton down - last:" Button_lastdown)

	if PAActive {
		if Setting["ClickLock"].value = "Manual" {
;	 		if LButton_ClickLockon {
;				Click("U")
;				SoundBeep(600, 100)
;			LButton_ClickLockon := false
;			} 
			; else {
			; 	Click("D")
			; }
		} else if Setting["ClickLock"].value = "Auto" {
			if Context(Mouse(), "EI i1 i2") {
				LButton_lastdown := A_TickCount
				SetTimer(_LButton_beep, -Setting["ClickLock_interval"].value)
				if LButton_ClickLockon {
					PASound("EIClickLockOff")
					LButton_ClickLockon := false
				}
			}
			; Click("D")
		} else {
			; Click("D")
		}
	} else {
		; Click("D")
	}
}


; L button up may engage click lock if space was pressed
; Or releases click lock if currently enabled
; Auto doesn't work [wip]
LButton Up:: {
	global LButton_ClickLockon
	global LButton_ClickLocktrigger
	global LButton_lastdown

	if PAActive {

		if Setting["ClickLock"].value = "Manual" {
			if LButton_ClickLocktrigger {
				; engage Click Lock
				click("D")					; keep L mouse button down
				LButton_ClickLocktrigger := false
				LButton_ClickLockon := true
			} else if LButton_ClickLockon {
				; disengage Click Lock
				Click("U")					; release logically held L mouse button
				PASound("EIClickLockOff")
				LButton_ClickLockon := false
			}
		} else if Setting["ClickLock"].value = "Auto" {
			if A_TickCount - LButton_lastdown > Setting["ClickLock_interval"].value {
				Click("D")					; L mouse button down
				LButton_ClickLockon := true
			} else {
				Click("U")					; L mouse button up
				SetTimer(_LButton_beep, 0)	; cancel pending beep
				; if LButton_ClickLockon {
				; 	SoundBeep(600, 100)
				; 	LButton_ClickLockon := false
				; }
			}
		} else {
			Click("U")							; L mouse button up
		}

	} else {
		Click("U")							; L mouse button up
	}

}


; callback function for sounding beep when activating Auto click lock
; Auto doesn't work [wip]
_LButton_beep() {
	PASound("EIClickLockOn")
}




/**********************************************************
 * Functions defined by this module
 */


; Some EI shortcut keys operate on the currently active series which is not
; always the one under the cursor. For these keys, it is helpful to send a mouse
; click to activate the series under the mouse prior to sending the shortcut.
; The W/L preset keys, next/prev series, and invert keys are examples.
;
; For these keys, listed in _EIKeyList, a hotkey is created to cause
; a Click XButton2 to be sent to make the series under the mouse cursor active
; so that the key will act upon the series under the cursor. The hotkey itself is 
; then sent. XButton2 does not do anything by default in EI (but it does activate 
; the series under the cursor) so it appears to be a safe choice.
;
; Click XButton2 won't be sent if the L or R mouse button is being held down.
;
; In effect for EI image windows
;
; Pass an array of hotkey strings, without the $ modifier.
; Each time this function is called, any hotkeys previously defined by this function are 
; disabled (no way to actually delete them) prior to defining the new list of hotkeys.
;

PA_EIKeyList := ["1", "2", "3", "4", "5", "+1", "+2", "+3", "+4", "+5", "d", "+d", "f", "+f", "x", "w", "+w", "e", "+e"]

PA_MapActivateEIKeys(keylist := PA_EIKeyList) {
	static definedhklist := Array()		; remembers all hotkeys which have been defined through this function

	if keylist {
		for hk in definedhklist {
			Hotkey(hk, "Off")	; disable previously defined hotkeys
		}

		for key in keylist {
			; (re)define a hotkey for key
			hkey := "$" . key
			Hotkey(hkey, _PA_EIHotkey, "On")
			
			; if the hotkey is not already in the definedhklist, then add it
			found := 0
			for hk in definedhklist {
				if hk = hkey {
					found := true
					break
				}
			}
			if !found {
				definedhklist.Push(hkey)	; remember the new hotkey
			}
		}
	}
}


_PA_EIHotkey(key) {
	global PADoubleClickSetting

	if Context(Mouse(), "EI i1 i2") {
		; only send a Click if it won't result in a double click
		if !A_TimeSincePriorHotkey || A_TimeSincePriorHotkey > PADoubleClickSetting {
			
			; only send a Click if the L & R mouse buttons are NOT being pressed, otherwise don't do anything
			if !GetKeyState("LButton") && !GetKeyState("RButton") {
				Click("XButton2")
				Sleep(100)	; allows time (ms) for viewport to become active before sending the shortcut key
			}
		}
	}
	Send(SubStr(key,2))		; don't send the $ that is part of the hotkey name
}




/**********************************************************
 * Hotkeys for testing
 */


; Left Shift key mapping
;	single press ->
;	double press ->
; (~ prefix keeps the native function of the key)
; ~LShift:: {
; 	if (A_PriorHotkey != "~LShift" or A_TimeSincePriorHotkey > PADoubleClickSetting)
; 	 {
; 		 ; Too much time between presses, so this isn't a double-press.
; 		 KeyWait "LShift"
; 		 return
; 	 }
;  ;    MsgBox "You double-pressed the left shift key."
; 		 SoundBeep(659, 80)
; 		 SoundBeep(622, 80)
; }



; this one is for testing
+F2:: {
	if Context(Mouse(), "PA") {
		SoundBeep(440)
		PAShowHome()
	}
}


; this one is for testing
F3:: {
	global PACurrentPatient
	global PACurrentStudy
	
	pt := EIRetrievePatientInfo()
	if pt { 
		PACurrentPatient.lastname := pt.lastname
		PACurrentPatient.firstname := pt.firstname
		PACurrentPatient.dob := pt.dob
		PACurrentPatient.sex := pt.sex

		st := EIRetrieveStudyInfo(pt)
		if st {
			PACurrentStudy.accession := st.accession
			PACurrentStudy.lastfirst := st.lastfirst
			PACurrentStudy.dobraw := st.dobraw
			PACurrentStudy.description := st.description
			PACurrentStudy.facility := st.facility
			PACurrentStudy.patienttype := st.patienttype
			PACurrentStudy.priority := st.priority
			PACurrentStudy.orderingmd := st.orderingmd
			PACurrentStudy.referringmd := st.referringmd
			PACurrentStudy.reason := st.reason
			PACurrentStudy.other := st.other
			PACurrentStudy.techcomments := st.techcomments
		}

	}

	; MsgBox PACurrentStudy.print()


}


; this one is for testing
+F3:: {
; Insert Dr. _ was notified on ____ at ...
	If PACurrentStudy.accession {
		if !PACurrentStudy.orderingmd && !PACurrentStudy.referringmd {
			return
		}
		mdarr := StrSplit((PACurrentStudy.orderingmd ? PACurrentStudy.orderingmd : PACurrentStudy.referringmd), ",")
		if mdarr.Length = 2 {
			; if first name has more than one word, just keep the first word
			md := StrTitle(StrSplit(Trim(mdarr[2]), " ")[1] . " " . mdarr[1])
			phrase := "Dr. " . md . " was notified of these findings on " . FormatTime(A_Now, "M/d/yyyy") . " at "
			PSPaste(phrase)
		}
	}

}


; ^F3:: {

; }


F8:: {
	pwd := GUIGetPassword()
	TTip("password = " pwd)
}

+F8:: {
	CoordMode("Mouse", "Screen")
	MouseGetPos(&x, &y)
	TTip("x, y: " x ", " y " -> " MonitorNumber(x, y))
}

^F8:: {
	
}


