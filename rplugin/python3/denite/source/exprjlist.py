# -*- coding: utf-8 -*-
#!/usr/bin/env python3

from .base import Base
import glob
import itertools
import os
from denite import util


class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        # Denite xxx 中的 xxx 名字定义
        self.name = 'exprjlist'
        # kind 类型指定
        self.kind = 'exprjlist'

    def on_init(self, context):
        '''
        当source初始化完毕后被调用
        '''
        # cache的路径
        self.__cacheroot = self.vim.eval('g:exprjlist_cache_directory')
        self.__cachepath = os.sep.join([self.__cacheroot, 'exprjlist', 'prjmgrlist.txt'])
        self.__vscpath = os.sep.join([self.__cacheroot, 'exprjlist', 'vsclist.txt'])
        # 创建缓存目录
        cachepath = os.path.dirname(self.__vscpath)
        if not os.path.exists(cachepath):
            os.makedirs(cachepath)

    def on_close(self, context):
        '''
        Denite 动作结束时调用的
        '''
        pass

    def gather_candidates(self, context):
        '''
        收集需要显示的工程列表
        [{'word': 用于输入匹配, 'abbr': 显示在 denite 窗口, 如果没有, 用word替代}]
        [{'label': 'git', 'word': 'path']

        :Denite exprjlist:vsc:user:vimplug
        user: exvim工程及用户调用DPrjSave保存的
        vsc: 通过vsclist.txt 获取的
        vimplug: 用户的vim插件目录
        sources:[{'name':'exprjlist', 'args': ['vimplug', 'user', 'vsc', ...]}, ...]
        "forbid_fresh": true or false -> 强制刷新选项-forbid-fresh: 刷新vsc工程
        '''
        # 分离出需要显示的项: wiki, git, common(exvim, useradd)
        curargs = []
        for item in context["sources"]:
            if item["name"] == "exprjlist":
                curargs = item["args"]
                break

        return self._gather_candidates(curargs)

    def _gather_candidates(self, curargs):
        # if curargs is null, display usrdefine;
        candidates = []
        if (0 == len(curargs)) or (curargs.count('user') >= 1) or (curargs.count('exvim')>=1):
            candidates += self._parse_user_prj_candidate()

        if curargs.count('vimplug') > 0:
            candidates += self._parse_vimplug_candidate()

        if curargs.count('vsc') > 0:
            candidates += self._parse_vsc_candidate()

        return candidates

    def _parse_user_prj_candidate(self):
        """
        解析保存的文件cache, 并显示
        """
        candidates = []
        if os.path.isfile(self.__cachepath):
            with open(self.__cachepath, 'r', encoding='utf-8', newline='\n') as f:
                while True:
                    line = f.readline().strip()
                    if not line:
                        break
                    item = {}
                    item['word'] = line
                    candidates.append(item)
        return candidates

    def _parse_vimplug_candidate(self):
        vimplug_root = self.vim.eval('g:exprjlist_vimplug_root_dir')
        if 0 == len(vimplug_root):
            return []

        label = 'vimplug'
        candidates = []
        for item in os.listdir(vimplug_root):
            itempath = os.sep.join([vimplug_root, item])
            if os.path.isdir(itempath):
                item = {}
                item['word'] = label + ":" + itempath
                candidates.append(item)
        return candidates

    def _parse_vsc_candidate(self):
        # version控制项目遍历, 给你设置一个根目录, 遍历下面的文件夹是否是某种工程
        if not os.path.isfile(self.__vscpath):
            self._prjmgr_refresh()

        candidates = []
        if os.path.isfile(self.__vscpath):
            with open(self.__vscpath, 'r', encoding='utf-8', newline='\n') as f:
                while True:
                    line = f.readline().strip()
                    if not line:
                        break
                    # get label and path
                    item = {}
                    item['word'] = line
                    candidates.append(item)

        return candidates

    def _prjmgr_refresh(self):
        """
        主要为遍历git, svn等版本控制的文件夹
        """
        # vsc 根目录字典
        vsc_rootdir = self.vim.eval('g:exprjlist_vsc_root_dir')
        with open(self.__vscpath, 'w', encoding='utf-8', newline='\n') as f:
            for item in vsc_rootdir.items():
                self._filter_vsc_projcect(f, item[1], item[0])

    def _filter_vsc_projcect(self, fileobj, label, path):
        """
        主要查找path下面的文件夹是否是label类型的文件夹, 如git, svn等, 并写入文件(label:path)
        """
        for item in os.listdir(path):
            itempath = os.sep.join([path, item])
            fullpath = os.sep.join([itempath, "."+label])
            if os.path.isdir(fullpath):
                line = label + ":" + itempath + "\n"
                fileobj.write(line)
