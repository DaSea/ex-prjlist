# ex-prjlist
列出你已经创建的exvim工程(List your exvim project)

## 安装(install)
由于你使用时可能已经有ex-utility插件了, 最好用我fork的替代exvim的, 由于我添加了一些函数, 但是并没有
测试过所有平台, 所以没有添加到主分支里面, 所以, 委屈下用我的分支版本了!

### Vundle.vim
```
Plugin 'DaSea/ex-utility'
Plugin 'DaSea/ex-prjlist'
```
### vim-plug
```
Plug 'DaSea/ex-utility'
Plug 'DaSea/ex-prjlist'
```

## 快捷键(key mapping)
1. 打开工程列表窗口: <leader>el;
2. 在工程列表窗口时: 按j, k 可以上下选择, 按下<enter>可以打开工程;
3. 按下dd可以删除工程, 包括删除工程文件和工程文件夹;

## TODO
1. 添加文件夹类型的工程, 快速进入某个文件夹;
2. 删除添加到里面的工程文件夹名, 只是简单删除记录的文件夹名, 而不是真正的删除;
3. 显示一个列表
