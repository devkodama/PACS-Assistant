/**
 * Updater.ahk
 * 
 * Functions for self updating this script.
 * 
 *
 *
 * This module defines the functions:
 * 
 *  UpdaterInit()                           - Performs housekeeping. Should be called 
 *                                          - once every script startup.
 * 
 *  UpdaterLatestVersion(urllatestversion)      - Returns a string specifying the latest
 *                                              - available version.
 * 
 *  UpdaterPerformUpdate(filename, urllatestrelease)    - Replaces filename with the 
 *                                                      - latest version downloaded 
 *                                                      - from urllatestrelease, then 
 *                                                      - reloads the script.
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Global variables and constants used in this module
 */




/**********************************************************
 * 
 */


; Should be called on startup to perform clean up operations (like deleting old files).
UpdaterInit() {
    ; remove any undeleted old files
    FileRecycle("___deprecated_*")
}


; Returns a string specifying the latest version. The latest version is obtained from
; urllatestversion, which should return only simple text. 
;
; The returned string should be a valid semantic versioning expression.
; Otherwise "" (empty string) is returned.
UpdaterLatestVersion(urllatestversion) {
    
    ; get the latest version
    Download(urllatestversion, "___latestversion")
    try {
        latestversion := FileRead("___latestversion")
        FileDelete("___latestversion")
    } catch {
        latestversion := ""
    }

    ; Use regex to match semantic version string, see:
    ; https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    ; https://regex101.com/r/Ly7O1x/3/
    if RegExMatch(latestversion, "/^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/gm") {
        return latestversion
    } else {
        return ""
    }
}


; Downloads the latest version of the file filename from urllatestrelease.
; Replaces the file, restarts the running script.
UpdaterPerformUpdate(filename, urllatestrelease) {

    try {
        Download(urllatestrelease, "___partial_" . filename)
    } catch {
        ; download failed, delete any residual partial file
        try {
            FileDelete("___partial_" . filename)
        } catch {
        }
    }

    ; [todo] need to verify good downloaded file
    if FileExist("___partial_" . filename) {
        
        if FileExist(filename) {
            ; rename existing file
            try {
                FileMove(filename, "___deprecated_" . filename)
            } catch {
            }            
            ; replace with new file
            try {
                FileMove("___partial_" . filename, filename)
            } catch {
                ; if failed, try to revert
                try {
                    FileMove("___deprecated_" . filename, filename)
                    FileDelete("___partial_" . filename)
                } catch {
                }
            }
            ; hopefully filename is now the new file,
            ; and the old deprecated file will be deleted after script restart
        }

    } else {
        ; didn't succeed with download, don't do anything.
    }
    
    ; restart the script
    Reload()
}







; Download "http://subrads.com/system/files/ref/images/03_990973_01B.jpeg", "test.jpeg"




; httpreq := ComObject("Msxml2.XMLHTTP")
; ; Open a request with async enabled.
; httpreq.open("GET", "http://subrads.com/", true)
; ; Set our callback function.
; httpreq.onreadystatechange := Ready
; ; Send the request.  Ready() will be called when it's complete.
; httpreq.send()



/*
; If you're going to wait, there's no need for onreadystatechange.
; Setting async=true and waiting like this allows the script to remain
; responsive while the download is taking place, whereas async=false
; will make the script unresponsive.
while req.readyState != 4
    sleep 100
*/

; Persistent

; Ready() {
;     if (httpreq.readyState != 4)  ; Not done yet
;         return
;     if (httpreq.status == 200) ; OK
;         return MsgBox "Latest AutoHotkey version: " httpreq.responseText
;     else
;         MsgBox "Status " httpreq.status,, 16
;     ExitApp
; }