# pystow

GNU Stow 的 Python 重新实现，用于管理符号链接。

## 用法

```
pystow [选项] 包名 [包名 ...]
```

### 选项

| 选项               | 说明                                 |
| ------------------ | ------------------------------------ |
| `-t, --target DIR` | 目标目录（默认：stow 目录的父目录）  |
| `-d, --dir DIR`    | 包所在的 stow 目录（默认：当前目录） |
| `-S, --stow`       | 安装包（默认操作）                   |
| `-D, --delete`     | 卸载包                               |
| `-R, --restow`     | 重新安装（先卸载再安装）             |
| `-n, --simulate`   | 模拟运行，不实际修改文件系统         |
| `-v, --verbose`    | 增加详细程度（可重复使用）           |

### 基本用法

假设你有一个 dotfiles 仓库：

```
dotfiles/
├── bash/
│   └── .bashrc
├── vim/
│   └── .vim/
│       └── autoload/
│           └── plug.vim
└── git/
    └── .gitconfig
```

将它们链接到 home 目录：

```bash
cd ~/dotfiles
pystow -t ~ bash vim git
```

结果：

```
~/
├── .bashrc -> ~/dotfiles/bash/.bashrc
├── .vim -> ~/dotfiles/vim/.vim
└── .gitconfig -> ~/dotfiles/git/.gitconfig
```

### 目录折叠

如果目标目录已经存在，pystow 会进入目录内部创建链接，而不是替换整个目录：

```bash
# 目标已有 .config 目录
mkdir -p ~/.config/other

# 安装包含 .config/app 的包
pystow -t ~ myapp
```

```
~/.config/
├── app -> ../../dotfiles/myapp/.config/app    # 新链接
└── other/                                     # 原有内容不受影响
```

### 卸载

```bash
pystow -t ~ -D bash
```

卸载后，空目录会被自动清理。如果目录中还有其他内容（如上例的 `.config/other`），目录会被保留。

### 重新安装

适用于更新包内容后刷新链接：

```bash
pystow -t ~ -R vim
```

### 模拟运行

查看将要执行的操作，不实际修改文件系统：

```bash
pystow -t ~ -n -v bash
```

### 使用 `--dir` 指定 stow 目录

```bash
pystow -d ~/dotfiles -t ~ bash vim
```

### 安装多个包

```bash
pystow -t ~ bash vim git
```

## 测试

```bash
./test.sh
```

## 与 GNU Stow 的对比

pystow 实现了 GNU Stow 的核心功能：

- 符号链接创建（相对路径）
- 目录折叠
- 冲突检测
- 卸载与空目录清理
- 模拟运行
- 多包操作

未实现的功能：`--ignore`、`--defer`、`--override`、`--adopt`、`--dotfiles`
