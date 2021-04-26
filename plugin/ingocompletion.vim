" ingocompletion.vim: Customization of completions.
"
" DEPENDENCIES:
"   - BuiltInCompletes.vim plugin
"   - CompleteHelper.vim plugin
"   - ingo-library.vim plugin
"   - ingosupertab.vim plugin
"   - InsertAllCompletions.vim plugin
"   - Uses functions defined in ingospell.vim for |i_CTRL-X_CTRL-S|
"     modifications.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_ingocompletion') || (v:version < 700)
    finish
endif
let g:loaded_ingocompletion = 1
let s:save_cpo = &cpo
set cpo&vim

" Note: The CursorMovedI event is not fired during completion with the popup
" menu.
let s:CompleteEntirelyDone = 'BufLeave,WinLeave,InsertLeave,CursorMovedI'
if v:version == 703 && has('patch813') || v:version > 703
    let s:CompleteDone = 'CompleteDone'
else
    let s:CompleteDone = s:CompleteEntirelyDone
endif


"- Integration with InsertAllCompletions.vim -----------------------------------

inoremap <expr> <SID>(BuiltInLocalCompleteNext) InsertAllCompletions#CompleteFunc#Set('BuiltInCompletes#LocalCompleteNext', 0)
inoremap <expr> <SID>(BuiltInLocalCompletePrev) InsertAllCompletions#CompleteFunc#Set('BuiltInCompletes#LocalCompletePrev', 1)
inoremap <expr> <SID>(BuiltInTagComplete) InsertAllCompletions#CompleteFunc#Set('BuiltInCompletes#TagComplete')
inoremap <expr> <SID>(BuiltInOmniComplete) InsertAllCompletions#CompleteFunc#Set(&omnifunc)



"- customization of completion behavior ----------------------------------------

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
		" Note: Cannot use s:CompleteDone here, because on repeat of
		" file complete, this function is triggered first, and then Vim
		" fires the CompleteDone event (as the previous completion is
		" completed by the retriggered completion), which would undo the
		" temp option value too early!
		execute printf('autocmd! %s * let &shellslash=%d | autocmd! CompleteFilePathSeparator', s:CompleteEntirelyDone, &shellslash)
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

" Fix the multi-line completion problem.
" Currently, completion matches are inserted literally, with newlines
" represented by ^@. Vim should expand this into proper newlines. We work around
" this via an autocmd that fires once after completion, and by hooking into the
" <CR> key. (<C-Y> apparently works even without this.)
" (FIXME: It seems to be fired once after the initial completion trigger with
" empty 'completeopt'.)
" Usage: All CTRL-X_... completion mappings that may return multi-line matches
" must append <Plug>(CompleteMultilineFixSetup) to get this fix.
function! s:HasAutoWrap()
    return (&l:textwidth > 0 || &l:wrapmargin > 0) && &l:formatoptions =~# '[act]'
endfunction
function! s:CompleteMultilineFix()
    let l:textBeforeCursor = strpart(getline('.'), 0, col('.') - 1)
    let l:lastNewlineCol = strridx(l:textBeforeCursor, "\n")
    if l:lastNewlineCol == -1
	let l:previousLnum = line('.') - 1
	if s:HasAutoWrap() && getline(l:previousLnum) =~# '\n'
	    " Auto-wrap has already introduced a linebreak if the insertion of
	    " the (multi-line) completion exceeded 'textwidth'. Remove the ^@
	    " and any following comment prefix plus indent.
	    let [l:before, l:after] = matchlist(getline(l:previousLnum), '^\(.*\)\n\(.*\)$')[1:2]
	    let [l:indent, l:afterIndent] = ingo#comments#SplitIndentAndText(l:after)
	    call setline(l:previousLnum, l:before . ' ' . l:afterIndent)

	    " Reformat the current and previous lines. Ensure that the relative cursor
	    " position does not change.
	    call ingo#cursor#keep#WhileExecuteOrFunc(l:previousLnum, line('.'), l:previousLnum . 'normal! gqj')

	    " Integration into CompleteHelper.vim.
	    call CompleteHelper#Repeat#SetRecord()
	else
	    " Nothing to do.
	endif
	return ''
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
	execute 'autocmd!' s:CompleteDone '* call <SID>CompleteMultilineFix() | autocmd! CompleteMultilineFix'
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
	autocmd BufLeave,WinLeave * call <SID>CompleteThesaurusFix() | autocmd! CompleteThesaurusFix
    augroup END

    return ''
