/* PAFindTextStrings.ahk
**
** This file holds search strings for the FindText() function.
**
** Strings are stored in the PAText map object.
**
*/


#Requires AutoHotkey v2.0
#SingleInstance Force



; Dictionary of strings for FindText function
;
global PAText := Map()

;EI Login left top edge of username or password fields (35px x 12px)
PAText["EILoginField"] := "|<>*168$21.zzzzzzzk006000U"



; EI Desktop toolbar Search button icon (magnifying glass)
PAText["EISearch"] := "|<>*142$21.zw3zy07zVsTszlyDzDnzsyTzbnzwyTzbnzwyTz7lztzDyDkTXw00z10DkTzw7zz1zzsTzz7zzw"

; EI Desktop toolbar Go to List area button icon (clipboard)
PAText["EIList"] := "|<EIList>*113$18.z0zySTyrT0n0Mz6PzqM06TzyTzyM3yTzyTzyMTyTzyTzyM1yTzyTzyMzyTzyTzy000U"

; EI Desktop toolbar Go to Text area button icon
PAText["EIText"] := "|<EIText>*132$22.0001zzzbzzyM00NU01a006M00NU01a006MU8NbGla9G6MW8NWAVa9H6M04NU01bzzyTzzs0008"

; EI Desktop toolbar Go to Image area button icon
PAText["EIImage"] := "|<EIImage>*133$22.0001zzzbzs6TzNdzxqa002P399iRaatqOM0TdaM0afLyP3TtgBzatryPzTtU1zbzzyTzzs0008"

; EI Desktop toolbar Launch Epic button icon
PAText["EIEpic"] := "|<EIEpic>*145$24.U001U0010000000000000000000000007s0065Ys7YzA64T0AAz8CAf80N1k0800000000000000000000000000U001U001zzzzzzzzzzzzzzzzU"



; EI Desktop toolbar Search button (magnifying glass) is selected
PAText["EISearchOn"] := "|<EISearchOn>*137$36.zzzzzzU00001jzzzzxjzzzzxjzzzzxjzz0zxjzw0DxjzsS7xjzlzXxjzXznxjzbzlxjzbztxU"

; EI Desktop toolbar Go to List area button (clipboard) is selected
PAText["EIListOn"] := "|<EIListOn>*133$36.zzzzzzU00001jzzzzxjzzzzxjzzzzxjzs7zxjznnzxjzqvzxjs6s7xjv7srxjvTyrxjv00rxjvzzrxU"

; EI Desktop toolbar Go to Text area button is selected
PAText["EITextOn"] := "|<EITextOn>*133$36.zzzzzzU00001jzzzzxjzzzzxjzzzzxjzzzzxjU001xjjzzxxjjzzxxjg00Bxjg00Bxjg00Bxjg00Bxjg00BxU"

; EI Desktop toolbar Go to Image area button is selected
PAText["EIImageOn"] := "|<EIImageOn>*131$36.zzzzzzU00001jzzzzxjzzzzxjzzzzxjzzzzxjU001xjjzzxxjjzkBxjjzgJxjjzipxjg005xU"



; EI Desktop Search page Clear button
PAText["EISearch_Clear"] := "|<EISearch_Clear>*160$31.00000TzzzzzzzzzzzzzzzzzzzzkvzzzbBzzzrmswAPzNBqRzhrvSzq3VjT/TarbBarPwCss5zzzzzzzzzzzzzzzzzzzzzzzzzzU00008"
; EI Desktop Search page "Patient last name" search field
PAText["EISearch_LastName"] := "|<EISearch_LastName>*80$55.zzzzzzzzzvzzjzzzzzxzzrzzzzzyksluQC4SDP9fxqnRqrTaRyvtAmxg7ayv1iv0qvRTRirRjvNgjiqPirRUknrMBrQTzzzzzzzzz"



; EI Desktop Text area "Reading"
PAText["EI_Reading"] := "|<EI_Reading>*112$54.zzzzzzzzzU7zzzvTzzbnzzzvzzzbnzzzvzzzbnVsC3M71bnAnAnNaNU7SThnNqtbC0Q9vPoxbaTndvPoxbbTrhvPqxbnCrAnPqNblVka3Pr1zzzzzzzzxzzzzzzzytzzzzzzzy3zzzzzzzzzU"
; EI Desktop Text area "Study"
PAText["EI_Study"] := "|<EI_Study>*112$38.zzzzzzw7zzzTySPzzrzbazzxztz2xkHb7vjNatsCvqtaztixDNDzPjHrHjqvqxlttaNaQT0skQ7bzzzzzvzzzzzwzzzzzyTzzzzzzs"
; EI Desktop Text area "Compar"ison
PAText["EI_Comparison"] := "|<EI_Comparison>*114$54.zzzzzzzzzsDzzzzzzznXzzzzzzzbnzzzzzzzbzVk8MD1VjzAn6NaNbjzSnbNrxbjzSrjPnVjbvSrjPmRjbnSrjNqxjnXArjNatjsDVrjMC4jzzzzzvzzzzzzzzvzzzzzzzzvzzzzzzzzzzzzU"
; EI Desktop Text area "Compar"ison
;PAText["EI_Addendum"] := "|<EI_Comparison>*114$54.zzzzzzzzzsDzzzzzzznXzzzzzzzbnzzzzzzzbzVk8MD1VjzAn6NaNbjzSnbNrxbjzSrjPnVjbvSrjPmRjbnSrjNqxjnXArjNatjsDVrjMC4jzzzzzvzzzzzzzzvzzzzzzzzvzzzzzzzzzzzzU"

