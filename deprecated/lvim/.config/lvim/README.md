# 🚦我的nvim终极配置指南

<font color="#dd0000">基于lunarvim+额外自己的配置</font>

<font color="#0000dd">本文主要是笔记向+教程向，基础比如插件快捷键篇笔记向，一些难配的偏教程向</font>

当然本身基于`lunarvim`，大量基础配置已经弄好了， 只需要修改一些自己习惯的+增加自己的需求插件就好了

# ⚡️ 使用前必读

**适用于neovim版本`0.9`，推荐和我相同版本可以减少各种bug**

**演示示例：** [https://www.bilibili.com/video/BV1ec411s7Vc](https://www.bilibili.com/video/BV1ec411s7Vc)

**安装以及配置教程：** [https://www.bilibili.com/video/BV1nQ4y1L79w](https://www.bilibili.com/video/BV1nQ4y1L79w)

*如果你使用的nvim版本是`0.8`，可以看我之前的历史版本： [https://github.com/gxt-kt/lvim/tree/nvim_8](https://github.com/gxt-kt/lvim/tree/nvim_8)*


# 你自己可能添加的配置
1. chatgpt的插件**gp.nvim**，需要提供openai的api
  同目录创建一个文件`.openai_api_key`，在这个文件里写入你的key，形式应该是`sk-****`

2. 创建一个你自己的配置文件（可选）
  `cp my_config_example.lua my_config.lua`，
  然后就可以修改`my_config.lua`，内容示例:
  ```
local M = {}

-- 是否使能neovim显示图片，涉及插件有leetcode.nvim和image.nvim
M.image_enabled = false

return M
  ```


# 📦 使用的所有插件

<font color="#dd0000">分成两部分，分别是lunarvim的和自己的，每个插件后面都有简略介绍</font>

|lunarvim插件|功能|
|---|---|
|**bufferline.nvim**|顶栏显示buffer名称，类似vscode的tab|
|**cmp-buffer**|可以从buffer补全|
|**indent-blankline.nvim**|强化缩进显示|
|**lazy.nvim**|插件管理|
|**lir.nvim**|文件管理器，比如打开一个临时浮动的文件管理器，和nvimtree不同|
|**lualine.nvim**|底下的状态栏美化配置|
|**lunar.nvim**|主题|
|**mason-lspconfig.nvim**|lsp强化相关|
|**mason.nvim**|lsp强化相关|
|**nlsp-settings.nvim**|lsp强化相关|
|**nvim-cmp**|代码补全|
|**nvim-dap**|代码调试相关|
|**nvim-dap-ui**|代码调试相关|
|**nvim-lspconfig**|lsp强化相关|
|**nvim-navic**|顶栏显示当前光标所在嵌套层级，需要lsp|
|**nvim-tree.lua**|文件树|
|**nvim-treesitter**|代码高亮，代码折叠，彩虹花括号，代码格式化（没有用到，用的是lsp的格式化）|
|**nvim-ts-context-commentstring**|强化注释插件，和treesitter相关|
|**nvim-web-devicons**|强化图标显示|
|**plenary.nvim**|lua相关，仅限nvim，很多其它插件需要比如telescope,gitsigns|
|**popup.nvim**|暂时的其他依赖|
|**project.nvim**|打开项目，配合telescope打开最近项目|
|**structlog.nvim**|lua警告错误提示插件，可以在右上角提示消息框美化等|
|**telescope.nvim**|查找插件|
|**toggleterm.nvim**|nvim中的终端，可以浮动或者侧边栏|
|**tokyonight.nvim**|主题|
|**vim-illuminate**|同含义文字高亮|
|**which-key.nvim**|按键映射管理，可有效防止忘记快捷键|
|**Comment.nvim**|注释插件|
|**LuaSnip**|代码片段增强|
|**friendly-snippets**|代码片段增强|
|**gitsigns.nvim**|git相关插件|
|**neodev.nvim**|强化nvim,可以配合lsp提供函数悬浮提示|
|**null-ls.nvim**|强化lsp|
|**nvim-autopairs**|自动括号补全|
|**schemastore.nvim**|json文件显示强化|
|**onedarker.nvim**|主题|
|**cmp-cmdline**|输入命令时也可以补全|
|**cmp-nvim-lsp**|lsp服务|
|**cmp-path**|路径补全|
|**cmp_luasnip**|强化补全|
|**packer**|插件管理器|
|**alpha-nvim**|刚打开nvim首页美化和增加功能选项|
|**bigfile.nvim**|当打开超大文件时自动关闭一些功能比如lsp,语法高亮等|
|**telescope-fzf-native.nvim**|强化telescope|

---


|我自己的插件|功能|
|---|---|
|`trouble.nvim`|可以和其他插件配合强化显示，比如查看所有todo，查看所有lsp提示信息|
|`nvim-bqf`|强化quickfix窗口显示|
|`vista.vim`|一种分类的大纲试图|
|`telescope-live-grep-args.nvim`|支持telescope查找文本时传参，比如--no-ignore不忽略.ignore内容|
|`hop.nvim`|跳转，和easymotion一样|
|`flash.nvim`|支持任意字母匹配数跳转，和Jetbrains的ideam跳转一样|
|`winresizer`|窗口管理，\<C-e\>呼出|
|`vim-log-highlighting`|可以手动对内容进行高亮，方便自己查看|
|`nvim-surround`|更好对"({''})"等进行增删改|
|`todo-comments.nvim`|todo高亮|
|`auto-save.nvim`|自动保存，":ASToggle"进行开启或关闭|
|`clangd_extensions.nvim`|clangd扩展|
|`nvim-treesitter-textobjects`|强化treesitter|
|`nvim-neoclip.lua`| 剪切板  |
|`cmp-nvim-lsp-signature-help`|lsp高亮当前的输入参数|
|`nvim-lastplace`|智能回到上次关闭是所在的地方|
|`telescope-dap.nvim`|调试强化|
|`sniprun`|可以只跑一段代码，适合python等脚本，也可跑单文件类似vscode的run插件|
|`nvim-colorizer.lua`|对于#aabbcc显示颜色，对css等很有用|
|`nvim-lightbulb`|当lsp存在code|
|`symbols-outline.nvim`|真正的大纲试图|
|`nvim-ts-rainbow`|彩虹花括号，需要treesitter|
|`tmux.nvim`|在tmux中使用nvim，强化窗口移动兼容等|
|`vim-autoread`|文件改变时自动加载|
|`vim-ripgrep`|支持正则表达式的搜索，需要ripgrep，使用":Rp"|
|`nvim-spectre`|全局查找和替换插件|
|`vim-visual-multi`|多光标|
|`nvim-code-action-menu`|对于lsp action提示使用浮动窗口显示|
|`nvim-dap-virtual-text`|dap调试时行尾显示变量变化情况|
|`vim-maximizer`|只显示当前buffer，空间更大|
|`markdown-preview.nvim`|在本地网页中显示markdown内容|
|`hlchunk.nvim`|显示一条匹配的线当检测到块|
|`persistent-breakpoints.nvim`|调试时可以打持久断电，重新启动nvim断点还在|
|`twilight.nvim`|只高亮显示光标在的块|
|`nvim-ufo`|增强代码块折叠|
|`statuscol.nvim`|支持自己任意配置左侧状态栏|
|`headlines.nvim`|增强markdown文件高亮显示|
|`wildfire.nvim`|支持enter进行块选择，类似Jetbrains的enter|
|`nvim-hlslens`|增强vim默认的`/*#`搜索|
|`bookmarks.nvim`|增强书签|
|`leetcode.nvim`|leetcode刷题插件|
|`image.nvim`|支持在neovim和tmux中显示图片|

---

|主题|注释|
|---|---|
|`tokyonight.nvim`|lvim带的|
|`catppuccin`|我自己最常用的|
|`nightfox`||
|`everforest`||
|`gruvbox`||
|`github-nvim-theme`|github主题比如github light|
|`papercolor-theme`|类纸颜色|
|`material`|推荐palenight|




# 注释插件使用 Comment.nvim

>  除了以下插件的使用方法，lunarvim还支持“\<leader\>/"进行行注释

#### Basic mappings

These mappings are enabled by default. (config: `mappings.basic`)

- NORMAL mode

```
`gcc` - Toggles the current line using linewise comment
`gbc` - Toggles the current line using blockwise comment
`[count]gcc` - Toggles the number of line given as a prefix-count using linewise
`[count]gbc` - Toggles the number of line given as a prefix-count using blockwise
`gc[count]{motion}` - (Op-pending) Toggles the region using linewise comment
`gb[count]{motion}` - (Op-pending) Toggles the region using blockwise comment
```

- VISUAL mode

```
`gc` - Toggles the region using linewise comment
`gb` - Toggles the region using blockwise comment
```

#### Extra mappings

These mappings are enabled by default. (config: `mappings.extra`)

- NORMAL mode

```
`gco` - Insert comment to the next line and enters INSERT mode
`gcO` - Insert comment to the previous line and enters INSERT mode
`gcA` - Insert comment to end of the current line and enters INSERT mode
```

##### Examples

```
# Linewise

`gcw` - Toggle from the current cursor position to the next word
`gc$` - Toggle from the current cursor position to the end of line
`gc}` - Toggle until the next blank line
`gc5j` - Toggle 5 lines after the current cursor position
`gc8k` - Toggle 8 lines before the current cursor position
`gcip` - Toggle inside of paragraph
`gca}` - Toggle around curly brackets

# Blockwise

`gb2}` - Toggle until the 2 next blank line
`gbaf` - Toggle comment around a function (w/ LSP/treesitter support)
`gbac` - Toggle comment around a class (w/ LSP/treesitter support)
```



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
print("hello") -> [ print("hello") ] # yss[
```

3. 第三种
text object用t表示 t表示tag
```
<p 123> abc </p> -> ' abc ' # cst'
```

  

# 自动保存

默认已经开启自动保存

关闭或者再次开启执行 ":ASToggle"

# telescope
| key       | description                                                  |
| ------------ | ------------------------------------------------------------ |
|\<leader\>ff| 查找文件 |
|\<leader\>fs| 查找文本 |
|\<leader\>fp| 打开最近的项目 |
|\<leader\>fr| 打开最近的文件 |
|\<leader\>fy| 打开剪切板 <font color="#0000dd">使用的neoclip</font> |
|\<leader\>fk| 打开按键映射 |
|\<leader\>fw| 查找当前光标所有的内容 |


# trouble

在底部栏显示汇总相关内容

| key       | description                                                  |
| ------------ | ------------------------------------------------------------ |
| \<leader\>tt | 查看所有todo <font color="#dd0000">（推荐使用）</font>       |
| \<leader\>td | 查看当前文件所有lsp诊断 <font color="#dd0000">（推荐使用）</font> |
| \<leader\>tw | 查看当前工作区所有lsp诊断 <font color="#dd0000">（推荐使用）</font> |
| \<leader\>tl | 另一种quickfix：locallist 不过现在有bug <font color="#0000dd">暂时不用记</font> |
| \<leader\>tq | quickfix  有bug,同上 <font color="#0000dd">暂时不用记</font> |
| \<leader\>tr | 查看所有引用，和lsp的gr差不多，<font color="#0000dd">暂时不用记</font> |
| \<leader\>tf | 查看定义，和lsp差不多 <font color="#0000dd">暂时不用记</font> |
|              |                                                              |



# lsp

>  lsp和trouble和telescope很多地方都重合了，不同点在于telescope是浮动形式的，trouble则是侧边栏形式（底栏）


| key  | description                                                  | mode   |
| ---- | ------------------------------------------------------------ | ------ |
| `gl` | show line diagnostics<font color="#dd0000">（推荐使用，查看诊断信息）</font> | normal |
| `gh` | hover information<font color="#dd0000">（推荐使用，浮动查看函数详情）</font> | normal |
| `gd` | go to definition<font color="#dd0000">（推荐使用）</font>    | normal |
| `gD` | go to declaration<font color="#dd0000">（推荐使用）</font>   | normal |
| `gr` | go to references<font color="#dd0000">（推荐使用）</font>    | normal |
| `gs` | show signature help<font color="#dd0000">（推荐使用，输入参数时浮动查看输入参数情况）</font> | normal |
| `gI` | go to implementation<font color="#0000dd"> 暂时还没弄明白咋用，不知道使用场景</font> | normal |



# 浮动终端 toggleterm.nvim

| 终端类型|快捷键|
|---|---|
|浮动终端 1|\<Alt-\`\> <font color="#dd0000">（推荐使用，常用）</font>|
|浮动终端 2|\<Alt-Escape\> <font color="#dd0000">（推荐使用，常用）</font>|
|右边栏终端 1 |\<A-\\\>|
|右边栏终端 2 |\<A-BackSpace\>|
|底部栏终端 |\<A-\-\>|


# 光标和窗口相关

#### 光标移动 : 

默认可以使用 "\<C-h/j/k/l\>"进行上下左右切换

为了避免和tmux冲突，已经安装了tmux插件，注意需要在tmux中也加入相应配置内容，配置完成后这个就不算问题了

#### 窗口分屏：

可以使用vim默认的 `<C-w>v` 和 `<C-w>s` 进行左右和上下分屏，

不过我还映射了一个`<leader>\` 和 `<leader>-` 进行左右和上下分屏

#### 窗口缩放：

关于窗口缩放，默认使用 "Ctrl+方向键"，同样在tmux中会有冲突

默认按下后会执行tmux的窗口缩放，这个问题由下面这个插件单独解决。

#### 插件winresizer：

`<C-e>`进入插件窗口缩放模式：

`h\j\k\l`可以直接进行窗口移动，并且比默认的移动更加符合直觉。

再次按 `e` 可以切换到窗口移动模式，这时候 `h\j\k\l` 就是移动当前窗口

同样再次按 `e` 又切换回窗口缩放模式

按`Esc`或`q`退出



# 代码折叠

由treesitter插件提供，lunarvim默认没有开，我已经手动开启了，最大折叠为99层嵌套，但是实际上肯定用不到这么多

| key  | description  |
| ---- | ------------ |
| zc   | 折叠         |
| zo   | 打开折叠     |
| zM   | 折叠全部     |
| zR   | 打开全部折叠 |

实际的折叠效果已经被插件`kevinhwang91/nvim-ufo`所替代，不过快捷键都是一样的

同样这一套快捷键适用在其他可能会有折叠的插件，可以按下尝试一下



# 代码查找替换

代码查找相关可以使用默认的 `/` 和 `telescope`

不好用的话可以用 `:Rg string | copen` 把搜索结果给到quickfix

下面主要是使用`spectre`进行代码替换，当然也是兼容查找的

| key                      | description                          |
| ------------------------ | ------------------------------------ |
| sf                       | 在当前文件进行查找替换               |
| sF                       | 在当前工作区进行查找替换             |
| H                        | 不搜索隐藏文件                       |
| I                        | 不搜索ignore文件                     |
| r                        | 替换当前行                           |
| R                        | 替换所有                             |
| dd                       | 当前行排除在外，也可以"V"选择多行再d |
| F                        | 将当前搜索结果发送到quickfix         |
| \<Alt-v\>                | 改变替换预览显示方式                 |
| M                        | 显示菜单，一般不用，直接H或者I就好了 |

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



# vim基本功内容

和插件没有关系，主要是一些基本内容，有的冷门一点怕忘了

| key            | description          |
| -------------- | -------------------- |
| u  C-r         | undo  reundo         |
| viw  vi'  vi{} | vi选择               |
| f*  F*         | 当前行跳到*字符      |
| C-o  C-i       | 返回刚刚编辑位置     |
| C-d C-u        | 翻半页               |
| C-f C-b        | 翻整页               |
| $ ^ 0          | 行尾，行首非空，行首 |



# vim剪切板使用

\+ \* 系统剪切板，已经和tmux，系统无缝使用

"  无名剪切板

0-9 其他剪切板

也可以自己定义剪切板，使用其他字符

使用：reg查看寄存器详情

使用寄存器都需要` " ` 前缀

