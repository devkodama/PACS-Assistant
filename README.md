# PACS Assistant

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently.

PACS Assistant performs multiple functions which are described below. PACS Assistant is highly customizable--most of its functions can be selectively enabled or disabled from the Settings page.

## How to use

On your home workstation, copy the PACS Assistant folder to the Documents folder. Inside the PACS Assistant folder, double click on "Run PACS Assistant" to start it. You can create a desktop shortcut to make it easier to run next time. The first time you run it, you'll need to enter your username and password. PACS Assistant remembers your username and password so you don't have to enter it again.

On hospital workstations, copy the PACS Assistant folder to the Documents folder. Inside the PACS Assistant folder, double click on "Run PACS Assistant" to start it. You cannot create a persistent desktop shortcut on hospital workstations. PACS Assistant will remember your username but not your password for security reasons.

A useful key to remember is **F2**, which toggles on/off PACS Assistant and can get you out of trouble if you notice something weird happening. There is also a toggle switch in the lower left corner of the PACS Assistant window.

## Single sign on

PACS Assistant streamlines PACS start up, especially when reading from home.

At home, clicking the **Power** button and entering a one time passcode will complete the entire sequence of connecting to the VPN and starting EI, Powerscribe, and Epic. PACS Assistant securely stores your username and password so you don't have to reenter them every time.

>ℹ️ Your stored username and password are protected by your Windows login credentials. Anyone who knows your Windows login can access your stored username and password.

At the hospital, clicking the **Power** button will start EI, Powerscribe, and Epic. On hospital workstations, you will have to enter your password each time you start PACS Assistant. Your password is not stored for security reasons.

## Window management

PACS Assistant can remember your window layout and restore them to their saved positions when PACS is started.

The EPIC Secure Chat window can automatically enlarge and shrink itself to save space when not in use.

PACS Assistant can automatically dismiss selected popup messages such as PowerScribe Logout confirmation messages, PowerScribe Create addendum confirmation messages, Epic Timezone confirmation messages, etc.

## Focus following

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being separate applications. PACS Assistant follows your mouse pointer on the screen and keeps the proper application in focus. You don't need to click to change which application window has focus.

In most cases, key presses are sent to the application under the mouse pointer.

> For example, when the mouse pointer is hovering over the EI image window, pressing the `C` key will trigger the EI Shortcut that is assigned to the `C` key. However, when the mouse pointer is hovering over the PowerScribe window, pressing the `C` key will type the letter *c* in PowerScribe.

When appropriate, however, key presses may be sent to a different application than is under the mouse pointer.

> For example, if the Tab key is assigned to the PowerScribe command "Next Field", pressing Tab will always send a "Next Field" command to PowerScribe regardless of whether the mouse pointer is hovering over the PowerScribe window or an EI image window.

## Viewport activation for EI

PACS Assistant can activate the viewport under the mouse pointer when certain EI keyboard shortcuts are pressed. You don't need to first click to change the active viewport.

> For example, if the `1` key is mapped to EI Window/Level Preset #1, pressing the `1` key will first activate the viewport under the mouse pointer and *then* change the window/level, since that is what you likely intended.

In order to enable this functionality, you need to tell PACS Assistant (via Settings) which shortcut keys are mapped to which tools in EI.

## New keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect whenever the mouse pointer is hovering over the EI or PowerScribe windows.

### CapsLock key

**CapsLock** turns the microphone on and off.

**Shift-CapsLock** can do one of several things:

* If a report is currently being dictated, signs the report. Equivalent to the PowerScribe Sign button (F4).

* If a study is open and ready to start dictation, then start (or resume) dictation. Equivalent to the EI Start (or Resume) reading button.

* If the currently open study is not ready for dictation, and one or more studies are selected on the EI worklist, then start dictation of the selected. Equivalent to the EI Start (or Resume) reading button.

* If no studies are selected studies on the EI worklist, then start dication of all the studies on the worklist. Equivalent to the EI Start list button.

