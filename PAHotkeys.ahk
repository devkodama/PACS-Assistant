/**
 * PAHotkeys.ahk
 * 
 * Hotkey definitions for PACS Assistant
 * 
 */ 

#Requires AutoHotkey v2.0
#SingleInstance Force



#Include <FindText>
#Include "PAFindTextStrings.ahk"

#Include PAGlobals.ahk


/*
** Global variables and constants
*/





/***********************************************/



; The F2 hotkey toggles the top level on/off switch for PACS Assistant.
;
F2:: {
;	global PASettings
;    PASettings["active"].value := !PAActive

	hwndPA := PAWindows["PA"]["main"].hwnd
	if hwndPA {
		WinActivate(hwndPA)
		MouseGetPos(&savex, &savey)
		Send "{Click 25 275}" 
		MouseMove(savex, savey)
	}
}

+F2:: {
	global PAGui


	PAGui_Post("log", "innerHTML", CurrentUserCredentials.username " / " CurrentUserCredentials.password)
	

}




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

; 	hwndEI := PAWindows["EI"]["images1"].hwnd
; 	if hwndEI {
; 		WinGetClientPos(&x0, &y0, &w0, &h0, hwndEI)
; ;msgbox("xywh=" x0 "," y0 "," w0 "," h0 " but=" PAText["EI_RemoveFromList"])
; 		ok := FindText(&x, &y, x0, y0, x0 + 1280, y0 + 64, 0, 0, PAText["EI_RemoveFromList"])
; ;		MsgBox("ok: " ok)
; 		MsgBox("ok[1].1 ok[1].2 ok[1].3 ok[1].4 ok[1].x ok[1].y ok[1].id = " ok[1].1 " " ok[1].2 " " ok[1].3 " " ok[1].4 " " ok[1].x " " ok[1].y " " ok[1].id)
; 		PAToolTip("xywh0=" x0 "," y0 "," w0 "," h0 "  xy=" x "," y)
; 		if ok {
; ; PAToolTip("found close")
; 		}
; 	}	
; }



; Tab key mapping:
;	Tab -> PowerScribe Next field
;	Shift-Tab -> PowerScribe Previous field
;	Ctrl-Tab -> PowerScribe Go to end of current line (End). If pressed again,
;			move down one line and go to end of line.
;	Ctrl-Shift-Tab -> PowerScribe Move up one line and go to end of line.
;
;	In effect for EI (images, 4dm, desktop text area), PS (main or report) windows
;
$Tab:: {
	if PAActive && PACheckContext( , , "PS main report", "EI images1 images2 desktop/text desktop/list 4dm") {
		PSSend("{Tab}")
		SoundBeep(440, 10)
	} else {
		Send("{Tab}")
	}
}
$+Tab:: {
	if PAActive && PACheckContext( , , "PS main report", "EI images1 images2 desktop/text desktop/list 4dm") {
		PSSend("{Blind}+{Tab}")
		SoundBeep(440, 10)
	} else {
		Send("+{Tab}")
	}
}
$^Tab:: {
	if PAActive && PACheckContext( , , "PS main report", "EI images1 images2 desktop/text desktop/list 4dm") {
		if A_PriorHotkey = "$^Tab" {
			PSSend("{Down}{End}")
		} else {
			PSSend("{End}")
		}
		SoundBeep(440, 10)
	} else {
		Send("^{Tab}")
	}
}
$^+Tab:: {
	if PAActive && PACheckContext( , , "PS main report", "EI images1 images2 desktop/text desktop/list 4dm") {
		PSSend("{Up}{End}")
		SoundBeep(440, 10)
	} else {
		Send("^+{Tab}")
	}
}



; CapsLock mapping
;	CapsLock -> PowerScribe Start/Stop Dictation (F4)
;	Shift-CapsLock -> PowerScribe Sign Dictation (F12) OR EI Start reading (Ctrl-Enter)
;	Ctrl-CapsLock -> PowerScribe Draft Dictation (F9)
;	Ctrl-Shift-CapsLock -> PowerScribe Prelim Dictation (Alt-F Alt-M (File > Prelim))
;
; In effect for EI and PS windows.
; Alt-CapsLock still works to toggle Caps Lock when the above mappings are in effect.
;
$CapsLock:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		PSSend("{F4}")							; Start/Stop Dictation
		PASound("toggle dictate")
		; PSDictateIsOn(true)						; force update of status
	} else {
		SetCapsLockState(!GetKeyState("CapsLock", "T"))
	}
}
$+CapsLock:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		if PSIsReport() {
			; PS has an open report, so sign the report
			PSSend("{F12}")							; Sign report
			PASound("sign report")
		} else {
			; PS does not have an open report, so try to start reading the next case
			EISend("^{Enter}")					; Start reading
			PASound("Start dictation")
		}
	} else {
		SetCapsLockState true
	}
}
$^CapsLock:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		PSSend("{F9}")							; save as Draft
		PASound("draft report")
	} else {
		; do nothing
	}
}
$^+CapsLock:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		PSSend("{Alt down}fm{Alt up}")			; save as Prelim
		PASound("prelim report")
	} else {
				; do nothing
	}
}



