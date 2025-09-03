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
App["PA"] := AppItem("PA", "AutoHotkey64.exe", "PACS Assistant", "main")
App["VPN"] := AppItem("VPN", "csc_ui.exe", "Cisco Secure Client", "main")
App["EILOGIN"] := AppItem("EILOGIN", "javaw.exe", "Agfa HealthCare Enterprise Imaging", "login")
App["EI"] := AppItem("EI", "javaw.exe", "Agfa HealthCare Enterprise Imaging", "d")
App["EICLIN"] := AppItem("EICLIN", "javawClinapps.exe", "IMPAX Volume", "mpr")
App["PS"] := AppItem("PS", "Nuance.PowerScribe360.exe", "PowerScribe", "main")
App["PSSP"] := AppItem("PSSP", "natspeak.exe", "PowerScribe 360 Spelling Window", "spelling")
App["EPIC"] := AppItem("EPIC", "Hyperdrive.exe", "Hyperspace – Production (PRD)", "main")
App["DCAD"] := AppItem("DCAD", "StudyManager.exe", "DynaCAD", "main")
App["DSTUDY"] := AppItem("DSTUDY", "MRW.exe", "DynaCAD Study", "main")
App["DLUNG"] := AppItem("DLUNG", "MeVisLabApp.exe", "DynaCAD Lung", "main")


; Add known windows of interest belonging to each app.

; PACS Assistant
App["PA"].Win["main"] := WinItem("main", App["PA"], , "PACS Assistant", "Chrome Legacy Window", PAShow_main)

; Cisco VPN
App["VPN"].Win["main"] := WinItem("main", App["VPN"], , "Cisco Secure Client", "Preferences", VPNShow_main, VPNClose_main)
App["VPN"].Win["prefs"] := WinItem("prefs", App["VPN"], , "Cisco Secure Client", "Export Stats", VPNShow_prefs, VPNClose_prefs)
App["VPN"].Win["login"] := WinItem("login", App["VPN"], , "Cisco Secure Client |", "Username", VPNShow_login, VPNClose_login)
App["VPN"].Win["otp"] := WinItem("otp", App["VPN"], , "Cisco Secure Client |", "Answer", VPNShow_otp, VPNClose_otp)
App["VPN"].Win["connected"] := WinItem("connected", App["VPN"], , "Cisco Secure Client", "Security policies", VPNShow_connected, VPNClose_connected)

; Agfa EI Login window
App["EILOGIN"].Win["login"] := WinItem("login", App["EI"], , "Agfa HealthCare Enterprise Imaging", , EILOGINShow_login, EILOGINClose_login)

; Agfa EI diagnostic desktop
App["EI"].Win["d"] := WinItem("d", App["EI"], , "Diagnostic Desktop - 8", , EIShow_d, EIClose_d)
App["EI"].Win["i1"] := WinItem("i1", App["EI"], , "Diagnostic Desktop - Images (1", , EIShow_i1, EIClose_i1)
App["EI"].Win["i2"] := WinItem("i2", App["EI"], , "Diagnostic Desktop - Images (2", , EIShow_i2, EIClose_i2)
App["EI"].Win["4dm"] := WinItem("4dm", App["EI"], , "4DM", "Corridor4DM.exe", EIShow_4dm)
App["EI"].Win["chat"] := WinItem("chat", App["EI"], , "Chat", , EIShow_chat)
; Agfa EI pseudowindows
App["EI"].Win["list"] := WinItem("list", App["EI"], App["EI"].Win["d"], , , , , EIIsList)
App["EI"].Win["text"] := WinItem("text", App["EI"], App["EI"].Win["d"], , , , , EIIsText)
App["EI"].Win["search"] := WinItem("search", App["EI"], App["EI"].Win["d"], , , , ,EIIsSearch)
App["EI"].Win["image"] := WinItem("image", App["EI"], App["EI"].Win["d"], , , , , EIIsImage)

