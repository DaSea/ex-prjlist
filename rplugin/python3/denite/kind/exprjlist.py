# -*- coding: utf-8 -*-
#!/usr/bin/env python3

import re
from .base import Base

class Kind(Base):
    def __init__(self, vim):
        super().__init__(vim)
        # kind 名称, 用于在source中指定
        self.name = 'exprjlist'
        # self.default_action = 'xxx' 指定默认动作, enter的时候
        # action_xxx() 定义实际操作
        self.default_action = 'default'

    def action_default(self, context):
        '''
        主要是切换到路径, 如果是exvim工程的话, 则打开exvim文件
        '''
        target = context['targets'][0]
        label, path = target['word'].split(':', maxsplit=1)
        if 'exvim' == label:
            self.__action_open(path)
        else:
            self.__action_cd(path)

    def __action_open(self, path):
        match_path = '^{0}$'.format(path)
        if self.vim.call('bufwinnr', match_path) <= 0:
            self.vim.call(
                'denite#util#execute_path', 'edit', path)
        elif self.vim.call('bufwinnr', match_path) != self.vim.current.buffer:
            self.vim.call(
                'denite#util#execute_path', 'buffer', path)

    def __action_cd(self, path):
        """
        cd 到对应的目录
        """
        self.vim.command('lcd {}'.format(path))
