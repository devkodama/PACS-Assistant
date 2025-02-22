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
 *  GetApp(hwnd)        - returns the application key of the specified window
 *  GetWin(hwnd)        - returns the window key of the specified window
 * 
 *  Context(hwnd, contexts*) - returns true if the passed hwnd matches the passed context(s), false otherwise
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




/**********************************************************
 * Global variables and constants used in this module
 */


; Reverse lookup table for determining the app and window given an hwnd
;
; Entries are of the form:
;
;   _HwndLookup[hwnd] := WinItem
;
_HwndLookup := Map()




/**********************************************************
 * Classes defined by this module
 * 
 */


; WinItem class
; 
; WinItem properties:
;
;   parentapp   - AppItem, parent app to which this window belongs
;   key         - string, window id, e.g. "desktop", "images1", "images2", "main", "login", etc.
;
;	fulltitle	- string, full title of window, not used for matching
;	searchtitle	- string, short title of window, used for matching
;	wintext		- string, window text to match, used for matching
;
;	hook_open	- function to be called when this window is opened
;	hook_close	- function to be called when this window is closed
;
;   parentwindow - WinItem, parent window if this is a pseudowindow, zero if this is a true window
;
;	hwnd		- 0 if window doesn't exist, HWND of the window if it not a pseudowindow
;               - Pseudowindows return the hwnd of their parent window
;
;	criteria	- string, combined search string generated from searchtitle and exename of parent app
;
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	opentime	- tickcount when window was last opened (from A_TickCount)
;
;   x           - current screen x position of the window
;   y           - current screen y position of the window
;   w           - current width of the window
;   h           - current height of the window
;
;	savex		- saved screen x position of the window
;	savey		- saved screen y position of the window
;	savew		- saved width of the window (should be >= 100)
;	saveh		- saved height of the window (should be >= 100)
;
;
; WinItem methods:
;
;   Update()    - updates properties for the window (visible, minimized, opentime, etc.)
;
; Pseudowindows can also be tracked by this class. Pseudowindows are not
; unique system windows, but are a subpage of a window such as the Text display
; area of the EI desktop page.
; 
; A pseudowindow is defined by setting parentwindow at instantiation to
; the parent window (WinItem).
;
; To instantiate a new WinItem, use:
;
;   WinItem(parentapp, key, id, fulltitle, [searchtitle, wintext, hook_open, hook_close, parentwindow])
;
; where parentapp is the owning App object. If parentapp is null,
; then this window is not associated with an app.
;
;
class WinItem {

    __New(parentapp, key, fulltitle, searchtitle := "", wintext := "", hook_open := 0, hook_close := 0, parentwindow := 0, hwnd := 0) {
        this.parentapp := parentapp
        this.key := key
        this.fulltitle := fulltitle
        this.searchtitle := searchtitle
        this.wintext := wintext
        this.hook_open := hook_open
        this.hook_close := hook_close

        this.savex := 0
        this.savey := 0
        this.savew := 0
        this.saveh := 0

        ; check if this is a psuedowindow
        if parentwindow {

            ; this is a pseudowindow
            this.parentwindow := parentwindow
            this.criteria := ""
            this.hwnd := 0

            this.opentime := 0
            this.visible := false
            this.minimized := false
            this.x := 0
            this.y := 0
            this.w := 0
            this.h := 0

        } else {

            ; this is a real window, not a pseudowindow
            this.parentwindow := 0

            ; store the search criteria for this window
            if parentapp && parentapp.exename {
                this.criteria := searchtitle . " ahk_exe " . parentapp.exename
            } else {
                this.criteria := searchtitle
            }
            
            ; If we are passed a hwnd, use it. If not, look for it by criteria.
            if hwnd {
                this.hwnd := hwnd
            } else {
                ; check if the window exists, get its hwnd
                DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
                try {
                    this.hwnd := WinExist(this.criteria, this.wintext)
                } catch {
                    this.hwnd := 0
                }
            }

            if this.hwnd {
                ; success, found a matching window, save the visibility, minimized, and opentime
                this.opentime := A_TickCount
                try {
                    this.visible := (WinGetStyle(this.hwnd) & WS_VISIBLE) ? true : false
                    try {
                        this.minimized := WinGetMinMax(this.hwnd) = -1 ? true : false
                    } catch {
                        this.minimized := false
                    }
                } catch {
                    this.visible := false
                    this.minimized := false
                }
                try {
                    WinGetPos(&x, &y, &w, &h, this.hwnd)
                    this.x := x
                    this.y := y
                    this.w := w
                    this.h := h
                } catch {
                    this.x := 0
                    this.y := 0
                    this.w := 0
                    this.h := 0
                }
            } else {
                ; no existing window at this time
                this.opentime := 0
                this.visible := false
                this.minimized := false
                this.x := 0
                this.y := 0
                this.w := 0
                this.h := 0
            }
        }
    }

