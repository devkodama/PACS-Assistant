/**
 * BuildExe.ahk
 * 
 * Helper script to make a compiled version of PACS Assistant (stand-alone exe).
 * 
 * Run this script by itself. It will regenerate the Compiled.ahk file
 * to contain necessary compile-time directives for embedding the necessary
 * files with the executable, plus other compiled version requirements.
 * 
 * Subsequently it will run ahk2exe to create the PACS Assistant.exe runtime.
 * 
 * This module defines the functions:
 * 
 * GenerateCompileDirectives()          - Generate the resources file for PACS Assistant's compiled version
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Configuration
 * 
*/

; ahk2exe.exe executable
EXE_AHK2EXE := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"

; input file(s)
inputScriptFile := "AutoHotkey64.ahk"
inputIcoFile := "PA.ico"

; output file destinations
outputScriptFile := "Compiled.ahk"
outputExeFile := "Standalone\PACS Assistant\PACS Assistant.exe"

; Product name and description
productDescription := "PACS Assistant"
productName := "PACS Assistant"

; The auto-generated directives written to outputScriptFile are
; placed in between the resourceBlockStart and resourceBlockEnd markers.
resourceBlockStart := "; ### RESOURCE BLOCK START ###"
resourceBlockEnd := "; ### RESOURCE BLOCK END ###"

; WebViewToo resources - array of resources needed for WebViewToo to run when compiled.
;
; Array items in WVTresourcesList can be strings or arrays:
;
;   If an item is a string, it is interpreted as a file or folder specification which may
;   contain wildcards ("*"). Directories are processed recursively.
;
;   If the item is an array, the first element is the filename and the second item 
;   is the resourcename to be passed to the ;@Ahk2Exe-AddResource directive. If there 
;   is no second element, the resourcename is taken to be the same as the filename.
;
; These need to be added with ;@Ahk2Exe-AddResource directives, and also created 
; at runtime in the runtime temp directory by calling WebViewToo.CreateFileFromResource().
;
; At runtime, these files will be created inside a temp directory at
; C:\Users\<winuser>\AppData\Local\Temp\<dirname>.
WVTresourcesList := [
    ["Lib\64bit\WebView2Loader.dll", "64bit\WebView2Loader.dll"],
    ["Lib\32bit\WebView2Loader.dll", "32bit\WebView2Loader.dll"],
    "pages\*",
]

; File resources - array of filenames or directories of files that are placed
; in the working directory at runtime by the compiled script. The files are 
; rewritten (overwritten) on every run.
;
; Items in this array are strings, interpreted as a file specification.
; Directories are processed recursively.
;
; At runtime, these files will be created in the working directory of the compiled exe file.
; Directories will be created as needed.
filesList := [
    "PA.ico",
    "icd10codes.txt",
    "README.md",
]




/**********************************************************
 * 
 * 
*/


