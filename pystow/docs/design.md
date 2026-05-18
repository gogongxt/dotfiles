# pystow 实现设计文档

## 整体架构

```
pystow          # Bash 入口脚本，执行同目录下的 main.py
main.py         # 核心实现，包含 CLI 解析和所有操作逻辑
test_main.py    # pytest 测试
test.sh         # 测试入口脚本
```

`pystow` 是一个简单的 bash 包装脚本，通过 `dirname "$0"` 定位自身路径，然后执行同目录下的 `main.py` 并透传所有参数。这样无论从哪个路径调用，都能找到正确的 Python 文件。

## 核心概念

### 包（Package）

包是 stow 目录下的一个子目录，其中的文件结构镜像目标目录的布局。例如：

```
stow_dir/bash/.bashrc    →  target/.bashrc
stow_dir/vim/.vimrc      →  target/.vimrc
```

### 相对符号链接

所有符号链接使用相对路径。这样做的好处是：即使整个目录树被移动，链接仍然有效。

```
target/.bashrc -> ../bash/.bashrc
target/.config/app -> ../../myapp/.config/app
```

相对路径通过 `os.path.relpath(src, dst.parent)` 计算。

## 操作流程

### Stow（安装）

入口函数：`stow_package(package_dir, target_dir, simulate, verbose)`

递归遍历包目录，对每个条目执行以下判断：

```
包中的条目 entry  →  对应的目标路径 target_entry

1. target_entry 不存在且不是断链接
   → 创建符号链接 target_entry -> entry（相对路径）

2. target_entry 是符号链接
   → 检查它是否已指向本包中的对应文件
      是 → 跳过（幂等）
      否 → 报告 CONFLICT

3. target_entry 是目录 且 entry 也是目录
   → 递归进入两个目录（目录折叠）

4. 其他情况
   → 报告 CONFLICT（文件/目录类型不匹配）
```

#### 目录折叠

这是 stow 的关键设计。当目标路径已经是一个真实目录时，不能将它替换为符号链接（会破坏其中已有的内容）。所以递归进入该目录，在更深层级创建链接。

示例：

```
包: myapp/.config/app/config.yml

目标已有: ~/.config/other/

结果:
  ~/.config/        ← 真实目录，不创建链接
  ~/.config/other/  ← 原有内容
  ~/.config/app/    ← 符号链接 → ../../myapp/.config/app
```

如果目标目录不存在，则整个目录被链接：

```
包: myapp/.config/app/config.yml

目标: ~/ (没有 .config)

结果:
  ~/.config/        ← 符号链接 → ../myapp/.config
```

### Delete（卸载）

入口函数：`delete_package(package_dir, target_dir, simulate, verbose)`

递归遍历包目录，对每个条目检查对应的目标路径：

```
1. target_entry 是符号链接 且 指向本包
   → 删除该符号链接
   → 尝试向上清理空目录

2. target_entry 是目录 且 entry 也是目录
   → 递归进入

3. 其他
   → 跳过（不是本包的链接，不碰）
```

#### 空目录清理（Prune）

删除符号链接后，其父目录可能变空。`_prune_empty_parents` 从被删链接的父目录开始，逐级向上检查：如果目录为空，则删除；遇到非空目录或到达 target_root 则停止。

这确保了：

- 卸载后不留空目录垃圾
- 共享目录（如已有 `other/` 的 `.config/`）不会被删除

### Restow（重新安装）

先调用 delete，再调用 stow。适用于包内容变更后刷新链接。

### Simulate（模拟运行）

所有操作函数接受 `simulate` 参数。为 `True` 时，正常执行判断逻辑，但跳过所有文件系统修改操作（`symlink_to`、`unlink`、`rmdir`），只打印将要执行的操作。

## CLI 参数处理

使用 `argparse` 解析命令行参数。操作优先级：

```
-R (--restow)  >  -D (--delete)  >  -S (--stow, 默认)
```

`-d` 指定 stow 目录，缺省为当前工作目录。`-t` 指定目标目录，缺省为 stow 目录的父目录（与 GNU Stow 一致）。

## 错误处理

- 冲突（目标已被其他文件/链接占据）→ 打印 WARNING，记录到 errors 列表，继续处理其他条目
- 包不存在 → 打印 WARNING，跳过该包
- 所有错误汇总，如果有任何错误则退出码为 1

这种"尽力而为"的策略与 GNU Stow 一致：遇到冲突不中断，继续处理能处理的部分。

## 测试结构

`test_main.py` 使用 pytest，每个测试用例通过 `tmp_path` fixture 创建隔离的临时目录。

| 测试类               | 覆盖场景                                                 |
| -------------------- | -------------------------------------------------------- |
| TestCreateSymlink    | 链接创建、simulate 不创建                                |
| TestStowBasic        | 顶层链接、深层嵌套、多包、幂等性                         |
| TestDirectoryFolding | 目录已存在时的折叠、多级折叠                             |
| TestConflicts        | 文件冲突、链接冲突                                       |
| TestDelete           | 删除链接、清理空目录、保留共享目录、模拟、删除未安装的包 |
| TestRestow           | 刷新链接、新增文件后 restow                              |
| TestSimulate         | stow/delete 的模拟模式                                   |
| TestCLI              | 命令行集成测试（subprocess 调用 main.py）                |