    hwnd {
        get {
            if this.parentwindow {
                return this.parentwindow.hwnd
            }
            if !this.hwnd {
                ; try to find the window
                ; if this.criteria {
                ;     DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
                ;     try {
                ;         this.hwnd := WinExist(this.criteria, this.wintext)
                ;         this.opentime := A_TickCount
                ;     } catch {
                ;         this.hwnd := 0
                ;     }

                ; } else {
                ;     this.hwnd := 0
                ; }
            }
            return this.hwnd
        }
        set {
            if this.parentwindow {
                this.hwnd := 0
            } else {
                this.hwnd := Value
            }
        }
    }

    ; if a non-zero hwnd is passed, it is assumed to be the valid hwnd for this window
    Update(hwnd := 0) {

        ; check if this is a psuedowindow
        if this.parentwindow {

            ; pseudowindow, don't do anything (for now)

        } else {

            if hwnd {

                ; assume a passed non-zero hwnd is valid
                this.hwnd := hwnd
                this.opentime := A_TickCount

            } else if !this.hwnd {

                ; look to see if the window exists, get its hwnd
                if this.criteria {
                    DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
                    try {
                        this.hwnd := WinExist(this.criteria, this.wintext)
                        this.opentime := A_TickCount
                    } catch {
                        this.hwnd := 0
                    }
                } else {
                    this.hwnd := 0
                }
            }

            if this.hwnd {
                ; update the visibility, minimized, and position of this window
                try {
                    this.visible := (WinGetStyle(this.hwnd) & WS_VISIBLE) ? true : false
                    try {
                        this.minimized := WinGetMinMax(this.hwnd) = -1 ? true : false
                    } catch {
                        this.hwnd := 0
                        this.opentime := 0
                        this.visible := false
                        this.minimized := false
                    }
                } catch {
                    this.hwnd := 0
                    this.opentime := 0
                    this.visible := false
                    this.minimized := false
                }
                try {
                    WinGetPos(&x, &y, &w, &h, this.hwnd)
                    this.x := x
                    this.y := y
                    this.w := w
                    this.h := h
                } catch {
                    this.hwnd := 0
                    this.opentime := 0
                    this.visible := false
                    this.minimized := false
                    this.x := 0
                    this.y := 0
                    this.w := 0
                    this.h := 0
                }
            } else {
                ; window does not exist
                this.visible := false
                this.minimized := false
                this.x := 0
                this.y := 0
                this.w := 0
                this.h := 0
            }
        }
    }

}


; AppItem properties:
;
;   key         - string, single letter app code used as a key, e.g. "V", "E", "P", "H", "P"
;
;	exename		- string, executable name, used for matching, e.g. "Nuance.PowerScribe360.exe"
;   appname     - string, full name of app, e.g. "PowerScribe 360"
;
;;   searchtitle - string, optional, title of main window of app, used for window matching
;;   wintext     - string, optional, window text used for window matching of main window
;
;   Win[]       - Map, all windows associated with the app
;
;   pid         - process ID of this function
;   isrunning   - (read only) true if app has been started, false if not
;
;   wincount    - returns total number of windows being tracked
;   activecount - returns number of windows that are active
;
; AppItem methods:
;
;   Update()    - Searches for all windows associated with this app
;                   and adds a WinItem object for each window to Win[]
;
;
; To instantiate a new AppItem, use:
;
;       AppItem(key, id, exename, appname, [searchtitle, wintext])
;
; Creating an AppItem  populate its Win Map.
;
; 
;
class AppItem {

    __New(key, exename, appname, searchtitle := "", wintext := "") {
        this.key := key
        this.exename := exename
        this.appname := appname
;        this.searchtitle := searchtitle
;        this.criteria := searchtitle
;        this.wintext := wintext

        this.Win := Map()
        this._pid := 0

        if !exename {
            return 0    ; cannot create an AppItem without an exename
        }
        this.criteria := " ahk_exe " . exename
        
        ; check whether the app is running, get its PID
        DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
        try {
            ; found a running process
            this._pid := WinGetPID(this.criteria)
        } catch {
            ; did not find a running process
            this._pid := 0
        }

        ; * Currently the following events are supported: `Show`, `Create`, `Close`, `Exist`, `NotExist`, `Active`, `NotActive`, `Move`, 
        ; * `MoveStart`, `MoveEnd`, `Minimize`, `Restore`, `Maximize`. See comments for the functions for more information.
       
        ; Set up event handlers
        this.hookShow := WinEvent.Show(_cbAppShow, this.criteria)
        this.hookCreate := WinEvent.Create(_cbAppCreate, this.criteria)
        this.hookClose := WinEvent.Close(_cbAppClose, this.criteria)
        this.hookMove := WinEvent.Move(_cbAppMove, this.criteria)
        this.hookMinimize := WinEvent.Minimize(_cbAppMinimize, this.criteria)
        this.hookRestore := WinEvent.Restore(_cbAppRestore, this.criteria)
        this.hookMaximize := WinEvent.Maximize(_cbAppMaximize, this.criteria)

    }