;
GenerateCompileDirectives() {

    ; Read the existing content of the output script.
    try {
        scriptContent := FileRead(outputScriptFile)
    } catch {
        scriptContent := ""
    }

    ; Find the start and end markers of the resource block
    blockStartPos := InStr(scriptContent, resourceBlockStart)
    blockEndPos := InStr(scriptContent, resourceBlockEnd)

    ; If necessary, insert start and end markers
    if !blockStartPos && !blockEndPos {
        ; If both are not present, add the pair of markers to the end of the file.
        scriptContent .= resourceBlockStart "`n"
        scriptContent .= resourceBlockEnd "`n"
    } else if !blockStartPos {
        ; End marker but no start marker. Insert a start marker on the line before the end marker.
        scriptContent := StrReplace(scriptContent, resourceBlockEnd, resourceBlockStart . "`n" . resourceBlockEnd)
    } else if !blockEndPos {
        ; Start marker but no end marker. Insert an end marker on the line after the start marker.
        scriptContent := StrReplace(scriptContent, resourceBlockStart, resourceBlockStart . "`n" . resourceBlockEnd)
    }

    ; double check that we have both start and end markers in the file
    blockStartPos := InStr(scriptContent, resourceBlockStart)
    blockEndPos := InStr(scriptContent, resourceBlockEnd)
    if !blockStartPos || !blockEndPos {
        ; error condition
        MsgBox("Could not find or add resource start and end markers. " outputScriptFile " was not created or modified.")
        ExitApp()
    }

    ; Start generating the new resource directives

    ; Add properties
    propertyDirectives := ''

    ; Get build version from the text file "version".
    if FileExist("version") {
        productVersion := FileRead("version")
        productVersion := SubStr(productVersion, 1, 32)       ; limit to 32 chars
    } else {
        productVersion := ""
    }
    propertyDirectives .= ";@Ahk2Exe-SetVersion " . productVersion . "`n"
    propertyDirectives .= ";@Ahk2Exe-SetCopyright Copyright " . A_Year . "`n"
    propertyDirectives .= ";@Ahk2Exe-SetName " . productName . "`n"
    propertyDirectives .= ";@Ahk2Exe-SetDescription " . productDescription . "`n"
    propertyDirectives .= "`nCompiled_VersionString := `"" . productVersion . "`"`n"

    ; Process WVTresourcesList, build directives for adding resources
    wvtAddDirectives := ''
    wvtCreateDirectives := ''
    for item in WVTresourcesList {

        if IsObject(item) {
            ; assume item is an Array[]
            try {
                filename := item[1]
            } catch {
                filename := ''
            }
            try {
                resourcename := item[2]
            } catch {
                resourcename := filename
            }
            wvtAddDirectives .= ';@Ahk2Exe-AddResource ' . filename . ', ' . resourcename . '`n'
            wvtCreateDirectives .= '`tWebViewToo.CreateFileFromResource("' . resourcename . '")`n'

        } else {
            ; assume item is a string specifying a filepath

            ; if a simple file (no backslash indicating a directory), don't loop
            if !InStr(item, "\") {
                ; a simple file
                filename := item
                resourcename := filename

                wvtAddDirectives .= ';@Ahk2Exe-AddResource ' . filename . ', ' . resourcename . '`n'
                wvtCreateDirectives .= '`tWebViewToo.CreateFileFromResource("' . resourcename . '")`n'
            } else {
                ; a path with a directory, loop through it
                Loop Files item, "R" {      
                    filename := (A_LoopFileDir ? A_LoopFileDir . '\' : '') . A_LoopFileName
                    resourcename := filename

                    wvtAddDirectives .= ';@Ahk2Exe-AddResource ' . filename . ', ' . resourcename . '`n'
                    wvtCreateDirectives .= '`tWebViewToo.CreateFileFromResource("' . resourcename . '")`n'
                }
            }
        }
    }

    ; Process filesList, build directives for adding files and creating directories
    fileInstallDirectives := ''
    directoryList := Map()
    for item in filesList {
        ; item is expected to be a string specifying a filepath

        ; if a simple file (no backslash indicating a directory), don't loop
        if !InStr(item, "\") {
            ; a simple file
            sourcefile := item
            destfile := sourcefile

            fileInstallDirectives .= 'FileInstall "' . sourcefile . '", "' . destfile . '", 1`n'    ; 1 = overwrite
        } else {
            ; a path with a directory, loop through it
            Loop Files item, "R" {
                ; add the directory to list of directories
                directoryList[A_LoopFileDir] := true    ; this adds a map entry with A_LoopFileDir as the key
                sourcefile := (A_LoopFileDir ? A_LoopFileDir . "\" : "") . A_LoopFileName
                destfile := sourcefile

                fileInstallDirectives .= 'FileInstall "' . sourcefile . '", "' . destfile . '", 1`n'    ; 1 = overwrite
            }
        }
    }

    dirCreateDirectives := ''
    if directoryList.Count > 0 {
        for dir, in directoryList {
            newDirDirectives .= 'if !DirExist("' . dir . '") {`n`tDirCreate("' . dir . '")`n}`n'
        }
    }

    ; assemble all the directives
    newDirectives := '`n'
    if propertyDirectives {
        newDirectives .= propertyDirectives . '`n'
    }
    if wvtAddDirectives {
        newDirectives .= wvtAddDirectives . '`n'
    }
    if (wvtCreateDirectives) {
        newDirectives .= 'if A_IsCompiled {`n'
        newDirectives .= wvtCreateDirectives
        newDirectives .= '}`n`n'
    }
    if fileInstallDirectives {
        newDirectives .= fileInstallDirectives . '`n'
    }
    if (dirCreateDirectives) {
        newDirectives .= dirCreateDirectives . '`n'
    }

    ; combine the new directives with the pre-existing script (that was outside the resource block markers)
    beforeBlock := SubStr(scriptContent, 1, blockStartPos + StrLen(resourceBlockStart))
    afterBlock := SubStr(scriptContent, blockEndPos)

    newScriptContent := beforeBlock . newDirectives . afterBlock

    ; Write the updated script content back to the file.
    if FileExist(outputScriptFile) {
        FileDelete(outputScriptFile)
    }
    FileAppend(newScriptContent, outputScriptFile)

; MsgBox("Success, resource directives have been updated in " outputScriptFile ".")

}




/**********************************************************
 * Auto execute section
 * 
*/


; Regenerate the Compiled.ahk file.
GenerateCompileDirectives()

; Run ahk2exe.exe to generate the standalone exe.

try {
    if FileExist(outputExeFile) {
        try {
            FileDelete(outputExeFile)
        } catch {
        }
    }
    result := RunWait(EXE_AHK2EXE . ' /in "' . inputScriptFile . '" /out "' . outputExeFile . '" /icon "' . inputIcoFile . '"')
    if !result {
        ; success
        MsgBox(outputExeFile . " created successfully")
    } else {
        ; failure
        MsgBox(outputExeFile . " could not be created (Ahk2Exe result code " . result . ")")
    }
} catch {
    MsgBox(outputExeFile . " could not be created, " EXE_AHK2EXE . " could not be found")
}


