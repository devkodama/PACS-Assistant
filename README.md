# PACS Assistant

## Introduction

PACS Assistant lets you work with Agfa Enterprise Imaging (EI), PowerScribe, and Epic more seamlessly and efficiently. PACS Assistant has many features which are described below. Key features include:

* Single sign on - Log onto VPN and start EI, Powerscribe, and Epic with minimal effort
* Window management - Remember window layouts, automatically dismiss popup messages
* Focus following - Keep the window under the mouse active
* Viewport activation for EI - Reduce unnecessary clicks
* New hotkeys - Toggle microphone, go to next field, sign report, click lock for image scrolling, show comparison report, and more
* Microphone on/off - Automatically turn on the microphone when opening a new report
* Mouse jiggler - Keep the Windows screensaver from activating

PACS Assistant is highly customizable--most of its features can be selectively enabled or disabled from the Settings page.

## How to use

In the Documents folder on your computer, create a folder named _PACS Assistant_ and copy the file _PACS Assistant.exe_ into it. Double-click _PACS Assistant.exe_ to run.

The first time you run PACS Assistant, you'll need to enter your PACS username and password. On home workstations, PACS Assistant can remember your username and password so you don't have to enter them again. On hospital workstations, for security reasons PACS Assistant will remember your username and settings but not your password.

> ℹ️ Your stored username and password are protected by your Windows login credentials. Anyone who knows your Windows login can access your stored username and password.

## Single sign on

On home workstations, PACS Assistant can connect to the VPN and start EI, Powerscribe, and Epic with minimal supervision. To begin, click on the **Power** button, wait a few seconds, and enter a one time passcode from the Authenticate app on your mobile phone. The rest happens automatically.

On hospital workstations, PACS Assistant can start EI, Powerscribe, and Epic, but you will have to enter your password each time you start PACS Assistant. Your password is not stored for security reasons.

## Window management

