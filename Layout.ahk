/**
 * Layout.ahk
 * 
 * This module defines classes and function for managing window layouts and monitors.
 * 
 * 
 * This module defines the following classes:
 * 
 *  Pos         - Stores a 4-tuple x, y, w, h that specifies the position and size of a window.
 * 
 *  WinPos      - Associates a window (WinItem) with a location/size (Pos)
 * 
 *  LayoutItem  - Holds one layout, i.e. a set of windows and their positions.
 * 
 * 
 * This module defines the functions:
 *  
 *  MonitorCount()          - Returns the system monitor count
 *  MonitorNumber(x, y)     - Returns the monitor number that contains the x, y coordinates
 *  MonitorPos(N)           - For monitor N, returns the monitor position and size (Pos).
 *  VirtualScreenPos()      - Returns a Pos with  the coordinates and size of the virtual screen.
 * 
 *  GenerateLayout()        - Returns a LayoutItem that holds an auto generated layout.
 *                          - Generated layout is based on number and sizes of monitors.
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
** Global variables and constants used or defined in this module
 */


; Map of Layouts saved by PACS Assistant
Layout["Default"] := LayoutItem()


; The number of system monitors
global _MonitorCount := 0

; Array of objects of {l, t, r, b}, representing the left, top, right, bottom
; coordinates for each monitor. The right and bottom coordinates are just outside
; the displayable area.
global _MonitorCoords := Array()




/**********************************************************
 * Classes defined by this module
 * 
 */


; Pos class
;
; A simple class to hold the position and size of a window
;
; Properties:
;   x           - current screen x position of the window
;   y           - current screen y position of the window
;   w           - current width of the window
;   h           - current height of the window
;
; To create a new instance:
;   mypos := Pos([x, y, w, h])
;
class Pos {
    __New(x := 0, y := 0, w := 0, h := 0) {
        this.x := x
        this.y := y
        this.w := w
        this.h := h
    }
}


; WinPos class
;
; Associates a window (WinItem) with a location/size (Pos)
;
; Properties:
;   window          - WinItem
;   position        - Pos
;
; To create a new instance:
;   mywinpos := WinPos(window, position)
;
class WinPos {
    __New(window, position) {
        this.window := window
        this.position := position
    }
}


; LayoutItem class
;
; Holds one layout, i.e. a set of windows and their positions.
;
; Properties:
;   winpos[]            - Array, each element holds a WinPos
;
; Internal properties:
;   _lastwinpos[]       - Array, each element holds a WinPos. Records the previous layout before Activate()
;                       - repositioned the windows, for use by Revert(). Empty (_lastwinpos == 0) if no previous layout.
;
; Methods:
;   Add(window, position)   - Adds the passed window (WinItem) and position (Pos) to the layout. If the window
;                           - already has a saved position, replaces the position.
;
;   Memorize()          - Remebers current position/size of all visible true windows as a layout.
;
;   Restore(window := 0) - If window (WinItem) is passed (and non-zero), and this layout has a saved position for the
;                       - window, repositions/resizes the window.
;                       - If window is zero, repositions/resizes all the windows in this layout to their saved positions.
;
;   Revert()            - Returns the windows in this layout to their previous positions/sizes
;                       - before Activate() was called for this layout. If Activate() was not previously
;                       - called for this layout, does nothing.
;
;   GetPos(window)       - Returns a Pos for the remembered position/size of the window (WinItem), if stored in this layout.
;                       - If no stored layout, returns 0.
;
;   Save(layoutname)    - Save the layout layoutname to the user specific settings.ini file.
;
;   Read(layoutname)    - Read the layout layoutname from the user specific settings.ini file.
;
;   Print()             - Returns the windows and positions stored in this layout as a string (for diagnostic use).
;
class LayoutItem {
    winpos := Array()
    _lastwinpos := Array()

    Add(window, position) {
        if window && position {
            ; See if the window already has a saved position in this layout
            for wp in this.winpos {
                if wp.window == window {
                    ; found, just update the position
                    wp.window.pos := position
                    ;done
                    return
                }
            }
            ; didn't find the window, so add a new WinPos
            this.winpos.Push(WinPos(window, position))
        }
    }

    Memorize() {
        this._lastwinpos := this.winpos      ; save winpos in _lastwinpos before memorizing new positions
        this.winpos := Array()          ; create new empty array for winpos
        for , a in App {
            for , w in a.Win {
                if !w.parentwindow {
                    ; this is a real window, not a pseudowindow
                    if w.IsReady() {
                        ; save position of displayed windows
                        this.winpos.Push(WinPos(w, w.pos))
                    }
                } else {
                    ; this is a pseudowindow
                    ; do nothing
                }
            }
        }
    }

