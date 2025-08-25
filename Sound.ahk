/* Sound.ahk
**
** Provide audio feedback for PACS Assistant operations
**
**
*/

#Requires AutoHotkey v2.0
#SingleInstance Force




/**********************************************************
** Global variables and constants used or defined in this module
*/

; Global sound object, used in this module
_SoundObj := ComObject("SAPI.SpVoice")




/**********************************************************
** Classes defined by this module
*/


; Holds a sound or voice to be played, and a status message to be displayed
;
; Can be a a spoken voice phrase and/or a beep or an audio file (.wav)
;
; To specify a voice phrase, pass a string
;
; To specify a beep, pass a frequency or an array of [frequency, duration_in_ms]
;
; To specify an audio file, pass a filename ending in .wav
;
; Displays the status message if specified
;
; To produce standard system sounds, pass a voice phrase with the format
; below:
;
; "*-1" = Simple beep. If the sound card is not available, the sound is generated using the speaker.
; "*16" = Hand (stop/error)
; "*32" = Question
; "*48" = Exclamation
; "*64" = Asterisk (info)
;
class SoundItem {
    beepfreq := 0
    beepdur := 0
    phrase := ""
    audiofile := ""
    statusmessage := ""

    __New(spokenphrase := "", soundarg := "", statusmsg := "") {
        this.phrase := spokenphrase
        if IsNumber(soundarg) {
            ; this is a frequency value without a duration, use a default duration of 150ms
            this.beepfreq := soundarg
            this.beepdur := 150
        } else if IsObject(soundarg) {
            ; this must be a beep frequency or an array of [freq, duration]
            this.beepfreq := soundarg[1]
            if soundarg.Length > 1 {
                this.beepdur := soundarg[2]
            } else {
                this.beepdur := 150
            }
    } else if SubStr(soundarg, -4) = ".wav" {
            ; found a .wav file
           this.audiofile := soundarg
        } else {
            ; not sure what this is??
        }
        this.statusmessage := statusmsg
    }
}



/*
; Sounds maps PA events to voice or audio feedback
Sounds := Map()

Sounds["PSTab"] := SoundItem( , [440, 10])
Sounds["PSToggleMic"] := SoundItem( , 392)

Sounds["PSSignReport"] := SoundItem("Signed", , "Report signed")
Sounds["PSDraftReport"] := SoundItem("Save as draft", , "Report saved as Draft")
Sounds["PSSPreliminary"] := SoundItem("Preliminary report", , "Report saved as Preliminary")

Sounds["EIStartReading"] := SoundItem( , 480)
Sounds["EIClickLockOn"] := SoundItem(, [1000, 100])
Sounds["EIClickLockOff"] := SoundItem(, [600, 100])

Sounds["EPIC"] := SoundItem("EPIC was clicked")
*/



/***********************************************/



; Plays the requested sound, passed in soundevent
;
; Uses the global map Sounds
;
; If voice usage is enabled (according to Setting["UseVoice"].value) and there is a voice phrase to speak,
; then speaks the voice phrase.
;
; If sound file is available, plys the sound file.
;
; If beep is requested, plays the beep.
;
; If the soundevent is not found in Sounds, then if voice usage is enabled, speaks the soundevent string as a voice phrase.
;
PlaySound(soundevent) {
    global _SoundObj
    global Sounds

    if Sounds.Has(soundevent) {
    
        sound := Sounds[soundevent]
        if sound.statusmessage {
            GUIStatus(sound.statusmessage)
        }

        if Setting["UseVoice"].value && sound.phrase {

            ; retrieve list of available voices (each voice is a SpeechSynthesisVoice object)
            voices := _SoundObj.GetVoices()
            
            ; set voice to use
            _SoundObj.Voice := voices.Item(Setting["Voice"].value)    ; use voice 1 (Zira) (0=Dave, 2=Mark)

            ; speak phrase
            _SoundObj.Speak(sound.phrase, 0x01)
        
        }

        if sound.audiofile {

            SoundPlay(sound.audiofile)

        }

        if sound.beepfreq {

            SoundBeep(sound.beepfreq, sound.beepdur)

        }

    } else {

        ; key not found in Sounds[], just speak the passed string

        if Setting["UseVoice"].value {
            ; retrieve list of available voices (each voice is a SpeechSynthesisVoice object)
            voices := _SoundObj.GetVoices()

            ; set voice to use
            _SoundObj.Voice := voices.Item(Setting["Voice"].value)    ; use voice 1 (Zira) (0=Dave, 2=Mark)

            ; speak phrase
            _SoundObj.Speak(soundevent, 0x01)
        }

    }

}

