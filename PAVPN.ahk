/**
 * PAVPN.ahk
 * 
 * Functions for working with Cisco AnyConnect VPN
 *
 *
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <FindText>
#Include PAFindTextStrings.ahk

#Include PAGlobals.ahk
#Include PASound.ahk




/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * Functions to send info
 * 
 */




/**********************************************************
 * Functions to retrieve info about the VPN
 */


; Returns the connection status of the Cisco VPN
;
; Returns TRUE if connected, FALSE if not
;
; Connected status is cached, checked every WATCHVPN_UPDATE_INTERVAL,
; unless forceupdate is true.
;
VPNIsConnected(forceupdate := false) {
	static vpnstatus := false
	static lastcheck := 0		; setting lastcheck to 0 initially forces an update on the first call

	if forceupdate || ((A_TickCount - lastcheck) > WATCHVPN_UPDATE_INTERVAL) {
		vpnstatus := InStr(StdoutToVar('"' . EXE_VPNCLI . '" state').Output, "state: Connected") ? true : false
		lastcheck := A_TickCount
	}
	return vpnstatus
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
		PAStatus("VPN already connected")
		running := false
		return 1
	}

	; close OTP window if open, to get back to main vpn window
	hwndotp := WinExist(PAWindows["VPN"]["otp"].criteria, PAWindows["VPN"]["otp"].wintext)
	if hwndotp {
		ControlClick("Cancel", hwndotp, , , , "NA")
		WinWaitClose(hwndotp)
		PAWindows.Update("VPN")
	}

	; close login window if open, to get back to main vpn window
	hwndlogin := WinExist(PAWindows["VPN"]["login"].criteria, PAWindows["VPN"]["login"].wintext)
	if hwndlogin {
		ControlClick("Cancel", hwndlogin, , , , "NA")
		WinWaitClose(hwndlogin)
		PAWindows.Update("VPN")
	}

	; don't allow focus following while trying to make a VPN connection
	PAWindowBusy := true

	PAGui_ShowCancelButton()

	; loop until connected, timed out, cancelled, or failed too many times
	tick0 := A_TickCount
	connected := false
	cancelled := false
	failedlogins := 0
	runflag := false
	lastdialog := ""
