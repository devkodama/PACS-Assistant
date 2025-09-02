/**
 * Network.ahk
 * 
 * Functions for detecting and making network connections, including VPN connections
 * 
 *
 *
 * This module defines the functions:
 * 
 *  NetworkGetHostName(forceupdate := false)	- Returns the host name (computer name) of this workstation
 *  NetworkGetIP(forceupdate := false)			- Returns the current IPv4 address of this workstation
 * 
 *  WorkstationIsHospital(forceupdate := false)	- Returns whether we are on a hospital workstation
 * 	VPNIsConnected(forceupdate := false)		- Returns the connection status of the Cisco VPN
 * 
 *  NetworkIsConnected(forceupdate := false)	- Returns whether we have an appropriate network connection,
 * 													either direct (hospital) or VPN (home)
 *
 * 	VPNOpen_VPNmain()							- Callback
 * 
 * 	VPNStart(cred := CurrentUserCredentials)	- Connects the Cisco AnyConnect VPN
 * 	VPNStop()									- Disconnects the Cisco AnyConnect VPN
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force





/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * Functions to interact with VPN client
 * 
 */




/**********************************************************
 * Functions to retrieve info about the network and vpn
 * 
 */


; Returns the host name (computer name) of this workstation
;
NetworkGetHostName() {
	hostname := StrUpper(Trim(StdoutToVar('hostname').Output))
	return hostname
}


; Returns the current IPv4 address of this workstation
; 
; Empty string is returned if no ip address
;
NetworkGetIP() {

	cmdout := StdoutToVar('ipconfig').Output

	; there can be multiple host adapters
	; use the first ipv4 address found, this seems to be the correct one
	if RegExMatch(cmdout, "IPv4 Address.+:\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)", &regout) {
		ipv4 := regout[1]
	} else {
		ipv4 := ""
	}

	return ipv4
}
 

; Returns whether we are on a hospital workstation.
;
; Connected status is cached, checked every WATCHNETWORK_UPDATE_INTERVAL,
; unless forceupdate is true.
;
WorkstationIsHospital(forceupdate := false) {
	static ishospital := false		; cached status
	static lastcheck := 0			; setting lastcheck to 0 initially forces an update on the first call

	if forceupdate || ((A_TickCount - lastcheck) > WATCHNETWORK_UPDATE_INTERVAL) {
		ishospital := false
		
		; check for a matching hostname
		host := NetworkGetHostName()
		if host {
			for prefix in HOSPITAL_WORKSTATIONPREFIXES {
				if InStr(host, prefix, true) {
					; found a match
					ishospital := true
					break			; for
				}
			}
		}

		; if we didn't find a matching hostname, then try checking for a matching ip addresses (subnet)
		if !ishospital {
			; the /24 subnet prefix (xx.xx.xx) of the current ip is matched against list of known hospital network prefixes
			ip := NetworkGetIP()
			if RegExMatch(ip, "([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+", &regout) {	
				for prefix in HOSPITAL_SUBNETPREFIXES {		
					if regout[1] == prefix {
						ishospital := true
						break			; for
					}
				}
			} 
		}

		lastcheck := A_TickCount
	}
	return ishospital
}


; Returns the connection status of the Cisco VPN
;
; Returns TRUE if connected, FALSE if not
;
; Connected status is cached, checked every WATCHNETWORK_UPDATE_INTERVAL,
; unless forceupdate is true.
;
VPNIsConnected(forceupdate := false) {
	static vpnstatus := false	; cached status
	static lastcheck := 0		; setting lastcheck to 0 initially forces an update on the first call

	if forceupdate || ((A_TickCount - lastcheck) > WATCHNETWORK_UPDATE_INTERVAL) {
		vpnstatus := InStr(StdoutToVar('"' . EXE_VPNCLI . '" state').Output, "state: Connected") ? true : false
		lastcheck := A_TickCount
	}
	return vpnstatus
}