endfunction
inoremap <expr> <SID>(CompleteThesaurusFixSetup) <SID>CompleteThesaurusFixSetup()



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
inoremap <silent> <expr>  <SID>PumCR <SID>DisableCompletionPreview('<C-y>').'<C-r>=ingosupertab#Completed()<CR><C-r>=<SID>CompleteMultilineFix()<CR><C-r>=<SID>CompleteStopInsert()<CR>'
inoremap <silent> <expr> <Plug>PumCR <SID>DisableCompletionPreview('<C-y>').'<C-r>=ingosupertab#Completed()<CR><C-r>=<SID>CompleteMultilineFix()<CR><C-r>=<SID>CompleteStopInsert()<CR>'
" Note: Cannot use :inoremap here; abbreviations wouldn't be expanded any
" longer.
imap <silent> <expr> <CR> pumvisible() ? '<SID>PumCR' : '<CR>'



inoremap <expr> 1 pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : '1'
inoremap <expr> 2 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up>'.<SID>DisableCompletionPreview('<C-y>')                 : '<Down>'.<SID>DisableCompletionPreview('<C-y>')                         : '2'
imap <expr><S-CR> pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up>'.<SID>DisableCompletionPreview('<C-y>')                 : '<Down>'.<SID>DisableCompletionPreview('<C-y>')                         : '<Plug>(GotoNextLineAtSameColumn)'
inoremap <expr> 3 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up>'.<SID>DisableCompletionPreview('<C-y>')             : '<Down><Down>'.<SID>DisableCompletionPreview('<C-y>')                   : '3'
inoremap <expr> 4 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')         : '<Down><Down><Down>'.<SID>DisableCompletionPreview('<C-y>')             : '4'
inoremap <expr> 5 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')     : '<Down><Down><Down><Down>'.<SID>DisableCompletionPreview('<C-y>')       : '5'
inoremap <expr> 9 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Up>'.<SID>DisableCompletionPreview('<C-y>')         : '<PageDown><Down>'.<SID>DisableCompletionPreview('<C-y>')               : '9'
inoremap <expr> 8 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp>'.<SID>DisableCompletionPreview('<C-y>')             : '<PageDown>'.<SID>DisableCompletionPreview('<C-y>')                     : '8'
inoremap <expr> 7 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down>'.<SID>DisableCompletionPreview('<C-y>')       : '<PageDown><Up>'.<SID>DisableCompletionPreview('<C-y>')                 : '7'
inoremap <expr> 6 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down><Down>'.<SID>DisableCompletionPreview('<C-y>') : '<PageDown><Up><Up>'.<SID>DisableCompletionPreview('<C-y>')             : '6'


inoremap <script> <expr> <C-f> pumvisible() ? '<PageDown><Up><C-n>' : '<SID>(CompleteFilePathSeparatorStart)<SID>(CompleteStart)<C-x><C-f><SID>(CompleteoptLongestSelectNext)'
inoremap <expr> <C-b> pumvisible() ? '<PageUp><Down><C-p>' : ''



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

function! s:IsInlineComplete()
    " This function clears the stored w:IngoCompletion_InlineCompletePosition, so
    " that when an inline completion has no matches, the first <Esc> clears this
    " flag and jumps out of the completion submode, and the second <Esc> then
    " gets to exit from insert mode. Otherwise, each <Esc> would just repeat the
    " s:UndoLongest() call and never get out of insert mode until the cursor
    " moves away from that position.
    " A consecutive CTRL-N at the same position will re-set the position through
    " its autocmd, anyway.
    if exists('w:IngoCompletion_InlineCompletePosition')
	if ingo#record#Position(1) == w:IngoCompletion_InlineCompletePosition
	    unlet w:IngoCompletion_InlineCompletePosition
	    return 1
	endif
	unlet w:IngoCompletion_InlineCompletePosition
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
	" Note: Cannot use CompleteDone here; during inline completion, that is
	" fired only after additional, non-match characters have been typed /
	" the completion sub-mode has been left. We really need the CursorMovedI
	" here.
	execute 'autocmd!' s:CompleteEntirelyDone '<buffer> let &completeopt = s:save_completeopt | let w:IngoCompletion_InlineCompletePosition = ingo#record#Position(1) | autocmd! InlineCompleteOff'
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

