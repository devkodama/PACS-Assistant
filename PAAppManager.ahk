/**
 * PAAppManager.ahk
 *
 * 
 *
 * This module provides App and AppWin classes for managing application windows.
 *
 * The App class corresponds to a single application such as Cisco VPN Client,
 * or EI, or PowerScribe, or Epic. An App object tracks and returns information
 * about the status of the application and its windows. Any number of windows
 * can be managed within one App object.
 * 
 * The AppWin class tracks and returns information about an individual window that
 * belongs to the App.
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





/**********************************************************
 * Classes defined by this module
 * 
 */

 

;
;	appkey		- [required] appliation key string
;	winkey		- [required] window key string
;
;	fulltitle	- full title of window, not used for matching
;	searchtitle	- short title of window, used for matching
;	wintext		- window text to match, used for matching
;	ahk_exe		- executable name, used for matching
;	criteria	- combined search string generated from searchtitle and ahk_exe
;
;	hwnd		- 0 if window doesn't exist, HWND of the window otherwise
;	visible		- true if window is visible (has WF_VISIBLE style), false if a hidden window
;	minimized	- true if window is minimized, false if not
;	opentime	- timestamp when window was last opened (from A_Now)
;	status		- [optional] status item, window specific usage
;
;	xpos		- saved screen x position of the window
;	ypos		- saved screen w position of the window
;	width		- saved width of the window (must be >= 100)
;	height		- saved height of the window (must be >= 100)
;
;	hook_open	- function to be called when this window is opened
;	hook_close	- function to be called when this window is closed

; PAWindows["PS"]["main"] := WindowItem("PS", "main", "PowerScribe 360 | Reporting", "PowerScribe", "Signing queue", "Nuance.PowerScribe360.exe", PSOpen_PSmain, PSClose_PSmain)


; App properties:
;   id          - string, app name, e.g. "VPN", "EI", "PS", "EPIC", "PA"
;   name        - string, full name of app, e.g. "PowerScribe 360"
;   
;   windows     - Map, all windows associated with the app
;
;   Exists      - (read only) true if app has been started, false if not

; App methods:
;   Exists   - 
;
;
class App {
    

}