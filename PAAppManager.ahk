/**
 * PAAppManager.ahk
 *
 * 
 *
 * This module defines the following classes:
 *
 *  The AppItem class corresponds to a single application such as Cisco VPN Client,
 *  or EI, or PowerScribe, or Epic. It tracks and returns information
 *  about the status of the application and its windows. Any number of windows
 *  can be managed within one AppItem object.
 * 
 *  The WinItem class tracks and returns information about an individual window that
 *  belongs to an AppItem.
 * 
 * 
 * This module defines the functions:
 *  
 *  GetWinItem(hwnd)    - Returns the WinItem for the specified window handle
 *  GetAppkey(hwnd)     - Returns the application key of the specified window handle
 *  GetWinkey(hwnd)     - Returns the window key of the specified window handle
 * 
 *  Mouse()             - Returns hwnd of window under mouse
 * 
 *  Context(hwnd, contexts*) - Check whether the passed hwnd matches the passed context(s).
 *                              Returns true if hwnd matches any of the context strings, false otherwise.
 * 
 *  PrintWindows([app, win])    - Returns diagnostic info about a window(s) for an app (or all apps) as a string
 * 
 *  SavePositionsAll()      - For all windows of all apps, saves the current x, y, width, and height of each in its savepos proprety.
 *  RestorePositionsAll()   - For all windows of all apps, restores window to the size and position in its savepos property.
 *  WritePositionsAll()     - For all windows of all apps, write window's savepos to user specific settings.ini file.
 *  ReadPositionsAll()      - For all windows of all apps, reads window's savepos from user specific settings.ini file.
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <WinEvent>

#Include PAGlobals.ahk
#Include PASettings.ahk




/**********************************************************
 * Global variables and constants used in this module
 */






/**********************************************************
 * Classes defined by this module
 * 
 */



; WinPos class
;
; A simple class to hold the position and size of a window
;
; Properties:
;   x           - current screen x position of the window
;   y           - current screen y position of the window
;   w           - current width of the window
;   h           - current height of the window
;
class WinPos {
    __New(x := 0, y := 0, w := 0, h := 0) {
        this.x := x
        this.y := y
        this.w := w
        this.h := h
    }
}


; WinItem class
; 
; Tracks a window of interest. All windows belong to a parent
; application (parentapp).
;
; Pseudowindows can be tracked by this class. Pseudowindows are not
; unique system windows, but are a subpage of a window such as the Text display
; page of the EI desktop window. A pseudowindow is defined by setting 
; parentwindow at instantiation to the parent window (WinItem). Real windows by
; contrast have no parentwindow. A pseudowindow should also define the
; validate function, which should return true if the pseudowindow is
; showing or false if not.
;
;
; WinItem properties:
;
;   parentapp   - AppItem, parent app to which this window belongs
;   key         - string, window identifier, e.g. "desktop", "images1", "images2", "main", "login", etc.
;
;	fulltitle	- string, full title of window, not used for matching, just descriptive
;	searchtitle	- string, short title of window, used for matching
;	wintext		- string, window text to match, used for matching
;
;	hook_open	- function to be called when this window is opened, does not apply to pseudowindows
;	hook_close	- function to be called when this window is closed, does not apply to pseudowindows
;
;   parentwindow - WinItem, parent window if this is a pseudowindow, zero if this is a true window
;   validate    - function to be called to determine whether this pseudowindow is showing
;
;	hwnd		- 0 if window doesn't exist, HWND of the window if it is a true window, 
;                 HWND of the parent window if it is a pseudowindow
;	criteria	- string, combined search string generated from searchtitle and exename of parent app
;
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	opentime	- tickcount when window was last opened (from A_TickCount)
;
;   pos         - current WinPos of the window
;   savepos     - saved WinPos of the window
;
;   appkey      - returns the key of the parent app (parentapp), e.g. "EI"
;
; WinItem methods:
;
;   Update()    - Updates properties for the window including hwnd, visible, minimized, opentime
;   Print()     - Returns diagnostic info about this window as a string 
;
;	SavePosition()	    - Saves the current x, y, width, and height of a window in its savepos proprety
;	RestorePosition() 	- Restores window to the size and position in its savepos property.
;
;	CenterWindow(parentwindow)	- Centers a window over a parent window (WinItem)
;
;	WritePosition()	- Write window's savepos to user specific settings.ini file.
;	ReadPosition()	- Reads window's savepos from user specific settings.ini file.
;
;
; To instantiate a new WinItem, use:
;
;   WinItem(parentapp, key, fulltitle, [searchtitle, wintext, hook_open, hook_close, parentwindow, validate, hwnd])
;
; 
;
;
class WinItem {

