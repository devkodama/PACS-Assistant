/**
 * PAGlobals.ahk
 * 
 * Global variables and constants for PACS Assistant
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <Cred>

#Include PAAppManager.ahk



/**********************************************************
 * Global constants
 * 
 * Should not change during program execution
 * 
 */


; interval (ms) for dispatching PA functions
DISPATCH_INTERVAL := 100

; interval (ms) for updating GUI display
GUIREFRESH_INTERVAL := 200

; interval (ms) for updating window under mouse ( _UpdateMouseWindow() )
WATCHMOUSE_UPDATE_INTERVAL := 200

; interval (ms) for updating window statuses
WATCHWINDOWS_UPDATE_INTERVAL := 500

; interval (ms) for updating dictate button status
WATCHDICTATE_UPDATE_INTERVAL := 100

; interval (ms) for updating VPN connection status
WATCHVPN_UPDATE_INTERVAL := 2000

; interval (ms) for jiggling mouse to keeping screen awake
JIGGLEMOUSE_UPDATE_INTERVAL := 180000		; 180000 = 3 minutes

; timeout (ms) for clearing status bar text
GUISTATUSBAR_TIMEOUT := 60000	; 60 sec


; maximum timeout (seconds) for making VPN connection from start to finish
VPN_CONNECT_TIMEOUT := 120
; maximum timeout (seconds) for disconnecting VPN connection
VPN_DISCONNECT_TIMEOUT := 10
; timeout (seconds) for starting up VPN UI (main window)
; or for waiting for initial login window to appear
VPN_DIALOG_TIMEOUT := 10
; number of failed login attempts (username/password failures) allowed
VPN_FAILEDLOGINS_MAX := 3
; VPN URL string
VPN_URL := "vpn.adventhealth.com/SecureAuth"


; timeout (seconds) for starting up EI to get to login window
EI_LOGIN_TIMEOUT := 60
; timeout (seconds) for getting to EI desktop window after login
EI_DESKTOP_TIMEOUT := 60
; timeout (seconds) for allowing Collaborator window to appear after login
EI_COLLABORATOR_TIMEOUT := 10
; timeout (seconds) for shutting down EI
EI_SHUTDOWN_TIMEOUT := 60
; EI server string
EI_SERVER := "mivcsp.adventhealth.com"


; timeout (seconds) for getting to PS main window after login
PS_MAIN_TIMEOUT := 120
; time delay (seconds) for turing off microphone after a report is closed
PS_DICTATEAUTOOFF_DELAY := 5
; timeout (seconds) for shutting down EI
PS_SHUTDOWN_TIMEOUT := 120


; timeout (seconds) for starting up EPIC to get to login window
EPIC_LOGIN_TIMEOUT := 60
; timeout (seconds) for shutting down EPIC
EPIC_SHUTDOWN_TIMEOUT := 30
; timezone string for Epic
EPIC_TIMEZONE := "America/Chicago"




; minimum width and height to consider a window position valid
WINDOWPOSITION_MINWIDTH := 100
WINDOWPOSITION_MINHEIGHT := 100


; Windows constant (style of visible windows)
WS_VISIBLE := 0x10000000

; Windows constants used in PAPS.ahk module.
WM_SETTEXT := 0x000C
WM_GETTEXT := 0x000D
EM_GETSEL := 0x00B0
EM_SETSEL := 0x00B1
EM_SETREADONLY := 0x00CF


; Executable paths
EXE_VPN := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"
EXE_VPNCLI := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"

EXE_EI := "C:\Program Files (x86)\Agfa\Enterprise Imaging\EnterpriseImagingLauncher.exe"

EXE_EPIC := "C:\Program Files (x86)\Epic\Hyperdrive\VersionIndependent\hyperspace.exe"

; Base filneame used to derive settings.ini and setting.username.ini filenames
FILE_SETTINGSBASE := "settings"

; filepath to icd code table
ICD_CODEFILE := "icd10codes.txt"


; Text/color to display when microphone is off
MICROPHONETEXT_OFF := "Microphone Off"
MICROPHONECOLOR_OFF := "#303030"

