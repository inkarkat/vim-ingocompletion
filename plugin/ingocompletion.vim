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
"	002	14-Jun-2009	Undid complete longest+preselect; too many
"				obstacles prevented a clean implementation. 
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
