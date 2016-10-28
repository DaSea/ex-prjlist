" 实现保存文件夹类似功能的工程
" TODO
" 1. save立即保存;
" 2. 开窗口的时候读取内容, 定时销毁, 销毁的时候判断是有有新的内容保存, 有则写到文件, 无则免之;

function! s:substitute_path_separator(path) "{{{
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction "}}}

" Variables{{{
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')

if !exists('g:exprjlist_cache_directory')
    let g:exprj_list_cache_directory = expand('~/.cache')
endif
let s:cache_file = s:substitute_path_separator(g:exprj_list_cache_directory . '/exprj/prjmgrlist')

let s:cache_time = -1

" Use dictionary: {path: saved}
let s:prj_dict = {}

" timer
let s:clear_timer = -1

" If append new item ,set it to 1
let s:list_updated = 0

" title
let s:win_title = '_PRJ_LIST_'

" winpos(aboveleft, belowright)
if !exists('g:exprj_list_win_pos')
    let g:exprj_list_win_pos = 'belowright'
endif

" winsize
if !exists('g:exprj_list_win_size')
    let g:exprj_list_win_size = 10
endif
"}}}

function! projectmgr#load() abort "{{{
    " Load exvim project list when start vim
    " echo s:cache_file
    if !filereadable(s:cache_file)
        return
    endif
    let s:cache_time = getftime(s:cache_file)

    let plist = readfile(s:cache_file)
    if empty(plist)
        echo "No project list cache!"
        return
    endif

    for item in plist
        " 验证item是否存在
        if isdirectory(expand(item))
            let s:prj_dict[item] = 1
        endif
    endfor
endfunction "}}}

function! projectmgr#reload() abort "{{{
    " Reload project list because list item has changed
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
            let s:prj_dict[item] = 0
        endif
    endfor
endfunction "}}}

function! projectmgr#append(path) abort "{{{
    " Append new exvim project to list
    " echo a:path
    if 0 == strlen(a:path)
        echo 'Project Manager: Invalid path!'
        return
    endif

    " Judge whether a:path is in s:prj_dict
    if !has_key(s:prj_dict, a:path)
        let s:prj_dict[a:path] = 0
        let s:list_updated = 1
    endif
endfunction "}}}

function! projectmgr#save() abort "{{{
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
        call projectmgr#reload()
    endif

    let prj_list = keys(s:prj_dict)
    call s:savelist(s:cache_file, prj_list)
endfunction "}}}

function! projectmgr#exit() abort "{{{
    call projectmgr#save()
    let s:prj_dict = {}
endfunction "}}}

" if open, close it; if close , open it
function! projectmgr#toggle_window() abort "{{{
    if -1 == s:cache_time
        call projectmgr#load()
    endif

    " open project windows
    let result = projectmgr#close_window()
    if 0 == result
        call projectmgr#open_window()
        call projectmgr#init_window()
    endif
endfunction "}}}

function! projectmgr#close_window() abort "{{{
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

function! projectmgr#open_window() abort "{{{
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
        " 将光标切换到窗口winnr
        exe winnr . 'wincmd w'
    endif

    " 清空窗口
    normal! ggdG

    silent setlocal winfixheight
    silent setlocal winfixwidth
endfunction "}}}

function! projectmgr#init_window() abort "{{{
    " set project list context to windows
    " will call ftplugin/projectmgr.vim
    set filetype=projectmgr

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

function! projectmgr#bind_mappings() abort "{{{
    " Define <cr> action
    silent exec 'nnoremap <silent> <buffer> <CR> :call projectmgr#select_item()<CR>'
    " Define exit action
    silent exec 'nnoremap <silent> <buffer> q :call projectmgr#close_window()<CR>'
    " Define jump to next line action
    silent exec 'nnoremap <silent> <buffer> j :call projectmgr#jump_next_line()<CR>'
    " Define jump to previous line action
    silent exec 'nnoremap <silent> <buffer> k :call projectmgr#jump_previous_line()<CR>'
    " Delete project
    silent exec 'nnoremap <silent> <buffer> dd :call projectmgr#delete_prj()<CR>'
    " Forbid i 等
    silent exec 'nnoremap <silent> <buffer> i :call projectmgr#join_you()<CR>'
    " Define other action
endfunction "}}}

function! projectmgr#join_you() abort "{{{
    echo "你的行为是不被允许的(Your action is forbided!)"
    return
endfunction "}}}

function! projectmgr#select_item() abort "{{{
    " Get context of current line
    let pathName = getline('.')
    call projectmgr#close_window()

    " cd 路径
    if "" != pathName
        execute 'cd! ' . pathName
    endif

    " 添加GTAGS
    silent! execute 'cs add GTAGS'
endfunction "}}}

function! projectmgr#jump_next_line() abort "{{{
    " Go to next line, if in last line, go to first line
    let cur_line = line('.')
    let end_line = line('$')
    if cur_line == end_line
        normal! gg
    else
        normal! j
    endif
endfunction "}}}

function! projectmgr#jump_previous_line() abort "{{{
    " Go to previous line, if in first line, go to the last line
    let cur_line = line('.')
    if 1 == cur_line
        normal! G
    else
        normal! k
    endif
endfunction "}}}

function! projectmgr#delete_prj() abort "{{{
    " 获取当前行的工程名,并判断.exvim文件夹是否存在,如果存在,则删除
    let cur_prj = getline('.')
    " 询问是否删除
    call inputsave()
    let answer = input("Are you sure delete(Y/N)> ")
    call inputrestore()
    if 'y' ==? answer
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

    call projectmgr#save()
    let s:cache_time = -1
    let s:list_updated = 0
    let s:prj_dict = {}
endfunction " }}}
"}}}

