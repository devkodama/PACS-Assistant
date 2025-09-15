/**
 * Layout.ahk
 * 
 * This module defines classes and function for managing window layouts and monitors.
 * 
 * 
 * This module defines the following classes:
 * 
 *  WinPos - stores a 4-tuple x, y, w, h that specifies the position and size
 *  of a window.
 * 
 * 
 * 
 * 
 * This module defines the functions:
 *  
 * 
 * 
 *  MonitorCount()          - Returns the system monitor count
 *  MonitorNumber(x, y)     - Returns the monitor number that contains the x, y coordinates
 *  MonitorPos(N)           - For monitor N, returns the monitor position and size (Pos).
 *  VirtualScreenPos()      - Returns a Pos with  the coordinates and size of the virtual screen.
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
** Global variables and constants used or defined in this module
 */


; Map of Layouts saved by PACS Assistant
Layout["default"] := LayoutItem()


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
;   Memorize()          - Remebers current position/size of all visible true windows as a layout.
;
;   Restore()           - Repositions/resizes the windows in this layout to their saved positions.
;
;   Revert()            - Returns the windows in this layout to their previous positions/sizes
;                       - before Activate() was called for this layout. If Activate() was not previously
;                       - called for this layout, does nothing.
;
;   Print()             - Returns the windows and positions stored in this layout as a string (for diagnostic use).
;
class LayoutItem {
    winpos := Array()
    _lastwinpos := Array()

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

    Restore() {
        for wp in this.winpos {
            ; move the window to the current saved position
            wp.window.pos := wp.position
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

    Print() {
        output := "Layout:<br/>"
        for wp in this.winpos {
            output .= wp.window.parentapp.key "/" wp.window.key " (" wp.position.x ", " wp.position.y ", " wp.position.w ", " wp.position.h ")<br/>"
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
