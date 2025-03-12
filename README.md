# PACS Assistant

## Introduction

PACS Assistant is intended to make the combination of Agfa Enterprise Imaging (EI), PowerScribe, and Epic work together more seamlessly and efficiently.

PACS Assistant performs multiple functions which are described below. PACS Assistant is highly customizable--most of its functions can be selectively enabled or disabled from the Settings page.

## How to install

To use PACS Assistant on your home workstation, copy the PACS Assistant folder to your Documents folder. Inside the PACS Assistant folder, double click on "Run PACS Assistant" to start it. You can create a desktop shortcut to make it easier to run next time.

The first time you run it, you'll need to enter your username and password. PACS Assistant remembers your username and password so you don't have to enter it again.

PACS Assistant will work on hospital workstations, but for security reasons it will not remember your password on hospital workstations.

A useful key to remember is **F2**, which toggles on/off PACS Assistant and can get you out of trouble if you notice something weird happening. There is also a toggle switch in the lower left corner of the PACS Assistant window.

## Single sign on

PACS Assistant streamlines PACS start up especially when reading from home.

At home, clicking the **Power** button and entering a one time passcode will complete the entire sequence of connecting to the VPN and starting EI, Powerscribe, and Epic. Your username and password are stored securely so you don't have to reenter them every time.

At the hospital, clicking the **Power** button will start EI, Powerscribe, and Epic. On shared workstations, only your username is stored. You will have to enter your password once when you first start working.

## Window management

PACS Assistant can remember your window layout and restore them to their saved positions when PACS is started.

The EPIC Secure Chat window can automatically enlarge and shrink itself to save space when not in use.

PACS Assistant can automatically dismiss selected popup messages such as PowerScribe Logout confirmation messages, PowerScribe Create addendum confirmation messages, Epic Timezone confirmation messages, etc.

## Focus following

PACS Assistant lets you treat EI, PowerScribe, and Epic as though they were integrated instead of being separate applications. PACS Assistant follows your mouse pointer on the screen and keeps the proper application in focus. You don't need to click just to change which application window has focus.

Key presses get sent to the appropriate application. In most cases, this is the application under the mouse pointer.

> For example, when the mouse pointer is over the EI image window, pressing the `C` key will trigger the EI Shortcut that is assigned to the `C` key. But when the mouse pointer is over the PowerScribe window, pressing the `C` key will type the letter *c* in PowerScribe.

When appropriate, key presses get sent to a different application than is under the mouse pointer.

> For example, if the Tab key is assigned to the PowerScribe command "Next Field", pressing Tab will always send a "Next Field" command to PowerScribe regardless of whether the mouse pointer is over the PowerScribe window or over an EI image window.

## Viewport activation for EI

PACS Assistant can activate the viewport under the mouse pointer when certain EI keyboard shortcuts are pressed. You don't need to click just to change the active viewport.

> For example, if the `1` key is mapped to EI Window/level Preset #1, pressing the `1` key will activate the viewport under the mouse pointer *before* changing the window/level, since that is what you probably intended.

In order to enable this functionality, you will need to tell PACS Assistant which shortcut keys you have mapped to which tools in EI.

## New keyboard shortcuts

PACS Assistant provides several new keyboard shortcuts for working with PowerScribe and EI. These shortcuts are in effect whenever the mouse pointer is over the EI or PowerScribe windows.

### CapsLock key

**CapsLock** turns the microphone on and off.

**Shift-CapsLock** signs the report currently being dictated.

If no report is currently being dictated, then start (or resume) dictation on the currently open study.

If the currently open study is not ready for dictation, then start dictation of the currently selected studies on the EI worklist.

If no studies are selected studies on the EI worklist, then start dication of the entire worklist.

**Ctrl-CapsLock** saves the report being dictated as a Draft.

**Shift-Ctrl-CapsLock** signs the report being dictated as Preliminary.

**Alt-CapsLock** toggles the caps lock state (*i.e.* the original function of the CapsLock key).

### Tab key

**Tab** moves to the next field in a PowerScribe report.

**Shift-Tab** moves to the previous field in a PowerScribe report.

**Ctrl-Tab** moves the cursor to the end of the current line in a PowerScribe report. Pressing it a second time moves the cursor down one line then to the end of the line.

> This can be useful to position the cursor *after* the default text when tabbing into a field so that dictation does not replace the default text.

**Shift-Ctrl-Tab** moves the cursor up one line then to the end of the line.

### ` (Backtick or tilde) key

**Backtick** brings up the report for the comparison study (same as clicking on the Display Study Details icon in the upper right corner of each viewport), showing the Text page on the EI desktop if necessary.

Pressing it again brings up the report of a second comparison study if there is one displayed on the screen. If no second comparison study is displayed, it brings up the empty report of the active study.

**Shift-Backtick** toggles between the Worklist and Text pages of the EI Desktop.

**Ctrl-Backtick** brings up the Search page of the EI Desktop. Pressing it a second time clears the search fields and puts the cursor in the Patient last name field, ready to enter a search.

### Spacebar

The **Spacebar** has several new functions:

- When the mouse pointer is over an EI image window, pressing **Spacebar** performs a double-click. This is useful to enlarge or restore the size of a series, or if the mouse pointer is over a series thumbnail to put the series into the active viewport.

> Known issue: In some places, the spacebar no longer works to type a space. For example, when creating a text annotation on an image, the space bar will send a double-click which leads to unwanted side effects. If you need to type a space, you can press **Shift-Spacebar** to enter a space, or press **F2** to temporarily disable PACS Assistant while you are typing.

- While scrolling through images in EI by holding down the left mouse button, pressing **Spacebar** engages Click Lock, allowing the left mouse button to be physically released. Pressing **Spacebar** again disengages Click Lock. Clicking either mouse button also disengages Click Lock.

- When the mouse pointer is over the EI desktop List page, pressing **Spacebar** performs a double-click. This can occastionally be useful, such as to open a case.

### Escape key

**Shift-Esc** closes the current case in EI when the mouse pointer is over an EI image window (same as clicking on the *Remove from list* button).

### Ctrl-Z / Ctrl-Y

**Ctrl-Z** and **Ctrl-Y** will send Undo and Redo commands to PowerScribe even when the mouse pointer is within an EI window.

> This can be useful to undo when PowerScribe accidentally transcribes noise.

## Mouse jiggler

PACS Assistant can jiggle the mouse periodically in order to suppress the Windows screensaver and prevent the screen from turning off.

## Comments

PACS Assistant is optimized for a handsfree  setup: a handsfree microphone (*i.e.* a freestanding desktop mic or headset), right hand on the mouse, and left hand on the keyboard.

If most EI keyboard shortcuts are mapped to the left half of the keyboard, then almost everything can be done without looking down at the keyboard or away from the screen.

A physically separate keypad for shortcuts, such as a Tartarus gaming keypad, is an alternative to the standard keypad. With PACS Assistant I've found a separate keypad redundant since everything can be done with just the standard keyboard.

PACS Assistant is still being developed, so you may run into bugs or conflicts with other applications. Because it has very limited ability to communicate with EI, PowerScribe, and Epic, some features occasionally will have glitches or won't work.

If you use PACS Assistant, let me know of any problems you encounter as well as any features you'd like to see. I will be adding more features in the future.