;	trace := ""			;for debugging

	while !connected && !cancelled && (failedlogins < VPN_FAILEDLOGINS_MAX) && (A_TickCount - tick0 < VPN_CONNECT_TIMEOUT * 1000) {

		PAStatus("Starting VPN... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")

		; look for connected info dialog box
		hwndconnected := WinExist(PAWindows["VPN"]["connected"].criteria, PAWindows["VPN"]["connected"].wintext)
		if hwndconnected {
			; close connection info window
			WinClose(hwndconnected)
			PAWindows.Update("VPN")

			; confirm connection (and update connected status cache)
			connected := VPNIsConnected(true)
			if connected {
				break		; exit while loop
			}

			; lastdialog := "connected"
		}

		; look for one time password dialog box
		hwndotp := WinExist(PAWindows["VPN"]["otp"].criteria, PAWindows["VPN"]["otp"].wintext)
		if hwndotp {
			; wait for user to enter otp and/or close window
			PAStatus("Starting VPN - Please provide one time passcode from the Authenticate app")
			while (WinExist(PAWindows["VPN"]["otp"].criteria, PAWindows["VPN"]["otp"].wintext)) && (A_TickCount - tick0 < VPN_CONNECT_TIMEOUT * 1000) {
				PAStatus("Starting VPN - Please provide one time passcode from the Authenticate app (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
				Sleep(500)
				try {
					WinActivate(hwndotp) 		; keep OTP window focused
				} catch {
				}
				if PACancelRequest {
					cancelled := true
					break			; inner while
				}
			}
			PAWindows.Update("VPN")
			lastdialog := "otp"
			continue		; while
		}

		if PACancelRequest {
			cancelled := true
		}

		; look for login dialog box
		hwndlogin := WinExist(PAWindows["VPN"]["login"].criteria, PAWindows["VPN"]["login"].wintext)
		if hwndlogin {
			; before entering username and password, see if the last login failed
			; if it failed, we might be on the wrong server, so cancel the login window
			; and return to the main UI so the correct server can be populated
			hwndmain := WinExist(PAWindows["VPN"]["main"].criteria, PAWindows["VPN"]["main"].wintext)
			if hwndmain && ControlGetText("Static2", hwndmain) = "Login failed." {
				failedlogins++
				ControlClick("Cancel", hwndlogin, , , , "NA")
				WinWaitClose(hwndlogin)
				PAWindows.Update("VPN")
			} else {
				; enter username and password and press OK
				BlockInput true
				ControlSetText(cred.username, "Edit1", hwndlogin)
				ControlSetText(cred.password, "Edit2", hwndlogin)
				ControlClick("OK", hwndlogin, , , , "NA") 
				BlockInput false
				WinWaitClose(hwndlogin)
				PAWindows.Update("VPN")
			}
			lastdialog := "login"
			continue
		}

		; look for VPN UI main window
		hwndmain := WinExist(PAWindows["VPN"]["main"].criteria, PAWindows["VPN"]["main"].wintext)
		if hwndmain {
			; In the VPN UI main window, enter the VPN URL and press connect
			statustext := ControlGetText("Static2", hwndmain)
			if statustext = "Ready to connect." {
				; at this point, if the last dialog box was "otp", then we
				; infer the user clicked the Cancel button so we abort the entire login process
				if lastdialog = "otp" {
					cancelled := true
					break		; exit while
				}
				BlockInput true
				ControlSetText("", "Edit1", hwndmain)
				ControlSendText(VPN_URL, "Edit1", hwndmain)
				ControlClick("Connect", hwndmain, , , , "NA")
				BlockInput false
			} else if InStr(statustext, "Contacting ", true) {
				PAStatus("Starting VPN - Contacting server " . VPN_URL . "...")
			} else if InStr(statustext, "Login failed", true) {
				PAStatus("Starting VPN - Incorrect username or password")
			}
			Sleep(300)
			lastdialog := "main"
			continue

		} else {

			; if VPN UI main window does not already exist, try to start it
			; if startup fails after timeout, quit and return failure
			;
			; When the VPN connection is made, the main window self closes 
			; to the system tray, which causes it to no longer exist. 
			; There can be a brief window after it closes and before the
			; connection successful dialog opens when it will look like 
			; the VPN client is not running, and this code branch will be
			; taken. We do not want to run the EXE_VPN again in this scenario,
			; so we wait briefly then continue.

			if runflag {
				Sleep(300)
			} else {
				; only want to do this once, we set runflag to true
				runflag := true		
				Run(EXE_VPN)
				PAWindows.Update("VPN")

				; wait for main window to be appear
				tick1 := A_TickCount
				while !(hwndmain := PAWindows["VPN"]["main"].hwnd) && (A_TickCount - tick1 < VPN_DIALOG_TIMEOUT * 1000) {
					PAStatus("Starting VPN... (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
					Sleep(500)
					PAWindows.Update("VPN")
trace .= "(w:" . A_TickCount-tick1 . ")"
					if PACancelRequest {
						cancelled := true
						break			; inner while
					}
				}
				if !hwndmain {
					; failed to open main window
					break	; exit while loop
				}
				PAWindows.Update("VPN")
			}

			continue
		}

	}	; while

	PAGui_HideCancelButton()

	if connected {
		PAStatus("VPN connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else if cancelled {
		PAStatus("VPN startup cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else if failedlogins >= VPN_FAILEDLOGINS_MAX {
		PAStatus("Invalid username/password - VPN could not be connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else {
		PAStatus("Timeout - VPN could not be connected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

;	MsgBox(trace)

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
; Returns 1 if disconnected, 0 if disconnection fails
; 
VPNStop() {
	global PACancelRequest
	static running := false			; true if the VPNDisconnect is already running
	static tick0 := A_TickCount

	; if VPNStop() is already running, don't run another instance
	if running {
		return -1
	}
	running := true

	; if VPN is alraedy connected, immediately return success
	connected := VPNIsConnected(true)
	if !connected {
		PAStatus("VPN already disconnected")
		running := false
		return 1
	}

	PAStatus("Disconnecting VPN...")
	PAGui_ShowCancelButton()

	; run CLI command to disconnect the VPN
	vpnstate := StdoutToVar('"' . EXE_VPNCLI . '" disconnect').Output
	connected := VPNIsConnected(true)
	
	tick0 := A_TickCount
	while connected && !cancelled && A_TickCount - tick0 < VPN_DISCONNECT_TIMEOUT * 1000 {
		Sleep(500)
		connected := VPNIsConnected(true)
		if PACancelRequest {
			cancelled := true
		}
	}

	PAGui_HideCancelButton()

	if !connected {
		PAStatus("VPN disconnected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else if cancelled {
		PAStatus("VPN disconnection cancelled (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	} else {
		PAStatus("Timeout-  VPN could not be disconnected (elapsed time " . Round((A_TickCount - tick0) / 1000, 0) . " seconds)")
	}

	; done
	running := false
	return !connected ? 1 : 0
}

