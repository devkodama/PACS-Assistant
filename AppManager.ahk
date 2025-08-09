/**
 * AppManager.ahk
 * 
 * This module defines classes and function for managing apps, windows, and monitors.
 * 
 * 
 * This module defines the following classes:
 * 
 *  WinPos - stores a 4-tuple x, y, w, h that specifies the position and size
 *  of a window.
 * 
 *  WinItem - tracks and returns information about an individual window that
 *  belongs to an AppItem.
 * 
 *  AppItem - corresponds to a single application such as Cisco VPN Client,
 *  or EI, or PowerScribe, or Epic. It tracks and returns information
 *  about the status of the application and its windows. Any number of windows
 *  can be managed within one AppItem object.
 * 
 * 
 * This module defines the functions:
 *  
 *  GetWinItem(hwnd)    - Returns the WinItem for the specified window handle
 *  GetAppkey(hwnd)     - Returns the application key of the specified window handle
 *  GetWinkey(hwnd)     - Returns the window key of the specified window handle
 *  GetMonitor(hwnd)    - Returns the monitor number that this window is on (upper left corner)
 * 
 *  Mouse()             - Returns the hwnd of the window under the mouse
 * 
 *  Context(hwnd, contexts*) - Check whether the passed hwnd matches the passed context(s).
 *                              Returns true if hwnd matches any of the context strings, false otherwise.
 * 
 *  PrintWindows([app, win, showall])    - Returns diagnostic info about a window(s) for an app (or all apps) as a string
 * 
 *  SavePositionsAll()      - For all windows of all apps, saves the current x, y, width, and height of each in its savepos proprety.
 *  RestorePositionsAll()   - For all windows of all apps, restores window to the size and position in its savepos property.
 *  WritePositionsAll()     - For all windows of all apps, write window's savepos to user specific settings.ini file.
 *  ReadPositionsAll()      - For all windows of all apps, reads window's savepos from user specific settings.ini file.
 * 
 *  MonitorCount()          - Returns the system monitor count
 *  MonitorNumber(x, y)     - Returns the monitor number that contains the x, y coordinates
 *  MonitorPos(N)           - For monitor N, returns the monitor position and size (WinPos).
 *  VirtualScreenPos()      - Returns a WinPos with  the coordinates and size of the virtual screen.
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
** Global variables and constants used or defined in this module
 */


; The number of system monitors
global _MonitorCount := 0

; Array of objects of {l, t, r, b}, representing the left, top, right, bottom
; coordinates for each monitor. The right and bottom coordinates are just outside
; the displayable area.
global _MonitorCoords := Array()


; App is a Map which stores information about all the windows that belong to a
; specific application. 
;
; The following are valid keys for App:
;
;	"PA"     - id "PA", PACS Assistant
;	"VPN"     - id "VPN", Cisco VPN
;	"EI"     - id "EI", Agfa EI
;	"EICLIN"     - id "EICLIN", Agfa EI ClinApps
;	"PS" 	- id "PS", PowerScribe
;	"PSSP" 	- id "PSSPELL", PowerScribe Spelling Window
;	"EP" 	- id "EPIC", Epic Hyperspace
;	"DCAD"     - id "DCAD", DynaCAD Prostate and Breast
;	"DSTUDY"     - id "DCADSTUDY", DynaCAD Prostate and Breast
;	"DLUNG"     - id "DLUNG", DynaCAD Lung
;
;
global App

; define apps
App["PA"] := AppItem("PA", "AutoHotkey64.exe", "PACS Assistant")
App["VPN"] := AppItem("VPN", "vpnui.exe", "Cisco AnyConnect Secure Mobility Client")
App["EI"] := AppItem("EI", "javaw.exe", "Agfa HealthCare Enterprise Imaging")
App["EICLIN"] := AppItem("EICLIN", "javawClinapps.exe", "Agfa HealthCare Enterprise Imaging")
App["PS"] := AppItem("PS", "Nuance.PowerScribe360.exe", "PowerScribe 360")
App["PSSP"] := AppItem("PSSP", "natspeak.exe", "PowerScribe 360 Spelling Window")
App["EPIC"] := AppItem("EPIC", "Hyperdrive.exe", "Hyperspace – Production (PRD)")
App["DCAD"] := AppItem("DCAD", "StudyManager.exe", "DynaCAD")
App["DSTUDY"] := AppItem("DSTUDY", "MRW.exe", "DynaCAD Study")
App["DLUNG"] := AppItem("DLUNG", "MeVisLabApp.exe", "DynaCAD Lung")


