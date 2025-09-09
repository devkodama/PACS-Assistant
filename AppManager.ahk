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


; Define apps
App["PA"] := AppItem("PA", A_AhkExe, "PACS Assistant", "main")
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


; Windows of interest belonging to each app.

; PACS Assistant
App["PA"].Win["main"] := WinItem("main", App["PA"], , "PACS Assistant", , , PAShow_main)

; Cisco VPN
App["VPN"].Win["main"] := WinItem("main", App["VPN"], , "Cisco Secure Client", "Preferences", , VPNShow_main)
App["VPN"].Win["prefs"] := WinItem("prefs", App["VPN"], , "Cisco Secure Client", "Export Stats", , VPNShow_prefs)
App["VPN"].Win["login"] := WinItem("login", App["VPN"], , "Cisco Secure Client |", "Username", , VPNShow_login)
App["VPN"].Win["otp"] := WinItem("otp", App["VPN"], , "Cisco Secure Client |", "Answer", , VPNShow_otp)
App["VPN"].Win["connected"] := WinItem("connected", App["VPN"], , "Cisco Secure Client", "Security policies", , VPNShow_connected)

; Agfa EI Login window
App["EILOGIN"].Win["login"] := WinItem("login", App["EI"], , "Agfa HealthCare Enterprise Imaging", , , EILOGINShow_login)

; Agfa EI diagnostic desktop
App["EI"].Win["d"] := WinItem("d", App["EI"], , "Diagnostic Desktop - 8", , true, )
App["EI"].Win["i1"] := WinItem("i1", App["EI"], , "Diagnostic Desktop - Images (1", , , EIShow_i1)
App["EI"].Win["i2"] := WinItem("i2", App["EI"], , "Diagnostic Desktop - Images (2", , , EIShow_i2)
App["EI"].Win["4dm"] := WinItem("4dm", App["EI"], , "4DM", "Corridor4DM.exe", , EIShow_4dm)
App["EI"].Win["chat"] := WinItem("chat", App["EI"], , "Chat", , , EIShow_chat)
; Agfa EI pseudowindows
App["EI"].Win["list"] := WinItem("list", App["EI"], App["EI"].Win["d"], , , , , , EIIsList)
App["EI"].Win["text"] := WinItem("text", App["EI"], App["EI"].Win["d"], , , , , , EIIsText)
App["EI"].Win["search"] := WinItem("search", App["EI"], App["EI"].Win["d"], , , , , ,EIIsSearch)
App["EI"].Win["image"] := WinItem("image", App["EI"], App["EI"].Win["d"], , , , , , EIIsImage)

; Agfa ClinApps (e.g. MPR)
; Window titles may be one of:
;   IMPAX Volume Viewing 3D + MPR Viewing
;   IMPAX Volume Viewing Reformatting
;   IMPAX Volume Viewing Basic CPR
;   IMPAX Volume Viewing Vessel Viewing
;   IMPAX Volume Viewing Basic MPR viewing
;   IMPAX Volume Viewing Reformatting
;   IMPAX Volume Viewing Basic CPR
App["EICLIN"].Win["main"] := WinItem("main", App["EICLIN"], , "IMPAX Volume Viewing", , , EICLINShow_main)
; Agfa EI pseudowindows
App["EICLIN"].Win["mpr"] := WinItem("mpr", App["EICLIN"], App["EICLIN"].Win["main"], "MPR", , true, EICLINShow_mpr, , EICLINIsMpr)
App["EICLIN"].Win["reformat"] := WinItem("reformat", App["EICLIN"], App["EICLIN"].Win["main"], "Reformatting", , true, EICLINShow_reformat, , EICLINIsReformat)
App["EICLIN"].Win["cpr"] := WinItem("cpr", App["EICLIN"], App["EICLIN"].Win["main"], "Basic CPR", , true, EICLINShow_cpr, , EICLINIsCpr)
App["EICLIN"].Win["vessel"] := WinItem("vessel", App["EICLIN"], App["EICLIN"].Win["main"], "Vessel Viewing", , true, EICLINShow_vessel, , EICLINIsVessel)

