# PACS Assistant

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently. 

PACS Assistant has multiple functions which are described below. PACS Assistant is highly customizable--most functions can be selectively enabled or disabled.

## Single sign on

PACS Assistant streamlines PACS start up especially when reading remotely.

At home, clicking the **Power** button and entering a one time passcode will complete the sequence of connecting to the VPN and starting EI, Powerscribe, and Epic. At the hospital, clicking the **Power** button will start EI, Powerscribe, and Epic. After start up, PACS Assistant will resize and reposition your windows to your desired layout so you are ready to dictate.

On your personal computer, your username and password are securely stored so you don't have to reenter them every time. On a shared workstation, only your username is stored. You will have to provide your password when you first start.

## EI, PowerScribe, and Epic window focusing

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being three separate applications. By following your mouse on the screen, PACS Assistant determines your intention and treats keyboard and mouse inputs accordingly. You no longer have to click to change focus between application windows.

As an example, if the `C` key is mapped to the EI Caliper tool, pressing `C` while the mouse is over the EI image windows will activate the Caliper tool. However, pressing `C` while the mouse is over the PowerScribe report window will type the letter *c*. No mouse click is necessary to change window focus.

Within EI, PACS Assistant also helps keep the correct viewport active. For example, if the `1` key is mapped to window/level preset #1, pressing `1` will change the window/level of the viewport under the mouse, rather than of the last viewport that was active.

## Shortcut keys

PACS Assistant provides several new keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect when the mouse over the EI or PowerScribe windows.

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

The Ctrl-Z and Ctrl-Y can be enabled to always send the Undo and Redo commands to PowerScribe even when the mouse is over an EI window. This is quicker than having to move the mouse to the PowerScribe window, and quicker than using the voice command "Scratch that".

## Adding EI shortcuts

EI does not allow some operations to be assigned a keyboard shortcut. PACS Assistant adds this capability for a few additional operations.

### Display Study Details

A small icon in the upper right corner of each viewport displays the study report on the EI Desktop Text page when clicked. Now you can assign this function to a keyboard shortcut.

In the most common usage, pressing the assigned shortcut key displays the report for the comparison study. Pressing the key again toggles to the report of either a second comparison study, or the blank report of the active study.

## Mouse jiggler

PACS Assistant provides a mouse jiggler to prevent the screen from turning off and the Windows screen saver from activating.