    __New(parentapp, key, fulltitle, searchtitle := "", wintext := "", hook_open := 0, hook_close := 0, parentwindow := 0, validate := 0, hwnd := 0) {
        global _HwndLookup
        
        this.parentapp := parentapp
        this.key := key
        this.fulltitle := fulltitle
        this.searchtitle := searchtitle
        this.wintext := wintext
        this.hook_open := hook_open
        this.hook_close := hook_close
        this.validate :=  validate
        
        this.visible := false
        this.minimized := false
        
        this._pos := WinPos()
        this._savepos := WinPos()

        ; _hwnd, opentime, criteria are set below

        ; check if this is a psuedowindow
        if parentwindow {

            ; this is a pseudowindow
            this.parentwindow := parentwindow
            this.criteria := ""
            this._hwnd := 0
            this.opentime := 0

        } else {

            ; this is a real window, not a pseudowindow
            this.parentwindow := 0

            ; store the search criteria for this window
            if searchtitle {
                this.criteria := searchtitle
                if parentapp && parentapp.exename {
                    this.criteria .= " ahk_exe " . parentapp.exename
                }
            } else {
                this.criteria := ""
            }

            ; If we are passed a hwnd, use it. If not, look for the window by criteria.
            if hwnd {
                this._hwnd := hwnd
            } else if this.criteria {
                ; check if the window exists, get its hwnd
                DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
                try {
                    this._hwnd := WinExist(this.criteria, this.wintext)
                } catch {
                    this._hwnd := 0
                }
            } else {
                ; no criteria to look for
                this._hwnd := 0
            }

            if this._hwnd {
                ; success, update reverse lookup table _HwndLookup
                _HwndLookup[this._hwnd] := this
                this.opentime := A_TickCount

                ; update the visibility, minimized, and opentime
                try {
                    this.visible := (WinGetStyle(this.hwnd) & WS_VISIBLE) ? true : false
                } catch {
                }
                try {
                    this.minimized := WinGetMinMax(this.hwnd) = -1 ? true : false
                } catch {
                }
                try {
                    WinGetPos(&x, &y, &w, &h, this.hwnd)
                    this._pos := WinPos(x, y, w, h)
                } catch {
                }
            } else {
                ; no existing window at this time
                this.opentime := 0
            }
        }
    }

    hwnd {
        get {
            if this.parentwindow && this.parentwindow.hwnd {
                return this.parentwindow.hwnd
            } else {
                return this._hwnd
            }
        }
        set {
            this._hwnd := Value
        }
    }

    pos {
        get {
            try {
                WinGetPos(&x, &y, &w, &h, this.hwnd)
                this._pos.x := x
                this._pos.y := y
                this._pos.w := w
                this._pos.h := h
            } catch {
                this._pos.x := 0
                this._pos.y := 0
                this._pos.w := 0
                this._pos.h := 0
            }
            return this._pos
        }
        set {
            this._pos.x := Value.x
            this._pos.y := Value.y
            this._pos.w := Value.w
            this._pos.h := Value.h
        }
    }
    
    savepos {
        get {
            return this._savepos
        }
        set {
            this._savepos.x := Value.x
            this._savepos.y := Value.y
            this._savepos.w := Value.w
            this._savepos.h := Value.h
        }
    }

    appkey {
        get {
            if this.parentapp {
                return this.parentapp.key
            } else {
                return ""
            }
        }
    }

