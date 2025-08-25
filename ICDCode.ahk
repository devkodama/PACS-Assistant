/**
 * ICDCode.ahk
 * 
 * ICD Code functions for PACS Assistant
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force



/**********************************************************
 * Globals
 * 
 */


; Holds the icd-10 lookup table
global ICDCodeTable := ""




/**********************************************************
 * Functions defined by this module
 * 
 */


; Reads the ICD code table from the file named "icd10codes.txt"
; The file a fixed format text file downloaded from https://www.cdc.gov/nchs/icd/icd-10-cm/files.html
; contained in a zip file e.g. ICD10-CM Code Descriptions 2025.zip.
;
; The first 8 characters of each line are the ICD-10 code.  The rest of
; the line is the description of the code.
;
ICDReadCodeFile(filename := ICD_CODEFILE) {
    global ICDCodeTable

    if ICDCodeTable := FileRead(filename) {
        GUIStatus("ICD Code table successfully read")
    } else {
        GUIStatus("Could not read ICD Code table")
    }
}


; Lookup an ICD-10 code (as string) and return the description as a string
;
ICDLookupCode(icdcode) {

    ; remove periods from the code
    icdcode := StrReplace(icdcode, ".")

    ; search for the code in the lookup table
    startpos := InStr(ICDCodeTable, icdcode)
    if startpos {
        endpos := InStr(SubStr(ICDCodeTable, startpos, 200), "`n")
        if endpos {
            icddescription := SubStr(ICDCodeTable, startpos + 8, endpos - 10)  ; needs to be 10, not 9
        } else {
            icddescription := "Code " icdcode " not found"
        }
    } else {
        icddescription := "Code " icdcode " not found"
    }

    return icddescription
}
