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
" Note: With the complete longest+pre-select, the <Esc> mapping isn't actually
" necessary. But I keep it e.g. due to the Vim ignorance mentioned below. 
inoremap <expr> <Esc>      pumvisible() ? '<C-e>' : '<Esc>'
inoremap <expr> <CR>       pumvisible() ? '<C-y>' : '<CR>'

" Complete longest+preselect: On completion with multiple matches, insert the
" longest common text AND pre-select (but not yet insert) the first match. 
" When 'completeopt' contains "longest", only the longest common text of the
" matches is inserted. I want to combine this with automatic selection of the
" first match so that I can both type more characters to narrow down the
" matches, or simply press <Enter> to accept the first match or press CTRL-N to
" go to the next match.
" To achieve this, CTRL-N/P must be remapped to <Down>/<Up> (which only select,
" but not yet insert) when the popup menu is visible, and all completion
" mappings must preselect the first match in case of multiple matches. This is
" achieved by having the <Plug>CompleteoptLongestSelect mapping appended to all
" built-in and custom completion mappings.
if &completeopt =~# 'longest'
    " Note: :map-expr cannot be used here, it would be evaluated before the
    " preceding mapping that triggers the completion, thus pumvisible() would be
    " always false. 
    inoremap <Plug>CompleteoptLongestSelect     <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectNext <C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>
    inoremap  <SID>CompleteoptLongestSelectPrev <C-r>=pumvisible() ? "\<lt>Up>" : ""<CR>

    " CTRL-N/P only select, not insert the match. 
    " Note: These mappings are ignored in all <C-x><C-...> popups, they are only
    " active in <C-n>/<C-p>. 
    inoremap <script> <expr> <C-n> pumvisible() ? '<Down>' : '<C-n><SID>CompleteoptLongestSelectNext'
    inoremap <script> <expr> <C-p> pumvisible() ? '<Up>' : '<C-p><SID>CompleteoptLongestSelectPrev'

    " Install <Plug>CompleteoptLongestSelect for all built-in completion types.
    imap <C-x><C-k> <C-x><C-k><Plug>CompleteoptLongestSelect
    imap <C-x><C-t> <C-x><C-t><Plug>CompleteoptLongestSelect
    imap <C-x><C-]> <C-x><C-]><Plug>CompleteoptLongestSelect
    imap <C-x><C-f> <C-x><C-f><Plug>CompleteoptLongestSelect
    imap <C-x><C-v> <C-x><C-v><Plug>CompleteoptLongestSelect
    imap <C-x><C-u> <C-x><C-u><Plug>CompleteoptLongestSelect
    imap <C-x><C-o> <C-x><C-o><Plug>CompleteoptLongestSelect
    imap <C-x>s     <C-x>s<Plug>CompleteoptLongestSelect

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
" CTRL-F		Select a match several entries further, but don't insert
"			it. This doesn't work in filename completion, where
"			CTRL-F goes to the next matching filename. 
" CTRL-B		Select a match several entries back, but don't insert it. 
imap <C-]> <C-x><C-]>
inoremap <expr> <C-f> pumvisible() ? '<PageDown>' : '<C-x><C-f><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
inoremap <expr> <C-b> pumvisible() ? '<PageUp>' : ''

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
