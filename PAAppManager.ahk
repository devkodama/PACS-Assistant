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
;   key         - string, single letter window code used as a key, e.g. "d", "1", "2", "m", "l", etc.
;   id          - string, window id, e.g. "desktop", "images1", "images2", "main", "login", etc.
;
;   parent      - WinItem, parent window if this is a pseudowindow, zero if this is a true window
;
;	appid		- string, single letter app code, the app to which this window belongs
;   
;	fulltitle	- string, full title of window, not used for matching
;	searchtitle	- string, short title of window, used for matching
;
;	criteria	- string, combined search string generated from searchtitle and exename of parent app
;	wintext		- string, window text to match, used for matching
;
;	hwnd		- 0 if window doesn't exist, HWND of the window if it not a pseudowindow
;               - Pseudowindows return the hwnd of their parent window
;
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	opentime	- timestamp when window was last opened (from A_Now)
;
;	status		- [optional] status item, window specific usage
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
;	hook_open	- function to be called when this window is opened
;	hook_close	- function to be called when this window is closed
;
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

    __New(parentapp, key, id, fulltitle, searchtitle := "", wintext := "", hook_open := 0, hook_close := 0, parentwindow := 0) {
        this.key := key
        this.id := id
        this.appid := parentapp.id
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

            this.parentwindow := parentwindow
            this.criteria := ""
            this.hwnd := ""

        } else {

            this.parentwindow := ""

            if parentapp && parentapp.exename {
                searchtitle .= " ahk_exe " . parentapp.exename
            }
            
            if this.criteria := searchtitle {
                ; Do not want to search hidden text when looking for windows
                DetectHiddenText(false)
                this.hwnd := WinExist(this.criteria, this.wintext)
            } else {
                this.hwnd := 0
            }

            if this.hwnd {
                ; success, found a matching window, save the visibility, minimized, and opentime
                this.visible := (WinGetStyle(this.hwnd) & WS_VISIBLE) ? true : false
                this.minimized := WinGetMinMax(this.hwnd) = -1 ? true : false
                this.opentime := A_Now
                WinGetPos(&x, &y, &w, &h, this.hwnd)
                this.x := x
                this.y := y
                this.w := w
                this.h := h
            } else {
                this.visible := false
                this.minimized := false
                this.opentime := ""
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
                if this.criteria {
                    ; Do not want to search hidden text when looking for windows
                    DetectHiddenText(false)
                    this.hwnd := WinExist(this.criteria, this.wintext)
                } else {
                    this.hwnd := 0
                }
            }
            return this.hwnd
        }
        set {
            if !this.parentwindow {
                this.hwnd := Value
            } else {
                this.hwnd := 0
            }
        }
    }

}


; AppItem properties:
;
;   key         - string, single letter app code used as a key, e.g. "V", "E", "P", "H", "P"
;   id          - string, app id, e.g. "VPN", "EI", "PS", "EPIC", "PA"
;
;	exename		- string, executable name, used for matching, e.g. "Nuance.PowerScribe360.exe"
;   appname     - string, full name of app, e.g. "PowerScribe 360"
;   searchtitle - string, optional, title of main window of app, used for window matching
;   wintext     - string, optional, window text used for window matching of main window
;
;   Win         - Map, all windows associated with the app
;
;   pid         - process ID of this function
;   isrunning   - (read only) true if app has been started, false if not
;
;   wincount    - returns total number of windows being tracked
;   activecount - returns number of windows that are active
;
; AppItem methods:
;
;
; To instantiate a new AppItem, use:
;
;       AppItem(key, id, exename, appname, [searchtitle, wintext])
;
; Creating an AppItem  populate its Win Map.
;
class AppItem {

    __New(key, id, exename, appname, searchtitle := "", wintext := "") {
        this.key := key
        this.id := id
        this.exename := exename
        this.appname := appname
        this.searchtitle := searchtitle
        this.criteria := searchtitle
        this.wintext := wintext

        this.Win := Map()
        this._pid := 0

        if !exename {
            return 0    ; cannot create an AppItem without an exename
        }

        ; if searchtitle {
        ;     this.criteria := searchtitle . " ahk_exe " . exename
        ; } else {
        ;     this.criteria := " ahk_exe " . exename
        ; }
        
        ; ; Do not want to search hidden text when looking for windows
        ; DetectHiddenText(false)
        ; if hwnd := WinExist(this.criteria, wintext) {
        ;     this.pid := WinGetPID(hwnd)
        ; } else {
        ;     this.pid := 0
        ; }


        this.criteria := " ahk_exe " . exename
        
        DetectHiddenText(false)     ; Do not want to search hidden text when looking for windows

        if hwndarr := WinGetList(this.criteria) && hwndarr.Length > 0 {
            this.pid := WinGetPID(hwndarr[1])
        } else {
            this.pid := 0
        }

        ; * Currently the following events are supported: `Show`, `Create`, `Close`, `Exist`, `NotExist`, `Active`, `NotActive`, `Move`, 
        ; * `MoveStart`, `MoveEnd`, `Minimize`, `Restore`, `Maximize`. See comments for the functions for more information.
       
        ; Set up event handlers
        this.hookShow := WinEvent.Show(_cbAppShow, this.criteria)
        this.hookCreate := WinEvent.Create(_cbAppShow, this.criteria)
        this.hookClose := WinEvent.Close(_cbAppClose, this.criteria)
        this.hookMove := WinEvent.Move(_cbAppMove, this.criteria)
        this.hookMinimize := WinEvent.Minimize(_cbAppMinimize, this.criteria)
        this.hookRestore := WinEvent.Restore(_cbAppRestore, this.criteria)
        this.hookMaximize := WinEvent.Maximize(_cbAppMaximize, this.criteria)

    }

    pid {
        get {
            if !this.pid {
                ; Try to find the pid
                ; Do not want to search hidden text when looking for windows
                DetectHiddenText(false)
                if hwnd := WinExist(this.criteria, this.wintext) {
                    this._pid := WinGetPID(hwnd)
                }
            }
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

}







; This callback function is called when a matching window is shown.
;
_cbAppShow(hwnd, hook, dwmsEventTime) {

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

