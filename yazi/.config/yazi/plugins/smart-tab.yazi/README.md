# smart-tab.yazi

一个 Yazi 插件，可以智能地切换或创建标签页。

## 功能

- 当目标标签页存在时，切换到该标签页。
- 当目标标签页是下一个紧邻的标签页时，创建并切换到该标签页。

例如，如果您有 3 个标签页（索引为 0, 1, 2）：

- 调用 `plugin smart-tab 0` 将会切换到第一个标签页（索引 0）。
- 调用 `plugin smart-tab 3` 将会创建一个新的标签页（索引 3）并切换过去。
- 调用 `plugin smart-tab 4` 将不会执行任何操作，因为它跳过了索引。

## 安装

终端中执行：

```bash
ya pkg add gogongxt/smart-tab
```

## 用法

在您的 `keymap.toml` 中添加以下按键绑定。这允许您使用 `Alt+1` 到 `Alt+8` 切换到或创建相应的标签页。

```plaintext
[mgr.prepend_keymap]
# -- smart-tab
# 切换到第 N 个标签页，如果它尚不存在但紧邻当前最后一个标签页，则创建它。
{ on = "t", run = "tab_create --current", desc = "Create a new tab with CWD" },
{ on = "1", run = "plugin smart-tab  0", desc = "Switch to/create tab 1" },
{ on = "2", run = "plugin smart-tab  1", desc = "Switch to/create tab 2" },
{ on = "3", run = "plugin smart-tab  2", desc = "Switch to/create tab 3" },
{ on = "4", run = "plugin smart-tab  3", desc = "Switch to/create tab 4" },
{ on = "5", run = "plugin smart-tab  4", desc = "Switch to/create tab 5" },
{ on = "6", run = "plugin smart-tab  5", desc = "Switch to/create tab 6" },
{ on = "7", run = "plugin smart-tab  6", desc = "Switch to/create tab 7" },
{ on = "8", run = "plugin smart-tab  7", desc = "Switch to/create tab 8" },
{ on = "9", run = "plugin smart-tab  8", desc = "Switch to/create tab 9" },
{ on = "0", run = "plugin smart-tab  9", desc = "Switch to/create tab 10" },
```
