/**
 * Settings.ahk
 *
 * This module defines classes and function for managing settings within PACS Assistant
 * 
 *
 * This module defines the following globals:
 *
 *  Setting             - Map() with program-wide modifiable settings
 *  SettingsPage        - Array() ordered array of keys that determines which settings
 *                          are shown and the order in which they are shown on the 
 *                          GUI Settings page
 * 
 *
 * This module defines the following classes:
 *
 *  SetItem             - Holds an individual setting
 *   
 * 
 * This module defines the functions:
 *
 *  SettingsInit()                          - Determine the current user, then read the user's saved settings from the user-specific .ini file.
 *  SettingsReadAll()                       - Reads all the settings from the user-specific .ini file for the current user
 *  SettingsWriteAll()                      - Writes all settings to a (new) user-specific .ini file for the current user.
 *  SettingsGeneratePage(show := true)      - Generate an HTML form and displays it on the PACS Assistant GUI Settings page.
 * 
 *  HandleFormInput(WebView, id, newval)    -
 * 
 * 
 */


#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
** Includes
*/


#Include <Cred>

#Include Utils.ahk
#Include Globals.ahk




/**********************************************************
** Global variables and constants used or defined in this module
*/


; Program-wide modifiable settings are defined here in the Setting[] Map
; object. Not all of these settings have to be exposed to the user on the
; GUI Settings page.
;
; Note that username, password, and inifile are special cases, even
; though they are stored in the Setting[] map. They are treated differently 
; by functions that handle changes to the settings (e.g. HandleFormInput(), and 
; by the value property setter and getter).
;
Setting := Map()

; PASettings["active"] is the top level on/off--it defines whether many
; PACS Assistant functions are active.
Setting["active"] := SetItem("active", "bool", true, , "Top level switch for many PACS Assistant functions")

; Special settings
Setting["username"] := SetItem("username", "special", "", PA_USERNAME_MAXLENGTH, "Username")
Setting["password"] := SetItem("password", "special", "", PA_PASSWORD_MAXLENGTH, "Password")
Setting["inifile"] := SetItem("inifile", "special", FILE_SETTINGSBASE . ".ini", 0, "Current .ini file")
Setting["storepassword"] := SetItem("storepassword", "bool", true, , "Remember your password on this workstation")

; General settings
Setting["MouseJiggler"] := SetItem("MouseJiggler", "bool", true, , "Enable mouse jiggler to prevent the screen from going to sleep")
Setting["MouseJiggler_timeout"] := SetItem("MouseJiggler_timeout", "num", 240, [0, 1440], "Disable mouse jiggler after this many minutes of inactivity (0 = never disable)")
Setting["ClearCapsLock"] := SetItem("ClearCapsLock", "bool", true, , "Reset CapsLock to off after no keyboard input for " . Integer(CAPSLOCK_TIMEOUT / 1000) . " seconds")

Setting["FocusFollow"] := SetItem("FocusFollow", "bool", true, , "Enable focus following to keep the window under the mouse active")
;Setting["RememberWindows"] := SetItem("RememberWindows", "bool", true, , "Automatically remember window positions on exit.")

Setting["UseVoice"] := SetItem("UseVoice", "bool", true, , "Enable synthesized voice feedback")
Setting["Voice"] := SetItem("Voice", "select", "Zira", Map("Dave", 0, "Zira", 1), "Which voice to use")

Setting["ClickLock"] := SetItem("ClickLock", "select", "Spacebar", Map("Off", "Off", "Spacebar", "Manual"), "Enable Click Lock for left mouse button")
Setting["ClickLock_interval"] := SetItem("ClickLock_interval", "num", 2000, [500, 5000], "For Auto Click Lock, how long (in ms) the left mouse button needs to be held down before click lock activates.")

; VPN settings
Setting["VPN_center"] := SetItem("VPN_center", "bool", true, , "When VPN window appears, center it on the screen")

