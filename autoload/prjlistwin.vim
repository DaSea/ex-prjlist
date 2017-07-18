"=============================================================================
" FILE: prjlistwin.vim
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

" function! s:substitute_path_separator(path) "{{{
  " return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
" endfunction "}}}

" Variables{{{
" let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
" let s:cache_file=s:substitute_path_separator(g:exprjlist_cache_directory.'/exprjlist/prjlistmgr.txt')

let s:win_title = 'ExPrjDirList'

" winpos(aboveleft, belowright)
if !exists('g:exprjlist_win_pos')
    let g:exprjlist_win_pos = 'belowright'
endif

" winsize
if !exists('g:exprjlist_win_size')
    let g:exprjlist_win_size = 10
endif

" 记录本次打开的的文件的子类型
let s:dir_list_type = 0
"}}}

" if open, close it; if close , open it
function! prjlistwin#toggle_window(type) abort "{{{
    let winnr = bufwinnr(s:win_title)
    if -1 != winnr
        " 窗口存在
        if a:type == s:dir_list_type
            " 相同类型
            call prjlistwin#close_window()
            return
        else
            " 不同类型，则需要清除当前内容，然后重新填充
        endif
    else
        " 窗口不存在
        call prjlistwin#open_window()
    endif

    " 清除内容
    normal! ggdG

    if 1==a:type
        call prjlistwin#init_common_windows()
    elseif 2==a:type
        call prjlistwin#init_vsc_windows()
    elseif 3==a:type
        call prjlistwin#init_plug_windows()
    endif
    let s:dir_list_type = a:type
endfunction "}}}

function! prjlistwin#close_window() abort "{{{
    let winnr = bufwinnr(s:win_title)
    if -1 != winnr
        " jump to the window
        exe winnr . 'wincmd w'
        " if this is not the only window, close it
        try
            close
        catch /E444:/
            echo 'Can not close the last window!'
        endtry

        doautocmd BufEnter
        return 1
    endif

    return 0
endfunction "}}}

function! prjlistwin#open_window() abort "{{{
    let winnr = bufwinnr(s:win_title)
    if winnr == -1
        " Make sure winpos and winsize
        let winpos = g:exprjlist_win_pos
        let winsize = g:exprjlist_win_size

        " if the buffer already exists, reuse it
        " Otherwise create a new buffer
        let bufnum = bufnr(s:win_title)
        let bufcmd = ''
        if -1 == bufnum
            let bufcmd = fnameescape(s:win_title)
        else
            let bufcmd = '+b' . bufnum
        endif

        " create window
        silent exe winpos . ' ' . winsize . ' split ' . bufcmd
    else
        exe winnr . 'wincmd w'
    endif

    silent setlocal winfixheight
    silent setlocal winfixwidth
endfunction "}}}

function! prjlistwin#init_common_windows() abort "{{{
    " set project list context to windows
    " will call ftplugin/prjlistwin.vim
    set filetype=exprjlist

    if line('$') <= 1
        call prjlistcache#fill_exvim_cache()
    endif

    " Delete the last empty line
    normal! G
    let curline = getline('.')
    if strlen(curline) == 0
        normal! dd
    endif
    normal! gg
endfunction "}}}

function! prjlistwin#init_vsc_windows() abort "{{{
    " set project list context to windows
    " will call ftplugin/prjlistwin.vim
    set filetype=exprjlist

    if line('$') <= 1
        call prjlistcache#fill_vsc_cache()
    endif

    " Delete the last empty line
    normal! G
    let curline = getline('.')
    if strlen(curline) == 0
        normal! dd
    endif
    normal! gg
endfunction "}}}

function! prjlistwin#init_plug_windows() abort "{{{
    " set project list context to windows
    " will call ftplugin/prjlistwin.vim
    set filetype=exprjlist

    if line('$') <= 1
        call prjlistcache#fill_plug_cache()
    endif

    " Delete the last empty line
    normal! G
    let curline = getline('.')
    if strlen(curline) == 0
        normal! dd
    endif
    normal! gg
endfunction "}}}

function! prjlistwin#bind_mappings() abort "{{{
    " Define <cr> action
    silent exec 'nnoremap <silent> <buffer> <CR> :call prjlistwin#select_item()<CR>'
    " Define exit action
    silent exec 'nnoremap <silent> <buffer> q :call prjlistwin#close_window()<CR>'
    " Define jump to next line action
    silent exec 'nnoremap <silent> <buffer> j :call prjlistwin#jump_next_line()<CR>'
    " Define jump to previous line action
    silent exec 'nnoremap <silent> <buffer> k :call prjlistwin#jump_previous_line()<CR>'
    " Delete project
    silent exec 'nnoremap <silent> <buffer> dd :call prjlistwin#delete_prj()<CR>'
    " Forbid i 等
    silent exec 'nnoremap <silent> <buffer> i :call prjlistwin#join_you()<CR>'
    " Define other action
endfunction "}}}

function! prjlistwin#join_you() abort "{{{
    echo "Your action is forbided!"
    return
endfunction "}}}

function! prjlistwin#select_item() abort "{{{
    " Get context of current line
    let filename = getline('.')
    call prjlistwin#close_window()

    " 判断filename所代表的是文件还是文件夹,然后采用不同的方式
    echomsg "select item: " . filename
    let idx = stridx(filename, ":")
    if idx < 0
        echomsg "找不到,非法的!"
        return
    endif

    let finalname = strpart(filename, idx+1)
    if isdirectory(finalname)
        execute ' silent lcd ' . escape(finalname, ' \')
    else
        execute ' silent edit ' . escape(finalname, ' \')
    endif
endfunction "}}}

function! prjlistwin#jump_next_line() abort "{{{
    " Go to next line, if in last line, go to first line
    let cur_line = line('.')
    let end_line = line('$')
    if cur_line == end_line
        normal! gg
    else
        normal! j
    endif
endfunction "}}}

function! prjlistwin#jump_previous_line() abort "{{{
    " Go to previous line, if in first line, go to the last line
    let cur_line = line('.')
    if 1 == cur_line
        normal! G
    else
        normal! k
    endif
endfunction "}}}

function! prjlistwin#delete_prj() abort "{{{
    " 获取当前行的工程名,并判断.exvim文件夹是否存在,如果存在,则删除
    let cur_prj = getline('.')
    " 提取路径
    let prj_path = fnamemodify(cur_prj, ":p:h")
    " 询问是否删除
    call inputsave()
    let answer = input("Are you sure delete(Y/N)> ")
    call inputrestore()
    if 'y' ==? answer
        " 删除文件
        if 0 == delete(cur_prj)
            echomsg "<Delete project config file success!"
        endif

        " 获取工程名
        let prjName = fnamemodify(cur_prj, ":t")

        " 删除文件夹
        let prj_dir = prj_path . '/.exvim'
        if isdirectory(prj_dir)
            " 如果存在,则删除文件夹
            call ex#os#del_folder(prj_dir)
        else
            let prj_dir = prj_path . '/' . prjName
            if isdirectory(prj_dir)
                call ex#os#del_folder(prj_dir)
            endif
        endif

        " 从显示界面移除
        normal! dd
    endif
endfunction "}}}

" Private function{{{

"}}}