inoremap <expr> <SID>CompletedCall ingosupertab#Completed()
"imap <expr> <C-e> pumvisible() ? <SID>DisableCompletionPreview('<C-e>') : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<C-E>'
"imap <expr> <C-y> pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<C-Y>'
" This is overloaded with "Insert from Below / Above", cp. InsertFromAround.vim
imap <expr> <C-e> pumvisible() ? <SID>DisableCompletionPreview('<C-e>') : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<Plug>(InsertFromTextBelow)'
imap <expr> <C-y> pumvisible() ? <SID>DisableCompletionPreview('<C-y>') : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<Plug>(InsertFromTextAbove)'



"- complete longest + preselect -----------------------------------------------

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
else
    " Custom completion types are enhanced by defining custom mappings to the
    " <Plug>...Completion mappings in 00ingoplugin.vim. This is also defined
    " when the "longest" option isn't set, so that no check is necessary there.
    inoremap <silent> <Plug>(CompleteoptLongestSelect) <Nop>
    inoremap <silent> <SID>(CompleteoptLongestSelectNext) <Nop>
    inoremap <silent> <SID>(CompleteoptLongestSelectPrev) <Nop>
endif

" Integration into ingosupertab.vim.
function! ingocompletion#IngoSuperTabCompleteFunc()
    return (ingosupertab#IsBackwardsCompletion() ? 'BuiltInCompletes#CompletePrev' : 'BuiltInCompletes#CompleteNext')
endfunction
function! ingocompletion#Complete()
    call s:SetUndo()
    return "\<C-p>\<C-r>=empty(InsertAllCompletions#CompleteFunc#Set(" . string(ingocompletion#IngoSuperTabCompleteFunc()) . ',' . ingosupertab#IsBackwardsCompletion() . ")) && pumvisible() ? \"\\<Up>\" : \"\"\<CR>"
endfunction
function! ingocompletion#ContinueComplete()
    return (pumvisible() ? "\<Down>\<C-p>\<C-x>\<C-p>" : "\<C-x>\<C-p>\<C-r>=empty(InsertAllCompletions#CompleteFunc#Set(" . string(ingocompletion#IngoSuperTabCompleteFunc()) . ',' . ingosupertab#IsBackwardsCompletion() . ")) && pumvisible() ? \"\\<Up>\" : \"\"\<CR>")
endfunction
unlet! g:IngoSuperTab_complete g:IngoSuperTab_continueComplete
let g:IngoSuperTab_complete = function('ingocompletion#Complete')
let g:IngoSuperTab_continueComplete = function('ingocompletion#ContinueComplete')

" Install <Plug>(CompleteoptLongestSelect) for the built-in generic completion.
" Note: These mappings are ignored in all <C-x><C-...> popups, they are only
" active in <C-n>/<C-p>.
inoremap <script> <expr> <C-n> pumvisible() ? '<C-n>' : '<SID>InlineCompleteNext'
inoremap <script> <expr> <C-p> pumvisible() ? '<C-p>' : '<SID>InlineCompletePrev'

" Install <Plug>(CompleteoptLongestSelect) for all built-in completion types.
inoremap <script> <C-x><C-k> <SID>(CompleteStart)<C-x><C-k><SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-t> <SID>(CompleteStart)<SID>(CompleteThesaurusPrep)<C-x><C-t><SID>(CompleteThesaurusFixSetup)<SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-]> <SID>(CompleteStart)<C-x><C-]><SID>(CompleteoptLongestSelectNext)<SID>(BuiltInTagComplete)
inoremap <script> <C-x><C-f> <SID>(CompleteFilePathSeparatorStart)<SID>(CompleteStart)<C-x><C-f><SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-v> <SID>(CompleteStart)<C-x><C-v><SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-u> <SID>(CompleteStart)<C-x><C-u><SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-o> <SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)
" Integrate spell suggestion completion with ingospell.vim.
" Note: This is done here, because somehow using :imap and
" <Plug>(CompleteoptLongestSelectNext) always inserts "Next" instead of showing
" the completion popup menu.
"inoremap <script> <C-x>s     <SID>(CompleteStart)<C-x>s<SID>(CompleteoptLongestSelectNext)
"inoremap <script> <C-x><C-s> <SID>(CompleteStart)<C-x><C-s><SID>(CompleteoptLongestSelectNext)
inoremap <silent> <expr> <SID>SpellCompletePreWrapper SpellCompletePreWrapper()
inoremap <silent> <expr> <SID>SpellCompletePostWrapper SpellCompletePostWrapper()
inoremap <script> <C-x>s     <SID>(CompleteStart)<SID>SpellCompletePreWrapper<C-x>s<SID>SpellCompletePostWrapper<SID>(CompleteoptLongestSelectNext)
inoremap <script> <C-x><C-s> <SID>(CompleteStart)<SID>SpellCompletePreWrapper<C-x><C-s><SID>SpellCompletePostWrapper<SID>(CompleteoptLongestSelectNext)

" All completion mappings that allow repetition need a special mapping: To be
" able to repeat, the match must have been inserted via CTRL-N/P, not just
" selected. Committing the selection via CTRL-Y completely finishes the
" completion and prevents repetition, so that cannot be used as a workaround,
" neither.
inoremap <script> <expr> <C-x><C-l> pumvisible() ? '<Up><C-n><C-x><C-l>' : '<SID>(CompleteStart)<C-x><C-l><SID>(CompleteoptLongestSelectNext)'
inoremap <script> <expr> <C-x><C-n> pumvisible() ? '<Up><C-n><C-x><C-n>' : '<SID>(CompleteStart)<C-x><C-n><SID>(CompleteoptLongestSelectNext)<SID>(BuiltInLocalCompleteNext)'
inoremap <script> <expr> <C-x><C-p> pumvisible() ? '<Down><C-p><C-x><C-p>' : '<SID>(CompleteStart)<C-x><C-p><SID>(CompleteoptLongestSelectPrev)<SID>(BuiltInLocalCompletePrev)'
inoremap <script> <expr> <C-x><C-i> pumvisible() ? '<Up><C-n><C-x><C-i>' : '<SID>(CompleteStart)<C-x><C-i><SID>(CompleteoptLongestSelectNext)'
inoremap <script> <expr> <C-x><C-d> pumvisible() ? '<Up><C-n><C-x><C-d>' : '<SID>(CompleteStart)<C-x><C-d><SID>(CompleteoptLongestSelectNext)'



"- Additional completion triggers ---------------------------------------------

" Note: The CTRL-F mapping is included in the popupmenu overload above.
"imap <C-f> <C-x><C-f>


"inoremap <expr> <C-Space>  pumvisible() ? "<C-N>" : "<C-N><C-R>=pumvisible() ? \"\\<lt>Down>\" : \"\"<CR>"
if has('gui_running') || ingo#os#IsWinOrDos()
    inoremap <script> <expr> <C-Space> pumvisible() ? '<C-n>' : '<SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)<SID>(BuiltInOmniComplete)'
else
    " On the Linux console, <C-Space> does not work, but <nul> does.
    inoremap <script> <expr> <nul> pumvisible() ? '<C-n>' : '<SID>(CompleteStart)<C-x><C-o><SID>(CompleteoptLongestSelectNext)<SID>(BuiltInOmniComplete)'
endif



function! s:ChooseOptionFile( optionName, count )
    execute 'let l:optionValue = &' . a:optionName
    let l:allOptions = ingo#option#Split(l:optionValue)
    if a:count > len(l:allOptions)
	call ingo#msg#ErrorMsg(printf("Only %d '%s' value%s", len(l:allOptions), a:optionName, (len(l:allOptions) == 1 ? '' : 's')))
	return ''
    endif

    augroup TemporarySingleOptionValue
	execute printf('autocmd! %s * let &%s = %s | autocmd! TemporarySingleOptionValue', s:CompleteDone, a:optionName, string(l:optionValue))
    augroup END

    execute 'let &' . a:optionName '= l:allOptions[a:count - 1]'

    return ''
endfunction
" Note: Use :imap to include any embellishments (e.g. complete longest +
" preselect) of the completion trigger.
inoremap <expr> <SID>(ChooseDictionaryFile1) <SID>ChooseOptionFile('dictionary', 1)
inoremap <expr> <SID>(ChooseDictionaryFile2) <SID>ChooseOptionFile('dictionary', 2)
inoremap <expr> <SID>(ChooseDictionaryFile3) <SID>ChooseOptionFile('dictionary', 3)
inoremap <expr> <SID>(ChooseDictionaryFile4) <SID>ChooseOptionFile('dictionary', 4)
inoremap <expr> <SID>(ChooseDictionaryFile5) <SID>ChooseOptionFile('dictionary', 5)
inoremap <expr> <SID>(ChooseDictionaryFile6) <SID>ChooseOptionFile('dictionary', 6)
inoremap <expr> <SID>(ChooseDictionaryFile7) <SID>ChooseOptionFile('dictionary', 7)
inoremap <expr> <SID>(ChooseDictionaryFile8) <SID>ChooseOptionFile('dictionary', 8)
inoremap <expr> <SID>(ChooseDictionaryFile9) <SID>ChooseOptionFile('dictionary', 9)
imap <C-x>1<C-d> <SID>(ChooseDictionaryFile1)<C-x><C-t>
imap <C-x>2<C-d> <SID>(ChooseDictionaryFile2)<C-x><C-t>
imap <C-x>3<C-d> <SID>(ChooseDictionaryFile3)<C-x><C-t>
imap <C-x>4<C-d> <SID>(ChooseDictionaryFile4)<C-x><C-t>
imap <C-x>5<C-d> <SID>(ChooseDictionaryFile5)<C-x><C-t>
imap <C-x>6<C-d> <SID>(ChooseDictionaryFile6)<C-x><C-t>
imap <C-x>7<C-d> <SID>(ChooseDictionaryFile7)<C-x><C-t>
imap <C-x>8<C-d> <SID>(ChooseDictionaryFile8)<C-x><C-t>
imap <C-x>9<C-d> <SID>(ChooseDictionaryFile9)<C-x><C-t>
inoremap <expr> <SID>(ChooseThesaurusFile1) <SID>ChooseOptionFile('thesaurus', 1)
inoremap <expr> <SID>(ChooseThesaurusFile2) <SID>ChooseOptionFile('thesaurus', 2)
inoremap <expr> <SID>(ChooseThesaurusFile3) <SID>ChooseOptionFile('thesaurus', 3)
inoremap <expr> <SID>(ChooseThesaurusFile4) <SID>ChooseOptionFile('thesaurus', 4)
inoremap <expr> <SID>(ChooseThesaurusFile5) <SID>ChooseOptionFile('thesaurus', 5)
inoremap <expr> <SID>(ChooseThesaurusFile6) <SID>ChooseOptionFile('thesaurus', 6)
inoremap <expr> <SID>(ChooseThesaurusFile7) <SID>ChooseOptionFile('thesaurus', 7)
inoremap <expr> <SID>(ChooseThesaurusFile8) <SID>ChooseOptionFile('thesaurus', 8)
inoremap <expr> <SID>(ChooseThesaurusFile9) <SID>ChooseOptionFile('thesaurus', 9)
imap <C-x>1<C-t> <SID>(ChooseThesaurusFile1)<C-x><C-t>
imap <C-x>2<C-t> <SID>(ChooseThesaurusFile2)<C-x><C-t>
imap <C-x>3<C-t> <SID>(ChooseThesaurusFile3)<C-x><C-t>
imap <C-x>4<C-t> <SID>(ChooseThesaurusFile4)<C-x><C-t>
imap <C-x>5<C-t> <SID>(ChooseThesaurusFile5)<C-x><C-t>
imap <C-x>6<C-t> <SID>(ChooseThesaurusFile6)<C-x><C-t>
imap <C-x>7<C-t> <SID>(ChooseThesaurusFile7)<C-x><C-t>
imap <C-x>8<C-t> <SID>(ChooseThesaurusFile8)<C-x><C-t>
imap <C-x>9<C-t> <SID>(ChooseThesaurusFile9)<C-x><C-t>

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
