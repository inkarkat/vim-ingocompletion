" ingocompletion.vim: Customization of completions. 
"
" DEPENDENCIES:
"   - Uses functions defined in ingospell.vim for |i_CTRL-X_CTRL-S|
"     modifications. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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

"- popup menu mappings and behavior -------------------------------------------

" <Enter>		Accept the currently selected match and stop completion.
"			Alias for |i_CTRL-Y|. 
"			Another <Tab> will continue completion with the next
"			word instead of restarting the completion; if you don't
"			want this, use |i_CTRL-Y| instead. 
inoremap <expr> <CR> pumvisible() ? '<C-y><C-\><C-o>:call ingosupertab#Completed()<CR>' : '<CR>'

"			Quick access accelerators for the popup menu: 
" 1-6			In the popup menu: Accept the first, second, ... visible
"			offered match and stop completion. 
" 0, 9-7		In the popup menu: Accept the last, second-from-last,
"			... visible offered match and stop completion. 
"			These assume a freshly opened popup menu where no
"			selection (via <Up>/<Down>/...) has yet been made. 
"			In a backward completion (first candidate at bottom),
"			the counting starts from the bottom, too; i.e. 0 is the
"			candidate displayed at the top of the completion popup. 
inoremap <expr> 1 pumvisible() ? '<C-y>' : '1'
inoremap <expr> 2 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><C-y>'                 : '<Down><C-y>'                         : '2'
inoremap <expr> 3 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><C-y>'             : '<Down><Down><C-y>'                   : '3'
inoremap <expr> 4 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up><C-y>'         : '<Down><Down><Down><C-y>'             : '4'
inoremap <expr> 5 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up><Up><C-y>'     : '<Down><Down><Down><Down><C-y>'       : '5'
inoremap <expr> 6 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<Up><Up><Up><Up><Up><C-y>' : '<Down><Down><Down><Down><Down><C-y>' : '6'
inoremap <expr> 0 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Up><C-Y>'         : '<PageDown><Down><C-y>'               : '0'
inoremap <expr> 9 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><C-Y>'             : '<PageDown><C-y>'                     : '9'
inoremap <expr> 8 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down><C-y>'       : '<PageDown><Up><C-y>'                 : '8'
inoremap <expr> 7 pumvisible() ? ingosupertab#IsBackwardsCompletion() ? '<PageUp><Down><Down><C-y>' : '<PageDown><Up><Up><C-y>'             : '7'

" Aliases for |popupmenu-keys|:
" CTRL-F		Use a match several entries further. This doesn't work
"			in filename completion, where CTRL-F goes to the next
"			matching filename. 
" CTRL-B		Use a match several entries back. 
inoremap <script> <expr> <C-f> pumvisible() ? '<PageDown><Up><C-n>' : '<SID>CompleteoptLongestSetUndo<C-x><C-f>'
inoremap <expr> <C-b> pumvisible() ? '<PageUp><Down><C-p>' : ''

" <Esc>			Abort completion, go back to what was typed. 
"			In contrast to |i_CTRL-E|, this also erases the longest
"			common string. 
" Note: To implement the total abort of completion, all mappings that start a
" completion must prepend <Plug>CompleteoptLongestSetUndo. 

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
    " that does not prepend <Plug>CompleteoptLongestSetUndo (e.g. because it's
    " not under my control) doesn't wreak havoc to the buffer. (This happened
    " when aborting a fuf.vim search.) 
    let w:IngoCompetion_UndoPoint = s:RecordUndoPoint('.')

    call setpos("'" . s:IngoCompletion_UndoMark, getpos('.'))
    return ''
