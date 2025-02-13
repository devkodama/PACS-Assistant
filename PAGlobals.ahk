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


global PAText






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
