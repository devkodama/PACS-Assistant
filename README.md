# PACS Assistant

## Introduction

PACS Assistant helps Agfa Enterprise Imaging (EI), PowerScribe, and Epic function work together more seamlessly and efficiently.

PACS Assistant has many features which are described below. PACS Assistant is highly customizable--most of its features can be selectively enabled or disabled from the Settings page.

## How to use

In the Documents folder on your computer, create a folder named PACS Assistant and copy the file PACS Assistant.exe into it. Doubleclick PACS Assistant.exe to run it.

The first time you run PACS Assistant, you'll need to enter your PACS username and password. On home workstations, PACS Assistant will remember your username and password so you don't have to enter them again. On hospital workstations, for security reasons PACS Assistant will remember your username but not your password.

> ℹ️ Your stored username and password are protected by your Windows login credentials. Anyone who knows your Windows login can access your stored username and password.

## Single sign on

On home workstations, PACS Assistant can start the VPN and start EI, Powerscribe, and Epic with minimal input. To begin, click on the **Power** button, wait a few seconds, and enter a one time passcode from the Authenticate app on your mobile phone. The rest happens automatically.

On hospital workstations, PACS Assistant can start EI, Powerscribe, and Epic, but you will have to enter your password the first time you use PACS Assistant. Your password is not stored for security reasons.

## Window management