endfunction
" Note: By using a :map-expr that doesn't return anything and setting the
" mark via setpos() instead of the 'm' command, subsequent CTRL-X CTRL-N
" commands can be used to continue the completion with following words. Any
" inserted key (even CTRL-R=...<CR>) would break this. 
inoremap <expr> <Plug>CompleteoptLongestSetUndo <SID>SetUndo()
inoremap <expr> <SID>CompleteoptLongestSetUndo <SID>SetUndo()
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
inoremap <script> <expr> <Esc>      pumvisible() ? '<C-e>' . <SID>UndoLongest() : '<Esc>'



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
"imap <expr> <C-E> pumvisible() ? '<C-E>' : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<C-E>'
"imap <expr> <C-Y> pumvisible() ? '<C-Y>' : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<C-Y>'
" This is overloaded with "Insert from Below / Above", cp. ingomappings.vim. 
imap <expr> <C-E> pumvisible() ? '<C-E>' : <SID>IsInlineComplete() ? <SID>UndoLongest()        : '<Plug>InsertFromBelow'
imap <expr> <C-Y> pumvisible() ? '<C-Y>' : <SID>IsInlineComplete() ? ' <BS><SID>CompletedCall' : '<Plug>InsertFromAbove'



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
" <Plug>CompleteoptLongestSelect mapping appended to all built-in and custom
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
    inoremap <Plug>CompleteoptLongestSelect     <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectNext <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectPrev <C-r>=pumvisible() ? "\<lt>Up>" : ""<CR>
    " Integration into ingosupertab.vim. 
    function! s:Complete()
	call s:SetUndo()
	return "\<C-p>\<C-r>=pumvisible() ? \"\\<Up>\" : \"\"\<CR>"
    endfunction
    function! s:ContinueComplete()
	return (pumvisible() ? "\<Down>\<C-p>\<C-x>\<C-p>" : "\<C-x>\<C-p>\<C-r>=pumvisible() ? \"\\<Up>\" : \"\"\<CR>")
    endfunction
    function! s:function(name)
	return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
    endfunction
    let g:IngoSuperTab_complete = s:function('s:Complete')
    let g:IngoSuperTab_continueComplete = s:function('s:ContinueComplete')
    delfunction s:function

    " Install <Plug>CompleteoptLongestSelect for the built-in generic
    " completion. 
    " Note: These mappings are ignored in all <C-x><C-...> popups, they are only
    " active in <C-n>/<C-p>. 
    inoremap <script> <expr> <C-n> pumvisible() ? '<C-n>' : '<SID>InlineCompleteNext'
    inoremap <script> <expr> <C-p> pumvisible() ? '<C-p>' : '<SID>InlineCompletePrev'

    " Install <Plug>CompleteoptLongestSelect for all built-in completion types.
    inoremap <script> <C-x><C-k> <SID>CompleteoptLongestSetUndo<C-x><C-k><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-t> <SID>CompleteoptLongestSetUndo<C-x><C-t><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-]> <SID>CompleteoptLongestSetUndo<C-x><C-]><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-f> <SID>CompleteoptLongestSetUndo<C-x><C-f><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-v> <SID>CompleteoptLongestSetUndo<C-x><C-v><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-u> <SID>CompleteoptLongestSetUndo<C-x><C-u><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-o> <SID>CompleteoptLongestSetUndo<C-x><C-o><SID>CompleteoptLongestSelectNext
    " Integrate spell suggestion completion with ingospell.vim. 
    " Note: This is done here, because somehow using :imap and
    " <Plug>CompleteoptLongestSelectNext always inserts "Next" instead of
    " showing the completion popup menu. 
    "inoremap <script> <C-x>s     <SID>CompleteoptLongestSetUndo<C-x>s<SID>CompleteoptLongestSelectNext
    "inoremap <script> <C-x><C-s> <SID>CompleteoptLongestSetUndo<C-x><C-s><SID>CompleteoptLongestSelectNext
    inoremap <silent> <expr> <SID>SpellCompletePreWrapper SpellCompletePreWrapper()
    inoremap <silent> <expr> <SID>SpellCompletePostWrapper SpellCompletePostWrapper()
    inoremap <script> <C-x>s     <SID>CompleteoptLongestSetUndo<SID>SpellCompletePreWrapper<C-x>s<SID>SpellCompletePostWrapper<SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-s> <SID>CompleteoptLongestSetUndo<SID>SpellCompletePreWrapper<C-x><C-s><SID>SpellCompletePostWrapper<SID>CompleteoptLongestSelectNext

    " All completion mappings that allow repetition need a special mapping: To be
    " able to repeat, the match must have been inserted via CTRL-N/P, not just
    " selected. Committing the selection via CTRL-Y completely finishes the
    " completion and prevents repetition, so that cannot be used as a
    " workaround, neither. 
    inoremap <script> <expr> <C-x><C-l> pumvisible() ? '<Up><C-n><C-x><C-l>' : '<SID>CompleteoptLongestSetUndo<C-x><C-l><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-n> pumvisible() ? '<Up><C-n><C-x><C-n>' : '<SID>CompleteoptLongestSetUndo<C-x><C-n><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-p> pumvisible() ? '<Down><C-p><C-x><C-p>' : '<SID>CompleteoptLongestSetUndo<C-x><C-p><SID>CompleteoptLongestSelectPrev'
    inoremap <script> <expr> <C-x><C-i> pumvisible() ? '<Up><C-n><C-x><C-i>' : '<SID>CompleteoptLongestSetUndo<C-x><C-i><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-d> pumvisible() ? '<Up><C-n><C-x><C-d>' : '<SID>CompleteoptLongestSetUndo<C-x><C-d><SID>CompleteoptLongestSelectNext'
else
    " Custom completion types are enhanced by defining custom mappings to the
    " <Plug>...Completion mappings in 00ingoplugin.vim. This is also defined
    " when the "longest" option isn't set, so that no check is necessary there. 
    inoremap <Plug>CompleteoptLongestSelect <Nop>
    inoremap <SID>CompleteoptLongestSelectNext <Nop>
    inoremap <SID>CompleteoptLongestSelectPrev <Nop>
endif



"- additional completion triggers ---------------------------------------------

" Shorten some commonly used insert completions. 
" CTRL-]		Tag completion |i_CTRL-X_CTRL-]|
" CTRL-F		File name completion |i_CTRL-X_CTRL-F|
"
imap <C-]> <C-x><C-]>
" The CTRL-F mapping is included in the popupmenu overload above. 
"imap <C-f> <C-x><C-f>


" vimtip #1228, vimtip #1386: Completion popup selection like other IDEs. 
" i_CTRL-Space		IDE-like generic completion (via the last-used user
"			completion ('completefunc'). Also cycles through matches
"			when the completion popup is visible. 
"inoremap <expr> <C-Space>  pumvisible() ? "<C-N>" : "<C-N><C-R>=pumvisible() ? \"\\<lt>Down>\" : \"\"<CR>"
if has('gui_running') || has('win32') || has('win64') 
    inoremap <script> <expr> <C-Space> pumvisible() ? '<C-n>' : '<SID>CompleteoptLongestSetUndo<C-x><C-u><SID>CompleteoptLongestSelectNext'
else
    " On the Linux console, <C-Space> does not work, but <nul> does. 
    inoremap <script> <expr> <nul> pumvisible() ? '<C-n>' : '<SID>CompleteoptLongestSetUndo<C-x><C-u><SID>CompleteoptLongestSelectNext'
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