    ; if a non-zero hwnd is passed, it is assumed to be the valid hwnd for this window
    Update(hwnd := 0) {
        global _HwndLookup

        ; check if this is a psuedowindow
        if this.parentwindow {

            ; pseudowindow, don't do anything (for now)

        } else {

            if hwnd {
                ; assume a passed non-zero hwnd is valid

            } else {
                ; hwnd is null                

                ; search for the window by criteria, get its hwnd
                if this.criteria {
                    DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
                    try {
                        hwnd := WinExist(this.criteria, this.wintext)
                    } catch {
                        ; window no longer exists
                        hwnd := 0
                    }
                } else {
                    ; do nothing
                }

            }

            ; At this point, hwnd has a value either passed to us
            ; or found from the window search criteria. If it is null,
            ; that means the window doesn't exist

            if hwnd {

                if this.hwnd != hwnd {
                    ; the window is new or has a new handle
                    
                    if this.hwnd {
                        ; delete reverse lookup entry
                        try {
                            _HwndLookup.Delete(this.hwnd)
                        }
                    }

                    ; assign the new hwnd
                    this.hwnd := hwnd
                    _HwndLookup[hwnd] := this
                    this.opentime := A_TickCount
                }
                
                ; update the visibility and minimized
                visible := (WinGetStyle(hwnd) & WS_VISIBLE) ? true : false
                minimized := WinGetMinMax(hwnd) = -1 ? true : false

                ; call hook_open if window transitions from not visible or minimized to visible and not minimized
                if !_PAUpdate_Initial && PAActive && this.hook_open && (!this.visible || this.minimized) && (visible && !minimized) {
                    this.hook_open.Call()
                }

                ; call hook_close if window transitions from visible and not minimized to not visible or minimzed
                if PAActive && this.hook_close && (this.visible && !this.minimized) && (!visible || minimized) {
                    this.hook_close.Call()
                }

                this.visible := visible
                this.minimized := minimized

            } else {

                ; the window no longer exists
                ; if this.hwnd exists, delete its reverse lookup entry
                if this.hwnd {
                    try {
                        _HwndLookup.Delete(this.hwnd)
                    }
                    this.hwnd := 0
                    this.opentime := 0
                }
                this.visible := false
                this.minimized := false
                this.pos := WinPos()

            }

        }

    }

    ; Returns diagnostic info about this window as a string
    ; does not show non-existing windows or pseudowindows unless showall is set to true
    Print(showall := false) {

        if showall || (this.hwnd && !this.parentwindow) {
            output := "&nbsp;&nbsp;&nbsp;&nbsp;"

            output .= this.key " (" this.hwnd 
            
            if this.hwnd {
                output .= (this.visible ? "/visible" : " hidden") . (this.minimized ? "/minimized) - " : ") - ")
            } else {
                output .= ") - "
            }

            output .= this.fulltitle " (" this.pos.x ", " this.pos.y ", " this.pos.w ", " this.pos.h ") / (" this.savepos.x ", " this.savepos.y ", " this.savepos.w ", " this.savepos.h ")"

            ; output .= this.fulltitle " (= '" this.criteria "'"  
            ; if this.wintext {
            ;     output .= ", '" this.wintext "')"
            ; } else {
            ;     output .= ")"
            ; }
            
            output .= "<br />"

        } else {

            output := ""

        }

        return output
    }

	; Closes the window.
	; Calls ahk WinClose() to actually close the window
	Close() {
        global _HwndLookup
		
		if this.hwnd  {

			; delete the reverse lookup
            try {
                _HwndLookup.Delete(this.hwnd)
            }

			; close the actual window
            try {
                WinClose(this.hwnd)
            }
            this.hwnd := 0
            this.opentime := 0
            this.visible := false
            this.minimized := false
            this.pos := WinPos()
		}
	}

