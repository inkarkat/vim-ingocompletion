" ingocompletion.vim: Customization of completions. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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

" vimtip #1228, vimtip #1386: Completion popup selection like other IDEs. 
" i_CTRL-Space		IDE-like generic completion (via 'complete'). 
" i_CTRL-Enter		Shortcut that inserts the first match without selecting
"			it first with <C-N>. 
" The IDE completion keeps a menu item always highlighted. This way you can keep
" typing characters to narrow the matches, and the nearest match will be
" selected so that you can hit <Enter> at any time to insert it. 
" <C-N> and <C-P> are still available as (non-selecting) alternatives, too. 
"inoremap <expr> <C-Space>  pumvisible() ? "<C-N>" : "<C-N><C-R>=pumvisible() ? \"\\<lt>Down>\" : \"\"<CR>" 
"inoremap <expr> <C-CR>     pumvisible() ? "<C-N><C-Y>" : "<C-CR>"


" Add overloads to allow end of completion with <Esc> in additon to CTRL-E and
" to accept the currently selected match with <CR> in addition to CTRL-Y. 
inoremap <expr> <Esc>      pumvisible() ? '<C-e>' : '<Esc>'
inoremap <expr> <CR>       pumvisible() ? '<C-y>' : '<CR>'

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
    inoremap <Plug>CompleteoptLongestSelect     <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectNext <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectPrev <C-r>=pumvisible() ? "\<lt>Up>" : ""<CR>
    " Integration into ingosupertab.vim. 
    let g:IngoSuperTab_complete = "\<C-p>\<C-r>=pumvisible() ? \"\\<Up>\" : \"\"\<CR>"

    " Install <Plug>CompleteoptLongestSelect for the built-in generic
    " completion. 
    " Note: These mappings are ignored in all <C-x><C-...> popups, they are only
    " active in <C-n>/<C-p>. 
    inoremap <script> <expr> <C-n> pumvisible() ? '<C-n>' : '<C-n><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-p> pumvisible() ? '<C-p>' : '<C-p><SID>CompleteoptLongestSelectPrev'

    " Install <Plug>CompleteoptLongestSelect for all built-in completion types.
    inoremap <script> <C-x><C-k> <C-x><C-k><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-t> <C-x><C-t><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-]> <C-x><C-]><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-f> <C-x><C-f><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-v> <C-x><C-v><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-u> <C-x><C-u><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x><C-o> <C-x><C-o><SID>CompleteoptLongestSelectNext
    inoremap <script> <C-x>s     <C-x>s<SID>CompleteoptLongestSelectNext

    " All completion mappings that allow repetition need a special mapping: To be
    " able to repeat, the match must have been inserted via CTRL-N/P, not just
    " selected. Committing the selection via CTRL-Y completely finishes the
    " completion and prevents repetition, so that cannot be used as a
    " workaround, neither. 
    inoremap <script> <expr> <C-x><C-l> pumvisible() ? '<Up><C-n><C-x><C-l>' : '<C-x><C-l><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-n> pumvisible() ? '<Up><C-n><C-x><C-n>' : '<C-x><C-n><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-p> pumvisible() ? '<Down><C-p><C-x><C-p>' : '<C-x><C-p><SID>CompleteoptLongestSelectPrev'
    inoremap <script> <expr> <C-x><C-i> pumvisible() ? '<Up><C-n><C-x><C-i>' : '<C-x><C-i><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-x><C-d> pumvisible() ? '<Up><C-n><C-x><C-d>' : '<C-x><C-d><SID>CompleteoptLongestSelectNext'
else
    " Custom completion types are enhanced by defining custom mappings to the
    " <Plug>...Completion mappings in 00ingoplugin.vim. This is also defined
    " when the "longest" option isn't set, so that no check is necessary there. 
    inoremap <Plug>CompleteoptLongestSelect <Nop>
endif

" Shorten some commonly used insert completions. 
" CTRL-]		Tag completion |i_CTRL-X_CTRL-]|
" CTRL-F		File name completion |i_CTRL-X_CTRL-F|
"
" Aliases for |popupmenu-keys|:
" CTRL-F		Use a match several entries further. This doesn't work
"			in filename completion, where CTRL-F goes to the next
"			matching filename. 
" CTRL-B		Use a match several entries back. 
imap <C-]> <C-x><C-]>
inoremap <expr> <C-f> pumvisible() ? '<PageDown><Up><C-n>' : '<C-x><C-f>'
inoremap <expr> <C-b> pumvisible() ? '<PageUp><Down><C-p>' : ''

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
