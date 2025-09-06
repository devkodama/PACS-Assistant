/**
 * Help.ahk
 * 
 * This module defines classes and functions for providing help and documentation.
 * 
 * 
 * This module defines the following classes:
 * 
 * 
 * 
 * This module defines the functions:
 *  
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Includes
 */


#Include <_MD_Gen>

#Include Globals.ahk
#Include Settings.ahk




/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * Classes defined by this module
 * 
 */




/**********************************************************
 * Functions defined by this module
 * 
 */


HelpShowReadme() {
    
	md_txt := FileRead("README.md")

	; in order for Marked to work:
	; need to replace single quotes with \'
	; need to replace CRLF (ahk `r`n) with \n
	md_txt := StrReplace(md_txt, "'", "\'")
	md_txt := StrReplace(md_txt, "`r`n", "\n")
; MsgBox(md_txt)

; Tack on debugging information
if Setting["Debug"].enabled {
	md_txt .= "\n\n====\n\n"
	md_txt .= "EXE_VPNUI " (FileExist(EXE_VPNUI) ? "FOUND" :"NOT FOUND") "\n\n"
	md_txt .= "EXE_VPNCLI " (FileExist(EXE_VPNCLI) ? "FOUND" :"NOT FOUND") "\n\n"
	md_txt .= "EXE_EI " (FileExist(EXE_EI) ? "FOUND" :"NOT FOUND") "\n\n"
	md_txt .= "EXE_PS " (FileExist(EXE_PS) ? "FOUND" :"NOT FOUND") "\n\n"
	md_txt .= "EXE_EPIC " (FileExist(EXE_EPIC) ? "FOUND" :"NOT FOUND") "\n\n"
	md_txt .= "\n\n"
}

	PAGUI.PostWebMessageAsString("document.getElementById('helpinfo').innerHTML = marked.parse('" md_txt "');")

}