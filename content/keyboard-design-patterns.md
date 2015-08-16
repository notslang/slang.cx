# Keyboard Design Patterns
This document will attempt to cover the general patterns behind keyboard shortcut design, and how keys are combined in meaningful ways to produce new actions.

## Shift
`Shift` means "reverse" or "select" depending upon the command. The "select" meaning can be thought of as a reverse of the default method of moving around text without selecting.

Selections made using `Shift` are continuous - everything between the beginning and end of the selection is included. This has the benefit of being quicker to select entire sections, but isn't good for selecting specific parts of a list/body of text.

## Space
In addition to entering single whitespace characters, `Space` means "toggle selection"

...Add example of checkboxes...

## Ctrl / ⌘
On Apple keyboards, this is `⌘`, and on "Windows-style" keyboards this is `Ctrl`. It represents specific actions to be performed on either the selection, or on the entire file

Examples:
 - `⌘` + `a`: select all
 - `⌘` + `shift` + `a`: un-select all
 - `⌘` + `z`: undo
 - `⌘` + `shift` + `z`: redo
 - `⌘` + `x`: cut
 - `⌘` + `c`: copy
 - `⌘` + `v`: paste

## Home
Go to the beginning

## End
Go to the end