; Text to display when microphone is on
MICROPHONETEXT_ON := "Microphone On"
MICROPHONECOLOR_ON := "#d02020"

; Format to return DOB from patient info
INFO_DOB_FORMAT := "M/d/yyyy"

; PA GUI
PAGUI_WINDOWTITLE := "PACS Assistant"
PAGUI_HOMEPAGE := "pages/PACSAssistant.html"

; Used in PAInfo.ahk. Format for returning DOB from Patient object.
INFO_DOB_FORMAT := "M/d/yyyy"





/**********************************************************
 * Global variables
 * 
 */


; This is the top level on/off switch for PACS Assistant.
; If false, many PACS Assistant functions are disabled.
; This is a shadow copy of PA_Settings["active"].value, kept
; current by PADaemon GUI refresh.
global PAActive := false

; WindowBusy is a semaphore which if true prevents activation of a
; different window by PACS Assistant (blocks follow focus)
global PAWindowBusy := false

; Cancel flag, can be set to signal that long running operations should quit
global PACancelRequest := false

; This is true at startup and set to false after the first time PAWindows.Update() is called
global _PAUpdate_Initial := true

; This is false at startup and set to true after the GUI is up and running.
global _PAGUI_Running := false

; updated with the handle of the window under the mouse cursor every time
; _UpdateMouseWindow() is called
global PA_WindowUnderMouse := 0


; Global dispatch queue
global DispatchQueue := Array()


; PASettings holds settings used across PACS Assistant.
; Each entry is a {"key", Setting()} pair. See PASettings.ahk for Setting
; class and PASettings[] definitions.
global PASettings

; credentials of current user. See Crek.ahk for Credential
; class definition.
global CurrentUserCredentials := Credential()

; Current Patient
global PACurrentPatient := Patient()

; Current Exam
global PACurrentStudy := Study()


; Window Info for GUI display
global PAWindowInfo := ""

; Status bar contents
global PAStatusBarText := ""

; Power button status
global PAStatus_PowerButton := ""



; This holds the Windows double click setting (in ms) - value is updated by PA_Init()
global PA_DoubleClickSetting := 400

; This holds the Windows mouse speed setting (1-20) - value is updated by 
global PA_MouseSpeedSetting := 10



; PACurState holds the current state of apps and other things across PACS Assistant
; Valid values are unique to each entry:
;   "PA"    ->  
;   "power" -> "off", "yellow", "green"
;   "VPN"   -> "false", "true"
;   "EI"   -> "false", "true"
;   "PS"   -> "false", "true"
;   "EPIC"   -> "false", "true"
;   "microphone"   -> "false", "true"
;
global PACurState := Map(
    "PA", "",
    "VPN", "",
    "EI", "",
    "PS", "",
    "EPIC", "",
    "power", "",
    "microphone", ""
)




; PAApps is a global object which stores information about all of the
; applications and windows of interest to PACS Assistant.
;
; PAApps is initialized by PAInit(), recording all of the apps defined in App[].
;
global PAApps := Map()


; App is a Map which stores information about all the windows that belong to;
; specific application. 
;
; The following are valid keys for PAWins:
;
;	"A"     - id "PA", PACS Assistant
;	"V"     - id "VPN", Cisco VPN
;	"E"     - id "EI", Agfa EI
;	"F"     - id "EICLIN", Agfa EI ClinApps
;	"P" 	- id "PS", PowerScribe
;	"S" 	- id "PSSPELL", PowerScribe Spelling Window
;	"H" 	- id "EPIC", Epic Hyperspace
;	"D"     - id "DCAD", DynaCAD Prostate and Breast
;	"B"     - id "DCADSTUDY", DynaCAD Prostate and Breast
;	"L"     - id "DLUNG", DynaCAD Lung
;
;
global App := Map()

