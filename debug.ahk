/* Debug.ahk
**
** Debug code helpers
**
**
*/






; Reloads the current script whenever script files are saved (Ctrl-S) 
; in one of the specified code editors
;
; see: Editing a script in almost real time
; https://www.reddit.com/r/AutoHotkey/comments/1hbgbj7/editing_a_script_in_almost_real_time/?share_id=1_iI6NRPimVBnqpTKZsCo&utm_medium=ios_app&utm_name=iossmf&utm_source=share&utm_term=10
;

#HotIf WinActive('ahk_exe code.exe')

~^s:: {
    ; stop daemons
    InitDaemons(false)

    ; stop windows "Close" event callbacks
    WinEvent.Stop("Close")

    PAToolTip("Reloading script " A_ScriptName " in 3 seconds...")
    Sleep(1000)
    PAToolTip("Reloading script " A_ScriptName " in 2 seconds...")
    Sleep(1000)
    PAToolTip("Reloading script " A_ScriptName " in 1 second...")
    Sleep(1000)
    Reload
    Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
    Result := MsgBox("The script could not be reloaded. Would you like to open it for editing?",, 4)
    if Result = "Yes"
        Edit
    return
    
}

#HotIf