; PowerScribe
App["PS"].Win["main"] := WinItem("main", App["PS"], , "PowerScribe", "ProgressBar", , PSShow_main)
App["PS"].Win["recognition"] := WinItem("recognition", App["PS"], , "PowerScribe", "*Finishing recognition", , PSShow_recognition)
App["PS"].Win["logout"] := WinItem("logout", App["PS"], , "PowerScribe", "Are you sure you wish to log off the application?", , PSShow_logout)
App["PS"].Win["savespeech"] := WinItem("savespeech", App["PS"], , "PowerScribe", "Your speech files have changed. Do you wish to save the changes?", , PSShow_savespeech)
App["PS"].Win["savereport"] := WinItem("savereport", App["PS"], , "PowerScribe", "Do you want to save the changes to the", , PSShow_savereport)
App["PS"].Win["deletereport"] := WinItem("deletereport", App["PS"], , "PowerScribe", "Are you sure you want to delete", , PSShow_deletereport)
App["PS"].Win["saveautotext"] := WinItem("saveautotext", App["PS"], , "PowerScribe", "Do you want to save the currently open AutoText entry", , PSShow_saveautotext)
App["PS"].Win["unfilled"] := WinItem("unfilled", App["PS"], , "PowerScribe", "This report has unfilled fields. Are you sure you wish to sign it?", , PSShow_unfilled)
App["PS"].Win["confirmaddendum"] := WinItem("confirmaddendum", App["PS"], , "PowerScribe", "Do you want to create an addendum", , PSShow_confirmaddendum)
App["PS"].Win["confirmanother"] := WinItem("confirmanother", App["PS"], , "PowerScribe", "Do you want to create another addendum", , PSShow_confirmanother)
App["PS"].Win["existing"] := WinItem("existing", App["PS"], , "PowerScribe", "is associated with an existing report", , PSShow_existing)
App["PS"].Win["continue"] := WinItem("continue", App["PS"], , "PowerScribe", "Do you wish to continue editing", , PSShow_continue)
App["PS"].Win["ownership"] := WinItem("ownership", App["PS"], , "PowerScribe", "Are you sure you want to acquire ownership", , PSShow_ownership)
App["PS"].Win["microphone"] := WinItem("microphone", App["PS"], , "PowerScribe", "Your microphone is disconnected", , PSShow_microphone)
App["PS"].Win["ras"] := WinItem("ras", App["PS"], , "PowerScribe", "The call to RAS timed out", , PSShow_ras)
App["PS"].Win["find"] := WinItem("find", App["PS"], , "Find and", , , PSShow_find)
; PowerScribe pseudowindows
App["PS"].Win["login"] := WinItem("login", App["PS"], App["PS"].Win["main"], , "Disable speech", true, PSShow_login, PSClose_login, PSIsLogin)
App["PS"].Win["home"] := WinItem("home", App["PS"], App["PS"].Win["main"], , "Signing queue", true, PSShow_home, PSClose_home, PSIsHome)
App["PS"].Win["report"] := WinItem("report", App["PS"], App["PS"].Win["main"], , "Report -", true, PSShow_report, PSClose_report, PSIsReport)
App["PS"].Win["addendum"] := WinItem("addendum", App["PS"], App["PS"].Win["main"], , "Addendum -", true, PSShow_addendum, PSClose_addendum, PSIsAddendum)

; PowerScribe spelling window
App["PSSP"].Win["spelling"] := WinItem("spelling", App["PSSP"], , "Spelling", , , PSSPShow_spelling)

; for Epic
App["EPIC"].Win["main"] := WinItem("main", App["EPIC"], , "Production", , , EPICShow_main)
App["EPIC"].Win["chat"] := WinItem("chat", App["EPIC"], , "Secure Chat", , , EPICShow_chat)
; pseudowindows, parent is main window App["EI"].Win["main"]
App["EPIC"].Win["login"] := WinItem("login", App["EPIC"], App["EPIC"].Win["main"], , , , , , )
App["EPIC"].Win["timezone"] := WinItem("timezone", App["EPIC"], App["EPIC"].Win["main"], , , , , , )
App["EPIC"].Win["chart"] := WinItem("chart", App["EPIC"], App["EPIC"].Win["main"], , , , , , )



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
;               -   determines whether this app is running
;
;
;   Win[]       - Map, all the WinItems[] associated with this app
;
; read-only properties:
;
;   pid         - process ID of this app, or 0 if not running
;   isrunning   - true if app is running (i.e. has a pid), false if not
;
; AppItem methods:
;
;   Close()     - Terminates the process, via call to ProcessClose()
;
;   Print()     - Returns diagnostic info about the window(s) for this app as a string
;
;;;   CountOpenWindows()   - Returns the number of open (and visible?) windows that belong to this app
;
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
;       AppItem(key, exename, appname, mainwin)
;
; 
class AppItem {

