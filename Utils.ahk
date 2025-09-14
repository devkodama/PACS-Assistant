/**
 * Utils.ahk
 * 
 * Utility functions
 *
 *
 *
 * This module defines the functions:
 * 
 *  TTip(message, duration := 5000)                     - Displays a tooltip.
 * 
 *  StrJoin(arr, delimiter := "", OmitChars := "")      - Joins an array of strings into a single string and returns it.
 * 
 *  EscapeHTML(Text)                                    - Escapes characters "&, "<", ">", and single and double quotes from a string
 *                                                          and returns the escaped string.
 * 
 *  StdoutToVar(sCmd, sDir:="", sEnc:="CP0")            - Function to run a command line command and return its output as an
 *                                                          object of the form {Output: sOutput, ExitCode: nExitCode}
 *
 *  VersionStringIsValid(version)           - Returns true if version string is a valid semantic version string.
 * 
 *  MD5StringIsValid(filename)              - Return a string containing the MD5 checksum of 
 *                                          - the specified file, or "" on failure.
 * 
 *  ComputeChecksum(filename)               - Return a string containing the MD5 checksum of the specified file, 
 *                                          - or "" on failure.
 * 
 */


; Displays a tooltip.
;
; Can set the duration (ms) before the tooltip is hidden. The default is 5 seconds.
;
TTip(message, duration := 5000) {
	static currentmessage := ""

	if SubStr(message, 1, 1) = "+" {
		currentmessage := currentmessage . SubStr(message, 2)
	} else {
		currentmessage := message
	}
	
	ToolTip currentmessage
	SetTimer ToolTip, -duration
}


; Joins an array of strings into a single string and returns it.
;
; Can specify a delimiter.
;
; Can specify characters to trim from the beginning and end of each string before joining.
;
StrJoin(arr, delimiter := "", OmitChars := "") {

    string := Trim(arr[1],OmitChars)
    i := 1
    while i++ < arr.Length {
        string .= delimiter . Trim(arr[i],OmitChars)
    } 
	return string
}