PACS Assistant can remember your window layout and restore windows to the same positions when PACS starts up. [nb current version is slightly buggy, EI desktop doesn't always restore.]

PACS Assistant can automatically dismiss selected popup messages, such as the PowerScribe, EI, or Epic confirmation messages.

## Focus following

PACS Assistant treats EI, PowerScribe, and Epic as though they were unified instead of being separate applications. PACS Assistant watches your mouse and keeps the appropriate application window in focus. You don't need to click on each application to switch focus.

In most cases, key presses are transmitted to the window which has focus. However, when appropriate, some keys may be transmitted to a different window or application.

> For example, if the Tab key is assigned to the PowerScribe command "Next Field", pressing Tab will send a "Next Field" command to PowerScribe regardless of whether the mouse is hovering over the PowerScribe window or over an EI image window.

## Viewport activation for EI

PACS Assistant can activate the EI viewport under the mouse pointer when certain EI keyboard shortcuts are pressed. This eliminates the need to click or turn the mouse wheel to activate the viewport before you press a shortcut key.

> For example, if the `X` key is mapped to the EI Invert image tool, pressing the `X` key will first activate the viewport under the mouse pointer and *then* invert the image, since that is what you likely intended.

In order to enable this functionality, you first need to tell PACS Assistant which shortcut keys you have mapped to which tools in EI. You can do this by entering a comma-separated list of shortcut keys on the Settings page. I would recommend including shortcut keys for the following tools:

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

Use the prefix `+` for Shift, `^` for Ctrl, and `!` for Alt. For example, Shift-A would be entered as *+a*, Ctrl-X would be entered as *^x*, and Shift-Ctrl-T would be entered as *+^t*.

> For example, my list of shortcut keys, corresponding to the above list of tools, looks like:
>
>> 1,2,3,4,5,+1,+2,+3,+4,+5,x,w,+w,e,+e,d,f,+d,+f
>
> where the number keys and the Shift number keys are W/L presets, and the other keys are the other tools.

## New keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts (hotkeys) for working with PowerScribe and EI. Most of these keys will work when the mouse is hovering over the Powerscribe, EI, Epic, or PACS Assistant windows.

### CapsLock key

**CapsLock** toggles the microphone on and off.

**Shift-CapsLock** can do one of several things:

* If a report is currently being dictated, signs the report. Equivalent to the PowerScribe *Sign* button (F4).

* If a study is open and ready for dictation, then start (or resume) dictation. Equivalent to the EI *Start* (or *Resume*) *reading* button.

* If the open study is not ready for dictation or if there is no open study, and if one or more studies are selected on the EI List page, then start dictation of the selected studies. Equivalent to the EI *Start* (or *Resume*) *reading* button.

* If no studies are selected studies on the EI List page, then start dictation of all the studies on the worklist. Equivalent to the EI *Start list* button.

**Ctrl-CapsLock** saves the report currently being dictated as a Draft. Equivalent to the PowerScribe *Draft* button (F12).

**Shift-Ctrl-CapsLock** signs the report currently being dictated as Preliminary. Equivalent to the PowerScribe *Prelim* button.

**Alt-CapsLock** toggles the caps lock state (*i.e.* the original function of the CapsLock key).

### Tab key

**Tab** moves to the next field in a PowerScribe report.

**Shift-Tab** moves to the previous field in a PowerScribe report.

**Ctrl-Tab** moves the cursor to the end of the current line in a PowerScribe report. Pressing it a second time moves the cursor down one line then to the end of the line.

> 💡 This can be used to position the cursor *after* the default text after tabbing into a fill-in field, so that dictation does not replace the default text.

**Shift-Ctrl-Tab** moves the cursor up one line, then to the end of the line.

### ` (Backtick or tilde) key

**Backtick** brings up the report for the comparison study (equivalent to clicking on the Display Study Details button in the upper right corner of a viewport), switching to the Text page of the EI desktop if necessary.

Pressing it again brings up the report of a second comparison study if one is being displayed on the screen. If no second comparison study is displayed, it brings up the empty report of the active study.

**Shift-Backtick** toggles between the List and Text pages of the EI Desktop.

**Ctrl-Backtick** brings up the Search page of the EI Desktop. Pressing it a second time clears the search fields and puts the cursor in the Patient last name field, ready for entering a new search.

### Spacebar

The **Spacebar** can do one of several things:

* While scrolling through images in EI with the left mouse button down, pressing **Spacebar** engages Click Lock, allowing the left mouse button to be physically released. Pressing **Spacebar** again disengages Click Lock. Pressing either mouse button also disengages Click Lock.

* When the mouse pointer is over an EI image window, pressing **Spacebar** performs a double-click. This is useful to enlarge or restore the size of a series, or if the mouse pointer is over a series thumbnail to put the series into the active viewport.

> ⚠️ Known issue: In some places, the spacebar no longer works to type a space. For example, when creating a text annotation on an image, the space bar will send a double-click which leads to unwanted side effects. If you need to type a space, you can press **Shift-Spacebar** to enter a space, or temporarily disable PACS Assistant while you are typing.

* When the mouse pointer is over the EI desktop List page, pressing **Spacebar** performs a double-click. This can be used to open a study, for example.

### Escape key

**Shift-Esc** closes the current case in EI when the mouse pointer is over an EI image window (same as clicking the EI *Remove from list* button).

### Ctrl-Z / Ctrl-Y

**Ctrl-Z** and **Ctrl-Y** send *Undo* and *Redo* commands, respectively, to PowerScribe.

> ⚠️ Disable this if you have Ctrl-Z or Ctrl-Y mapped as EI shortcuts (or remap your EI shortcuts).

## Miscellaneous functions

### Microphone auto on/off

PACS Assistant can automatically turn on the microphone when you open a report for dictation, and turn it off when you close it. It can also automatically turn off the microphone after a period of inactivity (*e.g.* when you leave your workstation).

### Mouse jiggler

PACS Assistant can jiggle the mouse periodically in order to suppress the Windows screensaver and prevent the screen from turning off.

### CapsLock auto off

PACS Assistant can return the CapsLock state to off after a short period of time (around 10 seconds).

## Comments

PACS Assistant is optimized for a handsfree setup, *i.e.* a handsfree microphone, right hand on the mouse, and left hand on the keyboard.

If frequently used EI keyboard shortcuts are mapped to the left half of the keyboard, then reading can be done with minimal hand movement and without needing to look away from the screen.

PACS Assistant could be used with an accessory keypad such as a Tartarus gaming keypad by reassigning its functions to keypad keys. I've found that I prefer using the regular keyboard because it doesn't require extra hardware and is available on every workstation.

PACS Assistant is still under heavy development with more features to come. You may (will) encounter bugs or conflicts with other applications; in most cases, temporariliy disabling PACS Assistant with the on/off toggle switch can bypass the problem.

Feedback is welcome, let me know of issues you encounter or new features you'd like to see.
