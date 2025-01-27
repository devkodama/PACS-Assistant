/**
 * PAInfo.ahk
 * 
 * Classes for handling Patient Info, Study Info, other pertinent information.
 *
 *
 */

#Requires AutoHotkey v2.0
#SingleInstance Force



/*
** Includes
*/

#include <DateParse>



/*
** Globals
*/

INFO_DOB_FORMAT := "M/d/yyyy"




; Patient class
;
; Stores info about a patient
;
; Properties (some may be read only):
; 
;   lastname        "Smith"
;   firstname       "John E"
;   lastfirst       "Smith, John E"
;   firstlast       "John E Smith"
;   dob             "4/27/1992"
;   dobraw          "19920427"
;   age             "34Y"
;   agelong         "34 year old"
;   sex             "M"
;   sexlong         "male"
;   other           array of uncategorized data, in format of ["value1", "value2", ...]
;
class Patient {
    changed := true             ; set to true whenever a property is updated
    _lastname := ""
    _firstname := ""
    _dob := ""
    _sex := ""
    other := Array()

    lastname {
        get {
            return this._lastname
        }
        set {
            this._lastname := Trim(StrTitle(value))
            this.changed := true
        }
    }
    firstname {
        get {
            return this._firstname
        }
        set {
            this._firstname := Trim(StrTitle(value))
            this.changed := true
        }
    }
   
;    firstlast => this.firstname ? (this.firstname . " " . this.lastname) : ""
;    lastfirst => this.lastname ? (this.lastname . ", " . this.firstname) : ""

    firstlast {
        get {
            if !this._firstname || !this._lastname {
                return ""
            } else {
                return this._firstname . " " . this._lastname
            }
        }
        set {
            ; assumes format "FIRST LAST"
            ; if more than one space, then what comes after the last space is taken as the last name,
            ; and everything before that is the first name
            val := Trim(value)
            split := InStr(val, " ", -1)
            if (split < 2) || (split > StrLen(val) - 1) {
                this._firstname := ""
                this._lastname := ""
            } else {
                first := Trim(SubStr(val, 1, split - 1))
                last := Trim(SubStr(val, split + 1))
                if first = "" || last = "" {
                    this._firstname := ""
                    this._lastname := ""
                } else {
                    this._firstname := first
                    this._lastname := last
                }
            }
            this.changed := true
        }
    }

    lastfirst {
        get {
            if !this._lastname || !this._firstname {
                return ""
            } else {
                return this._lastname . ", " . this._firstname
            }
        }
        set {
            ; assumes format "LAST, FIRST" with only a single comma
            ; if more than one comma, ignore stuff after the second comma
            ; if doesn't have two parts, set to blank
            parts := StrSplit(value, ",")
            if parts.Length < 2 {
                this._lastname := ""
                this._firstname := ""
            } else {
                this._lastname := Trim(StrTitle(parts[1]))
                this._firstname := Trim(StrTitle(parts[2]))
            }
            this.changed := true
        }
    }

    dob {
        ; dob is stored internally in YYYYMMDDHH24MISS format (time part is blank)
        ; returned value is formatted per INFO_DOB_FORMAT
        get {
            if !this._dob {
                return ""
            }
            return FormatTime(this._dob, INFO_DOB_FORMAT)
        }
        set {
            if value {
                d := DateParse(value)
                this._dob := SubStr(d, 1, 8)        ; truncate time portion
                this.changed := true
            } else {
                this._dob := ""
            }
            this.changed := true
        }

    }

    dobraw {
        ; return dob in raw internally stored format (YYYYMMDDHH24MISS format (time part is blank) )
        get {
            return this._dob
        }
        set {
            ; no verification on set
            this._dob := value
            this.changed := true
        }

    }

    age {
        ; returns age string in largest non-zero units
        ; e.g. 25 year 3 months 2 days => "25Y" (agelong = "25 year old")
        ; e.g. 0 year 7 months 18 days => "7M" (agelong = "7 month old")
        ; e.g. 0 year 0 months 12 days => "12D" (agelong = "12 day old")
        ; e.g. 0 year 0 months 0 days => "0D" (agelong = "newborn")
        get {
            static daysinmonth := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

            if !this._dob {
                return ""
            }
            dobYYYY := SubStr(this._dob, 1, 4)
            dobMM := SubStr(this._dob, 5, 2)
            dobDD := SubStr(this._dob, 7, 2)
            diffYYYY := A_YYYY - dobYYYY
            diffMM := A_MM - dobMM
            diffDD := A_DD - dobDD

;            MsgBox(diffYYYY . " " . diffMM . " " . diffDD . " days in " . dobMM . "=" . daysinmonth[dobMM])

            if diffYYYY > 0 {
                if diffMM < 0 || (diffMM = 0 && diffDD < 0) {
                    diffYYYY--
                    diffMM += 12
                }
                if diffYYYY > 0 {
                    return diffYYYY . "Y"
                }
            }
            if diffMM > 0 {
                if diffDD < 0 { 
                    diffMM--
                    diffDD += daysinmonth[dobMM]
                    
                    ; leap year correction
                    if dobMM = 2 && ( (Mod(dobYYYY, 4) = 0 && Mod(dobYYYY,100) != 0) || Mod(dobYYYY, 400) = 0 ) {
                        diffDD++
                    }
                }
                if diffMM > 0 {
                    return diffMM . "M"
                }
            }
            if diffDD > 0 {
                return diffDD . "D"
            }
            return "0D"            
        }
    }

