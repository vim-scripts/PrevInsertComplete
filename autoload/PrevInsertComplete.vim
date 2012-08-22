" PrevInsertComplete.vim: Recall and insert mode completion for previously inserted text.
"
" DEPENDENCIES:
"   - CompleteHelper/Abbreviate.vim autoload script
"   - CompleteHelper/Repeat.vim autoload script
"   - ingodate.vim autoload script
"   - PrevInsertComplete/Record.vim autoload script
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.004	21-Aug-2012	Minor: Reduce initial indent in list; :marks and
"				:jumps have little indent, too.
"	003	05-May-2012	Move dependency from CompleteHelper.vim to
"				CompleteHelper/Abbreviate.vim script broken out
"				in version 1.01.
"	002	23-Mar-2012	No need for inputsave() around getchar().
"	001	09-Nov-2011	file creation from plugin/PrevInsertComplete.vim.
let s:save_cpo = &cpo
set cpo&vim

function! s:ComputeReltime( matchObj )
    let a:matchObj.menu = ingodate#HumanReltime(localtime() - a:matchObj.menu, {'shortformat': 1, 'rightaligned': 1})
    return a:matchObj
endfunction
if v:version >= 703 || v:version == 702 && has('patch295')
function! PrevInsertComplete#FindMatches( pattern )
    " Use default comparison operator here to honor the 'ignorecase' setting.
    return
    \	map(
    \	    filter(
    \		map(copy(g:PrevInsertComplete_Insertions), '{"word": v:val, "menu": g:PrevInsertComplete_InsertionTimes[v:key]}'),
    \		'v:val.word =~ a:pattern'
    \	    ),
    \	    'CompleteHelper#Abbreviate#Word(s:ComputeReltime(v:val))'
    \	)
endfunction
else
function! PrevInsertComplete#FindMatches( pattern )
    " Use default comparison operator here to honor the 'ignorecase' setting.
    return
    \	map(
    \	    filter(copy(g:PrevInsertComplete_Insertions), 'v:val =~ a:pattern'),
    \	    'CompleteHelper#Abbreviate#Word({"word": v:val})'
    \	)
endfunction
endif
let s:repeatCnt = 0
function! PrevInsertComplete#PrevInsertComplete( findstart, base )
    if s:repeatCnt
	if a:findstart
	    return col('.') - 1
	else
	    let l:histIdx = index(g:PrevInsertComplete_Insertions, s:addedText)
"****D echomsg '***1' l:histIdx s:addedText
	    if l:histIdx == -1 || l:histIdx == 0
		return []
	    endif
"****D echomsg '***2' get(g:PrevInsertComplete_Insertions, (l:histIdx - 1), '')
	    return [{'word': get(g:PrevInsertComplete_Insertions, (l:histIdx - 1), '')}]
	endif
    endif

    if a:findstart
	" Locate the start of the keyword.
	let l:startCol = searchpos('\k*\%#', 'bn', line('.'))[1]
	if l:startCol == 0
	    let l:startCol = col('.')
	endif
	return l:startCol - 1 " Return byte index, not column.
    else
	" Find matches starting with (after optional non-keyword characters) a:base.
	let l:matches = PrevInsertComplete#FindMatches('^\%(\k\@!.\)*\V' . escape(a:base, '\'))
	if empty(l:matches)
	    " Find matches containing a:base.
	    let l:matches = PrevInsertComplete#FindMatches('\V' . escape(a:base, '\'))
	endif
	return l:matches
    endif
endfunction

function! PrevInsertComplete#Expr()
    set completefunc=PrevInsertComplete#PrevInsertComplete

    let s:repeatCnt = 0
    let [s:repeatCnt, s:addedText, l:fullText] = CompleteHelper#Repeat#TestForRepeat()
"****D echomsg '****' string( [s:repeatCnt, s:addedText, l:fullText] )
    return "\<C-x>\<C-u>"
endfunction

function! PrevInsertComplete#Recall( position, multiplier )
    let l:insertion = get(g:PrevInsertComplete_Insertions, (a:position - 1), '')
    if empty(l:insertion)
	if len(g:PrevInsertComplete_Insertions) == 0
	    let v:errmsg = 'No insertions yet'
	else
	    let v:errmsg = printf('There %s only %d insertion%s in the history',
	    \   len(g:PrevInsertComplete_Insertions) == 1 ? 'is' : 'are',
	    \   len(g:PrevInsertComplete_Insertions),
	    \   len(g:PrevInsertComplete_Insertions) == 1 ? '' : 's'
	    \)
	endif
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None

	return
    endif

    " This doesn't work with special characters like <Esc>.
    "execute 'normal! a' . l:insertion . "\<Esc>"

    let l:save_clipboard = &clipboard
    set clipboard= " Avoid clobbering the selection and clipboard registers.
    let l:save_reg = getreg('"')
    let l:save_regmode = getregtype('"')
    call setreg('"', l:insertion, 'v')
    try
	execute 'normal!' a:multiplier . 'p'
    finally
	call setreg('"', l:save_reg, l:save_regmode)
	let &clipboard = l:save_clipboard
    endtry

    " Execution of the recall command counts as an insertion itself. However, we
    " do not consider the a:multiplier here.
    call PrevInsertComplete#Record#Insertion(l:insertion)
endfunction
function! PrevInsertComplete#List()
    if len(g:PrevInsertComplete_Insertions) == 0
	let v:errmsg = 'No insertions yet'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    echohl Title
    echo ' #  insertion'
    echohl None
    for i in range(min([9, len(g:PrevInsertComplete_Insertions)]), 1, -1)
	echo ' ' . i . '  ' . EchoWithoutScrolling#TranslateLineBreaks(g:PrevInsertComplete_Insertions[i - 1])
    endfor
    echo 'Type number (<Enter> cancels): '
    let l:choice = nr2char(getchar())
    if l:choice =~# '\d'
	redraw	" Somehow need this to avoid the hit-enter prompt.
	call PrevInsertComplete#Recall(l:choice, v:count1)
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
