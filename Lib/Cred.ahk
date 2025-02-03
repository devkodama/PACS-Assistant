/** 
 * Cred.ahk
 *
 * Credentials management using Windows Credential Manager API
 * 
 * Refs:
 *	https://www.autohotkey.com/boards/viewtopic.php?t=116285
 *	https://www.reddit.com/r/AutoHotkey/comments/1051mkc/comment/j3921wj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
 *  https://learn.microsoft.com/en-us/windows/win32/secauthn/credentials-management
 * 
 */


 #Requires AutoHotkey v2.0


; Usage examples:
 
; if !CredWrite("AHK_CredForScript1", "SomeUsername", "SomePassword")
; 	MsgBox "failed to write cred"

; if (cred := CredRead("AHK_CredForScript1"))
; 	MsgBox cred.name "," cred.username "," cred.password
; else
; 	MsgBox "Cred not found"

; if !CredDelete("AHK_CredForScript1")
; 	MsgBox "Failed to delete cred"



; Write username and password to credential name.
; Returns true on success, false on failure.
CredWrite(name, username, password) {
	cred := Buffer(24 + A_PtrSize * 7, 0)
	cbPassword := StrLen(password) * 2
	NumPut("UInt", 1               , cred,  4+A_PtrSize*0) ; Type = CRED_TYPE_GENERIC
	NumPut("Ptr",  StrPtr(name)    , cred,  8+A_PtrSize*0) ; TargetName
	NumPut("UInt", cbPassword      , cred, 16+A_PtrSize*2) ; CredentialBlobSize
	NumPut("Ptr",  StrPtr(password), cred, 16+A_PtrSize*3) ; CredentialBlob
	NumPut("UInt", 3               , cred, 16+A_PtrSize*4) ; Persist = CRED_PERSIST_ENTERPRISE (roam across domain)
	NumPut("Ptr",  StrPtr(username), cred, 24+A_PtrSize*6) ; UserName
	return DllCall("Advapi32.dll\CredWriteW",
		"Ptr", cred, ; [in] PCREDENTIALW Credential
		"UInt", 0,   ; [in] DWORD        Flags
		"UInt" ; BOOL
	)
}

; Delete credential name.
; Returns true on success, false on failure.
CredDelete(name) {
	return DllCall("Advapi32.dll\CredDeleteW",
		"WStr", name, ; [in] LPCWSTR TargetName
		"UInt", 1,    ; [in] DWORD   Type
		"UInt", 0,    ; [in] DWORD   Flags
		"UInt" ; BOOL
	)
}

; Read username and password under credential name.
; Returns a Map of form {name: name, username: username, password: password}
CredRead(name) {
	pCred := 0
	DllCall("Advapi32.dll\CredReadW",
		"Str",  name,   ; [in]  LPCWSTR      TargetName
		"UInt", 1,      ; [in]  DWORD        Type = CRED_TYPE_GENERIC (https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala)
		"UInt", 0,      ; [in]  DWORD        Flags
		"Ptr*", &pCred, ; [out] PCREDENTIALW *Credential
		"UInt" ; BOOL
	)
	if !pCred
		return
	name := StrGet(NumGet(pCred, 8 + A_PtrSize * 0, "UPtr"), 256, "UTF-16")
	username := StrGet(NumGet(pCred, 24 + A_PtrSize * 6, "UPtr"), 256, "UTF-16")
	len := NumGet(pCred, 16 + A_PtrSize * 2, "UInt")
	password := StrGet(NumGet(pCred, 16 + A_PtrSize * 3, "UPtr"), len/2, "UTF-16")
	DllCall("Advapi32.dll\CredFree", "Ptr", pCred)
	return {name: name, username: username, password: password}
}
