# -*- coding: utf-8 -*-
#!/usr/bin/env python3

import vim
import os

def cache_append(prjlabel, prjpath, cachepath):
    data = prjlabel + ":" + prjpath + '\n'
    if os.path.isfile(cachepath):
        isexists = False
        with open(cachepath, 'r+', encoding='utf-8', newline='\n') as f:
            lines = f.readlines()
            for line in lines:
                if line == data:
                    isexists = True
            if not isexists:
                f.write(data)
    else:
        with open(cachepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(data)

def cache_refresh():
    """
    主要为遍历git, svn等版本控制的文件夹
    """
    # cache存放地址
    cacheroot = vim.eval('g:exprjlist_cache_directory')
    cachepath = os.sep.join([cacheroot, 'exprjlist', 'vsclist.txt'])
    # vsc 根目录字典
    vsc_rootdir = vim.eval('g:exprjlist_vsc_root_dir')
    with open(cachepath, 'w', encoding='utf-8', newline='\n') as f:
        for item in vsc_rootdir.items():
            _filter_vsc_projcect(f, item[1], item[0])

def fill_plug_cache():
    """
    主要为遍历vim插件目录，并将插件目录列表显示出来
    """
    cb = vim.current.buffer
    print(cb.name)

    vimplug_root = vim.eval('g:exprjlist_vimplug_root_dir')
    if 0 == len(vimplug_root):
        return

    label = 'vimplug'
    candidates = []
    for item in os.listdir(vimplug_root):
        itempath = os.sep.join([vimplug_root, item])
        if os.path.isdir(itempath):
            item = label + ":" + itempath
            candidates.append(item)
    # 添加到buffer
    cb[:]  = candidates

def fill_exvim_cache():
    """
    显示exvim工程列表和自己保存的目录
    """
    cb = vim.current.buffer
    print(cb.name)

    cacheroot = vim.eval('g:exprjlist_cache_directory')
    cachepath = os.sep.join([cacheroot, 'exprjlist', 'prjmgrlist.txt'])
    if not os.path.isfile(cachepath):
        return

    candidates = []
    with open(cachepath, 'r', encoding='utf-8', newline='\n') as f:
        while True:
            line = f.readline().strip()
            if not line:
                break
            candidates.append(line)
    # 添加到buffer
    cb[:]  = candidates


def fill_vsc_cache():
    cb = vim.current.buffer
    print(cb.name)

    cacheroot = vim.eval('g:exprjlist_cache_directory')
    vscpath = os.sep.join([cacheroot, 'exprjlist', 'vsclist.txt'])
    vsc_rootdir = vim.eval('g:exprjlist_vsc_root_dir')
    if not os.path.isfile(vscpath):
        with open(cachepath, 'w', encoding='utf-8', newline='\n') as f:
            for item in vsc_rootdir.items():
                _filter_vsc_projcect(f, item[1], item[0])

    candidates = []
    with open(vscpath, 'r', encoding='utf-8', newline='\n') as f:
        while True:
            line = f.readline().strip()
            if not line:
                break
            # get label and path
            candidates.append(line)
    cb[:] = candidates

def _filter_vsc_projcect(fileobj, label, path):
    """
    主要查找path下面的文件夹是否是label类型的文件夹, 如git, svn等, 并写入文件(label:path)
    """
    for item in os.listdir(path):
        itempath = os.sep.join([path, item])
        fullpath = os.sep.join([itempath, "."+label])
        if os.path.isdir(fullpath):
            line = label + ":" + itempath + "\n"
            fileobj.write(line)