    pid {
        get {
            if !this._pid {
                ; Try to find the pid
            ;     DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows
            ;     try {
            ;         ; found a running process
            ;         this._pid := WinGetPID(this.criteria)
            ;     } catch {
            ;         ; did not find a running process
            ;     }
            ; }
            return this._pid
        }
        set {
            this._pid := Value
        }
    }

    isrunning {
        get {
            return this.pid ? true : false
        }
    }

    ; Searches for all windows associated with this app and updates
    ; the existing WinItem or adds a new WinItem corresponding to each window
    Update() {

        ; get all the windows belonging to this app
        if !this.criteria {
            ; can't update
            return 0
        }

        hwndarr := WinGetList(this.criteria)
        for hwnd in hwndarr {

            ; look for an existing Win entry that matches this window hwnd
            wintitle := WinGetTitle(hwnd)
            wintext := WinGetText(hwnd)
            match  := false

            for k, w in this.Win {

                if w.parentwindow {
                    ; skip pseudowindows
                    continue
                }

                if w.searchtitle {
                    if InStr(wintitle, w.searchtitle) {
                        ; w.searchtitle found within wintitle
                        if !w.wintext || InStr(wintext, w.wintext) {
                            ; we have a match
                            match := true
                            ; update the WinItem with this hwnd
                            w.Update(hwnd)
                            break
                        }
                    }
                }
            }

            if !match {
                ; Did not find a matching WinItem in Win[], so create a new WinItem.
                ; The window key for the new item is "1001", "1002", etc....
                ; Find the next unused key
                k := 1001
                while this.Win.Has(String(k)) {
                    k++
                }
                ; Add the new window
                this.Win[String(k)] := WinItem(this, String(k), wintitle, , , , , , hwnd)
            }
        }

    }

}







; This callback function is called when a matching window is shown.
;
_cbAppShow(hwnd, hook, dwmsEventTime) {
    global PAApps

    ; Update the window that matches this hwnd



    ; Get the PID of this process


	; Figure out which application window was shown by searching
	; for the matching criteria in all the apps within PAApps[]
	criteria := hook.MatchCriteria[1]

    for app in PAApps {
        if app.criteria = criteria {
            ; found the matching app

            ; search the windows of the app for a match


            for k, w in this.Win {

                if w.parentwindow {
                    ; skip pseudowindows
                    continue
                }

                if w.searchtitle {
                    if InStr(wintitle, w.searchtitle) {
                        ; w.searchtitle found within wintitle
                        if !w.wintext || InStr(wintext, w.wintext) {
                            ; we have a match
                            match := true
                            ; update the WinItem with this hwnd
                            w.Update(hwnd)
                            break
                        }
                    }
                }
            }

        }
    }



	text := hook.MatchCriteria[2]

    

            ; look for an existing Win entry that matches this window hwnd
            wintitle := WinGetTitle(hwnd)
            wintext := WinGetText(hwnd)
            match  := false



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


; This callback function is called when a matching window is created.
;
_cbAppCreate(hwnd, hook, dwmsEventTime) {

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



/**********************************************************
 * Functions defined by this module
 * 
 */


; Returns the application key of the specified window
;
GetApp(hwnd) {
    if wi := _HwndLookup(hwnd) {
        return wi.appid
    } else {
        return ""
    }
}


; Returns the window key of the specified window
GetWin(hwnd) {
    if wi := _HwndLookup(hwnd) {
        return wi.key
    } else {
        return ""
    }
}


; Check whether the passed hwnd matches the passed context(s)
;
; contexts are strings of a format similar to:
;   "E"             - matches any EI window
;	"E12"           - matches either EI images1 or images2 windows
;	"Ewt"	        - matches either EI desktop list page or text page
;	"P"	    		- matches any PS window
;	"Pr"    		- matches PS report window
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

    if !hwnd || !contexts {
        return false
    }
	; contexts[] is an array of strings

    app := GetApp(hwnd)

    if app {
        win := GetWin(hwnd)

        for context in contexts {
            if app == SubStr(context, 1, 1) {
                ; found an app match

                j := 2
                while j <= context.Length {
                    subcontext := SubStr(context, j, 1)
                    if win == subcontext {
                        ; found a win match
                        if !App[app].Win[win].pseudo {
                            ; this is a real window so we're done, return success
                            return true
                        } else {
                            ; [todo] determine if pseudowindow condition(s) is true via callback
                            
                            
                            return true
                        }
                        
                    }
                } else {
                    ; no windows (no subcontext) to match with, so we've succeeded
                    return true
                }
            }
        }
    }

    ; no match, failed
    return false
}