    ; Saves the current x, y, width, and height of a window in its savepos proprety
    ; Returns true on success, false on failure.
    SavePosition() {
        try {
            if this.hwnd {
				WinGetPos(&x, &y, &w, &h, this.hwnd)
				if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
                    this._savepos.x := x
                    this._savepos.y := y
                    this._savepos.w := w
                    this._savepos.h := h
                    return true
				}
			}
        }
        return false
    }

    ; Restores window to the size and position in its savepos property.
    ; Returns true on success, false on failure.
    RestorePosition() {
        try {
			if this.hwnd {
                if this._savepos.w >= WINDOWPOSITION_MINWIDTH && this._savepos.h >= WINDOWPOSITION_MINHEIGHT {
    				WinMove(this._savepos.x, this._savepos.y, this._savepos.w, this._savepos.h, this.hwnd)
                    return true
                }
			}
        }
        return false
    }

    ; Centers this window over another (parent) window (parentwindow is a WinItem)
    ; Returns true on success, false on failure.
    CenterWindow(parentwindow) {

		if parentwindow {
			cw := 0
			pw := 0

            try {
                ; get child and parent window positions and dimensions
                if this.hwnd {
                    WinGetPos( , , &cw, &ch, this.hwnd)
                }
                if parentwindow.hwnd {
                    WinGetPos(&px, &py, &pw, &ph, parentwindow.hwnd)
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
            }
        }
        return false
    }

    ; Write window's savepos to user specific settings.ini file.
    ; If this is a pseudowindow, do nothing, return failure.
    ; Returns true on success, false on failure.
	WritePosition() {
        if this.parentwindow {
            ; pseuodwindow, return failure
            return false
        }

        try {
            if this._savepos.w >= WINDOWPOSITION_MINWIDTH && this._savepos.h >= WINDOWPOSITION_MINHEIGHT {
                appkey := this.parentapp.key
                winkey := this.key
                sectionname := A_ComputerName . "_WinPos"
                inifile := PASettings["inifile"].value
;    MsgBox(inifile "/" sectionname "/" appkey "/" winkey)
;    MsgBox(this._savepos.x "," this._savepos.y "," this._savepos.w "," this._savepos.h)
                if inifile {
                    IniWrite(this._savepos.x, inifile, sectionname, appkey . winkey . "_x") 
                    IniWrite(this._savepos.y, inifile, sectionname, appkey . winkey . "_y")
                    IniWrite(this._savepos.w, inifile, sectionname, appkey . winkey . "_w")
                    IniWrite(this._savepos.h, inifile, sectionname, appkey . winkey . "_h")
                }
            }
        }
    }

    ; Reads window's savepos from user specific settings.ini file.
    ; If this is a pseudowindow, do nothing, return failure.
    ; Returns true on success, false on failure.
    ReadPosition() {
        if this.parentwindow {
            ; pseuodwindow, return failure
            return false
        }

        try {
            appkey := this.parentapp.key
            winkey := this.key
            sectionname := A_ComputerName . "_WinPos"
            inifile := PASettings["inifile"].value
    ; MsgBox(inifile "/" sectionname "/" appkey "/" winkey)
            if inifile {
                x := IniRead(inifile, sectionname, appkey . winkey . "_x", -1)
                y := IniRead(inifile, sectionname, appkey . winkey . "_y", -1)
                w := IniRead(inifile, sectionname, appkey . winkey . "_w", 0)
                h := IniRead(inifile, sectionname, appkey . winkey . "_h", 0)
                if w >= WINDOWPOSITION_MINWIDTH && h >= WINDOWPOSITION_MINHEIGHT {
                    this._savepos.x := x
                    this._savepos.y := y
                    this._savepos.w := w
                    this._savepos.h := h
    ; MsgBox(this._savepos.x "," this._savepos.y "," this._savepos.w "," this._savepos.h)
                    return true
                }
            }
        }
        return false
    }

}