; Returns whether we have an appropriate network connection,
; either direct (hospital) or VPN (home).
;
; Returns TRUE if so, FALSE if not.
;
; Connected status is cached, checked every WATCHNETWORK_UPDATE_INTERVAL,
; unless forceupdate is true.
;
NetworkIsConnected(forceupdate := false) {
	static networkstatus := false	; cached status
	static lastcheck := 0			; setting lastcheck to 0 initially forces an update on the first call

	if forceupdate || ((A_TickCount - lastcheck) > WATCHNETWORK_UPDATE_INTERVAL) {

		if WorkstationIsHospital(forceupdate) {
			if NetworkGetIP() {
				networkstatus := true
			} else {
				networkstatus := false
			}
		} else {
			networkstatus := VPNIsConnected(forceupdate)
		}

		lastcheck := A_TickCount
	}
	return networkstatus
}




/**********************************************************
 * Callback functions called on Network window events
 */


VPNShow_main(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["main"].hwnd := hwnd

	; crit := hook.MatchCriteria[1]
	; text := hook.MatchCriteria[2]
	; TTip("VPNShow_main(" hwnd ": ('" crit "','" text "') <=" WinItem.LookupHwnd(hwnd).appkey "/" WinItem.LookupHwnd(hwnd).key)
	; PlaySound("VPN show main")

	if Setting["VPN_center"].enabled {
		; center on the current monitor
		App["VPN"].Win["main"].CenterWindow()
	}
}

VPNClose_main(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["main"].hwnd := 0
}


; Callback function when VPN main window is shown
VPNShow_prefs(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["prefs"].hwnd := hwnd

	; crit := hook.MatchCriteria[1]
	; text := hook.MatchCriteria[2]
	; TTip("VPNShow_prefs(" hwnd ": ('" crit "','" text "') <=" WinItem.LookupHwnd(hwnd).appkey "/" WinItem.LookupHwnd(hwnd).key)
	; PlaySound("VPN show prefs")
}

VPNClose_prefs(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["main"].hwnd := 0
}


; Callback function when VPN login window is shown
VPNShow_login(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["login"].hwnd := hwnd

	; crit := hook.MatchCriteria[1]
	; text := hook.MatchCriteria[2]
	; TTip("VPNShow_login(" hwnd ": ('" crit "','" text "') <=" WinItem.LookupHwnd(hwnd).appkey "/" WinItem.LookupHwnd(hwnd).key)
	; PlaySound("VPN show login")
}

VPNClose_login(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["login"].hwnd := 0
}


; Callback function when VPN otp window is shown
VPNShow_otp(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["otp"].hwnd := hwnd

	; crit := hook.MatchCriteria[1]
	; text := hook.MatchCriteria[2]
	; TTip("VPNShow_otp(" hwnd ": ('" crit "','" text "') <=" WinItem.LookupHwnd(hwnd).appkey "/" WinItem.LookupHwnd(hwnd).key)
	; PlaySound("VPN show otp")
}

VPNClose_otp(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["otp"].hwnd := 0
}


; Callback function when VPN connected window is shown
VPNShow_connected(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["connected"].hwnd := hwnd

	; crit := hook.MatchCriteria[1]
	; text := hook.MatchCriteria[2]
	; TTip("VPNShow_connected(" hwnd ": ('" crit "','" text "') <=" WinItem.LookupHwnd(hwnd).appkey "/" WinItem.LookupHwnd(hwnd).key)
	; PlaySound("VPN show connected")
}

VPNClose_connected(hwnd, hook, dwmsEventTime) {
	App["VPN"].Win["connected"].hwnd := 0
}





/**********************************************************
 * Start up and Shut down functions
 * 
 */


