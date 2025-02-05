# PACS Assistant

![PACS Assistant](/assets/PA main screen.png)

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently. 

PACS Assistant has multiple functions which are described below. PACS Assistant is highly customizable--most functions can be selectively enabled or disabled.

## Single sign on

PACS Assistant streamlines PACS start up especially when reading remotely.

At home, clicking the **Power** button and entering a one time passcode will complete the entire sequence of connecting to the VPN and starting EI, Powerscribe, and Epic. Your username and password are stored securely so you don't have to reenter them every time.

At the hospital, clicking the **Power** button will start EI, Powerscribe, and Epic. On shared workstations, only your username is stored. You will have to provide your password once when you first start.

At startup, PACS Assistant can reposition EI, Powerscribe, and Epic windows to your customized positions so you are ready to begin dictating.

## EI, PowerScribe, and Epic focus following

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being three separate applications. PACS Assistant follows your mouse pointer on the screen and keeps the proper application window in focus. Mouse clicks are unnecessary to switch window focus.

PACS Assistant treats keypresses differently depending on which window is in focus. 

> For exmaple, if the mouse pointer is within the EI image window, pressing the `C` key will trigger the EI Shortcut that has been assigned to `C`. However, if the mouse pointer is within the PowerScribe window, pressing the `C` key will type the letter *c* in the PowerScribe report.

In most cases, keypresses will be sent to the currently focused application. However, in some cases, keypresses may be sent to a different application.

> For example, if the Tab key is mapped to the PowerScribe command "Next Field", pressing Tab will send a "Next Field" command to PowerScribe regardless of whether the mouse pointer is within the PowerScribe window or an EI image window.



Within EI, PACS Assistant helps to keep the correct viewport active. For example, if the `1` key is mapped to window/level preset #1, pressing `1` will change the window/level of the viewport under the mouse, rather than of the last viewport that was active. No additional mouse click is necessary.

In order to enable this functionality, you will need to tell PACS Assistant which keys you have mapped to which tools in EI (one time setup).

## Keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect when the mouse over the EI or PowerScribe windows.

### CapsLock key

The **CapsLock** key turns the microphone on and off.

**Shift-CapsLock** signs the report currently being dictated. If there is no current report, then it starts dictation on the next case (i.e. Start reading).

**Ctrl-CapsLock** drafts the current report.

**Shift-Ctrl-CapsLock** makes the current report preliminary.

**Alt-CapsLock** toggles the caps lock state (i.e. the original function of the CapsLock key).

### Tab key

The **Tab** key moves to the next PowerScribe field.

**Shift-Tab** moves to the previous PowerScribe field.

**Ctrl-Tab** moves the cursor to the end of the current line in a report. Pressing it again moves the cursor to the end of the line below.

### ` (backtick or tilde) key

The **`** key switches between the Worklist and Text pages of the EI Desktop.

Shift-`**** switches to the Search page of the EI Desktop. Pressing it again resets the search and puts the cursor in the Patient last name field, ready for you to enter a search.

### Spacebar

The **Spacebar** has a few new functions:

- When the mouse is over the EI image windows, pressing **Spacebar** performs a double-click. This is useful to enlarge/restore the size of a series, or to display a thumbnail in the active viewport.
- When scrolling through an EI image series by holding down the left mouse button and moving the mouse, pressing **Spacebar** engages click lock, allowing the left mouse button to be released while continuing to scroll through images. Pressing **Spacebar** again or clicking either mouse button disengages click lock.
- When the mosue is over the PowerScribe window, 

### Escape key

The **Esc** key closes the current case in EI (i.e. Remove from list) when the mouse is over the EI image windows.

### Ctrl-Z / Ctrl-Y

The **Ctrl-Z** and **Ctrl-Y** keys can be enabled to always send Undo and Redo commands to PowerScribe even when the mouse is over an EI window. This allows quicker editing than needing to move the mouse to the PowerScribe window, and is quicker than using the voice command "Scratch that".

## Adding EI shortcuts

By default EI does not allow some operations to be assigned a keyboard shortcut. PACS Assistant adds this capability for a few such operations.

### Display Study Details

A small icon in the upper right corner of each viewport displays the study report on the EI Desktop Text page when clicked. This function can now be assigned to a keyboard shortcut.

In the most common scenario, pressing the assigned shortcut key will display the report for the comparison study. Pressing the key again toggles to the report of either a second comparison study, or otherwise the empty report of the active study.

## Mouse jiggler

PACS Assistant has a mouse jiggler which can suppress the Windows screensaver and can prevent the screen from turning off.
