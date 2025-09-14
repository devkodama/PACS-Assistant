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
 *  UpdaterLatestVersion(urllatestversion)  - Returns a string specifying the latest
 *                                          - available version, obtained from urllatestversion.
 *
 *  UpdaterLatestChecksum(urlchecksum)      - Returns a string specifying the checksum of latest
 *                                          - available version, obtained from urlchecksum.
 * 
 *  UpdaterPerformUpdate(filename, urllatestrelease, urlchecksum)       - Replaces filename with the 
 *                                                      - latest version downloaded from urllatestrelease,
 *                                                      - after confirming download with checksum obtained from
 *                                                      - urlchecksum, then reloads the script.
 * 
 *  Updater()                               - The main function to be called externally.
 *                                          - Checks for a new version of PACS Assistant, asks the user
 *                                          - for permission to update, then performs the update and restarts.
 *                                          - Only works for compiled version of script.
 *                                          - A_AhkExe must be defined as the name of the script exe file.
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
 * Global variables and constants used in this module
 */


; Updater files are kept in this directory
updaterdir := "update"




/**********************************************************
 * 
 */


; Should be called on startup to perform clean up operations (like deleting old files).
;
UpdaterInit() {
    if DirExist(updaterdir) {
        ; remove any undeleted temp files
        try {
            FileDelete(updaterdir . "\__partial__*")
            FileDelete(updaterdir . "\__version__")
            FileDelete(updaterdir . "\__checksum__")
        } catch {
        }
        ; remove saved versions of exe files which are older than 60 days
        try {
            loop files updaterdir . "\*.exe" {
                if DateDiff(A_LoopFileTimeCreated, A_Now, "D") > -1 {
                    FileDelete(A_LoopFileFullPath)
                }
            }
        } catch {
        }
    }

}


; Returns a string specifying the latest version. The latest version is obtained from
; urllatestversion, which should return only simple text. 
;
; The returned string should be a valid semantic versioning expression.
; Otherwise "" (empty string) is returned.
;
UpdaterLatestVersion(urllatestversion) {
    
    if !DirExist(updaterdir) {
        DirCreate(updaterdir)
    }
    ; get the latest version
    Download(urllatestversion, updaterdir . "\__version__")
    try {
        latestversion := FileRead(updaterdir . "\__version__")
        FileDelete(updaterdir . "\__version__")
    } catch {
        latestversion := ""
    }

    ; check the version string for validity before returning
    return VersionStringIsValid(latestversion) ? latestversion : ""
}


; Returns a string specifying the expected checksum for the latest version.
; The expected checksum is obtained from urlchecksum, which should return only simple text.
; The returned string should be a valid MD5 hash (i.e. 32-digit hex string).
;
UpdaterLatestChecksum(urlchecksum) {
    
    if !DirExist(updaterdir) {
        DirCreate(updaterdir)
    }
    ; get the latest version
    Download(urlchecksum, updaterdir . "\__checksum__")
    try {
        checksum := FileRead(updaterdir . "\__checksum__")
        FileDelete(updaterdir . "\__checksum__")
    } catch {
        checksum := ""
    }

    ; check the hash string for validity before returning
    return MD5StringIsValid(checksum) ? checksum : ""
}


; Downloads the latest version of the exe file filename from urllatestrelease.
; Verifies the download against the checksum (unless urlchecksum is omitted or blank).
; Replaces the script exe file, saving the old one in the updater folder as a backup.
;
; The script must be compiled for this function to succeed. If not compiled, returns failure.
;
; If urlchecksum is omitted or blank, then checksum verification is skipped (NOT RECOMMENDED).
;
; On success, returns true.
; On failure, returns false.
;
UpdaterPerformUpdate(filename, urllatestrelease, urlchecksum:="") {

    if !A_IsCompiled {
        return false        ; failure
    }

    if urlchecksum {
        ; get the expected MD5 of the download
        checksum := UpdaterLatestChecksum(urlchecksum)
        if !checksum {
            return false        ; failure
        }
    } else {
        checksum := ""
    }

    if !DirExist(updaterdir) {
        DirCreate(updaterdir)
    }

    ; download the latest release executable file
    try {
        Download(urllatestrelease, updaterdir . "\__partial__" . filename)
    } catch {
        ; download failed, delete any residual partial file and return failure
        try {
            FileDelete(updaterdir . "\__partial__" . filename)
        }    
        return false        ; failure
    }    

    if checksum {
        ; verify checksum
        if !(ComputeChecksum(updaterdir . "\__partial__" . filename) == checksum) {
            ; verify failed, delete any residual partial file and return failure
            try {
                FileDelete(updaterdir . "\__partial__" . filename)
            }    
            return false        ; failure
        }
        ; checksums match
    }    

    ; Save current file as backup and replace it with downloaded file.
    if !FileExist(filename) {
        ; this should never happen
        msgbox(filename . "doesn't exist")
        return false        ; failure
    }

    ; rename current file with its version appended and save it in the updater folder
    SplitPath(filename, , , &ext, &fn)
    savename := fn . " " . A_Version . "." . ext
    try {
        FileMove(filename, updaterdir . "\" . savename)
    } catch {
        return false        ; failure
    }
    ; replace current file with new file
    try {
        FileMove(updaterdir . "\__partial__" . filename, filename)
    } catch {
        ; if error, try to revert
        try {
            FileMove(updaterdir . "\" . savename, filename)
            FileDelete(updaterdir . "\__partial__" . filename)
        } catch {
        return false        ; failure
        }
    }

    return true         ; success
}


; Check for a new version of PACS Assistant, asks the user for
; permission to update, then performs the update and restarts.
;
; A_AhkExe must be defined as the name of the running exe file.
;
; Only works for compiled version of script. Returns false if non-compiled version is running.
;
; If update is performed, the script is restarted and this function never returns.
; If no update is performed, simply returns.
;
Updater() {

    UpdaterInit()

    if !A_IsCompiled {
        return false
    }
    
    latestversion := UpdaterLatestVersion("https://raw.githubusercontent.com/devkodama/PACS-Assistant/refs/heads/main/version")

MsgBox(latestversion " vs. " A_Version)

    if VerCompare(latestversion, A_Version) >= 0 {
        ; latest version is higher than current version, so try to update
        if MsgBox("A newer version of PACS Assistant is available. Do you want to update?", "PACS Assistant Update", "Y/N") = "Yes" {
            ; user said Yes, do the update
            if UpdaterPerformUpdate(A_AhkExe, "https://github.com/devkodama/PACS-Assistant/raw/refs/heads/main/Standalone/PACS%20Assistant/PACS%20Assistant.exe")
            ; success, restart the script
            MsgBox("Click OK to restart PACS Assistant")
            ; Reload()
        }
    } else {
        MsgBox("No update is available.", "PACS Assistant Update", "OK")
    }
}