; AppItem properties:
;
;   key         - string, app identifier, e.g. "VPN", "EI", "PS", "EPIC", ...
;
;	exename		- string, executable name, used for matching, e.g. "Nuance.PowerScribe360.exe"
;   appname     - string, full name of app, e.g. "PowerScribe 360"
;
;   searchtitle - string, optional, title of main window of app, used for window matching
;   wintext     - string, optional, window text used for window matching of main window
;
;   Win[]       - Map, all windows associated with the app
;
;   pid         - process ID of this function
;   isrunning   - (read only) true if app has been started, false if not
;
;;;   wincount    - returns total number of windows being tracked
;;;   activecount - returns number of windows that are active
;
; AppItem methods:
;
;   Update()    -  Updates the pid for this app
;                   If the pid is non-zero, then updates all the windows in Win[]
;   Print()     - Returns diagnostic info about the window(s) for this app as a string
;
;   CountOpenWindows()   - Returns the number of open (and visible?) windows that belong to this app
; 
;	SavePositions()     - For all windows of this app,
;                           saves the current x, y, width, and height
;                           of each in its savepos proprety.
;	RestorePositions() 	- For all windows of this app,
;                           restores window to the size and position in its savepos property.
;
;	WritePositions()	- For all windows of this app,
;                           write window's savepos to user specific settings.ini file.
;	ReadPositions()	    - For all windows of this app,
;                           reads window's savepos from user specific settings.ini file.
;
;
; To instantiate a new AppItem, use:
;
;       AppItem(key, exename, appname, [searchtitle, wintext])
;
; 
class AppItem {

    __New(key, exename, appname, searchtitle := "", wintext := "") {

        if !exename {
            return 0    ; cannot create an AppItem without an exename
        }

        this.key := key
        this.exename := exename
        this.appname := appname
        this.searchtitle := searchtitle
        this.wintext := wintext

        this.Win := Map()
        this.pid := 0

        ; store the search criteria for this window
        if searchtitle {
            this.criteria := searchtitle . " ahk_exe " . exename
        } else {
            this.criteria := "ahk_exe " . exename
        }

        ; check whether the app is running, get its PID
        DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
        try {
            ; found a running process
            this.pid := WinGetPID(this.criteria)
        } catch {
            ; did not find a running process
            this.pid := 0
        }

        ; * Currently the following events are supported: `Show`, `Create`, `Close`, `Exist`, `NotExist`, `Active`, `NotActive`, `Move`, 
        ; * `MoveStart`, `MoveEnd`, `Minimize`, `Restore`, `Maximize`. See comments for the functions for more information.
       
        ; Set up event handlers
        ; this.hookShow := WinEvent.Show(_cbAppShow, this.criteria)
        ; this.hookCreate := WinEvent.Create(_cbAppCreate, this.criteria)
        ; this.hookClose := WinEvent.Close(_cbAppClose, this.criteria)
        ; this.hookMove := WinEvent.Move(_cbAppMove, this.criteria)
        ; this.hookMinimize := WinEvent.Minimize(_cbAppMinimize, this.criteria)
        ; this.hookRestore := WinEvent.Restore(_cbAppRestore, this.criteria)
        ; this.hookMaximize := WinEvent.Maximize(_cbAppMaximize, this.criteria)

    }

    isrunning {
        get {
            ; look for a running app, get its PID
            DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
            try {
                this.pid := WinGetPID(this.criteria)
            } catch {
                ; didn't find a running process
                this.pid := 0
            }
            return this.pid ? true : false
        }
    }

    ; Updates the pid for this window
    ;
    ; If the pid is non-zero, then updates all the windows in Win[]
    ;
    Update() {


        if !this.criteria {
            ; can't update
            return
        }

        ; check whether the app is running, get its PID
        DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
        try {
            ; found a running process
            this.pid := WinGetPID(this.criteria)
        } catch {
            ; did not find a running process
            this.pid := 0
        }

        if this.pid {
            for , win in this.Win {
                win.Update()
            }
        }
    }

    ; Returns diagnostic info about the window(s) for this app as a string
    Print(winkey := "") {

        if this.pid {

            output .= this.key " (pid " this.pid ") - " this.appname " (= '" this.criteria "')<br />"
            
            if winkey {
                ; return info just for one window of this app
                output .= this.Win[winkey].Print()
            } else {
                    ;return info for all windows of this app
                    for k, w in this.Win {
                        output .= w.Print()
                    }
                }
        } else {
            output := ""
        }

        return output
    }

    ; Returns the number of open (and visible?) windows that belong to this app
    CountOpenWindows() {
      	count := 0

        ; check all the open windows for a match with this app
        for , win in _HwndLookup {
            if win.appkey = this.key {
                count++
            }
        }
        return count
    }

    ; For all windows of this app, saves the current x, y, width, and height
    ; of each in its savepos proprety.
    SavePositions() {
        for , win in this.Win {
            win.SavePosition()
        }
    }

