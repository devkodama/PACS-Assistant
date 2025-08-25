/**
 * Globals.ahk
 * 
 * Global variables and constants for PACS Assistant
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


;#Include <Cred>




/**********************************************************
 * Global constants
 * 
 * These don't change during program execution
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

; interval (ms) for updating network connection or workstation status
WATCHNETWORK_UPDATE_INTERVAL := 5000       ; 5000 = 5 seconds

; interval (ms) for jiggling mouse to keeping screen awake
JIGGLEMOUSE_UPDATE_INTERVAL := 120000		; 120000 = 2 minutes

; interval (ms) for clearing CapsLock after no keyboard input
CAPSLOCK_TIMEOUT := 10000		; 10000 = 10 sec

; timeout (ms) for clearing status bar text
GUISTATUSBAR_TIMEOUT := 60000	    ; 60000 = 60 sec


; maximum timeout (seconds) for making VPN connection from start to finish
VPN_CONNECT_TIMEOUT := 120
; maximum timeout (seconds) for disconnecting VPN connection
VPN_DISCONNECT_TIMEOUT := 10
; timeout (seconds) for starting up VPN UI (main window)
; or for waiting for initial login window to appear
VPN_DIALOG_TIMEOUT := 10
; number of failed login attempts (username/password failures) allowed
VPN_FAILEDLOGINS_MAX := 5
; VPN URL string
VPN_URL := "vpn.adventhealth.com/SecureAuth"


; timeout (seconds) for starting up EI to get to login window
EI_LOGIN_TIMEOUT := 60
; timeout (seconds) for getting to EI desktop window after login
EI_DESKTOP_TIMEOUT := 120
; timeout (seconds) for allowing Collaborator window to appear after login
EI_COLLABORATOR_TIMEOUT := 30
; timeout (seconds) for shutting down EI
EI_SHUTDOWN_TIMEOUT := 60
; EI server string
EI_SERVER := "mivcsp.adventhealth.com"


; timeout (seconds) for starting up PS to get to login window
PS_LOGIN_TIMEOUT := 60
; timeout (seconds) for getting to PS main window after login
PS_MAIN_TIMEOUT := 180
; timeout (seconds) for shutting down PS
PS_SHUTDOWN_TIMEOUT := 180
; time delay (seconds) for turing off microphone after a report is closed
PS_DICTATEAUTOOFF_DELAY := 3


; timeout (seconds) for starting up EPIC to get to login window
EPIC_LOGIN_TIMEOUT := 120
; timeout (seconds) for shutting down EPIC
EPIC_SHUTDOWN_TIMEOUT := 30
; timezone string for Epic
EPIC_TIMEZONE := "America/Chicago"


; maximum username length
PA_USERNAME_MAXLENGTH := 20
; maximum password length
PA_PASSWORD_MAXLENGTH := 20

; default width and height of PACS Assistant GUI window
PA_DEFAULTWIDTH := 1080
PA_DEFAULTHEIGHT := 350

; minimum width and height to consider a window position valid
WINPOS_MINWIDTH := 100
WINPOS_MINHEIGHT := 100




; Windows constant (style of visible windows)
WS_VISIBLE := 0x10000000

; Windows constants used in PS.ahk module
WM_SETTEXT := 0x000C
WM_GETTEXT := 0x000D
EM_GETSEL := 0x00B0
EM_SETSEL := 0x00B1
EM_SETREADONLY := 0x00CF

; Windows constants used in GUI.ahk module




; Executable paths
; [deprecated] EXE_VPNUI := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe"
; [deprecated] EXE_VPNCLI := "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe"
EXE_VPNUI := "C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe"
EXE_VPNCLI := "C:\Program Files (x86)\Cisco\Cisco Secure Client\vpncli.exe"

EXE_EI := "C:\Program Files (x86)\Agfa\Enterprise Imaging\EnterpriseImagingLauncher.exe"

EXE_PS := "C:\Users\PACS\Desktop\Nuance.PowerScribe360.application"

EXE_EPIC := "C:\Program Files (x86)\Epic\Hyperdrive\VersionIndependent\Hyperspace.exe"
EPIC_CLIOPTIONS := "Id=605 Env=PRD TZ=America/Chicago enableGPU=false"

; Base filneame used to derive settings.ini and setting.username.ini filenames
FILE_SETTINGSBASE := "settings"

; filepath to icd code table
ICD_CODEFILE := "icd10codes.txt"


; Text and color to display when microphone is off
MICROPHONETEXT_OFF := "Microphone Off"
MICROPHONECOLOR_OFF := "#303030"

; Text and color to display when microphone is on
MICROPHONETEXT_ON := "Microphone On"
MICROPHONECOLOR_ON := "#d02020"

; Format to return DOB from patient info
INFO_DOB_FORMAT := "M/d/yyyy"

; PA GUI
GUIWINDOWTITLE := "PACS Assistant"
GUIHOMEPAGE := "pages/PACSAssistant.html"

; Used in Info.ahk. Format for returning DOB from Patient object.
INFO_DOB_FORMAT := "M/d/yyyy"

; Hospital workstation names
; HOSPITAL_WORKSTATIONNAMES := ["ACIDPACRRMA01", "ACIDPACRRMA02", "ACIDPACRRDS02", "BOLDPACRRDS1", "BOLDPACWCMA1", "BOLXRRDS01", "BOLXRRDS02", "GLEDPACRDS1", "HINDPACRRDS01", "HINDPACRRDS02", "HINDPACRRDS03", "HINDPACRRDS05", "HINXNMOFFMA01", "HICDPACRRMA02", "HINXRRDS03", "HINXRRMA02", "HINXRRMA03", "LAGXRRDS02", "LAGXRRDS03", "LAGDPACRRDS01", "LAGDPACRRMA02", "LAGDPACRRDS03", "WMDPACRRDS01"]

; Hospital workstation prefixes
HOSPITAL_WORKSTATIONPREFIXES := ["ACIDP", "BOLDP", "BOLX", "GLEDP", "HINXR", "HINDP", "HINXN", "HICDP", "LAGXR", "LAGDP", "WMDPA"]

; Hospital network /24 subnet prefixes
HOSPITAL_SUBNETPREFIXES := ["172.30.198", "10.136.15"]




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

; This is true at startup and set to false after the first time UpdateAll() is called
global _PAUpdate_Initial := true

; This is false at startup and set to true after the GUI is up and running.
global _GUIIsRunning := false


; the main PACS Assistant GUI
global PAGUI

; Global dispatch queue
global DispatchQueue


; PASettings holds settings used across PACS Assistant.
; Each entry is a {"key", SetItem()} pair. See Settings.ahk for Setting
; class and PASettings[] definitions.
global Setting


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
    "Network", "",
    "EI", "",
    "PS", "",
    "EPIC", "",
    "power", "",
    "microphone", ""
)



; App is a Map which stores information about all the windows that belong to a
; specific application. See AppManager.ahk for more info.
global App := Map()


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



; Sounds map maps PA events to voice or audio feedback
Sounds := Map()

Sounds["VPNConnected"] := SoundItem("VPN connected")
Sounds["VPNDisconnected"] := SoundItem("VPN disconnected")

Sounds["PSTab"] := SoundItem( , [440, 10])
Sounds["PSToggleMic"] := SoundItem( , 392)

Sounds["PSSignReport"] := SoundItem("Signed", , "Report signed")
Sounds["PSDraftReport"] := SoundItem("Draft saved", , "Report saved as Draft")
Sounds["PSSPreliminary"] := SoundItem("Preliminary saved", , "Report saved as Preliminary")

Sounds["EIStartReading"] := SoundItem( , 480)
Sounds["EIClickLockOn"] := SoundItem(, [1000, 100])
Sounds["EIClickLockOff"] := SoundItem(, [600, 100])

Sounds["EPIC"] := SoundItem("EPIC was clicked")



; PAText holds a dictionary of strings for the FindText function.
; Strings are defined in the FindTextStrings.ahk module.
global PAText := Map()



; Holds the icd-10 lookup table. See ICDCode.ahk.
global ICDCodeTable