; q key mapping
;	q -> Display Study Details, by clicking the first Study Details icon
;			that is in off state, found on either EI image window. This
;			effectively toggles between active and comparison study details
;			in the most common scenarios.
; 		 If necessary, switches to the EI Text area.
;
; In effect for EI image windows
;
$q:: {
	if PAActive && PACheckContext( , , "EI images1 images2") {
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
			WinActivate(EIhwnd)
			CoordMode("Mouse", "Screen")
			MouseGetPos(&savex, &savey)
			FindText().Click(x, y)
			MouseMove(savex, savey)
			if !EIIsText() {
				EIClickDesktop("EIText")
			}
		}
	} else {
		Send("q")
	}
}



; ` key mapping
;	` -> Toggle between EI List and Text views
;			If List view is currently selected, then click the EI Text button
;			Otherwise, click the EI List button
;	Shift-` -> Switch to EI Search area. If pressed a second time, 
;			clear search fields and place cursor in patient last name
;			search field
;
; In effect for EI and PS windows.
;
$`:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		if EIIsList() {
			EIClickDesktop("EIText")
		} else {
			EIClickDesktop("EIList")
		}
	} else {
		Send("``")
	}
}
$+`:: {
	if PAActive && PACheckContext( , , "EI", "PS") {
		if A_PriorHotkey = "$+``" {
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
		} else {
			EIClickDesktop("EISearch")
		}
	} else {
		Send("+``")
	}
}


; Esc key mapping
;	Esc -> Close current study (Remove from list)
;
; In effect for EI images1 and images2 windows.
;
$Esc:: {
	if PAActive && PACheckContext( , , "EI images1 images2") {
		EIClickImages("EI_RemoveFromList")
	} else {
		Send("{Esc}")
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
	if PAActive && PACheckContext( , , "PS", "EI images1 images2 desktop/text 4dm") {
		PSSend("^y")
	} else {
		Send("^y")
	}
}
$^z:: {
	if PAActive && PACheckContext( , , "PS", "EI images1 images2 desktop/text 4dm") {
		PSSend("^z")
	} else {
		Send("^z")
	}
}



; Ctrl-S mapping
;	Augment Ctrl-S to give audio feedback when used in EI
; (~ prefix preserves the native function of the key)
~^s:: {
	if PAActive && PACheckContext( , , "EI") {
		SoundBeep(200,200)
		SoundBeep(200,200)
	}
}



; Left Shift key mapping
;	single press ->
;	double press ->
; (~ prefix keeps the native function of the key)
; ~LShift:: {
; 	if (A_PriorHotkey != "~LShift" or A_TimeSincePriorHotkey > PA_DoubleClickSetting)
; 	 {
; 		 ; Too much time between presses, so this isn't a double-press.
; 		 KeyWait "LShift"
; 		 return
; 	 }
;  ;    MsgBox "You double-pressed the left shift key."
; 		 SoundBeep(659, 80)
; 		 SoundBeep(622, 80)
; }





; Space bar key mapping
;
; If pressed while the mouse cursor is on an EI image window,
; a doubleclick (Click 2) is sent to double click at the current mouse position.
;
; [todo] If pressed while the mouse cursor is on the PS report window and
; a text selection exists, sends Delete keystroke
;
; Blocks user mouse movement or input while sending doubleclick, for reliability
;
; In effect for EI image windows, EI desktop if list area showing
;
; If ClickLock is set to manual, then pressing space bar while L mouse button is down
; will engage click lock. A second press will disengage. In effect for EI image windows
;
$Space:: {
	global LButton_ClickLockon
	global LButton_ClickLockmanual
	
	if PAActive {
		PAWindows.GetAppWin("", &app, &win)
		if PACheckContext(app, win, "EI images1 images2") {
			if PASettings["ClickLock"].value = "Manual" && GetKeyState("LButton") {
				; space was pressed while L mouse button is logically down, inside an EI images window
				if !LButton_ClickLockmanual {
					; check whether L mouse button is physically down
					if GetKeyState("LButton", "P") {
						; if so activate click lock, for when L mouse button is released (see LButton hotkey)
						SoundBeep(1000, 100)
						LButton_ClickLockmanual := true	
					} else {
						; if not, logically release the L mouse button
						if LButton_ClickLockon {
							Click("U")
							SoundBeep(600, 100)
							LButton_ClickLockon := false
						}
					}
				} else {
					SoundBeep(600, 100)
					LButton_ClickLockmanual := false
				}
			} else {
				; if LButton_ClickLockon {
				; 	Click("U")
				; 	PAToolTip("release")
				; 	SoundBeep(600, 100)
				; 	LButton_ClickLockon := false
				; }
				; avoid double clicking on a window by checking system double click timeout
				if !A_TimeSincePriorHotkey || A_TimeSincePriorHotkey > PA_DoubleClickSetting {
					BlockInput true
					Click 2
					BlockInput false
				}
			}
		} else if PACheckContext(app, win, "EI desktop/list") {
			; avoid double clicking on a window by checking system double click timeout
			if !A_TimeSincePriorHotkey || A_TimeSincePriorHotkey > PA_DoubleClickSetting {
				BlockInput true
				Click 2
				BlockInput false
			}
		} else {
			Send("{Space}")
		}
	}  else {
		Send("{Space}")
	}
	
	/*else if PAWindows.GetAppWin("", &app, &win) && (app = "PS" && win = "report") {
		; check to see if there is a text selection in the PS report area 
	}*/

}




; Left mouse button mapping for click lock
;
; Spacebar can also activate click lock, see above
;
; [todo] Auto doesn't work properly
;
global LButton_lastdown := 0			; tick count of last L button down
global LButton_ClickLockon := false
global LButton_ClickLockmanual := false

~RButton:: {
	global LButton_lastdown
	global LButton_ClickLockon

	; PAToolTip("RButton down - last:" Button_lastdown)
	if PAActive && LButton_ClickLockon {
		Click("U")							; L mouse button up
		SoundBeep(600, 100)
		LButton_ClickLockon := false
	}
}

~LButton:: {
	global LButton_lastdown
	global LButton_ClickLockon

	; PAToolTip("LButton down - last:" Button_lastdown)

	if PAActive {
		if PASettings["ClickLock"].value = "Manual" {
;	 		if LButton_ClickLockon {
;				Click("U")
;				SoundBeep(600, 100)
;			LButton_ClickLockon := false
;			} 
			; else {
			; 	Click("D")
			; }
		} else if PASettings["ClickLock"].value = "Auto" {
			if PACheckContext( , , "EI images1 images2") {
				LButton_lastdown := A_TickCount
				SetTimer(_LButton_beep, -PASettings["ClickLock_interval"].value)
				if LButton_ClickLockon {
					SoundBeep(600, 100)
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

LButton Up:: {
	global LButton_lastdown
	global LButton_ClickLockon
	global LButton_ClickLockmanual

	if PAActive {

		if PASettings["ClickLock"].value = "Manual" {
			if LButton_ClickLockmanual {
				click("D")					; L mouse button down
				LButton_ClickLockmanual := false
				LButton_ClickLockon := true
			} else if LButton_ClickLockon {
			; 	Click("D")					; L mouse button down
			; } else {
				Click("U")
				SoundBeep(600, 100)
				LButton_ClickLockon := false
			}
		} else if PASettings["ClickLock"].value = "Auto" {
			if A_TickCount - LButton_lastdown > PASettings["ClickLock_interval"].value {
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

; callback
_LButton_beep() {
	SoundBeep(1000,100)
}




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

_EIKeyList := ["1", "2", "3", "4", "5", "+1", "+2", "+3", "+4", "+5", 
		"d", "+d", "f", "+f", "x", "w", "+w", "e", "+e"]

PA_MapEIKeys() {
	for key in _EIKeyList {
		Hotkey("$" . key, _PA_MapEIKeysCallback)
	}
}

_PA_MapEIKeysCallback(key) {
	global PA_DoubleClickSetting

	if PAActive && PACheckContext( , , "EI images1 images2") {
		; only send a Click if it won't result in a double click
		if !A_TimeSincePriorHotkey || A_TimeSincePriorHotkey > PA_DoubleClickSetting {
; only send a Click if the L & R mouse buttons are NOT being pressed, otherwise don't do anything
			if !GetKeyState("LButton") && !GetKeyState("RButton") {
				Click("XButton2")
				Sleep(100)	; allows time (ms) for viewport to become active before sending the shortcut key
			}
		}
	}
	Send(SubStr(key,2))		; don't send the $ that is part of the hotkey name
}