    ; For all windows of this app, restores window to the size and position
    ; in its savepos property.
    RestorePositions() {
        for , win in this.Win {
            win.RestorePosition()
        }
    }
    
	; For all windows of this app, write window's savepos to 
    ; user specific settings.ini file.
    WritePositions() {
        for , win in this.Win {
            win.WritePosition()
        }
    }

    ; For all windows of this app, reads window's savepos from
    ; user specific settings.ini file.
    ReadPositions() {
        for , win in this.Win {
            win.ReadPosition()
        }
    }

}







; This callback function is called when a matching window is shown.
;
_cbAppShow(hwnd, hook, dwmsEventTime) {
    global PAApps

PAToolTip("_cbAppShow(" hwnd ", " hook.MatchCriteria[1] ", " hook.MatchCriteria[2] ")")

    ; Is this a known open window?
    ; try {
    ;     win := _HwndLookup[hwnd]
    ; } catch {
    ;     win := 0
    ; }
    
    ; if win {    
    ;     ; found a window matching this hwnd
    ;     ; update it
    ;     win.Update()

    ; } else {

    ;     ; Figure out which application's window was shown by searching
    ;     ; for the matching criteria in all the apps within PAApps[]
    ;     criteria := hook.MatchCriteria[1]
    ;     for app in PAApps {
    ;         if app.criteria = criteria {
    ;             ; found the matching app
    ;             ; update all its windows
    ;             app.Update()
    ;             break
    ;         }
    ;     }
    ; }

; 	wintext := hook.MatchCriteria[2]

}


; This callback function is called when a matching window is created.
;
_cbAppCreate(hwnd, hook, dwmsEventTime) {

	wintitle := hook.MatchCriteria[1]
 	wintext := hook.MatchCriteria[2]

PAToolTip("_cbAppCreate(" hwnd ", " wintitle ", " wintext ")")
return

; 	; Figure out which application window was created by searching PAWindows
; 	; for matching criteria
; 	crit := hook.MatchCriteria[1]
; 	text := hook.MatchCriteria[2]
; 	for app in PAWindows["keys"] {
; 		for win in PAWindows[app]["keys"] {
; 			if crit = PAWindows[app][win].criteria && text = PAWindows[app][win].wintext {

; 				; found the window
; 				PAWindows[app][win].Update(hwnd)

; 				; ToolTip "Window opened: " app "/" win " [" hwnd "] <- " crit "/" text "`n"
; 				; SetTimer ToolTip, -7000

; 				; set up an event trigger for when this window is closed
; ;debug				WinEvent.Close(_PAWindowCloseCallback, hwnd, 1)
; 				break 2		; break out of both for loops
; 			}
; 		}
; 	}
}


; This callback function is called when a matching window is closed.
;
_cbAppClose(hwnd, hook, dwmsEventTime) {

	wintitle := hook.MatchCriteria[1]
 	wintext := hook.MatchCriteria[2]

PAToolTip("_cbAppClose(" hwnd ", " wintitle ", " wintext ")")
return


; 	; Figure out which application window was created by searching PAWindows
; 	; for matching criteria
; 	crit := hook.MatchCriteria[1]
; 	text := hook.MatchCriteria[2]
; 	for app in PAWindows["keys"] {
; 		for win in PAWindows[app]["keys"] {
; 			if crit = PAWindows[app][win].criteria && text = PAWindows[app][win].wintext {

; 				; found the window
; 				PAWindows[app][win].Update(hwnd)

; 				; ToolTip "Window opened: " app "/" win " [" hwnd "] <- " crit "/" text "`n"
; 				; SetTimer ToolTip, -7000

; 				; set up an event trigger for when this window is closed
; ;debug				WinEvent.Close(_PAWindowCloseCallback, hwnd, 1)
; 				break 2		; break out of both for loops
; 			}
; 		}
; 	}
}



/**********************************************************
 * Functions defined by this module
 * 
 */




; Returns the WinItem for the specified window handle
GetWinItem(hwnd) {
    
    try {
        win := _HwndLookup[hwnd]
    } catch {
        win := 0
    }

    return win
}

