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
WATCHWINDOWS_UPDATE_INTERVAL := 400

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
global PADoubleClickSetting := 400

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




; PAApps is a global Array() which tracks all of the applications of interest
; to PACS Assistant.
;
; PAApps is initialized by PAInit(), recording all of the apps defined in App[].
;
global PAApps := Array()


; Reverse lookup table for determining the app and window given an hwnd
;
; Entries are of the form:
;
;   _HwndLookup[hwnd] := WinItem
;
; Updated every time a window is opened or closed
;
global _HwndLookup := Map()


; App is a Map which stores information about all the windows that belong to;
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
global App := Map()

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

App["PA"].Win["main"] := WinItem(App["PA"], "main", "PACS Assistant", "PACS Assistant")

; for Cisco VPN
App["VPN"].Win["main"] := WinItem(App["VPN"], "main", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Preferences")
App["VPN"].Win["prefs"] := WinItem(App["VPN"], "prefs", "Cisco AnyConnect Secure Mobility Client", "Cisco AnyConnect Secure Mobility Client", "Export Stats")
App["VPN"].Win["login"] := WinItem(App["VPN"], "login", "Cisco AnyConnect |", "Cisco AnyConnect |", "Username")
App["VPN"].Win["otp"] := WinItem(App["VPN"], "otp", "Cisco AnyConnect |", "Cisco AnyConnect |", "Answer")
App["VPN"].Win["connected"] := WinItem(App["VPN"], "connected", "Cisco AnyConnect", "Cisco AnyConnect", "Security policies")

; for Agfa EI
App["EI"].Win["login"] := WinItem(App["EI"], "login", "Agfa HealthCare Enterprise Imaging", "Agfa HealthCare Enterprise Imaging")
App["EI"].Win["d"] := WinItem(App["EI"], "d", "Diagnostic Desktop - 8.2.2.062  - mivcsp.adventhealth.com - AHEIAE1", "Diagnostic Desktop - 8", , EIOpen_EIdesktop, EIClose_EIdesktop)
App["EI"].Win["i1"] := WinItem(App["EI"], "i1", "Diagnostic Desktop - Images (1 of 2)", "Diagnostic Desktop - Images (1")
App["EI"].Win["i2"] := WinItem(App["EI"], "i2", "Diagnostic Desktop - Images (2 of 2)", "Diagnostic Desktop - Images (2")
App["EI"].Win["4dm"] := WinItem(App["EI"], "4dm" ,"4DM(Enterprise Imaging) v2017", "4DM", , "Corridor4DM.exe")
App["EI"].Win["collab"] := WinItem(App["EI"], "collab", "Collaborator", "Collaborator")
; pseudowindows
App["EI"].Win["list"] := WinItem(App["EI"], "list", "Desktop List page", , , , , App["EI"].Win["d"], EIIsList)
App["EI"].Win["text"] := WinItem(App["EI"], "text", "Desktop Text page", , , , , App["EI"].Win["d"], EIIsText)
App["EI"].Win["search"] := WinItem(App["EI"], "search", "Desktop Search page", , , , , App["EI"].Win["d"], EIIsSearch)
App["EI"].Win["image"] := WinItem(App["EI"], "image", "Desktop Image page", , , , , App["EI"].Win["d"], EIIsImage)

; for Agfa ClinApps (e.g. MPR)
App["EICLIN"].Win["mpr"] := WinItem(App["EICLIN"], "mpr", "IMPAX Volume Viewing 3D + MPR Viewing", "IMPAX Volume")

; for PowerScribe
App["PS"].Win["login"] := WinItem(App["PS"], "login", "PowerScribe 360 | Reporting", "PowerScribe", "Disable speech", PSOpen_PSlogin)
App["PS"].Win["main"] := WinItem(App["PS"], "main", "PowerScribe 360 | Reporting", "PowerScribe", "Signing queue", PSOpen_PSmain, PSClose_PSmain)
App["PS"].Win["report"] := WinItem(App["PS"], "report", "PowerScribe 360 | Reporting", "PowerScribe", "Report -", PSOpen_PSreport, PSClose_PSreport)
App["PS"].Win["addendum"] := WinItem(App["PS"], "addendum", "PowerScribe 360 | Reporting", "PowerScribe", "Addendum -", PSOpen_PSreport, PSClose_PSreport)
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

; for PowerScribe spelling window
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

