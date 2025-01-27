# PACS Assistant

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently. It performs multiple functions which are described below.

PACS Assistant is highly customizable. Most functions can be selectively enabled or disabled.


## Single sign on

PACS Assistant can streamline PACS start up especially when reading remotely. At home, with a click of the **Power** button and entry of a one time passcode, it will connect the VPN and start up EI, Powerscribe, and Epic, leaving you ready to start dictating. At the hospital, it will simply start up EI, Powerscribe, and Epic.

After startup, PACS Assistant will resize and reposition your windows to your desired layout.

At home, your username and password are securely stored so you don't have to reenter them every time. At the hospital, only your username is stored--you will have to provide your password the first time you start up.


## EI, PowerScribe, and Epic window focus

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being three separate applications. By following your mouse on the screen, PACS Assistant determines your intention and treats keyboard and mouse inputs accordingly. You no longer have to click simply to change focus between application windows.

For example, if the `C` key is mapped to the Caliper tool, pressing `C` while the mouse is over the EI image windows will activate the Caliper tool. However, pressing `C` while the mouse is over the PowerScribe report window will type the letter *c* into your report. No mouse click is necessary to change which window is in focus.

Within EI, PACS Assistant also helps with keeping the correct viewport in focus. For example, if the `1` key is mapped to window/level preset #1, pressing `1` will change the window/level of the viewport under the mouse rather than the last viewport that was clicked in.


## Shortcut keys

PACS Assistant provides several keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect when the mouse over the EI or PowerScribe windows.

### CapsLock key

The CapsLock key turns the microphone on and off.

Shift-CapsLock signs the current report. [todo] #44 If there is no current report, start dictating the next case (EI Start reading).

Ctrl-CapsLock drafts the current report.

Shift-Ctrl-CapsLock makes the current report preliminary.

Alt-CapsLock toggles the caps lock state (i.e. the original function of the CapsLock key).

### Tab key

The Tab key moves to the next PowerScribe field.

Shift-Tab moves to the previous PowerScribe field.

Ctrl-Tab moves the cursor to the end of the current line in a report. Pressing it again moves the cursor to the end of the line below.

### ` (backtick or tilde) key

The ` key switches between the Worklist and Text pages of the EI Desktop.

Shift-` switches to the Search page of the EI Desktop. Pressing it again resets the search and puts the cursor in the Patient last name field, ready for you to enter a search.

### Spacebar

The space bar has a few new functions:

- When the mouse is over the EI image windows, pressing space performs a double-click. This is useful to enlarge/restore the size of a series, or to display a thumbnail in the active viewport.
- When scrolling through an EI image series by holding down the left mouse button and moving the mouse, pressing space engages click lock, allowing the left mouse button to be released while continuing to scroll through images. Pressing space again or clicking either mouse button disengages click lock.
- When the mosue is over the PowerScribe window, 

### Escape key

The Esc key closes the current case in EI (EI Remove from list) when the mouse is over the EI image windows.

### Ctrl-Z / Ctrl-Y

The Ctrl-Z and Ctrl-Y can be enabled to always send the Undo and Redo commands to PowerScribe, even when the mouse is over an EI window. This is quicker than having to move the mouse to the PowerScribe window, and quicker than using the voice command "Scratch that".

## Adding EI shortcuts

EI does not allow some operations to be assigned a keyboard shortcut. PACS Assistant adds this capability for several additional operations.

### Display Study Details

A small icon in the upper right corner of each viewport displays the study report on the EI Desktop Text page when clicked. Now you can assign this function to a keyboard shortcut.

In the most common usage, pressing the assigned shortcut key displays the report for the comparison study. Pressing the key again toggles to the report of either a second comparison study, or the blank report of the active study.


## Mouse jiggler

Mouse jiggler to prevent the screen from turning off and the Windows screen saver from activating.
