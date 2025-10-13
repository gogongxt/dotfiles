# 分屏操作

`c-w H/J/K/L`
在已经打开多个window的情况下，可以按上面的快捷键实现快速交换窗口和将窗口从左右切换成垂直

# jump

| keymap | usage         |
| ------ | ------------- |
| `[]c`  | diff          |
| `{}`   | null line     |
| `[]e`  | lsp error     |
| `[]w`  | lsp warning   |
| `[]i`  | current scope |

## keymap

| keymap       | usage            |
| ------------ | ---------------- |
| `<Leader>lc` | remove null line |
| `<Leader>ld` | remove comments  |

## git diff

> plugin: https://github.com/sindrets/diffview.nvim
> more usage see https://github.com/sindrets/diffview.nvim/blob/main/doc/diffview.txt

| keymap                                       | usage                                         |
| -------------------------------------------- | --------------------------------------------- |
| `DiffviewOpen`                               | diff view git status (unstaged and staged)    |
| `DiffviewOpen HEAD~2`                        | diff view between specical commit and current |
| `DiffviewOpen d4a7b0d`                       | diff view between specical commit and current |
| `DiffviewOpen d4a7b0d^!`                     | diff view single specical commit              |
| `DiffviewOpen HEAD~4..HEAD~2`                | diff view range [head~4, head~2)              |
| `DiffviewOpen d4a7b0d..519b30e`              | diff view range [head~4, head~2)              |
| `DiffviewOpen origin/main...HEAD`            | diff view between origin/main and HEAD        |
| `DiffviewFileHistory`                        | diff view current branch                      |
| `DiffviewFileHistory %`                      | diff view current file                        |
| `DiffviewFileHistory path/to/some/file.txt`  | diff view single file history                 |
| `DiffviewFileHistory path/to/some/directory` | diff view single file history                 |

# Spell 拼写检查

| key           | description                            |
| ------------- | -------------------------------------- |
| :set spell    | 启用拼写检查                           |
| :set nospell  | 禁用拼写检查                           |
| :set nospell! | 反转拼写检查                           |
| \[s / \]s     | 跳到上/下一个错误拼写处                |
| z=            | 显示当前错误拼写建议的列表，按顺序选择 |
| zg            | 将当前单词添加到字典中                 |
| zw            | 将当前单词标记为拼写错误，从词典删除   |

# surround.vim

1. 第一种使用

```
test -> "test"   #添加 ysiw"
"test" -> (test) #修改 cs"(
"test" -> test   #删除 ds"
注意对于括号类左括号和右括号行为不一样，左括号会自动加空格
```

2. 第二种
   text object用s表示选择整行

```
print("hello") -> [ print("hello") ] # 整行添加 yss[
```

3. 第三种
   text object用t表示 t表示tag

```
<p 123> abc </p> -> ' abc ' # 修改 cst'
```

# 代码折叠

由lsp，treesitter提供

| key | description  |
| --- | ------------ |
| za  | 反转当前折叠 |
| zc  | 折叠         |
| zo  | 打开折叠     |
| zM  | 折叠全部     |
| zR  | 打开全部折叠 |

# 代码查找替换

代码查找相关可以使用默认的 `/` 和 `telescope`

不好用的话可以用 `:Rg string | copen` 把搜索结果给到quickfix

下面主要是使用`spectre`进行代码替换，当然也是兼容查找的

| key       | description                          |
| --------- | ------------------------------------ |
| sf        | 在当前文件进行查找替换               |
| sF        | 在当前工作区进行查找替换             |
| H         | 不搜索隐藏文件                       |
| I         | 不搜索ignore文件                     |
| r         | 替换当前行                           |
| R         | 替换所有                             |
| dd        | 当前行排除在外，也可以"V"选择多行再d |
| F         | 将当前搜索结果发送到quickfix         |
| \<Alt-v\> | 改变替换预览显示方式                 |
| M         | 显示菜单，一般不用，直接H或者I就好了 |

还有一些其他快捷键配置，但很多貌似都没有用

**额外注意几点**：

1. 在insert模式不会进行搜索，进入normal模式会开始搜索
2. 搜索一个字符的时候需要使用"()"包起来，提了相关issue作者回答是搜索单个字符出现大量结果会崩溃，不过搜索^$单字符替换时还是很有需求的。
3. 不要编辑文本除了查找和替换的那一行
4. 搜索里的内容默认就开正则表达式了，替换和路径没有开

# 代码片段运行 SnipRun

> 使用Lazy后基本都没什么问题
> 如果初次安装不成功，使用 :checkhealth sniprun 查看一下报错，手动 `sh install.sh` 安装一下

对脚本语言比如`python`,`lua`支持较好

对于`c++`,`rust`这种支持一般，问题主要出现在编译上

已经映射好了快捷键

| key         | description                                              |
| ----------- | -------------------------------------------------------- |
| \<leader\>r | normal模式下运行当前文件，（行）visual模式下运行选择的行 |

消除SnipRun高亮内容使用手动 “:SnipClose” ,这个没有映射快捷键，需要是手动snip

# 多光标vim-visual-multi

这个和C-v进入的列选择模式不太一样，两者使用场景也不一样

使用只需要记住一下几个快捷键

| key     | description                                                |
| ------- | ---------------------------------------------------------- |
| C-n     | 开启多光标，可以先用visual选中要选的，否则就默认是iw的内容 |
| n N     | 选中当前的并移动到上/下一个位置                            |
| q Q     | 取消选中当前的并移动到上/下一个位置                        |
| \[ / \] | 去往上/下一个已经选中的位置                                |

选择完成后就可以`i/I/a/A/c`进入插入模式了
