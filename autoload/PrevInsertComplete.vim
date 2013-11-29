" PrevInsertComplete.vim: Recall and insert mode completion for previously inserted text.
"
" DEPENDENCIES:
"   - CompleteHelper/Abbreviate.vim autoload script
"   - CompleteHelper/Repeat.vim autoload script
"   - ingo/avoidprompt.vim autoload script
"   - ingo/date.vim autoload script
"   - ingo/msg.vim autoload script
"   - ingo/register.vim autoload script
"   - PrevInsertComplete/Record.vim autoload script
"   - repeat.vim (vimscript #2136) autoload script (optional)
"
" Copyright: (C) 2011-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.11.008	18-Nov-2013	Use ingo#register#KeepRegisterExecuteOrFunc().
"				Use ingo#msg#ErrorMsg().
"				Make recall of insertion (q<CTRL-@>, q<CTRL-A>)
"				repeatable.
"   1.11.007	08-Jul-2013	Move ingodate.vim into ingo-library.
"   1.11.006	07-Jun-2013	Move EchoWithoutScrolling.vim into ingo-library.
"   1.10.005	22-Aug-2012	Do not show relative time when the timestamp is
"				invalid (i.e. negative or zero). This is better
"				when the g:PrevInsertComplete_InsertionTimes
"				somehow wasn't persisted.
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
    let a:matchObj.menu = (a:matchObj.menu <= 0 ?
    \	'' :
    \   ingo#date#HumanReltime(localtime() - a:matchObj.menu, {'shortformat': 1, 'rightaligned': 1})
    \)
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
    let s:insertion = get(g:PrevInsertComplete_Insertions, (a:position - 1), '')
    if empty(s:insertion)
	if len(g:PrevInsertComplete_Insertions) == 0
	    call ingo#msg#ErrorMsg('No insertions yet')
	else
	    call ingo#msg#ErrorMsg(printf('There %s only %d insertion%s in the history',
	    \   len(g:PrevInsertComplete_Insertions) == 1 ? 'is' : 'are',
	    \   len(g:PrevInsertComplete_Insertions),
	    \   len(g:PrevInsertComplete_Insertions) == 1 ? '' : 's'
	    \))
	endif
    else
	call PrevInsertComplete#DoRecall( a:multiplier )
    endif
endfunction
function! PrevInsertComplete#DoRecall( multiplier )

    " This doesn't work with special characters like <Esc>.
    "execute 'normal! a' . s:insertion . "\<Esc>"
    call ingo#register#KeepRegisterExecuteOrFunc(function('PrevInsertComplete#Insert'), s:insertion, a:multiplier)

    " Execution of the recall command counts as an insertion itself. However, we
    " do not consider the a:multiplier here.
    call PrevInsertComplete#Record#Insertion(s:insertion)

    silent! call repeat#set("\<Plug>(PrevInsertRecallRepeat)", a:multiplier)
endfunction
function! PrevInsertComplete#Insert( insertion, multiplier )
    call setreg('"', a:insertion, 'v')
    execute 'normal!' a:multiplier . 'p'
endfunction
function! PrevInsertComplete#List()
    if len(g:PrevInsertComplete_Insertions) == 0
	call ingo#msg#ErrorMsg('No insertions yet')
	return
    endif

    echohl Title
    echo ' #  insertion'
    echohl None
    for i in range(min([9, len(g:PrevInsertComplete_Insertions)]), 1, -1)
	echo ' ' . i . '  ' . ingo#avoidprompt#TranslateLineBreaks(g:PrevInsertComplete_Insertions[i - 1])
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
