" PrevInsertComplete/Persist.vim: Persistence of previous insertions across Vim sessions.
"
" DEPENDENCIES:
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.10.001	22-Aug-2012	file creation

function! PrevInsertComplete#Persist#Load()
    if exists('g:PREV_INSERTIONS')
	try
	    " Persistent global variables cannot be of type List, so we actually
	    " store the string representation, and eval() it back to a List.
	    execute 'let g:PrevInsertComplete_Insertions =' g:PREV_INSERTIONS
	catch /^Vim\%((\a\+)\)\=:E/
	    let v:errmsg = 'Corrupted persistent insertion history in g:PREV_INSERTIONS'
	    echohl ErrorMsg
	    echomsg v:errmsg
	    echohl None

	    unlet! g:PREV_INSERTIONS
	    unlet! g:PREV_INSERTION_TIMES

	    return
	endtry

	if exists('g:PREV_INSERTION_TIMES')
	    try
		execute 'let g:PrevInsertComplete_InsertionTimes =' g:PREV_INSERTION_TIMES
	    catch /^Vim\%((\a\+)\)\=:E/
		" Just ignore the insertion dates when they are corrupted.
		let g:PrevInsertComplete_InsertionTimes = repeat(0, len(g:PrevInsertComplete_Insertions))
	    endtry
	else
	    " Somehow, the insertion dates weren't persisted. So what.
	    let g:PrevInsertComplete_InsertionTimes = repeat(0, len(g:PrevInsertComplete_Insertions))
	endif

	" Free the memory occupied by the persistence variables. They will be
	" re-populated by PrevInsertComplete#Persist#Save() before Vim exits.
	unlet! g:PREV_INSERTIONS
	unlet! g:PREV_INSERTION_TIMES
    endif
endfunction

function! PrevInsertComplete#Persist#Save()
    let l:size = len(g:PrevInsertComplete_Insertions)
    " Need to truncate to actual size for the List slicing from behind.
    let l:size = (l:size < g:PrevInsertComplete_PersistSize ? l:size : g:PrevInsertComplete_PersistSize)

    let g:PREV_INSERTIONS      = string(g:PrevInsertComplete_Insertions[(-1 * l:size):-1])
    let g:PREV_INSERTION_TIMES = string(g:PrevInsertComplete_InsertionTimes[(-1 * l:size):-1])
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
