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

function! s:substitute_path_separator(path) "{{{
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction "}}}

" Variables{{{
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')

if !exists('g:exprjlist_cache_directory')
    let g:exprj_list_cache_directory = expand('~/.cache')
endif
let s:cache_file = s:substitute_path_separator(g:exprj_list_cache_directory . '/exprj/exlist')

let s:cache_time = -1

" Use dictionary: {path: saved}
let s:prj_dict = {}

" timer
let s:clear_timer = -1

" If append new item ,set it to 1
let s:list_updated = 0

" title
let s:win_title = '_EXPRJ_LIST_'

" winpos(aboveleft, belowright)
if !exists('g:exprj_list_win_pos')
    let g:exprj_list_win_pos = 'belowright'
endif

" winsize
if !exists('g:exprj_list_win_size')
    let g:exprj_list_win_size = 10
endif
"}}}

function! exprjlist#load() abort "{{{
    " Load exvim project list when start vim
    " echo s:cache_file
    if !filereadable(s:cache_file)
        return
    endif
    let s:cache_time = getftime(s:cache_file)

    let plist = readfile(s:cache_file)
    if empty(plist)
        echo "No exvim project list cache!"
        return
    endif

    for item in plist
        " TODO 需要验证item是否存在
        if filereadable(expand(item))
            let s:prj_dict[item] = 1
        endif
    endfor
endfunction "}}}

function! exprjlist#reload() abort "{{{
    " Reload exvim project list because list item changed
    if !filereadable(s:cache_file)
        return
    endif

    let plist = readfile(s:cache_file)
    if empty(plist)
        echo "Empty cache!"
        return
    endif

    " plist 中的项是否在s:prj_dict中
    for item in plist
        if !has_key(s:prj_dict, item)
            s:prj_dict[item] = 0
        endif
    endfor
endfunction "}}}

function! exprjlist#append(path) abort "{{{
    " Append new exvim project to list
    " echo a:path
    if 0 == strlen(a:path)
        echo 'Unit-exprj: Invalid path!'
        return
    endif

    " Judge whether a:path is in s:prj_dict
    if !has_key(s:prj_dict, a:path)
        let s:prj_dict[a:path] = 0
        let s:list_updated = 1
    endif
endfunction "}}}

function! exprjlist#save() abort "{{{
    if empty(s:prj_dict)
        return
    endif

    if !s:list_updated
        " echo 'No update item'
        return
    endif

    " Save exvim project list to file
    let last_cache_time = getftime(s:cache_file)
    if last_cache_time != s:cache_time
        " Only need to get new project list
        call exprjlist#reload()
    endif

    let prj_list = keys(s:prj_dict)
    call s:savelist(s:cache_file, prj_list)
endfunction "}}}

" if open, close it; if close , open it
function! exprjlist#toggle_window() abort "{{{
    if has("timers")
        if s:clear_timer == -1
            " After 1 minutes, clear memory
            let s:clear_timer = timer_start(60000, 'ClearMemory', {'repeat': 1})
            call exprjlist#load()
        endif
    else
        if empty(s:prj_dict)
            call exprjlist#load()
        endif
    endif

    " open project windows
    let result = exprjlist#close_window()
    if 0 == result
        call exprjlist#open_window()
        call exprjlist#init_window()
    endif
endfunction "}}}

function! exprjlist#close_window() abort "{{{
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

function! exprjlist#open_window() abort "{{{
    let winnr = bufwinnr(s:win_title)
    if winnr == -1
        " Make sure winpos and winsize
        let winpos = g:exprj_list_win_pos
        let winsize = g:exprj_list_win_size

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

function! exprjlist#init_window() abort "{{{
    " set project list context to windows
    " will call ftplugin/exprjlist.vim
    set filetype=exprjlist

    if line('$') <= 1
        silent call append(0, keys(s:prj_dict))
    endif

    " Delete the last empty line
    normal! G
    let curline = getline('.')
    if strlen(curline) == 0
        normal! dd
    endif
    normal! gg
endfunction "}}}

function! exprjlist#bind_mappings() abort "{{{
    " Define <cr> action
    silent exec 'nnoremap <silent> <buffer> <CR> :call exprjlist#select_item()<CR>'
    " Define exit action
    silent exec 'nnoremap <silent> <buffer> q :call exprjlist#close_window()<CR>'
    " Define jump to next line action
    silent exec 'nnoremap <silent> <buffer> j :call exprjlist#jump_next_line()<CR>'
    " Define jump to previous line action
    silent exec 'nnoremap <silent> <buffer> k :call exprjlist#jump_previous_line()<CR>'
    " Delete project
    silent exec 'nnoremap <silent> <buffer> dd :call exprjlist#delete_prj()<CR>'
    " Forbid i 等
    silent exec 'nnoremap <silent> <buffer> i :call exprjlist#join_you()<CR>'
    " Define other action
endfunction "}}}

function! exprjlist#join_you() abort "{{{
    echo "Your action is forbided!"
    return
endfunction "}}}

function! exprjlist#select_item() abort "{{{
    " Get context of current line
    let filename = getline('.')
    call exprjlist#close_window()

    " Need close other windows
    let win_count = winnr('$')
    let win_idx = win_count
    while win_idx >= 1
        exe win_idx . 'wincmd w'
        let ftype = &filetype
        if ftype ==? 'exproject'
            try
                close
            catch /E444:/
                echo 'Can not close the last window!'
            endtry
        endif

        let win_idx = win_idx - 1
    endwhile

    execute ' silent edit ' . escape(filename, ' ')
endfunction "}}}

function! exprjlist#jump_next_line() abort "{{{
    " Go to next line, if in last line, go to first line
    let cur_line = line('.')
    let end_line = line('$')
    if cur_line == end_line
        normal! gg
    else
        normal! j
    endif
endfunction "}}}

function! exprjlist#jump_previous_line() abort "{{{
    " Go to previous line, if in first line, go to the last line
    let cur_line = line('.')
    if 1 == cur_line
        normal! G
    else
        normal! k
    endif
endfunction "}}}

function! exprjlist#delete_prj() abort "{{{
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

        " 从字典中删除
        call remove(s:prj_dict, cur_prj)
        " 从显示界面移除
        normal! dd
    endif
endfunction "}}}

" Private function{{{
function! s:on_close() abort
    echo 'Wait for add!'
endfunction

function! s:savelist(path, list) abort
    let path = fnamemodify(a:path, ':p')
    if !isdirectory(fnamemodify(path, ':h'))
        call mkdir(fnamemodify(path, ':h'), 'p')
    endif

    call writefile(a:list, path)
endfunction

function! ClearMemory(timer) abort
    echomsg "Clear memory and stop timer"
    if -1 != a:timer
        call timer_stop(a:timer)
    endif
    let s:clear_timer = -1

    call exprjlist#save()
    let s:prj_dict = {}
endfunction " }}}
"}}}
