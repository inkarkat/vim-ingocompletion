" ingocompletion.vim: Customization of completions.
"
" DEPENDENCIES:
"   - ingo/window/preview.vim autoload script
"   - Uses functions defined in ingospell.vim for |i_CTRL-X_CTRL-S|
"     modifications.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	037	21-Jun-2013	FIX: Forgot <SID>(CompleteoptLongestSelectNext)
"				in imap <C-f>.
"				ENH: On Windows, when completing paths that only
"				consist of forward slashes, temporarily set
"				'shellslash' so that the completion candidates
"				use forward slashes instead of the default
"				backslashes, too.
"	036	08-Apr-2013	Move ingowindow.vim functions into ingo-library.
"	035	27-Feb-2013	Make CompleteMultilineFix and
"				CompleteThesaurusFix more robust by including
"				triggers on InsertLeave and BufLeave; we don't
"				want to skip applying the fixes or apply them in
"				the wrong buffer.
"				Better handling of CompleteThesaurusFix inside
"				snipMate snippets. Adapting the tabstop
"				positions is too difficult; instead, postpone
"				the deletion of the temporary Unit Separators
"				until snippet editing is done. For
"				re-triggering, do not insert a Unit Separator
"				when there's already one before the current
"				keyword. And correctly calculate the cursor
"				position when multiple Unit Separators have been
"				deleted. And also remove the Unit Separators
"				from all other lines; the snippet may have
"				mirrored them there.
"				FIX: Make retrieval of l:textBeforeCursor
"				multibyte-safe.
"	034	27-Feb-2013	FIX: Avoid clobbering the search history in
"				s:CompleteThesaurusFix() and
"				s:CompleteMultilineFix().
"	033	02-Nov-2012	XXX: FuzzyFinder uses the completion popup for
"				its own selection control; our enhancements
"				prevent the abort of the FuzzyFinder search via
"				<Esc>.
"	032	12-Oct-2012	Use omni completion instead of user completion
"				for <C-Space> mapping; many useful completions
"				(Python, HTML, CSS, JavaScript, ...) ship with
"				Vim.
"	031	11-Oct-2012	BUG: Must use :imap for <Esc> hook, or
"				abbreviations aren't expanded any longer.
"	030	02-Oct-2012	Add <Plug>(CompleteStart) definition for other
"				modes.
"	029	13-Sep-2012	BUG: Must use :imap for <CR> hook, or
"				abbreviations aren't expanded any longer. Use
"				intermediate :inoremap <SID>PumCR mapping to
"				avoid that literal keys like <C-r> are remapped,
"				too.
"	028	18-Aug-2012	In s:CompleteThesaurusFix(), remove the
"				temporary Unit Separator globally; when doing
"				completion with snipMate mirroring, the Unit
"				Separator is mirrored, too, so it should be
"				removed, too. Of course, OTOH it would be more
"				correct to limit the substitution to before the
"				cursor.
"	027	12-May-2012	Change CTRL-W_CTRL-P to CTRL-G_CTRL-P to avoid
"				delaying CTRL-W (delete word under cursor),
"				which is important in console Vim.
"	026	09-May-2012	Rename <Plug>CompleteoptLongestSelect.
"	025	05-May-2012	Switch order in s:EnableCompletionPreview() to
"				avoid unexpected scrolling in popup menu when
"				moving along forward.
"				ENH: When an unused preview window exists, keep
"				/ enable completion preview instead of disabling
"				it (when a new completion starts).
"				Rename <Plug>CompleteoptLongestSetUndo to
"				<Plug>(CompleteStart), because it now also
"				includes the handling for completion preview.
"	024	04-May-2012	ENH: Enable completeopt=preview on demand via
"				CTRL-W_CTRL-P in the completion popup menu, and
"				automatically disable it again when a match is
"				accepted.
"	023	05-Apr-2012	Remove i_CTRL-] shortening; it prevents manual
"				abbreviation expansion and was overridden by
"				snipMate.vim, anyway.
"	022	22-Jan-2012	Add <SID>CompleteStopInsert() hook to <CR> for
"				BidiComplete's immediate leave of insert mode.
"				CHG: In the popup menu, 9 (not 0) is now the
"				shortcut key for the last visible completion
"				match. This is hopefully more intuitive, as I
"				often got this wrong in the past.
"	021	15-Dec-2011	Work around thesaurus completion's limitation of
"				treating all whitespace and non-keyword
"				characters as delimiters. Limit the delimites to
"				lower-ASCII unprintable characters and (mainly)
"				<Tab>. Enable insertion of newlines via symbol
"				workarounds.
"	020	09-Oct-2011	imap <CR>: Use i_CTRL-R instead of
"				i_CTRL-\_CTRL-O to invoke the calls to
"				ingosupertab and the multi-line fix. The leave
"				of insert mode made my CompleteHelper#Repeat#...
"				not repeating when accepting a completion popup
"				match via <CR>, because the run-once autocmds
"				somehow didn't run.
"				Make multi-line completion fix support repeat
"				functionality of CompleteHelper.vim: After
"				expansion of newlines, the repeat record must be
"				updated so that a repeat of completion is
"				detected correctly.
"	019	05-Oct-2011	Implement check before substitution and cursor
"				column correction in multi-line completion fix.
"				BUG: Must only add the multi-line completion fix
"				to the pumvisible()-branch of <CR>; doing this
"				now directly in the Ex command-line without
"				another <SID>-mapping.
"	018	04-Oct-2011	Add fix for multi-line completion problem.
"	017	30-Sep-2011	Avoid showing internal commands and expressions
"				by using <silent>.
"	016	21-Sep-2011	Avoid use of s:function() by using autoload
"				function name.
"	015	29-Jul-2011	BUG: Choosing completion candidate via 0-9 quick
"				access accelerators does not work for backwards
"				completion (like <C-X><C-P>, <Tab> from
"				ingosupertab.vim).
"	014	29-Jul-2011	ENH: Another <Tab> after accepting a completion
"				candidate with <CR> in the popup menu or <C-Y>
"				in inline completion will continue completion
"				with the next word instead of restarting the
"				completion.
"	013	24-Sep-2010	Added check via recorded undo point
"				to <Esc> mapping so that a completion that does
"				not prepend <Plug>CompleteoptLongestSetUndo
"				(e.g. because it's not under my control) doesn't
"				wreak havoc to the buffer. (This happened when
"				aborting a fuf.vim search.)
"				FIX: The '" mark can only be set since Vim 7.2.
"	012	06-Aug-2010	Retired <Esc> overload to abort Inline
"				Completion, as it clashed with leaving insert
"				mode. Instead, defining <C-E> and <C-Y> mappings
"				like with the popup menu. The corresponding
"				mappings to "Insert from Below / Above" have
"				been moved from ingomappings.vim and augmented.
"	011	08-Jul-2010	Restructured some script fragments.
"				Added i_CTRL-N / i_CTRL-P Inline Completion
"				without popup menu.
"	010	13-Jan-2010	|i_CTRL-X_CTRL-S| now consumes wrapper from
"				ingospell.vim to allow use when spelling is
"				disabled. The mapping must be in this script
"				because :imap and <Plug> mappings somehow don't
"				work properly.
"	009	12-Jan-2010	Added missing <C-x><C-s> spell complete overload
"				of <C-x>s.
"	008	13-Nov-2009	Added quick access accelerators 0-9 for the
"				popup menu.
"	007	07-Aug-2009	BF: Always defining <Plug>UndoLongest, not just
"				for Complete longest+preselect.
"				Re-introduced IDE-like generic completion
"				(i_CTRL-Space), now via the last-used user
"				completion.
"	006	25-Jun-2009	Now also using a function (s:Complete()) for
"				g:IngoSuperTab_complete to be able to use
"				s:SetUndo() instead of the m" command, which
"				broke repetition of the completion via '.'.
"	005	18-Jun-2009	Replaced temporary mark z with mark ".
"				Now setting undo mark via setpos() instead of
"				using the 'm"' command. With this, completion
"				with following words isn't broken anymore.
"				Added g:IngoSuperTab_continueComplete for
"				IngoSuperTab completion continuation.
"	004	17-Jun-2009	ENH: Now aborting completion without additional
"				undo point. Instead, setting mark z via
"				<Plug>CompleteoptLongestSetUndo.
"	003	16-Jun-2009	ENH: Abort completion: <Esc> mapping ends
"				completion and also erases the longest common
"				string now.
"	002	14-Jun-2009	CTRL-N/P now use, not just select the subsequent
"				match. That was impossible to implement because
"				Vim ignores the mappings there. This alternative
"				might actually reduce typing on some occasions,
"				too.
"	001	14-Jun-2009	file creation from ingomappings.vim

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_ingocompletion') || (v:version < 700)
    finish
