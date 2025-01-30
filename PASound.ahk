/* PASound.ahk
**
** Provide audio feedback for PACS Assistant operations
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force


/*
** Global variables and constants
*/





; A sound/sounds to be played.
; Can be a spoken voice phrase, audio file (.wav), and/or a beep.
;
; To produce standard system sounds, specify an asterisk followed by a 
; number as shown below:
;
; "*-1" = Simple beep. If the sound card is not available, the sound is generated using the speaker.
; "*16" = Hand (stop/error)
; "*32" = Question
; "*48" = Exclamation
; "*64" = Asterisk (info)
;
;
class SoundItem {
    voice := ""
    audio := ""
    beepfreq := 0

    __New(argvoi := "", argaud := "", argbeep := 0, statusmsg := "") {
        this.voice := argvoi
        this.audio := argaud
        this.beepfreq := argbeep
        this.statusmessage := statusmsg

        ; if SubStr(arg,-4) = ".wav" {
        ;     this.audio := arg
        ; } else if IsInteger(arg) {
        ;     this.beepfreq := Number(arg)
        ; } else {
        ;     this.voice := arg
        ; }
    }
}


; Sounds maps PA events to voice or audio feedback
Sounds := Map()
Sounds["sign report"] := SoundItem("Sign report", , , "Sign report")
;Sounds["sign report"] := SoundItem(, A_WinDir "\Media\tada.wav")
Sounds["draft report"] := SoundItem("Save as draft", , , "Save as draft")
Sounds["prelim report"] := SoundItem("Preliminary report", , , "Save as preliminary report")
Sounds["EPIC"] := SoundItem("EPIC was clicked")
Sounds["toggle dictate"] := SoundItem(, , 392)


; Global sound object
_SoundObj := ComObject("SAPI.SpVoice")



/***********************************************/





;
;
;
PASound(message) {
    global _SoundObj
    global Sounds

    if Sounds.Has(message) {
    
        sound := Sounds[message]
        if sound.statusmessage {
            PAStatus(sound.statusmessage)
        }
        if sound.voice {

            ; retrieve list of available voices (each voice is a SpeechSynthesisVoice object)
            voices := _SoundObj.GetVoices()
            
            ; set voice to use
            _SoundObj.Voice := voices.Item(PAOptions["PA_voice"].setting)    ; use voice 1 (Zira) (0=Dave, 2=Mark)

            ; speak phrase
            _SoundObj.Speak(sound.voice, 0x01)
        
        }
        if sound.audio {

            SoundPlay(sound.audio)

        }
        if sound.beepfreq {

            SoundBeep(sound.beepfreq, 150)

        }

    } else {

        ; key not found in sound array, just speak the passed message string

        ; retrieve list of available voices (each voice is a SpeechSynthesisVoice object)
        voices := _SoundObj.GetVoices()

        ; set voice to use
        _SoundObj.Voice := voices.Item(PAOptions["PA_voice"].setting)    ; use voice 1 (Zira) (0=Dave, 2=Mark)

        ; speak phrase
        _SoundObj.Speak(message, 0x01)

    }

}