; Add known windows of interest belonging to each app.

; PACS Assistant
App["PA"].Win["main"] := WinItem(App["PA"], "main", "PACS Assistant", "PACS Assistant")

; Cisco VPN
App["VPN"].Win["main"] := WinItem(App["VPN"], "main", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Preferences", VPNOpen_VPNmain)
App["VPN"].Win["prefs"] := WinItem(App["VPN"], "prefs", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Export Stats")
App["VPN"].Win["login"] := WinItem(App["VPN"], "login", "Cisco AnyConnect |", "Cisco AnyConnect |", "Username")
App["VPN"].Win["otp"] := WinItem(App["VPN"], "otp", "Cisco AnyConnect |", "Cisco AnyConnect |", "Answer")
App["VPN"].Win["connected"] := WinItem(App["VPN"], "connected", "Cisco AnyConnect", "Cisco AnyConnect", "Security policies")

; Agfa EI
App["EI"].Win["login"] := WinItem(App["EI"], "login", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging")
App["EI"].Win["d"] := WinItem(App["EI"], "d", "Diagnostic Desktop - 8.2.2.062  - mivcsp.adventhealth.com - AHEIAE1", "Diagnostic Desktop - 8", , EIOpen_EIdesktop, EIClose_EIdesktop)
App["EI"].Win["i1"] := WinItem(App["EI"], "i1", "Diagnostic Desktop - Images (1 of 2)", "Diagnostic Desktop - Images (1")
App["EI"].Win["i2"] := WinItem(App["EI"], "i2", "Diagnostic Desktop - Images (2 of 2)", "Diagnostic Desktop - Images (2")
App["EI"].Win["4dm"] := WinItem(App["EI"], "4dm" ,"4DM(Enterprise Imaging) v2017", "4DM", , "Corridor4DM.exe")
App["EI"].Win["chat"] := WinItem(App["EI"], "chat", "Chat Tool", "Chat")
; Agfa EI pseudowindows
App["EI"].Win["list"] := WinItem(App["EI"], "list", "Desktop List page", , , , , App["EI"].Win["d"], EIIsList)
App["EI"].Win["text"] := WinItem(App["EI"], "text", "Desktop Text page", , , , , App["EI"].Win["d"], EIIsText)
App["EI"].Win["search"] := WinItem(App["EI"], "search", "Desktop Search page", , , , , App["EI"].Win["d"], EIIsSearch)
App["EI"].Win["image"] := WinItem(App["EI"], "image", "Desktop Image page", , , , , App["EI"].Win["d"], EIIsImage)

; Agfa ClinApps (e.g. MPR)
App["EICLIN"].Win["mpr"] := WinItem(App["EICLIN"], "mpr", "IMPAX Volume Viewing 3D + MPR Viewing", "IMPAX Volume")

; PowerScribe
App["PS"].Win["main"] := WinItem(App["PS"], "main", "PowerScribe 360 | Reporting", "PowerScribe", , PSOpen_PSmain, PSClose_PSmain)
App["PS"].Win["logout"] := WinItem(App["PS"], "logout", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you wish to log off the application?", PSOpen_PSlogout)
App["PS"].Win["savespeech"] := WinItem(App["PS"], "savespeech", "PowerScribe 360 | Reporting", "PowerScribe", "Your speech files have changed. Do you wish to save the changes?", PSOpen_PSsavespeech)
App["PS"].Win["savereport"] := WinItem(App["PS"], "savereport", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to save the changes to the", PSOpen_PSsavereport)
App["PS"].Win["deletereport"] := WinItem(App["PS"], "deletereport", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to delete", PSOpen_PSdeletereport)
App["PS"].Win["unfilled"] := WinItem(App["PS"], "unfilled", "PowerScribe 360 | Reporting", "PowerScribe", "This report has unfilled fields. Are you sure you wish to sign it?", PSOpen_PSunfilled)
App["PS"].Win["confirmaddendum"] := WinItem(App["PS"], "confirmaddendum", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create an addendum", PSOpen_PSconfirmaddendum)
App["PS"].Win["confirmanother"] := WinItem(App["PS"], "confirmanother", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create another addendum", PSOpen_PSconfirmanotheraddendum)
App["PS"].Win["existing"] := WinItem(App["PS"], "existing", "PowerScribe 360 | Reporting", "PowerScribe", "is associated with an existing report", PSOpen_PSexisting)
App["PS"].Win["continue"] := WinItem(App["PS"], "continue", "PowerScribe 360 | Reporting", "PowerScribe", "Do you wish to continue editing", PSOpen_PScontinue)
App["PS"].Win["ownership"] := WinItem(App["PS"], "ownership", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to acquire ownership", PSOpen_PSownership)
App["PS"].Win["microphone"] := WinItem(App["PS"], "microphone", "PowerScribe 360 | Reporting", "PowerScribe", "Your microphone is disconnected", PSOpen_PSmicrophone)
App["PS"].Win["find"] := WinItem(App["PS"], "find", "Find and Replace", "Find and", , PSOpen_PSfind)
; PowerScribe pseudowindows
App["PS"].Win["login"] := WinItem(App["PS"], "login", "PowerScribe 360 | Reporting", "PowerScribe", "Disable speech", PSOpen_PSlogin, PSClose_PSlogin, App["PS"].Win["main"], PSIsLogin)
App["PS"].Win["home"] := WinItem(App["PS"], "home", "PowerScribe 360 | Reporting", "PowerScribe", "Signing queue", PSOpen_PShome, PSClose_PShome, App["PS"].Win["main"], PSIsHome)
App["PS"].Win["report"] := WinItem(App["PS"], "report", "PowerScribe 360 | Reporting", "PowerScribe", "Report -", PSOpen_PSreport, PSClose_PSreport, App["PS"].Win["main"], PSIsReport)
App["PS"].Win["addendum"] := WinItem(App["PS"], "addendum", "PowerScribe 360 | Reporting", "PowerScribe", "Addendum -", PSOpen_PSreport, PSClose_PSreport, App["PS"].Win["main"], PSIsAddendum)

; PowerScribe spelling window
App["PSSP"].Win["spelling"] := WinItem(App["PSSP"], "spelling", "Spelling Window", "Spelling", , PSOpen_PSspelling)

; for Epic
App["EPIC"].Win["main"] := WinItem(App["EPIC"], "main", "Hyperspace – Production (PRD)", "Production", , EPICOpened_EPICmain, EPICClosed_EPICmain)
App["EPIC"].Win["chat"] := WinItem(App["EPIC"], "chat", "Secure Chat", "Secure Chat")
; pseudowindows, parent is main window App["EI"].Win["main"]
App["EPIC"].Win["login"] := WinItem(App["EPIC"], "login", "Hyperspace - login", , , , , App["EPIC"].Win["main"])
App["EPIC"].Win["timezone"] := WinItem(App["EPIC"], "timezone", "Hyperspace - time zone", , , , , App["EPIC"].Win["main"])
App["EPIC"].Win["chart"] := WinItem(App["EPIC"], "chart", "Hyperspace - chart", , , , , App["EPIC"].Win["main"])



; PAWindows["DCAD"]["keys"] := ["login", "main", "study"]
; PAWindows["DCAD"]["login"] := WindowItem("DCAD", "login", "Login", "Login", , "StudyManager.exe")
; PAWindows["DCAD"]["main"] := WindowItem("DCAD", "main", "Philips DynaCAD", "Philips DynaCAD", , "StudyManager.exe")
; PAWindows["DCAD"]["study"] := WindowItem("DCAD", "study", , , , "MRW.exe")

; PAWindows["DLUNG"]["keys"] := ["login", "main", "second"]
; PAWindows["DLUNG"]["login"] := WindowItem("DLUNG", "login", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
; PAWindows["DLUNG"]["main"] := WindowItem("DLUNG", "main", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
; PAWindows["DLUNG"]["second"] := WindowItem("DLUNG", "second", "DynaCAD Lung - Second Screen", "DynaCAD Lung - Second", , "MeVisLabApp.exe")





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
;   key         - string, window identifier, e.g. "d", "i1", "i2", "main", "login", etc.
;
;	fulltitle	- string, full title of window, not used for matching, just descriptive
;	searchtitle	- string, short title of window, used for matching
;	wintext		- string, window text to match, used for matching
;
;	hook_open	- function to be called when this window is opened, does not apply to pseudowindows
;	hook_close	- function to be called when this window is closed, does not apply to pseudowindows
;
;   parentwindow - WinItem, parent window if this is a pseudowindow, zero if this is a true window
;   validate    - function to be called to determine whether this window or pseudowindow is showing
;
;	hwnd		- 0 if window doesn't exist, HWND of the window if it is a true window, 
;                 HWND of the parent window if it is a pseudowindow
;	criteria	- string, combined search string generated from searchtitle and exename of parent app
;
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	openclosetime	- tickcount when window was last opened or closed (from A_TickCount)
;
;   pos         - current WinPos of the window
;   savepos     - saved WinPos of the window
;
;   appkey      - returns the key of the parent app (parentapp), e.g. "EI"
;
; WinItem methods:
;
;   WinExist()  - Searches for the window (using ahk WinExist()) and returns the hwnd, or 0 if doesn't exist
;   Update()    - Updates properties for the window including hwnd, visible, minimized, openclosetime
;   Print()     - Returns diagnostic info about this window as a string 
;
;   Close()     - Closes the window, clears the hwnd and other properties
;
;	SavePosition()	    - Saves the current x, y, width, and height of a window in its savepos proprety
;	RestorePosition() 	- Restores window to the size and position in its savepos property.
;
;	CenterWindow(parentwindow)	- Centers a window over a parent window or specific monitor
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

        ; _hwnd, openclosetime, criteria are set below

        ; check if this is a psuedowindow
        if parentwindow {

            ; this is a pseudowindow
            this.parentwindow := parentwindow
            this.criteria := ""
            this._hwnd := 0
            this.openclosetime := 0

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
                this.openclosetime := A_TickCount

                ; update the visibility, minimized, and openclosetime
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
                this.openclosetime := 0
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

    ; Searches for the window (using ahk WinExist()) and returns the hwnd, 
    ; or 0 if doesn't exist
    WinExist() {
        return WinExist(this.criteria, this.wintext)
    }

    ; if a non-zero hwnd is passed, it is assumed to be the new valid hwnd for this window
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
                    ; DetectHiddenText(true)
                    hwnd := WinExist(this.criteria, this.wintext)
                } else {
                    ; do nothing, hwnd already = 0
                }
            }

            ; At this point, hwnd has a value either passed to us
            ; or found from the window search criteria. If it is null,
            ; that means the window doesn't exist

            if hwnd {

                if this.hwnd != hwnd {
                    ; the window is new or has a new handle

                    if this.hwnd {
                        ; delete reverse lookup entry for the old handle
                        try {
                            _HwndLookup.Delete(this.hwnd)
                        }
                    }

                    ; save the new hwnd
                    this.hwnd := hwnd
                    _HwndLookup[hwnd] := this
                    this.openclosetime := A_TickCount
                }
                
                ; update the visibility and minimized
                try {
                    visible := (WinGetStyle(hwnd) & WS_VISIBLE) ? true : false
                } catch {
                    visible := false
                }
                try {
                    minimized := WinGetMinMax(hwnd) = -1 ? true : false
                } catch {
                    minimized := false
                }

                ; call hook_open if window transitions from not visible to visible
                if !_PAUpdate_Initial && PAActive && this.hook_open && !this.visible && visible {
                    this.hook_open.Call()
                }

                this.visible := visible
                this.minimized := minimized

            } else {
                ; the window doesn't exist

                ; if this.hwnd exists, delete its reverse lookup entry and call its hook_close
                if this.hwnd {

                    try {
                        _HwndLookup.Delete(this.hwnd)
                    }

                    ; ; call hook_close if window transitions from visible to not visible
                    ; if PAActive && this.hook_close && this.visible && !visible {

                    if PAActive && this.hook_close {
;PAToolTip("calling hook_close for " this.key)
                        this.hook_close.Call()
                    }

                    this.hwnd := 0
                    this.openclosetime := A_TickCount
                    this.visible := false
                    this.minimized := false
                    this.pos := WinPos()
                }

            }

        }

    }

    ; Returns diagnostic info about this window as a string
    ; returns empty string for non-existing windows unless showall is set to true
    Print(showall := false) {

;        if showall || (this.hwnd && !this.parentwindow) {
        if showall || this.hwnd {
            output := "&nbsp;&nbsp;&nbsp;&nbsp;"

            output .= this.key " (" this.hwnd 
            if !this.parentwindow {
                ; this is a real window
                if this.hwnd {
                    output .= (this.visible ? "/visible" : "/hidden") . (this.minimized ? "/minimized) - " : ") - ")
                } else {
                    output .= ") - "
                }
            } else {
                ; this is a pseudowindow
                if this.hwnd {
                    output .= (this.validate.Call() ? "/yes" : "/no") . ") - "
                } else {
                    output .= ") - "
                }
            }

;            output .= this.fulltitle " (" this.pos.x ", " this.pos.y ", " this.pos.w ", " this.pos.h ") / (" this.savepos.x ", " this.savepos.y ", " this.savepos.w ", " this.savepos.h ")"
            ; output .= this.fulltitle " (" this.pos.x ", " this.pos.y ", " this.pos.w ", " this.pos.h ")"
            output .= " savepos=(" this.savepos.x ", " this.savepos.y ", " this.savepos.w ", " this.savepos.h ")"

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

    ; Closes the window (if closeflag is true), also clears 
    ; the hwnd and other properties and calls hook_close
    Close(closeflag := true) {
        if this.hwnd {
            if closeflag {
                try {
                    WinClose(this.hwnd)
                }
            }
            try {
                _HwndLookup.Delete(this.hwnd)
            }
            if PAActive && this.hook_close {
                this.hook_close.Call()
            }
            this.hwnd := 0
            this.openclosetime := A_TickCount
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
				if w >= WINPOS_MINWIDTH && h >= WINPOS_MINHEIGHT {
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
                if this._savepos.w >= WINPOS_MINWIDTH && this._savepos.h >= WINPOS_MINHEIGHT {
    				WinMove(this._savepos.x, this._savepos.y, this._savepos.w, this._savepos.h, this.hwnd)
                    return true
                }
			}
        }
        return false
    }

    ; Centers this window over the passed parent window (WinItem),
    ; window position (WinPos), or monitor (integer).
    ;
    ; If no parameter is passed, then centers within the monitor which the window is in.
    ;
    ; Returns true on success, false on failure.
    CenterWindow(parent := 0) {

        if IsObject(parent) {
            if parent.HasOwnProp("parentapp") {
                ; parent is a WinItem object
                try {
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

                    ; move child window to center of parentwindow
                    WinMove(nx, ny, , , this.hwnd)
                
                    return true
                }
            } else {
                ; parent is assumed to be a WinPos object
                try {
                    cw := 0
                    ; get child window position and dimensions
                    if this.hwnd {
                        WinGetPos( , , &cw, &ch, this.hwnd)
                    }
                    if cw = 0 {
                        return false
                    }
                    ; calculate new position
                    nx := parent.x + (parent.w - cw) / 2
                    ny := parent.y + (parent.h - ch) / 2

                    ; move child window to center of parentwindow
                    WinMove(nx, ny, , , this.hwnd)

                    return true
                }
            }
        } else {
            ; parent is assumed to be an integer specifying a monitor number
            ; if parent is zero, the get the monitor number that window is on
            if !parent {
                pos := this.pos
                parent := MonitorNumber(pos.x, pos.y)
            }
            if parent >= 1 && parent <= MonitorCount() {
                cw := 0
                ; get child window position and dimensions
                if this.hwnd {
                    WinGetPos( , , &cw, &ch, this.hwnd)
                }
                if cw = 0 {
                    return false
                }
                ; get position of monitor N (parent)
                monpos := MonitorPos(parent)

                ; calculate new position
                nx := monpos.x + (monpos.w - cw) / 2
                ny := monpos.y + (monpos.h - ch) / 2

                ; move child window to center of parentwindow
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
            if this._savepos.w >= WINPOS_MINWIDTH && this._savepos.h >= WINPOS_MINHEIGHT {
                appkey := this.parentapp.key
                winkey := this.key
                sectionname := A_ComputerName . "_WinPos"
                inifile := Setting["inifile"].value
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
            inifile := Setting["inifile"].value
    ; MsgBox(inifile "/" sectionname "/" appkey "/" winkey)
            if inifile {
                x := IniRead(inifile, sectionname, appkey . winkey . "_x", -1)
                y := IniRead(inifile, sectionname, appkey . winkey . "_y", -1)
                w := IniRead(inifile, sectionname, appkey . winkey . "_w", 0)
                h := IniRead(inifile, sectionname, appkey . winkey . "_h", 0)
                if w >= WINPOS_MINWIDTH && h >= WINPOS_MINHEIGHT {
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
;   pid         - (read only) process ID of this function, or 0 if not running
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

        ; store the search criteria for this window
        if searchtitle {
            this.criteria := searchtitle . " ahk_exe " . exename
        } else {
            this.criteria := "ahk_exe " . exename
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

    pid {
        get {
            if this.criteria {
                try {
                    ; look for a running process and return its pid
                    _pid := WinGetPID(this.criteria)
                    return _pid
                } catch {
                    ; did not find a running process
                    return 0
                }
            } else {
                ; no criteria, cannot look for a running process
                return 0
            }
        }
    }

    isrunning {
        get {
            return this.pid ? true : false
        }
    }

    ; If the app is running, updates all the windows in Win[] for the app
    ;
    Update() {
        if this.isrunning {
            for , win in this.Win {
                win.Update()
            }
        }
    }

    ; Returns diagnostic info about the window(s) for this app as a string
    ; omits non-existing windows or pseudowindows unless showall is set to true
    Print(winkey := "", showall := false) {

        if showall || this.pid {

            ; output .= this.key " (pid " this.pid ") - " this.appname " (= '" this.criteria "')<br />"

            output .= this.key " (pid " this.pid ") - " this.appname "<br />"
            
            if winkey {
                ; return info just for one window of this app
                output .= this.Win[winkey].Print(showall)
            } else {
                ;return info for all windows of this app
                for k, w in this.Win {
                    output .= w.Print(showall)
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

TTip("_cbAppShow(" hwnd ", " hook.MatchCriteria[1] ", " hook.MatchCriteria[2] ")")

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

TTip("_cbAppCreate(" hwnd ", " wintitle ", " wintext ")")
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

TTip("_cbAppClose(" hwnd ", " wintitle ", " wintext ")")
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


; Returns the monitor number that this window is on (upper left corner).
; Returns 0 on failure.
GetMonitor(hwnd) {
    try {
        win := _HwndLookup[hwnd]
        n := MonitorNumber(win.pos.x, win.pos.y)
    } catch {
        n := 0
    }
    return n
}


; Returns hwnd of window under mouse
WindowUnderMouse() {
    MouseGetPos( , , &hwnd)
    return hwnd
}


; Check whether the passed hwnd matches the passed context(s)
;
; Contexts are strings of a format similar to:
;	"EI"					- matches any EI window
;	"EI i1 i2"		        - matches either EI images1 or images2 windows
;	"EI d                   - matches EI desktop window
;	"EI list text"	        - matches EI desktop window if list page or text page (pseudowindow) is showing
;	"PS"					- matches any PS window
;	"PS report"				- matches PS report window
;	...
;
; Multiple context strings may be passed.
;
; Returns false if PAActive is not true
;
; Returns false if hwnd doesn't match any of the context strings, 
; if hwnd does not exist, or if context is empty ("").
;
; Returns true if hwnd matches one of the context strings.
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

    appkey := GetAppkey(hwnd)       ; the app key of the window being checked
TTip("Context: " appkey)
    if appkey {

        for context in contexts {

            carr := StrSplit(context, " ")
            cappkey := carr[1]		;get the context app key from the context string

TTip("Context: " appkey " <?> " cappkey)

            if cappkey == appkey {
                j := 2
                if j > carr.Length {
                    ; no windows to match with, so we've succeeded
                    return true
                }

                winkey := GetWinkey(hwnd)     ; the win key of the window being checked
TTip("Context: " appkey "/" winkey " <?> " cappkey)

                ; need to check for a match among the windows in the context
                while j <= carr.Length {
                    cwin := App[appkey].Win[carr[j]]    ; get the winitem of the context item
                    j++

                    if !cwin.parentwindow {
                        ; this is a true window
                        cwinkey := cwin.key   
TTip("Context: " appkey "/" winkey " <?> " cappkey "/" cwinkey)
                        if cwinkey == winkey {
                            ; found a window match
                            return true
                        }
                    } else {
                        ; this is a pseudowindow, get the parent window's winkey for comparing
                        cwinkey := cwin.parentwindow.key
TTip("Context: " appkey "/" winkey " <?> " cappkey "/" cwinkey)
                        if cwinkey == winkey {
                            ; found a parent window match
                            ; need to call the validate function for pseudowindow validation
                            fn := cwin.validate
                            if fn {
TTip("Context: " appkey "/" winkey " <?> " cappkey "/" cwinkey "/" fn.Call())
                                if fn.Call() {
                                    ; pseudowindow condition successfully validated
                                    ; return success
                                    return true
                                }
                            }
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

    for , a in App {
		a.Update()
	}

    _PAUpdate_Initial := false
}



; Returns diagnostic info about a window (or all windows) for an app (or all apps)
; as a string
;
; omits non-existing windows or pseudowindows unless showall is set to true
;
PrintWindows(appkey := "", winkey := "", showall := false) {
    global App

	output := ""

    if appkey {
        if winkey {
            ; return info just for one window of one app
            output .= App[appkey].Win[winkey].Print(showall)
        } else {
            ; return info for all windows of one app
            output .= App[appkey].Print( , showall)
        }
    } else {
        ; return info for all apps, all windows
        for k, a in App {
            output .= a.Print( , showall)
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


; Helper function to other Monitor functions
_MonitorGetInfo() {
    global _MonitorCount
    global _MonitorCoords

    ; if first time, get and cache info about the montors
    if !_MonitorCount {
        _MonitorCount := MonitorGetCount()
        n := 1
        while n <= _MonitorCount {
            MonitorGetWorkArea(n, &left, &top, &right, &bottom)
            _MonitorCoords.Push({l: left, t: top, r: right, b: bottom})
            n++
        }
    }
}


; Returns the system monitor count
MonitorCount() {
    if !_MonitorCount {
        _MonitorGetInfo()
    }
    return _MonitorCount
}


; Returns the monitor number that contains the passed x, y coordinates.
;
; Returns 0 if coordinates are not on any monitor.
;
MonitorNumber(x, y) {
    if !_MonitorCount {
        _MonitorGetInfo()
    }

    ; determine which monitor the passed x, y coordinates falls on
    monitorN := 0
    for mon in _MonitorCoords {
        if x >= mon.l && x < mon.r && y >= mon.t && y < mon.b {
            monitorN := A_Index
            break               ; for
        }
    }

    return monitorN
}


; For monitor N, returns a WinPos reflecting the monitor's position and size (x,y,w,h).
;
; Returns 0 if an invalid monitor number is passed.
;
MonitorPos(N) {
    if !_MonitorCount {
        _MonitorGetInfo()
    }

    if N < 1 || N > _MonitorCount {
        return 0
    }

    mon := _MonitorCoords[N]
    return WinPos(mon.l, mon.t, (mon.r - mon.l), (mon.b - mon.t))
}


; Returns a WinPos (x, y, w, h) reflecting the coordinates and size of the
; virtual screen, which is the bounding rectangle of all display monitors.
;
; SM_XVIRTUALSCREEN := 76   - Coordinates for the left side and the top of the virtual screen.
; SM_YVIRTUALSCREEN := 77
; SM_CXVIRTUALSCREEN := 78  - Width and height of the virtual screen, in pixels.
; SM_CYVIRTUALSCREEN := 79
;
VirtualScreenPos() {
    return WinPos(SysGet(76), SysGet(77), SysGet(78), SysGet(79))
}