; EI settings
Setting["EI_restoreatopen"] := SetItem("EI_restoreatopen", "bool", true, , "When EI opens, auto restore windows to their saved positions")
Setting["EIcollaborator_show"] := SetItem("EIcollaborator_show", "bool", false, , "Show Collaborator window at EI startup")

; PS settings
Setting["PS_restoreatopen"] := SetItem("PS_restoreatopen", "bool", true, , "When PowerScribe opens, auto restore window to its saved position")

Setting["PSlogout_dismiss"] := SetItem("PSlogout_dismiss", "bool", true, , "Automatically answer Yes to logout confirmation message when you have draft or unsigned reports")
Setting["PSlogout_dismiss_reply"] := SetItem("PSlogout_dismiss_reply", "select", "Yes", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

Setting["PSsavespeech_dismiss"] := SetItem("PSsavespeech_dismiss", "bool", false, , "Automatically answer 'Save changes to speech files?' message")
Setting["PSsavespeech_dismiss_reply"] := SetItem("PSsavespeech_dismiss_reply", "select", "No", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

Setting["PSconfirmaddendum_dismiss"] := SetItem("PSconfirmaddendum_dismiss", "bool", true, , "Automatically answer Yes to 'Create addendum?' message")
Setting["PSconfirmaddendum_dismiss_reply"] := SetItem("PSconfirmaddendum_dismiss_reply", "select", "Yes", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

Setting["PS_dictate_autoon"] := SetItem("PS_dictate_autoon", "bool", true, , "Automatically turn microphone on when opening a report and off when closing a report")

Setting["PS_dictate_idleoff"] := SetItem("PS_dictate_idleoff", "bool", true, , "Automatically turn microphone off after a period of inactivity")
Setting["PS_dictate_idletimeout"] := SetItem("PS_dictate_idletimeout", "num", 1, [1, 120], "After how many minutes?")

Setting["PSmicrophone_dismiss"] := SetItem("PSmicrophone_dismiss", "bool", true, , "Automatically dismiss 'Microphone disconnected' message")
Setting["PSmicrophone_dismiss_reply"] := SetItem("PSmicrophone_dismiss_reply", "select", "OK", Map("OK", "OK"), "Reply to PowerScribe 'Microphone disconnected' message.")

Setting["PScenter_dialog"] := SetItem("PScenter_dialog", "bool", true, , "Always center PowerScribe popup messages over the main PowerScribe window")

Setting["PSSPspelling_autoclose"] := SetItem("PSSPspelling_autoclose", "bool", true, , "Auto close the Spelling window except when within the PowerScribe window")

; EPIC settings
Setting["EPIC_restoreatopen"] := SetItem("EPIC_restoreatopen", "bool", true, , "When Epic opens, auto restore windows to their saved positions")
Setting["EPICtimezone_dismiss"] := SetItem("EPICtimezone_dismiss", "bool", true, , "Automatically dismiss the Time Zone confirmation message")

; Hotkey settings
Setting["hkCapsLock"] := SetItem("hkCapsLock", "bool", true, , "CapsLock ⇒ PowerScribe Microphone on/off")
Setting["+hkCapsLock"] := SetItem("+hkCapsLock", "bool", true, , "Shift-CapsLock ⇒ PowerScribe Sign Dictation")
Setting["^hkCapsLock"] := SetItem("^hkCapsLock", "bool", true, , "Ctrl-CapsLock ⇒ PowerScribe Draft Dictation")
Setting["^+hkCapsLock"] := SetItem("^+hkCapsLock", "bool", true, , "Ctrl-Shift-CapsLock ⇒ PowerScribe Sign as Preliminary")

Setting["hkTab"] := SetItem("hkTab", "bool", true, , "Tab ⇒ PowerScribe Next field")
Setting["+hkTab"] := SetItem("+hkTab", "bool", true, , "Shift-Tab ⇒ PowerScribe Previous field")
Setting["^hkTab"] := SetItem("^hkTab", "bool", true, , "Ctrl-Tab ⇒ PowerScribe Move to End of current/next line")
Setting["^+hkTab"] := SetItem("^+hkTab", "bool", true, , "Ctrl-Shift-Tab ⇒ PowerScribe Move to End of line above")

Setting["hkBacktick"] := SetItem("hkBacktick", "bool", true, , "Backtick (``) ⇒ Display Study Details (comparison report)")
Setting["+hkBacktick"] := SetItem("+hkBacktick", "bool", true, , "Shift-Backtick (``) ⇒ Toggle between EI Desktop List and Text pages")
Setting["^hkBacktick"] := SetItem("^hkBacktick", "bool", true, , "Ctrl-Backtick (``) ⇒ Show EI Desktop Search page")

Setting["+hkEsc"] := SetItem("+hkEsc", "bool", true, , "Shift-Escape ⇒ Close current study")

Setting["hkCtrlYZ"] := SetItem("hkCtrlYZ", "bool", true, , "Ctrl-Y & Ctrl-Z ⇒ PowerScribe Redo/Undo")

Setting["hkSpaceClick"] := SetItem("hkSpaceClick", "bool", true, , "Spacebar to double click")
Setting["hkSpaceDelete"] := SetItem("hkSpaceDelete", "bool", false, , "Spacebar to delete text in PowerScribe")

; Advanced
Setting["EIactivate"] := SetItem("EIactivate", "bool", false, , "Enable automatic EI image viewport activation before specific hotkeys. Before enabling, need to edit the list of hotkeys PA_EIKeyList[] in the file Hotkeys.ahk.")

; Misc settings
Setting["run"] := SetItem("run", "num", 0, , "")



; PASettingsPage is an ordered array of keys that determines which settings
; are shown and the order in which they are shown on the GUI Settings page. 
;
; Settings can be grouped into categories. When a key begins with a colon,
; as in ":CategoryName", then CategoryName is used as the grouping title
;
; When a key is prefixed with ">", as in ">MouseJiggler_timeout", then
; the key is indented when displayed. A double indent ">>" can also be used.
;
SettingsPage := Array()

; The settings to be displayed on the GUI Settings page are defined here in 
; the SettingsPage[] Array object.

SettingsPage.Push("#Account")
SettingsPage.Push("username")
SettingsPage.Push("password")
SettingsPage.Push(">storepassword")

SettingsPage.Push("#General")
SettingsPage.Push("FocusFollow")
SettingsPage.Push("MouseJiggler")
; SettingsPage.Push(">MouseJiggler_timeout")
SettingsPage.Push("ClearCapsLock")
SettingsPage.Push("UseVoice")
SettingsPage.Push(">Voice")

SettingsPage.Push("#VPN")
SettingsPage.Push("VPN_center")

SettingsPage.Push("#EI")
SettingsPage.Push("EI_restoreatopen")
SettingsPage.Push("ClickLock")
; PASettingsPage.Push(">ClickLock_interval")

SettingsPage.Push("#PowerScribe")
SettingsPage.Push("PS_restoreatopen")
SettingsPage.Push("PS_dictate_autoon")
SettingsPage.Push("PS_dictate_idleoff")
SettingsPage.Push(">PS_dictate_idletimeout")
SettingsPage.Push("PSconfirmaddendum_dismiss")
SettingsPage.Push("PSlogout_dismiss")
SettingsPage.Push("PSsavespeech_dismiss")
SettingsPage.Push(">PSsavespeech_dismiss_reply")
SettingsPage.Push("PSmicrophone_dismiss")
SettingsPage.Push("PSSPspelling_autoclose")
SettingsPage.Push("PScenter_dialog")

SettingsPage.Push("#Epic")
SettingsPage.Push("EPIC_restoreatopen")
SettingsPage.Push("EPICtimezone_dismiss")

SettingsPage.Push("#Hotkeys")
SettingsPage.Push("hkCapsLock")
SettingsPage.Push("+hkCapsLock")
SettingsPage.Push("^hkCapsLock")
SettingsPage.Push("^+hkCapsLock")
SettingsPage.Push("hkTab")
SettingsPage.Push("+hkTab")
SettingsPage.Push("^hkTab")
SettingsPage.Push("^+hkTab")
SettingsPage.Push("hkBacktick")
SettingsPage.Push("+hkBacktick")
SettingsPage.Push("^hkBacktick")
SettingsPage.Push("+hkEsc")
SettingsPage.Push("hkCtrlYZ")
SettingsPage.Push("hkSpaceClick")

SettingsPage.Push("#Advanced")
SettingsPage.Push("EIactivate")

SettingsPage.Push("#Beta - Experimental, not working yet")
SettingsPage.Push("hkSpaceDelete")
SettingsPage.Push("EIcollaborator_show")




/**********************************************************
** Classes defined by this module
*/


; Class to hold an individual setting within PACS Assistant
;
; Possible values for type:
;   "bool"      - possiblevalues is ignored, as it assumed to be [true, false]
;   "num"       - possiblevalues is an array of [lowerbound, upperbound], or empty if no limits
;   "text"      - possiblevalues is an integer defining maximum length of text
;   "select"    - possiblevalues is a Map of options, e.g. Map("opt1key", "opt1val", "opt2key", "opt2val", "opt3key", "opt3val", ...)
;   "special"   - possiblevalues is a string defining what type of special value this is
;
class SetItem {
    name := ""              ; Name of this setting. Should match the key used in 
	type := ""              ; Type of this setting.
    default := ""           ; Default value for this setting. For select type, this corresponds to the key, not the actual mapped value.
	possible := 0			; Number, Array, or Map, usage depends on type
	description :=""		; Description of this setting, shown to user on the Settings page
    
    _value := ""		    ; Current value. For "select" type, stores the mapped value (e.g. "&YES")
    _key := ""              ; For "select" type only. Stores the key (e.g. "Yes")


    ; For "select" type, reading the value property returns the mapped
    ; value. To retrieve the key, use the key property.
    ;
    ; For "select" type, assigning the value property actually assigns
    ; the key, and the mapped value is assigned based on lookup in the 
    ; possible map.
    ;
    ; For example:
    ;   s := Setting("Keyname", "select", "Yes", Map("Yes", "&YES", "No", "&NO", "Description")
    ;   MsgBox(s.value)         ; => "&YES"
    ;   MsgBox(s.key)           ; => "Yes"
    ;   s.value := "No"
    ;   MsgBox(s.value)         ; => "&NO"
    ;   MsgBox(s.key)           ; => "No"
    ;
    value {
        get {
            ; switch this.type {
            ;     case "select":
            ;         return this._key
            ;     default:
                    return this._value
            ; }
        }
        set { 
            global Setting
            global CurrentUserCredentials

    ; PAToolTip(this.name " = " Value)
            switch this.type {
                case "select":
                    if IsObject(this.possible) {
                        for k, v in this.possible {
                            if k == Value {
                                this._value := v
                                this._key := Value
                                break
                            }
                        }
                    } else {
                        this._value := Value
                        this._key := Value
                    }
                case "special":
                    switch this.name {
                        case "username":
                            newval := Trim(Value)
                            if this._value != newval {
                                ; username has changed, so update the user and his settings
                                this._value := newval
                                this._key := ""
                                CurrentUserCredentials.username := newval

                                if newval {
                                    ; username is non-empty

                                    ; add username to title bar
                                    GUIPost("curuser", "innerHTML", " - " . newval)

                                    ; update password
                                    if !WorkstationIsHospital() {
                                        ; not hospital, try to get the password from local storage
                                        cred := CredRead("PA_cred_" . newval)
                                        if cred {
                                            Setting["password"].value := cred.password
                                        } else {
                                            Setting["password"].value := ""
                                        }
                                    } else {
                                        Setting["password"].value := ""
                                    }

                                    ; update the user-specific .ini filename
                                    Setting["inifile"].value := FILE_SETTINGSBASE "." newval ".ini"
                                    if FileExist(Setting["inifile"].value) {
                                        ; Read the new user's saved settings
                                        SettingsReadAll()
                                    } else {
                                        ; No ini file, let's write a new one
                                        SettingsWriteAll()
                                    }

                                } else {
                                    ; username is empty

                                    ; update title bar
                                    GUIPost("curuser", "innerHTML", "")

                                    ; set password to empty
                                    Setting["password"].value := ""

                                    ; set inifile to application-wide settings.ini file
                                    Setting["inifile"].value := FILE_SETTINGSBASE ".ini"
                                }

                                ; Update the displayed settings page form
                                SettingsGeneratePage()

                            } else {
                                ; username was not changed, don't do anything
                            }
                        case "password":
                            newval := Trim(Value)
                            this._value := newval
                            this._key := ""
                            CurrentUserCredentials.password := newval
                        default:
                            newval := Trim(Value)
                            this._value := newval
                            this._key := ""
                    }
                default:
                    ; [todo] #64 need bounds checking...
                    this._value := Trim(Value)
                    this._key := ""
            }
            ; Save this update setting to the .ini file
            this.SaveSetting()
        }
    }

    key {
        get {
            return this._key
        }
    }

    on {
        get {
            return this._value ? true : false 
        }
    }
    ; Call to save the current Setting object to the current settings.ini file(s).
    ;
    ; There is a master settings.ini file used by PACS Assistant. Each user also
    ; has a separate settings.username.ini file, where username is replaced by 
    ; the actual username. The username must have a value stored in 
    ; Setting["username"].
    ;
    SaveSetting() {
;        PAToolTip(this.name " / " this._value " / " )
        switch this.type {
            case "special":
                ; special options handling (e.g. username, password)
                switch this.name {
                    case "username":
                        if this._value {
                            inifile := FILE_SETTINGSBASE ".ini"
                            
                            ; save to ini file to remember current user
                            IniWrite(this._value, inifile, "Users", "curuser")
                            
                            ; add it to list of previously encountered usernames
                            users := IniRead(inifile, "Users", "users", "")
                            usersarr := StrSplit(users, ",", " `t")
                            found := false
                            for v in usersarr {
                                if this._value = v {
                                    found := true
                                    break
                                }
                            }
                            if !found {
                                ; username not already in the list, add it to the list and save the list
                                usersarr.Push(this._value)
                                IniWrite(StrJoin(usersarr, ","), inifile, "Users", "users")
                            }
                        }
                    case "password":
                        ; Don't save to disk.
                        ; Save to local credentials store if this is not a hospital computer 
                        ; and the password is non-empty.
                        if !WorkstationIsHospital() {
                            ; not hospital, so save password to local storage if wanted
                            if Setting.Has("storepassword") {
                                if Setting["storepassword"].on {
                                    if this._value {
                                        CredWrite("PA_cred_" . Setting["username"].value, Setting["username"].value, this._value)
                                    }
                                } else {
                                    ; user does not want password stored locally
                                    ; delete any existing locally stored password
                                    CredDelete("PA_cred_" . Setting["username"].value)
                                }
                            }
                        }
                    case "inifile":
                        ; don't save this anywhere
                    default:
                }
            case "select":
                ; in this case, save this._key instead of this._value)
                if Setting.Has("inifile") && Setting["inifile"].value {
                    IniWrite(this._key, Setting["inifile"].value, "PASettings", this.name) 
                }
            default:
                ; save this._value
                if Setting.Has("inifile") && Setting["inifile"].value {
                    IniWrite(this._value, Setting["inifile"].value, "PASettings", this.name) 
                }
        } 
    }

    ; Called when a new Setting object is created.
    ; No bounds checking on the passed defaultvalue.
    ; Current value of the Settting is set to the same as the default value for new objects.
	__New(settingname, settingtype := "", defaultvalue := "", possiblevalues:= 0, desc := "") {
        this.name := settingname
        this.type := settingtype
        this.default := defaultvalue
		this.possible := possiblevalues        
		this.description := desc
		this.value := defaultvalue        ; value prop should be assigned last
	}

    ; Checks a new value against the list of allowed possibilites.
    ; Returns true if allowed, false if not allowed.
    isValid(newval) {
        switch this.type {
            case "bool":
                ; always succeeds
                return true
            case "num":
                if !this.possible {
                    ; no restrictions
                    return true
                } else {
                    ; check value against lower and upper bounds
                    if newval >= this.possible[1] && newval <= this.possible[2] {
                        return true
                    } else {
                        return false
                    }
                }
            case "text", "special":
                ; check string length against limit
                if StrLen(newval) <=  this.possible {
                    return true
                } else {
                    return false
                }
            case "select":
                ; check that the value is valid key in the Map of possibles
                return this.possible.Has(newval)
            default:
                return false
        }
    }
}




/**********************************************************
** Functions defined by this module
*/


; Determine the current user, then read the user's saved settings
; from the user-specific .ini file.
; If there is no current user (""), then use the application-wide inifile.
SettingsInit() {
    inifile := FILE_SETTINGSBASE . ".ini"

    curuser := IniRead(inifile, "Users", "curuser", "")
    Setting["username"].value := curuser

    ; Now read the current user's settings
    SettingsReadAll()           
}


; Reads all the settings from the user-specific .ini file for the current user.
; Settings not found in the .ini file are set to their default values.
;
; The current user is specified by PASettings["username"].
; The current user-specific .ini file is specified by PASettings["inifile"].
;
; Updates "special" setting for password by reading from local store.
;
SettingsReadAll() {
    global Setting
    global CurrentUserCredentials

    ; ensure username has a value
    if Setting["username"].value {

        inifile := Setting["inifile"].value
        readvalue := ""

        for key, sett in Setting {
            switch sett.type {
                case "special":
                    if sett.name == "password" {
                        if !WorkstationIsHospital() {
                            ; not hospital, so try to get the password from local storage
                            cred := CredRead("PA_cred_" . Setting["username"].value)
                            if cred {
                                Setting["password"].value := cred.password
                                CurrentUserCredentials.password := cred.password
                            } else {
                                ; didn't find a locally stored password
                                Setting["password"].value := ""
                                CurrentUserCredentials.password := ""
                            }
                        } else {
                            ; this is a hospital computer, set password to blank
                            Setting["password"].value := ""
                            CurrentUserCredentials.password := ""
                        }
                    }
                default:
                    if inifile {
                        ; try to read the saved value for this 
                        readvalue := IniRead(inifile, "PASettings", sett.name, "")
                    }
                    ; only update setting if a non-empty value is retrieved
                    if readvalue != "" {
                        Setting[key].value := readvalue
                    } else {
                        Setting[key].value := Setting[key].default
                    }
            }
        }

    }
}


; Writes all settings to a (new) user-specific .ini file for the current user.
;
; All current settings values are written, excluding "special" settings
; such as username, password, or inifile.
;
; The current user is specified by PASettings["username"].
; The current user-specific .ini file is specified by PASettings["inifile"].
;
SettingsWriteAll() {
    global Setting
;    global CurrentUserCredentials

    ; ensure username has a value
    if Setting["username"].value {
        for key, sett in Setting {
            switch sett.type {
                case "special":
                    ; skip, don't write special settings
                default:
                    sett.SaveSetting()
            }
        }
    }
}


; Generate an HTML form and displays it on the PACS Assistant GUI Settings page.
;
; The form is generated from the Setting[] map and the SettingsPage[] array.
;
; The generated form is inserted into div.#settingsform on the GUI
; (replacing any previous contents of innerHTML), unless the show parameter
; is set to false.
;
; The generated form is returned as a string.
;
; Sample form output (but confirm with code):
;
; <div id="settingsform">
;     <form id="PASettings">
;         <details class="set-cat" id="setcat-Account" open="">
;             <summary>Account</summary>
;             <div class="set-opt" id="setopt-username">
;                 <div id="setdesc-username" class="set-desc">Username<span id="setvalerr-username"
;                         class="set-err"></span></div>
;                 <div class="set-val"><input id="setval-username" type="text" onchange="handleText(this);"
;                         value="skl424"></div>
;             </div>
;             <div class="set-opt" id="setopt-password">
;                 <div id="setdesc-password" class="set-desc">Password<span id="setvalerr-password"
;                         class="set-err"></span></div>
;                 <div class="set-val"><input id="setval-password" type="password" onchange="handleText(this);"
;                         value=""></div>
;             </div>
;         </details>
;         <details class="set-cat" id="setcat-General" open="">
;             <summary>General</summary>
;             <div class="set-opt" id="setopt-MouseJiggler">
;                 <div id="setdesc-MouseJiggler" class="set-desc">Enable mouse jiggler to prevent the screen from going to
;                     sleep<span id="setvalerr-MouseJiggler" class="set-err"></span></div>
;                 <div class="set-val"><input id="setval-MouseJiggler" role="switch" oninput="handleCheckbox(this);"
;                         type="checkbox" checked=""></div>
;             </div>
;             <div class="set-opt" id="setopt-MouseJiggler_timeout">
;                 <div id="setdesc-MouseJiggler_timeout" class="set-desc set-indent1">Disable mouse jiggler after this
;                     many minutes of inactivity (0 = never disable)<span id="setvalerr-MouseJiggler_timeout"
;                         class="set-err"></span></div>
;                 <div class="set-val"><input id="setval-MouseJiggler_timeout" type="text" onchange="handleNum(this);"
;                         value="0"></div>
;             </div>
;             <div class="set-opt" id="setopt-UseVoice">
;                 <div id="setdesc-UseVoice" class="set-desc">Enable synthesized voice feedback<span
;                         id="setvalerr-UseVoice" class="set-err"></span></div>
;                 <div class="set-val"><input id="setval-UseVoice" role="switch" oninput="handleCheckbox(this);"
;                         type="checkbox" checked=""></div>
;             </div>
;             <div class="set-opt" id="setopt-Voice">
;                 <div id="setdesc-Voice" class="set-desc set-indent1">Which voice to use<span id="setvalerr-Voice"
;                         class="set-err"></span></div>
;                 <div class="set-val"><select id="setval-Voice" oninput="handleSelect(this);">
;                         <option>Dave</option>
;                         <option selected="">Zira</option>
;                     </select></div>
;             </div>
;         </details>
;     </form>
; </div>
;
SettingsGeneratePage(show := true) {
    static special := false

    ; Need to special case the storepassword setting depending on whether this is 
    ; a hospital workstation or a home workstation. The option is removed from the
    ; SettingsPage[] array if we are running on a hospital workstation.
    if !special && WorkstationIsHospital() {
        ; this is a hospital workstation
        for item in SettingsPage {
            if !IsSet(item) {
                ; this array element has been deleted, skip to next one
                continue    ; for
            }
            if item == ">storepassword" {
                ; this is the setting we need to delete
                SettingsPage.Delete(A_Index)
                special := true     ; so we don't have to do this again
                break           ; for
            }
        }
    }

    ; intialize the form to be generated
    form := ''
    form .= '<form id="PASettings">'

    in_cat := false     ; track whether we are inside a category section so we remember to close it

    for optname in SettingsPage {

        if !IsSet(optname) {
            ; this array element has been deleted, skip to next one
            continue    ; for
        }

        if (SubStr(optname, 1, 1) == "#") {
            ; this is a Category heading

            catname := SubStr(optname, 2)

            if in_cat {
                form .= '</details>'
            }
            form .= '<details class="set-cat" id="setcat-' catname '" open>'
            form .= '<summary>' catname '</summary>'
            in_cat := true

        } else {
            ; this is an Option with name (key) optname

            ; indent contains the number indents to insert (0, 1, or 2)
            ; if indent is greater than 0, then the class set-indentX is added to
            ; the description div, where X is either 1 or 2, and css will add padding-left
            indent := 0
            while SubStr(optname, 1, 1) == ">" {
                indent++
                optname := SubStr(optname, 2)
            }
    
            switch Setting[optname].type {

                case "bool":
                    ; output a toggle switch

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    
                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(Setting[optname].description) '<span id="setvalerr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" role="switch" oninput="handleCheckbox(this);" type="checkbox"' (Setting[optname].value ? ' checked>' : '>')
                    form .= '</div>'
                    form .= '</div>'

                case "num":
                    ; output a numerical field

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    
                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(Setting[optname].description) '<span id="setvalerr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="text" onchange="handleNum(this);" value="' Setting[optname].value '">'
                    form .= '</div>'
                    form .= '</div>'
              
                case "text":
                    ; output a text field

                    form .= '<div class="set-opt" id="setopt-' optname '">'

                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(Setting[optname].description) '<span id="setvalerr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="text" onchange="handleText(this);" value="' Setting[optname].value '">'
                    form .= '</div>'
                    form .= '</div>'
              
                case "select":
                    ; output a select list

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    
                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(Setting[optname].description) '<span id="setvalerr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<select id="setval-' optname '" oninput="handleSelect(this);">'

                    ; create options for the select list from the map of possible values
                    ; displayed options are the keys from the possible map
                    for k, v in Setting[optname].possible {
                        ; if k matches the current value PASettings[optname].key, then add the selected attribute
                        form .= '<option' ((k == Setting[optname].key) ? ' selected>' : '>') k '</option>'
                    }

                    form .= '</select>'
                    form .= '</div>'
                    form .= '</div>'

                case "special":
                    ; output a text field or a password field

                    form .= '<div class="set-opt" id="setopt-' optname '">'

                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(Setting[optname].description) '<span id="setvalerr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    if Setting[optname].name == "password" {
                        form .= '<input id="setval-' optname '" type="password" onchange="handleText(this);" value="' Setting[optname].value '">'
                    } else {
                        form .= '<input id="setval-' optname '" type="text" onchange="handleText(this);" value="' Setting[optname].value '">'
                    }
                    form .= '</div>'
                    form .= '</div>'
              
                default:
                    
            }

        }
    }
    
    if in_cat {
        form .= '</details>'
    }
    form .= '</form>'

    if show {
        ; replace current form on GUI Settings page
        GUIPost("settingsform", "innerHTML", form)
    }
    
    return form
}




/**********************************************************
** Web callback form handler functions defined by this module
*/


; HandleFormInput() is called by JS in response to changes made to form elements.
;
; HandleFormInput() uses Setting[] map to validate and save the new values.
;
; If validation succeeds, the new value is saved in Setting[] and 
; also written to the settings.ini file.
;
; If validation fails, an error message is displayed and the previous setting
; is kept.
;
HandleFormInput(WebView, id, newval) {

    ; strip the prefix (e.g. "setval-", or "tab-") from the id name to get the key 
    ; if there is no hyphen, then assume no prefix and use the id as is
    ; as the key to Setting[] map
    h := InStr(id,"-")
    optname := SubStr(id, 1 + h)
    if h {
        errid := SubStr(id, 1, h - 1) . "err-" . optname
    } else {
        errid := "err-" . optname
    }

    sett := Setting[optname]
    
    if sett.isValid(newval) {

        ; validation succeeded, change the setting's value
        sett.value := newval
        ; clear any previous error
        GUIPost(errid, "innerHTML", "")

    } else {

        ; validation failed, don't change the setting's value
        ; display error message
        switch sett.type {
            case "num":
                if IsObject(sett.possible) {
                    GUIPost(errid, "innerHTML", "<br />⚠️ Value must be between " sett.possible[1] " and " sett.possible[2])
                } else {
                    GUIPost(errid, "innerHTML", "<br />⚠️ Invalid number")
                }
            case "text", "special":
                if sett.possible > 0 {
                    GUIPost(errid, "innerHTML", "<br />⚠️ Maximum " sett.possible " characters")
                } else {
                    GUIPost(errid, "innerHTML", "<br />⚠️ Invalid entry")
                }
            case "select":
                GUIPost(errid, "innerHTML", "<br />⚠️ Invalid choice")
            default:
                GUIPost(errid, "innerHTML", "<br />⚠️ Invalid input - error unkonwn")
        }
    }

}