endif
let g:loaded_ingocompletion = 1
let s:save_cpo = &cpo
set cpo&vim

"- customization of completion behavior ----------------------------------------

" CTRL-X CTRL-F		On Windows, when completing paths that only consist of
"			forward slashes, temporarily set 'shellslash' so that
"			the completion candidates use forward slashes instead of
"			the default backslashes, too.
if exists('+shellslash')
    function! s:CompleteFilePathSeparatorStart()
	let l:startCol = searchpos('\f*\%#', 'bn', line('.'))[1]
	if l:startCol == 0
	    return ''
	endif
	let l:base = strpart(getline('.'), l:startCol - 1, (col('.') - l:startCol))
	let [l:native, l:foreign] = (&shellslash ? ['/', '\'] : ['\', '/'])
	if stridx(l:base, l:native) == -1 && stridx(l:base, l:foreign) != -1
	    augroup CompleteFilePathSeparator
		execute printf('autocmd! CursorMovedI,InsertLeave,BufLeave * let &shellslash=%d | autocmd! CompleteFilePathSeparator', &shellslash)
	    augroup END
	    let &shellslash = ! &shellslash
	endif

	return ''
    endfunction
    inoremap <silent> <expr> <SID>(CompleteFilePathSeparatorStart) <SID>CompleteFilePathSeparatorStart()
else
    inoremap <silent> <SID>(CompleteFilePathSeparatorStart) <Nop>
endif



"- popup menu mappings and behavior -------------------------------------------

"			Fix the multi-line completion problem.
"			Currently, completion matches are inserted literally,
"			with newlines represented by ^@. Vim should expand this
"			into proper newlines. We work around this via an autocmd
"			that fires once after completion (the CursorMovedI event
"			is not fired during completion with the popup menu), and
"			by hooking into the <CR> key. (<C-Y> apparently works
"			even without this.)
"			(FIXME: It seems to be fired once after the initial
"			completion trigger with empty 'completeopt'.)
"			Usage: All CTRL-X_... completion mappings that may
"			return multi-line matches must append
"			<Plug>(CompleteMultilineFixSetup) to get this fix.
function! s:CompleteMultilineFix()
    let l:textBeforeCursor = strpart(getline('.'), 0, col('.') - 1)
    let l:lastNewlineCol = strridx(l:textBeforeCursor, "\n")
    if l:lastNewlineCol == -1
	" Nothing to do.
	return ''
    endif

    if strridx(l:textBeforeCursor, nr2char(160)) != -1
	substitute/\%d160/ /ge
    endif

    execute "substitute/\n/\\r/ge"

    " The substitute command positions the cursor at the first column of the
    " last line inserted. This is fine when the completion ended with a newline,
    " but needs correction when an incomplete last line has been inserted.
    call cursor(line('.'), len(l:textBeforeCursor) - l:lastNewlineCol)

    " Integration into CompleteHelper.vim.
    call CompleteHelper#Repeat#SetRecord()

    call histdel('search', -1)

    return ''
endfunction
function! s:CompleteMultilineFixSetup()
    augroup CompleteMultilineFix
	autocmd!
	autocmd CursorMovedI,InsertLeave,BufLeave * call <SID>CompleteMultilineFix() | autocmd! CompleteMultilineFix
    augroup END

    return ''
endfunction
inoremap <expr> <Plug>(CompleteMultilineFixSetup) <SID>CompleteMultilineFixSetup()

function! CompleteThesaurusMod( start )
    " Insert the temporary Unit Separator in position a:start, and adapt the
    " cursor position.
    let l:cursorCol = col('.')
	let l:line = getline('.')
	if matchstr(l:line, '.\%' . (a:start + 1) . 'c') == nr2char(31)
	    " There's already a Unit Separator in front of the keyword before
	    " the cursor.
	    return ''
	endif
	let l:modline = strpart(l:line, 0, a:start) . nr2char(31) . strpart(l:line, a:start)
	call setline('.', l:modline)
    call cursor(line('.'), l:cursorCol + 1)
    return ''
endfunction
function! s:CompleteThesaurusPrep()
    let l:modifier = ''

    if col('.') > 1 " Unless we're at the beginning of a line ...
	" We need to temporarily insert an non-(extended) keyword character
	" (let's take the rare ASCII 31 = Unit Separator), or the search for
	" completions with the extended 'iskeyword' will fail.
	let l:keywordStartCol = searchpos('\k*\%#', 'bn', line('.'))[1]
	if l:keywordStartCol == 0
	    let l:keywordStartCol = col('.')
	endif
	" Cannot directly modify inside map-<expr>.
	let l:modifier = "\<C-r>\<C-r>=CompleteThesaurusMod(" . (l:keywordStartCol - 1) . ")\<CR>"
    endif

    " The thesaurus completion treats all non-keyword characters as delimiters.
    " Make almost everything (except the lower unprintable ASCII characters,
    " including the desired delimiter <Tab>) a keyword character to be able to
    " include spaces and other non-alphabetic characters like ["'()] in
    " thesaurus words, and only have <Tab> as delimiter.
    " Note that this has the side effect of only allowing completion from
    " <Tab> and other lower-ASCII-separated completion bases, since the
    " i_CTRL-X_CTRL-T completion both determines the completion base and
    " generates the completion matches with the same (modified) 'iskeyword'
    " setting. We would need to write our own custom completion to get around
    " this. Instead, we work around this via CompleteThesaurusMod(), see above.
    if ! exists('s:save_iskeyword')
	" When the CompleteThesaurusFix hasn't been applied yet, but another
	" thesaurus completion is triggered, we must not clobber the original,
	" correct saved option value with the temporary one.
	let s:save_iskeyword = &l:iskeyword
    endif
    setlocal iskeyword=@,32-255

    return l:modifier
endfunction
inoremap <expr> <SID>(CompleteThesaurusPrep) <SID>CompleteThesaurusPrep()
function! s:CompleteThesaurusFix()
    let &l:iskeyword = s:save_iskeyword
    unlet s:save_iskeyword

    " Remove the temporary Unit Separator at the beginning of the inserted
    " completion match.
    let l:cursorCol = col('.')
    let l:textBeforeCursor = matchstr(getline('.'), '^.*\%'.col('.').'c')
    if strridx(l:textBeforeCursor, nr2char(31)) != -1
	substitute/\%d31//ge
	let l:offset = strlen(substitute(l:textBeforeCursor, '[^'.nr2char(31).']', '', 'g'))
	call cursor(line('.'), l:cursorCol - l:offset)
    endif
    let l:save_cursor = getpos('.')
	" Snippets may have mirrored the thesaurus completion to other lines.
	" Those need the temporary Unit Separator removed, too.
	keepjumps %substitute/\%d31//ge
    call setpos('.', l:save_cursor)

    " Convert newline symbol to actual newline.
    let l:lastNewlineCol = strridx(l:textBeforeCursor, nr2char(182))
    if l:lastNewlineCol != -1
	substitute/\%d182/\r/ge

	" The substitute command positions the cursor at the first column of the
	" last line inserted. This is fine when the completion ended with a newline,
	" but needs correction when an incomplete last line has been inserted.
	call cursor(line('.'), len(l:textBeforeCursor) - l:lastNewlineCol)
    endif

    " Integration into CompleteHelper.vim.
    call CompleteHelper#Repeat#SetRecord()

    call histdel('search', -1)
    return ''
endfunction
function! s:CompleteThesaurusFixSetup()
    augroup CompleteThesaurusFix
	autocmd!
	" Assume that snippet expansion is done when the global snipMate context
	" isn't there, or when the cursor jumped to the end of the current line.
	autocmd CursorMovedI,InsertLeave *
	\   if ! exists('g:snipPos') || col('.') >= col('$') |
	\	call <SID>CompleteThesaurusFix() | execute 'autocmd! CompleteThesaurusFix' |
	\   endif
	autocmd BufLeave * call <SID>CompleteThesaurusFix() | autocmd! CompleteThesaurusFix
    augroup END

    return ''
endfunction
inoremap <expr> <SID>(CompleteThesaurusFixSetup) <SID>CompleteThesaurusFixSetup()

" i_CTRL-G_CTRL-P	Show extra information about the currently selected
"			completion in the preview window (if available). You
"			need to re-enable this for each completion.
function! s:EnableCompletionPreview()
    set completeopt+=preview
    return "\<Up>\<Down>"
endfunction
" Note: Even when all keys that can conclude a completion are wrapped in this,
" it still doesn't cover all cases (e.g. continued typing to get out of the
" completion). Rather than use another fire-once autocmd to turn this off, we
" use the fact that (almost all?) completion mappings include the
" <Plug>(CompleteStart) mapping, and as it's enough to disable the
" setting before the next completion, go for this instead.
function! s:DisableCompletionPreview( wrappedMapping )
    set completeopt-=preview
    return a:wrappedMapping
endfunction
inoremap <expr> <C-g><C-p> pumvisible() ? <SID>EnableCompletionPreview() : '<C-g><C-p>'

" <Enter>		Accept the currently selected match and stop completion.
"			Alias for |i_CTRL-Y|.
"			Another <Tab> will continue completion with the next
"			word instead of restarting the completion; if you don't
"			want this, use |i_CTRL-Y| instead.
function! s:CompleteStopInsert()
    " This hook can be used by completion functions to immediately leave insert
    " mode after a completion match was chosen. Used by BidiComplete.
    if exists('g:CompleteStopInsert')
	unlet g:CompleteStopInsert
	return "\<Esc>"
    else
	return ''
    endif
endfunction
inoremap <silent> <expr> <SID>PumCR <SID>DisableCompletionPreview('<C-y>').'<C-r>=ingosupertab#Completed()<CR><C-r>=<SID>CompleteMultilineFix()<CR><C-r>=<SID>CompleteStopInsert()<CR>'
" Note: Cannot use :inoremap here; abbreviations wouldn't be expanded any
" longer.
imap <silent> <expr> <CR> pumvisible() ? '<SID>PumCR' : '<CR>'

"			Quick access accelerators for the popup menu:
" 1-5			In the popup menu: Accept the first, second, ... visible
"			offered match and stop completion.
" 9-6			In the popup menu: Accept the last, second-from-last,
"			... visible offered match and stop completion.
"			These assume a freshly opened popup menu where no
"			selection (via <Up>/<Down>/...) has yet been made.
"			In a backward completion (first candidate at bottom),
"			the counting starts from the bottom, too; i.e. 9 is the
"			candidate displayed at the top of the completion popup.
inoremap <expr> 1 pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : '1'
inoremap <expr> 2 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up>'.<SID>DisableCompletionPreview('<C-y>')                 : '<Down>'.<SID>DisableCompletionPreview('<C-y>')                         : '2'
inoremap <expr> 3 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up>'.<SID>DisableCompletionPreview('<C-y>')             : '<Down><Down>'.<SID>DisableCompletionPreview('<C-y>')                   : '3'
inoremap <expr> 4 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')         : '<Down><Down><Down>'.<SID>DisableCompletionPreview('<C-y>')             : '4'
inoremap <expr> 5 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')     : '<Down><Down><Down><Down>'.<SID>DisableCompletionPreview('<C-y>')       : '5'
inoremap <expr> 9 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Up>'.<SID>DisableCompletionPreview('<C-y>')         : '<PageDown><Down>'.<SID>DisableCompletionPreview('<C-y>')               : '9'
inoremap <expr> 8 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp>'.<SID>DisableCompletionPreview('<C-y>')             : '<PageDown>'.<SID>DisableCompletionPreview('<C-y>')                     : '8'
inoremap <expr> 7 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down>'.<SID>DisableCompletionPreview('<C-y>')       : '<PageDown><Up>'.<SID>DisableCompletionPreview('<C-y>')                 : '7'
inoremap <expr> 6 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down><Down>'.<SID>DisableCompletionPreview('<C-y>') : '<PageDown><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')             : '6'

" Aliases for |popupmenu-keys|:
" CTRL-F		Use a match several entries further. This doesn't work
"			in filename completion, where CTRL-F goes to the next
"			matching filename.
" CTRL-B		Use a match several entries back.
inoremap <script> <expr> <C-f> pumvisible() ? '<PageDown><Up><C-n>' : '<SID>(CompleteFilePathSeparatorStart)<SID>(CompleteStart)<C-x><C-f><SID>(CompleteoptLongestSelectNext)'
inoremap <expr> <C-b> pumvisible() ? '<PageUp><Down><C-p>' : ''

" <Esc>			Abort completion, go back to what was typed.
"			In contrast to |i_CTRL-E|, this also erases the longest
"			common string.
" Note: To implement the total abort of completion, all mappings that start a
" completion must prepend <Plug>(CompleteStart).

function! s:RecordUndoPoint( positionExpr )
    " The undo point record consists of the position of a:positionExpr and the
    " buffer number. When this position record is assigned to a window-local
    " variable, it is also linked to the current window and tab page.
    return getpos(a:positionExpr) + [bufnr('')]
endfunction
" Set undo point to go back to what was typed when aborting completion.
"
" Setting of mark '" is only supported since Vim 7.2; use last jump mark ''
" for Vim 7.1.
let s:IngoCompletion_UndoMark = (v:version < 702 ? "'" : '"')
function! s:SetUndo()
    " Separately record information about the undo point so that a completion
    " that does not prepend <Plug>(CompleteStart) (e.g. because it's not under
    " my control) doesn't wreak havoc to the buffer. (This happened when
    " aborting a fuf.vim search.)
    let w:IngoCompetion_UndoPoint = s:RecordUndoPoint('.')

    call setpos("'" . s:IngoCompletion_UndoMark, getpos('.'))
    return ''
endfunction
" Note: Sneak in handling of the completion preview; as we cannot catch all
" situations when completion stops, better ensure that the setting is reset when
" starting a new completion, or keeping / enabling the setting when an unused
" preview window exists.
function! s:CheckCompletionPreview()
    let l:previewWinnr = ingo#window#preview#IsPreviewWindowVisible()
    if l:previewWinnr && empty(bufname(winbufnr(l:previewWinnr))) && ! getwinvar(l:previewWinnr, '&modifiable')
	" The preview window is open and contains an unmodifiable scratch
	" buffer, presumably from a previous completion preview. Keep / enable
	" completion preview.
	call s:EnableCompletionPreview()
    else
	call s:DisableCompletionPreview('')
    endif
    return ''
endfunction
" Note: By using a :map-expr that doesn't return anything and setting the
" mark via setpos() instead of the 'm' command, subsequent CTRL-X CTRL-N
" commands can be used to continue the completion with following words. Any
" inserted key (even CTRL-R=...<CR>) would break this.
inoremap <expr> <Plug>(CompleteStart) <SID>SetUndo().<SID>CheckCompletionPreview()
" Some completions may be triggered from other modes (e.g. MotionComplete allows
" to select the completion base in visual / select mode).
noremap  <expr> <Plug>(CompleteStart) <SID>SetUndo().<SID>CheckCompletionPreview()
inoremap <expr> <SID>(CompleteStart) <SID>SetUndo().<SID>CheckCompletionPreview()
function! s:UndoLongest()
    " Only undo when the undo point is intact; i.e. the window, buffer and mark
    " are still the same.
"****D echomsg '****' string(w:IngoCompetion_UndoPoint) string(s:RecordUndoPoint("'\""))
    if exists('w:IngoCompetion_UndoPoint') && w:IngoCompetion_UndoPoint == s:RecordUndoPoint("'" . s:IngoCompletion_UndoMark)
	unlet w:IngoCompetion_UndoPoint
	" After a completion, the line must be the same and the column must be
	" larger than before.
	if line("'" . s:IngoCompletion_UndoMark) == line('.') && col("'" . s:IngoCompletion_UndoMark) < col('.')
	    return "\<C-\>\<C-o>dg`" . s:IngoCompletion_UndoMark
	endif
    endif
    return ''
endfunction
" Note: Cannot use :inoremap here; abbreviations wouldn't be expanded any
" longer.
" XXX: FuzzyFinder uses the completion popup for its own selection control; our
" enhancements prevent the abort of the FuzzyFinder search via <Esc>.
imap <expr> <Esc>      pumvisible() && bufname('') !=# '[fuf]' ? <SID>DisableCompletionPreview('<C-e>') . <SID>UndoLongest() : '<Esc>'



"- inline completion without popup menu ---------------------------------------

" i_CTRL-N / i_CTRL-P	Inline completion without popup menu:
" 	    		Find next/previous match for words that start with the
"	    		keyword in front of the cursor, looking in places
"			specified with the 'complete' option.
"			The first match is inserted fully, key repeats will step
"			through the completion matches without showing a menu.
function! s:RecordPosition()
    " The position record consists of the current cursor position, the buffer
    " number and its current change state. When this position record is assigned
    " to a window-local variable, it is also linked to the current window and
    " tab page.
    return getpos('.') + [bufnr(''), b:changedtick]
endfunction
function! s:IsInlineComplete()
    " This function clears the stored w:IngoCompetion_InlineCompletePosition, so
    " that when an inline completion has no matches, the first <Esc> clears this
    " flag and jumps out of the completion submode, and the second <Esc> then
    " gets to exit from insert mode. Otherwise, each <Esc> would just repeat the
    " s:UndoLongest() call and never get out of insert mode until the cursor
    " moves away from that position.
    " A consecutive CTRL-N at the same position will re-set the position through
    " its autocmd, anyway.
    if exists('w:IngoCompetion_InlineCompletePosition')
	if s:RecordPosition() == w:IngoCompetion_InlineCompletePosition
	    unlet w:IngoCompetion_InlineCompletePosition
	    return 1
	endif
	unlet w:IngoCompetion_InlineCompletePosition
    endif
    return 0
endfunction
function! s:InlineComplete( completionKey )
    if &completeopt !~# 'menu'
	" The completion menu isn't enabled, anyway.
	" (Or the temporary disabling of the completion menu by this function
	" hasn't been restored yet.)
	return a:completionKey
    endif

    " Clear the 'completeopt' setting so that no popup menu appears and the
    " first match is inserted in its entirety.
    " The insertion of the match will trigger the autocmd that restores the
    " original 'completeopt' setting for future completion requests.
    " We also store the position so that we can later check whether we're
    " currently in an inline completion, as pumvisible() does when there's a
    " completion with the popup menu.
    let s:save_completeopt = &completeopt
    set completeopt=
    augroup InlineCompleteOff
	autocmd!
	autocmd BufLeave,WinLeave,InsertLeave,CursorMovedI <buffer> let &completeopt = s:save_completeopt | let w:IngoCompetion_InlineCompletePosition = s:RecordPosition() | autocmd! InlineCompleteOff
    augroup END

    if ! s:IsInlineComplete()
	" This is the start of an inline completion; set an undo point so that
	" the completion can be canceled and the original text restored, like
	" with CTRL-E in the popup menu. This needs some help from the mapping
	" for <Esc> to work.
	call s:SetUndo()
    endif
    return a:completionKey
endfunction
inoremap <expr> <SID>InlineCompleteNext <SID>InlineComplete("\<lt>C-n>")
inoremap <expr> <SID>InlineCompletePrev <SID>InlineComplete("\<lt>C-p>")

"			One can abort the completion and return to what was
"			inserted beforehand via <C-E>, or accept the currently
"			selected match and stop completion with <C-Y>.
"			It is not possible to abort via <Esc>, because that
"			would clash with stopping insertion at all; i.e. it
"			would then not be possible to exit insert mode after an
"			inline completion without typing and removing an
"			additional character.
inoremap <expr> <SID>CompletedCall ingosupertab#Completed()
"imap <expr> <C-e> pumvisible() ? <SID>DisableCompletionPreview('<C-e>') : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<C-E>'
"imap <expr> <C-y> pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<C-Y>'
" This is overloaded with "Insert from Below / Above", cp. ingomappings.vim.
imap <expr> <C-e> pumvisible() ? <SID>DisableCompletionPreview('<C-e>') : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<Plug>InsertFromBelow'
imap <expr> <C-y> pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<Plug>InsertFromAbove'



"- complete longest + preselect -----------------------------------------------

" Complete longest+preselect: On completion with multiple matches, insert the
" longest common text AND pre-select (but not yet insert) the first match.
" When 'completeopt' contains "longest", only the longest common text of the
" matches is inserted. I want to combine this with automatic selection of the
" first match so that I can both type more characters to narrow down the
" matches, or simply press <Enter> to accept the first match or press CTRL-N to
" use the next match.
" To achieve this, all completion mappings must preselect the first match in
" case of multiple matches. This is achieved by having the
" <Plug>(CompleteoptLongestSelect) mapping appended to all built-in and custom
" completion mappings.
" Once a subsequent match is chosen (via CTRL-N/P/F/B), it is already inserted.
" Changing this to select-only is impossible, because Vim ignores CTRL-N/P
" mappings when inside a completion that was started with CTRL-X (i.e. all
" completions except the generic i_CTRL-N/P completion itself). This may often
" (when no matches have a larger length than the current one) even save the
" keystroke to accept the current match, as one can simply continue to type.
if &completeopt =~# 'longest'
    " Note: :map-expr cannot be used here, it would be evaluated before the
    " preceding mapping that triggers the completion, thus pumvisible() would be
    " always false.
    " XXX: When canceling a long-running completion with CTRL-C, Vim only
    " removes the very first pending key (<C-r>) from the typeahead buffer;
    " thus, the text "=pumvisible() ? ..." will be literally inserted into the
    " buffer. Once cannot work around this by using <C-r><C-r>=...; it'll insert
    " the literal terminal code for <Up>/<Down> (something like "Xkd"). Any
    " other intermediate no-op mapping will interfere with the (potentially
    " opened) completion popup menu, too.
    inoremap <silent> <Plug>(CompleteoptLongestSelect)     <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap <silent>  <SID>(CompleteoptLongestSelectNext) <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap <silent>  <SID>(CompleteoptLongestSelectPrev) <C-r>=pumvisible() ? "\<lt>Up>" : ""<CR>
    " Integration into ingosupertab.vim.
    function! ingocompletion#Complete()
	call s:SetUndo()
	return "\<C-p>\<C-r>=pumvisible() ? \"\\<Up>\" : \"\"\<CR>"
    endfunction
    function! ingocompletion#ContinueComplete()
	return (pumvisible() ? "\<Down>\<C-p>\<C-x>\<C-p>" : "\<C-x>\<C-p>\<C-r>=pumvisible() ? \"\\<Up>\" : \"\"\<CR>")
    endfunction
    let g:IngoSuperTab_complete = function('ingocompletion#Complete')
    let g:IngoSuperTab_continueComplete = function('ingocompletion#ContinueComplete')

    " Install <Plug>(CompleteoptLongestSelect) for the built-in generic
    " completion.
    " Note: These mappings are ignored in all <C-x><C-...> popups, they are only
    " active in <C-n>/<C-p>.
    inoremap <script> <expr> <C-n> pumvisible() ? '<C-n>' : '<SID>InlineCompleteNext'
    inoremap <script> <expr> <C-p> pumvisible() ? '<C-p>' : '<SID>InlineCompletePrev'

    " Install <Plug>(CompleteoptLongestSelect) for all built-in completion types.
    inoremap <script> <C-x><C-k> <SID>(CompleteStart)<C-x><C-k><SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-t> <SID>(CompleteStart)<SID>(CompleteThesaurusPrep)<C-x><C-t><SID>(CompleteThesaurusFixSetup)<SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-]> <SID>(CompleteStart)<C-x><C-]><SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-f> <SID>(CompleteFilePathSeparatorStart)<SID>(CompleteStart)<C-x><C-f><SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-v> <SID>(CompleteStart)<C-x><C-v><SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-u> <SID>(CompleteStart)<C-x><C-u><SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-o> <SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)
    " Integrate spell suggestion completion with ingospell.vim.
    " Note: This is done here, because somehow using :imap and
    " <Plug>(CompleteoptLongestSelectNext) always inserts "Next" instead of
    " showing the completion popup menu.
    "inoremap <script> <C-x>s     <SID>(CompleteStart)<C-x>s<SID>(CompleteoptLongestSelectNext)
    "inoremap <script> <C-x><C-s> <SID>(CompleteStart)<C-x><C-s><SID>(CompleteoptLongestSelectNext)
    inoremap <silent> <expr> <SID>SpellCompletePreWrapper SpellCompletePreWrapper()
    inoremap <silent> <expr> <SID>SpellCompletePostWrapper SpellCompletePostWrapper()
    inoremap <script> <C-x>s     <SID>(CompleteStart)<SID>SpellCompletePreWrapper<C-x>s<SID>SpellCompletePostWrapper<SID>(CompleteoptLongestSelectNext)
    inoremap <script> <C-x><C-s> <SID>(CompleteStart)<SID>SpellCompletePreWrapper<C-x><C-s><SID>SpellCompletePostWrapper<SID>(CompleteoptLongestSelectNext)

    " All completion mappings that allow repetition need a special mapping: To be
    " able to repeat, the match must have been inserted via CTRL-N/P, not just
    " selected. Committing the selection via CTRL-Y completely finishes the
    " completion and prevents repetition, so that cannot be used as a
    " workaround, neither.
    inoremap <script> <expr> <C-x><C-l> pumvisible() ? '<Up><C-n><C-x><C-l>' : '<SID>(CompleteStart)<C-x><C-l><SID>(CompleteoptLongestSelectNext)'
    inoremap <script> <expr> <C-x><C-n> pumvisible() ? '<Up><C-n><C-x><C-n>' : '<SID>(CompleteStart)<C-x><C-n><SID>(CompleteoptLongestSelectNext)'
    inoremap <script> <expr> <C-x><C-p> pumvisible() ? '<Down><C-p><C-x><C-p>' : '<SID>(CompleteStart)<C-x><C-p><SID>(CompleteoptLongestSelectPrev)'
    inoremap <script> <expr> <C-x><C-i> pumvisible() ? '<Up><C-n><C-x><C-i>' : '<SID>(CompleteStart)<C-x><C-i><SID>(CompleteoptLongestSelectNext)'
    inoremap <script> <expr> <C-x><C-d> pumvisible() ? '<Up><C-n><C-x><C-d>' : '<SID>(CompleteStart)<C-x><C-d><SID>(CompleteoptLongestSelectNext)'