; EI Desktop Text area mode is one of: "Reading", "Study", "Comparison", or "Addendum"
PAText["EI_Mode"] := PAText["EI_Reading"] . PAText["EI_Study"] . PAText["EI_Comparison"]  ; . PAText["EI_Addendum"]


; EI Desktop Text area "Patient info"
PAText["EI_Patientinfo"] := "|<EI_Patientinfo>*155$61.zzzzzzzzzzkDyrzzjjyDvrzTzzrzzTxtV5lkFv16CxiqmNhxaqP0zPPhqyrPRjwBg6vTPhirwqqzRjhqrPyvPBirqvNhz0ZlrNvRiDzzzzzzzzzz"

; EI Desktop Text area "Study info"
PAText["EI_Studyinfo"] := "|<EI_Studyinfo>*69$53.zzzzzzzzzVrzwzvzXyNjztzrzTxu/i0rg4MtyrNZjNhawRir+yrPRzPRiJxiqvSKvQXvRhqRhaNjqvNi78C3Thqszzzzyzzzzzzzznzzzzzzzzzzzzz"

; EI Desktop Text area "Technolog"ist Communication
PAText["EI_Technologist"] := "|<EI_Technologist>*72$59.zzzzzzzzzz0TzvzzzTzzrzzrzzyzzzjXlUkQRlsTSHBBanPBayxqyvRiqvRxsBxqvRhqvvrvvhqvPhrranLPgqnNjjXlirQRlsTzzzzzzzzyzzzzzzzzz3zzzzzzzzzz"

; EI Desktop Text area - UL corner of text box or dropdown box (4x12px)
PAText["EI_UL"] := "|<EI_UL>*16$4.zwnAnAnAU"

; EI Desktop Text area - Thin vertical blue line (1px wide, 12px tall)
PAText["EI_Vert"] := "|<EI_Vert>467BAC-0.90$4.8W8W8W8WU"

; EI Desktop Text area - Thin horizontal blue line (12px wide, 1px tall)
PAText["EI_Horz"] := "|<EI_Horz>467BAC-0.90$12.0000zz00U"



; Large is for 1x1 viewport
; Medium is for 1x2, 1x3, 2x1, 2x2, 2x3, 3x1 viewports
; Small is for 2x4, 3x3 viewports

; EI Images Study Details icon: Large Selected
PAText["EI_SD_LOn"] := "|<EI_SD_LOn>*109$14.zzlzwDz1zoDxVzQDrVxwDTVrwBzVTwE06"
; EI Images Study Details icon: Large Unselected
PAText["EI_SD_LOff"] := "|<EI_SD_LOff>*97$13.zzbzlzsTw7y1z0Tg7r1vkRw60100k"

; EI Images Study Details icon: Medium Selected
PAText["EI_SD_MOn"] := "|<EI_SD_MOn>*114$12.zz7z3z1zMzQTSDT7TXTlTl01U"
; EI Images Study Details icon: Medium Unselected
PAText["EI_SD_MOff"] := "|<EI_SD_MOff>*100$10.zxznz7wDkTExVr306"

; EI Images Study Details icon: Small Selected
PAText["EI_SD_SOn"] := "|<EI_SD_SOn*107$11.zy7w7t7n7b7D6T4z80E0k"
; EI Images Study Details icon: Small Unselected
PAText["EI_SD_SOff"] := "|<EI_SD_SOff>*106$10.zwTkz1wXn7CA0E1U"

; Combined strings containing several of the above EI_SD images
PAText["EI_SDOn"] := PAText["EI_SD_LOn"] . PAText["EI_SD_MOn"] . PAText["EI_SD_SOn"]
PAText["EI_SDOff"] := PAText["EI_SD_LOff"] . PAText["EI_SD_MOff"] . PAText["EI_SD_SOff"]
PAText["EI_SD"] := PAText["EI_SD_LOn"] . PAText["EI_SD_LOff"] . PAText["EI_SD_MOn"] . PAText["EI_SD_MOff"] . PAText["EI_SD_SOn"] . PAText["EI_SD_SOff"]



; PS toolbar Dictate button: On
PAText["PSDictateOn"]:="|<PSDictateOn>*200$8.zk000000000wTgzTzzxyD8"
; PS toolbar Dictate button: Off
PAText["PSDictateOff"]:="|<PSDictateOff>*200$8.00000000000wTgzDzzxyD8"