; Returns the application key of the specified window handle
GetAppkey(hwnd) {
    
    try {
        win := _HwndLookup[hwnd]
    } catch {
        return ""
    }

    if win && win.parentapp {
        return win.parentapp.key
    } else {
        return ""
    }

}


; Returns the window key of the specified window handle
GetWinkey(hwnd) {
    
    try {
        win := _HwndLookup[hwnd]
    } catch {
        return ""
    }

    if win {
        return win.key
    } else {
        return ""
    }
}


; Returns hwnd of window under mouse
Mouse() {
    MouseGetPos( , , &hwnd)
    return hwnd
}


; Check whether the passed hwnd matches the passed context(s)
;
; Contexts are strings of a format similar to:
;	"EI"					- matches any EI window
;	"EI i1 i2"		        - matches either EI images1 or images2 windows
;	"EI d                   - matches EI desktop window
;	"EI desktop/list desktop/text"	- matches EI desktop window if list page or text page is showing
;	"PS"					- matches any PS window
;	"PS report"				- matches PS report window
;	...
;
; Multiple context strings may be passed.
;
; Returns true if hwnd matches any of the context strings.
;
; Returns false if hwnd doesn't match any of the context strings, 
; if hwnd does not exist, or if context is empty ("").
;
; Case sensitive
;
Context(hwnd, contexts*) {

    if !PAActive {
        return false
    }
    if !hwnd || !contexts {
        return false
    }
	; contexts[] is an array of strings

    win := GetWinItem(hwnd)
    if win {
        
        appkey := GetAppkey(hwnd)

        if appkey {

            for context in contexts {

                carr := StrSplit(context, " ")
                capp := carr[1]		;get the app key from the context string

                if appkey == capp {
                    j := 2
                    if j > carr.Length {
                        ; no windows to match with, so we've succeeded
                        return true
                    }

                    ; need to check for a match among the windows in the context
                    winkey := win.key

                    while j <= carr.Length {
                        cwin := carr[j]
                        j++

                        ; split out page context (pseudowindow) if there is one
					    if (k := InStr(cwin, "/")) {
                            cpag := SubStr(cwin, k + 1)
                            cwin := SubStr(cwin, 1, k - 1)
                        
                            if winkey == cwin {
                                ; found a window match
                                ; now look for a pseudowindow match
                                fn := App[appkey].Win[winkey].validate
                                if fn && fn.Call() {
                                    ; pseudowindow condition successfully validated
                                    ; return success
                                    return true
                                }
                            }

                        } else if winkey == cwin {

                            ; no page context
                            ; found a window match, so we've succeeded
                            return true

                        }
                    }
                }
            }
        }
    }

    ; no match, failed
    return false
}


; Update all windows of all apps.
UpdateAll() {
    global _PAUpdate_Initial

	for app in PAApps {
		app.Update()
	}

    _PAUpdate_Initial := false
}



; Returns diagnostic info about a window(s) for an app (or all apps)
; as a string
;
PrintWindows(appkey := "", winkey := "") {
    global App

	output := ""

    if appkey {
        if winkey {
            ; return info just for one window of one app
            output .= App[appkey].Win[winkey].Print()
        } else {
            ; return info for all windows of one app
            output .= App[appkey].Print()
        }
    } else {
        ; return info for all apps, all windows
        for k, a in App {
            output .= a.Print()
        }
    }

	return output
}


; For all windows of all apps, saves the current x, y, width, and height
; of each in its savepos proprety.
SavePositionsAll() {
    for app in PAApps {
        app.SavePositions()
    }
}

; For all windows of all apps, restores window to the size and position
; in its savepos property.
RestorePositionsAll() {
    for app in PAApps {
        app.RestorePositions()
    }
}

; For all windows of all apps, write window's savepos to 
; user specific settings.ini file.
WritePositionsAll() {
    for app in PAApps {
        app.WritePositions()
    }
}

; For all windows of all apps, reads window's savepos from
; user specific settings.ini file.
ReadPositionsAll() {
    for app in PAApps {
        app.ReadPositions()
    }
}