else
    " Custom completion types are enhanced by defining custom mappings to the
    " <Plug>...Completion mappings in 00ingoplugin.vim. This is also defined
    " when the "longest" option isn't set, so that no check is necessary there.
    inoremap <silent> <Plug>(CompleteoptLongestSelect) <Nop>
    inoremap <silent> <SID>(CompleteoptLongestSelectNext) <Nop>
    inoremap <silent> <SID>(CompleteoptLongestSelectPrev) <Nop>
endif



"- additional completion triggers ---------------------------------------------

" Shorten some commonly used insert completions.
" i_CTRL-F		File name completion |i_CTRL-X_CTRL-F|
" Note: The CTRL-F mapping is included in the popupmenu overload above.
"imap <C-f> <C-x><C-f>


" vimtip #1228, vimtip #1386: Completion popup selection like other IDEs.
" i_CTRL-Space		IDE-like generic completion (via the last-used omni
"			completion ('omnifunc'). Also cycles through matches
"			when the completion popup is visible.
"inoremap <expr> <C-Space>  pumvisible() ? "<C-N>" : "<C-N><C-R>=pumvisible() ? \"\\<lt>Down>\" : \"\"<CR>"
if has('gui_running') || has('win32') || has('win64')
    inoremap <script> <expr> <C-Space> pumvisible() ? '<C-n>' : '<SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)'
else
    " On the Linux console, <C-Space> does not work, but <nul> does.
    inoremap <script> <expr> <nul> pumvisible() ? '<C-n>' : '<SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)'
endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
