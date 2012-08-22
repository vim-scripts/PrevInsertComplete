" PrevInsertComplete.vim: Recall and insert mode completion for previously inserted text.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - PrevInsertComplete.vim autoload script.
"   - PrevInsertComplete/Record.vim autoload script.
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.004	22-Aug-2012	Minor cleanup to prepare for publishing.
"	003	09-Nov-2011	FIX: Avoid hit-enter prompt after q<CTRL-A>.
"				Split off autoload script and documentation.
"	002	10-Oct-2011	Implement repetition with following history
"				items.
"	001	06-Oct-2011	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_PrevInsertComplete') || (v:version < 700)
    finish
endif
let g:loaded_PrevInsertComplete = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:PrevInsertComplete_MinLength')
    let g:PrevInsertComplete_MinLength = 10
endif
if ! exists('g:PrevInsertComplete_HistorySize')
    let g:PrevInsertComplete_HistorySize = 100
endif


"- internal data structures ----------------------------------------------------

let g:PrevInsertComplete_Insertions = []
let g:PrevInsertComplete_InsertionTimes = []


"- autocmds --------------------------------------------------------------------

augroup PrevInsertComplete
    autocmd! InsertLeave * call PrevInsertComplete#Record#Do()
augroup END


"- mappings --------------------------------------------------------------------

inoremap <script> <expr> <Plug>(PrevInsertComplete) PrevInsertComplete#Expr()
if ! hasmapto('<Plug>(PrevInsertComplete)', 'i')
    imap <C-x><C-a> <Plug>(PrevInsertComplete)
endif

nnoremap <silent> <Plug>(PrevInsertRecall) :<C-u>call PrevInsertComplete#Recall(v:count1, 1)<CR>
if ! hasmapto('<Plug>(PrevInsertRecall)', 'n')
    nmap qa <Plug>(PrevInsertRecall)
endif
nnoremap <silent> <Plug>(PrevInsertList) :<C-u>call PrevInsertComplete#List()<CR>
if ! hasmapto('<Plug>(PrevInsertList)', 'n')
    nmap q<C-a> <Plug>(PrevInsertList)
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
