" 实现保存文件夹类似功能的工程
" TODO
" 1. save立即保存;
" 2. 开窗口的时候读取内容, 定时销毁, 销毁的时候判断是有有新的内容保存, 有则写到文件, 无则免之;

function! s:substitute_path_separator(path) "{{{
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction "}}}

" Variables{{{
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:cache_file = s:substitute_path_separator(g:exprjlist_cache_directory . '/exprjlist/prjmgrlist.txt')
"}}}

let s:exprjlist_cache_py_path = fnamemodify(expand('<sfile>'), ':p:h')

function! prjlistcache#init() abort " 初始化python导入 {{{
    " 创建缓存目录
    let s:cache_path = g:exprjlist_cache_directory . '/exprjlist'
    if !isdirectory(s:cache_path)
        call mkdir(s:cache_path, "p", 0777)
    endif

    python3 import sys
    python3 import vim
    python3 sys.path.insert(0, vim.eval('s:exprjlist_cache_py_path'))
endfunction " }}}

function! prjlistcache#append(label, path) abort "{{{
    " Append new exvim project to list
    " echo a:path
python3 << EOF
# 主要实现将label的数据写入缓存文件中
from prjlistcache import cache_append
import vim
prjlabel = vim.eval('a:label')
prjpath = vim.eval('a:path')
cachepath = vim.eval('s:cache_file')
cache_append(prjlabel, prjpath, cachepath)
EOF
endfunction "}}}

function! prjlistcache#refresh() abort " 刷新vsc工程 {{{
python3 << EOF
from prjlistcache import cache_refresh
import vim
cache_refresh()
EOF
endfunction " }}}

function! prjlistcache#fill_plug_cache() abort " 填充显示vim插件目录列表 {{{
python3 << EOF
from prjlistcache import fill_plug_cache
import vim
fill_plug_cache()
EOF
endfunction " }}}

function! prjlistcache#fill_exvim_cache() abort " 填充显示exvim和自己主动添加的目录 {{{
python3 << EOF
from prjlistcache import fill_exvim_cache
import vim
fill_exvim_cache()
EOF
endfunction " }}}

function! prjlistcache#fill_vsc_cache() abort " 填充显示下载的一些开源项目列表{{{
python3 << EOF
from prjlistcache import fill_vsc_cache
import vim
fill_vsc_cache()
EOF
endfunction " }}}

function! prjlistcache#exit() abort "{{{
    " echo 'exit'
endfunction "}}}

