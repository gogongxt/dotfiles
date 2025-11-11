#!/bin/bash
# 反转当前窗口所有pane的copy mode状态
# 如果所有pane都在copy mode，则全部退出；否则全部进入

# 获取当前窗口的所有pane ID
panes=$(tmux list-panes -F "#{pane_id}")

# 检查是否所有pane都在copy mode
all_in_copy_mode=true
for pane in $panes; do
    pane_mode=$(tmux display -p -t "$pane" -F "#{pane_in_mode}")
    if [ "$pane_mode" != "1" ]; then
        all_in_copy_mode=false
        break
    fi
done

if [ "$all_in_copy_mode" = true ]; then
    # 所有pane都在copy mode，全部退出
    # 使用 send-keys 来退出 copy mode，这样更可靠
    for pane in $panes; do
        tmux send-keys -t "$pane" -X cancel 2>/dev/null || true
    done
else
    # 至少有一个pane不在copy mode，全部进入
    for pane in $panes; do
        tmux copy-mode -t "$pane" 2>/dev/null || true
    done
fi

# 确保脚本总是返回成功状态
exit 0
