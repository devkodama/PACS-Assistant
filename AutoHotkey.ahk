/************************************************************************
 * @description Top level script to start AHK
 * @author Scott Lee
 * @date 2025/02/25
 * @version 0.0.0
 * 
 * 
 * Runs script as Admin so cross app communication works on all systems.
 * 
 * Just includes PACS Assistant.ahk, which is the main script for PACS Assistant.
 * 
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance Force


; Makes a script unconditionally use its own folder as its working directory.
; Ensures a consistent starting directory.
SetWorkingDir A_ScriptDir



/**********************************************************
 * 
 */

; Run as Admin in order to interact with other programs that 
; are running as Admin (https://www.autohotkey.com/docs/v2/lib/Run.htm#RunAs)
if not (A_IsAdmin)
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}


/**********************************************************
 * Includes
 */


#Include PACSAssistant.ahk