; Connects the Cisco AnyConnect VPN
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If already connected, returns immediately (without using credentials)
; with return value 1.
;
; If not connected, uses cred to establish a VPN connection.
; The parameter cred is an object with username and password properties.
;
; Periodically checks PACancelRequest to see if it should cancel the 
; connection attempt and quit.
;
; Returns 1 once connection is successful, 0 if unsuccessful (e.g.
;  after timeout or if user cancels).
; 
VPNStart(cred := CurrentUserCredentials) {
	global PAWindowBusy
	global PACancelRequest
	static running := false			; true if the VPNConnect is already running

	; if VPNStart() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if VPN is already connected, just return true
	if VPNIsConnected(true) {
		GUIStatus("VPN already connected")
		running := false
		return 1
	}

	; close OTP window if currently open, to get back to main vpn window
	hwndotp := App["VPN"].Win["otp"].IsReady()
	if hwndotp {
		ControlClick("Cancel", hwndotp, , , , "NA")
		WinWaitClose(hwndotp)
;		App["VPN"].Update()
	}

	; close login window if open, to get back to main vpn window
	hwndlogin := App["VPN"].Win["login"].IsReady()
	if hwndlogin {
		ControlClick("Cancel", hwndlogin, , , , "NA")
		WinWaitClose(hwndlogin)
;		App["VPN"].Update()
	}

	; don't allow focus following while trying to make a VPN connection
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; if no password, ask user before proceeding
	if !cred.Password && !GUIGetPassword() {
		; couldn't get a password from the user, return failure (0)
        GUIStatus("Could not start VPN - password needed")
		running := false
		return 0
	}

	; loop until connected, timed out, cancelled, or failed too many times
	tick0 := A_TickCount
	connected := false
	cancelled := false
	failedlogins := 0
	runflag := false
	lastdialog := ""
;	trace := ""			;for debugging

	while !connected && !cancelled && (failedlogins < VPN_FAILEDLOGINS_MAX) && (A_TickCount - tick0 < VPN_CONNECT_TIMEOUT * 1000) {

		GUIStatus("Starting VPN... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")

		; look for connected info dialog box
		if hwndconnected := App["VPN"].Win["connected"].IsReady() {
			; close connection info window
			WinClose(hwndconnected)

			; confirm connection (and update connected status)
			connected := VPNIsConnected(true)
			if connected {
				break		; exit while loop
			}
			lastdialog := "connected"
		}

		; look for one time password dialog box
		if hwndotp := App["VPN"].Win["otp"].IsReady() {
			; wait for user to enter otp and/or close window
			WinActivate(hwndotp) 		; focus OTP window
			while (App["VPN"].Win["otp"].IsReady()) && (A_TickCount - tick0 < VPN_CONNECT_TIMEOUT * 1000) {
				GUIStatus("Starting VPN - Please provide one time passcode from the Authenticate app (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				Sleep(500)
;				WinActivate(hwndotp) 		; keep OTP window focused
				if PACancelRequest {
					cancelled := true
					break			; inner while
				}
			}
			lastdialog := "otp"
			continue		; while
		}

		if PACancelRequest {
			cancelled := true
			break			; while
		}

		; look for login dialog box
		if hwndlogin := App["VPN"].Win["login"].IsReady() {
			; Before entering username and password, see if the last login failed.
			; If it failed, we might be on the wrong server, so cancel the login window
			; and return to the main UI so the correct server can be populated.
			; If we've already tried twice, ask the user for another password.
			if hwndmain := App["VPN"].Win["main"].IsReady()  && ControlGetText("Static2", hwndmain) = "Login failed." {
				; Last login failed, keep track of it
				failedlogins++
				ControlClick("Cancel", hwndlogin, , , , "NA")
				WinWaitClose(hwndlogin)
				; if failed more than two times already, ask user for another password before trying again
				if failedlogins >= 2 {
					if GUIGetPassword("Re-enter your password") {
						cred.password := CurrentUserCredentials.password
					} else {
						cancelled := true
					}
				}
			} else {
				; enter username and password and press OK
				BlockInput true
				ControlSetText(cred.username, "Edit1", hwndlogin)
				ControlSetText(cred.password, "Edit2", hwndlogin)
				ControlClick("OK", hwndlogin, , , , "NA") 
				BlockInput false
				WinWaitClose(hwndlogin)
			}
			lastdialog := "login"
			continue
		}

		; look for VPN UI main window
		if hwndmain := App["VPN"].Win["main"].IsReady() {
			; In the VPN UI main window, enter the VPN URL and press connect
			statustext := ControlGetText("Static2", hwndmain)
			if statustext = "Ready to connect." {
				; at this point, if the last dialog box was "otp", then we
				; infer the user clicked the Cancel button so we abort the entire login process
				if lastdialog = "otp" {
					cancelled := true
					break		; exit while
				}
				; user didn't cancel the otp dialog, so enter the vpn url
				BlockInput true
				ControlSetText("", "Edit1", hwndmain)			; need to clear the edit box first
				ControlSendText(Setting["VPN_url"].value, "Edit1", hwndmain)		; set the vpn url
				ControlClick("Button1", hwndmain, , , , "NA")	; click Connect button
				BlockInput false
			} else if InStr(statustext, "Contacting ", true) {
				GUIStatus("Starting VPN - Contacting server " . Setting["VPN_url"].value . "...")
			} else if InStr(statustext, "Login failed", true) {
				GUIStatus("Starting VPN - Incorrect username or password")
			}
			Sleep(300)
			lastdialog := "main"
			continue

		} else {

			; if VPN UI main window does not already exist, try to start it
			; if startup fails after timeout, quit and return failure
			;
			; nb: When the VPN connection is made, the main window self closes 
			; to the system tray, which causes it to no longer exist. 
			; There can be a brief window after it closes and before the
			; connection successful dialog opens when it will look like 
			; the VPN client is not running, and this code branch will be
			; taken. We do not want to run the EXE_VPN again in this scenario,
			; so if runflag says we already ran the client, we just wait briefly
			; then continue.
			if runflag {
				; already executed Run() so just wait
				Sleep(300)
			} else {
				; only want to do this once, we set runflag to true
				runflag := true		
				Run(EXE_VPNUI)

				; wait for main window to be appear
				tick1 := A_TickCount
				while !(hwndmain := App["VPN"].Win["main"].IsReady()) && (A_TickCount - tick1 < VPN_DIALOG_TIMEOUT * 1000) {
					GUIStatus("Starting VPN... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
					Sleep(500)
					if PACancelRequest {
						cancelled := true
						break			; inner while
					}
				}
				if !hwndmain {
					; failed to open main window
					break	; exit while loop
				}
			}
			continue
		}

	}	; while

	GUIHideCancelButton()

	if connected {
		PlaySound("VPNConnected")
		GUIStatus("VPN connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		; if VPN main window is not closed, then close it (to windows tray)
		App["VPN"].Win["main"].Close()
	} else if cancelled {
		GUIStatus("VPN startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else if failedlogins >= VPN_FAILEDLOGINS_MAX {
		GUIStatus("Invalid username/password - VPN could not be connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else {
		GUIStatus("Timeout - VPN could not be connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; restore focus following
	PAWindowBusy := false

	; done
	running := false
	return connected ? 1 : 0
}


; Disconnects the Cisco AnyConnect VPN
;
; Function does not allow reentry. If called again while already running, 
; immediately returns -1.
;
; If already disconnected, returns immediately (without using credentials)
; with return value 1.
;
; Periodically checks PACancelRequest to see if it should cancel the 
; connection attempt and quit.
;
; Returns 1 if disconnection successful, 0 if disconnection fails
; 
VPNStop() {
	global PACancelRequest
	static running := false			; true if the VPNDisconnect is already running

	; if VPNStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if VPN is not connected, immediately return success
	connected := VPNIsConnected(true)
	if !connected {
		GUIStatus("VPN already disconnected")
		running := false
		return 1
	}

	tick0 := A_TickCount
	GUIStatus("Disconnecting VPN...")

	; don't allow focus following
	PAWindowBusy := true

	; allow user to cancel long running operation
	GUIShowCancelButton()

	; run CLI command to disconnect the VPN
	StdoutToVar('"' . EXE_VPNCLI . '" disconnect')
	connected := VPNIsConnected(true)
	while connected && !cancelled && A_TickCount - tick0 < VPN_DISCONNECT_TIMEOUT * 1000 {
		GUIStatus("Disconnecting VPN... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
		Sleep(300)
		connected := VPNIsConnected(true)
		if PACancelRequest {
			cancelled := true
		}
	}

	GUIHideCancelButton()

	if !connected {
		PlaySound("VPNDisconnected")
		GUIStatus("VPN disconnected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else if cancelled {
		GUIStatus("VPN disconnection cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else {
		GUIStatus("Timeout-  VPN could not be disconnected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; restore focus following
	PAWindowBusy := false

	; done
	running := false
	return !connected ? 1 : 0
}