App["A"] := AppItem("A", "PA", "AutoHotkey64.exe", "PACS Assistant", "PACS Assistant")
App["V"] := AppItem("V", "VPN", "vpnui.exe", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Preferences")
App["E"] := AppItem("E", "EI", "javaw.exe", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging")
App["F"] := AppItem("F", "EICLIN", "javawClinapps.exe", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging")
App["P"] := AppItem("P", "PS", "Nuance.PowerScribe360.exe", "PowerScribe 360", "PowerScribe", "Disable speech")
App["S"] := AppItem("P", "PS", "natspeak.exe", "PowerScribe 360 Spelling Window", "Spelling Window", "Spelling")
App["H"] := AppItem("H", "EPIC", "Hyperdrive.exe", "Hyperspace – Production (PRD)", "Production")
App["D"] := AppItem("D", "DCAD", "StudyManager.exe", "DynaCAD", "Login")
App["B"] := AppItem("B", "DCADSTUDY", "MRW.exe", "DynaCAD Study", "")
App["L"] := AppItem("L", "DLUNG", "MeVisLabApp.exe", "DynaCAD Lung", "DynaCAD Lung - Main")


; Add known windows of interest belonging to each app.
; Okay to add the main window with a different key

; for Cisco VPN
App["V"].Win["m"] := WinItem(App["V"], "m", "main", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Preferences")
App["V"].Win["p"] := WinItem(App["V"], "p", "prefs", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Export Stats")
App["V"].Win["l"] := WinItem(App["V"], "l", "login", "Cisco AnyConnect |", "Cisco AnyConnect |", "Username")
App["V"].Win["o"] := WinItem(App["V"], "o", "otp", "Cisco AnyConnect |", "Cisco AnyConnect |", "Answer")
App["V"].Win["c"] := WinItem(App["V"], "c", "connected", "Cisco AnyConnect", "Cisco AnyConnect", "Security policies")

; for Agfa EI
App["E"].Win["l"] := WinItem(App["E"], "l", "login", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging")
App["E"].Win["d"] := WinItem(App["E"], "d", "desktop", "Diagnostic Desktop - 8.2.2.062  - mivcsp.adventhealth.com - AHEIAE1", "Diagnostic Desktop - 8", , EIOpen_EIdesktop, EIClose_EIdesktop)
App["E"].Win["1"] := WinItem(App["E"], "1", "images1", "Diagnostic Desktop - Images (1 of 2)", "Diagnostic Desktop - Images (1")
App["E"].Win["2"] := WinItem(App["E"], "2", "images2", "Diagnostic Desktop - Images (2 of 2)", "Diagnostic Desktop - Images (2")
App["E"].Win["4"] := WinItem(App["E"], "4", "4dm" ,"4DM(Enterprise Imaging) v2017", "4DM", , "Corridor4DM.exe")
App["E"].Win["c"] := WinItem(App["E"], "c", "collaborator", "Collaborator", "Collaborator")
; pseudowindows
App["E"].Win["w"] := WinItem(App["E"], "w", "listpage", "Desktop List page", , , , , App["E"].Win["d"])
App["E"].Win["t"] := WinItem(App["E"], "t", "textpage", "Desktop Text page", , , , , App["E"].Win["d"])
App["E"].Win["s"] := WinItem(App["E"], "s", "searchpage", "Desktop Search page", , , , , App["E"].Win["d"])

; for Agfa ClinApps (e.g. MPR)
App["E"].Win["r"] := WinItem(App["E"], "r", "mpr", "IMPAX Volume Viewing 3D + MPR Viewing", "IMPAX Volume")

; for PowerScribe
App["P"].Win["l"] := WinItem(App["P"], "l", "login", "PowerScribe 360 | Reporting", "PowerScribe", "Disable speech", PSOpen_PSlogin)
App["P"].Win["m"] := WinItem(App["P"], "m", "main", "PowerScribe 360 | Reporting", "PowerScribe", "Signing queue", PSOpen_PSmain, PSClose_PSmain)
App["P"].Win["r"] := WinItem(App["P"], "r", "report", "PowerScribe 360 | Reporting", "PowerScribe", "Report -", PSOpen_PSreport, PSClose_PSreport)
App["P"].Win["a"] := WinItem(App["P"], "a", "addendum", "PowerScribe 360 | Reporting", "PowerScribe", "Addendum -", PSOpen_PSreport, PSClose_PSreport)
App["P"].Win["o"] := WinItem(App["P"], "o", "logout", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you wish to log off the application?", PSOpen_PSlogout)
App["P"].Win["s"] := WinItem(App["P"], "s", "savespeech", "PowerScribe 360 | Reporting", "PowerScribe", "Your speech files have changed. Do you wish to save the changes?", PSOpen_PSsavespeech)
App["P"].Win["p"] := WinItem(App["P"], "p", "savereport", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to save the changes to the", PSOpen_PSsavereport)
App["P"].Win["d"] := WinItem(App["P"], "d", "deletereport", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to delete", PSOpen_PSdeletereport)
App["P"].Win["u"] := WinItem(App["P"], "u", "unfilled", "PowerScribe 360 | Reporting", "PowerScribe", "This report has unfilled fields. Are you sure you wish to sign it?", PSOpen_PSunfilled)
App["P"].Win["c"] := WinItem(App["P"], "c", "confirmaddendum", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create an addendum", PSOpen_PSconfirmaddendum)
App["P"].Win["e"] := WinItem(App["P"], "e", "confirmanotheraddendum", "PowerScribe 360 | Reporting", "PowerScribe", "Do you want to create another addendum", PSOpen_PSconfirmanotheraddendum)
App["P"].Win["x"] := WinItem(App["P"], "x", "existing", "PowerScribe 360 | Reporting", "PowerScribe", "is associated with an existing report", PSOpen_PSexisting)
App["P"].Win["b"] := WinItem(App["P"], "b", "continue", "PowerScribe 360 | Reporting", "PowerScribe", "Do you wish to continue editing", PSOpen_PScontinue)
App["P"].Win["w"] := WinItem(App["P"], "w", "ownership", "PowerScribe 360 | Reporting", "PowerScribe", "Are you sure you want to acquire ownership", PSOpen_PSownership)
App["P"].Win["i"] := WinItem(App["P"], "i", "microphone", "PowerScribe 360 | Reporting", "PowerScribe", "Your microphone is disconnected", PSOpen_PSmicrophone)
App["P"].Win["f"] := WinItem(App["P"], "f", "find", "Find and Replace", "Find and", , PSOpen_PSfind)

; for PowerScribe spelling window
App["S"].Win["s"] := WinItem(App["P"], "g", "spelling", "Spelling Window", "Spelling", , "natspeak.exe", PSOpen_PSspelling)

; for Epic
App["E"].Win["m"] := WinItem(App["E"], "m", "main", "Hyperspace – Production (PRD)", "Production", , EPICOpened_EPICmain, EPICClosed_EPICmain)
App["E"].Win["c"] := WinItem(App["E"], "c", "chat", "Secure Chat", "Secure Chat")
; pseudowindows, parent is main window App["E"].Win["m"]
App["E"].Win["l"] := WinItem(App["E"], "l", "login", "Hyperspace - login", , , , , App["E"].Win["m"])
App["E"].Win["t"] := WinItem(App["E"], "t", "timezone", "Hyperspace - time zone", , , , , App["E"].Win["m"])
App["E"].Win["m"] := WinItem(App["E"], "m", "main chart", "Hyperspace - chart", , , , , App["E"].Win["m"])



; PAWindows["DCAD"]["keys"] := ["login", "main", "study"]
; PAWindows["DCAD"]["login"] := WindowItem("DCAD", "login", "Login", "Login", , "StudyManager.exe")
; PAWindows["DCAD"]["main"] := WindowItem("DCAD", "main", "Philips DynaCAD", "Philips DynaCAD", , "StudyManager.exe")
; PAWindows["DCAD"]["study"] := WindowItem("DCAD", "study", , , , "MRW.exe")

; PAWindows["DLUNG"]["keys"] := ["login", "main", "second"]
; PAWindows["DLUNG"]["login"] := WindowItem("DLUNG", "login", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
; PAWindows["DLUNG"]["main"] := WindowItem("DLUNG", "main", "DynaCAD Lung - Main Screen", "DynaCAD Lung - Main", , "MeVisLabApp.exe")
; PAWindows["DLUNG"]["second"] := WindowItem("DLUNG", "second", "DynaCAD Lung - Second Screen", "DynaCAD Lung - Second", , "MeVisLabApp.exe")