    Restore(window := 0) {
        if window {
            ; Restore a single winitem, if it has a saved postion in this layout.
            for wp in this.winpos {
                if wp.window == window {
                    ; move the window to the current saved position
                    wp.window.pos := wp.position
                    break       ; for
                }
            }
        } else {
            ; Restore all windows saved in this layout.
            for wp in this.winpos {
                ; move the window to the current saved position
                wp.window.pos := wp.position
            }
        }
    }

    Revert() {
        for wp in this._lastwinpos {
            ; move the window to the previous saved position
            wp.window.pos := wp.position
        } else {
            ; if no previous saved position, restore to current saved position
            this.Restore()
        }
    }

    GetPos(window) {
        if window {
            ; Restore a single winitem, if it has a saved postion in this layout.
            for wp in this.winpos {
                if wp.window == window {
                    ; found the item, return its saved position
                    return wp.position
                }
            }
        }
        return 0
    }

    Save(layoutname) {
        inifile := Setting["inifile"].value
        
        if inifile {
            sectionname := "Layout_" . layoutname
            
            for wp in this.winpos {
                appkey := wp.window.parentapp.key
                winkey := wp.window.key
                position := wp.position.x . "," . wp.position.y . "," . wp.position.w . "," . wp.position.h
                try {
                    IniWrite(position, inifile, sectionname, appkey . "_" . winkey)
                }
            }
        }
    }
    
    Read(layoutname) {
        inifile := Setting["inifile"].value
        
        if inifile {
            sectionname := "Layout_" . layoutname
            sectiontext := IniRead(inifile, sectionname, , "")

            this._lastwinpos := this.winpos     ; save winpos in _lastwinpos before reading new positions
            this.winpos := Array()              ; create new empty array for winpos

            loop parse sectiontext, "`n" {
                keyval := StrSplit(A_LoopField, "=")
                key := keyval[1]
                value := keyval[2]
                
                delimpos := InStr(key, "_")
                appkey := SubStr(key, 1, delimpos - 1)
                winkey := SubStr(key, delimpos + 1)
                
                getpos := StrSplit(value, ",")
                x := getpos[1]
                y := getpos[2]
                w := getpos[3]
                h := getpos[4]
                this.winpos.Push(WinPos(App[appkey].Win[winkey], Pos(x, y, w, h)))
            }
        }    
    }    
    
    Print() {
        output := ""
        for wp in this.winpos {
            output .= "&nbsp;&nbsp;&nbsp;&nbsp;" wp.window.parentapp.key "/" wp.window.key " (" wp.position.x ", " wp.position.y ", " wp.position.w ", " wp.position.h ")<br/>"
        }
        output .= "<br/>"
        return output
    }

}    


; Monitors class
;
; Represents the system's monitor configuration.
;
; Properties:
;   N               - integer, number of monitors
;   Monitor[]       - array, one WinPos for each monitor
;   
class Monitors {

}




/**********************************************************
 * Functions defined by this module
 * 
 */


; Helper function to other Monitor functions
_MonitorGetInfo() {
    global _MonitorCount
    global _MonitorCoords

    ; if first time, get and cache info about the monitors
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


; For monitor N, returns a Pos reflecting the monitor's position and size (x,y,w,h).
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
    return Pos(mon.l, mon.t, (mon.r - mon.l), (mon.b - mon.t))
}


; Returns a Pos (x, y, w, h) reflecting the coordinates and size of the
; virtual screen, which is the bounding rectangle of all display monitors.
;
; SM_XVIRTUALSCREEN := 76   - Coordinates for the left side and the top of the virtual screen.
; SM_YVIRTUALSCREEN := 77
; SM_CXVIRTUALSCREEN := 78  - Width and height of the virtual screen, in pixels.
; SM_CYVIRTUALSCREEN := 79
VirtualScreenPos() {
    return Pos(SysGet(76), SysGet(77), SysGet(78), SysGet(79))
}