[nb current version is buggy, desktops don't always restore.]

PACS Assistant can remember your window layout and restore windows to the same positions when PACS starts up. In PACS Assistant, go to the Window Manager tab. Arrange your EI, PowerScribe, Epic, and Epic Chat windows as you like. Then click Remember window positions.

PACS Assistant can automatically dismiss selected popup messages such as PowerScribe, EI, or Epic confirmation messages. In PACS Assistant, go to the Settings tab to enable or disable.

## Focus following

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were a single unified application instead of separate applications. PACS Assistant follows your mouse and keeps the appropriate window in focus. You don't need to click to switch focus.

In most cases, key presses are transmitted to the window which has focus. However, when appropriate, keys or commands may be transmitted to a different window or application.

> For example, if the Tab key is assigned to the PowerScribe command "Next Field", pressing Tab will send a "Next Field" command to PowerScribe regardless of whether the mouse is hovering over the PowerScribe window or over an EI image window.

## EI viewport activation

PACS Assistant can activate the EI viewport under the mouse pointer when certain EI keyboard shortcuts are pressed. This eliminates the need to click the mouse button or turn the mouse wheel to activate a viewport before you press the shortcut key.

> For example, if the `X` key is mapped to the EI Invert image tool, pressing the `X` key will first activate the viewport under the mouse pointer and *then* invert the image, since that is what you likely intended.

Before you enable this functionality, you first need to tell PACS Assistant which shortcut keys you have mapped to which tools in EI. Do this by entering a comma-separated list of shortcut keys on the Settings page. I would recommend including shortcut keys for the following tools:

* All W/L presets
* Invert
* Flip horizontal
* Flip vertical
* Rotate 90 left
* Rotate 90 right
* Switch viewport to next series
* Switch viewport to previous series
* Next set of images
* Previous set of images

Use the prefix `+` for Shift, `^` for Ctrl, and `!` for Alt. For example, Shift-A would be entered as *+a*, Ctrl-X would be entered as *^x*, and Shift-Ctrl-T would be entered as *+^t*. Special keys can be entered using AutoHotkey key names such as *Numpad0* for the number pad `0` key (see [full list of key names](https://www.autohotkey.com/docs/v2/KeyList.htm#general)).

> For example, my list of shortcut keys, corresponding to the above list of tools, looks like:
>
>> 1,2,3,4,5,+1,+2,+3,+4,+5,x,w,+w,e,+e,d,f,+d,+f
>
> where the number keys and the Shift number keys are my W/L presets, and the other keys are my shortcuts for the other tools.

## New keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts (hotkeys) for working with EI and PowerScribe. Most of these keys operate when the mouse is within the EI, Powerscribe, Epic, or PACS Assistant windows.

### CapsLock key

**CapsLock** toggles the microphone on and off.

**Shift-CapsLock** can do one of several things:

* If a report is currently being dictated, signs the report. Equivalent to the PowerScribe *Sign* button (F4).

* If a study is open and ready for dictation, starts (or resumes) dictation. Equivalent to the EI *Start* (or *Resume*) *reading* button.

* If there is no open study or the study that is open is not ready for dictation, and if one or more studies are selected on the EI List page, starts dictation of the selected studies. Equivalent to the EI *Start* (or *Resume*) *reading* button.

* If no studies are selected studies on the EI List page, starts dictation of all studies on the worklist. Equivalent to the EI *Start list* button.

**Ctrl-CapsLock** saves the report currently being dictated as a Draft. Equivalent to the PowerScribe *Draft* button (F12).

**Shift-Ctrl-CapsLock** signs the report currently being dictated as Preliminary. Equivalent to the PowerScribe *Prelim* button.

**Alt-CapsLock** toggles the caps lock state (*i.e.* the original function of the CapsLock key).

### Tab key

**Tab** moves to the next field in a PowerScribe report.

**Shift-Tab** moves to the previous field in a PowerScribe report.

**Ctrl-Tab** moves the cursor to the end of the current line in a PowerScribe report. Pressing it a second time moves the cursor down one line then to the end of the line.

> 💡 This can be used to position the cursor *after* the default text when tabbing into fill-in field, so that dictation does not replace the default text.

**Shift-Ctrl-Tab** moves the cursor up one line then to the end of the line.

### ` (Backtick or tilde) key

**Backtick** brings up the report for the comparison study (equivalent to clicking on the Display Study Details button in the upper right corner of a viewport), switching to the Text page of the EI desktop if necessary.

Pressing it again brings up the report of a second comparison study if one is being displayed on the screen. If no second comparison study is displayed, it brings up the empty report of the active study.

**Shift-Backtick** toggles between the List and Text pages of the EI Desktop.

**Ctrl-Backtick** brings up the Search page of the EI Desktop. Pressing it a second time clears the search fields and puts the cursor in the Patient last name field, ready for entering a new search.

### Spacebar

The **Spacebar** can do one of several things:

* CLick Lock - While scrolling through images in EI with the left mouse button down, pressing **Spacebar** engages Click Lock, allowing the left mouse button to be physically released. Pressing **Spacebar** again disengages Click Lock. Pressing either mouse button also disengages Click Lock.

* Double-click in EI Image window - When the mouse pointer is over an EI image window, pressing **Spacebar** performs a double-click. This is useful to enlarge or restore the size of a series, or if the mouse is over a series thumbnail to place the series into the active viewport.

> ⚠️ Known issue: In some places, the spacebar no longer works to type a space. For example, when creating a text annotation on an image, the space bar will send a double-click which leads to unwanted side effects. If you need to type a space, you can press **Shift-Spacebar** to enter a space, or temporarily disable PACS Assistant while you are typing.

* Double-click on EI desktop List page - When the mouse pointer is over the EI desktop List page, pressing **Spacebar** performs a double-click. This is useful to open a study, for example.

### Escape key

**Shift-Esc** closes the current case in EI when the mouse pointer is over an EI image window (same as clicking the EI *Remove from list* button).

### Ctrl-Z / Ctrl-Y

**Ctrl-Z** and **Ctrl-Y** send *Undo* and *Redo* commands, respectively, to PowerScribe.

> ⚠️ Disable this if you have Ctrl-Z or Ctrl-Y mapped as EI shortcuts (or remap your EI shortcuts).
>
> 💡 *Ctrl-Z* can be helpful to quickly revert accidentally transcribed noise.

## Miscellaneous functions

### Microphone auto on/off

PACS Assistant can automatically turn on the microphone when you open a report for dictation and turn it off when you close it. It can also automatically turn off the microphone after a period of inactivity (*e.g.* if you leave your workstation).

### Mouse jiggler

PACS Assistant can jiggle the mouse periodically in order to suppress the Windows screensaver and prevent the screen from turning off.

### CapsLock auto off

PACS Assistant can return the CapsLock state to off after a short period of time (around 10 seconds).

## Comments

PACS Assistant is optimized for a handsfree setup, *i.e.* a handsfree microphone, right hand on the mouse, and left hand on the keyboard. If frequently used EI keyboard shortcuts are mapped to the left half of the keyboard, then reading can be done with minimal hand movement and without needing to look away from the screen.

PACS Assistant could be used with an accessory keypad such as a Tartarus gaming keypad by reassigning its functions to keypad keys. (This can be done the file Hotkeys.ahk.) I've found that I prefer using the regular keyboard because it doesn't require extra hardware and so is available on every workstation.

PACS Assistant is still under heavy development with more features to come. You may (will) encounter bugs or conflicts with other applications; in many cases, temporariliy disabling PACS Assistant with the on/off toggle switch can bypass the problem.

Feedback is welcome--let me know of any issues you encounter or features you'd like to see.
