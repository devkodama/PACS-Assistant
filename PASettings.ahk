/* PASettings.ahk
**
** Settings functions for PACS Assistant
**
**
*/



#Requires AutoHotkey v2.0
#SingleInstance Force



/*
** Includes
*/

#Include <Cred>

#Include Utils.ahk
#Include PAGlobals.ahk



; PASettingsPage is an ordered array of keys that determines which settings
; are shown and the order in which they are shown on the GUI Settings page. 
;
; Settings can be grouped into categories. When the special key of the
; format ":CategoryName" appears, it defines the start of a new category with
; name CategoryName.
PASettingsPage := Array()


; Credential class
;
; Stores a set of credentials for PACS Assistant
;
class Credential {
    username := ""      ; username
    password := ""      ; password
}


; Class to hold for an individual setting that within PACS Assistant
;
; Possible values for settingtype:
;   "bool"      - possiblevalues is ignored, as it assumed to be [true, false]
;   "num"       - possiblevalues is an array of [lowerbound, upperbound], or empty if no limits
;   "text"      - possiblevalues is an integer defining maximum length of text
;   "select"    - possiblevalues is a Map of options, e.g. Map("opt1key", "opt1val", "opt2key", "opt2val", "opt3key", "opt3val", ...)
;   "special"   - possiblevalues is a string defining what type of special value this is
;
class Setting {
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
    ;   MsgBox(s.mappedvalue)   ; => "No"
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
            global PASettings

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
                                ; update GUI to show current user
                                if newval {
                                    PAGui_Post("curuser", "innerHTML", " - " . newval)
                                } else {
                                    PAGui_Post("curuser", "innerHTML", "")
                                }
                                ; update the user-specific .ini filename
                                if newval = "" {
                                    PASettings["inifile"].value := ""
                                } else {
                                    PASettings["inifile"].value := FILE_SETTINGSBASE "." newval ".ini"
                                }
                                ; Read the new user's saved settings
                                PASettings_ReadSettings()

                                ; Update the displayed form
                                PASettings_HTMLForm()
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
            ; Save the update setting to the user-specific .ini file
            this._SaveSetting()
        }
    }

    key {
        get {
            return this._key
        }
    }

    ; Call to save the current Setting object to the current settings.ini file(s).
    ;
    ; There is a master settings.ini file used by PACS Assistant. Each user also
    ; has a separate settings.username.ini file, where username is replaced by 
    ; the actual username. The username must have a value stored in 
    ; PASettings["username"].
    ;
    _SaveSetting() {
;        PAToolTip(this.name " / " this._value " / " )
        switch this.type {
            case "special":
                ; special options handling (e.g. username, password)
                switch this.name {
                    case "username":
                        if this._value {
                            inifile := FILE_SETTINGSBASE . ".ini"
                            
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
                        ; Don't save to disk
                        ; Save to local store if non-empty
                        if this._value {
                                CredWrite("PA_cred_" . PASettings["username"].value, PASettings["username"].value, this._value)
                        }
                    case "inifile":
                        ; don't save this anywhere
                    default:
                }
            case "select":
                ; in this case, save this._key instead of this._value)
                if PASettings.Has("inifile") && PASettings["inifile"].value {
                    IniWrite(this._key, PASettings["inifile"].value, "PASettings", this.name) 
                }
            default:
                ; save this._value
                if PASettings.Has("inifile") && PASettings["inifile"].value {
                    IniWrite(this._value, PASettings["inifile"].value, "PASettings", this.name) 
                }
        } 
    }

    ; called when a new Setting object is created
    ; no bounds checking on the passed defaultvalue
    ; current value of the Settting is set to the same as the default value
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
                    return true
                } else {
                    if newval >= this.possible[1] && newval <= this.possible[2] {
                        return true
                    } else {
                        return false
                    }
                }
            case "text", "special":
                if StrLen(newval) <=  this.possible {
                    return true
                } else {
                    return false
                }
            case "select":
                return this.possible.Has(newval)
            default:
                return false
        }
    }
}



; Program-wide modifiable settings are defined here in the PASettings[] Map
; object. Not all settings have to be exposed to the user on the GUI 
; Settings page.
;
; Note that username, password, and inifile are special cases, even
; though they are stored in the PASettings[] map. They are treated differently 
; by functions that handle changes to the settings (e.g. HandleFormInput(), and 
; by the value property setter and getter).
;
; PASettings["username"] must be set up first, before password
;
PASettings["username"] := Setting("username", "special", "", 20, "Username")
PASettings["password"] := Setting("password", "special", "", 20, "Password")
PASettings["inifile"] := Setting("inifile", "special", "", 0, "Current user-specific .ini file")

