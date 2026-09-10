#!/bin/sh

# 关闭窗口后找回焦点
#
# 同应用多窗口（如两个 kitty）关闭其一，系统/yabai 会在应用内自动转移焦点；
# 但关闭浮动窗口（manage=off，如 Notes/TextEdit）后应用驻留且已无窗口，
# macOS 不会把焦点交还给同空间的其它窗口，这里手动聚焦剩余的窗口。
#
# 选择策略：yabai 的窗口查询按最近使用（LRU）排序（聚焦过的窗口排在队首），
# 取当前空间第一个可见窗口，即"最近使用过的窗口"。
# 性能：有焦点时一次查询即返回；悬空时共两次查询，无人工延迟。

# 快路径：已有窗口持有焦点 → 立即返回
if yabai -m query --windows 2>/dev/null | jq -e 'any(.["has-focus"])' >/dev/null 2>&1; then
    exit 0
fi

# 复查 + 选择合并为一次查询：若期间焦点已被接走则退出，否则聚焦最近使用的可见窗口
win=$(yabai -m query --windows --space 2>/dev/null |
    jq -r 'if any(.["has-focus"]) then empty
             else ([.[] | select(."is-visible")] | first | .id? // empty)
             end' 2>/dev/null)
[ -n "$win" ] && yabai -m window --focus "$win" 2>/dev/null

exit 0