**从vim复制到寄存器里：** 

:"1yy 复制当前行到1寄存器

先v选中再:"+y 复制选中内容到系统剪切板

:"+2dd 删除两行并复制到系统剪切板

**从寄存器复制到vim里：**

:"+p 粘贴系统板内容

:"1p 粘贴1寄存器

alacritty/kitty还支持`<C-S-v>` 粘贴

tmux也有自己的粘贴方法



# 多光标vim-visual-multi

这个和C-v进入的列选择模式不太一样，两者使用场景也不一样

使用只需要记住一下几个快捷键

| key                                | description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| C-n                                | 开启多光标，可以先用visual选中要选的，否则就默认是iw的内容 |
| n N                                | 选中当前的并移动到上/下一个位置                            |
| q Q                                | 取消选中当前的并移动到上/下一个位置                        |
| \[   \]                            | 去往上/下一个已经选中的位置                                |

 选择完成后就可以`i/I/a/A/c`进入插入模式了


# 代码调试debug

这一部分估计才是最有难度的点了，lunarvim也已经配置好了大部分，但是我们自己的那一部分也有点难度

默认lunarvim没有开启dap，不过我的配置里已经active=true了

首先需要安装debug-adapter，默认直接使用lunarvim安装 `<leader>lI`就可以打开`Mason Info`窗口，选择3找到dap， 选择对应语言的调试器，按`i`安装就可以了