; Escapes characters "&, "<", ">", and single and double quotes from a string
; and returns the escaped string.
;
EscapeHTML(Text) {
    return StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(Text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "`"", "&quot;"), "'", "&#039;")
}


; not used?
;
; GetCMDOutput(command){
; 	Shell := ComObject("WScript.Shell")
; 	exec := Shell.Exec(A_ComSpec " /C " command)
; 	return exec.StdOut.ReadAll()
; }


; Function to run a command line command and return its output as an
;   object of the form {Output: sOutput, ExitCode: nExitCode}
;
; from https://www.autohotkey.com/boards/viewtopic.php?style=8&p=485576
;
; see also https://github.com/cocobelgica/AutoHotkey-Util/blob/master/StdOutToVar.ahk for v1
; see also https://www.autohotkey.com/docs/v2/lib/Run.htm#ExStdOut
; see also https://www.autohotkey.com/boards/viewtopic.php?p=345039#p345039
;
StdoutToVar(sCmd, sDir:="", sEnc:="CP0") {
    ; Create 2 buffer-like objects to wrap the handles to take advantage of the __Delete meta-function.
    oHndStdoutRd := { Ptr: 0, __Delete: delete(this) => DllCall("CloseHandle", "Ptr", this) }
    oHndStdoutWr := { Base: oHndStdoutRd }
    
    If !DllCall( "CreatePipe"
               , "PtrP" , oHndStdoutRd
               , "PtrP" , oHndStdoutWr
               , "Ptr"  , 0
               , "UInt" , 0 )
        Throw OSError(,, "Error creating pipe.")
    If !DllCall( "SetHandleInformation"
               , "Ptr"  , oHndStdoutWr
               , "UInt" , 1
               , "UInt" , 1 )
        Throw OSError(,, "Error setting handle information.")

    PI := Buffer(A_PtrSize == 4 ? 16 : 24,  0)
    SI := Buffer(A_PtrSize == 4 ? 68 : 104, 0)
    NumPut( "UInt", SI.Size,          SI,  0 )
    NumPut( "UInt", 0x100,            SI, A_PtrSize == 4 ? 44 : 60 )
    NumPut( "Ptr",  oHndStdoutWr.Ptr, SI, A_PtrSize == 4 ? 60 : 88 )
    NumPut( "Ptr",  oHndStdoutWr.Ptr, SI, A_PtrSize == 4 ? 64 : 96 )

    If !DllCall( "CreateProcess"
               , "Ptr"  , 0
               , "Str"  , sCmd
               , "Ptr"  , 0
               , "Ptr"  , 0
               , "Int"  , True
               , "UInt" , 0x08000000
               , "Ptr"  , 0
               , "Ptr"  , sDir ? StrPtr(sDir) : 0
               , "Ptr"  , SI
               , "Ptr"  , PI )
        Throw OSError(,, "Error creating process.")

    ; The write pipe must be closed before reading the stdout so we release the object.
    ; The reading pipe will be released automatically on function return.
    oHndStdOutWr := ""

    ; Before reading, we check if the pipe has been written to, so we avoid freezings.
    nAvail := 0, nLen := 0
    While DllCall( "PeekNamedPipe"
                 , "Ptr"   , oHndStdoutRd
                 , "Ptr"   , 0
                 , "UInt"  , 0
                 , "Ptr"   , 0
                 , "UIntP" , &nAvail
                 , "Ptr"   , 0 ) != 0
    {
        ; If the pipe buffer is empty, sleep and continue checking.
        If !nAvail && Sleep(100)
            Continue
        cBuf := Buffer(nAvail+1)
        DllCall( "ReadFile"
               , "Ptr"  , oHndStdoutRd
               , "Ptr"  , cBuf
               , "UInt" , nAvail
               , "PtrP" , &nLen
               , "Ptr"  , 0 )
        sOutput .= StrGet(cBuf, nLen, sEnc)
    }
    
    ; Get the exit code, close all process handles and return the output object.
    DllCall( "GetExitCodeProcess"
           , "Ptr"   , NumGet(PI, 0, "Ptr")
           , "UIntP" , &nExitCode:=0 )
    DllCall( "CloseHandle", "Ptr", NumGet(PI, 0, "Ptr") )
    DllCall( "CloseHandle", "Ptr", NumGet(PI, A_PtrSize, "Ptr") )
    Return { Output: sOutput, ExitCode: nExitCode } 
}


; Returns true if version string is a valid semantic version string.
; Uses regex to match semantic version string, see:
;   https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
;   https://regex101.com/r/Ly7O1x/3/
;
VersionStringIsValid(version) {
    return RegExMatch(version, "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$")
}


; Returns true if version string is a valid MD5 string, i.e. is a 32 digit hex string.
;
MD5StringIsValid(md5) {
    return RegExMatch(md5, "^[a-fA-F0-9]{32}$")
}


; Return a string containing the MD5 checksum of the specified file, or "" on failure.
;
; output of "certutil -hashfile <filename> MD5" looks like:
;   MD5 hash of <filename>:
;   0a4f2d7ef8be58dceb4a0d3b8e745aaf
;   CertUtil: -hashfile command completed successfully.
; on error:
;   CertUtil: -hashfile command FAILED: 0x80070002 (WIN32: 2 ERROR_FILE_NOT_FOUND)
;   CertUtil: The system cannot find the file specified.
;
ComputeChecksum(filename) {

    certutilout := StdoutToVar('cmd.exe /q /c CertUtil -hashfile "' . filename . '" MD5').Output

    if InStr(certutilout, "successfully") && RegExMatch(certutilout, "\n([0-9a-f]+)", &regout) {
            checksum := regout[1]       ; just the checksum digits
    } else {
        checksum := ""
    }

    return checksum
}
