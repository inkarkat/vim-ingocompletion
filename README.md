INGOCOMPLETION
===============================================================================
_by Ingo Karkat_

UNPUBLISHED AND UNSUPPORTED PLUGIN
------------------------------------------------------------------------------

Attention! This plugin has not (yet) been published and is only provided for
discussions or demonstration. It may be abandoned, deleted, or radically
changed without further notice. Documentation likely is absent or incomplete,
severe bugs or security issues may exist, crucial dependencies or configuration
may be completely missing. In other words, it may only work for me.
You may still take inspiration from it, copy parts or try to use it (according
to the license); just don't expect me to help you or offer any support at all.

DESCRIPTION
------------------------------------------------------------------------------

This plugin ...

### SOURCE

- vimtip #1228, vimtip #1386: Completion popup selection like other IDEs

### SEE ALSO
(Plugins offering complementary functionality, or plugins using this library.)

### RELATED WORKS
(Alternatives from other authors, other approaches, references not used here.)

USAGE
------------------------------------------------------------------------------

### CUSTOMIZATION OF COMPLETION BEHAVIOR

    CTRL-X CTRL-F           On Windows, when completing paths that only consist of
                            forward slashes, temporarily set 'shellslash' so that
                            the completion candidates use forward slashes instead
                            of the default backslashes, too.

### POPUP MENU MAPPINGS AND BEHAVIOR

    Fix the multi-line completion problem.

    CTRL-G CTRL-P           Show extra information about the currently selected
                            completion in the preview window (if available). You
                            need to re-enable this for each completion.

    <Enter>                 Accept the currently selected match and stop completion.
                            Alias for i_CTRL-Y.
                            Another <Tab> will continue completion with the next
                            word instead of restarting the completion; if you
                            don't want this, use i_CTRL-Y instead.

                            Quick access accelerators for the popup menu:
    1-5                     In the popup menu: Accept the first, second, ...
                            visible offered match and stop completion.
    9-6                     In the popup menu: Accept the last, second-from-last,
                            ... visible offered match and stop completion.
                            These assume a freshly opened popup menu where no
                            selection (via <Up>/<Down>/...) has yet been made. In
                            a backward completion (first candidate at bottom), the
                            counting starts from the bottom, too; i.e. 9 is the
                            candidate displayed at the top of the completion
                            popup.
    <S-CR>                  In the popup menu: Accept the second visible offered
                            match and stop completion; shortcut for 2 that may be
                            quicker to reach.

    Aliases for popupmenu-keys:
    CTRL-F                  Use a match several entries further. This doesn't work
                            in filename completion, where CTRL-F goes to the next
                            matching filename.
    CTRL-B                  Use a match several entries back.

    <Esc>                   Abort completion, go back to what was typed.
                            In contrast to i_CTRL-E, this also erases the
                            longest common string.

### INLINE COMPLETION WITHOUT POPUP MENU

    CTRL-N / CTRL-P         Inline completion without popup menu:
                            Find next/previous match for words that start with the
                            keyword in front of the cursor, looking in places
                            specified with the 'complete' option.
                            The first match is inserted fully, key repeats will
                            step through the completion matches without showing a
                            menu.
                            One can abort the completion and return to what was
                            inserted beforehand via <C-E>, or accept the currently
                            selected match and stop completion with <C-Y>.
                            It is not possible to abort via <Esc>, because that
                            would clash with stopping insertion at all; i.e. it
                            would then not be possible to exit insert mode after
                            an inline completion without typing and removing an
                            additional character.

### COMPLETE LONGEST AND PRESELECT

    On completion with multiple matches, insert the longest common text AND
    pre-select (but not yet insert) the first match. When 'completeopt' contains
    "longest", only the longest common text of the matches is inserted. I want to
    combine this with automatic selection of the first match so that I can both
    type more characters to narrow down the matches, or simply press <Enter> to
    accept the first match or press CTRL-N to use the next match.

### ADDITIONAL COMPLETION TRIGGERS

    Shorten some commonly used insert completions.
    CTRL-F                  File name completion i_CTRL-X_CTRL-F

    CTRL-Space              IDE-like generic completion (via the last-used omni
                            completion ('omnifunc'). Also cycles through matches
                            when the completion popup is visible.

    CTRL-X [N] CTRL-D       Limit 'dictionary' to the [N]'th entry for this
                            triggered i_CTRL-X_CTRL-D completion.
    CTRL-X [N] CTRL-T       Limit 'thesaurus' to the [N]'th entry for this
                            triggered i_CTRL-X_CTRL-T completion.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at https://github.com/inkarkat/vim-ingocompletion
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim ingocompletion*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:
configvar

plugmap
CONTRIBUTING
------------------------------------------------------------------------------

DO NOT report any bugs, send patches, or suggest features via the issue
tracker at https://github.com/inkarkat/vim-ingocompletion/issues or email
(address below).

HISTORY
------------------------------------------------------------------------------

##### GOAL
First published version.

##### 0.01    14-Jun-2009
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2009-2021 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