    agelong {
        get {
            if !this._dob {
                return ""
            }
            agestring := this.age
            if agestring = "0D" {
                return "newborn"
            }
            agestring := StrReplace(agestring, "Y", " year old", true, &n)
            if !n {
                agestring := StrReplace(agestring, "M", " month old", true, &n)
                if !n {
                    agestring := StrReplace(agestring, "D", " day old", true, &n)
                }
            }
            return 
        }
    }

    sex {
        get {
            if !this._sex {
                return ""
            }
            return this._sex
        }
        set {
            ; must exactly match (case-insensitive) one of: "f", "female", "m", "male", "o", "other"
            ; anything else is recorded as empty string
            ; value is stored as "F", "M", or "O" (in caps)
            s := StrUpper(Trim(value))
            switch s {
                case "F", "FEMALE":
                    this._sex := "F"
                case "M", "MALE":
                    this._sex := "M"
                case "O", "OTHER":
                    this._sex := "O"
                default:
                    this._sex := ""
            }
            this.changed := true
        }
    }

    sexlong {
        get {
            if !this._sex {
                return ""
            }
            switch this._sex {
                case "F":
                    return "female"
                case "M":
                    return "male"
                case "O":
                    return "other"
            }
        }
    }


    __New() {
    }


    
}



; Study class
;
; Stores info about a single study
;
; Properties (some are read only):
; 
;   lastfirst       "Smith, John E"
;   dobraw          "19920427"
;
;   accession       "ADV7044722063"
;   description     "CT CHEST ABDOMEN PELVIS WO IV CONTRAST"
;   facility        "AH UCM La Grange"
;   patienttype     "Ambulatory"
;   priority        "STAT!"
;   orderingmd      "BYAMBAA, TUMENDEMBEREL"
;   referringmd      "BYAMBAA, TUMENDEMBEREL"
;   reason          "Rib fracture"
;   techcomments    "cough since october"
;   other           array of uncategorized data, in format of ["value1", "value2", ...]
;
;   modality        "CT"
;   laterality      ""
;   
; The properties lastfirst and dobraw are used to match against Patient objects to ensure a match
;
; The properties modality and laterality are derived properties, should not be set directly
;
class Study {
    changed := true             ; set to true whenever a property is updated

    lastfirst := ""
    dobraw := ""
    _accession := ""
    _description := ""
    _facility := ""
    _patienttype := ""
    _priority := ""
    _orderingmd := ""
    _referringmd := ""
    _reason := ""
    _techcomments := ""
    other := Array()
    _modality := ""
    _laterality := ""

    accession {
        get {
            return this._accession
        }
        set {
            this._accession := StrUpper(Trim(value))
            this.changed := true
        }
    }

    description {
        get {
            return this._description
        }
        set {
            desc := StrUpper(Trim(value))
            this._description := desc
            if StrLen(desc) >= 2 {
                this._modality := SubStr(desc, 1, 2)
            } else {
                this._modality := ""
            }
            this.changed := true
        }
    }

    facility {
        get {
            return this._facility
        }
        set {
            this._facility := StrUpper(Trim(value))
            this.changed := true
        }
    }

    patienttype {
        get {
            return this._patienttype
        }
        set {
            this._patienttype := StrUpper(Trim(value))
            this.changed := true
        }
    }

    priority {
        get {
            return this._priority
        }
        set {
            this._priority := StrUpper(Trim(value))
            this.changed := true
        }
    }

    orderingmd {
        get {
            return this._orderingmd
        }
        set {
            this._orderingmd := StrUpper(Trim(value))
            this.changed := true
        }
    }

    referringmd {
        get {
            return this._referringmd
        }
        set {
            this._referringmd := StrUpper(Trim(value))
            this.changed := true
        }
    }

    reason {
        get {
            return this._reason
        }
        set {
            this._reason := Trim(value)
            this.changed := true
        }
    }
    
    techcomments {
        get {
            return this._techcomments
        }
        set {
            this._techcomments := Trim(value)
            this.changed := true
        }
    }

    modality {
        get {
            return this._modality
        }
    }

    laterality {
        get {
            return this._laterality
        }
        set {
            if this._laterality = "" {
                this._laterality := StrUpper(Trim(value))
                this.changed := true
            }
        }
    }

}

