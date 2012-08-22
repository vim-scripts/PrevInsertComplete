" PrevInsertComplete.vim: Recall and insert mode completion for previously inserted text.
"
" DEPENDENCIES:
"   - CompleteHelper.vim autoload script.
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.002	22-Aug-2012	Minor cleanup to prepare for publishing.
"	001	09-Nov-2011	file creation from plugin/PrevInsertComplete.vim.

if exists('*strchars')
function! s:strchars( expr )
    return strchars(a:expr)
endfunction
else
function! s:strchars( expr )
    return len(split(a:expr, '\zs'))
endfunction
endif

function! s:GetInsertion()
    " Unfortunately, we cannot simply use register "., because it contains all
    " editing keys, so also <Del> and <BS>, which show up in raw form "<80>kD",
    " and which insert completion does not interpret. Instead, we rely on the
    " range delimited by the marks '[ and '] (last one exclusive).
    let l:startPos = getpos("'[")[1:2]
    let l:endPos = [line("']"), (col("']") - 1)]
    return CompleteHelper#ExtractText(l:startPos, l:endPos, {})
endfunction
function! PrevInsertComplete#Record#Insertion( text )
    if a:text =~# '^\_s*$' || s:strchars(a:text) < g:PrevInsertComplete_MinLength
	" Do not record whitespace-only and short insertions.
	return
    endif

    let l:histIdx = index(g:PrevInsertComplete_Insertions, a:text)
    if l:histIdx == -1
	call insert(g:PrevInsertComplete_Insertions, a:text, 0)
	call insert(g:PrevInsertComplete_InsertionTimes, localtime(), 0)
	silent! call remove(g:PrevInsertComplete_Insertions, g:PrevInsertComplete_HistorySize, -1)
    else
	" Like in the Vim histories, the same history item replaces the previous
	" ones and is put at the top.
	call remove(g:PrevInsertComplete_Insertions, l:histIdx)
	call remove(g:PrevInsertComplete_InsertionTimes, l:histIdx)
	call insert(g:PrevInsertComplete_Insertions, a:text, 0)
	call insert(g:PrevInsertComplete_InsertionTimes, localtime(), 0)
    endif
endfunction
function! PrevInsertComplete#Record#Do()
    call PrevInsertComplete#Record#Insertion(s:GetInsertion())
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