    __New(key, exename, appname, mainwin) {

        this.key := key
        this.exename := exename
        this.appname := appname
        this.mainwin := mainwin

        this.Win := Map()
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

    ;
    Close() {
        if this.pid {
            try {
                ProcessClose(this.pid)
            } catch {
            }
        }
    }

    ; Returns diagnostic info about the window(s) for this app as a string
    ; omits non-existing windows or pseudowindows unless showall is set to true
    Print(winkey := "", showall := false) {

        if showall || this.pid {
            output := this.key " (pid " this.pid ")<br />"
            
            if winkey {
                ; return info just for one window of this app
                output .= this.Win[winkey].Print(showall)
            } else {
                ;return info for all windows of this app
                for , w in this.Win {
                    ; skip pseudowindows, which are printed by their parent window
                    if !w.parentwindow {
                        output .= w.Print(showall)
                    }
                }
            }
        } else {
            output := ""
        }

        return output
    }

    ; For all windows of this app, saves the current x, y, width, and height
    ; of each in its savepos proprety.
    SavePositions() {
        for , w in this.Win {
            w.SavePosition()
        }
    }

    ; For all windows of this app, restores window to the size and position
    ; in its savepos property.
    RestorePositions() {
        for , w in this.Win {
            w.RestorePosition()
        }
    }
    
	; For all windows of this app, write window's savepos to 
    ; user specific settings.ini file.
    WritePositions() {
        for , w in this.Win {
            w.WritePosition()
        }
    }

    ; For all windows of this app, reads window's savepos from
    ; user specific settings.ini file.
    ReadPositions() {
        for , w in this.Win {
            w.ReadPosition()
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
;	searchtitle	- string, short title of window for matching, used in criteria
;	wintext		- string, window text to match, used for matching
;
;   pollflag    - boolean, If false then a Windows event triggers hook_show (via WinEvent.Show).
;               -   If true then polling (by _WatchWindows()) is used to trigger hook_show.
;               - Polling is always used to trigger hook_close.
;	hook_show	- function, to be called when this window is opened.
;   hook_close	- function, to be called when this window is closed.
;   validate    - function, For pseudowindows, function to be called to determine 
;               -   whether this pseudowindow is showing on screen.
;
;	criteria	- string, combined search string generated from exename of parent app,
;               -   searchtitle of this window, and ahk_class of this window.
;               -   It is used along with wintext to find windows.
;               - For pseudowindows, criteria is an empty string.
;
;   hwnd        - handle to window, or 0 if the window doesn't exist
;               - For pseudowindows, returns hwnd of its parentwindow.
;               - When set, it maintains a reverse lookup table used to retrieve
;               -   a WinItem from a hwnd (by calling WinItem.LookupHwnd() -- see below). 
;
;   savepos     - WinPos, remembered position of the window
;
;   PWin[]      - array, An array of child pseudowindows.
;
; read-only properties:
;
;   pos         - WinPos, current position of the window
;   pid         - Process id of the window. Returns 0 if not found. 
;               -   For pseudowindows, returns pid of its parentwindow.
;	visible		- boolean, true if window state is visible (i.e. has WF_VISIBLE style)
;	minimized	- boolean, true if window state is minimized
;   appkey      - Returns the key of the parent app (parentapp), e.g. "EI".
;   haschild    - boolean, true if this window has children (i.e. PWin[] is not empty)
;
; internal variables:
;
;   _HwndReverseLookup[]    - Map(), Reverse lookup table, maps hwnd to WinItem.
;                           - For windows that have pseuodwindows, the hwnd always maps to
;                           -   the WinItem of the parent, not the pseudowindow.
;
; internal properties:
;
;   _hwnd       - integer, Stores the actual hwnd. For pseudowindows, stores the parent's hwnd.
;   _pos        - WinPos, stores the actual value
;   _savepos    - WinPos, stores the actual value
;
;   this._showstate     - boolean, False if window is not showing, becomes true when a polled hook_show is (queued to) run.
;                       - Reset to false when hwnd is set to 0.
;   this._closestate    - boolean, False if window is showing, becomes true when hook_close is (queued to) run.
;                       - Reset to false when hwnd is set to a non-zero value.
;
; WinItem class (static) methods:
; 
;   static LookupHwnd(hwnd)     - Returns the WinItem corresponding to the passed hwnd. 
;                               -   Uses the reverse lookup table _HwndReverseLookup[].
;                               - For windows with pseudowindows, will determine which
;                               -   pseudowindow is showing and return its WinItem. 
;                               -   If cannot determine which pseudowindow, then 
;                               -   returns the parent window's WinItem.
;
; WinItem instance methods:
;
;   IsReady()   - Returns hwnd if a window exists, is visible, and is not minimized.
;               - For pseudowindows, determines whether the pseudowindow is showing.
;               - Returns 0 if not showing.
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
; To instantiate a new WinItem, use:
;
;   WinItem(key, parentapp, [parentwindow, searchtitle, wintext, hook_show, hook_close, validate])
;
class WinItem {
    static _HwndReverseLookup := Map()             ; class variable, stores a map of hwnd to WinItems

    __New(key, parentapp, parentwindow := 0, searchtitle := "", wintext := "", pollflag := false, hook_show := 0, hook_close := 0, validate := 0) {
        
        this.key := key
        this.parentapp := parentapp
        this.parentwindow := parentwindow
        this.searchtitle := searchtitle
        this.wintext := wintext

        this.pollflag := pollflag
        this.hook_show := hook_show
        this.hook_close := hook_close
        this.validate :=  validate
        
        ; internal use variables
        this._hwnd := 0
        this._pos := WinPos()
        this._savepos := WinPos()

        this._showstate := false
        this._closestate := false

        this.PWin := Array()

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
                ; must have a parent app with exename to have valid search criteria, so set this.criteria to empty
                this.criteria := ""
            }
            
            ; See if the window already exists. If so, set the hwnd.
            if this.criteria {
                ; DetectHiddenText should be false (globally set), we do not want to search hidden text when looking for windows
                try {
                    gethwnd := WinExist(this.criteria, this.wintext)
                    if gethwnd {
                        this._showstate := true     ; don't want to run hook_show when PA first starts up
                    }
                } catch {
                    gethwnd := 0
                }
                this.hwnd := gethwnd
            } else {
                ; no criteria
                this.hwnd := 0
            }
            
        } else {
            ; this is a pseudowindow

            ; search criteria for a psuedowindow is ""
            this.criteria := ""

            ; Add this pseudowindow to the parentwindow's PWin[] array.
            this.parentwindow.PWin.Push(this)

            ; See if the pseudowindow is already showing. If so, set the hwnd.
            ; this.IsReady() returns the hwnd of the parent window 
            ; of a pseudowindow that's showing.
            gethwnd := this.IsReady()
            if gethwnd {
                this._showstate := true     ; don't want to run hook_show when PA first starts up
            }
            this.hwnd := gethwnd
        }
    }    
    
    pid {
        get {
            if !this.parentwindow {
                ; this is a real window, not a pseudowindow
                if this.criteria {
                    try {
                        ; look for this window's process and return its pid
                        getpid := WinGetPID(this.criteria, this.wintext)
                    } catch {
                        ; did not find a running process
                        getpid := 0
                    }
                } else {
                    ; no criteria, cannot look for a running process
                    getpid := 0
                }
            } else {
                ; this is a pseudowindow, return it's parent's pid
                getpid := this.parentwindow.pid
            }

            if !getpid {
                ; reset hwnd to 0 if this process it not running (or not found)
                this.hwnd := 0
            }
            return getpid
        }
    }

    hwnd {
        get {
            if !this.parentwindow {
                ; this is a real window, not a pseudowindow

                ; if this.pollflag {
                ;     ; This is a polled window. Polled windows always require
                ;     ; searching by criteria, as they may share a hwnd.
                ;     try {
                ;         gethwnd :=  WinExist(this.criteria, this.wintext)
                ;     } catch {
                ;         gethwnd :=  0
                ;     }
                ;     if this._hwnd {
                ;         if (this._hwnd != gethwnd)
                ;             || !WinItem._HwndReverseLookup.Has(gethwnd)
                ;             || (WinItem._HwndReverseLookup[gethwnd].key != this.key) {
                ;                 ; The found window does not match the existing window, so
                ;                 ; delete its assignment and then reassign it.

                ;                 this.hwnd := 0          ; deletes reverse lookup entry, resets flags
                ;                 this.hwnd := gethwnd    ; creates new reverse lookup entry, resets flags
                ;         } else {
                ;             ; The found window matches this window's hwnd
                ;             ; and the previously stored window has the same key
                ;             ; so this window aleady exists, don't need to do more.
                ;         }
                ;     } else {
                ;         if gethwnd {
                ;             this.hwnd := gethwnd
                ;         }
                ;     }
                    
                ; } else {
                ;     ; this is not a polled window
                    if gethwnd := WinExist(this._hwnd) {
                        ; This window already exists, so don't need to do more.
                    } else {
                        ; This window doesn't seem to exist, search for it by criteria
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
                ; }

            } else {
                ; This is a pseudowindow, see if the pseudowindow is showing.
                ; If so, return its parentwindow's hwnd.
                ; Pseudowindows always require checking their validation 
                ; function (via IsReady()).
                gethwnd := this.IsReady()
                this.hwnd := gethwnd
            }

            return this._hwnd
        }

        set {
            ; handle real windows and pseudowindows the same
            if this._hwnd = Value {
                ; This window has the same hwnd as the new hwnd value so we're done.
                return
            }
            
            ; this._hwnd and Value are different
            if !this.parentwindow && this._hwnd {
                ; this is a real window and this._hwnd is non-zero
                ; try to delete its reverse lookup entry
                try {
                    WinItem._HwndReverseLookup.Delete(this._hwnd)
                } catch {
                }
            }
            if Value {
                ; new hwnd is non-zero
                if !this.parentwindow {
                    ; this is a real window
                    ; record it in the reverse lookup table
                    WinItem._HwndReverseLookup[Value] := this
                }
                ; reset _closestate
                this._closestate := false
            } else {
                ; new hwnd is 0
                ; reset _showstate
                this._showstate := false
            }
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
        ; set {
        ;     this._pos.x := Value.x
        ;     this._pos.y := Value.y
        ;     this._pos.w := Value.w
        ;     this._pos.h := Value.h
        ; }
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
                    return (WinGetStyle(this._hwnd) & WS_VISIBLE) ? true : false
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
                    return (WinGetMinMax(this._hwnd) = -1) ? true : false
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

    haschild {
        get {
            return (this.PWin.Length > 0) ? true : false
        }
    }


    ; Returns the WinItem corresponding to the passed hwnd. 
    ; Uses the reverse lookup table _HwndReverseLookup[].
    ;
    ; For windows with pseudowindows, will determine which
    ; pseudowindow is showing and return its WinItem. 
    ; If cannot determine which pseudowindow, then 
    ; returns the parent window's WinItem.
    ;
    ; If no match, returns 0.
    static LookupHwnd(hwnd) {
        if hwnd && WinItem._HwndReverseLookup.Has(hwnd) {
            win := WinItem._HwndReverseLookup[hwnd]
            if win.haschild {
                for pwin in win.PWin {
                    if pwin.IsReady() {
                        ; found a matching child pseudowindow
                        ; return it
                        win := pwin
                        break       ; for
                    }
                }
            }
        } else {
            win := 0
        }
        return win
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

    ; Returns diagnostic info about this window as a string.
    ; Returns empty string for non-existing windows unless showall is set to true.
    ; Pseudowindows are nested under their parent window.
    Print(showall := false) {

        gethwnd := this.hwnd

        if !this.parentwindow {
            ; this is a real window

            if showall || gethwnd {
                output := "&nbsp;&nbsp;&nbsp;&nbsp;"
                output .= (showall && gethwnd) ? "*" : ""
                output .= this.key " (" this.pid "|" gethwnd
                if gethwnd {
                    output .= (this.visible ? "" : "h") . (this.minimized ? "m" : "")
                }
                output .= ")"
                ; output .= " _showstate=" this._showstate
                output .= "<br />"

                ; if this window has child windows, print them
                if this.haschild {
                    for w in this.PWin {
                        output .= w.Print(showall)
                    }
                }
            } else {
                output := ""
            }
        
        } else {
            ; this is a pseudowindow
            if this.validate {
                valid := this.validate.Call()
            } else {
                valid := 0
            }

            if showall || (gethwnd && valid) {
                output := "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
                output .= (showall && valid) ? "*" : ""
                output .= this.key " (" this.pid "|" gethwnd
                output .= valid ? "/yes" : "/no"                
                output .= ")"
                ; output .= " _showstate=" this._showstate
                output .= "<br />"
            } else {
                output := ""
            }

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
        } else {
            ; this is a pseudowindow
            ; do nothing
        }
    }

    ; Saves the current x, y, width, and height of a window in its savepos proprety.
    ;
    ; Return true on success, false on failure.
    ;
    ; For pseudowindows, do nothing and return false.
    SavePosition() {
        if !this.parentwindow {
            ; this is a real window
            try {
                if this.hwnd {
                    WinGetPos(&x, &y, &w, &h, this.hwnd)
                    if w >= WINPOS_MINWIDTH && h >= WINPOS_MINHEIGHT {
                        this._savepos.x := x
                        this._savepos.y := y
                        this._savepos.w := w
                        this._savepos.h := h
                        ; success, return true
                        return true
                    }
                }
            } catch {
            }
        } else {
            ; this is a pseudowindow
            ; do nothing
        }
        return false
    }

    ; Moves (restores) window to the size and position recorded in its savepos property.
    ;
    ; Return true on success, false on failure.
    ;
    ; For pseudowindows, do nothing and return false.
    RestorePosition() {
        if !this.parentwindow {
            ; this is a real window
            try {
                if this.hwnd {
                    if this._savepos.w >= WINPOS_MINWIDTH && this._savepos.h >= WINPOS_MINHEIGHT {
                        WinMove(this._savepos.x, this._savepos.y, this._savepos.w, this._savepos.h, this.hwnd)
                        ; success, return true
                        return true
                    }
                }
            } catch {
            }
        } else {
            ; this is a pseudowindow
            ; do nothing
        }
        return false
    }

    ; Centers this window over the passed parent window (WinItem),
    ; window position (WinPos), or monitor (integer).
    ;
    ; If no parameter is passed, then centers within the monitor which the window is in.
    ;
    ; Returns true on success, false on failure.
    ;
    ; For pseudowindows, do nothing and return false.
    CenterWindow(parent := 0) {

        if !this.parentwindow {
            ; this is a real window
            if IsObject(parent) {
                if parent.HasOwnProp("parentapp") {
                    ; parent is a WinItem object
                    try {
                        cw := 0
                        pw := 0
                        ; get child and parent window positions and dimensions
                        WinGetPos( , , &cw, &ch, this._hwnd)
                        WinGetPos(&px, &py, &pw, &ph, parent.hwnd)

                        if cw = 0 || pw = 0 {
                            return false
                        }

                        ; calculate new position
                        nx := px + (pw - cw) / 2
                        ny := py + (ph - ch) / 2

                        ; move child window to center of parentwindow, without resizing
                        WinMove(nx, ny, , , this._hwnd)
                        return true
                    } catch {
                    }
                } else {
                    ; parent is assumed to be a WinPos object
                    try {
                        cw := 0
                        ; get child window position and dimensions
                        WinGetPos( , , &cw, &ch, this._hwnd)

                        if cw = 0 {
                            return false
                        }

                        ; calculate new position
                        nx := parent.x + (parent.w - cw) / 2
                        ny := parent.y + (parent.h - ch) / 2

                        ; move child window to center of parentwindow, without resizing
                        WinMove(nx, ny, , , this._hwnd)
                        return true
                    } catch {
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
                    WinGetPos( , , &cw, &ch, this._hwnd)

                    if cw = 0 {
                        return false
                    }

                    ; get position of monitor N (parent)
                    monpos := MonitorPos(parent)

                    ; calculate new position
                    nx := monpos.x + (monpos.w - cw) / 2
                    ny := monpos.y + (monpos.h - ch) / 2

                    ; move child window to center of parentwindow
                    WinMove(nx, ny, , , this._hwnd)

                    return true
                }
            }
        
        } else {
            ; this is a pseudowindow
            ; do nothing
        }

        return false
    }

    ; Write window's savepos to user specific settings.ini file.
    ; Returns true on success, false on failure.
    ; If this is a pseudowindow, do nothing, return failure.
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
    ; Returns true on success, false on failure.
    ; If this is a pseudowindow, do nothing, return failure.
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




/**********************************************************
 * Functions defined by this module
 * 
 */


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
;
; For windows that don't have a pseudowindow, returns the win key of the real window.
;
; For windows that have one or more pseudowindows, determines which pseudowindow
; is showing and returns the win key of the pseudowindow.
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
; hwnd is the (real) window (not a pseudowindow)
; 
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

        if Setting["Debug"].enabled
            TTip("Context(" appkey "/" winkey ")", 700)

        for context in contexts {

            carr := StrSplit(context, " ")
            cappkey := carr[1]		;the app key of the context is the first element of carr[]
            
            if cappkey == appkey {
                ; app key of the window being checked matches the app key of this context
                ; now match the win key if there is a context win key to match

                j := 2
                if j > carr.Length {
                    ; no windows to match with, so we've succeeded, return true
                    if Setting["Debug"].enabled
                        TTip("Context(" appkey "/" winkey ")=>" cappkey, 700)
                    return true
                }    

                ; need to check for a match among each of the windows in the context
                while j <= carr.Length {
                    cwin := App[appkey].Win[carr[j]]    ; get the winitem of the context item
                    j++

                    if !cwin.parentwindow {
                        ; this context is a true window, match against its win key
                        cwinkey := cwin.key   
                        if cwinkey == winkey {
                            ; found a window match, return true
                            if Setting["Debug"].enabled
                                TTip("Context(" appkey "/" winkey ") == " cappkey "/" cwinkey, 700)
                            return true
                        }
                    } else {
                        ; this context is a pseudowindow, match against the parent window's win key
                        cwinkey := cwin.parentwindow.key
                        if cwinkey == winkey {
                            ; found a parent window match
                            ; still need to call the validate function to check if the pseudowindow is actually showing
                            fn := cwin.validate
                            if fn {
                                if fn.Call() {
                                    ; pseudowindow condition successfully validated
                                    ; return success
                                    if Setting["Debug"].enabled
                                        TTip("Context(" appkey "/" winkey ") == " cappkey "/" cwinkey "/" cwin.key, 700)
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


; Returns diagnostic info about a window (or all windows) for an app (or all apps)
; as a string
;
; omits non-existing windows or pseudowindows unless showall is set to true
PrintWindows(appkey := "", winkey := "", showall := false) {

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
        for , a in App {
            output .= a.Print( , showall)
        }
    }

	return output
}


; For all windows of all apps, saves the current x, y, width, and height
; of each in its savepos proprety.
SavePositionsAll() {
    for , a in App {
        a.SavePositions()
    }
}

; For all windows of all apps, restores window to the size and position
; in its savepos property.
RestorePositionsAll() {
    for , a in App {
        a.RestorePositions()
    }
}

; For all windows of all apps, write window's savepos to 
; user specific settings.ini file.
WritePositionsAll() {
    for , a in App {
        a.WritePositions()
    }
}

; For all windows of all apps, reads window's savepos from
; user specific settings.ini file.
ReadPositionsAll() {
    for , a in App {
        a.ReadPositions()
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
VirtualScreenPos() {
    return WinPos(SysGet(76), SysGet(77), SysGet(78), SysGet(79))
}