; Agfa ClinApps (e.g. MPR)
App["EICLIN"].Win["mpr"] := WinItem("mpr", App["EICLIN"], , "IMPAX Volume", , EICLINShow_mpr)

; PowerScribe
App["PS"].Win["main"] := WinItem("main", App["PS"], , "PowerScribe", , PSShow_main)
App["PS"].Win["logout"] := WinItem("logout", App["PS"], , "PowerScribe", "Are you sure you wish to log off the application?", PSShow_logout)
App["PS"].Win["savespeech"] := WinItem("savespeech", App["PS"], , "PowerScribe", "Your speech files have changed. Do you wish to save the changes?", PSShow_savespeech)
App["PS"].Win["savereport"] := WinItem("savereport", App["PS"], , "PowerScribe", "Do you want to save the changes to the", PSShow_savereport)
App["PS"].Win["deletereport"] := WinItem("deletereport", App["PS"], , "PowerScribe", "Are you sure you want to delete", PSShow_deletereport)
App["PS"].Win["unfilled"] := WinItem("unfilled", App["PS"], , "PowerScribe", "This report has unfilled fields. Are you sure you wish to sign it?", PSShow_unfilled)
App["PS"].Win["confirmaddendum"] := WinItem("confirmaddendum", App["PS"], , "PowerScribe", "Do you want to create an addendum", PSShow_confirmaddendum)
App["PS"].Win["confirmanother"] := WinItem("confirmanother", App["PS"], , "PowerScribe", "Do you want to create another addendum", PSShow_confirmanother)
App["PS"].Win["existing"] := WinItem("existing", App["PS"], , "PowerScribe", "is associated with an existing report", PSShow_existing)
App["PS"].Win["continue"] := WinItem("continue", App["PS"], , "PowerScribe", "Do you wish to continue editing", PSShow_continue)
App["PS"].Win["ownership"] := WinItem("ownership", App["PS"], , "PowerScribe", "Are you sure you want to acquire ownership", PSShow_ownership)
App["PS"].Win["microphone"] := WinItem("microphone", App["PS"], , "PowerScribe", "Your microphone is disconnected", PSShow_microphone)
App["PS"].Win["find"] := WinItem("find", App["PS"], , "Find and", , PSShow_find)
; PowerScribe pseudowindows
App["PS"].Win["login"] := WinItem("login", App["PS"], App["PS"].Win["main"], "PowerScribe", "Disable speech", PSOpen_PSlogin, PSClose_PSlogin, PSIsLogin)
App["PS"].Win["home"] := WinItem("home", App["PS"], App["PS"].Win["main"], "PowerScribe", "Signing queue", PSOpen_PShome, PSClose_PShome, PSIsHome)
App["PS"].Win["report"] := WinItem("report", App["PS"], App["PS"].Win["main"], "PowerScribe", "Report -", PSOpen_PSreport, PSClose_PSreport, PSIsReport)
App["PS"].Win["addendum"] := WinItem("addendum", App["PS"], App["PS"].Win["main"], "PowerScribe", "Addendum -", PSOpen_PSreport, PSClose_PSreport, PSIsAddendum)

; PowerScribe spelling window
App["PSSP"].Win["spelling"] := WinItem("spelling", App["PSSP"], , "Spelling", , PSSPShow_spelling)

; for Epic
App["EPIC"].Win["main"] := WinItem("main", App["EPIC"], , "Production", , EPICShow_main)
App["EPIC"].Win["chat"] := WinItem("chat", App["EPIC"], , "Secure Chat", , EPICShow_chat)
; pseudowindows, parent is main window App["EI"].Win["main"]
App["EPIC"].Win["login"] := WinItem("login", App["EPIC"], App["EPIC"].Win["main"], , , , , )
App["EPIC"].Win["timezone"] := WinItem("timezone", App["EPIC"], App["EPIC"].Win["main"], , , , , )
App["EPIC"].Win["chart"] := WinItem("chart", App["EPIC"], App["EPIC"].Win["main"], , , , , )