**Ctrl-CapsLock** saves the report currently being dictated as a Draft. Equivalent to the PowerScribe Draft button (F12).

**Shift-Ctrl-CapsLock** signs the report currently being dictated as Preliminary. Equivalent to the PowerScribe Prelim button.

**Alt-CapsLock** toggles the caps lock state (*i.e.* the original function of the CapsLock key).

### Tab key

**Tab** moves to the next field in a PowerScribe report.

**Shift-Tab** moves to the previous field in a PowerScribe report.

**Ctrl-Tab** moves the cursor to the end of the current line in a PowerScribe report. Pressing it a second time moves the cursor down one line, then to the end of the line.

> 💡 This can be useful to position the cursor *after* the default text when tabbing into a field so that dictation does not replace the default text.

**Shift-Ctrl-Tab** moves the cursor up one line, then to the end of the line.

### ` (Backtick or tilde) key

**Backtick** brings up the report for the comparison study (equivalent to clicking on the Display Study Details button in the upper right corner of each viewport), switching to the Text page of the EI desktop if necessary.

Pressing it again brings up the report of a second comparison study if one is being displayed on the screen. If no second comparison study is displayed, it brings up the empty report of the active study.

**Shift-Backtick** toggles between the Worklist and Text pages of the EI Desktop.

**Ctrl-Backtick** brings up the Search page of the EI Desktop. Pressing it a second time clears the search fields and puts the cursor in the Patient last name field, ready for entering a search.

### Spacebar

The **Spacebar** can do one of several things:

- While scrolling through images in EI by holding down the left mouse button, pressing **Spacebar** engages Click Lock, allowing the left mouse button to be physically released. Pressing **Spacebar** again disengages Click Lock. Clicking either mouse button also disengages Click Lock.

- When the mouse pointer is over an EI image window, pressing **Spacebar** performs a double-click. This is useful to enlarge or restore the size of a series, or if the mouse pointer is over a series thumbnail to put the series into the active viewport.

> Known issue: In some places, the spacebar no longer works to type a space. For example, when creating a text annotation on an image, the space bar will send a double-click which leads to unwanted side effects. If you need to type a space, you can press **Shift-Spacebar** to enter a space, or press **F2** to temporarily disable PACS Assistant while you are typing.


- When the mouse pointer is over the EI desktop List page, pressing **Spacebar** performs a double-click. This could be useful to open a study.

- Usage Tip: ...

### Escape key

**Shift-Esc** closes the current case in EI when the mouse pointer is over an EI image window (same as clicking the EI *Remove from list* button).

### Ctrl-Z / Ctrl-Y

**Ctrl-Z** and **Ctrl-Y** send Undo and Redo commands, respectively, to PowerScribe when the mouse pointer is hovering over PoserScribe or EI.

> This can be useful to undo something when PowerScribe accidentally transcribes noise.

> Don't enable this if you have Ctrl-Z or Ctrl-Y mapped as EI shortcuts.

## Mouse jiggler

PACS Assistant jiggles the mouse periodically in order to suppress the Windows screensaver and prevent the screen from turning off.

## Comments

PACS Assistant is optimized for a handsfree  setup, *i.e.* a handsfree microphone, right hand on the mouse, and left hand on the keyboard.

By mapping EI keyboard shortcuts to the left half of the keyboard and taking advantage of PACS Assistant's shortcuts, then pretty much everything can be done with minimal hand movements and without needing to look down at the keyboard or away from the screen.

PACS Assistant could be used with an accessory keypad such as a Tartarus gaming keypad for shortcuts, by reassigning the new functions to different keys. I've found that the regular keyboard is sufficient, however, and has the advantage of not having to carry an accessory keypad when switching to a different workstation.

PACS Assistant is still being developed and more features are to come. Some features will occasionally glitch or not work due to the nature of this type of software. You may run into conflicts with other applications; in most cases, temporariliy disabling PACS Assistant will get around the conflict.

If you use PACS Assistant, let me know of any problems you encounter as well as any features you'd like to see.