PASettings["MouseJiggler"] := Setting("MouseJiggler", "bool", true, , "Enable mouse jiggler to prevent the screen from going to sleep")

PASettings["Voice"] := Setting("Voice", "select", "Zira", Map("Dave", 0, "Zira", 1, "Mark", 2), "Which synthesized voice to use")

PASettings["ClickLock"] := Setting("ClickLock", "select", "Manual", Map("Off", "Off", "Manual", "Manual"), "Enable Click Lock for left mouse button")
PASettings["ClickLock_interval"] := Setting("ClickLock_interval", "num", 2000, [500, 5000], "For Auto click lock, how long (in ms) the left mouse button needs to be held down before click lock activates.")

PASettings["EIcollaborator_show"] := Setting("EIcollaborator_show", "bool", false, , "Show Collaborator window at EI startup")

PASettings["PSlogout_dismiss"] := Setting("PSlogout_dismiss", "bool", true, , "Automatically answer Yes to logout confirmation messages")
PASettings["PSlogout_dismiss_reply"] := Setting("PSlogout_dismiss_reply", "select", "Yes", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

PASettings["PSsavespeech_dismiss"] := Setting("PSsavespeech_dismiss", "bool", false, , "Automatically answer 'Save changes to speech files?' message")
PASettings["PSsavespeech_dismiss_reply"] := Setting("PSsavespeech_dismiss_reply", "select", "No", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

PASettings["PSconfirmaddendum_dismiss"] := Setting("PSconfirmaddendum_dismiss", "bool", true, , "Automatically answer Yes to 'Create addendum?' message")
PASettings["PSconfirmaddendum_dismiss_reply"] := Setting("PSconfirmaddendum_dismiss_reply", "select", "Yes", Map("Yes", "&Yes", "No", "&No"), "Answer to give")

PASettings["PS_dictate_autoon"] := Setting("PS_dictate_autoon", "bool", true, , "Automatically turn on microphone when opening a report and off when closing a report")

PASettings["PS_dictate_idleoff"] := Setting("PS_dictate_idleoff", "bool", true, , "Automatically turn microphone after a period of inactivity")
PASettings["PS_dictate_idletimeout"] := Setting("PS_dictate_idletimeout", "num", 1, [1, 720], "After how many minutes?")

PASettings["PSmicrophone_dismiss"] := Setting("PSmicrophone_dismiss", "bool", true, , "Automatically dismiss 'Microphone disconnected' message")
PASettings["PSmicrophone_dismiss_reply"] := Setting("PSmicrophone_dismiss_reply", "select", "OK", Map("OK", "OK"), "Reply to PowerScribe 'Microphone disconnected' message.")

PASettings["PScenter_dialog"] := Setting("PScenter_dialog", "bool", true, , "Always center message boxes over the main window")

PASettings["PSspelling_autoclose"] := Setting("PSspelling_autoclose", "bool", true, , "Auto close the Spelling window except within the PowerScribe window")



; The settings to be displayed on the GUI Settings page are defined here in 
; the PASettingsPage[] Array object.
;
PASettingsPage.Push("#Account")
PASettingsPage.Push("username")
PASettingsPage.Push("password")

PASettingsPage.Push("#General")
PASettingsPage.Push("MouseJiggler")
PASettingsPage.Push("Voice")

PASettingsPage.Push("#EI")
PASettingsPage.Push("EIcollaborator_show")
PASettingsPage.Push("ClickLock")
; PASettingsPage.Push(">ClickLock_interval")

PASettingsPage.Push("#PowerScribe")
PASettingsPage.Push("PS_dictate_autoon")
PASettingsPage.Push("PS_dictate_idleoff")
PASettingsPage.Push(">PS_dictate_idletimeout")
PASettingsPage.Push("PSconfirmaddendum_dismiss")
PASettingsPage.Push("PSlogout_dismiss")
PASettingsPage.Push("PSsavespeech_dismiss")
PASettingsPage.Push(">PSsavespeech_dismiss_reply")
PASettingsPage.Push("PSmicrophone_dismiss")

PASettingsPage.Push("PScenter_dialog")
PASettingsPage.Push("PSspelling_autoclose")



; Call this to initially set the current user from the settings.ini file.
; Updates PASettings[] and CurrentUserCredentials
PASettings_Init() {
    inifile := FILE_SETTINGSBASE . ".ini"
                            
    curuser := IniRead(inifile, "Users", "curuser", "")
    if curuser !="" {
        PASettings["username"].value := curuser
    }                       
}


; Reads all the settings from the user-specific .ini file for the current user.
; Settings not previously saved are set to the default setting.
;
; The current user is specified by PASettings["username"].
; The current user-specific .ini file is specified by PASettings["inifile"].
;
; Updates "special" setting for password by reading from local store.
;
PASettings_ReadSettings() {
    global PASettings
    global CurrentUserCredentials

    ; ensure username has a value
    if PASettings["username"].value {

        inifile := PASettings["inifile"].value
        readvalue := ""

        for key, sett in PASettings {
            switch sett.type {
                case "special":
                    if sett.name == "password" {
                        ; try to get the password from local storage
                        cred := CredRead("PA_cred_" . PASettings["username"].value)
                        if cred {
                            PASettings["password"].value := cred.password
                            CurrentUserCredentials.password := cred.password
                        } else {
                            PASettings["password"].value := ""
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
                        PASettings[key].value := readvalue
                    } else {
                        PASettings[key].value := PASettings[key].default
                    }
            }
        }

    }
}









; Generates an HTML form from PASettings[] and PASettingsPage[] and returns it
; as a string.
;
; The generated form is inserted into div.#settingsform on the GUI
; (replacing any previous contents of innerHTML), unless the show parameter
; is false, in which case the HTML form is only returned as a string.
;
; Sample form output:
;
;
;
PASettings_HTMLForm(show := true) {
    
    ; intialize the form to be generated
    form := ''
    form .= '<form id="PASettings">'

    in_cat := false     ; track whether we are inside a category section so we remember to close it

    for i, optname in PASettingsPage {

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
    
            switch PASettings[optname].type {

                case "bool":
                    ; output a toggle switch

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    
                    if indent {
                        form .= '<div id="setdesc-' optname '" class="set-desc set-indent' indent '">'
                    } else {
                        form .= '<div id="setdesc-' optname '" class="set-desc">'
                    }
                    form .= EscapeHTML(PASettings[optname].description) '<span id="seterr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" role="switch" oninput="handleCheckbox(this);" type="checkbox"' (PASettings[optname].value ? ' checked>' : '>')
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
                    form .= EscapeHTML(PASettings[optname].description) '<span id="seterr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="text" onchange="handleNum(this);" value="' PASettings[optname].value '">'
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
                    form .= EscapeHTML(PASettings[optname].description) '<span id="seterr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="text" onchange="handleText(this);" value="' PASettings[optname].value '">'
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
                    form .= EscapeHTML(PASettings[optname].description) '<span id="seterr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    form .= '<select id="setval-' optname '" oninput="handleSelect(this);">'

                    ; create options for the select list from the map of possible values
                    ; displayed options are the keys from the possible map
                    for k, v in PASettings[optname].possible {
                        ; if k matches the current value PASettings[optname].key, then add the selected attribute
                        form .= '<option' ((k == PASettings[optname].key) ? ' selected>' : '>') k '</option>'
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
                    form .= EscapeHTML(PASettings[optname].description) '<span id="seterr-' optname '" class="set-err"></span></div>'

                    form .= '<div class="set-val">'
                    if PASettings[optname].name == "password" {
                        form .= '<input id="setval-' optname '" type="password" onchange="handleText(this);" value="' PASettings[optname].value '">'
                    } else {
                        form .= '<input id="setval-' optname '" type="text" onchange="handleText(this);" value="' PASettings[optname].value '">'
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
        PAGui_Post("settingsform", "innerHTML", form)
    }
    
    return form
}



; Web callback form handler functions
;
; HandleFormInput() is called by JS in response to changes made to form elements.
;
; HandleFormInput() uses PASettings[] map to validate and save the new values.
;
; If validation succeeds, the new value is saved in PASettings[] and 
; also written to the settings.ini file.
;
; If validation fails, an error message is displayed and the previous setting
; is kept.
;
HandleFormInput(WebView, id, newval) {

    ; strip the prefix "setval-" (7 chars) from the id name to get the key 
    ; to PASettings[] map
    optname := SubStr(id, 8)

    sett := PASettings[optname]
    
    if sett.isValid(newval) {

        ; validation succeeded, change the setting's value
        sett.value := newval
        ; clear any previous error
        PAGui_Post("seterr-" . optname, "innerHTML", "")

    } else {

        ; validation failed, don't change the setting's value
        ; display error message
        switch sett.type {
            case "num":
                if IsObject(sett.possible) {
                    PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Value must be between " sett.possible[1] " and " sett.possible[2])
                } else {
                    PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Invalid number")
                }
            case "text", "special":
                if sett.possible > 0 {
                    PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Maximum " sett.possible " characters")
                } else {
                    PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Invalid entry")
                }
            case "select":
                PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Invalid choice")
            default:
                PAGui_Post("seterr-" . optname, "innerHTML", "<br />⚠️ Invalid input - error unkonwn")
        }
    }

}