; PAWindows["DCAD"]["login"] := WindowItem("DCAD", "login", "Login", "Login", , "StudyManager.exe")
; PAWindows["DCAD"]["main"] := WindowItem("DCAD", "main", "Philips DynaCAD", "Philips DynaCAD", , "StudyManager.exe")
; PAWindows["DCAD"]["study"] := WindowItem("DCAD", "study", , , , "MRW.exe")

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


; AppItem class
;
; Properties:
;
;   key         - string, app identifier, e.g. "VPN", "EI", "PS", "EPIC", ...
;
;	exename		- string, executable name, used for matching, e.g. "Nuance.PowerScribe360.exe"
;   appname     - string, full name of app, e.g. "PowerScribe 360"
;
;   mainwin     - string, window identifier of the top window of this app
;               -   e.g. "main", or "d"
;               - the top window's search criteria (e.g. criteria & wintext from its WinItem)
;               -   defines whether this app is running
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

    __New(key, exename, appname, mainwin) {

        if !exename {
            return 0    ; cannot create an AppItem without an exename
        }

        this.key := key
        this.exename := exename
        this.appname := appname
        this.mainwin := mainwin

        this.Win := Map()

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
            try {
                return this.Win[this.mainwin].pid
            } catch {
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

            ; output .= this.key " (pid " this.pid ") - " this.appname "<br />"
            output .= this.key " (pid " this.pid ")<br />"
            
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
;   key         - string, window identifier, e.g. "d", "i1", "i2", "main", "login", etc.
;   parentapp   - AppItem, parent app to which this window belongs
;   parentwindow - WinItem, parent window if this is a pseudowindow, zero if this is a true window
;
;	searchtitle	- string, short title of window, used for matching
;	wintext		- string, window text to match, used for matching
;
;	hook_show	- function to be called when this window is opened
;               - does not apply to pseudowindows
;
; hook_close	- function to be called when this window is closed
;               - does not apply to pseudowindows
;
;   validate    - function to be called to determine whether this pseudowindow is present
;
;	criteria	- string, combined search string generated from exename of parent app and searchtitle of this window. It is used along with wintext to find windows.
;               - for pseudowindows, criteria is empty string
;
;   hwnd        - handle to window, or 0 if the window doesn't exist
;               - For pseudowindows, returns hwnd of its parentwindow.
;
;   pos         - current WinPos of the window
;
;   savepos     - saved WinPos of the window
;
; [read-only properties]
;   pid         - Process id of the window. Returns 0 if not found. 
;               -   For pseudowindows, returns pid of its parentwindow.
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;   appkey      - Returns the key of the parent app (parentapp), e.g. "EI".
;
;;;	openclosetime	- tickcount when window was last opened or closed (from A_TickCount)
;
; WinItem class (static) methods:
; 
;   static LookupHwnd(hwnd)    - Returns the WinItem corresponding to the passed hwnd. Uses the reverse lookup table _HwndReverseLookup[].
;
; WinItem instance methods:
;
;;;   Exists()    - Searches for the window using criteria and wintext (using ahk WinExist()) and returns the hwnd, or 0 if doesn't exist
;               - [todo] If pseudowindow, determines whether pseudowindow exists, returns hwnd of parent window, or 0 if it doesn't exist
;
;   IsReady()   - Returns hwnd if a window exists (non-zero hwnd), is visible, and is not minimized. Otherwise returns 0.
;               - [todo] If pseudowindow
;
;   Update()    - Updates the hwnd and pid for this window
;
;   Print()     - Returns diagnostic info about this window as a string
;
;   Close()     - Closes the window, via call to WinClose()
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
;
; To instantiate a new WinItem, use:
;
;   WinItem(key, parentapp, [parentwindow, searchtitle, wintext, hook_show, hook_close, validate])
;
; 
;
;
class WinItem {
    static _HwndReverseLookup := Map()             ; class variable, stores a map of hwnd to WinItems

    __New(key, parentapp, parentwindow := 0, searchtitle := "", wintext := "", hook_show := 0, hook_close := 0, validate := 0) {
        
        this.key := key
        this.parentapp := parentapp
        this.parentwindow := parentwindow
        this.searchtitle := searchtitle
        this.wintext := wintext

        this.hook_show := hook_show
        this.hook_close := hook_close
        this.validate :=  validate
        
        this._hwnd := 0
        this._pos := WinPos()
        this._savepos := WinPos()

        ; set criteria and hwnd
        if !parentwindow {
            ; this is a real window, not a pseudowindow

            ; set the search criteria for this window
            if parentapp && parentapp.exename {
                if searchtitle {
                    this.criteria := searchtitle . " ahk_exe " . parentapp.exename
                } else {
                    this.criteria := "ahk_exe " . parentapp.exename
                }    
            } else {
                ; must have a parent app with exename to have valid search criteria, so set to empty
                this.criteria := ""
            }    
            
            ; Look to see if the window already exists. If so, set the hwnd.
            if this.criteria {
                ; DetectHiddenText should be false (globally set), we do not want to search hidden text when looking for windows
                try {
                    this.hwnd := WinExist(this.criteria, this.wintext)
                } catch {
                    this.hwnd := 0
                }    
            } else {
                ; no criteria
                this.hwnd := 0
            }    
            
        } else {
            ; this is a pseudowindow
            this.criteria := ""
            this.hwnd := 0

        }   

    }    
    
    pid {
        get {
            if !this.parentwindow {
                ; this is a real window, not a pseudowindow
                if this.criteria {
                    try {
                        ; look for this window's process and return its pid
                        _pid := WinGetPID(this.criteria)
                    } catch {
                        ; did not find a running process
                        _pid := 0
                    }
                } else {
                    ; no criteria, cannot look for a running process
                    _pid := 0
                }
            } else {
                ; this is a pseudowindow
                _pid := this.parentwindow.pid
            }

            if !_pid {
                ; also set hwnd to 0
                this.hwnd := 0
            }
            return _pid
        }
    }

    hwnd {
        get {
            if !this.parentwindow {
                ; this is a real window, not a pseudowindow
                
                if gethwnd := WinExist(this._hwnd) {
                    ; this window exists, don't need to do more
                } else {
                    if this.criteria {
                        ; DetectHiddenText should be false (globally set), we do not want to search hidden text when looking for windows
                        try {
                            gethwnd :=  WinExist(this.criteria, this.wintext)
                        } catch {
                            gethwnd :=  0
                        }
                    } else {
                        ; no criteria, return 0
                        gethwnd :=  0
                    }
                    this.hwnd := gethwnd
                }    

            } else {
                ; this is a pseudowindow, get and return its parentwindow's hwnd
                this._hwnd := this.parentwindow.hwnd
            }

            return this._hwnd
        }
        set {
            if !this.parentwindow {
                ; this is a real window, not a pseudowindow
                if this._hwnd = Value {
                    ; this._hwnd and Value are the same, so don't do anything, just return
                    return
                }
                ; this._hwnd and Value are different
                if this._hwnd {
                    ; if this._hwnd exists, try to delete its reverse lookup entry
                    try {
                        WinItem._HwndReverseLookup.Delete(this._hwnd)
                    }    
                }
                this._hwnd := Value
                if Value {
                    ; non-zero new hwnd, so record it in the reverse lookup table
                    WinItem._HwndReverseLookup[Value] := this
                }
            } else {
                ; this is a pseudowindow
                ; don't do anything
            }
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

    visible {
        get {
            if !this.parentwindow {
                ; this is a real window
                try {
                    return (WinGetStyle(this.hwnd) & WS_VISIBLE) ? true : false
                } catch {
                    return false
                }
            } else {
                ; this is a pseudowindow, return the parent window's visibility
                return this.parentwindow.visible
            }
        }    
    }    

    minimized {
        get {
            if !this.parentwindow {
                ; this is a real window
                try {
                    ; WinGetMinMax() return values:
                    ;   -1: The window is minimized
                    ;   1: The window is maximized
                    ;   0: The window is neither minimized nor maximized
                    return WinGetMinMax(this.hwnd) = -1 ? true : false
                } catch {
                    return false
                }
            } else {
                ; this is a pseudowindow, return the parent window's minimized status
                return this.parentwindow.minimized
            }
        }    
    }    
    
    appkey {
        get {
            if !this.parentwindow {
                ; this is a real window
                if this.parentapp {
                    return this.parentapp.key
                } else {
                    return ""
                } 
            } else {
                ; this is a pseudowindow, return the parent window's appkey
                return this.parentwindow.appkey
            }
        }
    }

    ; Returns the WinItem corresponding to the passed hwnd. 
    ; Uses the reverse lookup table _HwndReverseLookup[].
    ; If no match, return 0.
    static LookupHwnd(hwnd) {
        if hwnd && WinItem._HwndReverseLookup.Has(hwnd) {
            return WinItem._HwndReverseLookup[hwnd]
        }
        return 0
    }

    ; Searches for the window using criteria and wintext (using ahk WinExist()) and returns the hwnd, or 0 if doesn't exist. Also updates the object's hwnd property if necessary.
    ; If pseudowindow, determines whether pseudowindow exists, returns hwnd of parent window, or 0 if it doesn't exist.
    ; [deprecated]
    Exists() {
        
        if !this.parentwindow {
            ; this is a real window, not a pseudowindow

            if rethwnd := WinExist(this.hwnd) {
                ; this window exists, don't need to do more
                ; rethwnd has the hwnd
            } else {
                if this.criteria {
                    ; DetectHiddenText should be false (globally set), we do not want to search hidden text when looking for windows
                    try {
                        rethwnd :=  WinExist(this.criteria, this.wintext)
                    } catch {
                        rethwnd :=  0
                    }
                } else {
                    ; no criteria, return 0
                    rethwnd :=  0
                }    
            }    
        } else {
            ; this is a pseudowindow
            
            ; [todo]
            rethwnd :=  0
        }

        this.hwnd := rethwnd
        return rethwnd
    }

    ; Returns the hwnd of this window if it exists (non-zero hwnd) and is visible and not minimized.
    ; If a pseudowindow, and it is showing, returns the hwnd of its parent window
    ; Returns 0 otherwise.
    IsReady() {
        if !this.parentwindow {
            ; this is a real window, not a pseudowindow
            gethwnd := this.hwnd
            return (gethwnd && this.visible && !this.minimized) ? gethwnd : 0
        } else {
            ; this is a pseudowindow, call its validation function to determine whether it is showing
            if this.validate {
                ; try to validate the pseudowindow and return the hwnd of its parent
                return this.validate.Call()
            }
        }
        return 0
    }

    ; Updates ? for this window
    Update() {
ttip("Update()")
        ; do nothing

    }

    ; Returns diagnostic info about this window as a string
    ; returns empty string for non-existing windows unless showall is set to true
    Print(showall := false) {

        gethwnd := this.hwnd
        if showall || gethwnd {
            output := "&nbsp;&nbsp;&nbsp;&nbsp;"

            output .= this.parentwindow ? "  > " : ""

            output .= this.key " (" this.pid "|" gethwnd

            if !this.parentwindow {
                ; this is a real window
                if gethwnd {
                    output .= (this.visible ? "" : "h") . (this.minimized ? "m" : "")
                }
                output .= ")"

                ; output .= "[" WinItem.LookupHwnd(this.hwnd).appkey "/" WinItem.LookupHwnd(this.hwnd).key "]"

                output .= " - "
                
            } else {
                ; this is a pseudowindow
                if gethwnd && this.validate {
                    output .= (this.validate.Call() ? "/yes" : "/no") . ") - "
                } else {
                    output .= ") - "
                }
            }

            ; output .= " savepos=(" this.savepos.x ", " this.savepos.y ", " this.savepos.w ", " this.savepos.h ")"

            ; output .= "("
            ; if this.criteria {
            ;     output .= " crit=''" this.criteria "'"  
            ; }
            ; if this.wintext {
            ;      output .= " wintext='" this.wintext "'"
            ; }
            ; output .= ")"

            output .= "<br />"

        } else {

            output := ""

        }

        return output
    }

    ; Closes the window if it exists, using WinClose
    ; For pseudowindows, does nothing
    Close() {
        if !this.parentwindow {
            ; this is a real window
            if this.hwnd {
                try {
                    WinClose(this.hwnd)
                }
                this.hwnd := 0
            }
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
; Returns 0 on failure.
GetWinItem(hwnd) {
    
    try {
        win := WinItem.LookupHwnd(hwnd)
    } catch {
        win := 0
    }

    return win
}

; Returns the application key of the specified window handle
; Returns "" on failure.
GetAppkey(hwnd) {
    
    try {
        if win := WinItem.LookupHwnd(hwnd) {
            if win.parentapp {
                return win.parentapp.key
            } else {
                return ""
            }
        } else {
            return ""
        }
    } catch {
        return ""
    }
}


; Returns the window key of the specified window handle.
; Returns "" on failure.
GetWinkey(hwnd) {
    
    try {
        if win := WinItem.LookupHwnd(hwnd) {
            return win.key
        } else {
            return ""
        }
    } catch {
        return ""
    }
}


; Returns the monitor number that this window is on (upper left corner).
; Returns 0 on failure.
GetMonitor(hwnd) {
    try {
        if win := WinItem.LookupHwnd(hwnd) {
            n := MonitorNumber(win.pos.x, win.pos.y)
        }
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


; Check for a matching context
;
; hwnd is the (real) window
; contexts is an array of case sensitive context strings
;
; Context strings are of the format "APPKEY winkey1 winkey2 ..." where winkeyN are optional
;
; Some example valid context strings are:
;	"EI"					- matches any EI window
;	"EI i1 i2"		        - matches either EI images1 or images2 windows
;	"EI d                   - matches EI desktop window
;	"EI list text"	        - matches EI desktop window if list page or text page (pseudowindow) is showing
;	"PS"					- matches any PS window
;	"PS report"				- matches PS report window
;	...
;
; Example usage:
;   if Context(WindowUnderMouse(), "PS", "EI i1 i2 text list 4dm", "PA") { <do something> ... }
;
; Returns false if PAActive is false
;
; Returns true if hwnd matches one of the context strings.
;
; Returns false if hwnd doesn't match any of the context strings,  if hwnd does not exist, or if contexts[] is entirely empty ("").
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
    if appkey {
        
        winkey := GetWinkey(hwnd)     ; the win key of the window being checked
TTip("Context(" appkey "/" winkey ")")

        for context in contexts {

            carr := StrSplit(context, " ")
            cappkey := carr[1]		;get the context app key from the context string
            
            if cappkey == appkey {
                j := 2
                if j > carr.Length {
                    ; no windows to match with, so we've succeeded
TTip("Context(" appkey "/" winkey ") == " cappkey)                    
                    return true
                }    

                ; need to check for a match among the windows in the context
                while j <= carr.Length {
                    cwin := App[appkey].Win[carr[j]]    ; get the winitem of the context item
                    j++

                    if !cwin.parentwindow {
                        ; this is a true window
                        cwinkey := cwin.key   
                        if cwinkey == winkey {
                            ; found a window match
TTip("Context(" appkey "/" winkey ") == " cappkey "/" cwinkey)
                            return true
                        }
                    } else {
                        ; this is a pseudowindow, get the parent window's winkey for comparing
                        cwinkey := cwin.parentwindow.key
                        if cwinkey == winkey {
                            ; found a parent window match
                            ; need to call the validate function for pseudowindow validation
                            fn := cwin.validate
                            if fn {
                                if fn.Call() {
                                    ; pseudowindow condition successfully validated
                                    ; return success
TTip("Context(" appkey "/" winkey ") == " cappkey "/" cwinkey "/" fn.Call())
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
            output .= App[appkey].Print(winkey, showall)
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
