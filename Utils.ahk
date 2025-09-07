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
 *  SetTray(version := "")                              - Redefines the tray menu and tray tooltip
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


; Replaces the system tray icon menu.
;
; Copied from https://github.com/Nigh/ahk-autoupdate-template/blob/main/tray.ahk
SetTray(version := "") {
	
    ; returns a function that runs the specified webpage
    gotoWebpage_maker(url) {
        webpage(*) {
            Run(url)
        }
        return webpage
    }

    ; exit the application
	quit_pa(*) {
TTip("Quit PACS Assistant")
;		trueExit("", "")
	}

    ; If not passed as a parameter, get the current version for display from the version.txt file.
    if !version {
        try {
            version := FileRead("version.txt")
            version := SubStr(version, 1, 20)       ; limit to 20 chars
        } catch {
            version := "missing version.txt" 
        }
    }
    
    ; create the tray menu
	tray := A_TrayMenu

;    tray.delete

;	tray.add("v" . version, (*) => {})

    tray.add()
	tray.add("Github ahk-autoupdate-template", gotoWebpage_maker("https://github.com/Nigh/ahk-autoupdate-template"))
;	tray.add("Other", other_callback(ItemName, ItemPos, MenuRef))

    tray.add()
	tray.add("Quit PACS Assistant", quit_pa)
	tray.ClickCount := 1

    ; set tray icon's tooltip
    A_IconTip := "PACS Assistant`n" version

}