/* PASettings.ahk
**
** Settings functions for PACS Assistant
**
**
*/



#Requires AutoHotkey v2.0
#SingleInstance Force







; PASettings is the global object that holds user modifiable settings for PACS Assistant.
; Each entry is a {"key", Setting()} pair, defined below.
global PASettings := Map()

; PASettingsList is an ordered array that determines the order in which settings 
; are shown on the GUI Settings page. It contains an array of keys (as they appear 
; in PASettings).
;
; Settings can be grouped into categories. When the special key of the
; format ":CategoryName" appears, it defines the start of a new category with
; name CategoryName.
global PASettingsList := Array()


; Class to hold for an individual setting that can be performed by PACS Assistant
; possible values for settingtype:
;   "bool"      - possiblevalues is assumed to be [true, false]
;   "num"       - possiblevalues is array of [lowerbound, upperbound]
;   "text"      - possiblevalues not used
;   "select"    - possiblevalues is map of options ["opt1key", "opt1val", "opt2key", "opt2val", "opt3key", "opt3val", ...]
class Setting {
	type := ""              ; Type of value
    value := ""		    	; Current value
	possible := 0			; Array (Map) of possible values for this setting
	description :=""		; Description of this setting, shown to user on settings page

	__New(settingtype := "", newvalue := false, possiblevalues:= 0, desc := "") {
        this.type := settingtype
		this.value := newvalue
		if IsObject(possiblevalues) {
			this.possible := possiblevalues.Clone()
		}else {
			this.possible := 0
		}
		this.description := desc
	}
}



; All user modifiable settings are defined here 
;
PASettings["MouseJiggler"] := Setting("bool", true, [true, false], "Jiggle the mouse occasionally to keep the screen from going to sleep.")

PASettings["ClickLock"] := Setting("select", "Manual", ["Off", "Off", "Manual", "Manual", "Auto", "Auto"], "Click lock setting for left mouse button.")
PASettings["ClickLock_interval"] := Setting("num", 2000, [500, 5000], "For Auto click lock, how long (in ms) the left mouse button needs to be held down before click lock activates.")

PASettings["EIcollaborator_show"] := Setting("bool", false, [true, false], "Show Collaborator window at EI startup.")

PASettings["PSlogout_dismiss"] := Setting("bool", true, [true, false], "Automatically dismiss PowerScribe 'Logout anyway?' message.")
PASettings["PSlogout_dismiss_reply"] := Setting("select", "&Yes", ["Yes", "&Yes", "No", "&No"], "Reply to PowerScribe 'Logout anyway?' message.")

PASettings["PSsavespeech_dismiss"] := Setting("bool", false, [true, false], "Automatically dismiss PowerScribe 'Save changes to speech files?' message.")
PASettings["PSsavespeech_dismiss_reply"] := Setting("select", "&No", ["Yes", "&Yes", "No", "&No"], "Reply to PowerScribe 'Save speech files?' message.")

PASettings["PSconfirmaddendum_dismiss"] := Setting("bool", true, [true, false], "Automatically dismiss PowerScribe 'Create addendum?' message.")
PASettings["PSconfirmaddendum_dismiss_reply"] := Setting("select", "&Yes", ["Yes", "&Yes", "No", "&No"], "Reply to PowerScribe 'Create addendum?' message.")

PASettings["PS_dictate_autoon"] := Setting("bool", true, [true, false], "Automatically turn on microphone when starting to dictate a report or addendum.")
PASettings["PS_dictate_idletimeout"] := Setting("num", 0, [0, 3600], "Turn off microphone after this many minutes of inactivity (0 = never turn off).")

PASettings["PSmicrophone_dismiss"] := Setting("bool", true, [true, false], "Automatically dismiss PowerScribe 'Microphone disconnected' message.")
PASettings["PSmicrophone_dismiss_reply"] := Setting("select", "OK", ["OK", "OK"], "Reply to PowerScribe 'Microphone disconnected' message.")

PASettings["PScenter_dialog"] := Setting("bool", true, [true, false], "Always position confirmation dialogs and spelling window over the main PowerScribe window.")

PASettings["PSspelling_autoclose"] := Setting("bool", true, [true, false], "Close the Spelling popup window unless the mouse is over the PowerScribe window.")

PASettings["PA_voice"] := Setting("select", 1, [0, "Dave", 1, "Zira", 2, "Mark"], "Synthesized voice (0 for Dave, 1 for Zira, 2 for Mark).")

PASettings["PA_username"] := Setting("text", "", 20, "Username")
PASettings["PA_password"] := Setting("text", "", 20, "Password")