我这里选择：

- python -> debugpy      
-  c/c++/rust -> cpptools

然后需要相关调试器配置。

---

#### python配置（简单）

```lua
require('dap').configurations.python = {
  {
    type = 'python';
    request = 'launch';
    name = "Launch file";
    program = "${file}";
    pythonPath = function()
      return '/usr/bin/python'
    end;
  },
}
require('dap').adapters.python = {
  type = "executable";
  command='/home/gxt_kt/.local/share/nvim/mason/bin/debugpy-adapter';
  args = { };
}
```

调试器路径要注意，必须要绝对路径，然后安装的位置如果用上面的Mason安装的就在默认位置`.local/share/nvim/mason/bin/`，自己安装的就选择自己的

配置就完成了，在python代码中`<leader>dt`打断点，`<leader>ds`开始调试。

***

#### c/cpp/rust配置（难）

建议先把python配通再配置这个，这个难度要高一点

这三个语言都是用的cpptools+gdb，其中cpptools是借用vscode的（不用安装vscode也没事）

> 配置参考 https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)

```lua
-- https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)
-- 每一段都有解释，很好懂
-- 注意三点：
-- 1. dap的adapters的command改到自己路径
-- 2. 增加了一个attach,attach适用于程序已经跑起来了调试，还有有一个远程gdb的，不用的话可以注释掉
-- 3. 这里开启了enable pretty printing 主要是用来给stl显示用的，不开的话显示的就是stl原生的内容，不好读
local dap = require('dap')
dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '/home/gxt_kt/.local/share/nvim/mason/bin/OpenDebugAD7' --注意改到自己的路径
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
    setupCommands = {
      {
        text = '-enable-pretty-printing',
        description = 'enable pretty printing',
        ignoreFailures = false
      },
    },
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:1234',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '${workspaceFolder}',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    setupCommands = {
      {
        text = '-enable-pretty-printing',
        description = 'enable pretty printing',
        ignoreFailures = false
      },
    },
  },
  { -- attach
    name = "Attach process",
    type = "cppdbg",
    request = "attach",
    processId = require('dap.utils').pick_process,
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = "${workspaceFolder}",
    setupCommands = {
      {
        description = 'enable pretty printing',
        text = '-enable-pretty-printing',
        ignoreFailures = false
      },
    },
  },
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
```

还看到过相关说法，为了使用enable-pretty-printing还需要配置gdb,gdb相关配置可以参考 https://sourceware.org/gdb/wiki/STLSupport

不过我到vscode上实测了一下，launch.json配好了也不要这个配置，估计是历史问题，现在已经都集成了，不过我还是按照上面的gdb配了下，有发现stl显示不正常的可以配置下gdb再看看


# 其他

## 🐞 bug

1. **neovim 0.9.5在退出时会输出`uv__is_closing`的报错**

    > Ref: https://github.com/neovim/neovim/issues/21856

    已解决： 添加以下内容
    ```lua
    -- Sovle txt bug use kitty+tmux and show image
    -- https://github.com/neovim/neovim/issues/21856
    vim.api.nvim_create_autocmd({ "VimLeave" }, {
      callback = function()
        -- do nothing
        vim.fn.jobstart('', { detach = true })
      end,
    })
    ```

# 🎉 Reference

- [Neovim IDE from Scratch (youtube)](https://www.youtube.com/watch?v=ctH-a-1eUME&list=RDCMUCS97tchJDq17Qms3cux8wcA&index=1)
- [lunarvim website](https://www.lunarvim.org)
