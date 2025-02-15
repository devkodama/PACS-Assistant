# PACS Assistant

![alt text](<docs/images/PA main screen.png>)

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently.

PACS Assistant has multiple capabilities which are described below. PACS Assistant is highly customizable--most of its functions can be selectively enabled or disabled.

## Single sign on

PACS Assistant simplifies PACS start up especially when reading from home.

At home, clicking the **Power** button and entering a one time passcode will complete the entire sequence of connecting to the VPN and starting EI, Powerscribe, and Epic. Your username and password are stored securely so you don't have to reenter them every time.

At the hospital, clicking the **Power** button will start EI, Powerscribe, and Epic. On shared workstations, only your username is remembered. You will have to enter your password once when you first start working.

At startup, PACS Assistant can restore EI, Powerscribe, and Epic windows to your saved positions so you are ready to begin dictating.

## Focus following for EI, PowerScribe, and Epic

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being separate applications. PACS Assistant follows your mouse pointer on the screen and always keeps the proper application window in focus. Mouse clicks are not needed to switch window focus.

PACS Assistant treats keypresses differently depending on which window is in focus.

> For exmaple, if the mouse pointer is within the EI image window, pressing the `C` key will trigger the EI Shortcut which is assigned to the `C` key. However, if the mouse pointer is within the PowerScribe window, pressing the `C` key will type the letter *c* in the PowerScribe report.

In most cases, keypresses will be sent to the currently focused application. However, in some cases, keypresses may be sent to a different application.

> For example, if the Tab key is mapped to the PowerScribe command "Next Field", pressing Tab will send a "Next Field" command to PowerScribe regardless of whether the mouse pointer is within the PowerScribe window or an EI image window.

Within the EI image windows, most keyboard shortcuts act on the currently active viewport. This often requires a mouse click to change the active viewport before pressing the shortcut key. PACS Assistant eliminates the extra mouse click by activating the correct viewport before sending the shortcut key to EI.

> For example, if the `1` key is mapped to EI Window/level Preset #1, and the mouse pointer is positioned within the viewport you wish to change, pressing the `1` key will change the window/level of the desired viewport rather than the previously active viewport. No mouse click is neccesary to switch the active viewport.

In order to enable this functionality, you will need to tell PACS Assistant which shortcut keys you have mapped to which tools in EI.

## New keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect whenever the mouse pointer is within the EI or PowerScribe windows.

### CapsLock key

The **CapsLock** key turns the microphone on and off.

**Shift-CapsLock** signs the currently open report.

Otherwise if there is an open study ready to start (or resume) dictation, pressing **Shift-CapsLock** begins dictation.

Otherwise if there are studies selected in th EI worklist that are ready to start (or resume) dictation, pressing **Shift-CapsLock** begins dictation.

**Ctrl-CapsLock** drafts the current report.

**Shift-Ctrl-CapsLock** makes the current report preliminary.

**Alt-CapsLock** toggles the caps lock state (i.e. the original function of the CapsLock key).

### Tab key

The **Tab** key moves to the next field in a PowerScribe report.

**Shift-Tab** moves to the previous field in a PowerScribe report.

**Ctrl-Tab** moves the cursor to the end of the current line in a PowerScribe report. Pressing it again moves the cursor to the end of the line below.

> Normally, PowerScribe selects the default text when tabbing into a field. If you dictate while text is selected, the dictation will replace the default text. By pressing Ctrl-Tab, the default text will be deselected and whatever you dictate will be inserted after the default text.

**Shift-Ctrl-Tab** moves the cursor to the end of the line *above* in a PowerScribe report.

### ` (Backtick or tilde) key

The **`** key displays the report for the comparison study, similar to clicking on the Display Study Details icon found in the upper right corner of each viewport. Typically, pressing the **`** key displays the report for the most recent comparison study. Pressing the key again toggles to the report of a second comparison study if displayed on the screen, or otherwise the empty report of the active study.

(This works for 1x1 up to 3x3 viewport layouts, due to the changing size of the icon.)

**Shift-`** toggles between the Worklist and Text pages of the EI Desktop.

**Ctrl-`** brings up the Search page of the EI Desktop. Pressing it a second time resets the search fields and puts the cursor in the Patient last name field, ready to enter a search.

### Spacebar

The **Spacebar** has a few new functions:

- When the mouse pointer is within the EI desktop List area, pressing **Spacebar** performs a double-click. This is useful to open a case.
- When the mouse pointer is within an EI image window, pressing **Spacebar** performs a double-click. This is useful to enlarge or restore the size of a series, or if the mouse pointer is over a series thumbnail to put the series into the active viewport.
> Known issue: The spacebar no longer works to type a space, for example when creating a text annotation on an image. It will send a double-click instead which leads to unwanted side effects. You can use **Shift-Spacebar** to type a space, or press `F2` to temporarily disable PACS Assistant.
- When scrolling through a stack of images in EI by holding down the left mouse button, pressing **Spacebar** engages Click Lock, allowing the left mouse button to be physically released. Pressing **Spacebar** again, or clicking either mouse button, disengages Click Lock.
- When the mouse pointer is within the PowerScribe window and text is currently selected, pressing **Spacebar** deletes the selected text.

### Escape key

The **Esc** key closes the current case in EI (*i.e.* Remove from list) when the mouse is within an EI image window.

### Ctrl-Z / Ctrl-Y

The **Ctrl-Z** and **Ctrl-Y** keys will send Undo and Redo commands to PowerScribe even when the mouse pointer is within an EI window.

> This is useful when PowerScribe transcribes accidental noise. A quick Ctrl-Z undoes the errant words more quickly than using the voice command "Scratch that" or using the delete key.

## Added EI shortcuts

By default EI does not allow keyboard shortcuts to be assigned to some of its commands. PACS Assistant adds this capability for the following commands.

### Display Study Details


### Start 

## Mouse jiggler

The PACS Assistant mouse jiggler suppresses the Windows screensaver and prevents the screen from turning off by periodically and imperceptibly moving the mouse.

## Window management

PACS Assistant remembers your preset window layout and can restore them when PACS is started.

PACS Assistant can automatically dismiss selected messages, such as logout confirmation messages from PowerScribe, ...

## Setup - Personal computer

To use PACS Assistant on your own personal computer, copy the file to your Documents or Programs folder. Double click to start it.

The first time you run it, you'll need to enter your username and password. PACS Assistant can save your password so you don't have to enter it again.




## Comments

PACS Assistant is enables a handsfree setup, with a freestanding microphone (either desktop or headset), the right hand on the mouse, and keyboard shortcuts mapped to the left half of the keyboard. With this setup, almost everything can be done without looking down at the keyboard or away from the screen.

You can use a separate shortcut keypad such as a Tartarus gaming keypad or a Stream Deck and map functions, but 

With PACS Assistant I've found it redundant since nearly everything can be done with just the standard keyboard.

With a freestanding microphone and PACS Assistant, the Nuance PowerMic is unnecessary and does not even need to be plugged in.


my own PACS setup. If your setup is different (e.g. different layout of the EI Text area), some features might not work or might not be as useful to you.


PACS Assistant is actively being developed and debugged, so you may run into bugs or conflicts with other applications. A useful key to remember is `F2` which toggles on and off most PACS Assistant functions if you notice something weird happening.


If you use PACS Assistant, let me know of any problems you encounter as well as of any features you'd like to see. I'm interested in improving PACS Assistant so it works for your workflow.