; Returns a LayoutItem that holds an auto generated layout.
; Generated layout is based on number and sizes of monitors.
;
; Returned layout includes positions for each of the windows:
;   PA main
;   EI d
;   PS main
;   EICLIN main
;   EPIC main, chat
;
;
GenerateLayout() {
    static MPos := Array()
    
    newlayout := LayoutItem()

    count := MonitorCount()

    ; retrieve the sizes of all monitors, cache it in MPos
    if MPos.Length = 0 {
        n := 1
        while n <= count {
            MPos.Push(MonitorPos(n))
            n++
        }
    }

    ; base the layout on monitor configuration
    switch count {
        case 3:
            ; ensure 1st monitor is sufficiently large landscape
            if (MPos[1].w > EI_DEFAULTWIDTH + PA_DEFAULTWIDTH) && (MPos[1].w > MPos[1].h) {
                ; PA main - upper right corner of 1st monitor
                ; with width of PA_DEFAULTWIDTH and height of PA_DEFAULTHEIGHT
                w := PA_DEFAULTWIDTH
                h := PA_DEFAULTHEIGHT
                x := MPos[1].x + MPos[1].w - w
                y := 0
                newlayout.Add(App["PA"].Win["main"], Pos(x, y, w, h))
                ; PS main - right side of 1st monitor below PA
                ; with width of PA_DEFAULTWIDTH and height of monitor height minus PA_DEFAULTHEIGHT
                w := PA_DEFAULTWIDTH
                h := MPos[1].h - PA_DEFAULTHEIGHT
                x := MPos[1].x + MPos[1].w - w
                y := PA_DEFAULTHEIGHT
                newlayout.Add(App["PS"].Win["main"], Pos(x, y, w, h))
                ; EI d - 1st monitor to the left of PA and PS
                ; with width of EI_DEFAULTWIDTH and same height as PS
                w := EI_DEFAULTWIDTH
                h := MPos[1].h - PA_DEFAULTHEIGHT
                x := MPos[1].x + MPos[1].w - PA_DEFAULTWIDTH - w
                y := PA_DEFAULTHEIGHT
                newlayout.Add(App["EI"].Win["d"], Pos(x, y, w, h))
                ; EPIC main - 1st monitor to the left of PS and EI
                ; with width of EPIC_DEFAULTWIDTH and height of EPIC_DEFAULTHEIGHT
                w := EPIC_DEFAULTWIDTH
                h := EPIC_DEFAULTHEIGHT
                x := MPos[1].x + MPos[1].w - PA_DEFAULTWIDTH - EI_DEFAULTWIDTH - w
                y := PA_DEFAULTHEIGHT
                newlayout.Add(App["EPIC"].Win["main"], Pos(x, y, w, h))
                ; EPIC chat - 1st monitor above (and overlapping with) EPIC main window, right justified
                ; with width of EPICCHAT_DEFAULTWIDTH and height of EPICCHAT_DEFAULTHEIGHT
                w := EPICCHAT_DEFAULTWIDTH
                h := EPICCHAT_DEFAULTHEIGHT
                x := MPos[1].x + MPos[1].w - PA_DEFAULTWIDTH - EI_DEFAULTWIDTH - w
                y := 0
                newlayout.Add(App["EPIC"].Win["chat"], Pos(x, y, w, h))
            }

        case 4:
            ; assume 4 portrait monitors
            ; PA main - top of 2nd monitor
            ; with width of monitor and height of PA_DEFAULTHEIGHT
            w := MPos[2].w
            h := PA_DEFAULTHEIGHT
            x := MPos[2].x
            y := 0
            newlayout.Add(App["PA"].Win["main"], Pos(x, y, w, h))
            ; PS main - 2nd monitor below PA
            ; with width of monitor and height of monitor height minus PA_DEFAULTHEIGHT
            w := MPos[2].w
            h := MPos[2].h - PA_DEFAULTHEIGHT
            x := MPos[2].x
            y := PA_DEFAULTHEIGHT
            newlayout.Add(App["PS"].Win["main"], Pos(x, y, w, h))
            ; EI d - 1st monitor
            ; with width of monitor and same height as PS
            w := MPos[1].w
            h := MPos[2].h - PA_DEFAULTHEIGHT
            x := MPos[1].x
            y := PA_DEFAULTHEIGHT
            newlayout.Add(App["EI"].Win["d"], Pos(x, y, w, h))
        
        case 5:
            ; assume 5 portrait monitors
            ; PA main - top of 3rd monitor
            ; with width of monitor and height of PA_DEFAULTHEIGHT
            w := MPos[3].w
            h := PA_DEFAULTHEIGHT
            x := MPos[3].x
            y := 0
            newlayout.Add(App["PA"].Win["main"], Pos(x, y, w, h))
            ; PS main - 3rd monitor below PA
            ; with width of monitor and height of monitor height minus PA_DEFAULTHEIGHT
            w := MPos[3].w
            h := MPos[3].h - PA_DEFAULTHEIGHT
            x := MPos[3].x
            y := PA_DEFAULTHEIGHT
            newlayout.Add(App["PS"].Win["main"], Pos(x, y, w, h))
            ; EI d - 2nd monitor
            ; with width of monitor and same height as PS
            w := MPos[2].w
            h := MPos[3].h - PA_DEFAULTHEIGHT
            x := MPos[2].x
            y := PA_DEFAULTHEIGHT
            newlayout.Add(App["EI"].Win["d"], Pos(x, y, w, h))
        default:
            ; nothing
    }
                
    return newlayout
}