; Organize the settings to be displayed on the GUI Settings page
PASettingsList.Push(":Username/Password")
PASettingsList.Push("PA_username")
PASettingsList.Push("PA_password")

PASettingsList.Push(":General")
PASettingsList.Push("MouseJiggler")
PASettingsList.Push("ClickLock")
PASettingsList.Push("ClickLock_interval")

PASettingsList.Push(":EI")
PASettingsList.Push("EIcollaborator_show")

PASettingsList.Push(":PowerScribe")
PASettingsList.Push("PS_dictate_autoon")
PASettingsList.Push("PS_dictate_idletimeout")
PASettingsList.Push("PSconfirmaddendum_dismiss")
PASettingsList.Push("PSconfirmaddendum_dismiss_reply")
PASettingsList.Push("PSlogout_dismiss")
PASettingsList.Push("PSlogout_dismiss_reply")
PASettingsList.Push("PSsavespeech_dismiss")
PASettingsList.Push("PSsavespeech_dismiss_reply")
PASettingsList.Push("PSmicrophone_dismiss")
PASettingsList.Push("PSmicrophone_dismiss_reply")
PASettingsList.Push("PScenter_dialog")
PASettingsList.Push("PSspelling_autoclose")





; Display settings form on Settings page of GUI
;



; Generates and returns an HTML form from PASettings[]
;
; Sample form output:
;
; <form id="PAsettings">
;   <details class="set-cat" id="setcat-General" open>
;     <summary>General</summary>
;   
;     <div class="set-opt" id="setopt-MouseJiggler">
;       <div class="set-desc">Jiggle the mouse occasionally to keep the screen from going to sleep.</div>
;       <div class="set-val">
;         <input id="setval-MouseJiggler" type="checkbox" value="1">
;       </div>
;     </div>
;
;     <div id="setopt-PA_username" class="set-opt">
;       <div class="set-desc">Username</div>
;       <div class="set-val">
;         <input id="setval-PA_username" type="text" value="skl424">
;       </div>
;     </div>
;
;     <div id="setopt-PA_password" class="set-opt">
;       <div class="set-desc">Password</div>
;       <div class="set-val">
;         <input id="setval-PA_password" type="password">
;       </div>
;     </div>
;
;     <div id="setopt-ClickLock" class="set-opt">
;       <div class="set-desc">Enable Click lock for left mouse button.</div>
;       <div class="set-val">
;         <select id="setval-ClickLock" >
;           <option value="Off">Off</option>
;           <option value="Manual" selected>Manual</option>
;           <option value="Auto">Auto</option>
;         </select>   
;       </div>
;     </div>
;
;   </details>
; </form>
;
;
;
PASettings_HTMLForm() {
    global PASettings
    global PASettingsList
    static form := ''              ; holds the generated form that is returned

    ; intialize the return form
    form := ''
    form .= '<form id="PAsettings">'

    in_cat := false     ; track whether we are inside a category section so we remember to close it

    for i, optname in PASettingsList {

        if (SubStr(optname, 1, 1) == ":") {
            ; this is a Category heading

            catname := SubStr(optname, 2)

            if in_cat {
                form .= '</details>'
            }
            form .= '<details class="set-cat" id="setcat-' catname '" open>'
            form .= '<summary>' catname '</summary>'
            in_cat := true

        } else {
            ; this is an Option

            switch PASettings[optname].type {
                case "bool":
                    ; output a toggle switch

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    form .= '<div class="set-desc">' EscapeHTML(PASettings[optname].description) '</div>'
                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="checkbox" value="' PASettings[optname].value '">'
                    form .= '</div>'
                    form .= '</div>'

                case "num":
                    ; output a numerical field

                case "text":
                    ; output a text field

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    form .= '<div class="set-desc">' EscapeHTML(PASettings[optname].description) '</div>'
                    form .= '<div class="set-val">'
                    form .= '<input id="setval-' optname '" type="text" value="' PASettings[optname].value '">'
                    form .= '</div>'
                    form .= '</div>'
              
                case "select":
                    ; output a select list

                    form .= '<div class="set-opt" id="setopt-' optname '">'
                    form .= '<div class="set-desc">' EscapeHTML(PASettings[optname].description) '</div>'
                    form .= '<div class="set-val">'

                    form .= '<select id="setval-' optname '" >'
                    
                    for k, v in PASettings[optname].possible {
                        ; if v matches the current value PASettings[optname].value, then add the selected attribute
                        form .= '<option value="' v '"' (v == PASettings[optname].value ? 'selected' : '') '>' k '</option>'
                    }
                    form .= '</select>'
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

    return form
}