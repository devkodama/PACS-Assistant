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



HelpTest() {
    
	md_txt := FileRead("README.md")

	css := FileRead("style.css")

	code := {comma:"#60F"
		, par:"#60F" ; ()
		, bk:"#60F" ; []
		, bc:"#60F" ; {}
		, tag:"#F00" ; <...>
		, str:"#066" ; '' and ""
		, math:"#06F" ; + - * / & ^ | !
		, compare:"#0CF" ; && || == > < >= <=
		, assign:"#06F" ; = :=
		, number:"#0FF" ; not yet supported
		, objdot:"#06F"
		, comment:"#080"
		, flat_comments:true
		}

	options := {css:""
          , font_name:"Segoe UI"
          , font_size:16
          , font_weight:400
          , line_height:1.6
          , code:code
          , debug:false
		}


	html_txt := make_html(md_txt, , , false)



FileAppend(html_txt, A_ScriptDir "\temp.html", "UTF-8")

; Run '"' A_ScriptDir '\temp.html"' ; open and test

    GUIPost("helpinfo", "innerHTML", "html=" . html_txt)


}