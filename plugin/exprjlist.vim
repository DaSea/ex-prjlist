"=============================================================================
" FILE: exprjlist.vim
" AUTHOR: DaSea
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

if exists('g:loaded_ex_prjlist')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

augroup exprj
    autocmd!
    autocmd VimEnter * call exprjlist#load()
    autocmd BufNewFile,BufRead *.exvim call s:append(expand('<amatch>'))
    autocmd VimLeavePre * call exprjlist#save()
augroup END

let g:loaded_ex_prjlist= 1

" commands{{{
command! EXProjectList call exprjlist#toggle_window()
"}}}

" Key mapping {{{
nnoremap <leader>el :call exprjlist#toggle_window()<CR>
"}}}

" Private function {{{
function! s:append(path) "{{{
    " echomsg a:path
    if a:path == ''
      return
    endif

    call exprjlist#append(a:path)
endfunction "}}}
"}}}
let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
