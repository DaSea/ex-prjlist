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

let g:loaded_ex_prjlist= 1

augroup exprj
    autocmd!
    autocmd BufNewFile,BufRead *.exvim call s:append(expand('<amatch>'))
    autocmd VimLeavePre * call s:exit()
augroup END

" Variables{{{
if !exists('g:exprjlist_cache_directory')
    let g:exprjlist_cache_directory = expand('~/.cache')
endif

if !exists('g:exprjlist_vsc_root_dir')
    " 可以定义多个root目录, 是个字典类型:{'path':'git', 'path':'svn', ...}
    let g:exprjlist_vsc_root_dir = {}
endif

" 存放插件的路径
if !exists('g:exprjlist_vimplug_root_dir')
    let g:exprjlist_vimplug_root_dir = "~/.vim/plugged"
endif
"}}}

" commands{{{
" 将一个目录保存到工程缓存里面去
command! EXPrjDirSave call s:save_project()
" 刷新vsc目录缓存，第一次的时候缓存，然后在需要的时候再刷新
command! EXPrjVscDirRefresh call prjlistcache#refresh()

" 要显示三种类型的窗口: exvim工程，普通工程；vsc工程；插件目录
" 如果有denite.nvim的话，使用denite.vim进行切换
command! EXPrjCommonDirList call prjlistwin#toggle_window(1)
command! EXPrjVerDirList call prjlistwin#toggle_window(2)
command! EXPrjPlugDirLIst call prjlistwin#toggle_window(3)
"}}}

" 开始要做的一些工作{{{
call prjlistcache#init()
" }}}

" Private function {{{
function! s:append(path) "{{{
    " echomsg a:path
    if a:path == ''
      return
    endif

    call prjlistcache#append("exvim", a:path)
endfunction "}}}

function! s:exit() abort " exit {{{
    call prjlistcache#exit()
endfunction " }}}

" 保存文件夹类型的工程 {{{
function! s:save_project()
    let saveName = getcwd()
    " 使用所在文件的根目录为工程名
    " 试图进入根目录, 如果没有根目录, 则在当前文件夹
    call inputsave()
    let prjName = input("[exprjlist]保存路径为: ", saveName)
    call inputrestore()

    if "" == prjName
        echo "[exprjlist]路径为空, 请确定好路径!"
        return
    endif

    if !isdirectory(prjName)
        echo "[exprjlist]路径不合法"
        return
    endif

    call prjlistcache#append("common", prjName)
endfunction " }}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker

