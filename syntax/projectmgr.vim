if version < 700
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" syntax highlight
syntax match projectmgr_pathname '\<[a-zA-Z_][a-zA-Z0-9_]*\>$'hs=s,he=e

hi default link projectmgr_pathname KeyWord

let b:current_syntax = "projectmgr"

" vim:ts=4:sw=4:sts=4 et fdm=marker:
