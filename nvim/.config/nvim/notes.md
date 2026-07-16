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

# treesitter

## treesitter textobjects move

> plugin: nvim-treesitter-textobjects (由 AstroNvim 内置配置)

| keymap | usage             |
| ------ | ----------------- |
| `]f`   | 下一个函数起始    |
| `]F`   | 下一个函数结束    |
| `[f`   | 上一个函数起始    |
| `[F`   | 上一个函数结束    |
| `]s`   | 下一个 class 起始 |
| `]S`   | 下一个 class 结束 |
| `[s`   | 上一个 class 起始 |
| `[S`   | 上一个 class 结束 |
| `]k`   | 下一个 block 起始 |
| `]K`   | 下一个 block 结束 |
| `[k`   | 上一个 block 起始 |
| `[K`   | 上一个 block 结束 |
| `]a`   | 下一个参数起始    |
| `]A`   | 下一个参数结束    |
| `[a`   | 上一个参数起始    |
| `[A`   | 上一个参数结束    |

> 规律：小写=起始，大写=结束；f=function, s=class, k=block, a=argument

## treesitter textobjects select

> 可视模式选择，`a`=外层(around)，`i`=内层(inner)

| keymap  | usage           |
| ------- | --------------- |
| `af/if` | 选中外/内层函数 |
| `ac/ic` | 选中外/内层类   |
| `ak/ik` | 选中外/内层块   |
| `a?/i?` | 选中外/内层条件 |
| `ao/io` | 选中外/内层循环 |
| `aa/ia` | 选中外/内层参数 |

## treesitter textobjects swap

| keymap | usage               |
| ------ | ------------------- |
| `>F`   | 与下一个函数交换    |
| `<F`   | 与上一个函数交换    |
| `>S`   | 与下一个 class 交换 |
| `<S`   | 与上一个 class 交换 |
| `>K`   | 与下一个 block 交换 |
| `<K`   | 与上一个 block 交换 |
| `>A`   | 与下一个参数交换    |
| `<A`   | 与上一个参数交换    |

# git diff

> plugin: https://github.com/sindrets/diffview.nvim
> more usage see https://github.com/sindrets/diffview.nvim/blob/main/doc/diffview.txt

| keymap                                       | usage                                         |
| -------------------------------------------- | --------------------------------------------- |
| `DiffviewOpen`                               | diff view git status (unstaged and staged)    |
| `DiffviewOpen HEAD~2`                        | diff view between specical commit and current |
| `DiffviewOpen d4a7b0d`                       | diff view between specical commit and current |
| `DiffviewOpen d4a7b0d^!`                     | diff view single specical commit              |
| `DiffviewOpen HEAD~4..HEAD~2`                | diff view range [head\~4, head\~2)            |
| `DiffviewOpen d4a7b0d..519b30e`              | diff view range [head\~4, head\~2)            |
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
| zC  | 折叠递归     |
| zo  | 打开折叠     |
| zO  | 打开折叠递归 |
| zM  | 折叠全部     |
| zR  | 打开全部折叠 |

# 代码查找替换

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

# 把vim放入后台，回到之前的shell

> 总共两种方法，第一种更快更好用，并且nvim/vim通用

## 放入jobs后台

按`ctrl+z`把vim挂到后台，回会到打开vim的shell

终端里可以看到提示：`[1]+  Stopped     vim file.txt`

输入命令`fg`就可以回到之前的vim

别的命令：

- `jobs` 查看当前后台所有vim
- `fg %1` 进入指定的vim，这里的数字就是挂起时[]的数字，默认累加

## 使用!shell进入子shell，只支持vim，不支持neovim

在vim中输入`:shell`或者`:!bash`，`:!zsh` 都会进入子shell

在子shell里可以操作，回到vim只需要`exit`或者`ctrl-d`

# 快速编号

使用`ctrl+a`和`ctrl+x`可以快速加减编号

快速生成多个比如：

```
1.
2.
3.
4.
...
```

可以先打出：

```
1.
1.
1.
1.
```

然后选中这些行，输入`g<c-a>`就可以快速完成编号，会变成：

```
2.
3.
4.
5.
```

我们可以：

1. 选中这些行时不选择第一行，就会从第二行开始变2，以此类推
2. 再次选中所有行，输入`g<c-x>`就又是从1开始编号了

# 在neovim中添加bash命令输出

我自己写过一个函数`execute_and_print_cmd`专门执行bash命令并且输出到当前的光标位置

vim自己也有一套bash命令执行

比如我们想把date输出当当前行

`!!date` 或者`.!data`

其实本质上`!!date`就是`.!date`

这里的含义：

```plaintext
:.!date
│││ └── 外部 shell 命令
││└──── 把文本送给外部命令（filter）
│└───── 行范围
└────── Ex 命令起始符
```

**对于行范围，有多种可以选：**

| 符号    | 含义            |
| ------- | --------------- |
| `.`     | 当前行          |
| `$`     | 最后一行        |
| `1`     | 第一行          |
| `%`     | 全部行（`1,$`） |
| `'<,'>` | 可视选中范围    |

**别的示例：**

| 命令                     | 含义                   |
| ------------------------ | ---------------------- |
| `:.!tr a-z A-Z`          | 当前行转大写           |
| `:%!jq .`                | 对当前文件使用jq格式化 |
| `:5,$!sed 's/foo/bar/g'` | 第五行到结尾替换       |

# neovim 替换

## 删除指定行尾的单个空格

`'<,'>s/ $/`

- `'<,'>` visual模式下的选择
- `s` 表示替换substitute
- `/` 间隔
- ` $` 表示空格，$表示匹配行尾，就不会匹配上中间的空格
- `/` 间隔
- 后面不加东西，就是为空
- 只删最后一个空格；若行尾有多个空格，用下面的 `\s\+$` 一次性删完

## 删除行尾的多余空格（tab + space）

`:%s/\s\+$//e`

- `%` 全文件
- `\s\+` 一个或多个空白字符（包含 tab）
- `$` 行尾
- `//` 替换为空
- `e` 标志：没有匹配也不报错

## 删除所有空行

`:%g/^$/d`

- `g` global命令，对所有匹配行执行
- `^$` 空行
- `d` 删除

## 删除连续空行（只保留一行）

`:%s/\n\{3,}/\r\r/`

- `\n\{3,}` 匹配 3 个及以上连续换行（即 2 行及以上空行）
- `\r\r` 替换为 2 个换行（即保留 1 行空行）
- 替换文本中用 `\r` 表示换行，不是 `\n`
- 原命令 `:%g/^$/,/./-1d` 实际是删除整块空行（0 行），不是保留 1 行

## 替换时保留原匹配内容（使用 `&`）

`:%s/foo/&bar/g`

- `&` 表示整个匹配的文本
- 上面会把 `foo` 替换为 `foobar`

## 使用捕获组 `\1 \2`

`:%s/\(\w\+\)\s\+\(\w\+\)/\2 \1/g`

- 交换两个单词的位置
- `\(...\)` 捕获组（very magic 模式下用 `(...)`）
- `\1` `\2` 引用捕获

## very magic 模式（减少转义）

在模式前加 `\v`，让特殊字符不用转义：

`:%s/\v(\w+)\s+(\w+)/\2 \1/g`

- `\v` 后 `()` `+` `{}` 等直接使用，不用 `\`
- 模式开关：`\v` very magic、`\V` very nomagic、`\m` magic（默认）、`\M` nomagic
- 字符类（任何模式下都可用）：`\d` 数字、`\w` 单词字符、`\s` 空白、`\x` hex 等

## 大小写不敏感替换

`:%s/foo/bar/gi`

- `i` 忽略大小写（匹配 Foo、FOO 等）
- `g` 全行替换（不止第一个）
- `I` 则是强制大小写敏感

## 确认每次替换

`:%s/foo/bar/gc`

- `c` confirm，每次替换前询问
- 提示：`y` 替换、`n` 跳过、`a` 全部替换、`q` 退出、`l` 替换后退出、`e` 替换本个后退出、`^E`/`^Y` 上下滚动

## 在指定行范围替换

`:5,20s/foo/bar/g` " 5 到 20 行
`:.+1,$s/foo/bar/g` " 当前行下一行到文件末尾
`:'a,'bs/foo/bar/g` " mark a 到 mark b 之间

## 替换包含特殊字符

替换中如果想用换行，用 `\r`（不是 `\n`）：

`:%s/foo/bar\rbaz/`

- 会把 `foo` 替换为 `bar` 然后换行再加 `baz`
- 替换文本中 `\n` 表示空字符（NUL），不是换行

## 跨行替换（多行变一行）

`:%s/\n/, /g`

- 把所有换行替换为逗号空格，整文件变一行
- 注意：DOS 换行（`\r\n`）文件才会残留 `^M`，Unix 文件无此问题
- 副作用：最后一行行尾也会多一个 `, `。若不想留尾部分隔符，用 `:%s/\n\ze./, /g`（只在后面还有字符时替换换行）

## 替换时执行表达式

`:%s/\d\+/\=submatch(0)*2/g`

- `\=` 表示后面是表达式
- `submatch(0)` 是整个匹配
- 把所有数字乘以 2

## 复用上次模式

`:%s//新内容/g`

- 模式部分留空，复用上次搜索的 pattern（`/` 搜索过的）
- 适合先用 `/` 调试好再批量替换
- 若之前没搜索过会报 `E35: No previous regular expression`，先 `/pat` 一次即可

## 只替换可视选中的部分

选中后按 `:`，命令行自动变成 `'<,'>`，直接：

`:'<,'>s/foo/bar/g`

## 重复上次替换命令

`:&` 或 `:s` 回车 — 重复上次替换（不带参数）
`:&g` — 重复但加上 `g` 标志

## 在替换中使用寄存器

`:%s/foo/\=@a/`

- `\=` 后接寄存器表达式
- 把 `foo` 替换为寄存器 `a` 的内容

## 反向：把替换内容里出现的 `\0` 等价于 `&`

| 替换中字符 | 含义                  |
| ---------- | --------------------- |
| `&`        | 整个匹配              |
| `\0`       | 同 `&`                |
| `\1..\9`   | 对应捕获组            |
| `\r`       | 换行                  |
| `\n`       | NUL（不是换行）       |
| `\u \l`    | 下一个字符转大写/小写 |
| `\U \L`    | 后续直到 `\e` 或 `\E` |

示例：把每个单词首字母大写

`:%s/\w\+/\u&/g`
